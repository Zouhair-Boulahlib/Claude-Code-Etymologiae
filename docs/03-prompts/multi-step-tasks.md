# Multi-Step Tasks

> Break complex work into manageable pieces so each step is reviewable, testable, and reversible.

## Why Decomposition Matters

A single prompt that says "add authentication to the API" will produce something. It might even work. But it will be a monolithic blob of code that is hard to review, hard to test, and hard to revert if one part is wrong.

Decomposition gives you:
- **Reviewable diffs** -- each step is small enough to read carefully
- **Checkpoint commits** -- if step 4 goes wrong, you roll back to step 3, not step 0
- **Better AI output** -- focused tasks get more accurate results than sprawling ones
- **Cleaner context** -- each step can start with fresh or compacted context

## The Plan-Then-Execute Pattern

The most reliable pattern for multi-step work: make the AI plan first, then execute each step separately.

### Step 1: Ask for a plan

```
"I need to add JWT authentication to the REST API. The API is in src/api/
and uses Express. Don't write any code yet -- just give me a numbered plan
of the changes needed, with specific files for each step."
```

The AI responds with something like:

```
1. Add dependencies: jsonwebtoken, bcryptjs
2. Create src/db/entities/user.ts -- User entity with email, passwordHash, role
3. Create src/services/auth.ts -- register, login, verifyToken functions
4. Create src/api/middleware/auth.ts -- JWT verification middleware
5. Create src/api/routes/auth.ts -- POST /register, POST /login, POST /refresh
6. Add auth middleware to protected routes in src/api/routes/products.ts and orders.ts
7. Add tests for each new module
```

### Step 2: Review and adjust the plan

Before executing anything, validate the plan:

```
"Good plan. Changes:
- Skip step 1, I'll add dependencies manually
- In step 2, use Drizzle ORM -- follow the pattern in src/db/entities/product.ts
- In step 5, skip /refresh for now, we'll add it later
- Do step 7 alongside each step, not at the end

Start with step 2."
```

### Step 3: Execute one step at a time

```
"Step 2: Create the User entity in src/db/entities/user.ts.
Fields: id (uuid), email (unique), passwordHash, role (enum: admin, user),
createdAt, updatedAt. Follow the Drizzle pattern in src/db/entities/product.ts.
Include a test file."
```

Review, test, commit. Then:

```
"Step 3: Create src/services/auth.ts with register and login functions.
Use bcryptjs for password hashing, jsonwebtoken for JWT.
The register function should check for existing users by email.
The login function should return { token, user } on success.
Include unit tests."
```

Review, test, commit. Continue through the plan.

## Using Plan Mode

Claude Code has a built-in plan mode -- activated with `Shift+Tab` to toggle between plan and act modes. In plan mode, the AI analyzes and plans without making changes. In act mode, it executes.

**When to use plan mode:**
- At the start of a multi-step task, to get the decomposition right
- When you are unsure about the approach and want to see options
- Before touching unfamiliar code -- let the AI map out the impact
- When the task involves multiple files and you want to understand the scope

**When to skip plan mode:**
- Simple, single-file changes
- Tasks where you already know exactly what to do
- Follow-up steps in an already-planned sequence

## Checkpoint Commits Between Steps

Every completed step should be committed before starting the next one. This is not optional -- it is the safety net that makes the whole approach work.

```bash
# After each step:
# 1. Review the diff
# 2. Run tests
# 3. Commit

git add src/db/entities/user.ts src/db/entities/__tests__/user.test.ts
git commit -m "Add User entity with Drizzle ORM schema and tests"
```

Or ask Claude Code to do it:

```
"Run the tests for the new user entity. If they pass, commit the changes
with message 'Add User entity with Drizzle ORM schema and tests'."
```

**Why this matters:**

```
Without checkpoints:
  Step 1 (works) -> Step 2 (works) -> Step 3 (works) -> Step 4 (breaks everything)
  Result: revert ALL changes, start over

With checkpoints:
  Step 1 (commit) -> Step 2 (commit) -> Step 3 (commit) -> Step 4 (breaks)
  Result: git reset to step 3, retry just step 4
```

## Handing Off Context Between Conversations

When a task spans multiple conversations -- because context fills up or you take a break -- you need a way to carry over the relevant state.

### Method 1: The Summary Prompt

At the end of a conversation:

```
"Summarize the current state of the auth implementation. List: what's done,
what files were created/modified, what's left to do, and any decisions we made.
Format it so I can paste it into a new conversation."
```

Save the output. In the next conversation:

```
"Continuing work on JWT auth. Here's where we left off:

Done:
- User entity: src/db/entities/user.ts (committed)
- Auth service: src/services/auth.ts (committed)
- Auth middleware: src/api/middleware/auth.ts (committed)

Decisions:
- Using HS256 for JWT signing
- Tokens expire in 1 hour
- No refresh tokens yet

Remaining:
- Auth routes (POST /register, POST /login)
- Apply auth middleware to protected routes
- Tests for routes

Start with the auth routes."
```

### Method 2: The CLAUDE.md Breadcrumb

Add a temporary section to your CLAUDE.md:

```markdown
## In Progress: JWT Auth
Status: Steps 1-4 of 7 complete
Files created: src/db/entities/user.ts, src/services/auth.ts,
  src/api/middleware/auth.ts
Decisions: HS256 signing, 1hr expiry, no refresh tokens yet
Next: Auth routes in src/api/routes/auth.ts
```

This loads automatically in every new conversation. Delete it when the task is done.

### Method 3: The Git Log

If each step was committed with a clear message, the git log is your context:

```
"I'm adding JWT auth to the API. Check the last 4 commits to see what's
been done. Continue with the auth routes -- POST /register and POST /login
in src/api/routes/auth.ts."
```

The AI reads the commit log and diffs to reconstruct context from the code itself. This is the most robust method because it relies on the source of truth -- the actual code.

## Subagents vs Sequential Prompts

Claude Code can spawn subagents (via the Agent tool) that run in isolated contexts. Knowing when to let the AI use them vs. doing sequential prompts yourself matters.

### Let the AI use subagents for:
- **Research tasks** -- "Find all places where we handle authentication errors" scans many files in a subcontext, returns a concise summary
- **Large-scale analysis** -- "Check all API endpoints for consistent error handling" requires reading many files but the full contents do not need to stay in your main context
- **Pattern verification** -- "Verify that all routes in src/api/routes/ use the auth middleware" benefits from isolated scanning

### Use sequential prompts yourself for:
- **Build tasks** -- each step produces code you need to review, so it should be in your main context
- **Tasks with dependencies** -- step 2 depends on what step 1 actually produced
- **Tasks requiring your judgment** -- you need to see and approve intermediate results
- **Debugging** -- you need the full trail of what was tried and what happened

### The practical rule

If the AI needs to **read a lot and return a little**, subagents are ideal. If you need to **see and approve the output**, keep it in the main context.

## Tracking Progress Across Steps

For tasks with more than 3-4 steps, track progress explicitly.

### Option 1: Numbered steps in the conversation

```
"We're on step 4 of 7 in the auth implementation plan.

Steps completed:
[x] 1. User entity
[x] 2. Auth service
[x] 3. Auth middleware
[ ] 4. Auth routes       <-- current
[ ] 5. Apply middleware to existing routes
[ ] 6. Integration tests
[ ] 7. Update API documentation

Step 4: Create POST /register and POST /login in src/api/routes/auth.ts."
```

### Option 2: A tracking file

For longer projects, use a plain text file:

```
"Create a file at docs/auth-progress.md tracking the auth implementation.
Mark steps 1-3 as done, step 4 as in-progress."
```

Then in subsequent conversations:

```
"Check docs/auth-progress.md and continue with the next incomplete step."
```

## Worked Example: Adding Authentication to the API

Here is the full decomposition and execution of a real-world task. This is how the conversation flow actually looks.

### The initial prompt

```
"I need to add JWT authentication to our Express API. The API code is in
src/api/. Currently there's no auth at all -- all endpoints are public.

Don't write code yet. Give me a step-by-step plan."
```

### The plan (AI output, reviewed and adjusted)

```
1. Create User model and migration
2. Build auth service (register, login, token verification)
3. Create auth middleware for protecting routes
4. Add auth routes (register, login)
5. Apply middleware to existing protected routes
6. Add tests for all new code
```

Adjusted: tests will be written alongside each step, not as a separate step.

### Step 1 execution

```
"Step 1: Create a User entity in src/db/entities/user.ts using Drizzle ORM.
Follow the pattern in src/db/entities/product.ts.

Fields:
- id: uuid, primary key, auto-generated
- email: varchar(255), unique, not null
- passwordHash: varchar(255), not null
- role: enum('admin', 'user'), default 'user'
- createdAt: timestamp, default now
- updatedAt: timestamp, default now

Also create the migration file and a basic test that validates the schema."
```

Review the diff. Run `npm test`. Commit: `Add User entity with Drizzle schema and migration`.

### Step 2 execution

```
/compact focus on auth implementation -- User entity is done and committed

"Step 2: Create src/services/auth.ts with these functions:

- register(email, password): hash password with bcryptjs, create user, return user (no password)
- login(email, password): verify credentials, return { token: JWT, user: sanitized }
- verifyToken(token): decode and verify JWT, return payload or throw

Use jsonwebtoken. Secret from process.env.JWT_SECRET. Token expiry: 1 hour.
Include unit tests in src/services/__tests__/auth.test.ts. Mock the database calls."
```

Review. Test. Commit: `Add auth service with register, login, and token verification`.

### Step 3 execution

```
"Step 3: Create src/api/middleware/auth.ts.

The middleware should:
- Extract Bearer token from Authorization header
- Verify it using the verifyToken function from src/services/auth.ts
- Attach the decoded user to req.user
- Return 401 with { error: 'Unauthorized' } if no token or invalid token
- Return 403 with { error: 'Forbidden' } for valid token but insufficient role

Export two middlewares:
- requireAuth -- just requires a valid token
- requireRole(role) -- requires valid token AND specific role

Include tests that use supertest with a minimal Express app."
```

Review. Test. Commit: `Add auth middleware with role-based access control`.

### Step 4 execution

```
/compact focus on auth -- models, service, middleware are done

"Step 4: Create src/api/routes/auth.ts with:

POST /auth/register
- Body: { email, password }
- Validate: email format, password min 8 chars
- Returns: 201 with { user } on success, 409 if email exists, 400 if validation fails

POST /auth/login
- Body: { email, password }
- Returns: 200 with { token, user } on success, 401 if credentials wrong

Register the routes in src/api/index.ts.
Include integration tests using supertest."
```

Review. Test. Commit: `Add auth routes for register and login`.

### Step 5 execution

```
"Step 5: Apply the requireAuth middleware to all routes in:
- src/api/routes/products.ts (all routes)
- src/api/routes/orders.ts (all routes)

The auth routes themselves should remain public.
Update existing tests to include auth headers -- generate a valid test token
using a shared test helper."
```

Review. Test. Commit: `Apply auth middleware to product and order routes`.

**Total: 5 focused conversations or conversation phases, 5 clean commits, fully reviewable at every step.**

## When NOT to Decompose

Not everything benefits from multi-step planning:

- **Simple bug fixes** -- "fix the null check in src/utils/format.ts" is one step
- **Small features** -- "add a /health endpoint" is one step
- **Refactors with clear scope** -- "rename UserDTO to UserResponse across the codebase" is one step
- **Documentation updates** -- usually one step unless it is a massive overhaul

The overhead of planning and checkpointing is only worth it when the task has enough complexity to go wrong. If you can review the entire diff in under 2 minutes, it is probably a single-step task.

## Common Decomposition Mistakes

**Steps too large:** "Build the entire backend" is not a step. If you cannot review the diff in 5 minutes, the step is too big.

**Steps too small:** "Create the file. Now add the import. Now add the function signature." This wastes context on trivial round-trips. A step should produce a meaningful, testable unit of work.

**Wrong order:** Building the API routes before the service layer means the routes have nothing to call. Decompose bottom-up: data layer, then service layer, then API layer, then integration.

**Skipping tests:** "I'll add tests at the end" is the same trap as the God Prompt. Test each step. If a step is hard to test in isolation, the decomposition might be wrong.

## Next Steps

- [Context Management](context-management.md) -- Manage context across long multi-step sessions
- [Prompt Patterns](prompt-patterns.md) -- Templates for common step types
- [Effective Prompting](effective-prompting.md) -- Write better prompts for each step
