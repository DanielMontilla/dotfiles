## Phase 1: Metadata & Frontmatter

- [ ] `description` is clear enough for the agent to know when to activate the rule
- [ ] `globs` scopes the rule to specific files (e.g., `*.test.ts`) to save context
- [ ] `alwaysApply` is `false` unless absolutely necessary

## Phase 2: Clarity & Grounding

- [ ] Framework version is pinned (e.g., "Next.js 14")
- [ ] No assumptions about private libraries without explanation
- [ ] Rules do not conflict with project linter

## Phase 3: Prompt Engineering

- [ ] Uses positive constraints ("Do X") over negative ("Don't do Y")
- [ ] Includes at least one code example
- [ ] No fluff — removed "Please", "I would like", and generic padding

## Phase 4: Maintenance

- [ ] Rule is not tied to a deprecated library
- [ ] File saved to `.agents/rules/<rule-name>.md`