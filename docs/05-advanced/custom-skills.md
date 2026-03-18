# Custom Skills -- Reusable Slash Commands

> Turn repetitive multi-step workflows into one-word commands that your whole team can use.

## What Are Skills?

Skills are slash commands that expand into full prompts. When you type `/review-pr` in Claude Code, the tool loads a skill file -- a markdown template with instructions, context, and optionally parameters -- and feeds it to Claude as if you had typed out the entire prompt yourself.

Think of skills as saved prompts with structure. Instead of remembering and retyping a 15-line prompt for reviewing pull requests, you define it once and invoke it with a slash command.

```
> /review-pr 142

# This expands to a full prompt like:
# "Review pull request #142. Check for security issues, test coverage,
#  naming conventions, error handling. Use our team's review checklist..."
```

---

## Where Skills Live

Skills are markdown files stored in specific directories. Claude Code searches for them in this order:

| Location | Scope | Shared via Git |
|----------|-------|----------------|
| `.claude/skills/` | Project | Yes -- team shares these |
| `~/.claude/skills/` | User | No -- personal only |

File naming convention:

```
.claude/skills/review-pr.md      -> /review-pr
.claude/skills/deploy.md         -> /deploy
.claude/skills/db-migrate.md     -> /db-migrate
.claude/skills/update-deps.md    -> /update-deps
```

The filename (minus `.md`) becomes the slash command.

---

## Skill File Format

A skill file is a markdown document. At its simplest, it is just the prompt text:

```markdown
Review the current git diff for the staged changes. Check for:
- Security vulnerabilities (SQL injection, XSS, secrets in code)
- Error handling gaps (missing try/catch, unhandled promise rejections)
- Test coverage (are new code paths tested?)
- Naming conventions (do names match our project style?)
- Performance concerns (N+1 queries, unnecessary loops)

Summarize findings as a bulleted list. Flag critical issues first.
```

### Adding Metadata

You can include a YAML frontmatter block for parameters and descriptions:

```markdown
---
description: Review a pull request by number
arguments:
  - name: pr_number
    description: The PR number to review
    required: true
---

Fetch pull request #$pr_number using `gh pr view $pr_number` and `gh pr diff $pr_number`.

Review the changes for:
- Security vulnerabilities
- Error handling gaps
- Test coverage
- Naming convention violations
- Performance concerns

Then check the CI status with `gh pr checks $pr_number`.

Provide a structured review with:
1. Summary of changes (2-3 sentences)
2. Critical issues (must fix before merge)
3. Suggestions (nice to have)
4. Verdict: APPROVE, REQUEST_CHANGES, or COMMENT
```

### Parameter Substitution

Arguments defined in frontmatter are substituted using `$argument_name` syntax in the prompt body. When you run `/review-pr 142`, the `$pr_number` placeholder is replaced with `142`.

Multiple parameters work positionally:

```markdown
---
arguments:
  - name: environment
    description: Target environment (staging, production)
    required: true
  - name: version
    description: Version tag to deploy
    required: false
---
```

Invoked as: `/deploy staging v2.3.1`

---

## Building Real Skills: Step by Step

### Skill 1: /review-pr -- Pull Request Reviewer

Create `.claude/skills/review-pr.md`:

```markdown
---
description: Comprehensive pull request review
arguments:
  - name: pr_number
    description: PR number to review
    required: true
---

Perform a thorough code review of PR #$pr_number.

Step 1: Gather context
- Run `gh pr view $pr_number` to get the PR description
- Run `gh pr diff $pr_number` to get the full diff
- Run `gh pr checks $pr_number` to see CI status

Step 2: Analyze the changes
For each file changed, evaluate:
- Does the change do what the PR description says?
- Are there security issues (injection, auth bypass, data exposure)?
- Is error handling complete (edge cases, null checks, async errors)?
- Are there tests for new behavior? Are existing tests updated?
- Does the code follow the conventions in CLAUDE.md?
- Any performance implications (queries in loops, large allocations)?

Step 3: Produce the review
Format your review as:

### Summary
One paragraph describing what this PR does.

### Issues Found
- **[CRITICAL]** Issues that must be fixed
- **[WARNING]** Issues that should be addressed
- **[NIT]** Minor suggestions

### Verdict
State APPROVE, REQUEST_CHANGES, or COMMENT with justification.
```

Usage:

```
> /review-pr 142
```

### Skill 2: /deploy -- Deployment Workflow

Create `.claude/skills/deploy.md`:

```markdown
---
description: Deploy to a target environment with safety checks
arguments:
  - name: environment
    description: Target environment (staging or production)
    required: true
---

Deploy the current branch to $environment. Follow these steps strictly.

Step 1: Pre-flight checks
- Run `git status` -- abort if there are uncommitted changes
- Run `npm test` -- abort if any tests fail
- Run `npm run lint` -- abort if there are lint errors
- Run `npm run build` -- abort if the build fails
- Confirm the current branch: for production, it must be `main`

Step 2: Version check
- Read the current version from `package.json`
- Run `git log --oneline -5` to show recent commits
- Show what will be deployed (version + last 5 commits)

Step 3: Deploy
- If $environment is "staging": run `npm run deploy:staging`
- If $environment is "production": run `npm run deploy:production`
- If $environment is anything else: abort with an error

Step 4: Verify
- Wait 10 seconds, then run `npm run healthcheck:$environment`
- Report success or failure with the healthcheck output

If any step fails, stop immediately and report what went wrong.
Do not proceed to the next step after a failure.
```

Usage:

```
> /deploy staging
> /deploy production
```

### Skill 3: /db-migrate -- Database Migration Helper

Create `.claude/skills/db-migrate.md`:

```markdown
---
description: Create and run a database migration
arguments:
  - name: description
    description: What the migration does (e.g., "add-user-preferences-table")
    required: true
---

Create a database migration for: $description

Step 1: Generate the migration file
- Run `npx knex migrate:make $description` (or the equivalent command for this project's migration tool)
- Read the generated file to confirm the path

Step 2: Write the migration
- Based on the description "$description", write the appropriate up and down migrations
- Follow existing migration patterns -- read the most recent migration file in the migrations directory for style reference
- Include proper error handling and transactions where appropriate
- The down migration must fully reverse the up migration

Step 3: Validate
- Run `npx knex migrate:latest --dry-run` if supported, or review the SQL that would be generated
- Check for issues: missing indexes on foreign keys, overly broad column types, missing NOT NULL constraints

Step 4: Run it (on dev only)
- Run `npx knex migrate:latest`
- Show the result
- Run `npx knex migrate:status` to confirm the migration was applied

Do NOT run migrations against staging or production. This is for local development only.
```

Usage:

```
> /db-migrate add-user-preferences-table
```

### Skill 4: /update-deps -- Dependency Update Workflow

Create `.claude/skills/update-deps.md`:

```markdown
---
description: Check and update project dependencies safely
arguments:
  - name: scope
    description: "all" for everything, or a package name for a specific dependency
    required: false
---

Update project dependencies safely.

Step 1: Audit current state
- Run `npm outdated` to see what needs updating
- Run `npm audit` to check for known vulnerabilities
- If scope is specified and not "all", focus only on that package

Step 2: Categorize updates
Group the outdated packages into:
- **Patch updates** (1.2.3 -> 1.2.4) -- safe, bug fixes only
- **Minor updates** (1.2.3 -> 1.3.0) -- usually safe, new features
- **Major updates** (1.2.3 -> 2.0.0) -- breaking changes likely

Step 3: Apply updates
- Apply all patch updates: `npm update`
- For minor updates: update one at a time, run `npm test` after each
- For major updates: list them but do NOT apply them automatically. Show what changed in each major version (check the changelog if available)

Step 4: Verify
- Run `npm test` to confirm nothing broke
- Run `npm run build` to confirm the build still works
- Run `npm audit` again to see if vulnerabilities were resolved

Step 5: Report
Summarize:
- How many packages were updated
- Which major updates are pending (and why they need manual review)
- Whether any vulnerabilities remain
```

Usage:

```
> /update-deps
> /update-deps lodash
```

---

## Sharing Skills Across Your Team

The `.claude/skills/` directory sits inside your project and can be committed to git. This is the recommended approach:

```bash
mkdir -p .claude/skills
# Create your skill files
git add .claude/skills/
git commit -m "Add team Claude Code skills for PR review, deploy, and migrations"
```

When a team member clones the repo and runs Claude Code, the skills are available immediately. No extra setup.

### Conventions That Help

- **Name skills clearly**: `/deploy` not `/d`, `/review-pr` not `/rp`
- **Include descriptions**: The `description` field in frontmatter shows up when listing skills
- **Document required context**: If a skill assumes certain tools are installed (like `gh`, `knex`), say so at the top of the file
- **Keep skills focused**: One skill = one workflow. Do not combine deployment and migration into a single skill

---

## Skills vs. Hooks vs. CLAUDE.md

These three mechanisms overlap. Here is when to use each:

| Mechanism | Trigger | Best For |
|-----------|---------|----------|
| **Skills** | Manual -- user types a slash command | Multi-step workflows invoked on demand |
| **Hooks** | Automatic -- fires on tool events | Enforcement and formatting that should always happen |
| **CLAUDE.md** | Passive -- loaded into every conversation | Persistent context, conventions, preferences |

**Concrete examples:**

- "Always run Prettier after writing files" -- **Hook**. It should happen every time, without the user thinking about it.
- "When I ask for a PR review, follow this 4-step process" -- **Skill**. It is a workflow the user triggers intentionally.
- "We use camelCase for variables and PascalCase for components" -- **CLAUDE.md**. It is a convention that applies to all work, always.

**They compose well together.** A skill might trigger file writes, which fire a PostToolUse hook for formatting, and both operate within the conventions defined in CLAUDE.md.

---

## Tips for Effective Skills

**Be explicit about steps.** Claude follows numbered steps more reliably than vague instructions. "Step 1: Run X. Step 2: Read the output. Step 3: Based on the output, do Y" works better than "Run X and then handle it appropriately."

**Include abort conditions.** Tell Claude when to stop. "If tests fail, stop immediately and report the failure" prevents it from plowing ahead after an error.

**Reference project tools by name.** Use `npm test` not "run the tests." Use `gh pr view` not "check the PR." Specificity reduces ambiguity.

**Test your skills.** Run them a few times. Refine the wording based on what Claude actually does. Skills are prompts -- they benefit from the same iterative improvement as any other prompt.

**Keep them under 50 lines.** A skill that is 200 lines long is trying to do too much. Break it into multiple skills or move stable instructions into CLAUDE.md.

## Next Steps

- [Hooks & Automation](hooks.md) -- Add automatic behavior that complements your skills
- [MCP Servers](mcp-servers.md) -- Give your skills access to databases, APIs, and external tools
- [Effective Prompting](../03-prompts/effective-prompting.md) -- The same principles that make good prompts make good skills
