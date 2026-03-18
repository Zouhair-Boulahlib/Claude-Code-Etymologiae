# Testing Strategies

> Use AI to write more tests, better tests, and tests you wouldn't have thought of -- without creating a brittle mess.

## The Fundamental Rule

AI-generated tests must test **behavior**, not **implementation**. This is the single most common mistake.

```typescript
// Bad -- tests implementation details
test('calls processOrder with correct args', () => {
  const spy = jest.spyOn(service, 'processOrder');
  checkout(cart);
  expect(spy).toHaveBeenCalledWith(cart.items, cart.userId, expect.any(Date));
});

// Good -- tests behavior
test('checkout creates an order with the correct total', () => {
  const cart = { items: [{ price: 10, qty: 2 }, { price: 5, qty: 1 }], userId: 'u1' };
  const order = checkout(cart);
  expect(order.total).toBe(25);
  expect(order.status).toBe('pending');
});
```

When prompting for tests, state this preference explicitly. The AI defaults to whatever pattern dominates your codebase.

## Test-First with AI

The most powerful workflow -- describe behavior, then implement:

```
Write tests for a function `applyDiscount(cart, code)` that:
- Returns the cart with a `discount` field when the code is valid
- Throws DiscountError("expired") for expired codes
- Throws DiscountError("invalid") for unknown codes
- Caps percentage discounts at $50
- Never lets the total go below $0

Write the tests first. Do NOT implement the function yet.
```

The tests become your acceptance criteria. Then:

```
Now implement `applyDiscount` to make all those tests pass.
Follow the patterns in src/features/billing/billing.service.ts.
```

The AI has tests as a target and a pattern to follow. Implementation is almost always correct on the first try.

## Generating Edge Case Tests

AI excels at finding edge cases you'd miss:

```
Look at `parseCSVRow` in src/utils/csv-parser.ts.
Write tests for edge cases including:
- Empty input, quoted fields containing delimiters
- Escaped quotes, rows with wrong field count
- Unicode characters, very long fields (>10,000 chars)
Use the testing style from existing tests in src/utils/__tests__/.
```

The word "including" signals your list is a starting point. The AI will add more. Go broader with: "Review `src/api/routes/users.routes.ts` and write tests for every failure mode: invalid input, missing auth, race conditions, db failures."

## Writing Tests Alongside Features

Include testing in the same prompt as implementation:

```
Add a PATCH /users/:id endpoint to src/api/routes/users.routes.ts that:
- Updates only the fields provided (name, email)
- Returns 404/400/409 for missing user, bad email, duplicate email
- Requires auth (use authGuard middleware)

Include tests in src/api/routes/__tests__/users.routes.test.ts.
```

When tests are part of the same prompt, the AI writes them against behavior, not implementation, and catches its own bugs before presenting the result.

## Test Organization

**Co-located** -- next to source for easy discovery:

```
src/features/auth/
  auth.service.ts
  auth.service.test.ts
```

**Parallel directory** -- for cross-feature tests:

```
tests/
  integration/
    auth-billing.test.ts
    user-lifecycle.test.ts
  e2e/
    checkout.spec.ts
  fixtures/
    users.json
  helpers/
    db.ts
```

Reference helpers in CLAUDE.md so AI reuses them:

```markdown
## Testing
- Helpers: tests/helpers/ -- use them, don't create new ones
- Unit: `npm test` | Integration: `npm run test:integration` | E2E: `npm run test:e2e`
```

## Testing Patterns by Type

**Unit** -- point to function, describe what to test:

```
Write unit tests for `calculateShipping` in src/features/shipping/shipping.service.ts.
Test weight brackets, international vs domestic, free shipping threshold.
Mock the rate lookup -- don't call the real API.
```

Watch for over-mocking. If the test mocks everything, it tests nothing.

**Integration** -- provide explicit setup context:

```
Write an integration test for order creation:
1. Create user (factory in tests/helpers/factories.ts)
2. Add items via POST /cart/items, apply discount, check out
3. Verify order appears in GET /orders
Use test db setup from tests/helpers/db.ts. Clean up after.
```

**E2e** -- provide framework and page structure:

```
Write a Playwright e2e test for login. Navigate to /login, enter credentials,
verify redirect to /dashboard. Also test invalid password and empty form.
Follow page object pattern in tests/e2e/pages/.
```

## Avoiding Brittle Tests

**Snapshot overuse.** Easy to generate, break on cosmetic changes, uninformative failures. Say: "Do not use snapshot tests. Test specific rendered output."

**Overly specific assertions:**

```typescript
// Brittle
expect(error.message).toBe('Invalid email: the domain "test" is not a valid TLD');
// Resilient
expect(error).toBeInstanceOf(ValidationError);
expect(error.field).toBe('email');
```

**Test order dependencies.** Each test must create its own data. If it depends on a previous test, it fails in isolation. Use factory functions like `createTestUser()`.

**Framework internals.** "calls authGuard middleware" tests Express, not your code. Test what happens when auth fails instead.

## Maintaining Test Quality

Periodically audit:

```
Review tests in src/features/auth/__tests__/. Identify tests that check
implementation details, use weak assertions, miss edge cases, or would pass
even if the code was wrong. Fix them.
```

Find coverage gaps:

```
Compare src/features/billing/billing.service.ts with billing.service.test.ts.
What behaviors are untested? Write tests for the gaps.
```

## Quick Reference

| Goal | Prompt Pattern |
|------|---------------|
| Unit tests | "Write tests for `fn` in `path`. Test [behaviors]." |
| Edge cases | "Edge case tests for `path` including [list]. Add others." |
| Integration | "Integration test for [flow]. Use [helpers]. Clean up." |
| Coverage gaps | "Compare `source` with `test`. What's untested?" |
| Test-first | "Tests for a function that [spec]. Do NOT implement." |
| Fix brittle | "Refactor tests in `path`: behavior, not implementation." |

## Next Steps

- [Documentation](documentation.md) -- Keep docs current with AI assistance
- [Project Setup](project-setup.md) -- Structure projects for AI-friendly development
- [Effective Prompting](../03-prompts/effective-prompting.md) -- General prompting strategies
