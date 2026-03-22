# Multi-Agent Workflows

Claude Code can spawn subagents -- isolated instances that work on a focused task
and return results to the main conversation. This turns one developer into a small
team, running parallel research, exploration, and even code changes simultaneously.

## What Subagents Are

A subagent is a separate Claude instance launched from your main session. It gets
its own context window, its own tool access, and its own scope. When it finishes,
it reports back to the parent agent with a summary.

Key properties:

- **Isolated context.** The subagent does not see your full conversation history.
  It only gets the prompt you give it.
- **Scoped tools.** Subagents can read files, search code, and run commands, but
  they operate independently from your main session.
- **Parallel execution.** Multiple subagents run at the same time. You do not wait
  for one to finish before the next starts.

## When to Use Subagents

Subagents shine when a task can be decomposed into independent pieces.

**Good candidates:**
- Researching how multiple subsystems work before making a cross-cutting change
- Auditing different areas of a codebase in parallel
- Exploring several implementation approaches simultaneously
- Gathering information from multiple files or modules

**Poor candidates:**
- Sequential tasks where step 2 depends on step 1's output
- Small, focused questions you can answer in the main session
- Tasks requiring back-and-forth conversation to refine

## Agent Types

Claude Code supports several subagent patterns:

### Explore Agent
Read-only investigation. The agent searches, reads files, and reports findings.
It does not modify anything.

```
Use a subagent to explore how authentication works in this codebase.
Look at middleware, session handling, and token validation.
Report back with a summary of the auth flow.
```

### Plan Agent
Analysis that produces a concrete action plan. The agent investigates and returns
a structured set of steps.

```
Use a subagent to plan the migration from REST to GraphQL for the
user service. Identify all endpoints, their consumers, and propose
a migration order with minimal breakage.
```

### General-Purpose Agent
A subagent that can both read and write. Use with caution -- you want to review
what it produces before accepting changes.

```
Use a subagent to refactor the logging module to use structured
JSON output instead of plaintext. Work in a separate worktree.
```

## Launching Parallel Agents

The real power is parallelism. Ask Claude Code to run multiple subagents at once.

### Scenario 1: Parallel Codebase Audit

You need to audit a large application before a security review.

```
Run three subagents in parallel:

1. Audit all API endpoints for proper authentication and authorization
   checks. Flag any endpoint missing auth middleware.

2. Search for hardcoded secrets, API keys, or credentials anywhere
   in the codebase. Check config files, environment handling, and
   test fixtures.

3. Review all database queries for SQL injection vulnerabilities.
   Check both raw queries and ORM usage patterns.

Report findings from all three when complete.
```

Each agent works through its assigned area independently. You get three focused
reports instead of one agent trying to hold all three concerns in context.

### Scenario 2: Research Multiple Approaches

You need to add real-time notifications. There are several viable approaches.

```
Launch subagents to research three approaches in parallel:

1. Evaluate using Server-Sent Events (SSE) for our notification
   system. Look at our current Express setup, check compatibility,
   estimate implementation effort, and identify gotchas.

2. Evaluate using WebSockets via Socket.io. Same criteria --
   compatibility with our stack, effort, and risks.

3. Evaluate using a managed service (Pusher or Ably). Look at our
   current infrastructure, pricing implications, and integration
   complexity.

Compare all three when done and recommend one.
```

### Scenario 3: Fix a Bug While Understanding the System

You hit a bug in the payment flow, but you are not familiar with the codebase.

```
In parallel:

1. Use a subagent to trace the full payment flow from checkout
   button click to payment confirmation. Document every file,
   function, and service involved.

2. Use a subagent to investigate the bug report: orders placed
   between 11pm-1am UTC are getting duplicate charges. Look at
   the transaction logs, timezone handling, and idempotency
   logic in the payment service.

I will use the findings from both to fix the issue.
```

The first agent maps the territory. The second digs into the specific problem.
Together, they give you the context to fix the bug confidently.

### Scenario 4: Parallel Test and Implementation

You are adding a new feature and want to write tests alongside the implementation.

```
Run two subagents in parallel using separate worktrees:

1. Implement the user invitation feature in the main worktree:
   - POST /api/invitations endpoint
   - Email sending via the existing mailer service
   - Invitation acceptance flow with token validation

2. In a second worktree, write the test suite for the invitation
   feature based on the spec:
   - Unit tests for invitation model validation
   - Integration tests for the API endpoint
   - E2E test for the full invite-accept flow

I will merge the results after reviewing both.
```

## Worktree Isolation

When subagents need to write code, use Git worktrees to prevent conflicts.
A worktree is a separate working directory linked to the same repository, allowing
parallel branches without interference.

```
Create a worktree for the refactoring subagent:
git worktree add ../project-refactor feature/refactor-logging

The subagent works in ../project-refactor while the main session
stays in the primary working directory.
```

Why worktrees matter for multi-agent work:

- **No merge conflicts during work.** Each agent writes to its own directory.
- **Easy inspection.** You can diff each worktree against main independently.
- **Clean rollback.** Discard a worktree if the agent's output is not useful.
- **Branch isolation.** Each worktree can be on its own branch.

Cleanup after you are done:

```bash
git worktree remove ../project-refactor
```

## Practical Tips

**Keep subagent prompts specific.** Vague prompts produce vague results. Tell the
agent exactly what to look at, what to produce, and what format to use.

**Limit subagent scope.** A subagent investigating 500 files will burn context
fast and produce shallow results. Narrow the scope -- specific directories,
specific file types, specific concerns.

**Use subagents for read-heavy work.** The best use case is when you need to
digest a lot of information. Let subagents read and summarize while you focus
on decision-making.

**Review write-agent output carefully.** A subagent that modifies code does not
have the full context of your conversation. Review its changes as you would
review a junior developer's PR.

**Start with two agents, not ten.** Parallelism has diminishing returns. Two
well-scoped agents are more useful than five overlapping ones.

## When Not to Use Multi-Agent

- The task is small enough for the main session
- You need tight iteration loops with feedback
- The work is inherently sequential
- You are still figuring out what you want (use the main session to think first)

Multi-agent workflows are a force multiplier, but only when the work genuinely
decomposes into parallel tracks. Use them to scale your investigation and
implementation capacity, not as a substitute for clear thinking about the problem.

## Next Steps

- [Starter Kit: Agents](../../starter-kit/agents/) -- Ready-to-use agent definitions
