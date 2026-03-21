# Refactoring with AI Assistance

> Restructure code safely, incrementally, and with confidence -- not as a weekend yolo.

## The Golden Rule of AI-Assisted Refactoring

Never change behavior and structure in the same step. This is the single most important principle. Every refactoring prompt should either restructure code or change what it does -- never both at once.

```
"Extract lines 45-89 of src/services/order.ts into a new function called
calculateOrderTotal. Don't change any behavior -- same inputs, same outputs,
just moved into its own function."
```

The phrase "don't change any behavior" is your safety net. It tells the AI to focus purely on structure, and it gives you a clear criterion for reviewing the diff.

## Safe Incremental Refactoring

Large refactors fail. Small refactors shipped in sequence succeed. Here is how to break work down.

### Step 1: Understand Before You Touch

```
"Explain the data flow through src/services/billing.ts. What are the main
responsibilities of this file? Which functions are called externally vs.
used only internally?"
```

This gives you a map before you start moving furniture.

### Step 2: One Structural Change Per Prompt

```
Round 1: "Extract the tax calculation logic (lines 112-145) into a pure
         function called calculateTax at the bottom of the file."

Round 2: "Move calculateTax into a new file src/services/tax.ts and update
         the import in billing.ts."

Round 3: "Extract the discount logic (lines 78-110) into src/services/discount.ts
         following the same pattern as tax.ts."
```

Each round produces a reviewable, testable, committable change.

### Step 3: Run Tests Between Every Step

```
"Run the test suite for the billing module. If anything fails, stop and
show me the failure -- don't try to fix it."
```

If tests break after a pure structural change, something went wrong. Revert and try again with a smaller scope.

## Common Refactoring Patterns

### Extract Function

The most frequent refactoring. Pull a block of code into a named function.

```
"Extract the validation logic in src/api/users.ts lines 34-67 into a
function called validateUserPayload. It should take the request body
and return either the validated data or throw a ValidationError.
Keep it in the same file for now."
```

Specifying the function name, input, output, and location removes ambiguity.

### Rename Across Codebase

Renaming is tedious by hand and trivial with AI. But be explicit about scope.

```
"Rename the UserDTO interface to UserResponse everywhere in the codebase.
This includes type annotations, imports, file names if any file is called
UserDTO.ts, and comments that reference the old name. Show me every file
you change."
```

The key phrase is "show me every file you change." For renames, you want a complete audit trail.

### Move / Split File

Splitting a large file into modules is where AI assistance shines -- it handles the tedious import rewiring.

```
"Split src/services/payment.ts into three files by responsibility:
- src/services/payment/processing.ts -- the charge and refund functions
- src/services/payment/validation.ts -- card validation and fraud checks
- src/services/payment/types.ts -- all interfaces and type definitions

Create a src/services/payment/index.ts barrel file that re-exports
everything so existing imports like `from '../services/payment'` still work."
```

The barrel file instruction is critical -- it prevents breaking every consumer of the old module.

### Replace Implementation, Keep Interface

```
"Replace the hand-rolled CSV parser in src/utils/csv.ts with the 'papaparse'
library. Keep the exact same function signatures -- parseCsvFile(path)
and parseCsvString(content) should return the same shape. Existing tests
must pass without changes."
```

"Existing tests must pass without changes" is the strongest constraint you can give.

## Scope-Limiting Prompts

These phrases keep the AI from wandering:

| Phrase | What It Prevents |
|---|---|
| "Don't change any behavior" | Functional changes sneaking in |
| "Keep the same interface" | Breaking callers |
| "Only touch this file" | Uncontrolled blast radius |
| "Same inputs, same outputs" | Subtle contract changes |
| "Don't add dependencies" | Unnecessary library additions |
| "Existing tests must pass unchanged" | Hidden behavior changes |

Use them liberally. The AI follows constraints better than implications.

## Refactoring With Confidence Using Tests

### Tests First, Refactor Second

If the code you want to refactor has no tests, write them before touching anything.

```
"Before I refactor src/services/notifications.ts, I need tests that lock
in the current behavior. Write integration tests that cover:
1. Sending an email notification
2. Sending a push notification
3. Handling a failed delivery
4. The retry logic for transient failures

Use the existing test patterns in src/services/__tests__/. Mock external
services but test the actual logic."
```

These "characterization tests" capture what the code does today. After refactoring, they verify nothing changed.

### Test-Driven Refactoring Flow

```
Step 1: "Write tests for the current behavior of processOrder in src/services/order.ts"
Step 2: *review and commit tests*
Step 3: "Now extract the inventory check into its own function. Tests must still pass."
Step 4: *verify tests pass, review diff, commit*
Step 5: "Move the extracted function into src/services/inventory.ts"
Step 6: *verify tests pass, review diff, commit*
```

Each step is safe because the tests catch regressions immediately.

### When Tests Fail After Refactoring

```
"The test 'should apply bulk discount for orders over 100 items' is
failing after the extraction. Don't modify the test -- figure out
what the extraction changed about the behavior and fix the extracted
function to match the original behavior."
```

Always fix the code to match the tests, not the other way around. The tests represent the correct behavior.

## Small PRs vs. Big Sweeps

### When to Use Small PRs (Almost Always)

One PR per structural change. Benefits:
- Reviewers can follow the logic
- Easy to revert one step if something breaks
- Merge conflicts stay small
- CI catches issues early

```
PR 1: "Extract tax calculation into tax.ts"
PR 2: "Extract discount logic into discount.ts"
PR 3: "Extract shipping cost into shipping.ts"
PR 4: "Simplify billing.ts now that helpers are extracted"
```

### When a Big Sweep Is Acceptable

A single large PR is justified when:
- You are doing a mechanical rename across many files
- You are migrating from one API to another (e.g., updating a deprecated method everywhere)
- The changes are so coupled that splitting them would leave the codebase in a broken intermediate state

For these, ask the AI to generate a summary:

```
"Summarize every change you made as a bullet list, grouped by file.
I need this for the PR description."
```

### The Verification Prompt

After any refactoring session, sanity-check the result:

```
"Compare the public API of src/services/billing.ts before and after these
changes. Are there any functions, types, or exports that were removed,
renamed, or had their signatures changed? List any breaking changes."
```

This catches accidental interface changes that tests might not cover.

## Real-World Example: Breaking Up a God File

A 500-line `utils.ts` that does everything. Here is the sequence:

```
Prompt 1: "List every export from src/utils.ts, grouped by category
          (string manipulation, date formatting, validation, etc.)"

Prompt 2: "Move all string manipulation functions into src/utils/strings.ts.
          Update src/utils.ts to re-export them for backward compatibility."

Prompt 3: "Move all date functions into src/utils/dates.ts. Same pattern --
          re-export from the barrel file."

Prompt 4: "Move validation functions into src/utils/validation.ts. Re-export."

Prompt 5: "Now update all files in the codebase that import from
          'src/utils' to import from the specific module instead.
          Then remove the re-exports from the barrel file."

Prompt 6: "Run tests and show me the results."
```

Five small, reviewable steps. The barrel file keeps everything working between steps so you can commit after each one.

## What Not to Refactor With AI

Some refactoring requires deep domain knowledge that the AI does not have:

- **Business logic restructuring** -- the AI does not know why the discount is applied before tax in some regions
- **Performance-critical paths** -- structural changes can introduce allocations or cache misses the AI won't anticipate
- **Concurrency code** -- lock ordering and synchronization are subtle; structural changes can introduce deadlocks

For these, use the AI to understand the code, but make the structural decisions yourself.

## Next Steps

- [Writing Code](writing-code.md) -- Generating new code with AI assistance
- [Code Review](code-review.md) -- Reviewing refactored code before shipping
- [Debugging](debugging.md) -- When refactoring introduces unexpected behavior
- [Testing Strategies](../04-architecture/testing.md) -- Tests that make refactoring safe
