# Vendored herdr-space-topic

Upstream: https://github.com/panuhorsmalahti/herdr-space-topic
Vendored from commit `709dfb74d95da1f008f14e47470a670645d412c5` (v0.2.0).

This is a local copy because Spaces on these hosts use bare-repo worktrees
(`~/dev/<repo>/<branch>`), where upstream's `{original}`/`{cwd}` tokens report
the branch directory (`main`) rather than the repository (`<repo>`).

Local change:

- Add a `{repo}` format token. It resolves to the basename of the parent of the
  git common dir, so both `~/dev/<repo>/.bare` worktrees and ordinary
  `<repo>/.git` checkouts yield `<repo>`.
- Add `{branch_icon}` and `{branch_short}` tokens. Conventional branch
  prefixes (`feat/`, `fix/`, `hotfix/`, `WIP/`, `refactor/`, `cursor/`,
  `dependabot/`, ...) become one emoji; the prefix is dropped and remaining
  slashes/underscores become hyphens. Unknown prefixes stay in the name. The
  prefix-to-emoji map is `BRANCH_PREFIX_ICONS` near the top of the script.
- Do not strip status glyphs from labels, only from agent titles, so the
  branch icon survives later syncs.
- Strip a trailing `:` left when `{branch}` is empty (non-git directories).

Everything else is upstream. To update, re-copy the upstream files, re-apply
those changes, and restart herdr (or run `herdr server reload-config`).

Link the local plugin once per machine:

```sh
herdr plugin link ~/.config/herdr/plugins/phorsmalahti.space-topic
```

The user config lives next to it in
`~/.config/herdr/plugins/config/phorsmalahti.space-topic/config.toml`.
