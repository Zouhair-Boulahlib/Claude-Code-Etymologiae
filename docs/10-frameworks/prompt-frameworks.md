# Prompt Frameworks

> Structured thinking for structured output -- pick a framework, fill in the blanks, get better code on the first try.

## Why Frameworks Matter for Coding Prompts

Most developers write prompts the same way they write Slack messages: stream of consciousness, missing context, hoping the reader fills in the gaps. That works when the reader is a colleague who shares your codebase knowledge. It falls apart with an AI that has zero implicit context.

Prompt frameworks give you a checklist. Fill in predefined slots -- role, context, constraints, expected output -- and the AI produces something usable on the first pass instead of the third.

You do not need to memorize all seven frameworks below. Find the one or two that click with how you think, and use those.

---

## 4D Framework

**Origin:** Dakan/Feller, with support from Anthropic's prompt engineering research.

The 4D Framework focuses on how you *delegate* work to an AI -- treating it as a capable team member who needs a clear brief, not a search engine that needs keywords.

### Components

| Component | What It Means |
|-----------|--------------|
| **Delegation** | Define the role and authority level. What can the AI decide on its own? What requires your approval? |
| **Description** | Describe the task clearly. What needs to happen, where, and what does "done" look like? |
| **Discernment** | Provide judgment criteria. How should the AI handle ambiguity, edge cases, or conflicting requirements? |
| **Diligence** | Set quality expectations. What verification, testing, or validation should the AI perform? |

### When to Use It

The 4D Framework shines when you are delegating a substantial task where the AI needs to make judgment calls -- multi-file refactors, feature implementations with ambiguous edge cases, or any task where you would normally brief a junior developer for 10 minutes before they start.

### Prompt Example

```
Delegation: You are the lead developer on this task. Make implementation
decisions freely, but flag any changes to public API signatures for my
review before proceeding.

Description: Refactor the notification system in src/services/notifications/
to support multiple delivery channels (email, SMS, push). Currently
everything is hardcoded to email in notify.ts. The end state is a
channel-agnostic dispatcher that routes to channel-specific handlers.

Discernment: When choosing between simplicity and extensibility, lean
toward simplicity. We only need email and SMS for the next 6 months.
If you find tightly coupled code that would take more than 30 lines to
decouple properly, leave a TODO comment and move on.

Diligence: Every new function must have a corresponding unit test.
Run the existing test suite after changes and fix any regressions.
The final diff should include no unrelated formatting changes.
```

---

## RISEN

**Origin:** Kyle Balmer.

RISEN is a sequential framework -- each component builds on the previous one, narrowing the AI's focus step by step until there is very little room for misinterpretation.

### Components

| Component | What It Means |
|-----------|--------------|
| **Role** | Who the AI should act as. Sets the expertise level and perspective. |
| **Instructions** | What to do, stated directly. The core task. |
| **Steps** | Ordered sequence of actions. Removes ambiguity about execution order. |
| **End goal** | What the finished output looks like. A concrete definition of done. |
| **Narrowing** | Constraints that eliminate unwanted behavior. What *not* to do. |

### When to Use It

RISEN works well for procedural tasks with a clear sequence -- migrations, multi-step refactors, deployment scripts. If you find yourself thinking "first do X, then Y, then Z", RISEN is a natural fit.

### Prompt Example

```
Role: Senior backend engineer familiar with Express.js and PostgreSQL.

Instructions: Migrate the user session storage from in-memory (express-session
with MemoryStore) to PostgreSQL using connect-pg-simple.

Steps:
1. Read the current session config in src/config/session.ts
2. Add connect-pg-simple to package.json dependencies
3. Create the sessions table migration in src/db/migrations/
4. Update src/config/session.ts to use PgSession with the existing
   database pool from src/db/pool.ts
5. Update the session cleanup cron in src/jobs/cleanup.ts to use
   SQL-based expiration instead of the in-memory sweep
6. Verify the existing auth tests in src/api/__tests__/auth.test.ts
   still pass

End goal: Sessions persist across server restarts. A user who logs in,
waits for a server restart, and refreshes the page remains logged in.

Narrowing:
- Do not change the session cookie configuration (name, maxAge, httpOnly)
- Do not add Redis or any other session store -- PostgreSQL only
- Do not modify the authentication logic itself, only the storage layer
```

---

## CO-STAR

**Origin:** GovTech Singapore.

CO-STAR is the most comprehensive framework here. It was designed for general-purpose prompt engineering but maps naturally to coding tasks when you realize that "Audience" means "who reads this code" and "Style" means "what conventions to follow."

### Components

| Component | What It Means |
|-----------|--------------|
| **Context** | Background information. What project, what state, what history. |
| **Objective** | The specific task. One clear sentence if possible. |
| **Style** | Coding style, conventions, patterns to follow. |
| **Tone** | For code: level of verbosity in comments, naming style, documentation level. |
| **Audience** | Who will read, maintain, or use this code. |
| **Response** | What format the output should take. |

### When to Use It

CO-STAR is ideal when you are generating code that other people will read and maintain -- library code, shared utilities, API endpoints that multiple teams consume. Also strong for documentation generation, where tone and audience genuinely matter.

### Prompt Example

```
Context: We are building a Node.js SDK for our public REST API. The SDK
is published on npm and used by external developers. The codebase uses
TypeScript with strict mode, and all public methods have JSDoc comments.

Objective: Add a client.webhooks.verify(payload, signature, secret) method
that validates incoming webhook signatures using HMAC-SHA256.

Style: Match the existing method patterns in src/resources/events.ts.
Use the functional error handling pattern (return { ok, error } objects)
rather than throwing exceptions. No classes -- use plain functions
composed together.

Tone: Public-facing code. Every parameter and return type needs JSDoc
with @example tags. Error messages should be helpful to external devs
who are debugging webhook integration.

Audience: External developers who read the SDK source when the docs
are insufficient. Assume they know TypeScript but not our internal
architecture.

Response: The implementation file (src/resources/webhooks.ts), the type
definitions (src/types/webhooks.ts), and a test file
(src/__tests__/webhooks.test.ts) with at least 5 test cases covering
valid signatures, invalid signatures, expired timestamps, malformed
payloads, and missing headers.
```

---

## RACE

**Origin:** Trust Insights.

RACE is the minimalist framework. Four components, no fluff. It works because it forces you to answer the four questions that matter most, and nothing else. If CO-STAR is a full brief, RACE is a sticky note.

### Components

| Component | What It Means |
|-----------|--------------|
| **Role** | What expertise the AI should bring. |
| **Action** | What to do. The verb. |
| **Context** | The relevant background. |
| **Expectations** | What good output looks like. |

### When to Use It

RACE is your daily driver. Most coding prompts do not need six components -- they need four good sentences. Use RACE for bug fixes, small features, code reviews, quick refactors. When RACE is not enough, that is your signal to switch to a heavier framework.

### Prompt Example

```
Role: TypeScript developer familiar with React and Zustand.

Action: Fix the race condition in the shopping cart state.

Context: When a user clicks "Add to Cart" rapidly, the cart count sometimes
shows the wrong number. The cart store is in src/stores/cart.ts and uses
Zustand. The addItem action reads the current items array, appends the
new item, and calls set(). Two rapid calls can read the same stale state.

Expectations: The addItem action should use Zustand's callback form of
set() — set((state) => ...) — to guarantee it always reads the latest
state. Include a comment explaining why the callback form is needed.
No other changes.
```

---

## CRISPE

**Origin:** Matt Dinkevych.

CRISPE gives the AI a "capacity" -- a defined skill set and boundary. This is useful when you want the AI to operate within a specific domain and refuse to wander outside it. Think of it as giving the AI a job description, not just a task.

### Components

| Component | What It Means |
|-----------|--------------|
| **Capacity** | What the AI is capable of and responsible for. Its job description. |
| **Request** | The specific task to perform. |
| **Information** | Data, context, and reference material the AI needs. |
| **Style** | How the output should be formatted and written. |
| **Parameters** | Constraints, boundaries, and edge case handling rules. |

### When to Use It

CRISPE works well when you are using Claude Code for a specialized role over multiple prompts -- a security auditor, a performance reviewer, a database migration specialist. The Capacity component establishes a persistent identity that keeps the AI in its lane across the conversation.

### Prompt Example

```
Capacity: You are a database migration specialist. You write migrations,
review schema changes, and advise on data integrity. You do not modify
application code, API routes, or frontend components.

Request: Create a migration that adds soft-delete support to the
orders and order_items tables.

Information:
- Database: PostgreSQL 15
- Migration tool: Knex.js (see existing migrations in src/db/migrations/)
- The orders table has ~2M rows in production
- The order_items table has ~8M rows
- Current schema: src/db/schema.sql
- We need zero-downtime deployment

Style: Follow the naming convention in existing migrations (timestamp
prefix, snake_case description). Include both up and down migrations.
Add inline SQL comments explaining any non-obvious decisions.

Parameters:
- The migration must complete in under 30 seconds on the production
  dataset size
- Add deleted_at (timestamp, nullable) rather than is_deleted (boolean)
- Add a partial index on deleted_at IS NULL for query performance
- Do not backfill any data -- all existing rows remain active
- The down migration must be safe to run (drop columns, not truncate)
```

---

## Tree of Thoughts

**Origin:** Academic research, Yao et al. (2023). Adapted here for practical coding use.

Tree of Thoughts (ToT) is not a prompt template -- it is a reasoning strategy. Instead of asking the AI to follow one path from problem to solution, you ask it to explore multiple paths in parallel, evaluate them, and pick the best one. Think of it as brainstorming before committing.

### Components

| Component | What It Means |
|-----------|--------------|
| **Parallel reasoning paths** | Generate multiple candidate solutions, not just one. |
| **BFS/DFS exploration** | Explore broadly (breadth-first) or deeply (depth-first) depending on the problem. |
| **Evaluation and pruning** | Assess each path against criteria before continuing. Discard dead ends. |

### When to Use It

Use Tree of Thoughts for architecture decisions, design choices, and any problem where the first solution that comes to mind is probably not the best one:

- Choosing between architectural approaches
- Designing data models with complex relationships
- Planning a refactoring strategy for tangled code

Do not use it for straightforward tasks. If you know what you want, just ask for it.

### Prompt Example

```
I need to add real-time collaboration to our document editor
(src/features/editor/). Before implementing anything, explore three
different approaches:

Approach 1: Operational Transformation (OT)
Approach 2: Conflict-free Replicated Data Types (CRDTs)
Approach 3: Last-write-wins with manual conflict resolution UI

For each approach:
- Sketch the key data structures needed
- Estimate the implementation complexity (files to add/modify)
- Identify the biggest technical risk
- Assess how it fits with our current tech stack (React, Express,
  PostgreSQL, no Redis currently)

After evaluating all three, recommend one and explain why it wins
for our specific constraints. Only then proceed with implementation.
```

---

## Chain-of-Thought

**Origin:** Academic research, Wei et al. (2022). Now a foundational technique in prompt engineering.

Chain-of-Thought (CoT) prompting asks the AI to show its reasoning step by step before producing a final answer. For coding, this means the AI explains *why* before it writes *what*, which dramatically improves output quality for complex logic.

### Components

| Component | What It Means |
|-----------|--------------|
| **Intermediate reasoning steps** | The AI must articulate its thinking process, not just jump to code. |
| **Step-by-step decomposition** | Break complex problems into smaller, verifiable pieces. |

### When to Use It

Chain-of-Thought is most valuable for:

- Complex algorithms where correctness matters more than speed
- Debugging mysterious behavior where you need the AI to reason about causality
- Performance optimization where the AI needs to analyze before prescribing
- Any task where you have been burned by the AI confidently producing wrong code

It is the simplest technique here -- just add "think step by step" or "explain your reasoning before writing code" -- but the impact on complex tasks is substantial.

### Prompt Example

```
The calculateTax function in src/services/tax.ts is returning incorrect
values for multi-state orders. Before writing any fix:

1. Read the current implementation and explain what it does line by line
2. Trace through this failing test case step by step:
   - Order with items shipping to CA (9.5% tax) and OR (0% tax)
   - Item 1: $100 to CA
   - Item 2: $50 to OR
   - Expected total tax: $9.50
   - Actual total tax: $14.25 (wrong)
3. Identify exactly where the calculation diverges from expected
4. Explain the root cause
5. Only then write the fix

Show all your reasoning. I want to understand the bug, not just fix it.
```

---

## Framework Comparison

| Framework | Best For | Complexity | Coding Fit | Key Strength |
|-----------|----------|-----------|------------|-------------|
| **4D** | Delegated tasks with decision-making latitude | Medium | High | Balances autonomy with guardrails |
| **RISEN** | Sequential, procedural tasks | Medium | High | Explicit step ordering |
| **CO-STAR** | Public-facing or team-shared code | High | Medium-High | Audience and style awareness |
| **RACE** | Everyday coding tasks | Low | High | Fast, minimal overhead |
| **CRISPE** | Specialized, role-constrained work | Medium | Medium-High | Keeps the AI in its lane |
| **Tree of Thoughts** | Architecture and design decisions | High | Medium | Explores before committing |
| **Chain-of-Thought** | Complex logic and debugging | Low | High | Forces reasoning before code |

---

## Choosing the Right Framework

**Start with RACE.** Seriously. Four components, covers 80% of coding prompts. When RACE is not enough, escalate:

- Task needs ordered steps? **RISEN.**
- Task needs judgment calls and autonomy? **4D.**
- Code will be read by people outside your team? **CO-STAR.**
- You want the AI to stay in a specialized role? **CRISPE.**
- You are making an architecture decision? **Tree of Thoughts.**
- The AI keeps producing wrong logic? **Chain-of-Thought.**

If RACE handles it, do not use CO-STAR just because it has more letters.

---

## The Pragmatic Reality

Here is what actually happens in practice: experienced developers blend frameworks without thinking about it. A typical production prompt might use RACE's structure, add RISEN's explicit steps, and finish with a Chain-of-Thought request to explain the approach before coding. Nobody labels which components came from which framework. And that is exactly how it should work.

Frameworks are training wheels, not permanent fixtures. They teach you which information matters:

- **Who** the AI should be (role/capacity)
- **What** needs to happen (task/action)
- **Where** and **why** (context)
- **How** to constrain the output (narrowing/parameters/expectations)
- **What good looks like** (end goal/response format)

Once those questions become instinct, you stop thinking in frameworks and start writing prompts that just work.

**The anti-pattern to avoid:** Do not let framework orthodoxy slow you down. If you spend more time formatting your prompt into a framework than you would spend fixing a bad response, you have gone too far. A clear three-sentence prompt beats a poorly-filled six-component template every time.

**The real skill is calibration.** Match the framework weight to the task weight, and you will consistently get better output with less effort.

---

## Next Steps

- [Agent Loop Patterns](agent-loops.md) -- How Claude Code's agent loop processes your structured prompts
- [Effective Prompting](../03-prompts/effective-prompting.md) -- The fundamentals that underpin every framework
- [Multi-Step Tasks](../03-prompts/multi-step-tasks.md) -- Break complex work into manageable pieces
