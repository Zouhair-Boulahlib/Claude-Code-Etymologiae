# Context Management

> Work within and around context limits so long sessions stay productive and short sessions stay cheap.

## How the Context Window Works

The context window is the total amount of text the model can "see" at once -- your messages, its responses, tool calls, file contents, and system instructions. Think of it as RAM for a conversation. When it fills up, something has to give.

For Claude Code, the practical limits look like this:

| What | Approximate Token Cost |
|------|----------------------|
| Your CLAUDE.md | 50-500 tokens |
| System instructions | ~2,000 tokens |
| A typical prompt from you | 50-200 tokens |
| A typical response | 200-2,000 tokens |
| Reading a file (500 lines) | ~2,000-4,000 tokens |
| A large codebase search | 5,000-20,000 tokens |
| Tool call overhead per call | ~100-300 tokens |

A conversation that reads 15 files and has 10 back-and-forth exchanges can easily consume 60,000+ tokens. That is real money and real context pressure.

## What Consumes Context (And What Doesn't)

Everything inside the conversation counts: your prompts, the model's responses, file contents it reads, search results, tool outputs, and error messages. It all accumulates.

What does **not** count against your conversation context:
- Files the model has not read (sitting on disk is free)
- Subagent work (runs in a separate context, returns only a summary)
- Previous conversations (each `/clear` or new session starts fresh)

The biggest context hogs are typically:
1. **Large file reads** -- a 1,000-line file can eat 4,000-8,000 tokens
2. **Broad search results** -- "find all uses of this function" across a big codebase
3. **Verbose responses** -- the model explaining what it did and why, at length
4. **Failed attempts** -- dead-end debugging rounds that clutter the history

## Automatic Compaction

When your conversation approaches the context limit, Claude Code automatically compresses older messages. Here is what happens:

1. The system detects context pressure (approaching the token ceiling)
2. A fast model summarizes earlier messages
3. Critical details -- file paths, decisions made, errors resolved -- are preserved
4. Verbose explanations, intermediate tool outputs, and redundant content are dropped
5. The summary replaces the original messages, freeing token budget

You will see something like `[Context compacted]` when this happens. The conversation continues, but older details may be less precise.

**The practical impact:** You might ask "what was the error we saw earlier?" and get a vague answer, because the exact error text was compacted away. If something matters, keep it close to the present in the conversation -- or write it to a file.

## /compact vs /clear -- When to Use Each

### /compact -- Trim but keep going

```
/compact
```

Or with a focus hint:

```
/compact focus on the database migration changes
```

**Use /compact when:**
- You are mid-task but the conversation has accumulated noise (failed attempts, exploratory reads)
- You want to continue the current task with a cleaner context
- You are about to start a subtask and want to free up room
- Responses are getting slower or less coherent (a sign of context pressure)

**What it preserves:** Key decisions, file paths you have been working on, the current state of the task. What it drops: verbose explanations, intermediate outputs, dead-end explorations.

### /clear -- Start fresh

```
/clear
```

**Use /clear when:**
- You are switching to a completely different task
- The conversation has gone off the rails and retrying from scratch is faster
- You have committed your work and want a clean slate for the next feature
- The context is so polluted that `/compact` would not help

**What it preserves:** Nothing except your CLAUDE.md. Full reset.

### Decision framework

```
Still working on the same task?
  Yes -> Is the conversation getting sluggish or confused?
    Yes -> /compact
    No  -> Keep going
  No  -> Did you commit or finish the previous task?
    Yes -> /clear
    No  -> /compact (preserve the old context), finish up, then /clear
```

## Structuring Long Sessions

Long sessions -- 30+ minutes on a complex feature -- are where context management matters most. Here is how to structure them.

### The Checkpoint Pattern

Work in phases. After each phase, commit and optionally compact.

```
Phase 1: Set up the data model
  > "Create the User and Role entities in src/db/entities/"
  [review, test, commit]
  /compact focus on the auth feature -- models are done

Phase 2: Build the service layer
  > "Add UserService in src/services/user.ts with create, findById, and updateRole methods"
  [review, test, commit]
  /compact focus on the auth feature -- service layer is done

Phase 3: Wire up the API endpoints
  > "Add CRUD endpoints for users in src/api/routes/users.ts using the UserService"
  [review, test, commit]
```

Each `/compact` clears the implementation details of previous phases while retaining the overall picture. Your context stays focused on the current phase.

### The Breadcrumb Pattern

Leave notes in CLAUDE.md for context that must survive across compactions and sessions:

```markdown
## Current Work (delete when done)
- Adding auth to the API
- User and Role entities are done (src/db/entities/)
- UserService is done (src/services/user.ts)
- Next: API endpoints, then middleware
```

This costs ~50 tokens per conversation load but prevents you from re-explaining the same context.

## The Fresh Conversation Pattern

For complex projects, starting a new conversation for each subtask is often better than trying to keep one long conversation going.

**How it works:**

```
Conversation 1: "Create the User entity with fields: id, email, passwordHash,
                 role, createdAt. Put it in src/db/entities/user.ts.
                 Use the Drizzle ORM pattern from src/db/entities/product.ts."
  [review, commit]

Conversation 2: "Add a UserService in src/services/user.ts. Look at
                 src/services/product.ts for the pattern. Methods: create,
                 findById, findByEmail, updateRole."
  [review, commit]

Conversation 3: "Add user CRUD endpoints in src/api/routes/users.ts.
                 Follow the pattern in src/api/routes/products.ts.
                 Wire up the UserService."
  [review, commit]
```

Each conversation starts with a full context budget. No compaction, no stale references, no accumulated noise.

**When to use this:**
- Tasks that naturally decompose into independent subtasks
- After each subtask produces committed, working code
- When the codebase itself provides enough context (through patterns and conventions)

**When NOT to use this:**
- When subtasks have heavy dependencies on conversation history
- When you are debugging and need the full trail of what you have tried
- When the task requires understanding built up over multiple exchanges

## Context-Heavy vs Context-Light Approaches

Here is the same task done two different ways.

### Task: Add pagination to the /products endpoint

**Context-heavy approach** (one long conversation):

```
You: "Show me the current /products endpoint"
  [AI reads src/api/routes/products.ts -- 800 tokens]
You: "What does the Product model look like?"
  [AI reads src/db/entities/product.ts -- 400 tokens]
You: "How does the orders endpoint handle pagination?"
  [AI reads src/api/routes/orders.ts -- 900 tokens]
You: "And the test for orders pagination?"
  [AI reads src/api/__tests__/orders.test.ts -- 600 tokens]
You: "OK now add pagination to products following the same pattern, with tests"
  [AI generates code -- 1,500 tokens]
```

**Total: ~4,200+ tokens consumed.** The AI had to read four files to understand the context, and all of those file contents sit in the conversation.

**Context-light approach** (direct with references):

```
You: "Add pagination to the /products endpoint in src/api/routes/products.ts.
      Follow the exact same pagination pattern used in src/api/routes/orders.ts.
      Add tests matching the pattern in src/api/__tests__/orders.test.ts."
```

**Total: ~80 token prompt.** The AI still reads the files, but you skipped the exploratory rounds. One prompt, one response, done.

The context-light approach works because you already knew where the pattern was. When you do not know, the heavy approach is fine -- just be aware of the cost and `/compact` when you are done exploring.

## Using CLAUDE.md for Persistent Context

Anything you find yourself repeating across conversations belongs in CLAUDE.md.

```markdown
## Patterns
- Pagination: see src/api/routes/orders.ts for the standard pattern
- Error handling: all endpoints use the errorHandler middleware
- Validation: Zod schemas in src/schemas/, validated in route handlers
- Tests: co-located in __tests__/ directories, use supertest for API tests

## Current Sprint
Working on user management. Product and Order modules are stable -- reference
them for patterns. Do not modify files in src/api/routes/products.ts or
src/api/routes/orders.ts.
```

This costs maybe 100 tokens per load. It saves hundreds of tokens per conversation by eliminating the "here is how we do things" preamble.

## Recognizing Context Pressure

Signs your context is getting full:

- **Slower responses** -- the model takes longer because it is processing more
- **Repeated mistakes** -- it "forgets" constraints you stated earlier
- **Vague references** -- instead of specific file paths, it says "the file we discussed"
- **Contradicting itself** -- earlier decisions get overridden without reason
- **Automatic compaction messages** -- the system tells you it compressed context

When you see these signs, act:
1. If you can finish the current subtask quickly, do so and commit
2. If not, `/compact` with a focus hint for what matters right now
3. If the conversation is too far gone, commit what you have and `/clear`

## The Cost-Aware Workflow

Putting it all together:

```
1. Start with a clear CLAUDE.md (persistent context -- free per session)
2. Give specific prompts with file paths (minimize exploratory reads)
3. Work in focused phases with checkpoint commits
4. /compact between phases to reclaim context budget
5. /clear when switching tasks entirely
6. Start fresh conversations for independent subtasks
7. Write important decisions to files, not just the conversation
```

The developers who use Claude Code most effectively are not the ones with the cleverest prompts. They are the ones who manage context deliberately -- keeping it focused, trimming it early, and never letting a conversation get too far from its purpose.

## Next Steps

- [Multi-Step Tasks](multi-step-tasks.md) -- Break complex work into phases that fit in context
- [Prompt Patterns](prompt-patterns.md) -- Reusable templates that are context-efficient
- [Token Optimization](../05-advanced/token-optimization.md) -- Deep dive into token-level efficiency
