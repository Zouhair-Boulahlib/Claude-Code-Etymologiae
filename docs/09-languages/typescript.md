# TypeScript Patterns for AI-Assisted Development

> TypeScript's type system is the single most effective constraint system for guiding AI-generated code toward correctness.

## Why TypeScript Is Ideal for AI Coding

When Claude Code generates JavaScript, it guesses at shapes. When it generates TypeScript, it **proves** shapes. The compiler becomes a second reviewer that catches mistakes before you even read the output.

An interface like `User { id: string; email: string; role: "admin" | "agent" }` tells the AI more than a paragraph of explanation -- it knows exactly what fields exist, what values are legal, and what operations make sense. The AI cannot invent fields, null handling is enforced, and union types make every case explicit.

## CLAUDE.md for TypeScript Projects

```markdown
## Project
E-commerce API. Express + TypeScript, strict mode. Drizzle ORM, Vitest.

## Commands
- `npm run dev` -- start dev server with tsx watch
- `npm run test` -- vitest run
- `npm run lint` -- eslint . --ext .ts
- `npm run typecheck` -- tsc --noEmit

## TypeScript Conventions
- strict mode is ON. Never use `any` -- use `unknown` and narrow.
- Named exports only. No default exports.
- Barrel files (index.ts) for public module APIs only.
- Prefer `interface` over `type` for object shapes.
- Prefer `satisfies` over `as` for type assertions.
- All function parameters and return types must be explicit.
- Branded types for IDs: `type UserId = string & { __brand: "UserId" }`
- Return Result<T, E> types in services, do not throw.
```

The key rules: no `any`, named exports, explicit return types. These three constraints alone prevent the majority of AI-generated TypeScript problems.

## Prompt Patterns That Work

### "Implement this interface"

The most reliable pattern. Define the contract, then ask for the implementation.

```
I have this interface:

interface OrderService {
  create(input: CreateOrderInput): Promise<Result<Order, OrderError>>;
  findById(id: OrderId): Promise<Order | null>;
  cancel(id: OrderId, reason: string): Promise<Result<void, OrderError>>;
}

Implement this as OrderServiceImpl using the Drizzle ORM from src/db/client.ts.
Follow the error handling pattern in src/services/customer.service.ts.
```

### "Add types to this JavaScript file"

```
Convert src/utils/csv-parser.js to TypeScript.
- No `any` types. Use generics where the input type varies.
- The parse function should be generic: parse<T>(input: string, schema: Schema<T>): T[]
- Handle null/undefined explicitly -- the JS version has hidden null bugs.
- Create a CsvParseError type for error cases instead of returning null.
```

## Zod Schema Generation

Zod gives you runtime validation and static types from a single source of truth. AI excels at generating Zod schemas from natural language descriptions.

```
Create a Zod schema for user registration:
- email: valid email, lowercase, trimmed
- password: min 8 chars, must contain uppercase, lowercase, and number
- name: 2-100 chars, trimmed
- age: optional, integer between 13 and 120
Export both the schema and the inferred type.
```

```typescript
import { z } from "zod";

export const userRegistrationSchema = z.object({
  email: z.string().email().toLowerCase().trim(),
  password: z
    .string()
    .min(8)
    .regex(/[A-Z]/, "Must contain uppercase")
    .regex(/[a-z]/, "Must contain lowercase")
    .regex(/[0-9]/, "Must contain number"),
  name: z.string().trim().min(2).max(100),
  age: z.number().int().min(13).max(120).optional(),
});

export type UserRegistration = z.infer<typeof userRegistrationSchema>;
```

## React Component Patterns

### Typed Props with Discriminated Unions

```typescript
interface ButtonBase {
  children: React.ReactNode;
  className?: string;
  disabled?: boolean;
}

interface PrimaryButton extends ButtonBase {
  variant: "primary";
  onClick: () => void;
  loading?: boolean;
}

interface LinkButton extends ButtonBase {
  variant: "link";
  href: string;
  external?: boolean;
}

type ButtonProps = PrimaryButton | LinkButton | { variant: "submit" } & ButtonBase;

export function Button(props: ButtonProps) {
  switch (props.variant) {
    case "primary":
      return (
        <button disabled={props.disabled || props.loading} onClick={props.onClick}>
          {props.loading ? <Spinner /> : props.children}
        </button>
      );
    case "link":
      return <a href={props.href} target={props.external ? "_blank" : undefined}>{props.children}</a>;
    case "submit":
      return <button type="submit" disabled={props.disabled}>{props.children}</button>;
  }
}
```

### Typed Context with Safe Hook

```typescript
const AuthContext = createContext<AuthContextValue | null>(null);

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (context === null) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
```

Never use `createContext({} as AuthContextValue)` -- the null-check pattern catches misuse at runtime.

## Node.js/Express Typed Middleware

Express types are notoriously loose. Tighten them.

```typescript
interface TypedRequest<TBody = unknown, TParams = unknown> extends Request {
  body: TBody;
  params: TParams;
}

interface AuthenticatedRequest extends Request {
  user: User;
  tenantId: string;
}

function requireAuth(req: Request, res: Response, next: NextFunction): void {
  const token = req.headers.authorization?.split(" ")[1];
  if (!token) { res.status(401).json({ error: "Missing token" }); return; }
  const payload = verifyToken(token);
  if (!payload) { res.status(401).json({ error: "Invalid token" }); return; }
  (req as AuthenticatedRequest).user = payload.user;
  (req as AuthenticatedRequest).tenantId = payload.tenantId;
  next();
}

router.post("/orders", requireAuth, validateBody(createOrderSchema),
  async (req: TypedRequest<CreateOrderInput>, res: Response) => {
    const result = await orderService.create((req as unknown as AuthenticatedRequest).user.id, req.body);
    result.ok ? res.status(201).json(result.value) : res.status(400).json({ error: result.error.message });
  }
);
```

## Testing: Typed Mocks with Vitest

AI-generated mocks often lose type safety. Enforce it by banning `as any` in your CLAUDE.md.

```typescript
import { describe, it, expect, vi, beforeEach } from "vitest";

function createMockDb(): Pick<Database, "orders" | "products"> {
  return {
    orders: {
      insert: vi.fn<[NewOrder], Promise<Order>>(),
      findById: vi.fn<[string], Promise<Order | null>>(),
    },
    products: {
      findByIds: vi.fn<[string[]], Promise<Product[]>>(),
    },
  } satisfies Pick<Database, "orders" | "products">;
}

describe("OrderService.create", () => {
  let mockDb: ReturnType<typeof createMockDb>;
  let service: OrderServiceImpl;

  beforeEach(() => {
    mockDb = createMockDb();
    service = new OrderServiceImpl(mockDb as Database);
  });

  it("creates order with correct total", async () => {
    mockDb.products.findByIds.mockResolvedValue([
      { id: "p1", name: "Widget", price: 1099 },
    ]);
    mockDb.orders.insert.mockResolvedValue({
      id: "order-1", items: [{ productId: "p1", quantity: 2 }], total: 2198, status: "pending",
    });
    const result = await service.create({ customerId: "c1", items: [{ productId: "p1", quantity: 2 }] });
    expect(result.ok).toBe(true);
  });
});
```

## Common AI Mistakes in TypeScript

### 1. Overusing `any`

```typescript
// AI-generated -- takes the easy way out
function processData(data: any): any {
  return data.items.map((item: any) => item.value);
}

// What you want
function processData<T extends { items: ReadonlyArray<{ value: number }> }>(data: T): number[] {
  return data.items.map((item) => item.value);
}
```

### 2. Wrong Generic Constraints

```typescript
// Too loose -- T could be anything
function getName<T>(obj: T): string { return (obj as { name: string }).name; }

// Correct -- constraint ensures .name exists
function getName<T extends { name: string }>(obj: T): string { return obj.name; }
```

### 3. Missing Null Checks

```typescript
const user = users.find((u) => u.id === targetId);
console.log(user.name); // TypeError if undefined

// Correct
const user = users.find((u) => u.id === targetId);
if (!user) throw new NotFoundError(`User ${targetId} not found`);
console.log(user.name); // TypeScript narrows the type
```

### 4. Incorrect Type Narrowing

```typescript
// Does not actually narrow -- null and arrays are also "object"
if (typeof response === "object") { response.data; }

// Correct -- use a type guard
function isApiResponse(value: unknown): value is ApiResponse {
  return typeof value === "object" && value !== null && "data" in value && "status" in value;
}
```

## tsconfig.json for Catching AI Errors

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    "exactOptionalPropertyTypes": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true
  }
}
```

Key flags and what they catch:

- **`strict`** -- enables `strictNullChecks`, `noImplicitAny`, and others. Non-negotiable.
- **`noUncheckedIndexedAccess`** -- `array[0]` returns `T | undefined`. Catches AI's assumption that array access always succeeds.
- **`exactOptionalPropertyTypes`** -- distinguishes `undefined` from "missing". Catches AI code that sets optional fields to `undefined` when it should omit them.

Run `tsc --noEmit` after every AI-generated change. Fix errors before asking for more code.

## Real Example: Converting JS to TypeScript

Start with a JavaScript file:

```javascript
export function calculatePrice(items, discount, taxRate) {
  let subtotal = 0;
  for (const item of items) { subtotal += item.price * item.quantity; }
  let discountAmount = 0;
  if (discount) {
    discountAmount = discount.type === "percent"
      ? subtotal * (discount.value / 100) : discount.value;
  }
  const afterDiscount = Math.max(0, subtotal - discountAmount);
  const tax = afterDiscount * taxRate;
  return { subtotal, discount: discountAmount, tax, total: afterDiscount + tax };
}
```

Prompt:

```
Convert to TypeScript. Define types for all params and return value.
discount is optional, discount.type is "percent" | "fixed".
Return type should be a named interface PriceBreakdown.
Add a Zod schema for input validation.
```

The AI produces properly typed output with `ReadonlyArray<LineItem>`, optional `Discount | undefined`, named `PriceBreakdown` return type, and a matching Zod schema. The type constraints prevented the usual shortcuts.

## Workflow Summary

1. **Set up tsconfig.json** with maximum strictness before involving the AI.
2. **Write your CLAUDE.md** with TypeScript-specific rules -- especially the `any` ban.
3. **Define interfaces first**, then ask the AI to implement them.
4. **Use Zod schemas** as the single source of truth for validation and types.
5. **Run `tsc --noEmit`** after every AI-generated change.
6. **Review generics carefully** -- this is where AI makes the subtlest mistakes.

The stricter your configuration, the more the compiler does the reviewing for you.
