# Over-Engineering Traps

> When AI makes simple things complex -- and how to stop it.

## Why AI Over-Engineers

AI models are trained on vast amounts of public code. A disproportionate share of that code comes from:

- **Enterprise Java/C# codebases** -- AbstractFactoryProviderStrategyResolverImpl
- **Framework source code** -- heavily abstracted by necessity
- **Tutorial code** -- designed to demonstrate patterns, not solve problems simply
- **Open source libraries** -- generalized for every use case, not yours

The result: when you ask for a solution, the AI defaults to the most "complete" version it has seen. That version almost always has more abstraction, more indirection, and more flexibility than you need.

This is not a bug in the AI. It is a bias in the training data. Your job is to counteract it.

## Recognizing Over-Engineering

### Too Many Abstractions

You asked for a function that sends emails. You got:

- `EmailProvider` interface
- `SmtpEmailProvider` class implementing `EmailProvider`
- `EmailProviderFactory` to create providers
- `EmailTemplateEngine` with a plugin system
- `EmailQueue` with retry logic and dead letter handling
- `EmailConfig` loaded from 3 possible sources with fallback chain

You needed: a function that calls the SendGrid API.

### Unnecessary Design Patterns

The AI suggests the Strategy pattern for two if-branches. It suggests the Observer pattern for one event. It suggests Dependency Injection for a script that runs once and exits.

Design patterns solve real problems -- at sufficient scale. At insufficient scale, they are just indirection that makes code harder to read.

### Premature Optimization

You asked for a config loader. The AI adds caching, lazy loading, file watchers for hot reloading, and schema validation with custom error formatting. Your config is read once at startup from three environment variables.

### The "Factory Factory" Problem

This is the canonical case. You want to create an object. The AI gives you a factory that creates factories:

```typescript
// What the AI generates
class NotificationServiceFactory {
  static createFactory(config: FactoryConfig): NotificationFactory {
    return new NotificationFactory(
      new ChannelResolverStrategy(config),
      new TemplateProviderRegistry(config.templates),
      new DeliveryPipelineBuilder(config.pipeline)
    );
  }
}

// What you needed
function sendNotification(userId: string, message: string) {
  return fetch('/api/notifications', {
    method: 'POST',
    body: JSON.stringify({ userId, message })
  });
}
```

## How to Constrain Complexity

### Be Explicit About Simplicity

The single most effective technique: tell the AI what you do not want.

```
"Write a function that loads config from environment variables.
No classes. No factories. No abstraction layers. Just a plain
object with the values, and throw if any are missing."
```

This produces:

```typescript
function loadConfig() {
  const required = (key: string): string => {
    const val = process.env[key];
    if (!val) throw new Error(`Missing env var: ${key}`);
    return val;
  };

  return {
    dbUrl: required('DATABASE_URL'),
    port: parseInt(required('PORT'), 10),
    jwtSecret: required('JWT_SECRET'),
    nodeEnv: process.env.NODE_ENV || 'development',
  };
}
```

Fourteen lines. No classes. Does the job.

### Specify Complexity Level

```
"Implement this as a simple utility function. This is a small
internal tool, not a library. Optimize for readability over extensibility."
```

Or put it in your CLAUDE.md:

```markdown
## Code Style
- Prefer functions over classes unless state management requires it
- No design patterns unless the problem clearly demands one
- Flat is better than nested. Simple is better than clever.
- If a module has more than 2 levels of indirection, it's too abstract
```

### Set Line Count Expectations

```
"This should be about 20-30 lines. If your solution is longer,
you're over-thinking it."
```

This forces the AI to self-constrain. It will not generate a 200-line class hierarchy when you have told it the solution should fit in 30 lines.

## Before/After: Over-Engineered vs. Right-Sized

### Example 1: HTTP Client Wrapper

**Over-engineered (what AI might generate unprompted):**

```typescript
interface HttpClient {
  get<T>(url: string, config?: RequestConfig): Promise<Response<T>>;
  post<T>(url: string, data: unknown, config?: RequestConfig): Promise<Response<T>>;
}

interface RequestConfig {
  headers?: Record<string, string>;
  timeout?: number;
  retries?: number;
  retryDelay?: number;
  interceptors?: RequestInterceptor[];
}

interface RequestInterceptor {
  onRequest?: (config: RequestConfig) => RequestConfig;
  onResponse?: <T>(response: Response<T>) => Response<T>;
  onError?: (error: HttpError) => void;
}

class AxiosHttpClient implements HttpClient {
  private interceptorChain: InterceptorChain;
  private retryHandler: RetryHandler;

  constructor(private config: ClientConfig) {
    this.interceptorChain = new InterceptorChain(config.interceptors);
    this.retryHandler = new RetryHandler(config.retryPolicy);
  }
  // ... 80 more lines
}
```

**Right-sized (what you actually need):**

```typescript
const api = {
  async get(path: string) {
    const res = await fetch(`${process.env.API_URL}${path}`, {
      headers: { Authorization: `Bearer ${getToken()}` },
    });
    if (!res.ok) throw new Error(`GET ${path}: ${res.status}`);
    return res.json();
  },

  async post(path: string, data: unknown) {
    const res = await fetch(`${process.env.API_URL}${path}`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${getToken()}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    });
    if (!res.ok) throw new Error(`POST ${path}: ${res.status}`);
    return res.json();
  },
};
```

When you actually need retries, interceptors, and configurable timeouts -- add them. Not before.

### Example 2: Logger

**Over-engineered:**

```typescript
class Logger {
  private static instance: Logger;
  private transports: LogTransport[] = [];
  private formatters: LogFormatter[] = [];
  private filters: LogFilter[] = [];
  private level: LogLevel;

  private constructor(config: LoggerConfig) {
    this.level = config.level;
    this.transports = config.transports.map(TransportFactory.create);
    this.formatters = config.formatters || [new DefaultFormatter()];
    this.filters = config.filters || [];
  }

  static getInstance(config?: LoggerConfig): Logger {
    if (!Logger.instance) {
      Logger.instance = new Logger(config || DefaultLoggerConfig);
    }
    return Logger.instance;
  }

  log(level: LogLevel, message: string, meta?: Record<string, unknown>) {
    if (level < this.level) return;
    const entry = this.formatters.reduce(
      (e, f) => f.format(e),
      new LogEntry(level, message, meta)
    );
    if (this.filters.some(f => f.shouldFilter(entry))) return;
    this.transports.forEach(t => t.write(entry));
  }
  // ... info(), warn(), error(), debug() wrappers
}
```

**Right-sized:**

```typescript
const LOG_LEVELS = { debug: 0, info: 1, warn: 2, error: 3 } as const;
type LogLevel = keyof typeof LOG_LEVELS;

const currentLevel: LogLevel = (process.env.LOG_LEVEL as LogLevel) || 'info';

function log(level: LogLevel, message: string, data?: Record<string, unknown>) {
  if (LOG_LEVELS[level] < LOG_LEVELS[currentLevel]) return;
  const entry = { timestamp: new Date().toISOString(), level, message, ...data };
  console.log(JSON.stringify(entry));
}

export const logger = {
  debug: (msg: string, data?: Record<string, unknown>) => log('debug', msg, data),
  info:  (msg: string, data?: Record<string, unknown>) => log('info', msg, data),
  warn:  (msg: string, data?: Record<string, unknown>) => log('warn', msg, data),
  error: (msg: string, data?: Record<string, unknown>) => log('error', msg, data),
};
```

If you need log rotation, multiple transports, or structured formatting later -- your logging library (pino, winston) already handles that. Don't rebuild it.

### Example 3: Event System

**Over-engineered:**

```typescript
interface EventBus {
  subscribe<T extends Event>(
    eventType: Constructor<T>,
    handler: EventHandler<T>,
    options?: SubscriptionOptions
  ): Subscription;
  publish<T extends Event>(event: T): Promise<void>;
  unsubscribe(subscription: Subscription): void;
}

interface SubscriptionOptions {
  priority?: number;
  filter?: (event: Event) => boolean;
  once?: boolean;
  async?: boolean;
  queue?: string;
}

class InMemoryEventBus implements EventBus {
  private subscriptions = new Map<string, PriorityQueue<SubscriptionEntry>>();
  private deadLetterQueue: DeadLetterQueue;
  private middleware: EventMiddleware[] = [];
  // ... 120 lines of implementation
}
```

**Right-sized (for an app with 4 event types):**

```typescript
type Handler = (data: unknown) => void;
const handlers = new Map<string, Set<Handler>>();

export const events = {
  on(event: string, fn: Handler) {
    if (!handlers.has(event)) handlers.set(event, new Set());
    handlers.get(event)!.add(fn);
    return () => handlers.get(event)!.delete(fn);
  },

  emit(event: string, data?: unknown) {
    handlers.get(event)?.forEach(fn => fn(data));
  },
};
```

Fifteen lines. Covers pub/sub for a small application. When you outgrow it, you will know -- because you will have a specific problem that demands a specific solution.

### Example 4: Validation

**Over-engineered:**

```typescript
class ValidationBuilder<T> {
  private rules: ValidationRule<T>[] = [];
  private errorFormatter: ErrorFormatter;
  private abortEarly: boolean;

  required(): ValidationBuilder<T> { /* ... */ }
  string(): StringValidationBuilder<T> { /* ... */ }
  number(): NumberValidationBuilder<T> { /* ... */ }
  custom(fn: CustomValidator<T>): ValidationBuilder<T> { /* ... */ }
  when(condition: Predicate, then: ValidationBuilder<T>): ValidationBuilder<T> { /* ... */ }

  async validate(data: unknown): Promise<ValidationResult<T>> {
    // ... 50 lines of chain execution with error aggregation
  }
}
```

**Right-sized:**

```typescript
function validateCreateUser(data: unknown): { name: string; email: string; age: number } {
  const { name, email, age } = data as Record<string, unknown>;

  const errors: string[] = [];
  if (typeof name !== 'string' || name.length < 1) errors.push('name is required');
  if (typeof email !== 'string' || !email.includes('@')) errors.push('valid email is required');
  if (typeof age !== 'number' || age < 0 || age > 150) errors.push('age must be 0-150');

  if (errors.length > 0) throw new ValidationError(errors);

  return { name, email, age };
}
```

One function per endpoint. No builder. No chains. When you have 30 endpoints with similar validation patterns, then consider a schema library like Zod. Not before.

### Example 5: Database Access

**Over-engineered:**

```typescript
abstract class BaseRepository<T extends Entity> {
  constructor(
    protected readonly model: PrismaModel<T>,
    protected readonly cache: CacheProvider,
    protected readonly logger: Logger,
  ) {}

  abstract mapToDomain(raw: PrismaRecord): T;
  abstract mapToPersistence(entity: T): PrismaRecord;

  async findById(id: string): Promise<T | null> {
    const cached = await this.cache.get(`${this.model.name}:${id}`);
    if (cached) return this.mapToDomain(cached);
    const raw = await this.model.findUnique({ where: { id } });
    if (raw) await this.cache.set(`${this.model.name}:${id}`, raw);
    return raw ? this.mapToDomain(raw) : null;
  }
  // ... findMany, create, update, delete, each 15-20 lines
}
```

**Right-sized:**

```typescript
import { prisma } from '../db';

export const userRepo = {
  findById: (id: string) => prisma.user.findUnique({ where: { id } }),
  findByEmail: (email: string) => prisma.user.findUnique({ where: { email } }),
  create: (data: { name: string; email: string }) => prisma.user.create({ data }),
  updateName: (id: string, name: string) =>
    prisma.user.update({ where: { id }, data: { name } }),
};
```

Prisma already is your data access layer. Wrapping it in an abstract repository with domain mapping and caching is two layers of indirection you do not need until your data access patterns are genuinely complex.

## The "Just Enough Architecture" Principle

The right amount of architecture is the minimum that makes the code:

1. **Readable** -- a new developer can follow the flow
2. **Testable** -- you can write unit tests without elaborate setup
3. **Changeable** -- modifying one feature does not require touching ten files

That is it. Not extensible-for-future-requirements-we-might-have. Not pluggable-in-case-we-swap-providers. Not abstracted-behind-interfaces-for-testability-we-don't-use.

Build what you need today. Refactor when you need more tomorrow. AI tools make refactoring fast and cheap -- which means over-building upfront is even less justified than it used to be.

## CLAUDE.md Defenses

Add these to your project's CLAUDE.md to prevent over-engineering at the source:

```markdown
## Complexity Guidelines
- Functions over classes unless managing stateful resources
- No abstract base classes unless there are 3+ concrete implementations TODAY
- No design patterns unless you can name the specific problem it solves
- No caching unless profiling shows a measured performance problem
- If a solution has more files than the problem has requirements, simplify
- Prefer standard library over custom implementations
- When in doubt, write a plain function that takes arguments and returns a value
```

## Next Steps

- [Common Mistakes](common-mistakes.md) -- The over-engineering trap in context with other anti-patterns
- [Debugging AI Output](debugging-ai.md) -- When the suggestions are wrong, not just overcomplicated
- [Effective Prompting](../03-prompts/effective-prompting.md) -- Write constrained prompts that prevent bloat
