# Debugging

> The AI can't run your code, but it can read a stack trace faster than you can scroll past one.

## The Debugging Mindset

AI is not a debugger. It can't set breakpoints, inspect memory, or step through execution. What it *can* do is read error messages, understand stack traces, reason about code paths, and suggest hypotheses -- fast. Your job is to be its eyes and hands: you run the code, observe the behavior, and report back.

The most productive debugging sessions follow a pattern: **describe, hypothesize, verify, fix.**

## Sharing Error Messages Effectively

The single most important debugging skill with AI is providing good context. Here's the difference between a prompt that wastes three rounds and one that gets it right immediately.

### Bad: The bare error

```
I'm getting an error. Fix it.
```

The AI has nothing to work with. It will guess, probably wrong.

### Bad: The wall of logs

Pasting 200 lines of terminal output with "something's wrong in here" buried in the middle.

### Good: The structured report

```
I'm getting this error when I submit the checkout form with a promo code:

TypeError: Cannot read properties of undefined (reading 'discount')
  at applyPromoCode (src/services/pricing.ts:47:32)
  at processCheckout (src/services/checkout.ts:91:15)
  at handler (src/api/routes/checkout.ts:23:9)

The promo code "SAVE20" exists in the database -- I verified manually.
It works fine when no promo code is applied.

Expected behavior: 20% discount applied to the subtotal.
Actual behavior: TypeError crash.
```

This prompt gives the AI everything: the error, the stack trace, what triggers it, what you've already ruled out, and what should happen instead. One round, done.

### The template

When in doubt, use this structure:

```
**What I did:** [action that triggered the error]
**What I expected:** [correct behavior]
**What happened:** [actual behavior]
**Error/stack trace:** [exact error message]
**What I've tried:** [any debugging you've already done]
**Relevant context:** [recent changes, environment details, etc.]
```

## The Explain-Then-Fix Pattern

Don't jump straight to "fix this error." First, make sure the AI (and you) understand what's happening.

```
Read src/services/pricing.ts and explain what applyPromoCode does.
Then look at line 47 where the TypeError occurs and explain
why 'discount' would be undefined.
```

Once you understand the cause:

```
Now fix it. The promo code lookup returns the full promo object from the
database, but it seems like the code expects a different shape.
Handle the case where the promo code type is 'percentage' --
the discount value is in the 'value' field, not 'discount'.
```

This two-step approach has a concrete advantage: if the AI's explanation doesn't match what you know about the code, you catch the misunderstanding *before* it generates a wrong fix.

## Reading Stack Traces

Stack traces are information-dense and AI is excellent at parsing them:

```
Explain this stack trace. Which line is the actual error, and which frames
are just framework/library code I can ignore?

Error: ECONNREFUSED 127.0.0.1:5432
    at TCPConnectWrap.afterConnect [as oncomplete] (net.js:1141:16)
    at Protocol._enqueue (node_modules/pg-protocol/dist/protocol.js:47:22)
    at Client.query (node_modules/pg/lib/client.js:195:14)
    at Pool.query (node_modules/pg/lib/pool.js:399:10)
    at UserRepository.findById (src/db/repositories/user.ts:23:18)
    at UserService.getUser (src/services/user.ts:45:12)
    at handler (src/api/routes/users.ts:17:24)
```

```
I'm seeing this React error in the browser console. What component is causing it
and what's the likely fix?

Warning: Cannot update a component (`UserProfile`) while rendering a different
component (`DashboardLayout`). To locate the bad setState() call inside
`DashboardLayout`, follow the stack trace as described in [...]
```

For async stack traces that are harder to follow:

```
This error has a confusing async stack trace. Trace the actual execution path
through our code (ignore library internals) and tell me where the bug is.
```

## Bisecting Issues

When you don't know what broke, narrow the search space:

```
This endpoint was working yesterday and returns 500 today.
Here are the files changed in the last 3 commits:
- src/services/user.ts (added email normalization)
- src/api/middleware/auth.ts (updated token validation)
- src/db/migrations/024_add_email_index.ts

The error is: "column users.email_normalized does not exist"
Which change is most likely responsible, and why?
```

For harder cases, use the AI to plan a bisection strategy:

```
The search feature is returning wrong results but I don't know when it broke.
What's the fastest way to bisect this? What should I test at each step?
```

The AI might suggest:

1. Test with a known query that should return specific results
2. Check if the issue is in indexing or querying
3. Compare the generated SQL with what you expect
4. Narrow down to the specific filter or sort clause

This is more valuable than a fix attempt -- it gives you a **strategy**.

## Debugging Across Multiple Files

Bugs that span multiple files are where AI debugging shines. You can hold the entire call chain in context.

```
The webhook handler in src/api/webhooks/stripe.ts receives a payment_intent.succeeded
event, but the order status in the database never updates to "paid."

Read the webhook handler, the order service (src/services/order.ts), and the
order repository (src/db/repositories/order.ts). Trace the path from webhook
receipt to database update and find where it breaks.
```

```
User permissions are wrong after role changes. The role updates correctly in
the database, but the user's session still has old permissions.

Check how roles are loaded (src/services/auth.ts), how sessions are created
(src/middleware/session.ts), and whether there's any caching that would hold
stale data (check src/lib/cache.ts).
```

The key: name the specific files you suspect. If you don't know which files are involved, ask first:

```
Which files in this project are involved in user permission checks?
List them all so I can narrow down where the bug might be.
```

## Avoiding the Infinite Fix Loop

This is the most common debugging anti-pattern with AI. It goes like this:

1. You report a bug
2. AI suggests a fix
3. The fix breaks something else
4. You report the new bug
5. AI fixes that, breaking the first fix
6. Repeat until frustration

### How to break the cycle

**After round 3, stop.** If the AI hasn't fixed the issue in 3 attempts, the problem is one of these:

- The AI doesn't understand the actual cause (go back to explain-then-fix)
- The fix requires understanding runtime state the AI can't see (add logging, check database state yourself)
- The code structure makes the fix non-trivial (consider refactoring first)

**Ask for a diagnosis, not a fix:**

```
Stop trying to fix this. Instead, list 3 possible root causes for why the user's
session token is invalid after a password reset. For each cause, tell me
how I can verify whether that's the actual problem.
```

This shifts from guessing to investigating. You test each hypothesis, find the real cause, and then the fix is usually straightforward.

**Provide runtime evidence:**

```
I added console.log statements. Here's what I see:

1. updatePassword() is called -- user.passwordHash changes correctly
2. invalidateSessions() is called -- returns { deletedCount: 1 }
3. createSession() is called -- returns a new token
4. BUT: the next request with the new token returns 401

The token exists in the sessions table. The auth middleware
is rejecting it. Here's the middleware log: "Token signature invalid"
```

Now the AI has actual runtime data, not just static code analysis. The bug is obvious: the token was signed with the old password hash, and the middleware validates against the new one.

## Common Debugging Prompts

### For type errors

```
I'm getting a TypeScript error: "Type 'string | undefined' is not assignable
to type 'string'." The variable is user.email in src/services/notification.ts
line 34. The User type says email is required. Why would it be undefined here?
```

### For race conditions

```
This test passes when run alone but fails when run with the full suite.
It's testing the queue processor in src/services/queue.ts.
What could cause this flaky behavior? Check for shared state,
timers, or uncleared mocks.
```

### For performance issues

```
The /api/search endpoint takes 8 seconds when it should take < 200ms.
Read the handler in src/api/routes/search.ts and the search service in
src/services/search.ts. Identify the most likely performance bottleneck.
I suspect it's the database query but I'm not sure.
```

### For environment-specific bugs

```
This works in development but fails in production with:
"Error: self signed certificate in certificate chain"

We're calling an internal API at https://api.internal.company.com.
What's the difference between dev and prod that would cause this,
and what's the correct fix (not disabling TLS verification)?
```

## When AI Debugging Isn't Enough

Sometimes you need tools the AI doesn't have access to:

- **Profiling data** -- AI can suggest where to profile, but you need to run the profiler
- **Network traces** -- AI can interpret HAR files, but you need to capture them
- **Database query plans** -- paste the EXPLAIN output and ask AI to interpret it
- **Memory dumps** -- AI can explain heap snapshots, but you need to take them

In these cases, the best pattern is: you gather the data, paste the relevant output, and ask the AI to interpret it. You're the hands; it's the second pair of eyes.

## Next Steps

- [Reading Code](reading-code.md) -- Understand code before trying to fix it
- [Writing Code](writing-code.md) -- Write the fix once you understand the bug
- [Common Mistakes](../07-anti-patterns/common-mistakes.md) -- Anti-patterns that make debugging harder
- [Multi-Step Tasks](../03-prompts/multi-step-tasks.md) -- Decompose complex bugs into manageable investigation steps
