# Reading & Understanding Code

> Before you change anything, make sure you actually understand what's there.

## Why This Matters

Most development time is spent reading code, not writing it. When you inherit a codebase, onboard to a new team, or revisit code from six months ago, the first job is comprehension. AI turns hours of archaeological digging into minutes of targeted exploration.

The key insight: **you don't need to read every file yourself.** You need to ask the right questions and verify the answers against the code.

## Finding Entry Points

Every codebase has a front door. When you're dropped into an unfamiliar project, start by finding it.

```
Where is the main entry point for this application?
What happens when the server starts up?
```

```
Trace the startup sequence -- what gets initialized, in what order,
and where are the key configuration files loaded?
```

For web apps, the question is often more specific:

```
How does a request to POST /api/orders get handled?
Walk me through from the router to the database call.
```

This kind of request-tracing prompt is one of the most powerful tools for understanding a codebase. It forces a linear, followable explanation of code that might be scattered across a dozen files.

## Understanding Individual Files

When you land on a specific file and need to understand it, be direct:

```
Explain what src/services/billing.ts does. Focus on the public interface --
what does the rest of the codebase call, and what does each function return?
```

For complex files, narrow the scope:

```
Explain the reconcile() function in src/services/billing.ts.
What are its inputs, outputs, and side effects?
When would it fail, and how does it handle failure?
```

### Decoding Cryptic Code

Some code needs translation, not explanation:

```
What does this regex do?
/^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$/
```

```
This SQL query is 45 lines long. Explain what it returns in plain English
and what the CTE at the top is doing.
```

```
What does this bash pipeline do?
find . -name "*.log" -mtime +30 -exec gzip {} \; -print | wc -l
```

Don't feel bad about asking these questions. Dense code is dense for everyone. The point of reading code is to understand it, not to prove you can parse regex in your head.

## Tracing Data Flow

Understanding how data moves through a system is often harder than understanding any single file. AI excels here because it can hold the full path in context simultaneously.

```
Trace how a user's email address flows through the system, from the signup form
to the database. Which files touch it? Where is it validated? Where is it
transformed or normalized?
```

```
Where does the `orderId` field get set? Trace it backwards from the API response
to wherever it's first generated.
```

```
What happens to a webhook payload from Stripe? Show me the path from the HTTP
handler through to any database writes or side effects.
```

The key pattern: **start from what you can see** (an API response, a database column, a UI field) **and trace backwards** to what you can't.

## Subagents vs. Direct Reads

Claude Code can use subagents -- background exploration tasks that search, read, and analyze code independently. Knowing when to use each approach matters.

### Use direct reads for targeted lookups

When you know roughly where something is or you need a specific answer:

```
Read src/config/database.ts and tell me what connection pool settings we're using.
```

```
What type does the createUser function in src/services/user.ts return?
```

These are fast, cheap, and precise. No exploration needed.

### Use subagent-style exploration for open-ended questions

When you don't know where the answer lives or the question spans many files:

```
How does authentication work in this project? Check the middleware, the auth
service, the session management, and any relevant config files. Give me the
full picture.
```

```
Find every place in the codebase where we make an external HTTP call.
What libraries are we using? Is there a shared HTTP client or are there
multiple approaches?
```

These prompts benefit from the AI reading broadly, following imports, checking multiple directories. They burn more tokens but answer questions that would take you 30 minutes of manual searching.

### The exploration prompt pattern

For deep dives, use this structure:

```
I'm trying to understand how [SYSTEM/FEATURE] works in this codebase.

Start by finding the key files involved. Then explain:
1. The main components and how they relate
2. The data flow from [START] to [END]
3. Any non-obvious design decisions or patterns
4. Where I'd need to make changes if I wanted to [GOAL]
```

The last point -- "where I'd need to make changes" -- forces the answer to be practical, not academic.

## Understanding Architecture

For big-picture understanding, layer your questions:

```
Give me a high-level architecture overview of this project.
What are the main modules, and how do they communicate?
```

Then drill down:

```
You mentioned the event bus. How is it implemented?
What events exist, and which modules produce vs consume them?
```

Then connect it to what you need to do:

```
I need to add a notification when an order is cancelled.
Based on the architecture, where should that logic live?
Which existing events should I listen to?
```

This three-step pattern -- overview, drill-down, application -- builds understanding efficiently. Each step validates the previous one and adds detail where you need it.

## Understanding Legacy Code

Legacy code has a special challenge: the **why** is often missing. Comments are stale. The original author is gone. The requirements document is a Google Doc from 2019 that nobody can find.

```
This function has a lot of special cases. Can you explain why each branch exists?
Are any of them likely dead code?
```

```
src/utils/legacy-parser.ts has no comments and no tests.
Read it carefully and explain what it does, what format it expects,
and what assumptions it makes about input data.
```

```
There's a comment that says "HACK: temporary fix for #1234" from 3 years ago.
Look at the surrounding code and tell me what this hack does
and whether the original issue still applies.
```

One powerful technique: **ask the AI to identify what it's uncertain about.** This tells you where to focus your own review.

```
Explain what the sync module does. For anything you're uncertain about,
flag it explicitly so I know where to dig deeper.
```

## Verifying Your Understanding

After AI explains something, verify it. The best way:

```
Based on your explanation, if I deleted the cacheMiddleware from the request
pipeline, what would break and what would still work?
```

```
You said the retry logic stops after 3 attempts. Show me the exact line
where that limit is enforced.
```

These verification prompts catch hallucinations. If the AI can point to a specific line that matches its explanation, the explanation is likely correct. If it gets vague, dig deeper yourself.

## Common Pitfalls

**Asking for a full codebase summary.** This produces generic, surface-level output. Ask about specific systems or flows instead.

**Taking explanations on faith.** AI can confidently explain code that doesn't exist or describe behavior that's different from reality. Always spot-check against the actual code.

**Reading without purpose.** "Explain everything in src/" is a waste of tokens. "Explain how the payment flow works because I need to add Apple Pay support" gives you actionable understanding.

## Next Steps

- [Writing Code](writing-code.md) -- Turn understanding into implementation
- [Debugging](debugging.md) -- When the code doesn't do what you thought it did
- [Effective Prompting](../03-prompts/effective-prompting.md) -- General prompting techniques
