# Documentation

> Use AI to write docs that stay current, not docs that rot the moment they're committed.

## The Core Problem

Documentation decays. Code changes, docs don't. Three months later, the README describes an architecture that no longer exists.

AI solves this by making documentation cheap enough to regenerate. The cost drops from "annoying chore nobody does" to "one prompt after each significant change."

## Inline vs. External Docs

**Inline** (JSDoc, docstrings, comments) stays current because it's visible during code changes:

```
Add JSDoc to all exported functions in src/features/billing/billing.service.ts.
Include parameter descriptions, return types, @throws annotations.
Skip private/internal functions.
```

Result:

```typescript
/**
 * Calculates invoice total including taxes and discounts.
 *
 * @param lineItems - Invoice line items with price and quantity
 * @param taxRate - Tax rate as decimal (e.g., 0.08 for 8%)
 * @param discountCode - Optional discount code to apply
 * @returns Total in cents, never less than 0
 * @throws {DiscountError} If discount code is expired or invalid
 */
export function calculateInvoiceTotal(
  lineItems: LineItem[],
  taxRate: number,
  discountCode?: string
): number {
```

**External** docs (architecture guides, API references, tutorials) serve audiences who don't read source code. Rule: inline docs describe **what** and **how**. External docs describe **why** and **how to use**.

## Generating API Docs from Code

```
Generate API documentation for all routes in src/api/routes/.
For each endpoint: method, path, parameters, request/response schemas
with examples, error cases, required headers.
Format as Markdown. Group by resource.
Use actual validation schemas in src/api/schemas/ for accuracy.
```

This produces docs grounded in real code. When the API changes, run the same prompt again. For libraries:

```
Generate API reference for public exports of src/shared/utils/.
For each function: signature, description, usage example, gotchas.
Skip unexported functions.
```

## Writing READMEs

```
Write a README.md based on the codebase. Include:
- One-paragraph description
- Prerequisites and setup instructions
- How to run tests
- Project structure (top-level directories)
- Contributing guidelines

Keep it under 150 lines. Be specific -- use actual commands from package.json,
actual directory names. No badges or shields.
```

"Be specific" is the key instruction. Without it, you get generic boilerplate. With it, the AI reads your actual project and produces a README that matches reality.

## Changelog Generation

```
Generate a changelog for changes between v2.3.0 and v2.4.0.
Group by: Features, Bug Fixes, Breaking Changes.
Past tense. One line per user-facing change. Skip internals.
Reference PR numbers where available.
```

The output groups changes by type with PR references -- readable, useful, grounded in actual commits. Keep it growing incrementally after each merge: "Merged PR #325: webhook retry with exponential backoff. Add entry to CHANGELOG.md under Unreleased."

## Architecture Decision Records

ADRs capture **why** decisions were made:

```
Write an ADR for switching from REST to GraphQL for the mobile API.
Context: 6-8 REST calls per screen, cellular latency unacceptable.
Decision: GraphQL for mobile, keep REST for server-to-server.
Constraints: no team GraphQL experience, must maintain REST for
existing integrations, no significant backend complexity increase.
Standard ADR format: Title, Status, Context, Decision, Consequences.
```

Six months later, when someone asks "why GraphQL?", the answer exists.

## Documentation-as-Code

### Tests as Documentation

Prompt for specification-style test names:

```
Write tests for the discount engine that read like a specification.
Use names a product manager could understand.
```

```typescript
describe('Discount Engine', () => {
  it('applies percentage to cart subtotal', () => { ... });
  it('caps discount at maximum amount when specified', () => { ... });
  it('does not allow two percentage codes on same cart', () => { ... });
  it('allows one percentage and one fixed-amount code', () => { ... });
});
```

These names are a specification. They stay current because CI fails when they don't.

### Types as Documentation

```
Add JSDoc descriptions to fields in src/api/types/ where
the name alone is ambiguous.
```

```typescript
interface Order {
  id: string;
  /** ISO 8601 timestamp when the order was placed */
  createdAt: string;
  /** Transitions: pending -> processing -> shipped -> delivered */
  status: 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled';
  /** Total in cents (USD). Includes tax, shipping, after discounts. */
  totalCents: number;
  /** Null until a shipping label is generated */
  trackingNumber: string | null;
}
```

## Updating Docs When Code Changes

Make it a prompting habit. After changing code:

```
Refactored auth middleware to JWT instead of session cookies.
Files changed: src/api/middleware/auth-guard.ts, src/api/routes/auth.routes.ts.
Update docs referencing session-based auth: docs/api/authentication.md,
CLAUDE.md auth section, inline comments in changed files.
Show me the diff.
```

When reviewing a PR:

```
This PR changes the users table schema. Check if any docs reference
the old schema. Look in docs/, README.md, CLAUDE.md, inline comments.
```

Catches stale docs the moment they become stale, not three months later.

## Quick Reference

| Doc Type | Prompt Pattern |
|----------|---------------|
| API reference | "Docs from routes in [path]. Schemas, examples, errors." |
| README | "README from codebase. Real commands, real paths." |
| ADR | "ADR for [decision]. Context: [why]. Constraints: [list]." |
| Changelog | "Changelog [ref1] to [ref2]. Group by type. Skip internals." |
| Inline docs | "JSDoc on exports in [path]. Params, returns, throws." |
| Tutorial | "Step-by-step [task]. Use actual project code." |
| Onboarding | "New-dev guide: setup, architecture, key files, tasks." |

## The Maintenance Loop

1. **Create** -- Generate initial docs from code
2. **Verify** -- Fix inaccuracies. AI gets ~90% right; you add domain knowledge.
3. **Evolve** -- When code changes, prompt AI to update affected docs
4. **Audit** -- Compare docs against code, flag inconsistencies

```
Compare docs/api/orders.md against src/api/routes/orders.routes.ts.
List discrepancies: missing endpoints, changed params, wrong schemas.
```

Not zero-effort, but an order of magnitude less than maintaining docs manually.

## Next Steps

- [Project Setup](project-setup.md) -- Structure projects for AI-friendly development
- [Testing Strategies](testing.md) -- Write and maintain tests with AI assistance
- [The CLAUDE.md File](../01-foundations/claude-md.md) -- The most important doc in your project
