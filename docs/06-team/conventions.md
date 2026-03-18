# Team Conventions

Using Claude Code as an individual is straightforward. Using it across a team
requires agreements -- on how you configure it, when you use it, and how you
review what it produces. Without conventions, you get inconsistent output,
duplicated effort, and eroded trust in AI-assisted code.

## Standardizing CLAUDE.md

The `CLAUDE.md` file is the single most impactful lever for consistent AI behavior
across a team. Commit it to the repo root. Treat it like you treat your linter
config -- everyone uses the same one.

### What Belongs in a Team CLAUDE.md

```markdown
# Project: Acme API

## Architecture
- Monorepo: packages/api, packages/web, packages/shared
- API: Express + TypeScript, deployed on AWS ECS
- Web: Next.js 14, App Router, deployed on Vercel
- Database: PostgreSQL via Prisma ORM

## Code Standards
- TypeScript strict mode everywhere, no `any` without a comment justifying it
- Use named exports, not default exports
- Error handling: use Result<T, E> pattern from packages/shared/result.ts
- Tests: colocated with source files as *.test.ts, use vitest
- API routes: always validate input with zod schemas in packages/api/src/schemas/

## Naming
- Files: kebab-case (user-service.ts, not userService.ts)
- Types/Interfaces: PascalCase, no I prefix
- Database columns: snake_case
- API responses: camelCase

## Patterns to Follow
- See packages/api/src/routes/users.ts for the canonical route pattern
- See packages/api/src/services/user-service.ts for the service layer pattern
- See packages/web/src/app/dashboard/page.tsx for page component pattern

## Do Not
- Do not add new npm dependencies without discussing in PR
- Do not use console.log for logging -- use the logger from packages/shared/logger
- Do not write raw SQL -- use Prisma
- Do not put business logic in route handlers -- delegate to services
```

### Nested CLAUDE.md Files

Use directory-level `CLAUDE.md` files for subsystem-specific context.

```
repo/
  CLAUDE.md                  # Global conventions
  packages/api/CLAUDE.md     # API-specific patterns
  packages/web/CLAUDE.md     # Frontend-specific patterns
  packages/shared/CLAUDE.md  # Shared library conventions
```

A package-level CLAUDE.md might say:

```markdown
# packages/api

This package handles all HTTP API logic.

## Testing
- Every route file needs a corresponding test file
- Use supertest for integration tests
- Mock external services, never call them in tests
- Test fixtures live in __fixtures__/ directories

## Adding a New Endpoint
1. Add zod schema in src/schemas/
2. Add service method in src/services/
3. Add route handler in src/routes/
4. Add tests for validation, happy path, and error cases
```

## Shared Settings

The `.claude/settings.json` file controls Claude Code behavior. For team-wide
consistency, commit a project-level settings file.

```json
{
  "permissions": {
    "allow": [
      "Read(*)",
      "Write(docs/**)",
      "Bash(npm test*)",
      "Bash(npm run lint*)",
      "Bash(npx prisma*)"
    ],
    "deny": [
      "Bash(rm -rf*)",
      "Bash(git push --force*)",
      "Bash(npx prisma migrate deploy*)"
    ]
  }
}
```

This ensures everyone has the same guardrails. Developers can still have personal
settings in `~/.claude/settings.json` for preferences that do not affect the team.

## Prompt Libraries

Teams that use Claude Code heavily develop recurring prompts. Do not let these
live in individual chat histories -- formalize them.

### Create a Prompts Directory

```
repo/
  .claude/
    prompts/
      new-endpoint.md
      write-tests.md
      review-pr.md
      debug-performance.md
```

Example prompt file:

```markdown
<!-- .claude/prompts/new-endpoint.md -->
# New API Endpoint

Create a new API endpoint with the following:

Endpoint: [METHOD] [PATH]
Purpose: [DESCRIPTION]

Follow the pattern in packages/api/src/routes/users.ts exactly.

Checklist:
- [ ] Zod input schema in src/schemas/
- [ ] Service method in src/services/
- [ ] Route handler in src/routes/
- [ ] Register route in src/routes/index.ts
- [ ] Tests: validation, happy path, auth, error cases
- [ ] Update API docs if they exist
```

Developers load these with `/user:new-endpoint` or simply paste the template.

## Code Review Standards for AI-Generated Code

AI-generated code needs review, just like human-written code. But the failure
modes are different. Establish team norms.

### What to Watch For

1. **Plausible but wrong logic.** AI code often looks correct at first glance.
   Trace the logic manually for non-trivial functions.
2. **Hallucinated APIs.** Claude may use methods or parameters that do not exist
   in the version of a library you are using. Verify imports and function calls.
3. **Missing edge cases.** AI tends toward the happy path. Check: what happens
   with null input, empty arrays, concurrent access, network failures?
4. **Over-engineering.** AI sometimes adds abstractions you did not ask for.
   If a simple function became a class hierarchy, push back.
5. **Security gaps.** See the [Security](./security.md) guide for details.

### Review Checklist

Add this to your PR template:

```markdown
## AI-Assisted Code Review

- [ ] I have read and understood all AI-generated changes
- [ ] Logic has been manually traced for correctness
- [ ] External API calls and library usage have been verified
- [ ] Edge cases and error paths are handled
- [ ] No unnecessary abstractions or over-engineering
- [ ] Tests cover the actual behavior, not just the happy path
- [ ] No hardcoded values that should be configurable
```

## When to Use AI -- Team Agreements

Not every task benefits from AI. Establish clear guidelines.

### Sample Team Agreement

```
TEAM AI USAGE AGREEMENT -- Acme Engineering
Last updated: 2026-01-15

WHEN TO USE CLAUDE CODE:
- Boilerplate generation (new endpoints, components, test scaffolds)
- Exploring unfamiliar parts of the codebase
- First-pass implementation of well-specified features
- Writing tests for existing code
- Debugging with stack traces and error logs
- Documentation and code comments
- Refactoring with clear before/after requirements

WHEN NOT TO USE CLAUDE CODE:
- Security-critical authentication/authorization logic (write by hand, review with AI)
- Database migration logic (too risky for automated generation)
- Performance-critical hot paths (AI does not profile; benchmark by hand)
- Architectural decisions (use AI to research, decide as a team)
- Incident response (understand the system yourself first)

REVIEW REQUIREMENTS:
- All AI-generated code must be reviewed by a human before merge
- PRs with >50% AI-generated code require review from a senior engineer
- AI-generated security-relevant code requires security team review
- The developer who prompted the AI is responsible for the output

ATTRIBUTION:
- No special labeling required for AI-assisted commits
- If a PR is substantially AI-generated, note it in the PR description
- Do not claim AI output as solely your own in performance reviews

COST:
- Individual API keys, tracked per developer
- Monthly budget: $50/developer for Sonnet, $100/developer for Opus
- CI usage billed to the team infrastructure budget
- Review monthly spend in team retros
```

## Onboarding New Team Members

When a new developer joins, include AI workflow orientation.

**Day 1:**
- Show them the project CLAUDE.md and explain its role
- Walk through `.claude/settings.json` and permission boundaries
- Share the prompt library and explain how to use it

**Week 1:**
- Pair on a task using Claude Code so they see the workflow in practice
- Have them complete a small feature using AI assistance
- Review their AI-generated PR with explicit feedback on review standards

**Ongoing:**
- Add useful prompts to the shared library as the team discovers them
- Update CLAUDE.md when patterns evolve
- Discuss AI workflow improvements in retros

## Measuring AI Impact

Track metrics, but do not obsess over them.

**Useful signals:**
- Time from issue creation to PR (before and after AI adoption)
- PR review turnaround time (does AI-generated code take longer to review?)
- Bug rate in AI-assisted vs manually-written code
- Developer satisfaction surveys (does AI make their work better or worse?)

**Misleading signals:**
- Lines of code produced (AI inflates this meaninglessly)
- Number of PRs per day (quantity is not quality)
- API spend in isolation (compare against developer time saved)

**How to track without overhead:**
- Tag AI-assisted PRs with a label
- Compare cycle time metrics month-over-month after adoption
- Run a quarterly survey (5 questions max)
- Review bug reports to see if AI-generated code is disproportionately represented

The goal is not to maximize AI usage. It is to use AI where it genuinely helps
and stay out of the way where it does not. Conventions make that possible at
team scale.
