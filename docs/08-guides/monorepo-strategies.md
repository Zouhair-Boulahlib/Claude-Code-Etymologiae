# Monorepo Strategies

> Managing AI context across multiple packages -- so it stops importing your React components into your API server.

## The Monorepo Context Problem

Monorepos are great for code sharing. They are terrible for AI context. When you open a monorepo with Claude Code, it sees everything -- every package, every config, every test. If your repo has `packages/api/` and `packages/web/`, the AI will happily import a React hook into your Express route handler because it found both in the file tree.

This is not a bug. It is a context problem. The AI treats the entire repository as one project unless you tell it otherwise.

## Directory-Specific CLAUDE.md Files

Place a CLAUDE.md in each package directory. Claude Code loads the nearest CLAUDE.md and merges it with parent CLAUDE.md files, giving you layered configuration.

### Root CLAUDE.md

```markdown
# Monorepo: acme-platform

## Structure
- packages/api -- Express REST API (Node.js, TypeScript)
- packages/web -- Next.js frontend (React, TypeScript)
- packages/shared -- Shared types and utilities (no framework deps)
- packages/workers -- Background job processors (Node.js)

## Rules
- NEVER import from a sibling package directly by file path
- Cross-package imports MUST go through the package's public API (index.ts)
- Only packages/shared may be imported by other packages
- packages/web must NEVER be imported by packages/api or packages/workers

## Commands
- Install: pnpm install (from root)
- Build all: pnpm build
- Test all: pnpm test
```

### packages/api/CLAUDE.md

```markdown
# API Package
- Express 4.x, TypeScript, Prisma ORM, PostgreSQL, Jest
- This is a backend package. No React, no browser APIs, no CSS.
- Import shared types from @acme/shared only
- Do not import from @acme/web -- ever
- Dev: pnpm --filter api dev
- Test: pnpm --filter api test
```

### packages/web/CLAUDE.md

```markdown
# Web Package
- Next.js 14 App Router, React 18, Tailwind, React Query
- This is a frontend package. No direct database access.
- API calls go through src/lib/api-client.ts -- never raw fetch()
- Do not import from @acme/api -- ever
- Dev: pnpm --filter web dev
- Test: pnpm --filter web test
```

### packages/shared/CLAUDE.md

```markdown
# Shared Package
- Zero framework dependencies. No React, no Express, no DB clients.
- Only pure TypeScript: types, interfaces, utility functions, constants
- Must work in both Node.js and browser environments
- Every export goes through src/index.ts
```

When the AI works on `packages/api/src/routes/users.ts`, it loads both root and API CLAUDE.md files. It knows the stack, the import rules, and where things live.

## .claudeignore Strategies

Use `.claudeignore` at the root to exclude noise the AI never needs:

```
node_modules/
dist/
.next/
coverage/
*.lock
packages/*/dist/
packages/*/.turbo/
```

For session-level scoping, use prompts (see next section). For persistent scoping, the CLAUDE.md rules in each package are the right tool.

## Scoping Prompts

Every prompt in a monorepo should specify which package. Unscoped prompts cause cross-package contamination.

**Bad:**

```
"Add a getUserById function."
```

AI does not know which package. It might create it in `packages/web/` with a Prisma import.

**Good:**

```
"In packages/api/src/services/userService.ts, add a getUserById function
that takes a string ID and returns a User via Prisma. Return null if not found."
```

**For cross-cutting work:**

```
"Add a 'user role' concept across the monorepo:
1. In packages/shared/src/types/user.ts -- add a UserRole enum (ADMIN, MEMBER, VIEWER)
2. In packages/api/src/services/userService.ts -- add role to user creation
3. In packages/web/src/components/RoleSelector.tsx -- create a role dropdown
Import UserRole from @acme/shared in both packages."
```

Numbering steps and specifying import paths removes ambiguity.

## Cross-Package Refactoring

Changing a shared type touches every consumer. Be explicit about blast radius.

### Shared Type Changes

```
"Rename User to UserProfile in packages/shared. Add a new UserSummary
with only id, name, email. Update every import across all packages --
use UserSummary for list views, UserProfile for detail views.
Show me every file changed before I approve."
```

### API Contract Changes

```
"GET /api/users/:id currently returns flat fields. Nest address fields
under an `address` property:
1. Update type in packages/shared/src/types/api.ts
2. Update API route in packages/api/src/routes/users.ts
3. Update all consumers in packages/web that access user.street, user.city
4. Update tests in both packages"
```

The instruction "show me every file changed" is essential for cross-package work.

## Build Tool Patterns

### Turborepo

```markdown
## Build system: Turborepo
- `turbo run build` builds in dependency order
- `turbo run test --filter=api` tests one package
- Cache is in .turbo/ -- do not commit or modify

## Dependency graph
- shared: no internal deps
- api: depends on shared
- web: depends on shared
- workers: depends on shared
```

### Nx

```markdown
## Build system: Nx
- `nx run api:build` builds one package
- `nx affected:test` tests only changed packages
- Config is in project.json, not package.json
- Do not modify nx.json unless I ask
```

### pnpm Workspaces

```markdown
## Package manager: pnpm
- pnpm-workspace.yaml defines structure
- Use `pnpm --filter <package>` for package-specific commands
- Cross-package deps use workspace:* protocol
- Do not use npm or yarn commands
```

Adding build tool context prevents a common AI mistake: generating `npm install` or `yarn workspace` commands in a pnpm project.

## CLAUDE.md Inheritance

Claude Code merges CLAUDE.md files from parent directories:

```
repo/
  CLAUDE.md                    <-- root rules (everywhere)
  packages/
    api/
      CLAUDE.md                <-- API rules (inherits root)
      src/
        routes/
          CLAUDE.md            <-- route rules (inherits root + api)
```

Use this hierarchy: root for project structure and global rules, package for stack specifics and import restrictions, subdirectory (rare) for area-specific conventions. You rarely need more than two levels.

## Real Scenario: The Cross-Package Import Disaster

A developer asks: "Add a utility function that formats user names."

The AI sees `packages/web/src/utils/format.ts` has formatting functions and `packages/api/` needs the formatter. It generates:

```typescript
// packages/api/src/services/userService.ts
import { formatUserName } from '../../../web/src/utils/format';
```

This import bypasses the package boundary, pulls React-dependent code into the API server, breaks the build, and creates a hidden dependency that Turborepo cannot track. The fix: put `formatUserName` in `packages/shared/` and import as `@acme/shared` in both packages.

After this incident, the developer added to root CLAUDE.md:

```markdown
## Import rules (CRITICAL)
- Cross-package imports MUST use the package name (@acme/shared)
- Relative imports traversing into a sibling package (../../web/) are ALWAYS wrong
- If a function is needed by multiple packages, it belongs in packages/shared
```

## When to Use Subagents

Monorepos are a natural fit for multi-agent workflows. Each package is an isolated unit.

```
"Add a 'team' concept. Run three subagents in parallel:
1. packages/shared: add Team and TeamMember types, TeamRole enum
2. packages/api: add team CRUD routes, teamService, Prisma schema
3. packages/web: add team management page at /teams
Each agent only touches its assigned package plus packages/shared."
```

This works because agents write to different directories. The shared types are the contract.

**Do not use subagents** when the change is small enough for one session, when one package depends on the specific implementation of another, or when debugging across package boundaries -- a single agent tracing the full flow is better than three seeing only their slice.

## The Meta-Pattern

Every monorepo strategy comes down to one principle: **scope the AI to one package at a time.** Root CLAUDE.md sets rules. Package CLAUDE.md sets context. Prompts set focus. All three layers keep the AI from treating your monorepo as one tangled project.

When in doubt, start your prompt with: "Working in packages/X. Only look at packages/X and packages/shared."

## Next Steps

- [Database Work](database-work.md) -- AI-assisted migrations and query optimization
- [Multi-Agent Workflows](../05-advanced/multi-agent.md) -- Deeper dive into subagent patterns
- [Project Setup](../04-architecture/project-setup.md) -- Structuring projects for AI-assisted development
