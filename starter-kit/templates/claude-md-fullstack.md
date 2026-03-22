# CLAUDE.md — Fullstack Project

## Project
[PROJECT_NAME] — Fullstack application with [backend framework] API and [frontend framework] client.
[Brief description.]

## Tech Stack
### Backend (packages/api or server/)
- [Java / TypeScript / Python] with [Spring Boot / Express / FastAPI]
- Database: [PostgreSQL] with [JPA / Prisma / SQLAlchemy]
- Auth: [JWT / OAuth2 / Session-based]

### Frontend (packages/web or client/)
- [React / Next.js / Vue] with TypeScript
- [Tailwind CSS] for styling
- [React Query / SWR] for server state

## Commands
### Backend
- `cd server && [build command]`
- `cd server && [test command]`
- `cd server && [dev command]`

### Frontend
- `cd client && npm run dev`
- `cd client && npm run test`
- `cd client && npm run build`

### Both
- `docker-compose up` — start full stack locally
- `[monorepo tool] run test` — run all tests

## Architecture
- Backend owns all business logic and validation
- Frontend is a thin client — no business logic
- Shared types in packages/shared/ or generated from API schema
- API contract defined in [OpenAPI spec / GraphQL schema / tRPC router]

## Code Conventions
- Backend and frontend follow their own conventions (see respective CLAUDE.md if they exist)
- API changes require updating the shared contract first
- Database migrations are versioned and reversible
- Environment variables documented in .env.example

## Do NOT
- Duplicate validation logic between frontend and backend
- Make direct database calls from API route handlers
- Commit .env files or secrets
- Modify shared types without checking both consumers
