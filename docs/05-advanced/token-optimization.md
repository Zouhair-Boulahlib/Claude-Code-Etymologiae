# Token Optimization Techniques

> Understand how tokens work, why they matter, and practical tools and techniques to minimize usage without sacrificing output quality.

## Why Tokens Matter

Every interaction with an AI coding assistant consumes tokens - the atomic units of text that the model processes. More tokens = more cost, more latency, and faster context window exhaustion.

## How Token Counting Works Technically

Language models use **tokenizers** (like BPE - Byte Pair Encoding) to split text into tokens. The tokenizer has a fixed vocabulary of ~100K tokens learned from training data.

---

## Tool: Repomix (RTK)

### What It Is
[Repomix](https://github.com/yamadashy/repomix) (formerly Repopack) packs your entire repository into a single, AI-friendly file - optimized for minimal token usage while preserving maximum context.

### Installation and Usage

```bash
npm install -g repomix

# Pack entire repo
repomix

# Pack specific directories
repomix --include "src/api/**,src/models/**"

# With comment removal and compression
repomix --remove-comments --compress
```

### How Repomix Optimizes Tokens

#### 1. Intelligent File Filtering

Without Repomix, you might include node_modules (73K tokens), package-lock.json (45K tokens), dist bundles (28K tokens). Repomix automatically excludes these.

**Savings: 90%+ of raw repo size.**

#### 2. Smart Formatting

Repomix uses structured delimiters that models parse efficiently, eliminating natural language wrappers around each file.

**Savings: ~15-20% per file.**

#### 3. Comment and Whitespace Stripping

Before (with JSDoc, inline comments):
```javascript
/**
 * Calculates the total price for all items in the cart,
 * applying discounts based on membership tier.
 * @param {CartItem[]} items
 * @param {User} user
 * @returns {number}
 */
function calculateTotal(items, user) {
    // Initialize the running total
    let total = 0;
    // Iterate through each item
    for (const item of items) {
        // Get base price
        const basePrice = item.price * item.quantity;
        // Apply discount
        const discount = getDiscount(user.tier, item.category);
        total += basePrice * (1 - discount);
    }
    // Return the final total
    return total;
}
```
**~95 tokens**

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
**~52 tokens - 45% reduction, zero information loss for AI.**

#### 4. Full Project Comparison

| Method | Tokens | Percentage |
|--------|--------|-----------|
| Raw inclusion of everything | ~180,000 | 100% |
| Manual copy of src/ only | ~8,800 | 4.9% |
| Repomix (default) | ~6,200 | 3.4% |
| Repomix (--remove-comments --compress) | ~4,100 | 2.3% |

**97.7% reduction from naive inclusion.**

---

## Tool: Claude Code Built-in Context Management

### 1. Automatic Context Compaction

When the context window fills up, older messages are summarized. Critical information is preserved, redundant content is removed.

### 2. The /compact Command

```
/compact
/compact focus on the authentication refactor
```

Use after dead-end exploration, long debugging sessions, or before starting a new subtask.

### 3. Subagent Isolation

```
Main context: 50K tokens (your conversation)
  Agent subcontext: separate 200K window
    Reads 50 files, searches codebase
    Returns only ~500 token summary
```

Massive internal consumption, minimal impact on your main context.

---

## Tool: .claudeignore

```gitignore
node_modules/
dist/
build/
*.min.js
*.map
coverage/
.next/
```

Every file read consumes context tokens. This prevents wasted reads.

---

## Tool: aider (Repository Map)

[aider](https://github.com/paul-gauthier/aider) sends structural representations (~50 tokens) instead of full files (~800 tokens).

---

## Tool: gpt-tokenizer / tiktoken

Count tokens before sending:

```javascript
import { encode } from 'gpt-tokenizer';
console.log(encode(text).length + ' tokens');
```

```python
import tiktoken
enc = tiktoken.get_encoding("cl100k_base")
print(len(enc.encode(text)), 'tokens')
```

---

## Technique: Precise File References

Bad: "Look at the auth code" (AI reads 15 files = ~12,000 tokens)
Good: "Fix src/middleware/auth.ts line 45" (AI reads 1 file = ~400 tokens)

**95%+ savings.**

---

## Technique: Iterative Over Monolithic

Build in rounds. Review each. Commit. Then next round. Same total tokens, but each round is reviewable and reversible.

---

## Technique: Response Calibration

In CLAUDE.md:
```markdown
## Response Style
- Terse responses, no trailing summaries
- Show diffs, not full files
- Only explain non-obvious changes
```

**Savings: 40-60% on responses.**

---

## Summary: Token Optimization Hierarchy

| Technique | Typical Savings | Effort |
|-----------|----------------|--------|
| .claudeignore / file filtering | 90%+ of noise | 2 minutes |
| Precise file references | 80-95% per read | Zero |
| Repomix for bulk context | 95%+ vs raw repo | 5 min setup |
| Subagents for research | Isolates 80%+ of search | Zero |
| CLAUDE.md persistent context | 200+ tokens/conversation | 15 minutes |
| Comment stripping (Repomix) | 30-50% per file | Zero |
| /compact for long sessions | Recovers 30-50% context | Zero |
| Response calibration | 40-60% on responses | One prompt |

The single best optimization: **be specific about what you want and where it is.**
