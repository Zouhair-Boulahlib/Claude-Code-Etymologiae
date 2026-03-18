# Debugging AI Output

> When the suggestions are wrong -- how to recognize it, fix it, and know when to walk away.

## The Core Problem

AI output is not randomly wrong. It is wrong in specific, predictable ways. Understanding those failure modes is the difference between catching a bug in review and shipping it to production.

The danger is not that AI writes obviously broken code. The danger is that it writes code that looks correct, compiles, passes superficial review -- and fails at the edges.

## Failure Mode 1: Confident but Wrong

The AI presents incorrect information with the same tone and confidence as correct information. There is no hedging, no "I'm not sure about this." It just states the wrong thing as fact.

### Example: Hallucinated API

```typescript
// AI-generated code
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(url, key);

// This method does not exist
const { data } = await supabase
  .from('users')
  .select('*')
  .withGraph('posts.comments')  // <-- fabricated API
  .limit(10);
```

The `.withGraph()` method does not exist in the Supabase client. The AI borrowed it from Objection.js (a different ORM) and applied it here because the pattern looked plausible.

**How to catch it:** If you see a method or option you have not used before, check the actual library documentation. Do not trust the AI's implication that it exists. Run the code -- a `TypeError: .withGraph is not a function` would catch this immediately.

### Example: Wrong Function Signature

```python
# AI-generated code
from datetime import datetime

# strptime's format codes are wrong
date = datetime.strptime("2024-03-15", "%Y-%D-%M")
```

The correct format is `"%Y-%m-%d"`. The AI swapped `%D` (not a valid directive) and `%M` (minutes, not months). This code throws a `ValueError` at runtime, but if you are reviewing it quickly, the line looks plausible.

**How to catch it:** For standard library calls, verify format strings and argument order against the documentation. These are the most common micro-errors in AI output.

## Failure Mode 2: Plausible but Non-Functional

The code looks like it should work. It follows the right patterns. But there is a logic error, a missing step, or an incorrect assumption that makes it fail in practice.

### Example: Race Condition in Async Code

```javascript
// AI-generated code
async function transferFunds(fromId, toId, amount) {
  const sender = await db.accounts.findById(fromId);
  const receiver = await db.accounts.findById(toId);

  if (sender.balance < amount) {
    throw new Error('Insufficient funds');
  }

  await db.accounts.update(fromId, { balance: sender.balance - amount });
  await db.accounts.update(toId, { balance: receiver.balance + amount });
}
```

This has a textbook race condition. Between reading the balance and updating it, another request could modify the same account. Two concurrent transfers could both pass the balance check. The fix requires a database transaction with row-level locking -- which the AI did not include because the prompt did not mention concurrency.

**How to catch it:** For any code that reads then writes shared state, ask: "What happens if two requests hit this at the same time?" If the AI did not use a transaction or lock, it probably has a race condition.

### Example: Silent Data Loss

```python
# AI-generated code
def parse_csv_records(file_path):
    records = []
    with open(file_path) as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                records.append({
                    'name': row['name'],
                    'amount': float(row['amount']),
                    'date': datetime.strptime(row['date'], '%Y-%m-%d'),
                })
            except (ValueError, KeyError):
                continue  # <-- silently drops malformed rows
    return records
```

The `except ... continue` silently discards any row with a parsing error. If your CSV has a date formatted as `03/15/2024` instead of `2024-03-15`, every single row gets dropped, and the function returns an empty list with no error. The AI chose resilience over correctness -- a reasonable-looking decision that is usually wrong for data processing.

**How to catch it:** Look for bare `except` or `except ... continue/pass` in AI output. Ask: "What happens when this exception fires? Should we log it? Should we fail?"

## Failure Mode 3: Works but Insecure

The code functions correctly. It does what you asked. But it has a security vulnerability that the AI did not flag.

### Example: SQL Injection via String Interpolation

```python
# AI-generated code
def search_users(query):
    sql = f"SELECT * FROM users WHERE name LIKE '%{query}%'"
    return db.execute(sql)
```

Classic SQL injection. The AI used f-string interpolation instead of parameterized queries. This works perfectly for normal input and is exploitable with trivial malicious input like `'; DROP TABLE users; --`.

**How to catch it:** Any time AI generates database queries, check whether user input is interpolated into the query string. The fix is parameterized queries:

```python
def search_users(query):
    sql = "SELECT * FROM users WHERE name LIKE %s"
    return db.execute(sql, (f'%{query}%',))
```

### Example: Missing Authorization Check

```typescript
// AI-generated code
app.delete('/api/posts/:id', async (req, res) => {
  const post = await db.posts.findById(req.params.id);
  if (!post) return res.status(404).json({ error: 'Not found' });

  await db.posts.delete(req.params.id);
  res.json({ success: true });
});
```

The endpoint checks if the post exists but never checks if the requesting user owns it. Any authenticated user can delete any post. The AI implemented the happy path -- find and delete -- without considering authorization.

**How to catch it:** For every mutating endpoint (POST, PUT, DELETE), ask: "Who is allowed to do this? Where is that checked?" If the AI did not include an ownership or role check, it is missing.

## Failure Mode 4: Outdated Patterns

The AI uses patterns from an older version of a library or framework.

### Example: Deprecated React Patterns

```jsx
// AI-generated code
class UserProfile extends React.Component {
  componentWillMount() {  // <-- deprecated since React 16.3
    this.fetchUser();
  }

  componentWillReceiveProps(nextProps) {  // <-- deprecated
    if (nextProps.userId !== this.props.userId) {
      this.fetchUser(nextProps.userId);
    }
  }
  // ...
}
```

The AI generated a class component with deprecated lifecycle methods. Modern React uses functional components with hooks. This code works in React 16 but triggers warnings, and the patterns are removed in React 19.

**How to catch it:** If the AI generates code that uses patterns you have not seen in recent documentation, check whether those patterns are current. This is especially common with rapidly-evolving frameworks like React, Next.js, and Vue.

### Example: Old Node.js Callback Style

```javascript
// AI-generated code
const fs = require('fs');  // <-- CommonJS in an ESM project

fs.readFile('config.json', 'utf8', function(err, data) {  // <-- callback style
  if (err) throw err;
  const config = JSON.parse(data);
  // ...
});
```

Modern Node.js uses `import` and `fs/promises`:

```javascript
import { readFile } from 'fs/promises';
const config = JSON.parse(await readFile('config.json', 'utf8'));
```

**How to catch it:** If your CLAUDE.md specifies the module system and Node version, the AI will usually get this right. Without that context, it falls back to the style most represented in training data -- which is often older.

## Failure Mode 5: Subtly Wrong Logic

The code is almost correct. It handles 95% of cases. But there is an edge case that produces wrong results silently.

### Example: Off-by-One in Date Range

```typescript
// AI-generated code
function getBusinessDays(start: Date, end: Date): number {
  let count = 0;
  const current = new Date(start);
  while (current < end) {  // <-- should be <=
    const day = current.getDay();
    if (day !== 0 && day !== 6) count++;
    current.setDate(current.getDate() + 1);
  }
  return count;
}
```

The `<` should be `<=` if you want to include the end date. This is correct for half-open intervals and wrong for closed intervals. The AI picked one interpretation. Whether it is correct depends on your business requirement -- which the AI did not ask about.

**How to catch it:** Boundary conditions are where AI logic errors hide. For any loop or range, ask: "What about the first element? What about the last element? What about an empty input?"

### Example: Floating Point Comparison

```javascript
// AI-generated code
function applyDiscount(price, discountPercent) {
  const discounted = price * (1 - discountPercent / 100);
  if (discounted === 0) {  // <-- floating point comparison
    return 0;
  }
  return Math.round(discounted * 100) / 100;
}

// applyDiscount(10.10, 100) returns 1.78e-15, not 0
// because 10.10 * 0 in floating point is not exactly 0
```

The `=== 0` check fails due to floating-point precision. The AI should have used `Math.abs(discounted) < 0.001` or handled the 100% discount case explicitly.

**How to catch it:** Any time AI code compares floating-point numbers with `===` or `==`, flag it. This is a known class of bugs that AI consistently produces.

## Course-Correction Techniques

### Be Specific About What Is Wrong

```
Bad:  "That's wrong, try again"
Good: "The transferFunds function has a race condition. Two concurrent
       transfers can both pass the balance check. Wrap the read and
       write in a database transaction with SELECT FOR UPDATE."
```

The more precisely you identify the problem, the better the fix.

### Provide a Counterexample

```
"Your getBusinessDays function returns 4 for Monday to Friday of
the same week, but it should return 5 because both endpoints are
business days. The issue is the < comparison -- it should be <=."
```

Showing a concrete input/output mismatch is the fastest way to get a correct fix.

### Ask It to Critique Its Own Code

```
"Review the code you just wrote for:
1. Race conditions
2. Missing error handling
3. Security vulnerabilities
4. Edge cases with empty or null inputs"
```

AI is often better at finding bugs in code than avoiding them during generation. Use this to your advantage.

### Try a Fresh Conversation

If you have gone three rounds trying to fix something and it keeps regressing, start a new conversation. Long conversations accumulate context that can lock the AI into a bad approach. A clean start often produces a better solution on the first try.

### Constrain the Approach

```
"Don't use recursion for this -- use an iterative approach with
an explicit stack. The recursive version you wrote hits the call
stack limit for deep trees."
```

When the AI picks the wrong approach, do not just say it is wrong -- tell it which approach to use instead.

## When to Abandon AI and Do It Manually

Stop using AI for a task when:

- **You have gone 4+ rounds** and the code is getting worse, not better
- **The bug is in subtle domain logic** that requires understanding your business rules
- **The AI keeps "fixing" things by adding complexity** instead of finding the root cause
- **You cannot verify correctness** because you do not understand the domain well enough to check
- **The task requires integration knowledge** -- how your specific systems interact at runtime

There is no shame in writing code manually. AI is a tool, not a mandate. The fastest path to correct code is sometimes your own keyboard.

## Verification Checklist

Before accepting any non-trivial AI output, run through this:

```
[ ] Does this compile/parse without errors?
[ ] Do existing tests still pass?
[ ] Have I read every line of the diff?
[ ] For new APIs/methods used -- do they actually exist? (check docs)
[ ] For database operations -- is there a transaction where needed?
[ ] For user input -- is it validated and sanitized?
[ ] For auth-required endpoints -- is authorization checked?
[ ] For async code -- what happens with concurrent access?
[ ] For loops and ranges -- are boundary conditions correct?
[ ] For error handling -- are errors logged/surfaced, not swallowed?
```

You do not need all ten checks for every change. A one-line CSS fix does not need a concurrency review. But for anything touching data, auth, or business logic -- run the full list.

## The Pattern

AI mistakes follow a pattern: **the code does what you asked, but not what you meant.** The gap between "asked" and "meant" is where bugs live.

Close that gap by:
1. Writing precise prompts that include constraints and edge cases
2. Reviewing output with adversarial eyes -- "how could this fail?"
3. Testing with boundary inputs, not just happy-path data
4. Verifying API calls against actual documentation
5. Asking the AI to critique its own output before you accept it

The developers who get the most from AI tools are not the ones who accept the most output. They are the ones who catch the most mistakes.

## Next Steps

- [Common Mistakes](common-mistakes.md) -- Broader anti-patterns in AI-assisted development
- [Over-Engineering Traps](over-engineering.md) -- When the code is wrong by being too much
- [Effective Prompting](../03-prompts/effective-prompting.md) -- Write prompts that prevent mistakes
