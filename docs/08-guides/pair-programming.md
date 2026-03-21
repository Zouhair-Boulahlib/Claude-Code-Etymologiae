# AI Pair Programming Protocols

> Pair programming with AI is not autocomplete. It is a structured conversation where you and the AI collaborate on design, implementation, and review -- in real time, within a single session.

## What AI Pair Programming Actually Looks Like

Forget tab-completion suggestions. AI pair programming with Claude Code is a back-and-forth dialogue. You describe what you want to build. The AI asks clarifying questions, proposes an approach, writes code, and you review it before moving on. You stay in the driver's seat -- the AI never commits, deploys, or makes architectural decisions without your explicit approval.

A typical exchange:

```
You: "I need to add rate limiting to our API endpoints. We're using Express
     with Redis."

AI:  "Before I write anything -- do you want rate limiting per-user (by API key
     or JWT) or per-IP? And what are your limits -- requests per minute? Per hour?
     Should rate-limited responses include a Retry-After header?"

You: "Per-user by JWT. 100 requests per minute. Yes, include Retry-After."

AI:  [writes middleware, explains design choices, asks about edge cases]
```

This is a conversation, not a prompt-and-pray. The quality of the output scales directly with the quality of the dialogue.

## The Three Pairing Models

### Model 1: Driver/Navigator

You describe intent. The AI writes code. You review.

This is the most common model and the one most people start with. You are the navigator -- you know where you are going. The AI is the driver -- it handles the mechanics of getting there.

```
"I need a function that validates incoming webhook payloads from Stripe.
It should verify the signature using our webhook secret from env vars,
parse the event, and return a typed event object. If validation fails,
throw a WebhookValidationError with details about what failed."
```

The AI writes the implementation. You read it, test it, and either approve or redirect:

```
"This looks right, but you're catching the Stripe error too broadly.
I want to distinguish between an invalid signature and a malformed payload.
Split the catch block into two cases."
```

**When to use it:** Boilerplate-heavy tasks, implementing well-understood patterns, working in unfamiliar frameworks where you know WHAT you want but not HOW the framework expresses it.

### Model 2: Rubber Duck

You explain your approach. The AI asks clarifying questions.

This model flips the direction. Instead of asking the AI to write code, you describe your plan and use the AI to stress-test it before you write a single line.

```
"I'm going to implement X. Walk me through the approach before I start.

Here's my plan for the caching layer:
- Use Redis for session data with a 30-minute TTL
- Use an in-memory LRU cache for frequently accessed config values
- Cache invalidation happens on write, not on a timer

What am I missing? What edge cases should I handle?"
```

The AI might respond with questions you had not considered:

- "What happens when Redis is down? Do you fall back to the database or return an error?"
- "How do you handle cache stampede when a popular key expires?"
- "If a write invalidates the cache on one server, how do other servers in the cluster learn about it?"

**When to use it:** Before starting complex features, when you have a plan but want validation, when you are making architectural decisions.

### Model 3: Reviewer

You write code. The AI reviews it in real time.

This is the inverse of Driver/Navigator. You write the code yourself, then paste it or point the AI at it for immediate feedback -- before you commit.

```
"I just wrote this authentication middleware. Review it for security
issues, edge cases, and anything that doesn't match our existing
patterns in src/middleware/."
```

Or, for incremental review during a session:

```
"I've updated src/services/payment.ts with the refund logic. Before I
move on to the next function, review what I just wrote. Focus on error
handling -- I want to make sure a failed refund doesn't leave the order
in a bad state."
```

**When to use it:** Security-critical code, complex business logic where you want a second opinion, when you are learning and want feedback on your approach.

## Session Structure

Unstructured pairing sessions drift. Define the structure upfront.

### 1. Define Scope

Start every session by telling the AI exactly what you are working on:

```
"This session: we're building the WebSocket handler for real-time chat
messages. We need to handle connection, disconnection, message send,
typing indicators, and read receipts. We'll work through these one at a
time. Don't jump ahead."
```

The last sentence matters. Without it, the AI may try to generate everything at once, producing a wall of code that is hard to review.

### 2. Timebox the Session

Keep pairing sessions under 45 minutes. After that, context degrades -- both yours and the AI's. The AI's context window fills up with earlier conversation, and your focus drifts.

If a feature takes longer than 45 minutes:

1. Commit what you have
2. Start a fresh session
3. Point the new session at the code: "Continue from where src/chat/handler.ts left off"

### 3. Commit at Checkpoints

Every time a discrete unit of work is complete and passing tests, commit. Do not wait until the end of the session.

```
"The connection handler works and tests pass. I'm committing this.
Next: message sending."
```

This gives you rollback points if later work goes sideways. It also keeps your commits small and reviewable.

## When AI Pair Programming Works Best

**Unfamiliar frameworks:** You know what you want but not how the framework expresses it. The AI knows the API surface.

```
"I've never used SvelteKit's form actions. I need a login form that
submits to a server action, validates input, sets a session cookie,
and redirects. Walk me through the SvelteKit way to do this."
```

**Boilerplate-heavy tasks:** CRUD endpoints, form validation schemas, database models, test setup code. The AI handles the tedium while you focus on business logic.

**Learning new patterns:** Instead of reading documentation for an hour, describe what you want and let the AI teach you the pattern through working code.

```
"Show me how to implement the repository pattern for our Prisma models.
Start with a base repository class, then show me a concrete UserRepository
that extends it. I want to understand the pattern -- explain the why, not
just the what."
```

**Exploring trade-offs:** When you are deciding between approaches, the AI can prototype both quickly.

```
"I'm deciding between polling and WebSockets for real-time updates.
Implement both as minimal prototypes -- just the connection and a single
message type. I want to compare the code complexity."
```

## When AI Pair Programming Fails

**Complex business logic you cannot verify:** If you cannot read the code and confirm it is correct, the AI's output is a liability. Payment calculations, regulatory logic, and domain-specific algorithms need your domain expertise to validate.

**Performance-critical code:** The AI does not know your data volume, traffic patterns, or infrastructure constraints. It writes correct code, not necessarily fast code. Always benchmark AI-generated code in performance-sensitive paths.

**When you are too tired to review:** If you find yourself accepting AI output without reading it, stop. The whole model depends on you being an active reviewer. Rubber-stamping AI code is worse than writing bad code yourself -- at least your bad code reflects your understanding.

## Real Scenario: Building a WebSocket Chat Feature

Here is how a structured pairing session looks in practice.

**Session start:**

```
"We're building a WebSocket chat feature using Socket.IO with our Express
server. The feature needs: connect/disconnect handling, message sending with
persistence to PostgreSQL, typing indicators (ephemeral, not persisted),
and read receipts. Let's start with connection handling."
```

**Step 1 -- Connection:**

```
"Set up the Socket.IO server integration with our existing Express app in
src/server.ts. Authentication should use the same JWT middleware we use for
REST endpoints -- check src/middleware/auth.ts for the pattern. On connect,
join the user to rooms for each conversation they belong to."
```

AI writes the code. You review it and notice:

```
"You're querying the database for user conversations on every connect.
Cache the room list in Redis with a 5-minute TTL -- re-query on cache miss."
```

**Commit checkpoint.** Connection handling works. Commit.

**Step 2 -- Message sending:**

```
"Now implement message sending. When a user sends a message:
1. Validate the payload (conversationId, body, optional attachmentUrl)
2. Persist to the messages table
3. Broadcast to all users in the conversation room
4. Return an acknowledgment to the sender with the message ID

Use our existing Prisma client for database access."
```

AI writes the implementation. You catch an issue:

```
"The broadcast includes the sender. Filter the sender's socket out --
they already have the message from the acknowledgment."
```

**Commit checkpoint.** Messages work end to end. Commit.

**Step 3 -- Typing indicators:**

```
"Add typing indicators. These are ephemeral -- no database persistence.
When a user starts typing, broadcast a 'typing' event to the conversation
room. Include a 3-second debounce so we don't flood the room with events.
Clear the indicator when the user sends a message or after 5 seconds of
inactivity."
```

**Commit checkpoint.** Typing indicators work. Commit.

**Session wrap-up after ~35 minutes.** Read receipts can be the next session.

## Prompt Patterns for Pairing

### Before Starting

```
"I'm going to implement [feature]. Before I start:
1. What approach would you recommend?
2. What are the main edge cases I should handle?
3. Are there any gotchas with [framework/library] that I should know about?"
```

### During Implementation

```
"Here's what I have so far. [paste code or point to file]
Before I continue:
- Does this approach make sense for the next part?
- Am I painting myself into a corner with this structure?"
```

### When Stuck

```
"I'm stuck on [specific problem]. Here's what I've tried:
1. [approach 1] -- failed because [reason]
2. [approach 2] -- partially works but [issue]

What am I missing?"
```

### Wrapping Up

```
"We're done with the implementation. Before I commit:
1. Review all the files we changed for consistency
2. Are there any loose ends -- TODOs, hardcoded values, missing error handling?
3. What tests should I write for this?"
```

## Tips for Effective AI Pairing

1. **Keep sessions under 45 minutes.** Start fresh for new features.
2. **One thing at a time.** Do not ask the AI to implement five things at once. Sequential, reviewable chunks.
3. **Commit after each milestone.** Connection works? Commit. Messages work? Commit. Do not accumulate uncommitted changes.
4. **Read every line.** If you did not read it, you did not review it. If you did not review it, do not commit it.
5. **Redirect early.** If the AI is heading in the wrong direction, say so immediately. Do not let it write 200 lines before correcting course.
6. **State constraints upfront.** "We use PostgreSQL, Prisma, and TypeScript strict mode" saves multiple rounds of correction.
7. **Name the model.** Tell the AI which pairing model you want: "I'll describe what I need, you write the code" (Driver/Navigator) or "I'll write the code, you review it" (Reviewer). This sets expectations.
8. **Use CLAUDE.md for persistent context.** If you pair frequently, put your stack, conventions, and common patterns in CLAUDE.md so you do not repeat them every session.

## CLAUDE.md Directives for Pair Programming

```markdown
# Pair programming preferences

## Session behavior
- Do not generate code for multiple features at once -- work sequentially
- After writing code, explain your key design decisions before moving on
- When I say "commit checkpoint", summarize what we completed
- Always ask about edge cases before implementing, do not assume

## Code style during pairing
- Write small functions (under 30 lines)
- Add inline comments only for non-obvious logic
- Use descriptive variable names -- no abbreviations
- Follow the existing patterns in the codebase, not textbook patterns
```

## Next Steps

- [Effective Prompting](../03-prompts/effective-prompting.md) -- Foundational techniques for clear communication with AI
- [Writing Code](../02-workflows/writing-code.md) -- Solo coding workflows that complement pairing
- [Code Review](../02-workflows/code-review.md) -- Formalizing the review process after a pairing session
