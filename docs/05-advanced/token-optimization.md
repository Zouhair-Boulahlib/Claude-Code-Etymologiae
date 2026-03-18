# Token Optimization Techniques

> Understand how tokens work, why they matter, and practical tools and techniques to minimize usage without sacrificing output quality.

## Why Tokens Matter

Every interaction with an AI coding assistant consumes tokens — the atomic units of text that the model processes. Tokens map roughly to word fragments:

```
"Hello world"            -> 2 tokens
"authentication"         -> 1 token
"src/components/App.tsx" -> 5 tokens
```

More tokens = more cost, more latency, and faster context window exhaustion. Optimizing token usage means:
- **Faster responses** — less to process
- **Lower cost** — directly proportional to token count
- **More room in context** — keep important information longer
- **Better output quality** — less noise means clearer signal

## How Token Counting Works Technically

Language models use **tokenizers** (like BPE — Byte Pair Encoding) to split text into tokens. The tokenizer has a fixed vocabulary of ~100K tokens learned from training data.

### Tokenization in Practice

```python
# "function calculateTotal(items) {" breaks down as:

"function"      -> 1 token   (common word, single token)
" calculate"    -> 1 token   (space + common prefix)
"Total"         -> 1 token   (common camelCase fragment)
"("             -> 1 token
"items"         -> 1 token
")"             -> 1 token
" {"            -> 1 token
                = 7 tokens total
```

Whitespace, formatting, and verbose naming all consume tokens. This matters when your context window has a fixed ceiling.

---

## Tool: Repomix (RTK — Repomix Token Kit)

### What It Is
[Repomix](https://github.com/yamadashy/repomix) (formerly Repopack) is a tool that packs your entire repository into a single, AI-friendly file — optimized for minimal token usage while preserving maximum context.

### Installation

```bash
npm install -g repomix
```

### Basic Usage

```bash
# Pack entire repo
repomix

# Pack specific directories
repomix --include "src/api/**,src/models/**"

# Pack with token count
repomix --output repomix-output.txt
```

### How Repomix Optimizes Tokens — Detailed Breakdown

#### 1. Intelligent File Filtering

Repomix automatically excludes files that waste tokens:

```bash
# Without Repomix: you might accidentally include these in context
node_modules/lodash/lodash.js          -> 73,000 tokens (!)
package-lock.json                      -> 45,000 tokens
dist/bundle.min.js                     -> 28,000 tokens
.git/objects/...                       -> thousands of tokens

# With Repomix: automatically excluded
# Only your actual source code is included
```

**Token savings: Often 90%+ of raw repo size eliminated.**

#### 2. Smart Formatting

Repomix uses a structured format that models parse efficiently:

```
================
File: src/api/auth.ts
================
import { Router } from 'express';
import { validateLogin } from '../validators/auth';
// ... actual code
```

Compare to manually pasting with natural language wrappers around each file — Repomix eliminates those extra tokens.

**Token savings: ~15-20% per file from eliminating natural language wrappers.**

#### 3. Comment and Whitespace Stripping

```bash
repomix --remove-comments --compress
```

Before (with comments and whitespace):
```javascript
/**
 * Calculates the total price for all items in the cart,
 * applying any applicable discounts based on the user's
 * membership tier and active promotions.
 *
 * @param {CartItem[]} items - Array of cart items
 * @param {User} user - The current user
 * @returns {number} The final calculated total
 */
function calculateTotal(items, user) {
    // Initialize the running total
    let total = 0;

    // Iterate through each item
    for (const item of items) {
        // Get base price
        const basePrice = item.price * item.quantity;

        // Apply discount if applicable
        const discount = getDiscount(user.tier, item.category);
        total += basePrice * (1 - discount);
    }

    // Return the final total
    return total;
}
```
**Token count: ~95 tokens**

After stripping:
```javascript
function calculateTotal(items, user) {
    let total = 0;
    for (const item of items) {
        const basePrice = item.price * item.quantity;
        const discount = getDiscount(user.tier, item.category);
        total += basePrice * (1 - discount);
    }
    return total;
}
```
**Token count: ~52 tokens — 45% reduction, zero information loss for AI.**

The AI does not need JSDoc to understand what `calculateTotal(items, user)` does. It infers types and purpose from the code itself.

#### 4. Concrete Example: Full Project Comparison

Consider a typical Node.js API project:

```
my-api/
  src/
    routes/        (8 files,  ~2,400 tokens)
    models/        (6 files,  ~1,800 tokens)
    middleware/     (4 files,  ~800 tokens)
    utils/         (3 files,  ~600 tokens)
  tests/           (12 files, ~3,200 tokens)
  node_modules/    (1,200+ packages)
  package-lock.json (~45,000 tokens)
  dist/            (compiled output)
  .env             (secrets — never include!)
```

| Method | Tokens | Percentage |
|--------|--------|-----------|
| Raw inclusion of everything | ~180,000 | 100% |
| Manual copy of src/ only | ~8,800 | 4.9% |
| Repomix (default) | ~6,200 | 3.4% |
| Repomix (--remove-comments --compress) | ~4,100 | 2.3% |

**That is a 97.7% reduction from naive inclusion.**

### Repomix Configuration File

Create a `repomix.config.json` for project-specific settings:

```json
{
  "output": {
    "filePath": "repomix-output.txt",
    "style": "markdown",
    "removeComments": true,
    "showLineNumbers": false,
    "topFilesLength": 10
  },
  "include": [
    "src/**"
  ],
  "ignore": {
    "useGitignore": true,
    "useDefaultPatterns": true,
    "customPatterns": [
      "**/*.test.ts",
      "**/*.spec.ts",
      "docs/**"
    ]
  }
}
```

---

## Tool: Claude Code Built-in Context Management

Claude Code itself has built-in token optimization:

### 1. Automatic Context Compaction

When the context window fills up, Claude Code automatically compresses earlier messages:

```
[Previous context compressed — key information retained]
```

**How it works technically:**
- The system monitors token usage as the conversation grows
- When approaching the limit, older messages are summarized by a fast model
- Critical information (file paths, decisions, errors) is preserved
- Redundant or verbose content is removed
- The summary replaces the original messages, freeing up token budget

### 2. The /compact Command

Force manual compaction when you know the conversation has accumulated noise:

```
/compact
```

Or with a focus hint:

```
/compact focus on the authentication refactor
```

This tells the compactor what to prioritize keeping.

**When to use it:**
- After exploring multiple dead-end approaches (lots of wasted context)
- After a long debugging session where the fix is found
- Before starting a new subtask in the same conversation
- When you notice responses becoming less coherent (sign of context pressure)

### 3. Subagent Isolation

When Claude Code uses the Agent tool, work happens in an isolated sub-context:

```
Main context: 50K tokens (your conversation)
  Agent subcontext: separate 200K window
    Reads 50 files, searches codebase
    Returns only a concise summary (500 tokens)
```

The subagent can consume massive amounts of tokens internally, but only a concise result enters your main context. This is a massive token optimization for research and exploration tasks.

---

## Tool: .claudeignore / Glob Patterns

Control what Claude Code can see:

```gitignore
# .claudeignore
node_modules/
dist/
build/
*.min.js
*.map
coverage/
.next/
__pycache__/
*.pyc
```

**Token impact:** Prevents the AI from reading files that waste context. Every file read consumes tokens from your context window.

---

## Tool: aider (Code-Specific Token Optimization)

[aider](https://github.com/paul-gauthier/aider) uses a repository map to give AI context without sending full files:

```
# aider builds a "repo map" — a compressed representation:
# Instead of sending full file contents, it sends:

src/api/auth.ts:
  - class AuthController
    - login(req, res)
    - register(req, res)
    - refreshToken(req, res)
  - imports: express, jsonwebtoken, bcrypt
```

This gives the AI structural understanding (~50 tokens) instead of the full file (~800 tokens).

---

## Tool: gpt-tokenizer / tiktoken

Count tokens before sending to understand your budget:

```bash
# Install
npm install gpt-tokenizer

# Or Python
pip install tiktoken
```

```javascript
// JavaScript
import { encode } from 'gpt-tokenizer';

const text = fs.readFileSync('src/api/auth.ts', 'utf-8');
const tokens = encode(text);
console.log(`auth.ts: ${tokens.length} tokens`);
```

```python
# Python
import tiktoken

enc = tiktoken.get_encoding("cl100k_base")
with open("src/api/auth.ts") as f:
    tokens = enc.encode(f.read())
print(f"auth.ts: {len(tokens)} tokens")
```

Use this to identify which files are "expensive" and whether they need to be included.

---

## Technique: Structured CLAUDE.md

A well-written CLAUDE.md saves tokens across every conversation:

```markdown
## Commands
npm test / npm run dev / npm run lint

## Architecture
src/api/ = routes, src/services/ = logic, src/db/ = data
```

**Why this saves tokens:** Without it, you explain the same things in every conversation. With it, the information is loaded once (cheaply) and reused.

**Quantified:** If you spend ~200 tokens explaining your project setup in each conversation, and you have 10 conversations/day, that is 2,000 tokens/day saved by a 50-token CLAUDE.md section.

---

## Technique: Precise File References

```
Bad:  "Look at the auth code and fix the bug"
      (AI reads 15 files searching for "auth code" = ~12,000 tokens wasted)

Good: "Fix the JWT validation bug in src/middleware/auth.ts line 45"
      (AI reads 1 file, goes to line 45 = ~400 tokens)
```

**Token savings: 95%+ for targeted tasks.**

---

## Technique: Iterative Over Monolithic

Instead of describing the entire feature upfront (expensive prompt, massive response):

```
Bad:  "Build a user management system with registration, login,
       password reset, email verification, profiles, avatars,
       admin panel, audit logging, and OAuth"
       (~80 token prompt, ~5000 token response that is hard to review)
```

Build iteratively (cheaper per round, better results):

```
Good: Round 1: "Add POST /register endpoint" (~200 token response)
      [review, commit]
      Round 2: "Add POST /login with JWT" (~200 token response)
      [review, commit]
```

**Total tokens may be similar, but each round is reviewable, reversible, and focused.**

---

## Technique: Response Calibration

When you notice the AI being verbose, calibrate:

```
"From now on, show only the changed lines in diffs, not the full file.
Keep explanations under 2 sentences."
```

Or permanently in CLAUDE.md:

```markdown
## Response Style
- Terse responses, no trailing summaries
- Show diffs, not full files
- Only explain non-obvious changes
```

**Token savings: 40-60% on typical responses.**

---

## Technique: Strategic /clear

The `/clear` command resets your conversation context entirely. Use it when:
- Switching to a completely different task
- The conversation has gone far off track
- You want a "fresh start" with a complex problem

Unlike `/compact` (which preserves key info), `/clear` is a hard reset. Your CLAUDE.md still loads, but conversation history is gone.

---

## Advanced: Skills for Token Optimization

Custom skills (slash commands) can enforce token-efficient patterns automatically.

### /terse -- Force Minimal Output

Create `.claude/skills/terse.md`:

```markdown
---
name: terse
description: Switch to minimal output mode
---

From now on in this conversation:
- Show only changed lines, not full files
- No explanations unless the change is non-obvious
- No summaries after completing a task
- Use inline comments only for complex logic
- Omit import statements if they are obvious
```

Usage: type `/terse` at the start of any session. Saves 40-60% on response tokens for the rest of the conversation.

### /focused-read -- Read Only What Matters

Create `.claude/skills/focused-read.md`:

```markdown
---
name: focused-read
description: Read a file focusing on a specific function or section
---

Read the file provided, but ONLY output:
1. The specific function, class, or section mentioned
2. Its direct dependencies (imports it uses)
3. Nothing else -- no file overview, no other functions

If no specific target is mentioned, output only the public API (exported functions/classes) with their signatures, not implementations.
```

Usage: `/focused-read src/services/auth.ts verifyToken` -- reads the file but only outputs the `verifyToken` function. Typical savings: 70-80% per file read.

### /slim-diff -- Compact Diff Output

Create `.claude/skills/slim-diff.md`:

```markdown
---
name: slim-diff
description: Generate changes as minimal unified diffs
---

When making code changes, output ONLY:
- The file path
- A unified diff with 1 line of context (not 3)
- No explanation before or after

Do not show unchanged files. Do not summarize.
```

---

## Advanced: Hooks for Token Optimization

Hooks execute shell commands on specific events. Several hook patterns reduce token consumption.

### Block Accidental Large File Reads

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read",
        "command": "bash -c \"size=$(wc -c < \"$CLAUDE_FILE_PATH\" 2>/dev/null || echo 0); if [ $size -gt 50000 ]; then echo 'BLOCKED: File is too large. Use Grep to find the relevant section first.' >&2; exit 2; fi\""
      }
    ]
  }
}
```

Prevents AI from reading files over 50KB in a single call. Exit code 2 blocks the tool call. Forces targeted reads instead of consuming 10,000+ tokens on minified bundles or generated files.

### Token Usage Audit Logger

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": ".*",
        "command": "bash -c \"echo \"$(date +%H:%M:%S) $CLAUDE_TOOL_NAME $CLAUDE_FILE_PATH\" >> /tmp/claude-token-audit.log\""
      }
    ]
  }
}
```

Review after a session: "Why did it read 45 files when I only changed 3?" Awareness drives better prompting.

### Auto-Compact Notification

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "context_window",
        "command": "bash -c \"echo 'Context pressure detected. Consider /compact or a fresh conversation.' >&2\""
      }
    ]
  }
}
```

---

## Advanced: CLAUDE.md Token Directives

Your CLAUDE.md is loaded every conversation. Token-aware directives here compound across every session.

### Response Budget

```markdown
## Response Style
- Maximum 20 lines per explanation
- Show diffs not full files
- No trailing summaries
- Only explain non-obvious changes
- Skip import statements in examples unless unusual
```

### Read Strategy

```markdown
## File Reading Rules
- Always Grep to locate code before using Read
- Use Read with offset/limit for files over 200 lines
- Never read node_modules, dist, build, coverage
- For test files, read only the failing test, not the entire suite
```

### Agent Strategy

```markdown
## Agent Usage
- Use Explore agent for codebase structure questions
- Use Grep/Glob for specific file or function lookups
- Never spawn an agent for tasks requiring fewer than 3 file reads
```

---

## Advanced: Conversation Architecture Patterns

### The Checkpoint Pattern

Commit after each step, start fresh:

```
Conversation 1: "Implement User model and migration" -> commit
Conversation 2: "Implement UserService (see latest commit)" -> commit
Conversation 3: "Add REST endpoints for users" -> commit
```

Each conversation: just CLAUDE.md + current task. No accumulated noise.

Token savings: 60-80% vs one long conversation.

### The Scout-Then-Build Pattern

```
Conversation 1 (scout): "How is auth implemented? Which files? What middleware?"
[take notes on the answer]

Conversation 2 (build): "Auth uses JWT in src/middleware/auth.ts with
verification in src/services/tokenService.ts. Add refresh token rotation."
```

Scout does expensive exploration. Build gets pre-digested summary.

Token savings: 50% on the build conversation.

### The Narrowing Funnel

```
Conversation 1: "Overview of payment processing architecture"
Conversation 2: "Explain retry logic in src/payments/webhookHandler.ts"
Conversation 3: "Fix race condition in webhookHandler.ts line 89"
```

Each conversation is cheaper because prompts get more specific.

---

## Summary: Token Optimization Hierarchy

From highest to lowest impact:

| Technique | Typical Savings | Effort |
|-----------|----------------|--------|
| .claudeignore / file filtering | 90%+ of noise | 2 minutes |
| Precise file references in prompts | 80-95% per read | Zero |
| Repomix for bulk context sharing | 95%+ vs raw repo | 5 min setup |
| Checkpoint pattern (fresh conversations) | 60-80% vs long sessions | Zero |
| Subagents for research tasks | Isolates 80%+ of search | Zero |
| CLAUDE.md token directives | Compounds across all sessions | 15 minutes |
| Custom /terse skill | 40-60% on responses | 5 minutes |
| Hook: block large file reads | Prevents 10K+ token waste | 10 minutes |
| Scout-then-build pattern | 50% on build conversations | Zero |
| /focused-read skill | 70-80% per file read | 5 minutes |
| Comment stripping (Repomix flag) | 30-50% per file | Zero |
| /compact for long sessions | Recovers 30-50% context | Zero |
| Token audit logger hook | Awareness for optimization | 5 minutes |
| Token counting tools (tiktoken) | Awareness | 5 minutes |

The single best optimization: **be specific about what you want and where it is.** Everything else is amplification.

## Next Steps

- [Context Management](../03-prompts/context-management.md) — Broader strategies for working within limits
- [Hooks & Automation](hooks.md) — Automate token-saving workflows
