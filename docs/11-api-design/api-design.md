# API Design with AI

> Contract first, implement second -- let the spec drive the AI, not the other way around.

## Contract-First Design

The single most important principle when using AI for API work: **define the contract before you generate a single line of implementation code.**

Without a spec, AI will invent an API surface for you. It will name things inconsistently, guess at response shapes, and make assumptions about authentication, pagination, and error handling that you will spend days untangling. With a spec, AI becomes a remarkably efficient code generator -- it has the exact constraints it needs to produce correct, consistent handlers on the first pass.

Contract-first is not new advice. What is new is how dramatically the payoff increases with AI. A human developer might tolerate a loose spec because they carry context in their head. AI carries nothing between prompts unless you give it a document to anchor on. The spec *is* that anchor.

The workflow, regardless of API style:

1. **You** design the contract (schema, spec, proto)
2. **AI** validates and refines the contract based on your feedback
3. **AI** generates implementation from the finalized contract
4. **You** review, test, and iterate

This order matters. Reversing steps 1 and 3 is the most common API design mistake with AI.

---

## REST API Design

### OpenAPI-First Workflow

Start every REST API project by writing -- or prompting for -- an OpenAPI spec. This becomes your source of truth.

```
"Create an OpenAPI 3.1 spec for a project management API with these resources:
- /projects (CRUD, supports pagination via cursor)
- /projects/{id}/tasks (CRUD, filterable by status and assignee)
- /projects/{id}/members (list, add, remove)

Requirements:
- All responses use a standard envelope: { data, meta, errors }
- Authentication via Bearer token
- Include request/response examples for every endpoint
- Use $ref for shared schemas (Pagination, Error, Timestamps)
- Output as YAML"
```

Once you have the spec, use it to drive everything else:

```
"Read the OpenAPI spec in docs/api/openapi.yaml. Generate Express route
handlers for the /projects resource. Follow these rules:
- Use zod for request validation, derived from the spec's schemas
- Each handler in its own file under src/routes/projects/
- Validation middleware in src/middleware/validate.ts
- Return the exact response shapes defined in the spec
- Include JSDoc comments referencing the operationId"
```

The key insight: AI generates dramatically better validation, error handling, and response shaping when it can reference a concrete spec rather than inferring your intent.

### Resource Design Prompts

Getting resource modeling right matters more than getting any individual endpoint right. A bad resource hierarchy creates cascading problems in every handler.

```
"I am designing a multi-tenant API for a veterinary clinic platform.
Tenants are clinics. Each clinic has staff, patients (animals), owners,
and appointments. Design the REST resource hierarchy.

Constraints:
- Staff can belong to multiple clinics
- Owners can have multiple patients across clinics
- Appointments always belong to one clinic
- All resources must be scoped by clinic in the URL except /me
- Use plural nouns, kebab-case for multi-word resources
- No deeper than 3 levels of nesting

Output: the resource tree with example URLs and HTTP methods, plus a
brief justification for any non-obvious modeling decisions."
```

After the AI proposes a resource structure, challenge it:

```
"For the resource hierarchy you just proposed: what happens when a staff
member needs to see appointments across all their clinics? Does the
current design require N requests? If so, propose a top-level aggregate
endpoint that solves this without breaking the tenant scoping model."
```

This back-and-forth is where AI shines -- it can rapidly iterate on resource modeling while you evaluate the trade-offs.

### Versioning Strategies

```
"We are adding v2 of our billing API. The v1 endpoints must continue
working. Compare two approaches for our Express app:

1. URL versioning: /api/v1/invoices and /api/v2/invoices
2. Header versioning: Accept: application/vnd.myapp.v2+json

For each, show:
- Router setup
- How a shared service layer works across versions
- How we deprecate v1 endpoints with sunset headers

Our stack: Express, TypeScript, Prisma. We currently have 14 endpoints."
```

URL versioning is simpler and what most teams should use. But the prompt above forces the AI to show you both so you can make an informed decision, not a default one.

---

## GraphQL API Design

### Schema-First Development

The same principle applies: write the SDL schema first, then generate resolvers.

```
"Here is my GraphQL schema for a content management system:

type Article {
  id: ID!
  title: String!
  slug: String!
  body: String!
  status: ArticleStatus!
  author: User!
  tags: [Tag!]!
  publishedAt: DateTime
  createdAt: DateTime!
  updatedAt: DateTime!
}

enum ArticleStatus {
  DRAFT
  IN_REVIEW
  PUBLISHED
  ARCHIVED
}

type Query {
  article(id: ID, slug: String): Article
  articles(filter: ArticleFilter, pagination: CursorPagination!): ArticleConnection!
}

type Mutation {
  createArticle(input: CreateArticleInput!): ArticlePayload!
  updateArticle(id: ID!, input: UpdateArticleInput!): ArticlePayload!
  publishArticle(id: ID!): ArticlePayload!
}

Generate the resolvers using Apollo Server 4 and Prisma. Each resolver
in its own file. Use the dataSource pattern -- do not put Prisma calls
directly in resolvers. Include input validation with custom GraphQL
errors that follow the { message, code, path } pattern."
```

### N+1 and DataLoader Patterns

The N+1 problem is the most common performance issue in GraphQL, and AI frequently generates code that has it. Be explicit.

```
"The article resolver fetches author and tags. With a list of 50 articles,
this creates 50 author queries and 50 tag queries.

Add DataLoaders for:
1. User (batch by user ID)
2. Tags (batch by article ID, since it is a many-to-many)

Rules:
- DataLoaders must be request-scoped (new instance per request)
- Create them in a factory function: createLoaders(prisma)
- Attach to context in the Apollo server setup
- Update the article resolvers to use context.loaders instead of
  direct Prisma calls
- Add a comment explaining why each loader exists"
```

Always test the result by checking what SQL actually runs. Ask the AI to help:

```
"Add Prisma query logging (event-based) so I can verify the DataLoaders
are actually batching. Show me what to look for in the logs when I query
articles { author { name } } for 20 articles -- I should see 1 article
query and 1 batched user query, not 21 queries."
```

### Subscription Patterns

```
"Add a GraphQL subscription for real-time article status changes:

subscription {
  articleStatusChanged(projectId: ID!) {
    article { id title status }
    previousStatus
    changedBy { id name }
  }
}

Use graphql-ws (not the deprecated subscriptions-transport-ws).
The pub/sub backend is Redis. Show:
1. The subscription resolver
2. The publish call in the updateArticle and publishArticle mutations
3. The Redis pub/sub setup
4. WebSocket server integration with Apollo Server 4

Filter events so clients only receive updates for their projectId."
```

---

## gRPC API Design

### Proto-First Workflow

With gRPC, proto-first is not optional -- it is how the framework works. The prompt pattern focuses on getting the proto file right before generating anything.

```
"Design a .proto file for an order processing service.

Services:
- OrderService: CreateOrder, GetOrder, ListOrders, CancelOrder
- PaymentService: ProcessPayment, RefundPayment, GetPaymentStatus

Requirements:
- Use proto3 syntax
- Separate message types for requests and responses (no reuse)
- Include field validation comments
- google.protobuf.Timestamp for all time fields
- Pagination on ListOrders using page_token pattern
- Proper use of oneof for payment method (card, bank_transfer, wallet)
- Package: com.myapp.orders.v1

Do not generate service implementations yet. Just the proto file."
```

After the proto is finalized:

```
"Read the proto file at proto/orders/v1/orders.proto. Generate the Go
service implementation using grpc-go. Structure:
- internal/service/order_service.go
- internal/service/payment_service.go
- Each RPC method gets proper error handling with gRPC status codes
- Use the repository pattern for data access (interface + implementation)
- Include interceptor hooks for authentication and logging"
```

### Streaming Patterns

gRPC streaming is powerful but tricky. Be precise about which pattern you need.

```
"Add a server-streaming RPC to OrderService:

rpc TrackOrder(TrackOrderRequest) returns (stream OrderUpdate);

The server sends real-time updates as an order moves through stages:
PLACED -> CONFIRMED -> PREPARING -> SHIPPED -> DELIVERED

Implementation requirements:
- The stream stays open until the order reaches a terminal state
  (DELIVERED or CANCELLED)
- Send a heartbeat every 30 seconds if no state change occurs
- Handle client disconnection gracefully (context.Done())
- Include a Go client example that reads the stream
- Add proper deadline/timeout handling on both sides"
```

For bidirectional streaming:

```
"Add a bidirectional streaming RPC for real-time chat between customer
support and order customers:

rpc SupportChat(stream ChatMessage) returns (stream ChatMessage);

Handle: message ordering, client reconnection with message replay from
last seen ID, and graceful shutdown when either side closes the stream.
Show both the server handler and a client implementation in Go."
```

---

## Cross-Cutting Concerns

### Authentication & Authorization

Auth is where AI-generated APIs most often have security gaps. Be exhaustive in your prompt.

```
"Add JWT authentication middleware to all three API styles in this project:

REST (Express):
- Middleware that validates Bearer tokens on all routes except /health
  and /auth/*
- Extract tenant_id and user_id from token claims
- Attach to req.auth

GraphQL (Apollo):
- Context function that validates the token and populates context.user
- Throw AuthenticationError for missing/invalid tokens
- Queries/mutations that require specific roles use @auth directive

gRPC:
- Unary interceptor that reads the 'authorization' metadata key
- Populate context with user claims
- Skip auth for the HealthCheck RPC

For all three: tokens are RS256, JWKS endpoint is at
/.well-known/jwks.json, tokens expire in 1 hour, and refresh is
handled by a separate auth service (not in scope)."
```

### Error Handling

Consistency across your API is non-negotiable. Define the error contract and make the AI follow it.

```
"Implement consistent error handling across our API:

REST: Use RFC 9457 Problem Details. Every error response must include
type, title, status, detail, and instance. Create an AppError class
that serializes to this format. Add an Express error handler that
catches all thrown AppErrors.

GraphQL: All errors must include extensions with { code, timestamp,
requestId }. Create a base GraphQLAppError class. Validation errors
should return multiple errors in the errors array, one per field.

gRPC: Map application errors to appropriate status codes:
- NotFound -> codes.NotFound
- Validation -> codes.InvalidArgument (with field details in metadata)
- Auth -> codes.Unauthenticated
- Permission -> codes.PermissionDenied
- Conflict -> codes.AlreadyExists

Create a shared error catalog in src/errors/ that all three API styles
use as their source of truth."
```

### Pagination

```
"Add cursor-based pagination to the articles list endpoint.

Requirements:
- Cursor is an opaque base64-encoded string (not a raw ID)
- Support forward pagination: first + after
- Support backward pagination: last + before
- Response includes: edges with node and cursor, plus pageInfo
  { hasNextPage, hasPreviousPage, startCursor, endCursor }
- Default page size: 20, max: 100
- Stable ordering by createdAt DESC, id DESC (tie-breaker)

Implement for both REST (as query params) and GraphQL (as connection
type). The underlying Prisma query should be the same for both.
Show how cursor encoding/decoding works and handle the edge case
of a cursor pointing to a deleted record."
```

### Rate Limiting

```
"Add rate limiting to the REST API using a sliding window algorithm
backed by Redis.

Tiers:
- Anonymous: 30 requests/minute
- Authenticated: 120 requests/minute
- Admin: 600 requests/minute

Requirements:
- Return X-RateLimit-Limit, X-RateLimit-Remaining, X-RateLimit-Reset
  headers on every response
- Return 429 with Retry-After header when limit is exceeded
- Rate limit key: IP for anonymous, user_id for authenticated
- Skip rate limiting for /health and /metrics
- The middleware must work with Express and be testable without Redis
  (in-memory fallback for tests)"
```

---

## CLAUDE.md for API Projects

Add this section to your project's CLAUDE.md to keep every AI interaction aligned with your API conventions:

```markdown
## API Conventions

### REST
- All endpoints follow OpenAPI spec at docs/api/openapi.yaml
- Response envelope: { data, meta, errors } -- no exceptions
- Use plural resource names, kebab-case: /api/v1/project-members
- Pagination: cursor-based, never offset
- Errors: RFC 9457 Problem Details format

### GraphQL
- Schema-first: edit schema.graphql, then update resolvers
- All list queries must use Connection pattern with cursor pagination
- DataLoaders required for any relationship resolver
- Mutations return { success, errors, [entity] } payload type

### gRPC
- Proto files in proto/ directory, generated code in gen/
- Never edit generated code -- regenerate with buf generate
- All RPCs must have request and response messages (no Empty reuse)

### Shared rules
- Auth: JWT with RS256, claims in context
- Validation: at the API boundary, never in the service layer
- Error codes: defined in src/errors/catalog.ts, used everywhere
- No breaking changes to published API without versioning
```

---

## Common Pitfalls

**Letting AI design your API surface.** AI is excellent at *implementing* an API you have designed. It is mediocre at *designing* the API itself. It will default to generic CRUD patterns, miss domain-specific resource modeling, and create inconsistent naming. You design the resources, relationships, and semantics. AI writes the code.

**Inconsistent naming conventions.** Without explicit rules, AI will mix `camelCase` and `snake_case` in the same response body, use singular nouns in one endpoint and plural in another, and alternate between `id` and `ID` in GraphQL types. Put naming rules in your CLAUDE.md. Be pedantic about it.

**Missing validation at boundaries.** AI tends to generate handlers that trust input. It will parse the request body and pass it straight to the service layer. Every AI-generated handler should have explicit validation at the API boundary -- zod schemas for REST, input types with custom validation for GraphQL, proto field validation for gRPC. If the AI skips it, ask for it explicitly.

**Over-fetching in REST.** AI will return the full object for every endpoint unless you constrain it. Specify which fields each endpoint returns. Better yet, define response schemas in your OpenAPI spec and tell the AI to follow them exactly.

**Under-typing in GraphQL.** AI generates `String` for everything. Dates become strings. Emails become strings. URLs become strings. Use custom scalars and tell the AI which fields use them. If you have a `DateTime` scalar, put it in the schema before asking for resolvers.

**Ignoring idempotency.** AI rarely adds idempotency keys to POST endpoints unless asked. For any endpoint that creates resources or processes payments, prompt explicitly: "Add an Idempotency-Key header. If a duplicate key is received within 24 hours, return the original response."

**Generating API docs instead of spec-driven docs.** Do not ask AI to write API documentation from scratch. Generate it from your OpenAPI spec or GraphQL schema using tools like Redoc, Swagger UI, or GraphQL Playground. The spec is the doc. AI should help you write better specs, not separate documentation that drifts from reality.

---

## Next Steps

- [Testing Strategies](../04-architecture/testing.md) -- Test your API contracts
- [Documentation](../04-architecture/documentation.md) -- Generate API docs from code
- [Security Considerations](../06-team/security.md) -- Secure your API endpoints
- [Prompt Frameworks](../10-frameworks/prompt-frameworks.md) -- Structured approaches for complex API prompts
