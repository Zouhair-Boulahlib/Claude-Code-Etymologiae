# Common Mistakes

> Patterns that feel productive but lead to problems. Learn from others' pain.

## 1. The Blind Accept

Approving every diff without reading it. The code compiles, tests pass, so you ship it.

**Real Scenario:**

You ask AI to add a 20% discount for orders over $100. It generates `src/services/pricing.ts`:

```ts
export function applyDiscount(order: Order): number {
  const subtotal = order.items.reduce((sum, item) => sum + item.price, 0);
  if (subtotal > 100) {
    return subtotal - subtotal * 0.2;
  }
  return subtotal;
}
```

Compiles fine. Tests pass because test fixtures all use `quantity: 1`. But `item.price` is the unit price -- the reduce never multiplies by `item.quantity`. An order of 3 items at $40 each calculates as $40, not $120. No discount applied. Customer support tickets roll in three days later.

**The fix:** The line should be `sum + item.price * item.quantity`. Read every diff against the requirements, not just whether it compiles. If a diff is too large to review carefully, the task was too large.

---

## 2. The Context Dump

Pasting 200 lines of stack trace and saying "fix this."

**Real Scenario:**

Your app crashes. You paste the full terminal output -- 47 lines of nested stack trace, webpack noise, source maps, Node internals. AI wastes tokens parsing irrelevant webpack paths and gives a generic null-check answer. What you should send:

```
UserList.tsx line 18 throws "Cannot read properties of undefined (reading 'map')".
The component calls `props.users.map(...)` but `users` comes from a React Query
hook that returns `undefined` before the fetch resolves. The API endpoint is
GET /api/users. How should I handle the loading state?
```

**The fix:** Extract the root cause line. State what you already know. Five focused lines beat 200 lines of noise.

---

## 3. The Infinite Loop

Five rounds of fixes where each one breaks something new because nobody found the actual cause.

**Real Scenario:**

Round 1 -- `POST /api/orders` returns 500. AI adds try/catch in `src/routes/orders.ts`. Now returns 200 but the order is never saved.

Round 2 -- AI adds `await db.save(order)` in `src/services/orderService.ts`. Now "connection refused."

Round 3 -- AI changes port from 5432 to 5433 in `src/config/database.ts`. Migrations fail.

Round 4 -- AI updates `knexfile.js` to port 5433. Seed data breaks.

Round 5 -- AI rewrites `seeds/001_orders.js` entirely.

The actual root cause: someone changed `DATABASE_URL` in `.env.production` during a deploy. Staging was pointing at the old host. None of the code changes were necessary. Every round made things worse.

**The fix:** If round 3 hasn't solved it, stop. Read the error yourself. Run `env | grep DATABASE`. Then give a specific prompt: "The DATABASE_URL in .env.production points at the old host. Update it and revert the changes to database.ts and knexfile.js."

---

## 4. The Yak Shave

AI installs two npm packages and creates three files for something you could write in one line.

**Real Scenario:**

You ask: "Add email validation to the signup form." AI runs `npm install zod email-validator` then creates `src/schemas/userSchema.ts`:

```ts
import { z } from 'zod';
import * as EmailValidator from 'email-validator';

export const signupSchema = z.object({
  email: z.string().refine((val) => EmailValidator.validate(val), {
    message: 'Invalid email address',
  }),
  password: z.string().min(8),
});
```

Then creates middleware, updates routes. Your project had no Zod before. Two new deps to audit. What you needed in `src/routes/auth.ts`:

```ts
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
if (!EMAIL_RE.test(req.body.email)) {
  return res.status(400).json({ error: 'Invalid email address' });
}
```

**The fix:** "Validate email with a regex inline. Do not add dependencies." Always specify whether new packages are acceptable.

---

## 5. The God Prompt

One prompt tries to build an entire feature. AI generates 15 files using libraries you didn't ask for.

**Real Scenario:**

You prompt: "Build a complete notification system with in-app notifications, email digests, push notifications, preferences, read/unread tracking, and a notification center UI."

AI generates 15 files in one shot:

```
src/models/Notification.ts          -- uses TypeORM (your project uses Prisma)
src/services/NotificationService.ts -- 280 lines, imports nodemailer and web-push
src/workers/digestWorker.ts         -- uses Bull queue (not installed)
src/components/NotificationCenter.tsx
src/components/NotificationBell.tsx
src/hooks/useNotifications.ts
src/context/NotificationContext.tsx
prisma/migrations/add_notifications.sql -- raw SQL instead of Prisma migrate
tests/notifications.test.ts            -- imports from wrong paths
... 6 more files
```

Half import libraries your project doesn't use. The test file references paths that don't exist. Reviewing 15 files at once is impossible.

**The fix:** One piece at a time. "Create the Prisma schema for notifications." Review, commit. "Create a NotificationService using the existing Prisma client from src/lib/prisma.ts." Review, commit. Each step validated before the next starts.

---

## 6. The Test Afterthought

You build the feature first, then ask AI to "add tests." The tests mirror the implementation instead of verifying behavior.

**Real Scenario:**

You built `src/services/shippingCalculator.ts`:

```ts
export function calculateShipping(weightKg: number, zone: string): number {
  const baseRate = zone === 'domestic' ? 5.0 : 15.0;
  const perKgRate = zone === 'domestic' ? 0.5 : 2.0;
  return baseRate + weightKg * perKgRate;
}
```

AI writes tests that duplicate the formula:

```ts
it('calculates domestic', () => {
  expect(calculateShipping(10, 'domestic')).toBe(5.0 + 10 * 0.5); // formula, not value
});
```

If someone changes rates, these tests break even if behavior is correct. No edge cases tested.

**The fix:** Behavior-driven tests with hardcoded expected values:

```ts
it('charges $10 to ship 10kg domestically', () => {
  expect(calculateShipping(10, 'domestic')).toBe(10.0);
});
it('charges only base rate for zero weight', () => {
  expect(calculateShipping(0, 'domestic')).toBe(5.0);
});
it('throws on negative weight', () => {
  expect(() => calculateShipping(-1, 'domestic')).toThrow();
});
it('throws on unknown zone', () => {
  expect(() => calculateShipping(5, 'mars')).toThrow();
});
```

Expected values are business expectations, not copied formulas. Edge cases force the implementation to handle bad input.

---

## 7. The Security Bypass

CORS blocks your request during development. You ask AI to "fix CORS." It disables CORS entirely.

**Real Scenario -- Express:**

AI generates in `src/app.ts`:

```ts
app.use(cors({ origin: '*', credentials: true }));
```

Any website can now make authenticated requests to your API. An attacker on `evil-site.com` can call `/api/user/profile` with the victim's cookies.

**Real Scenario -- Spring Boot:**

AI adds to `src/main/java/com/app/config/WebConfig.java`:

```java
registry.addMapping("/**")
        .allowedOrigins("*")
        .allowedMethods("*")
        .allowCredentials(true);
```

Same vulnerability, different framework. Both pass manual testing because your browser is making the requests.

**The fix -- Express:**

```ts
const ALLOWED_ORIGINS = [
  'https://app.yourcompany.com',
  process.env.NODE_ENV === 'development' && 'http://localhost:3000',
].filter(Boolean) as string[];
app.use(cors({ origin: ALLOWED_ORIGINS, credentials: true }));
```

**The fix -- Spring Boot:**

```java
registry.addMapping("/api/**")
        .allowedOrigins("https://app.yourcompany.com")
        .allowedMethods("GET", "POST", "PUT", "DELETE")
        .allowCredentials(true);
```

Whitelist specific origins. Whitelist specific methods. Never combine `*` with `credentials: true`.

---

## 8. The Over-Engineered Solution

You ask for a config loader and get a 10-file abstraction layer.

**Real Scenario:**

You prompt: "Create a configuration system for the app." AI generates:

```
src/config/ConfigProvider.ts        -- abstract base class
src/config/EnvConfigProvider.ts     -- reads from process.env
src/config/FileConfigProvider.ts    -- reads from JSON files
src/config/ConfigRegistry.ts        -- registers providers by priority
src/config/ConfigValidator.ts       -- validates against a schema
src/config/types.ts                 -- 40 lines of interfaces
src/config/index.ts                 -- barrel export
... plus errors.ts, cache, and 120 lines of tests
```

Your app has 6 config values. What you actually need -- `src/config.ts`:

```ts
export const config = {
  databaseUrl: required('DATABASE_URL'),
  port: Number(process.env.PORT) || 3000,
  jwtSecret: required('JWT_SECRET'),
  logLevel: process.env.LOG_LEVEL || 'info',
  apiKey: required('STRIPE_API_KEY'),
  enableBeta: process.env.ENABLE_BETA === 'true',
};

function required(key: string): string {
  const value = process.env[key];
  if (!value) throw new Error(`Missing required env var: ${key}`);
  return value;
}
```

One file. Zero abstractions. Need a seventh value? Add one line.

**The fix:** "Simple config object from env vars. One file. No classes, no factories, no registries."

---

## 9. The Stale Context Trap

You refactored midway through a conversation. AI still references old file paths and method names.

**Real Scenario:**

Early in the conversation, auth code was in `src/utils/auth.ts` with `validateToken`. Twenty messages later, you refactored to `src/services/auth/tokenService.ts` with `verifyAccessToken`.

You ask: "Add rate limiting to the token validation endpoint." AI generates:

```ts
// src/middleware/rateLimit.ts
import { validateToken } from '../../utils/auth';

export function rateLimitedValidation(req, res, next) {
  const result = validateToken(req.headers.authorization);
  // ...
}
```

Imports a path that no longer exists. Calls a function that was renamed. After three rounds of corrections, AI updates the import path but still calls `validateToken` because that name is burned into the context from 20 messages ago.

**The fix:** Start new conversations at natural breakpoints -- after a refactor, after merging, after restructuring. Restate the current state: "Auth service is in src/services/auth/tokenService.ts. Main function is verifyAccessToken. Add rate limiting to /api/auth/verify."

---

## 10. The Undocumented Magic

AI generates working code using framework features nobody on the team understands. Six months later it's untouchable.

**Real Scenario:**

You ask AI to build a modal openable from a parent. It generates `src/components/ConfirmDialog.tsx`:

```tsx
const ConfirmDialog = forwardRef<ConfirmDialogHandle>((_, ref) => {
  const [visible, setVisible] = useState(false);
  const resolveRef = useRef<(value: boolean) => void>();

  useImperativeHandle(ref, () => ({
    open: (msg) => new Promise<boolean>((resolve) => {
      setVisible(true);
      resolveRef.current = resolve;
    }),
  }));

  // handleConfirm/handleCancel resolve the stored Promise, then hide
  // ...
});
```

Parent calls `dialogRef.current.open("Delete this?")` and gets a Promise back. It uses `forwardRef`, `useImperativeHandle`, and stores a Promise resolver in a ref -- three patterns most React devs rarely combine.

Six months later, a junior dev needs to add a "Don't ask again" checkbox. They don't understand why the component stores a resolve function in a ref. They're afraid to touch it. They build a duplicate modal instead.

**The fix:** When AI uses patterns you don't understand, ask: "Is there a simpler approach using state and an onConfirm callback?" Often there is. If the advanced pattern is right, add a comment:

```tsx
/**
 * Uses useImperativeHandle to expose an imperative open() API so the parent
 * can call dialogRef.current.open(msg) and await the result as a Promise.
 * See: https://react.dev/reference/react/useImperativeHandle
 */
```

---

## The Meta-Lesson

Every anti-pattern above comes from the same root cause: **treating AI as a black box that produces code, instead of a collaborator that produces suggestions.**

You are the engineer. You own the code, the architecture, and the production incidents. A powerful tool used carelessly does more damage than a simple tool used well.

## Next Steps

- [Over-Engineering Traps](over-engineering.md) -- When AI makes simple things complex
- [Debugging AI Output](debugging-ai.md) -- When the suggestions are wrong
