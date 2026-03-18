# Project Setup

> Structure your project so AI can navigate it as well as your best engineer.

## Why Structure Matters for AI

Claude Code reads your project to build context. A well-organized project means the AI finds what it needs fast and produces code that fits existing patterns. A messy project means the AI guesses -- and guesses wrong. The same prompt on a well-structured vs. poorly-structured project can be the difference between a one-shot implementation and three rounds of corrections.

## Directory Structures That AI Navigates Well

AI infers purpose from directory and file names. Generic names force it to open files to understand them. Specific names let it navigate by structure alone.

**Poor structure -- AI reads everything to understand anything:**

```
src/
  utils/
    helpers.ts          # What kind of helpers?
    misc.ts             # The junk drawer
  components/
    Component1.tsx      # Numbered components tell AI nothing
    Modal.tsx           # Which modal? For what feature?
  lib/
    api.ts              # One file for all API calls
```

**Good structure -- AI understands purpose from names alone:**

```
src/
  features/
    auth/
      LoginForm.tsx
      auth.service.ts
      auth.validators.ts
      auth.test.ts
    billing/
      InvoiceList.tsx
      billing.service.ts
      stripe.client.ts
  shared/
    components/
      Button.tsx
      DataTable.tsx
    utils/
      date-formatting.ts
      currency.ts
  api/
    routes/
      auth.routes.ts
      billing.routes.ts
    middleware/
      rate-limiter.ts
      auth-guard.ts
```

When you prompt "add email verification to the auth flow," the AI immediately knows to look in `src/features/auth/` and models its new files after the existing pattern.

**Feature-based beats layer-based.** Layer-based (all controllers together, all services together) forces AI to jump between distant directories. Feature-based keeps related code co-located, which means fewer files loaded and more relevant context.

## Naming Conventions That Help AI

Consistent suffixes act as a type system for your file structure:

```
*.service.ts    -- business logic
*.controller.ts -- request handling
*.repository.ts -- data access
*.test.ts       -- tests (co-located)
*.types.ts      -- type definitions
*.middleware.ts  -- middleware functions
*.schema.ts     -- validation schemas
```

When you say "create a service for notifications," the AI scans existing `*.service.ts` files, matches the pattern, and produces consistent code.

## Monorepo vs. Polyrepo

In a monorepo, Claude Code sees all packages at once -- powerful for cross-package changes but noisy. Use `.claudeignore` aggressively, and put `CLAUDE.md` files at multiple levels:

```
monorepo/
  CLAUDE.md              # "Monorepo with 3 packages. API is in packages/api..."
  packages/
    api/
      CLAUDE.md          # "Express API. Tests: pnpm --filter api test"
    web/
      CLAUDE.md          # "Next.js frontend. Dev: pnpm --filter web dev"
```

Polyrepos give clean, isolated context per service. The tradeoff: AI can't see across repo boundaries. If changes frequently span repos, a monorepo gives AI more useful context.

## Setting Up .claudeignore

Controls which files Claude Code loads into context. Uses gitignore syntax.

```
# .claudeignore
dist/
build/
.next/
coverage/
*.generated.ts
src/graphql/__generated__/
*.sql.bak
fixtures/large-dataset.json
node_modules/
vendor/
.env*
*.pem
*.key
```

The goal: only human-written source code, tests, and configuration. Every irrelevant file loaded wastes context window space that could hold useful code.

## Configuring Permissions in settings.json

Project-level settings in `.claude/settings.json` (committed to git for team sharing):

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run test)",
      "Bash(npm run test:*)",
      "Bash(npm run lint)",
      "Bash(npm run build)",
      "Bash(npx tsc --noEmit)"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(npm publish)",
      "Bash(git push *)"
    ]
  }
}
```

**Allow:** test runners, linters, type checkers, build commands -- things the AI runs repeatedly.
**Deny:** destructive operations, publishing, deployment -- things that need human approval.

## The Ideal Project Skeleton

```
project/
  CLAUDE.md                    # Project context for AI
  .claude/settings.json        # Shared team permissions
  .claudeignore                # Keep context clean
  src/
    features/
      [feature-name]/
        [Feature].tsx          # UI components
        [feature].service.ts   # Business logic
        [feature].types.ts     # Type definitions
        [feature].test.ts      # Co-located tests
    shared/
      components/              # Reusable UI
      hooks/                   # Reusable hooks
      utils/                   # Named by purpose, not "helpers"
    api/
      routes/                  # Route definitions
      middleware/              # Middleware functions
  tests/
    integration/               # Cross-feature tests
    e2e/                       # End-to-end tests
  scripts/
    seed-db.ts                 # Named by purpose
    migrate.ts
```

Every directory name answers "what's in here?" without opening a file. Every file name answers "what does this do?" without reading code.

## How Organization Affects AI Output

**1. Pattern matching.** If your services are consistently structured (`auth.service.ts`, `billing.service.ts`), new ones match. If they're all different, the AI picks one at random.

**2. Context efficiency.** A 500-line `utils.ts` gets loaded when the AI only needs one function. Five focused files mean only the relevant one loads.

**3. Change locality.** Related code together means smaller, more focused diffs. Scattered code means changes across many files, increasing review burden.

## Practical Checklist

Before starting AI-assisted work on a project:

- [ ] Create `CLAUDE.md` with project overview, tech stack, and common commands
- [ ] Create `.claudeignore` to exclude build artifacts and generated code
- [ ] Create `.claude/settings.json` with allowed test and lint commands
- [ ] Ensure directory and file names describe their contents and purpose
- [ ] Co-locate tests with source code
- [ ] Use consistent file naming conventions
- [ ] Remove or ignore dead code and junk-drawer files

None of these are AI-specific. They're good engineering practices that happen to make AI collaboration dramatically more effective.

## Next Steps

- [Testing Strategies](testing.md) -- Write and maintain tests with AI assistance
- [Documentation](documentation.md) -- Keep docs alive with AI help
- [The CLAUDE.md File](../01-foundations/claude-md.md) -- Deep dive into project configuration
