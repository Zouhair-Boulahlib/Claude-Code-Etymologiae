# Agent Loops

> Structured iteration patterns that turn Claude Code from a one-shot answer machine into a persistent, self-correcting agent.

## Why Agent Loops Matter

Claude Code is not a chatbot. It is an agent. It reads files, runs commands, observes results, and decides what to do next -- in a loop. Every time you give it a task, it enters a cycle of reasoning and action that continues until the task is complete or it gets stuck.

Understanding loop patterns changes how you work with Claude Code:

- You stop writing prompts and start **designing workflows**
- You choose the right iteration pattern for the right kind of task
- You recognize when the agent is stuck in a bad loop and know how to redirect it
- You compose multiple loop patterns for complex, multi-phase work

## How Claude Code Works Internally

Claude Code uses a **ReAct-style loop** as its core execution model:

```
1. Receive task from user
2. Think about what to do (reasoning)
3. Take an action (read file, run command, edit code, search)
4. Observe the result
5. Think about what the result means
6. Either take another action (go to 3) or respond to the user
```

This is not something you configure -- it is how the tool works. When you ask Claude Code to "fix the failing test in src/api/auth.test.ts," it reads the test, reads the implementation, runs the test to see the error, reasons about the cause, edits the code, runs the test again, and then reports back.

The patterns below are about **shaping and extending** this built-in loop, not replacing it.

## ReAct (Reason + Act)

### How It Works

ReAct, introduced by Yao et al. in 2023, is the foundational pattern:

```
Thought -> Action -> Observation -> Thought -> Action -> Observation -> ...
```

1. **Thought** -- reason about the current state and what to do next
2. **Action** -- take a concrete step (tool call, code edit, command)
3. **Observation** -- see the result of the action

The key insight: interleaving reasoning with action produces better results than pure reasoning (think everything through, then act once) or pure action (try things without thinking).

### When to Use

ReAct is the default -- what Claude Code does on every task. **Best for:** single-step tasks, debugging with clear error signals, exploration, and tasks where each step informs the next.

### Claude Code Implementation

ReAct is built in. You make it more effective by ensuring clear observation signals:

```
"Fix the TypeError in src/utils/parser.ts. Run the test suite after each
change so you can see whether the fix works. If the first attempt doesn't
fix it, read the error carefully and try a different approach."
```

Or make the reasoning phase explicit:

```
"Before making any changes, explain what you think the bug is and why.
Then fix it. Then verify."
```

### Compared to Other Patterns

ReAct is the simplest loop -- no explicit planning, no persistent memory, no self-evaluation. Fast and lightweight for straightforward tasks, but it struggles with long-range planning or learning from past failures.

---

## RALPH Loop

### How It Works

The RALPH Loop, articulated by Geoffrey Huntley in 2025, is a macro-level pattern for sustained, multi-session work:

```
Requirements -> Planning Loop -> Building Loop
                    |                  |
                    v                  v
            (iterate until          (fresh context
             plan is solid)          each iteration)
```

The critical insight is **fresh context per building iteration**. Instead of one long conversation that degrades as context fills up, each build cycle starts clean. The plan persists; the execution context does not.

1. **Requirements** -- define what you want, clearly and completely
2. **Planning Loop** -- iterate until the plan is solid. Poke holes, refine, stress-test.
3. **Building Loop** -- execute one piece at a time. Fresh conversation per piece. Verify, commit, update the plan.

### When to Use

RALPH is for **large features and multi-day work**: tasks spanning multiple sessions, work where context limits would degrade quality, or tasks needing consistency across many files.

### Claude Code Implementation

**Phase 1 -- Requirements:** Write them in a persistent file.

```
"Create docs/plans/notification-system.md with these requirements:
- Real-time notifications via WebSocket
- Types: order status, payment confirmation, system alerts
- PostgreSQL storage, read/unread tracking, API endpoints
- Max delivery latency: 2 seconds
Don't implement anything yet."
```

**Phase 2 -- Planning Loop:** Iterate on the plan across prompts.

```
"Read docs/plans/notification-system.md. Analyze the codebase architecture.
Write a detailed implementation plan with numbered steps, specific files,
and dependencies. Add the plan to the same file."
```

```
"Read the plan. Play devil's advocate. What edge cases are missing?
What could go wrong? Update the plan."
```

**Phase 3 -- Building Loop:** Fresh conversation per step.

```
"Read docs/plans/notification-system.md. I'm on step 3. Steps 1-2 are
committed. Implement step 3 following the plan. Run the tests when done."
```

### Compared to Other Patterns

RALPH is a meta-pattern -- it wraps around ReAct. Its unique contribution is fresh context per iteration and explicit separation of planning from building. Where ReAct is a single loop, RALPH is a loop of loops.

---

## Plan-Execute-Reflect

### How It Works

Plan-Execute-Reflect emerged as an industry pattern in 2024. More structured than ReAct, less heavyweight than RALPH:

```
Plan (all steps upfront) -> Execute (one at a time) -> Reflect (re-evaluate)
     ^                                                        |
     |________________________________________________________|
```

1. **Plan** -- generate a complete plan before doing anything
2. **Execute** -- carry out steps sequentially
3. **Reflect** -- after each step or failure, evaluate and revise the plan if needed

The reflection phase distinguishes this from simple plan-then-execute. Reflection can change the remaining plan.

### When to Use

**Medium-complexity tasks** within a single conversation: features touching 3-8 files, refactoring needing specific order, bug fixes where the root cause is unclear.

### Claude Code Implementation

```
"I need to migrate session handling from cookies to JWT. Constraint:
backward-compatible for 2 weeks.

Step 1: Create a plan listing every file that needs to change, in order.
Don't write code yet.

Step 2: I'll review and approve.

Step 3: Execute each step. After each step, assess whether the remaining
plan still makes sense. If something unexpected comes up, pause and revise
before continuing."
```

The key is the explicit instruction to reassess. Give it concrete signals:

```
"After implementing the dual-auth middleware, run the full test suite.
If any tests fail, stop and re-evaluate the approach before moving on."
```

### Compared to Other Patterns

Sits between ReAct (no planning) and RALPH (planning as a separate multi-session loop). The workhorse for single-conversation tasks needing structure.

---

## OODA Loop

### How It Works

The OODA Loop (Observe, Orient, Decide, Act) comes from military strategy (John Boyd). Adapted for AI-assisted development, it emphasizes **rapid situational awareness**:

```
Observe -> Orient -> Decide -> Act -> Observe -> ...
```

1. **Observe** -- gather raw information (read files, run tests, check logs)
2. **Orient** -- interpret observations in context (what does this mean for our goals?)
3. **Decide** -- choose a specific course of action
4. **Act** -- execute the decision

The critical phase is **Orient** -- connecting observations to context. This is where you inject domain knowledge, constraints, and priorities.

### When to Use

OODA excels in **fast-changing situations**: production incident response, codebases with active concurrent development, security patching, performance optimization.

### Claude Code Implementation

```
"Production alert: API response times spiked to 5 seconds.

Observe: Check application logs, database query logs, and recent deploys.
Orient: What are the most likely causes? Rank by probability.
Decide: Pick the most likely cause and propose a specific fix.
Act: Implement the fix. Then observe again -- did response times improve?

If not, loop back to Orient with the new information."
```

### Compared to Other Patterns

The fastest loop. Prioritizes speed over completeness. Where Plan-Execute-Reflect builds a full plan, OODA makes the smallest viable decision at each step. Ideal for shifting environments, less suitable for large structured work.

---

## Reflexion

### How It Works

Reflexion, introduced by Shinn et al. in 2023, adds **explicit self-evaluation and memory**:

```
Actor -> Evaluator -> Memory -> Actor (improved) -> ...
```

1. **Actor** -- attempt the task
2. **Evaluator (Critic)** -- assess against criteria. What worked? What failed? Why?
3. **Memory** -- store the evaluation as a lesson
4. **Loop** -- retry with accumulated lessons in context

The key innovation: **persistent memory of failures**. Instead of retrying blindly, the agent carries forward explicit knowledge about what did not work.

### When to Use

When **the first attempt is unlikely to be perfect**: complex test suites, output meeting quality criteria, tasks with automatically checkable acceptance criteria.

### Claude Code Implementation

```
"Implement CSV export in src/services/export.ts. Requirements:
- Handle up to 1M rows without OOM
- Streaming writes
- Proper escaping of commas, quotes, newlines

After implementing, run src/services/__tests__/export.test.ts.
If any tests fail:
1. Analyze WHY they failed, not just what failed
2. Write down the lesson
3. Fix with that lesson in mind
4. Run tests again

Repeat until all tests pass. Keep a running list of lessons as comments."
```

The critical element: instructing the agent to analyze _why_, not just fix the symptom. This turns blind retrying into directed improvement.

### Compared to Other Patterns

The only pattern with explicit memory across iterations. ReAct has implicit memory (conversation history), but Reflexion makes lessons structured and deliberate. The tradeoff is overhead -- best when criteria are measurable and iteration is expected.

---

## Self-Improving / Recursive Patterns

### How It Works

Emerging in 2025 with systems like Google's AlphaEvolve and GEPA (Generate, Evaluate, Prune, Amplify), these patterns apply **evolutionary selection pressure**:

```
Generate (multiple candidates) -> Evaluate (score each) -> Select (best)
     -> Mutate/Improve -> Generate -> ...
```

The key difference from Reflexion: self-improving loops generate **multiple candidates in parallel** and use selection, not just single-path improvement.

1. **Generate** -- produce multiple candidate solutions
2. **Evaluate** -- score each against objective criteria
3. **Prune** -- discard candidates below threshold
4. **Amplify** -- combine strengths of winners, generate new candidates

### When to Use

High-investment, high-reward. Use when you have a clear measurable fitness function, multiple valid approaches exist, and you can afford the token cost of parallel evaluation.

### Claude Code Implementation

You drive the outer loop; Claude Code handles generation and evaluation:

```
"Optimize the image pipeline in src/services/image.ts. Current: 340ms.

Round 1 -- generate three approaches:
A) Worker threads for parallel processing
B) Sharp's streaming API
C) Reduce intermediate buffer allocations

Implement each in a separate branch. Benchmark each. Report results."
```

After results (e.g., B wins at 195ms):

```
"Round 2: Take approach B as baseline. Two variations:
D) Combine B with buffer reduction from C
E) Approach B plus a fast-path for images under 1MB

Implement and benchmark both."
```

### Compared to Other Patterns

The most expensive and most powerful. Where ReAct finds _a_ solution and Reflexion finds _a better_ solution, self-improving patterns search for _the best_ solution across a candidate space.

---

## Comparison Table

| Pattern | Planning | Memory | Parallelism | Best For | Token Cost |
|---------|----------|--------|-------------|----------|------------|
| **ReAct** | None (implicit) | Conversation only | No | Single tasks, debugging | Low |
| **RALPH** | Dedicated phase | Plan file, fresh contexts | Between phases | Large features, multi-day work | Medium |
| **Plan-Execute-Reflect** | Upfront plan | Conversation + reflection | No | Medium features, refactors | Medium |
| **OODA** | None (fastest) | Conversation only | No | Incidents, fast-moving situations | Low |
| **Reflexion** | None | Explicit lesson storage | No | Test-driven iteration | Medium-High |
| **Self-Improving** | Meta-level | Cross-candidate evaluation | Yes (candidates) | Performance optimization | High |

## Combining Patterns

Real work rarely fits one pattern. Combine them across phases.

**RALPH + ReAct:** RALPH for macro structure (planning loop, building loop with fresh context), ReAct for each individual build step. The most common production combination.

**OODA + Reflexion:** OODA for rapid incident triage, then Reflexion when you have a hypothesis and need to iterate on a fix with memory of what failed.

**Plan-Execute-Reflect + Self-Improving:** Use Plan-Execute-Reflect for the overall approach, but switch to self-improving for specific optimization steps within the plan.

### Choosing Your Pattern

```
Is this a quick fix or investigation?
  -> Yes: ReAct (default)

Will it span multiple conversations or days?
  -> Yes: RALPH (wrap around everything else)

Is the environment changing rapidly (incident, live debugging)?
  -> Yes: OODA

Is there a measurable optimization target?
  -> Yes, and first attempt is likely close enough: Reflexion
  -> Yes, and the search space is wide: Self-Improving

Structured work in a single conversation?
  -> Plan-Execute-Reflect
```

## Next Steps

- [Prompt Frameworks](prompt-frameworks.md) -- Structured templates for crafting effective agent prompts
- [Multi-Agent Workflows](../05-advanced/multi-agent.md) -- Run parallel agents for investigation and implementation
- [Multi-Step Tasks](../03-prompts/multi-step-tasks.md) -- Decompose complex work into reviewable, committable steps
