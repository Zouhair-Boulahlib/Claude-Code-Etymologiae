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

All three questions answered. The AI knows what to build, where to put it, and what problem it solves (which helps it make better edge-case decisions).

## Prompt Patterns That Work

### The Specific Fix

```
The search bar in src/components/SearchBar.tsx doesn't debounce input.
When users type fast, it fires an API call per keystroke and overwhelms the backend.
Add a 300ms debounce using the existing lodash dependency.
```

Why it works: specific file, specific problem, specific solution, specific constraint (use lodash, not a new dependency).

### The Explain-Then-Fix

```
Explain what the retry logic in src/services/queue.ts does, then fix the bug
where failed jobs retry infinitely instead of stopping after 3 attempts.
```

Why it works: forces the AI to build understanding before modifying code. Especially useful for code you didn't write.

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

Why it works: clear spec, clear constraints, clear file locations. No ambiguity.

### The Scope-Limited Refactor

```
Extract the email sending logic from src/services/user.ts (lines 45-89)
into a new src/services/email.ts module. Keep the same interface —
the callers in user.ts should just import from the new location.
Don't change any behavior, just move and re-export.
```

Why it works: explicit scope, explicit constraint ("don't change behavior"), explicit expectation about the result.

## Anti-Patterns

### The Vague Request

```
❌ "make the code better"
❌ "fix the tests"
❌ "refactor this"
```

Better → always better *how*? Fix *which* tests? Refactor *toward what*?

### The Kitchen Sink

```
❌ "Add authentication, set up the database, create the user model,
    add email verification, implement password reset, add OAuth,
    set up rate limiting, and add CSRF protection"
```

This isn't a prompt, it's a sprint backlog. Break it into individual tasks.

### The Premature Abstraction

```
❌ "Create a generic, extensible, plugin-based validation framework
    that supports custom rules, async validators, and i18n error messages"
```

You probably need `if (!email.includes('@')) return error`. Start simple.

## Iterative Prompting

You don't have to get it perfect in one shot. Build iteratively:

```
Round 1: "Add a /users endpoint that returns all users from the database"
Round 2: "Add pagination — default 20 per page, max 100"
Round 3: "Add filtering by role and search by name"
Round 4: "Add rate limiting — 100 requests per minute per API key"
```

Each round builds on reviewed, working code. This is almost always better than trying to specify everything upfront.

## Context Injection Techniques

### Point to specific files
```
"Look at how src/api/orders.ts handles pagination and apply the same pattern to src/api/products.ts"
```

### Reference existing patterns
```
"Follow the same error handling pattern used in the auth middleware"
```

### Provide example output
```
"The API response should look like:
{
  "data": [...],
  "pagination": { "page": 1, "total": 42, "hasMore": true }
}"
```

### Mention what you've already tried
```
"I tried adding a useEffect cleanup but the WebSocket still leaks on unmount.
The connection is created in src/hooks/useChat.ts line 23."
```

## When the Output Is Wrong

Don't throw away the whole response. Be specific about what's wrong:

```
"The function works but:
1. It doesn't handle the case where `items` is empty
2. The variable name `d` should be `discount`
3. Move the helper function inside the main function, it's not used elsewhere"
```

This is faster and more accurate than re-prompting from scratch.

## The Golden Rule

**If you'd need to explain it to a new team member, explain it to the AI.** If you'd assume a senior dev already knows it, the AI probably knows it too.

## Next Steps

- [Context Management](context-management.md) — Work within and around context limits
- [Multi-Step Tasks](multi-step-tasks.md) — Break complex work into manageable pieces
- [Prompt Patterns](prompt-patterns.md) — Reusable templates for common scenarios
