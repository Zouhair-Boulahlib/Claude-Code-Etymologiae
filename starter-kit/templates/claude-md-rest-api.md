# CLAUDE.md — REST API Project

## Project
[PROJECT_NAME] — REST API built with [FRAMEWORK].
[Brief description of what it does, 1-2 sentences.]

## Tech Stack
- Language: [Java 21 / TypeScript / Python 3.12]
- Framework: [Spring Boot 3.x / Express / FastAPI]
- Database: [PostgreSQL / MySQL / MongoDB]
- ORM: [JPA/Hibernate / Prisma / SQLAlchemy]
- Testing: [JUnit 5 / Vitest / pytest]

## Commands
- `[build command]` — build the project
- `[test command]` — run all tests
- `[lint command]` — run linter
- `[dev command]` — start dev server
- `[migrate command]` — run database migrations

## Architecture
- Follow [hexagonal / layered / clean] architecture
- Controller → Service → Repository pattern
- DTOs for API boundaries, entities for persistence
- All business logic lives in the service layer

## API Conventions
- RESTful resource naming: plural nouns, kebab-case
- Consistent error responses: { error: string, code: string, details?: object }
- Pagination: cursor-based for lists, offset for admin views
- Versioning: URL prefix /api/v1/
- All endpoints require authentication except /health and /auth/*

## Code Conventions
- [Add 3-5 specific rules for your project]
- No business logic in controllers
- All database queries use parameterized statements
- Return Result types in services, don't throw exceptions for business errors
- Validate all input at the API boundary

## Do NOT
- Use raw SQL string concatenation
- Add new dependencies without checking existing ones first
- Modify migration files that have already been applied
- Skip writing tests for new endpoints
