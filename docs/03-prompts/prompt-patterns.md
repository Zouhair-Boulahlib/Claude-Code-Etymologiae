# Prompt Patterns

> Copy-pasteable templates for common development tasks. Adapt the bracketed sections to your codebase.

## How to Use This Guide

Each pattern has four parts:
- **The template** -- copy it, fill in the brackets
- **When to use it** -- the scenario it fits
- **Example** -- a filled-in version for a real task
- **Why it works** -- what makes the pattern effective

These are starting points, not rigid formulas. Modify them to fit your codebase and conventions.

---

## Bug Fix Patterns

### 1. The Targeted Bug Fix

**Template:**
```
There's a bug in [file path]: [describe the incorrect behavior].
Expected behavior: [what should happen].
Actual behavior: [what happens instead].
[Optional: steps to reproduce or relevant error message.]
Fix it without changing the public API.
```

**When to use it:** You know where the bug is and can describe the symptoms. The most common pattern you will use.

**Example:**
```
There's a bug in src/services/pricing.ts: the calculateDiscount function
returns negative prices when the discount percentage exceeds 100.
Expected behavior: discount should cap at 100%, resulting in a price of 0.
Actual behavior: a 150% discount on a $20 item returns -$10.
Fix it without changing the public API.
```

**Why it works:** Specific location eliminates search time. Expected vs actual makes the fix unambiguous. The API constraint prevents unnecessary refactoring.

### 2. The Diagnostic Bug Fix

**Template:**
```
[Describe the symptom]. I don't know the root cause.
Relevant error: [error message or stack trace excerpt].
Start by identifying the cause, explain it, then fix it.
Only modify files that are actually broken -- don't refactor adjacent code.
```

**When to use it:** You see the symptom but do not know why it happens. Lets the AI investigate before jumping to a fix.

**Example:**
```
Users report that uploading a profile image works on the first attempt
but fails silently on subsequent attempts until they refresh the page.
Relevant error: no errors in the browser console or server logs.
Start by identifying the cause, explain it, then fix it.
Only modify files that are actually broken -- don't refactor adjacent code.
```

**Why it works:** Forcing explanation before fix prevents the AI from applying a superficial patch. The "don't refactor" constraint keeps the diff focused.

---

## Feature Implementation Patterns

### 3. The Spec-Driven Feature

**Template:**
```
Add [feature] to [location].

Requirements:
- [Requirement 1]
- [Requirement 2]
- [Requirement 3]

Constraints:
- Follow the pattern in [reference file]
- [Any technical constraints]
- Include tests in [test location]
```

**When to use it:** You have clear requirements and want the AI to implement them precisely. Best for well-defined features.

**Example:**
```
Add a PATCH /users/:id endpoint to src/api/routes/users.ts.

Requirements:
- Accepts partial updates: { name?, email?, role? }
- Validates email format if provided
- Only admins can change role (check req.user.role)
- Returns the updated user object

Constraints:
- Follow the pattern in src/api/routes/products.ts (update endpoint)
- Use the existing UserService.update() method
- Include tests in src/api/__tests__/users.test.ts
```

**Why it works:** Numbered requirements are checkable -- you can verify each one. Reference files give the AI a concrete pattern to follow, reducing invention.

### 4. The Pattern Extension

**Template:**
```
Look at how [existing feature] works in [reference files].
Apply the same pattern to create [new feature].
Keep the same structure, naming conventions, and error handling.
[Any differences from the reference.]
```

**When to use it:** Your codebase already has a pattern and you want the AI to replicate it for a new resource, entity, or module.

**Example:**
```
Look at how the Product CRUD works across:
- src/db/entities/product.ts
- src/services/product.ts
- src/api/routes/products.ts
- src/api/__tests__/products.test.ts

Apply the same pattern to create Category CRUD.
Keep the same structure, naming conventions, and error handling.
Differences: Category has fields (id, name, description, parentId) and
parentId is a self-referential foreign key (categories can nest).
```

**Why it works:** The AI reads real code from your project instead of inventing conventions. The explicit differences section prevents it from blindly copying things that should be different.

---

## Refactoring Patterns

### 5. The Scoped Refactor

**Template:**
```
Refactor [what] in [file(s)].
Goal: [why -- what improvement you want].
Constraints:
- Don't change external behavior (all existing tests must still pass)
- Don't change the public API / function signatures
- [Specific scope limitation]
```

**When to use it:** You want internal improvements without external risk. The constraints prevent the refactor from spiraling.

**Example:**
```
Refactor the order processing logic in src/services/order.ts.
Goal: the processOrder function is 180 lines with deeply nested if/else.
Break it into smaller functions with clear names.
Constraints:
- Don't change external behavior (all existing tests must still pass)
- Don't change the public API (processOrder signature stays the same)
- Keep all extracted functions in the same file for now
```

**Why it works:** "All existing tests must still pass" is the ultimate safety net. The scope limitation ("same file") prevents the AI from reorganizing your entire project.

### 6. The Rename/Move Refactor

**Template:**
```
Rename [old name] to [new name] everywhere in the codebase.
Update all imports, references, types, and tests.
[Or: Move [file] from [old path] to [new path] and update all imports.]
Don't change any logic -- this is purely a rename/move.
```

**When to use it:** Mechanical refactors that touch many files but should not change behavior. The AI excels at this.

**Example:**
```
Rename the UserDTO interface to UserResponse everywhere in the codebase.
Update all imports, references, types, and tests.
Don't change any logic -- this is purely a rename.
```

**Why it works:** The "don't change any logic" constraint makes it clear this is a mechanical operation. The AI is very good at finding and updating all references.

---

## Code Review Patterns

### 7. The Review Request

**Template:**
```
Review [file(s)] for:
- [Specific concern 1]
- [Specific concern 2]
- [Specific concern 3]

For each issue found, explain the problem and suggest a concrete fix.
Don't make changes -- just report findings.
```

**When to use it:** You want a second opinion on code you or someone else wrote. The specific concerns focus the review instead of getting generic "consider using const" feedback.

**Example:**
```
Review src/api/middleware/auth.ts and src/services/auth.ts for:
- Security vulnerabilities (token handling, password storage, timing attacks)
- Error messages that leak internal details to the client
- Edge cases that could cause crashes (null/undefined, empty strings)

For each issue found, explain the problem and suggest a concrete fix.
Don't make changes -- just report findings.
```

**Why it works:** Focused review criteria get actionable findings. "Don't make changes" prevents the AI from silently fixing things you wanted to know about.

---

## Testing Patterns

### 8. The Test Suite Generator

**Template:**
```
Write tests for [file/function] in [test file location].
Cover:
- Happy path: [describe the normal case]
- Edge cases: [list specific edge cases]
- Error cases: [list expected failure modes]
Use [test framework] and follow the patterns in [existing test file].
```

**When to use it:** You have code that needs tests and you know what the important cases are. Better than "write tests for this file" because you specify coverage expectations.

**Example:**
```
Write tests for src/services/pricing.ts in src/services/__tests__/pricing.test.ts.
Cover:
- Happy path: single item, multiple items, with and without discount codes
- Edge cases: empty cart, zero-priced items, discount that exceeds item price
- Error cases: invalid discount code, expired discount, negative quantity
Use Vitest and follow the patterns in src/services/__tests__/order.test.ts.
```

**Why it works:** Explicit test cases ensure coverage of the scenarios you care about. Referencing an existing test file keeps style consistent. The AI will not just test the happy path.

### 9. The Test Fix

**Template:**
```
The test [test name] in [test file] is failing with:
[error message]

The test was passing before [describe what changed].
Fix the test to match the new behavior -- don't revert the code change.
[Or: Fix the code to match what the test expects -- the test is correct.]
```

**When to use it:** A code change broke a test and you need to decide which side to fix. Being explicit about which side is "correct" prevents confusion.

**Example:**
```
The test "should return 401 for expired tokens" in
src/api/__tests__/auth.test.ts is failing with:
"Expected status 401, received 403"

The test was passing before we added role-based authorization in the
auth middleware. Fix the test to match the new behavior -- the middleware
now returns 403 for valid-but-unauthorized tokens and 401 for
invalid/expired tokens. The new behavior is correct.
```

**Why it works:** Telling the AI which side is the source of truth eliminates ambiguity. Without this, it might "fix" the test by reverting the code behavior.

---

## Documentation Patterns

### 10. The API Documentation Generator

**Template:**
```
Generate API documentation for the endpoints in [route file(s)].
For each endpoint, document:
- Method and path
- Request body / query parameters (with types)
- Response format (with example)
- Error responses
- Authentication requirements
Format as [markdown/OpenAPI/JSDoc].
```

**When to use it:** You have working endpoints and need documentation generated from the actual code.

**Example:**
```
Generate API documentation for the endpoints in src/api/routes/users.ts.
For each endpoint, document:
- Method and path
- Request body / query parameters (with types)
- Response format (with example JSON)
- Error responses (status codes and body)
- Authentication requirements (which roles)
Format as markdown in docs/api/users.md.
```

**Why it works:** Structured format ensures consistent documentation. The AI reads the actual code, so the docs match the implementation rather than an outdated spec.

---

## Migration Patterns

### 11. The Incremental Migration

**Template:**
```
Migrate [file/module] from [old pattern] to [new pattern].
Reference: [file already migrated] shows the target pattern.
Requirements:
- All existing tests must pass after migration
- No behavior changes -- this is a mechanical conversion
- [Any specific migration rules]
```

**When to use it:** You are migrating a codebase incrementally -- one file at a time -- and have a reference for the target state.

**Example:**
```
Migrate src/services/order.ts from callbacks to async/await.
Reference: src/services/product.ts has already been migrated and shows
the target pattern.
Requirements:
- All existing tests must pass after migration
- No behavior changes -- this is a mechanical conversion
- Replace .then().catch() chains with try/catch blocks
- Keep the same function signatures (callers should not need to change)
```

**Why it works:** A reference file beats abstract instructions every time. The AI matches a concrete target instead of guessing your preferred style.

---

## Performance Patterns

### 12. The Performance Investigation

**Template:**
```
[File/function] is slow. [Describe the symptom: response time, memory usage, etc.]
Analyze the code and identify the likely bottlenecks.
For each bottleneck:
- Explain why it's slow
- Suggest a specific fix with estimated impact
- Note any tradeoffs (memory vs speed, complexity vs performance)
Don't make changes yet -- I want to review the analysis first.
```

**When to use it:** You have a performance problem and want diagnosis before treatment. The AI can spot N+1 queries, unnecessary allocations, and algorithmic inefficiencies from reading the code.

**Example:**
```
src/services/report.ts generateMonthlyReport() takes 45 seconds for
accounts with more than 10,000 transactions. It should complete in
under 5 seconds.
Analyze the code and identify the likely bottlenecks.
For each bottleneck:
- Explain why it's slow
- Suggest a specific fix with estimated impact
- Note any tradeoffs
Don't make changes yet -- I want to review the analysis first.
```

**Why it works:** "Don't make changes yet" prevents premature optimization. Getting the analysis first lets you choose which fixes to apply based on effort vs impact. The AI often spots the obvious bottleneck (N+1 query, missing index, loading everything into memory) quickly.

---

## Quick Reference Card

| Scenario | Key Pattern Element | Template # |
|----------|-------------------|-----------|
| Know where the bug is | Expected vs actual behavior | 1 |
| Bug with unknown cause | "Identify the cause first" | 2 |
| Clear requirements | Numbered requirements + constraints | 3 |
| Extending existing patterns | "Look at X, apply same pattern to Y" | 4 |
| Internal cleanup | "Don't change external behavior" | 5 |
| Mechanical rename/move | "Don't change any logic" | 6 |
| Want feedback, not changes | "Don't make changes -- just report" | 7 |
| Need comprehensive tests | Explicit happy/edge/error cases | 8 |
| Broken test after code change | Specify which side is correct | 9 |
| Document existing code | Structured per-endpoint format | 10 |
| One-at-a-time migration | Reference file as target state | 11 |
| Slow code investigation | "Diagnose before fixing" | 12 |

## Combining Patterns

Real tasks often combine patterns. A feature implementation (3) followed by a review (7) followed by test generation (8) is a common sequence. A bug fix (1 or 2) followed by a test (8) that prevents regression is another.

The key principle across all patterns: **constrain the output**. Every constraint you add -- "don't change the API", "follow this pattern", "include tests" -- reduces the chance the AI produces something you have to redo.

## Next Steps

- [Effective Prompting](effective-prompting.md) -- The fundamentals behind these patterns
- [Multi-Step Tasks](multi-step-tasks.md) -- Combine patterns into multi-step workflows
- [Context Management](context-management.md) -- Keep context efficient when chaining patterns
