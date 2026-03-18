# Git Workflows with AI Assistance

> Let AI handle the tedious parts of git -- commit messages, conflict resolution, PR descriptions -- so you can focus on the code.

## Commit Messages From Diffs

Writing good commit messages is important and boring. AI is good at both understanding diffs and writing structured prose.

### Basic Commit Message Generation

```
"Look at the staged changes and write a commit message. Follow conventional
commits format (feat/fix/refactor/docs/test). First line under 72 characters.
Add a body paragraph if the change needs explanation."
```

The AI reads the diff, understands what changed, and writes a message that describes why. This is consistently better than "fix stuff" or "update code."

### Using the /commit Skill

Claude Code has a built-in `/commit` skill that automates the entire flow:

```bash
# Stage your changes, then:
claude /commit
```

This stages, generates a message from the diff, and creates the commit. You review the message before it's finalized. For routine changes, this saves real time.

### Commit Message for Complex Changes

When the diff is large or touches multiple concerns:

```
"Review the staged diff. There are changes across three areas:
1. A bug fix in the payment flow
2. A new validation rule for email addresses
3. A test for the validation rule

Should this be one commit or multiple? If multiple, tell me what to
stage for each commit and write a message for each."
```

The AI will suggest splitting when appropriate and write targeted messages for each piece.

## PR Creation

### Generating PR Descriptions

After your branch is ready:

```
"Look at all commits on this branch since it diverged from main
(git log main..HEAD). Write a PR description with:
- A title under 70 characters
- A summary section with 2-3 bullet points explaining what and why
- A test plan section listing how to verify the changes
- A note about any migration steps or deployment considerations"
```

### Using gh CLI for PR Creation

```bash
# Create PR with AI-generated description
claude "Create a pull request from this branch to main. Review all the
commits, write a clear title and description, then use gh pr create
to submit it."
```

The AI will run `git log`, analyze the changes, draft the PR, and execute the `gh` command. You approve each step.

### PR Templates

If your repo has a PR template, point the AI to it:

```
"Create a PR using the template in .github/pull_request_template.md.
Fill in every section based on the actual changes in this branch.
Don't leave any section as TODO."
```

## Branch Management

### Creating Feature Branches

```
"Create a new branch from main called feat/add-user-preferences.
Make sure main is up to date first."
```

The AI runs `git fetch`, checks out main, pulls, then creates the branch. Simple but avoids the "forgot to pull main first" mistake.

### Cleaning Up Stale Branches

```
"List all local branches that have been merged into main. Show me the
list and the command to delete them, but don't delete anything yet."
```

Review the list, then:

```
"Delete all of those merged branches except 'staging'."
```

### Branch Comparison

```
"Compare this branch with main. How many commits ahead/behind are we?
Are there any files changed on main that we also changed -- potential
conflicts?"
```

This helps you decide whether to merge or rebase before opening a PR.

## Resolving Merge Conflicts

This is where AI assistance is genuinely transformative. Merge conflicts are tedious, error-prone, and often the place where bugs sneak in.

### Simple Conflict Resolution

```
"I have merge conflicts after rebasing onto main. Show me each conflict
and resolve them. For each one, explain which version you're keeping and why."
```

The "explain which version" part is critical -- you need to verify the AI made the right choice.

### Complex Conflict Resolution

When both sides made meaningful changes:

```
"There's a merge conflict in src/services/pricing.ts. Both branches
modified the calculateDiscount function:
- Main added support for percentage-based discounts
- This branch added support for tiered pricing

I need both changes. Merge them so that tiered pricing works with both
fixed and percentage discounts. Show me the merged result before applying it."
```

Give the AI context about intent. Without it, the AI has to guess which changes matter.

### Conflict Resolution Workflow

```bash
# Start the rebase
git rebase main

# When conflicts appear:
claude "Show me all current merge conflicts. For each one, explain what
both sides changed and suggest the correct resolution. Don't modify
files yet -- just show me your plan."

# Review the plan, then:
claude "Apply the conflict resolutions we discussed. After each file,
run git add on it."

# Continue the rebase
git rebase --continue
```

Always review the plan before letting the AI modify conflict markers. This two-step approach catches mistakes before they're committed.

## Rebasing

### Cleaning Up Commit History

```
"I have 7 commits on this branch. Three of them are 'fix typo' and
'address review feedback' type commits. Squash those into the main
commits they relate to. Show me the rebase plan before executing."
```

The AI will figure out which fixup commits belong to which feature commits and draft the rebase sequence.

### Rebase Onto Updated Main

```
"Rebase this branch onto the latest main. If there are conflicts,
show them to me one at a time with your suggested resolution."
```

## Cherry-Picking

### Selective Cherry-Pick

```
"I need to cherry-pick commit abc123 from the feature/payments branch
into the current hotfix branch. Check if it applies cleanly. If not,
show me what conflicts arise."
```

### Cherry-Pick a Fix to Multiple Branches

```
"Cherry-pick commit def456 (the XSS fix) into both release/2.1 and
release/2.0 branches. For each branch, check out the branch, cherry-pick,
and report whether it applied cleanly."
```

## Bisecting

AI makes `git bisect` much more practical by automating the test at each step.

### Automated Bisect

```
"The test 'should calculate tax correctly' passes on commit abc123
(last week) but fails on HEAD. Use git bisect to find which commit
introduced the failure. Run 'npm test -- --grep tax' at each step
to determine good/bad."
```

The AI runs the bisect loop, executing the test at each commit, until it identifies the offending change.

### Manual Bisect With AI Analysis

```
"Start a git bisect between v2.0.0 (good) and HEAD (bad). At each step,
instead of running a test, show me what changed in src/services/pricing.ts
in that commit so I can tell you if it's good or bad."
```

This is useful when the bug isn't captured by an automated test.

## Bulk Operations

### Updating Multiple Repos

```
"For each directory in ~/projects/ that is a git repo, run:
1. git fetch --all --prune
2. Report which repos have unpushed commits
3. Report which repos have uncommitted changes"
```

### Batch Branch Cleanup Across Repos

```
"In each git repo under ~/projects/microservices/, delete all local
branches that have been fully merged into main. Report what you deleted."
```

## Useful Git Inspection Prompts

### Understanding a Commit

```
"Explain what commit 7f3a2b1 does. Show the diff, summarize the changes,
and explain the likely motivation."
```

### File History Analysis

```
"Show the last 10 changes to src/services/auth.ts. For each commit,
give me a one-line summary of what changed and who changed it."
```

### Finding When Something Broke

```
"Search the git log for the commit that removed the validateEmail
function from src/utils.ts. Show me the commit message, author, and date."
```

### Blame With Context

```
"Run git blame on src/api/orders.ts lines 45-80. For each distinct author
and commit, summarize what that block of code does and when it was last
modified."
```

## Workflow Integration Patterns

### PR Review + Merge Workflow

```bash
# Review a PR
claude "Review PR #142 using gh pr diff 142. Summarize changes and flag concerns."

# After approval, merge cleanly
claude "Merge PR #142 using a squash merge. Use the PR title as the commit message."
```

### Release Tagging

```
"Create an annotated tag v2.3.0 on the current commit. For the tag message,
summarize all changes since v2.2.0 using the commit log. Group changes
by type (features, fixes, refactors)."
```

### Changelog Generation

```
"Generate a changelog entry for all commits between v2.2.0 and HEAD.
Format it as markdown with sections for Added, Changed, Fixed, and Removed.
Use the commit messages but rewrite them to be user-facing
(no internal jargon)."
```

## What to Watch Out For

- **Force pushes** -- AI will execute `git push --force` if you ask. Be explicit about when this is acceptable (your own feature branch) and when it is not (shared branches, main).
- **Rewriting shared history** -- Rebasing commits that others have based work on causes real pain. The AI won't warn you about this unless you ask.
- **Credential exposure** -- Be cautious about prompts that involve `.env` files, tokens, or keys. The AI will include them in commits if you stage them.
- **Large binary files** -- The AI won't warn you about committing large binaries that will bloat the repo permanently.

Always review the exact git commands the AI proposes before approving execution.

## Next Steps

- [Code Review](code-review.md) -- Reviewing changes before they're committed
- [Refactoring](refactoring.md) -- Restructuring code across branches
- [Effective Prompting](../03-prompts/effective-prompting.md) -- Writing better prompts for git operations
