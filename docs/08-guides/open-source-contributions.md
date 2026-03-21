# Open Source Contribution Workflows

> Contributing to unfamiliar codebases is one of the highest-leverage uses of AI. Claude Code can explain architecture, decode test frameworks, and help you match existing code style -- turning a weekend of reading into an hour of guided exploration.

## The Exploration Phase

Before writing a single line of code, understand the project. AI is an excellent guide for this.

### Architecture Overview

Clone the repo, open Claude Code, and start broad:

```
"Explain the architecture of this project. What are the main directories,
what does each one do, and how do the pieces fit together? Start with the
entry point and trace the main execution flow."
```

Follow up with specifics:

```
"How does the build system work? Walk me through what happens when I run
`npm run build` -- what tools are involved, what config files control the
process, and where does the output go?"
```

```
"How is the test suite organized? What framework do they use, where do
test files live, and how do I run a single test file?"
```

### Understanding the Dependency Graph

For larger projects:

```
"Map the dependency graph for the src/core/ directory. Which modules
depend on which? Are there any circular dependencies? Which module is
the most depended-on?"
```

This gives you a mental map of where changes will have ripple effects -- critical before you touch anything.

### Identifying Conventions

Every project has unwritten rules. AI can surface them from the code:

```
"Look at 5-6 files in src/utils/ and describe the conventions this project
follows: naming, error handling patterns, export style, comment style,
and how they handle async operations."
```

## Finding and Understanding Issues

### Good First Issues

Most projects label beginner-friendly issues. After finding one, use AI to understand it:

```
"I want to work on issue #342: 'Add timeout option to the HTTP client.'
Read the issue description and the current HTTP client implementation in
src/client.ts. Explain:
1. What the issue is asking for
2. Which parts of the code need to change
3. What the existing pattern looks like for similar options
4. Are there any tests I should look at for reference?"
```

### Understanding the Problem Domain

Sometimes the issue references concepts you are not familiar with:

```
"Issue #512 mentions 'backpressure handling in the stream processor.'
Explain what backpressure means in this context, why it matters, and
how this project currently handles streaming. Point me to the relevant
source files."
```

## Reading CONTRIBUTING.md and Coding Standards

Every serious open source project has contribution guidelines. AI helps you parse and apply them:

```
"Read CONTRIBUTING.md and summarize:
1. Branch naming convention
2. Commit message format
3. Required tests for new features
4. PR description template or requirements
5. Any CLA or sign-off requirements"
```

Then, as you work:

```
"Does my current implementation follow the coding standards described
in CONTRIBUTING.md? Check naming conventions, error handling approach,
and test structure against the project's requirements."
```

### Coding Style Matching

This is where AI truly shines. Matching an unfamiliar project's style by hand requires reading many files and internalizing patterns. AI does this instantly:

```
"Follow the existing pattern in src/utils/validators.ts. I need to add
a new validator function for email addresses. Match the exact style:
same JSDoc format, same error types, same parameter naming convention,
same way they handle edge cases."
```

For more subtle style points:

```
"Compare how error handling works in src/handlers/auth.ts versus
src/handlers/data.ts. They seem inconsistent -- which pattern is
used more widely in the codebase? I want to follow the dominant pattern."
```

## Understanding Unfamiliar Test Frameworks

Open source projects use every testing framework imaginable. You might encounter Vitest, Ava, tape, uvu, or a custom harness. AI bridges the gap:

```
"This project uses Ava for testing. I'm used to Jest. Explain:
1. How do I write a basic test in Ava?
2. How does setup/teardown work (beforeEach equivalent)?
3. How do they handle async tests?
4. How do I run a single test file?
5. Show me a test from this project and explain its structure."
```

### Writing Tests That Match Existing Patterns

```
"Look at the tests in test/unit/validators.test.ts. I need to add tests
for the new email validator. Follow the same structure:
- Same describe/it nesting pattern
- Same assertion style (they use t.is, not t.deepEqual for simple checks)
- Same fixture setup approach
- Same naming convention for test descriptions"
```

Do not write tests in your preferred style. Match the project. Maintainers will reject PRs that introduce inconsistent test patterns, even if the tests themselves are correct.

## Running Unfamiliar CI Pipelines Locally

Before pushing, run what CI will run. AI helps you figure out how:

```
"Read .github/workflows/ci.yml and tell me exactly what commands CI runs.
I want to run them all locally before pushing. Include any environment
setup I need."
```

The AI might produce:

```bash
# From reading the CI config:
npm ci                          # clean install (not npm install)
npm run lint                    # ESLint with project config
npm run typecheck               # tsc --noEmit
npm run test -- --coverage      # tests with coverage threshold
npm run build                   # make sure it compiles
```

For more complex CI:

```
"The CI config has a matrix build across Node 18 and 20. I'm on Node 20
locally. Are there any Node-version-specific things I should worry about
in my changes?"
```

### Dealing With CI Failures

If CI fails after you push:

```
"CI failed on the 'lint' step with this error: [paste error]. I don't
have this linting rule in my local config. How do I configure my editor
to match the project's lint setup, and how do I fix the current failure?"
```

## Drafting the PR

### Commit Messages

Match the project's commit style:

```
"Look at the last 20 commit messages in main. What format do they follow?
Is it Conventional Commits (feat:, fix:, etc.)? Do they reference issue
numbers? What tense do they use?"
```

Then:

```
"Write a commit message for my changes following this project's convention.
My changes: added a timeout option to the HTTP client, with a default of
30 seconds, configurable per-request. Fixes issue #342."
```

### PR Descriptions

```
"Draft a PR description for my changes. Follow any PR template in
.github/PULL_REQUEST_TEMPLATE.md. If there's no template, write a
description that includes:
1. What the change does (2-3 sentences)
2. How it was tested
3. Link to the issue it addresses
4. Any breaking changes or migration notes
5. Screenshots if it's a UI change"
```

Example AI output:

```markdown
## Summary

Adds a configurable `timeout` option to the HTTP client. Defaults to
30 seconds. Can be set globally via client config or per-request via
the options parameter.

Fixes #342.

## Changes

- Added `timeout` option to `ClientConfig` interface
- Added `timeout` option to `RequestOptions` interface (overrides global)
- Implemented timeout using `AbortController` with `setTimeout`
- Added unit tests for timeout behavior (success, timeout, per-request override)

## Testing

- Added 4 unit tests in `test/unit/client.test.ts`
- Ran full test suite: all 247 tests pass
- Tested manually against a slow endpoint to verify timeout fires correctly
```

### Linking to Issues

```
"What's the correct syntax to link this PR to issue #342 in this project?
Do they use 'Fixes #342', 'Closes #342', or something else? Check existing
merged PRs for the pattern."
```

## Responding to Review Feedback

Maintainer feedback on your PR is not a conversation to have with AI alone -- you need to engage directly. But AI can help you implement the feedback efficiently.

### Understanding Feedback

```
"The maintainer left this review comment:

'This should use the existing retry logic in src/utils/retry.ts instead
of implementing its own timeout. The retry utility already handles
AbortController -- just pass the signal through.'

I don't understand how the retry utility works. Explain src/utils/retry.ts
to me, then show me how to refactor my timeout to use it."
```

### Implementing Requested Changes

```
"The reviewer asked me to:
1. Use the existing retry utility instead of custom timeout logic
2. Add a test for the case where timeout is 0 (should disable timeout)
3. Update the JSDoc to match the format in src/client.ts

Make these changes. Keep everything else the same."
```

### Knowing When to Push Back

AI can help you reason about feedback, but the decision to push back is yours:

```
"The reviewer suggests using a different approach: event emitters instead
of promises for timeout handling. The rest of the codebase uses promises
for async operations. Is the reviewer's suggestion consistent with the
project's patterns, or should I respectfully push back with a rationale?"
```

## Real Scenario: Contributing a Bug Fix

You have never seen this project before. Here is the full workflow.

**Step 1 -- Explore:**

```
"Explain this project's architecture. I'm looking at issue #891: 'CSV
parser fails on quoted fields containing newlines.' Where is the CSV
parsing code?"
```

AI points you to `src/parsers/csv.ts` and explains the parsing pipeline.

**Step 2 -- Understand the bug:**

```
"Read src/parsers/csv.ts and the test file for CSV parsing. Explain how
quoted fields are currently handled. The issue says newlines inside
quoted fields break the parser -- can you identify where the bug is?"
```

AI identifies that the parser splits on `\n` before handling quotes, so quoted newlines are treated as record separators.

**Step 3 -- Check contribution guidelines:**

```
"Read CONTRIBUTING.md. What's the branch naming convention, commit format,
and test requirements for a bug fix?"
```

**Step 4 -- Write the fix, matching style:**

```
"Fix the newline-in-quotes bug in src/parsers/csv.ts. Follow the existing
code style exactly. The fix should handle the quoting state before
splitting on newlines, not after."
```

**Step 5 -- Write tests, matching patterns:**

```
"Add tests for this fix in the existing test file. Follow the exact test
structure used for other CSV edge cases. Include: a quoted field with a
single newline, a quoted field with multiple newlines, and a quoted field
with a newline at the start/end."
```

**Step 6 -- Run CI locally:**

```
"What commands does CI run? I want to verify everything passes locally."
```

**Step 7 -- Draft the PR:**

```
"Write the commit message and PR description for this fix. Follow the
project's conventions. Reference issue #891."
```

**Step 8 -- Submit and respond to feedback directly.** Thank the maintainer. Be concise and respectful in your responses.

## Etiquette: What AI Helps With vs. What You Must Do Yourself

### AI Can Help With

- **Code:** Writing, testing, and refactoring to match project patterns
- **Tests:** Generating test cases that follow the project's framework and style
- **Documentation:** Drafting docstrings, updating README sections, writing examples
- **Understanding:** Explaining unfamiliar code, frameworks, and patterns
- **Style matching:** Adapting your code to fit the project's conventions
- **CI debugging:** Understanding why a pipeline failed and how to fix it

### You Must Do Yourself

- **Communication:** Write your own issue comments and PR descriptions in your own voice. Maintainers can spot AI-generated communication and it comes across as impersonal.
- **Design discussions:** If a maintainer asks "why did you choose this approach?", answer from your understanding. Do not paste an AI-generated rationale.
- **Commit to follow-through:** If you open a PR, respond to feedback promptly. AI cannot do this for you.
- **Respect project norms:** If the project says "no AI-generated code," respect that. Some projects have explicit policies.
- **Attribution:** If your project or the upstream project requires it, use `Co-Authored-By` in your commits to indicate AI assistance. Be transparent.
- **Judgment calls:** When a maintainer and the AI disagree, side with the maintainer. They know their project better.

## CLAUDE.md for Open Source Contributions

When contributing to a new project, create a temporary working note:

```markdown
# Project context (contributing to <project-name>)

## Conventions discovered
- Commit format: Conventional Commits (feat:, fix:, chore:)
- Branch naming: <type>/<issue-number>-<short-description>
- Tests: Vitest, co-located with source (file.test.ts next to file.ts)
- Error handling: custom AppError class, never throw raw Error

## My current task
- Issue #891: CSV parser fails on quoted fields with newlines
- Files to change: src/parsers/csv.ts, test/parsers/csv.test.ts
- Approach: handle quoting state before line splitting

## Style rules
- No default exports
- Prefer `interface` over `type` for object shapes
- Use `readonly` on function parameters
- 2-space indentation, no semicolons
```

This anchors the AI to the project's specific patterns for the duration of your contribution.

## Next Steps

- [Code Review](../02-workflows/code-review.md) -- Reviewing code before submission
- [Git Workflows](../02-workflows/git-workflows.md) -- Managing branches and commits for contributions
- [Pair Programming](pair-programming.md) -- Using AI as a pairing partner for complex contributions
