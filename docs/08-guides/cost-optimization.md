# Cost Optimization Playbook

> AI-assisted development is not free. But the developers who complain about cost are usually the ones burning tokens on the wrong things. This guide helps you spend less and get more.

## Understanding the Pricing

Claude Code uses the Anthropic API. You pay per token -- both input and output.

```
Input tokens:   what you send (prompts, files, system context)
Output tokens:  what Claude generates (responses, code, explanations)
Cached tokens:  input tokens that match a previous request (discounted ~90%)
```

At typical rates (check anthropic.com/pricing for current numbers):

| Model | Input (per 1M tokens) | Output (per 1M tokens) | Cached Input |
|-------|----------------------|------------------------|--------------|
| Sonnet | ~$3 | ~$15 | ~$0.30 |
| Opus | ~$15 | ~$75 | ~$1.50 |

Output tokens cost 5x more than input tokens. This matters. A response with 2,000 tokens of code costs the same as 10,000 tokens of input context. Verbose AI output is expensive.

---

## How Claude Code Uses Tokens Under the Hood

Every Claude Code message is more expensive than it looks. Here is what gets sent with each request:

```
System prompt           ~2,000 tokens   (Claude Code's instructions)
CLAUDE.md contents      ~500-3,000      (your project config)
Tool definitions        ~3,000-5,000    (file read, edit, search, bash, etc.)
Conversation history    varies          (all previous messages in the session)
Your current message    varies          (your actual prompt)
```

A "simple" question in a long session might send 50,000+ input tokens just for context, even if your prompt is 20 words. This is why long conversations get expensive.

### The Conversation Growth Problem

```
Message 1:   ~8,000 input tokens   (system + tools + CLAUDE.md + your prompt)
Message 5:   ~25,000 input tokens  (all of the above + 4 rounds of conversation)
Message 15:  ~80,000 input tokens  (you're now paying for a lot of history)
Message 30:  ~150,000+ input tokens (context window filling up, cost escalating)
```

Every message replays the entire conversation. This is the single biggest cost driver.

---

## Tracking Your Spend

### API Dashboard

The Anthropic Console (console.anthropic.com) shows:
- Total spend by day, week, month
- Token usage broken down by input/output
- Usage by API key (useful for per-developer tracking)

Check it weekly. Set up billing alerts at 50% and 80% of your budget.

### Per-Session Estimates

Claude Code shows token usage during a session. Watch for sessions that are consuming disproportionate tokens. A code review session should not cost more than a full feature implementation.

Rough mental math: 1,000 output tokens is about 750 words or about 30 lines of code. If Claude Code generated a 200-line file, that is roughly 6,000-8,000 output tokens.

### Token Audit Hooks

Use Claude Code hooks to log token usage per session:

```json
{
  "hooks": {
    "post_response": [
      {
        "command": "echo \"$(date): session=$SESSION_ID tokens_in=$INPUT_TOKENS tokens_out=$OUTPUT_TOKENS\" >> ~/.claude/token-log.csv"
      }
    ]
  }
}
```

Aggregate this data weekly to understand your usage patterns.

---

## Budget Strategies for Teams

### Per-Developer Limits

Create separate API keys per developer. Set monthly spend limits on each:

```
Senior engineers:    $200/month  (complex tasks, architectural work)
Mid-level engineers: $100/month  (feature development, debugging)
Junior engineers:    $75/month   (learning, code review, small tasks)
```

These are starting points. Adjust based on your team's actual ROI.

### Project Budgets

For specific projects, track costs by having developers tag their sessions:

```bash
# In CLAUDE.md or session init
# Project: payments-migration
# Budget: $500 total
# Sprint: 2025-Q1-S3
```

Review costs per project at sprint retrospectives.

### The Cost Accountability Rule

Make costs visible. When developers see what they spend, they naturally optimize. When it is an invisible company credit card, nobody cares.

---

## Cost-Saving Techniques Ranked by Impact

### 1. Start New Conversations for New Tasks (High Impact)

The biggest cost saver. Do not reuse a 30-message conversation to ask an unrelated question. That unrelated question carries 30 messages of irrelevant context at full price.

```
Bad:  [30-message debugging session] -> "Now write me a README"
Good: Start a fresh session for the README
```

### 2. Use Sonnet for Simple Tasks (High Impact)

Not every task needs Opus. Use the model selection flag:

```bash
# Quick tasks: use Sonnet
claude --model sonnet "Add a created_at timestamp field to the User model"

# Complex tasks: use Opus
claude --model opus "Refactor the payment system from callbacks to async/await, maintaining all error handling semantics"
```

**Rule of thumb:** If you can describe the task in one sentence and the solution is straightforward, Sonnet is fine. If it requires multi-step reasoning, cross-file understanding, or architectural decisions, use Opus.

### 3. Be Specific in Prompts (Medium Impact)

Vague prompts cause the AI to read more files (input tokens) and generate longer exploratory responses (output tokens).

```
Expensive: "Look at the auth system and suggest improvements"
Cheap:     "In src/auth/jwt.ts, the token refresh logic on line 47 doesn't
            handle expired refresh tokens. Add a check that returns a 401
            if the refresh token is also expired."
```

The specific prompt might cost 1/5 as much because it avoids file searching and exploratory output.

### 4. Use Repomix for Batch Operations (Medium Impact)

Instead of having Claude Code read 20 files one by one (20 tool calls, each adding to conversation history), pack them with Repomix and provide them in one shot:

```bash
repomix --include "src/services/**/*.ts" -o context.txt
claude -p "Given this codebase context, identify all services that don't have error handling for database timeouts:" < context.txt
```

One round trip instead of twenty. See [Token Optimization Techniques](../05-advanced/token-optimization.md) for the full Repomix workflow.

### 5. Ask for Concise Output (Medium Impact)

Output tokens cost 5x more than input. Tell Claude Code to be brief:

```
Fix the null pointer in processOrder. Return ONLY the corrected function,
no explanation.
```

Compare costs:
- With explanation: ~500 tokens output ($0.0075 on Sonnet)
- Code only: ~150 tokens output ($0.00225 on Sonnet)

This adds up across hundreds of interactions.

### 6. Use Headless Mode for Scripted Tasks (Low-Medium Impact)

```bash
claude -p "your prompt here" --output-format text
```

Headless mode skips the interactive overhead and is ideal for CI/CD or scripted batch operations where you do not need a back-and-forth conversation.

### 7. Keep CLAUDE.md Lean (Low Impact)

Every token in CLAUDE.md is sent with every single message. A 3,000-token CLAUDE.md in a 20-message conversation costs 60,000 input tokens just for the config file.

Cut your CLAUDE.md to essentials. Move rarely-needed info to separate files that Claude Code reads on demand.

---

## When Claude Code Pays for Itself

The math is straightforward. Compare AI cost against developer time saved.

```
Developer hourly rate (loaded):  $100-200/hour
Average Claude Code session:     $0.50-5.00

If a $3 session saves 30 minutes of work:
  Value: $50-100 saved
  ROI:   16x-33x

If a $10 session saves 2 hours:
  Value: $200-400 saved
  ROI:   20x-40x
```

Claude Code almost always pays for itself on:
- Debugging unfamiliar code (saves hours of reading)
- Writing boilerplate tests (saves tedium)
- Code reviews (catches issues faster)
- Explaining legacy code (no more "who wrote this and why")

It does NOT pay for itself when:
- You use it as a search engine (Google is free)
- You ask it to do things you could do in 30 seconds
- You iterate endlessly on subjective style preferences

---

## Model Selection Guide

| Task Type | Recommended Model | Why |
|-----------|------------------|-----|
| Bug fix with clear error | Sonnet | Straightforward, error message guides the fix |
| Write unit tests | Sonnet | Pattern-following task |
| Code review | Sonnet | Reading + flagging, no complex generation |
| Multi-file refactor | Opus | Needs to hold full architecture in mind |
| System design | Opus | Complex reasoning, trade-off analysis |
| Debug subtle race condition | Opus | Requires deep multi-step reasoning |
| Generate boilerplate | Sonnet | Template-like output |
| Explain complex algorithm | Either | Sonnet for overview, Opus for deep dive |

---

## Real Numbers: Cost Per Task Type

Based on typical usage patterns (Sonnet pricing):

| Task | Messages | Approx. Cost |
|------|----------|-------------|
| Fix a clear bug | 2-3 | $0.10-0.30 |
| Write tests for one file | 3-5 | $0.30-0.80 |
| Code review (single PR) | 2-4 | $0.20-0.60 |
| Implement a feature (small) | 5-10 | $0.80-2.50 |
| Implement a feature (medium) | 10-20 | $2.50-8.00 |
| Large refactor | 15-30 | $5.00-20.00 |
| Architecture exploration | 5-10 | $0.50-3.00 |

Multiply by roughly 5x for Opus on the same tasks.

---

## Red Flags: Runaway Costs

Watch for these patterns that burn tokens with little value:

### Infinite Loops

Claude Code tries a fix, it fails, it tries again, it fails differently, it reverts, it tries a third approach. You are paying for every iteration. If you see two failed attempts, intervene. Provide more context or a different approach.

### Large File Reads

Claude Code reading a 5,000-line file costs ~7,000 input tokens. If it reads that file in every message of a 10-message conversation, that is 70,000 tokens just for one file. Tell it which functions or line ranges matter.

```
Bad:  "Read src/app.ts and find the bug"
Good: "The bug is in src/app.ts in the handleRequest function (lines 140-180)"
```

### Verbose Prompts

Developers who write essay-length prompts are paying for essay-length input. Be concise:

```
Expensive (150 tokens):
"I was working on the user authentication system and I noticed that when
a user tries to log in with an expired token, the system doesn't properly
handle the refresh flow. I think the issue might be in the middleware
but I'm not sure. Could you take a look and maybe fix it?"

Cheap (30 tokens):
"In src/middleware/auth.ts, the expired token case falls through without
triggering a refresh. Fix the handleExpiredToken function."
```

### Regenerating Lost Context

If you close a session and start a new one to continue the same task, you lose all context and pay to rebuild it. Use tmux to keep sessions alive. Use `/compact` to compress context when sessions get long rather than starting over.

---

## Monthly Cost Checklist

- [ ] Review API dashboard spend vs budget
- [ ] Check per-developer usage for outliers
- [ ] Identify sessions with >30 messages (probably should have been split)
- [ ] Verify CLAUDE.md has not grown beyond what is necessary
- [ ] Confirm team is using Sonnet for routine tasks
- [ ] Log any runaway cost incidents and root causes

## Next Steps

- [Token Optimization](../05-advanced/token-optimization.md) -- Deep dive into token-level efficiency
- [Context Management](../03-prompts/context-management.md) -- Manage context to reduce unnecessary token usage
