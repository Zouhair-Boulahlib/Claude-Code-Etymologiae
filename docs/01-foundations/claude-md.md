# The CLAUDE.md File

> Your project's instruction manual. The single highest-leverage thing you can configure.

## What It Is

`CLAUDE.md` is a markdown file at your project root that gets loaded into every conversation automatically. It tells the AI everything it needs to know about your project that isn't obvious from the code itself.

Think of it as onboarding documentation for the most productive new hire you'll ever work with.

## Where It Lives

| File | Scope | Committed to Git? |
|------|-------|-------------------|
| `PROJECT_ROOT/CLAUDE.md` | Project-wide | Yes |
| `PROJECT_ROOT/src/CLAUDE.md` | Directory-specific | Yes |
| `~/.claude/CLAUDE.md` | All your projects | No |

Directory-specific files are loaded when working on files in that directory. Use them for module-specific conventions.

## What to Include

### 1. Project Overview (2-3 sentences)

```markdown
## Project
CallCenter is a cloud-based call center management platform.
Spring Boot 3.4 backend with hexagonal architecture, React/Electron frontend.
Multi-tenant SaaS with role-based access (Admin -> Manager -> Agent).
```

Don't over-explain. Just enough to establish context.

### 2. Development Commands

```markdown
## Commands
- `./mvnw spring-boot:run` — run backend
- `npm run dev` — run frontend
- `./mvnw test` — run all tests
- `./mvnw test -pl module-name` — run module tests
- `npm run lint` — lint frontend
```

This is critical. Without it, the AI has to guess how to build, test, and run your project.

### 3. Code Conventions

```markdown
## Conventions
- Use constructor injection, never field injection
- DTOs go in `core/models/dtos/`, entities in `core/models/entities/`
- All endpoints return ResponseEntity with standard error format
- Use `@Valid` on all controller method parameters
- Tests use @SpringBootTest for integration, @WebMvcTest for controller tests
```

Focus on conventions that **aren't obvious from the code**. If your style is standard for the framework, you don't need to document it.

### 4. Architecture Decisions

```markdown
## Architecture
- Hexagonal architecture: adapters/web, adapters/persistence, core/
- Ports defined as interfaces in core/ports/
- No direct JPA calls from controllers — always go through a port
- Soft delete on all entities (deletedAt field, never hard delete)
```

### 5. Things to Avoid

```markdown
## Do NOT
- Add new dependencies without discussing first
- Modify SecurityConfig without security review
- Use raw SQL — always use JPA repositories
- Create new REST endpoints without OpenAPI annotations
```

This section prevents common mistakes before they happen.

## Real-World Example

Here's a complete, production-tested CLAUDE.md:

```markdown
# CLAUDE.md

## Project
E-commerce platform. Node.js/Express backend, React frontend, PostgreSQL.
Monorepo with packages/api, packages/web, packages/shared.

## Commands
- `pnpm dev` — start all services
- `pnpm test` — run all tests
- `pnpm test:api` — backend tests only
- `pnpm db:migrate` — run pending migrations
- `pnpm db:seed` — seed development data

## Conventions
- TypeScript strict mode everywhere
- Zod schemas for all API input validation (packages/shared/schemas/)
- React Query for server state, Zustand for client state
- Tailwind CSS, no inline styles, no CSS modules
- Named exports only, no default exports
- Error responses follow RFC 7807 (Problem Details)

## Architecture
- packages/shared/ contains types and schemas used by both api and web
- API follows controller -> service -> repository pattern
- All database access through Drizzle ORM
- Background jobs use BullMQ with Redis

## Testing
- Unit tests: Vitest, co-located with source files (*.test.ts)
- Integration tests: packages/api/tests/integration/
- E2E: Playwright in packages/e2e/
- Minimum 80% coverage on new code

## Do NOT
- Use `any` type — always define proper types
- Add client-side state for data that comes from the API
- Create database migrations that aren't reversible
- Put business logic in controllers — it belongs in services
```

## Common Mistakes

### Too long
If your CLAUDE.md is over 100 lines, you're probably including things that should be in code comments or actual documentation. Keep it focused on what the AI needs to know **that it can't figure out from reading the code**.

### Too vague
```markdown
# Bad
## Conventions
Follow best practices. Keep code clean.

# Good
## Conventions
- Functions over 30 lines should be split
- All API errors return { error: string, code: string, details?: object }
- Use early returns, not nested if/else
```

### Missing commands
The number one most common omission. If the AI can't run your tests or start your dev server, half its usefulness is gone.

## Evolving Your CLAUDE.md

Start minimal. Add things as you notice the AI getting something wrong that context would fix:

1. AI uses wrong test framework? Add testing commands
2. AI creates files in wrong directory? Add architecture section
3. AI uses a pattern you've deprecated? Add "Do NOT" section
4. AI doesn't know about your deployment process? Add deployment notes

Your CLAUDE.md should grow organically from real friction, not from trying to anticipate every scenario.

## Next Steps

- [Effective Prompting](../03-prompts/effective-prompting.md) — Complement your CLAUDE.md with good prompts
- [Team Conventions](../06-team/conventions.md) — Standardize CLAUDE.md across your team
