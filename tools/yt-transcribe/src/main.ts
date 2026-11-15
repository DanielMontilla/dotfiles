#!/usr/bin/env bun
import { NodeServices } from '@effect/platform-node';
import * as clack from '@clack/prompts';
import { Data, Effect, FileSystem, Option, Path, Stream } from 'effect';
import * as Argument from 'effect/unstable/cli/Argument';
import * as Command from 'effect/unstable/cli/Command';
import * as Flag from 'effect/unstable/cli/Flag';
import { ChildProcess, ChildProcessSpawner } from 'effect/unstable/process';
import { homedir } from 'node:os';

/** An external tool (yt-dlp, whisper) could not start or exited non-zero. */
export class ToolError extends Data.TaggedError('ToolError')<{
  readonly tool: string;
  readonly reason: string;
}> {}

/** Names of the external tools this CLI shells out to. Must be on PATH. */
const YT_DLP = 'yt-dlp';
const WHISPER = 'whisper';

/** Where transcripts are saved when no --output is given. */
export const defaultOutputDir = (home: string, path: Path.Path): string =>
  path.join(home, 'Downloads', 'yt-transcribe');

/**
 * Environment for the child tools. Bun injects `LD_LIBRARY_PATH` pointing at
 * Nix's gcc-12 libstdc++, which makes ffmpeg/ffprobe fail to start; yt-dlp then
 * reports them as "not found". Drop it so the tools use their own libraries.
 */
const childEnv: Record<string, string | undefined> = (() => {
  const { LD_LIBRARY_PATH: _ignored, ...env } = process.env;
  return env;
})();

/** Turn a video title into a safe file name. */
export const toFileStem = (title: string): string =>
  title
    .replace(/[\\/:*?"<>|\u0000-\u001f]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 120) || 'transcript';

// ─── Progress parsing ─────────────────────────────────────────────────

/** One progress update parsed from a tool's output line. */
export interface ProgressUpdate {
  /** Identifies the phase; a change of key starts a new progress bar. */
  readonly key: 'download' | 'model' | 'transcribe';
  readonly label: string;
  readonly percent: number;
  readonly eta: string;
  readonly detail: string;
}

/**
 * Parse a progress line from yt-dlp or Whisper (tqdm). Returns undefined for
 * lines that are not progress updates.
 *
 * yt-dlp:  `[download]  42.0% of 8.09MiB at 1.2MiB/s ETA 00:05`
 * tqdm:    ` 42%|████  | 2600/54460 [00:54<18:14, 47.39frames/s]`  (transcription)
 *          `  7%|▋  | 101M/1.42G [00:31<05:24, 4.38MiB/s]`          (model download)
 */
export const parseProgress = (line: string): ProgressUpdate | undefined => {
  const ytdlp = /\[download\]\s+([\d.]+)%.*?ETA\s+(\S+)/.exec(line);
  if (ytdlp) {
    const detail = /of\s+~?\s*([\d.]+\S+)/.exec(line)?.[1] ?? '';
    return {
      key: 'download',
      label: 'Downloading audio',
      percent: Number(ytdlp[1]),
      eta: ytdlp[2] ?? '?',
      detail,
    };
  }

  const tqdm = /(\d+)%\|[^|]*\|\s*(\S+?)\/(\S+?)\s*\[[^<\]]*<([\d:?]+)/.exec(line);
  if (tqdm) {
    const transcribing = /frames\/s/.test(line);
    return {
      key: transcribing ? 'transcribe' : 'model',
      label: transcribing ? 'Transcribing' : 'Downloading Whisper model',
      percent: Number(tqdm[1]),
      eta: tqdm[4] ?? '?',
      detail: `${tqdm[2]}/${tqdm[3]}${transcribing ? ' frames' : ''}`,
    };
  }
  return undefined;
};

type Bar = ReturnType<typeof clack.progress>;

/**
 * Turns streamed tool output into clack progress bars, one bar per phase.
 * Keeps the last few plain lines so a failure can show what the tool said.
 */
const makeTracker = () => {
  let active: { readonly key: string; readonly label: string; readonly bar: Bar; last: number } | undefined;
  const recent: string[] = [];

  const finishActive = (suffix: string) => {
    if (!active) return;
    active.bar.stop(`${active.label} ${suffix}`);
    active = undefined;
  };

  return {
    onLine(line: string) {
      const update = parseProgress(line);
      if (!update) {
        const text = line.trim();
        if (text) {
          recent.push(text);
          if (recent.length > 5) recent.shift();
        }
        return;
      }
      if (!active || active.key !== update.key) {
        finishActive('✓');
        const bar = clack.progress({ max: 100, size: 30 });
        bar.start(update.label);
        active = { key: update.key, label: update.label, bar, last: 0 };
      }
      const percent = Math.min(100, Math.floor(update.percent));
      const message = `${update.detail} · ETA ${update.eta}`;
      if (percent > active.last) {
        active.bar.advance(percent - active.last, message);
        active.last = percent;
      } else {
        active.bar.message(message);
      }
    },
    done() {
      finishActive('✓');
    },
    fail(reason: string) {
      if (active) active.bar.error(`${active.label} failed`);
      active = undefined;
      clack.log.error(reason);
    },
    tail: () => recent.slice(-3).join(' | '),
  };
};

// ─── Running tools ────────────────────────────────────────────────────

/**
 * Run a tool and show its progress with clack progress bars. Fails with a
 * {@link ToolError} when it cannot start or exits non-zero.
 */
const watchTool = (tool: string, args: ReadonlyArray<string>) => {
  const tracker = makeTracker();
  return Effect.gen(function* () {
    const spawner = yield* ChildProcessSpawner.ChildProcessSpawner;
    const handle = yield* spawner
      .spawn(ChildProcess.make(tool, args, { env: childEnv }))
      .pipe(Effect.mapError((error) => new ToolError({ tool, reason: error.message })));

    yield* handle.all.pipe(
      Stream.decodeText(),
      Stream.map((text) => text.replace(/\r/g, '\n')),
      Stream.splitLines,
      Stream.runForEach((line) => Effect.sync(() => tracker.onLine(line))),
      Effect.mapError((error) => new ToolError({ tool, reason: error.message })),
    );

    const code = yield* handle.exitCode.pipe(
      Effect.mapError((error) => new ToolError({ tool, reason: error.message })),
    );
    if (code !== 0) {
      return yield* Effect.fail(
        new ToolError({ tool, reason: `exited with code ${code}. Last output: ${tracker.tail()}` }),
      );
    }
    tracker.done();
  }).pipe(
    Effect.scoped,
    Effect.tapError((error) => Effect.sync(() => tracker.fail(error.reason))),
  );
};

/** Run a tool and capture its stdout, failing with a {@link ToolError} on error. */
const runCapture = (tool: string, args: ReadonlyArray<string>) =>
  Effect.gen(function* () {
    const spawner = yield* ChildProcessSpawner.ChildProcessSpawner;
    return yield* spawner
      .string(ChildProcess.make(tool, args, { env: childEnv }))
      .pipe(Effect.mapError((error) => new ToolError({ tool, reason: error.message })));
  });

/** Show a clack spinner while `effect` runs, then stop it with `done` or an error. */
const withSpinner = <A, E extends { readonly reason?: string; readonly message?: string }, R>(
  label: string,
  effect: Effect.Effect<A, E, R>,
  done: (value: A) => string,
) =>
  Effect.gen(function* () {
    const spinner = clack.spinner();
    spinner.start(label);
    const value = yield* effect.pipe(
      Effect.tapError((error) =>
        Effect.sync(() => spinner.error(error.reason ?? error.message ?? String(error))),
      ),
    );
    spinner.stop(done(value));
    return value;
  });

// ─── Transcribe ───────────────────────────────────────────────────────

export interface TranscribeOptions {
  readonly url: string;
  readonly model: string;
  readonly language: string;
  readonly output: Option.Option<string>;
}

/**
 * Download a video's audio, transcribe it with Whisper, and save the text.
 * Intermediate files live in a temp directory removed when this effect ends,
 * whether it succeeds or fails.
 * @returns the absolute path of the saved transcript
 */
export const transcribe = (options: TranscribeOptions) =>
  Effect.gen(function* () {
    const fs = yield* FileSystem.FileSystem;
    const path = yield* Path.Path;

    clack.intro('yt-transcribe');

    const workDir = yield* fs.makeTempDirectoryScoped({ prefix: 'yt-transcribe-' });
    const audioBase = path.join(workDir, 'audio');
    const outDir = path.join(workDir, 'out');

    const title = yield* withSpinner(
      'Reading video info',
      runCapture(YT_DLP, ['--no-playlist', '--skip-download', '--print', 'title', options.url]).pipe(
        Effect.map((text) => text.trim()),
      ),
      (value) => `Video: ${value || options.url}`,
    );

    yield* watchTool(YT_DLP, [
      '--no-playlist',
      '--newline',
      '-x',
      '--audio-format',
      'mp3',
      '-o',
      `${audioBase}.%(ext)s`,
      options.url,
    ]);

    yield* watchTool(WHISPER, [
      `${audioBase}.mp3`,
      '--model',
      options.model,
      '--language',
      options.language,
      '--output_format',
      'txt',
      '--output_dir',
      outDir,
      '--verbose',
      'False',
      '--fp16',
      'False',
    ]);

    const text = yield* fs
      .readFileString(path.join(outDir, 'audio.txt'))
      .pipe(
        Effect.mapError(
          (error) => new ToolError({ tool: WHISPER, reason: `no transcript produced: ${error.message}` }),
        ),
      );

    let outPath: string;
    if (Option.isSome(options.output)) {
      outPath = path.resolve(options.output.value);
    } else {
      const dir = defaultOutputDir(homedir(), path);
      yield* fs.makeDirectory(dir, { recursive: true });
      const stem = toFileStem(title);
      outPath = path.join(dir, `${stem}.txt`);
      for (let n = 2; yield* fs.exists(outPath); n++) {
        outPath = path.join(dir, `${stem} (${n}).txt`);
      }
    }
    yield* fs.writeFileString(outPath, `${text.trim()}\n`);
    clack.outro(`Saved transcript: ${outPath}`);
    return outPath;
  }).pipe(Effect.scoped);

// ─── CLI ──────────────────────────────────────────────────────────────

const url = Argument.string('url').pipe(Argument.withDescription('YouTube video URL'));

const model = Flag.choice('model', ['tiny', 'base', 'small', 'medium', 'large-v3']).pipe(
  Flag.withDescription('Whisper model size (bigger = more accurate, slower)'),
  Flag.withDefault('medium'),
);

const language = Flag.string('language').pipe(
  Flag.withDescription('Spoken language code, e.g. en, es'),
  Flag.withDefault('en'),
);

const output = Flag.optional(
  Flag.string('output').pipe(
    Flag.withDescription('Output file (default: ~/Downloads/yt-transcribe/<video title>.txt)'),
  ),
);

const rootCommand = Command.make('yt-transcribe', { url, model, language, output }, (config) =>
  transcribe({
    url: config.url,
    model: config.model,
    language: config.language,
    output: config.output,
  }).pipe(
    Effect.catchTag('ToolError', (error) =>
      Effect.sync(() => {
        clack.outro(`✗ ${error.tool}: ${error.reason}`);
        process.exitCode = 1;
      }),
    ),
  ),
).pipe(Command.withDescription('Transcribe a YouTube video locally with yt-dlp + Whisper'));

const program = Command.run(rootCommand, { version: '0.2.0' }).pipe(
  Effect.provide(NodeServices.layer),
);

program.pipe(Effect.runPromise).catch((error: unknown) => {
  clack.outro(`✗ ${error instanceof Error ? error.message : String(error)}`);
  process.exitCode = 1;
});
