# Writing Code

> The difference between "generate code" and "write the right code" is entirely in how you ask.

## From Prompt to Production

AI can write code fast. The hard part is getting code that fits -- fits your codebase, your patterns, your constraints, your team's expectations. The prompts that produce throwaway snippets look very different from the prompts that produce mergeable code.

The core principle: **the more context and constraints you provide, the less cleanup you do afterwards.**

## Good Prompts vs. Bad Prompts

### Bad: Vague and unconstrained

```
Write a user authentication system.
```

You'll get something that works in isolation but matches nothing in your project. Wrong framework, wrong patterns, wrong assumptions about your data layer.

### Better: Specific target, clear constraints

```
Add a login endpoint to src/api/routes/auth.ts that:
- Accepts POST with { email, password } body
- Validates input using our existing zod schemas in src/api/schemas/
- Calls the authenticate() function from src/services/auth.ts
- Returns a JWT using the same pattern as the /register endpoint
- Returns 401 with { error: "Invalid credentials" } on failure
```

### Best: Specific target with pattern reference

```
Add a login endpoint to src/api/routes/auth.ts following the same pattern
as the /register endpoint in that file. Use the same error handling,
validation approach, and response format.

It should accept POST { email, password }, call authenticate() from
src/services/auth.ts, and return a JWT on success.
```

The "following the same pattern as" instruction is one of the most powerful phrases you can use. It tells the AI to read existing code and match it, rather than inventing its own approach.

## The Pattern-Matching Approach

When your codebase has consistent patterns, leverage them explicitly:

```
Create a new service for managing invoices at src/services/invoice.ts.
Follow the exact same structure as src/services/order.ts -- same imports pattern,
same error handling, same way of interacting with the database layer.

The service should support:
- createInvoice(data: CreateInvoiceInput): Promise<Invoice>
- getInvoice(id: string): Promise<Invoice | null>
- listInvoices(filters: InvoiceFilters): Promise<PaginatedResult<Invoice>>
```

This approach is especially valuable for:
- New API endpoints that should match existing ones
- New database models following your ORM conventions
- New React components that should match your component library style
- New test files matching your testing patterns

## Implementing Interfaces

When the shape of the code is already defined -- by a TypeScript interface, a protocol, an API spec -- tell the AI:

```
Implement the PaymentProvider interface defined in src/types/payment.ts
for Stripe. Put it in src/providers/stripe.ts.

Use the same dependency injection pattern as the existing
src/providers/sendgrid.ts email provider.
```

```
Generate the implementation for the repository interface in
src/db/repositories/types.ts for the Invoice entity.
Use Prisma, matching the UserRepository in src/db/repositories/user.ts.
```

Interfaces and types are perfect AI constraints. They define the shape; the AI fills in the logic.

## Constraining the Output

Without constraints, AI tends to over-engineer. Be explicit about what you want and what you don't:

### Constrain dependencies

```
Implement email validation. Use a regex -- don't add a library for this.
```

```
Add CSV export. Use the 'csv-stringify' package we already have in
package.json -- don't install anything new.
```

### Constrain complexity

```
Write a simple caching wrapper around the getUser function.
Use a plain Map with a TTL. No LRU, no Redis, no cache invalidation strategy.
Just in-memory with expiry.
```

### Constrain scope

```
Add soft-delete to the User model. Only the model and repository layer.
Don't modify any API endpoints or services yet -- I'll do that separately.
```

### Constrain style

```
Write this in plain JavaScript -- no TypeScript, no JSDoc types.
Keep it under 50 lines. One function, no classes.
```

## Generating Boilerplate

This is where AI saves the most time with the least risk. Boilerplate is repetitive, well-defined, and low in business logic.

```
Generate a new Express router file at src/api/routes/invoices.ts with
CRUD endpoints for invoices. Include the standard middleware stack
(auth, validation, error handling) matching the pattern in
src/api/routes/orders.ts. Leave the handler bodies as TODO comments --
I'll implement the logic.
```

```
Create a new React component at src/components/InvoiceTable.tsx.
Use the same structure as src/components/OrderTable.tsx --
same props pattern, same hook usage, same styling approach.
Replace order-specific fields with invoice fields:
id, amount, status, dueDate, customerName.
```

The "leave bodies as TODOs" technique is useful when you want the structure but plan to write the logic yourself. You get the boilerplate without the risk of incorrect business logic.

## Iterative Refinement

Don't try to get perfect code in one shot. Build in layers:

```
Round 1: "Create the InvoiceService with createInvoice and getInvoice methods."
  -> Review, commit

Round 2: "Add listInvoices with pagination matching our standard pattern."
  -> Review, commit

Round 3: "Add filtering by status and date range to listInvoices."
  -> Review, commit

Round 4: "Add input validation using zod. Define schemas in src/api/schemas/invoice.ts."
  -> Review, commit
```

Each round builds on reviewed, working code. If round 3 goes wrong, you only lose round 3 -- not the whole feature.

### When refinement goes wrong

If you're on round 3 and the code is getting tangled:

```
Stop. Let's take a different approach. The current implementation of listInvoices
is getting complicated. Instead of adding filters to the existing query builder,
let's use the same Prisma where-clause pattern as listOrders in
src/services/order.ts. Start fresh on this method.
```

Explicitly saying "stop" and "start fresh on this method" prevents the AI from trying to patch code that needs rewriting.

## Writing Code That Fits

The biggest risk with AI-generated code isn't that it's wrong -- it's that it's *foreign*. It works, but it doesn't look like anything else in your codebase.

### Before generating, point to examples

```
Before writing anything, read these files to understand our patterns:
- src/services/order.ts (service layer pattern)
- src/api/routes/orders.ts (route handler pattern)
- src/db/repositories/order.ts (data access pattern)
- src/api/__tests__/orders.test.ts (test pattern)

Now create the equivalent files for an Invoice feature.
```

### After generating, check for consistency

```
Compare the code you just wrote with the existing order service.
Are there any inconsistencies in error handling, naming conventions,
or patterns? Fix them.
```

This review-and-fix prompt catches the subtle mismatches -- a different error class here, a slightly different naming convention there -- that make code feel inconsistent.

## Writing Tests Alongside Code

Don't write all the code first and then ask for tests. Write them together:

```
Add a calculateTotal function to src/services/pricing.ts that computes
the order total including tax and discounts.

Also write tests in src/services/__tests__/pricing.test.ts covering:
- Basic calculation with no discounts
- Percentage discount
- Fixed amount discount
- Tax calculation
- Zero-quantity edge case
```

Or test-first:

```
Write failing tests for a calculateTotal function that should:
- Sum line items (quantity * unitPrice)
- Apply a percentage discount to the subtotal
- Add tax (rate provided as parameter)
- Return { subtotal, discount, tax, total }

Put tests in src/services/__tests__/pricing.test.ts.
Don't write the implementation yet.
```

Then: "Now implement calculateTotal to make those tests pass."

## Common Pitfalls

**Accepting the first output without reading it.** AI code compiles and often passes tests, but may have subtle logic errors, security issues, or performance problems. Read the diff.

**Letting AI pick the architecture.** If you ask for "a notification system," you'll get whatever pattern the AI defaults to. Specify: "event-driven using our existing EventEmitter in src/lib/events.ts."

**Generating too much at once.** A prompt that produces 300 lines of code across 5 files is nearly impossible to review effectively. Keep each generation small enough that you can read every line.

**Not specifying error handling.** If you don't mention errors, AI might swallow them, throw generic exceptions, or return null. Be explicit: "Throw an InvoiceNotFoundError if the ID doesn't exist. Let validation errors bubble up."

## Next Steps

- [Reading Code](reading-code.md) -- Understand existing code before adding to it
- [Debugging](debugging.md) -- When the code you wrote doesn't work
- [Code Review](code-review.md) -- Review AI-generated code systematically
- [Refactoring](refactoring.md) -- Improve code structure without changing behavior
- [Over-Engineering Traps](../07-anti-patterns/over-engineering.md) -- When AI makes generated code too complex
- [Common Mistakes](../07-anti-patterns/common-mistakes.md) -- Pitfalls to watch for in AI-generated code
