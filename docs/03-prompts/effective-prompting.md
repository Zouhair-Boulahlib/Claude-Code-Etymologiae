# Effective Prompting

> Write prompts that get results on the first try, not the third.

## The Core Principle

A good prompt answers three questions:
1. **What** do you want done?
2. **Where** in the code?
3. **Why** (what's the context or constraint)?

```
"Add input validation to the signup endpoint in src/api/auth.ts.
Email must be valid format, password minimum 8 chars with at least one number.
We're getting spam signups with garbage data."
```

All three questions answered. The AI knows what to build, where to put it, and what problem it solves.

## Prompt Patterns That Work

### The Specific Fix

```
The search bar in src/components/SearchBar.tsx doesn't debounce input.
When users type fast, it fires an API call per keystroke and overwhelms the backend.
Add a 300ms debounce using the existing lodash dependency.
```

Why it works: specific file, specific problem, specific solution, specific constraint.

### The Explain-Then-Fix

```
Explain what the retry logic in src/services/queue.ts does, then fix the bug
where failed jobs retry infinitely instead of stopping after 3 attempts.
```

Why it works: forces understanding before modification.

### The Constrained Implementation

```
Add a /health endpoint to the API that returns:
- HTTP 200 with { status: "ok", uptime: <seconds> } when healthy
- HTTP 503 with { status: "degraded", checks: [...] } when DB is unreachable

Constraints:
- Add it to src/api/routes/system.ts (create if needed)
- Don't add new dependencies
- Include a test in src/api/__tests__/health.test.ts
```

### The Scope-Limited Refactor

```
Extract the email sending logic from src/services/user.ts (lines 45-89)
into a new src/services/email.ts module. Keep the same interface.
Don't change any behavior, just move and re-export.
```

## Anti-Patterns

### The Vague Request
```
"make the code better" / "fix the tests" / "refactor this"
```
Better *how*? Fix *which* tests? Refactor *toward what*?

### The Kitchen Sink
Don't cram an entire sprint into one prompt. One feature at a time.

### The Premature Abstraction
You probably need a simple function, not an AbstractConfigProviderFactory.

## Iterative Prompting

Build incrementally:
```
Round 1: "Add a /users endpoint that returns all users"
Round 2: "Add pagination — default 20, max 100"
Round 3: "Add filtering by role and search by name"
Round 4: "Add rate limiting — 100 req/min per API key"
```

Each round builds on reviewed, working code.

## The Golden Rule

**If you'd need to explain it to a new team member, explain it to the AI.** If you'd assume a senior dev already knows it, the AI probably knows it too.

## Next Steps

- [Context Management](context-management.md) — Work within and around context limits
- [Multi-Step Tasks](multi-step-tasks.md) — Break complex work into manageable pieces
- [Prompt Patterns](prompt-patterns.md) — Reusable templates for common scenarios
