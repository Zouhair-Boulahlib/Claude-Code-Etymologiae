# Go Patterns

> Go's simplicity is a gift to AI-assisted development -- until the AI decides your project needs generics, channels, and three layers of abstraction for a CRUD endpoint.

## CLAUDE.md for Go Projects

Go projects are straightforward, but the AI still needs to know your module path, linting setup, and test conventions.

```markdown
# CLAUDE.md

## Project
API gateway for order processing. Go 1.22, chi router, PostgreSQL via pgx.
Standard layout: cmd/, internal/, pkg/.

## Commands
- `go run ./cmd/server` -- start the server
- `go test ./...` -- all tests
- `go test ./internal/order/...` -- package tests
- `go test -run TestCreateOrder ./internal/order/` -- single test
- `go test -race ./...` -- tests with race detector
- `go vet ./...` -- static analysis
- `golangci-lint run` -- full linter suite
- `make migrate-up` -- run database migrations
- `make generate` -- run go generate (sqlc, mockgen)

## Conventions
- Errors are values -- always check them, always wrap with context
- Interfaces defined where they are used, not where they are implemented
- Accept interfaces, return structs
- No init() functions
- Context is the first parameter of any function that does I/O
- Table-driven tests with t.Run subtests
- No global state -- pass dependencies via struct fields

## Do NOT
- Use panic for error handling (only in main or truly unrecoverable situations)
- Use global variables for configuration -- pass config structs
- Create interfaces with more than 3-5 methods -- split them
- Use channels when a mutex would do
- Add external dependencies without discussing first
```

## Why Go's Simplicity Cuts Both Ways

Go's small feature set means the AI produces idiomatic code more often than with complex languages. There is only one way to write a for loop, one way to handle errors, one way to define a struct.

The problem: the AI often fights Go's simplicity. It introduces unnecessary abstractions, over-uses generics, creates interface hierarchies, or reaches for channels when a plain function call works. Go rewards boring code, and the AI sometimes tries to be clever.

Counter this in your prompts:

```
Keep it simple. No generics unless the function genuinely operates on
multiple types. No channels unless there is real concurrency. No interface
unless there are two or more implementations.
```

## Error Handling

This is the number one area where AI-generated Go code fails silently. The AI knows it should check errors. It still forgets -- especially in deferred calls and goroutines.

```go
// AI-generated -- looks fine at first glance
func (s *OrderService) CreateOrder(ctx context.Context, req CreateOrderRequest) (*Order, error) {
    order := &Order{
        CustomerID: req.CustomerID,
        Status:     StatusPending,
        CreatedAt:  time.Now(),
    }

    s.db.Save(ctx, order)  // BUG: error not checked

    s.notifier.Send(ctx, order.CustomerID, "Order created")  // BUG: error not checked

    return order, nil
}
```

The fix is to state your error handling pattern explicitly:

```
Every function call that returns an error must have that error checked.
Wrap errors with context using fmt.Errorf("operation: %w", err).
Never discard errors silently.

For deferred closes, use a helper:
  defer func() { _ = rows.Close() }()
or log the error if it matters.
```

Correct version:

```go
func (s *OrderService) CreateOrder(ctx context.Context, req CreateOrderRequest) (*Order, error) {
    order := &Order{
        CustomerID: req.CustomerID,
        Status:     StatusPending,
        CreatedAt:  time.Now(),
    }

    if err := s.db.Save(ctx, order); err != nil {
        return nil, fmt.Errorf("saving order: %w", err)
    }

    if err := s.notifier.Send(ctx, order.CustomerID, "Order created"); err != nil {
        // Non-critical -- log but don't fail the order
        s.logger.Error("failed to send notification",
            "customer_id", order.CustomerID,
            "error", err,
        )
    }

    return order, nil
}
```

Tell the AI which errors are critical (return them) and which are non-critical (log them). Without this guidance, it either ignores all errors or treats all of them as fatal.

## Interface-Driven Design

Go interfaces are implicit -- a type satisfies an interface by implementing its methods, with no `implements` keyword. This is powerful for AI-assisted design because you can define the contract first, then generate implementations.

The key rule: **accept interfaces, return structs.**

```go
// Good -- interface defined where it is consumed
type OrderRepository interface {
    Save(ctx context.Context, order *Order) error
    FindByID(ctx context.Context, id string) (*Order, error)
    List(ctx context.Context, filter OrderFilter) ([]Order, error)
}

// The service accepts the interface
type OrderService struct {
    repo   OrderRepository
    logger *slog.Logger
}

func NewOrderService(repo OrderRepository, logger *slog.Logger) *OrderService {
    return &OrderService{repo: repo, logger: logger}
}
```

Prompt pattern:

```
Define an OrderRepository interface in internal/order/service.go
with Save, FindByID, and List methods. Then create a PostgreSQL
implementation in internal/order/postgres_repo.go that uses pgx.

The interface belongs in the service file -- not in the repository file.
Keep the interface small: only the methods the service actually needs.
```

Common AI mistake: creating large interfaces that mirror the full database API. Push back with "Only include methods that the service uses today. We can add methods when we need them."

## Testing

### Table-Driven Tests

Go's testing convention is table-driven tests with subtests. The AI generally knows this pattern, but it sometimes generates individual test functions instead. Be explicit.

```
Write table-driven tests for ParseDuration in internal/util/duration.go.
Use t.Run subtests. Include cases for:
- Valid inputs: "30s", "5m", "2h", "1h30m"
- Invalid inputs: "", "abc", "-5s", "99z"
- Edge cases: "0s", very large values

Follow this structure:

  tests := []struct{
      name    string
      input   string
      want    time.Duration
      wantErr bool
  }{...}
```

```go
func TestParseDuration(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        want    time.Duration
        wantErr bool
    }{
        {name: "seconds", input: "30s", want: 30 * time.Second},
        {name: "minutes", input: "5m", want: 5 * time.Minute},
        {name: "hours and minutes", input: "1h30m", want: 90 * time.Minute},
        {name: "zero", input: "0s", want: 0},
        {name: "empty string", input: "", wantErr: true},
        {name: "invalid unit", input: "99z", wantErr: true},
        {name: "negative", input: "-5s", wantErr: true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := ParseDuration(tt.input)
            if tt.wantErr {
                require.Error(t, err)
                return
            }
            require.NoError(t, err)
            assert.Equal(t, tt.want, got)
        })
    }
}
```

### HTTP Handler Tests

Use `httptest` -- the AI often reaches for external mocking libraries when the standard library works perfectly.

```
Write tests for the CreateOrder handler using httptest.
Mock the OrderService interface (defined in handler.go).
Test:
- 201 on success with Location header
- 400 on invalid JSON body
- 400 on validation failure (missing customer_id)
- 500 on service error

Use httptest.NewRecorder and http.NewRequest. Do not add external test dependencies.
```

```go
func TestCreateOrderHandler(t *testing.T) {
    tests := []struct {
        name       string
        body       string
        mockSetup  func(*MockOrderService)
        wantStatus int
        wantBody   string
    }{
        {
            name: "success",
            body: `{"customer_id":"cust-1","items":[{"sku":"A","qty":2}]}`,
            mockSetup: func(m *MockOrderService) {
                m.CreateFunc = func(ctx context.Context, req CreateOrderRequest) (*Order, error) {
                    return &Order{ID: "ord-1", CustomerID: "cust-1"}, nil
                }
            },
            wantStatus: http.StatusCreated,
        },
        {
            name:       "invalid json",
            body:       `{not json}`,
            mockSetup:  func(m *MockOrderService) {},
            wantStatus: http.StatusBadRequest,
        },
        {
            name: "missing customer_id",
            body: `{"items":[{"sku":"A","qty":2}]}`,
            mockSetup: func(m *MockOrderService) {},
            wantStatus: http.StatusBadRequest,
        },
        {
            name: "service error",
            body: `{"customer_id":"cust-1","items":[{"sku":"A","qty":2}]}`,
            mockSetup: func(m *MockOrderService) {
                m.CreateFunc = func(ctx context.Context, req CreateOrderRequest) (*Order, error) {
                    return nil, fmt.Errorf("database connection lost")
                }
            },
            wantStatus: http.StatusInternalServerError,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            mock := &MockOrderService{}
            tt.mockSetup(mock)
            handler := NewOrderHandler(mock, slog.Default())

            req := httptest.NewRequest(http.MethodPost, "/orders", strings.NewReader(tt.body))
            req.Header.Set("Content-Type", "application/json")
            rec := httptest.NewRecorder()

            handler.Create(rec, req)

            assert.Equal(t, tt.wantStatus, rec.Code)
        })
    }
}
```

## Common AI Mistakes

### Goroutine Leaks

The AI spawns goroutines without a way to stop them. Every goroutine must have a clear shutdown path.

```go
// LEAK: goroutine runs forever, no way to stop it
func (s *Service) StartPolling() {
    go func() {
        for {
            s.poll()
            time.Sleep(10 * time.Second)
        }
    }()
}

// CORRECT: context cancellation stops the goroutine
func (s *Service) StartPolling(ctx context.Context) {
    go func() {
        ticker := time.NewTicker(10 * time.Second)
        defer ticker.Stop()
        for {
            select {
            case <-ctx.Done():
                return
            case <-ticker.C:
                s.poll(ctx)
            }
        }
    }()
}
```

Add to CLAUDE.md: "Every goroutine must be stoppable via context cancellation or a done channel."

### Missing Mutex

The AI adds concurrent access to shared state without synchronization.

```go
// RACE CONDITION: concurrent map writes
type Cache struct {
    items map[string]Item
}

func (c *Cache) Set(key string, item Item) {
    c.items[key] = item  // will panic under concurrent access
}

// CORRECT: mutex-protected access
type Cache struct {
    mu    sync.RWMutex
    items map[string]Item
}

func (c *Cache) Set(key string, item Item) {
    c.mu.Lock()
    defer c.mu.Unlock()
    c.items[key] = item
}

func (c *Cache) Get(key string) (Item, bool) {
    c.mu.RLock()
    defer c.mu.RUnlock()
    item, ok := c.items[key]
    return item, ok
}
```

Always run `go test -race ./...` to catch these. State this in CLAUDE.md under commands.

### Wrong Error Wrapping

The AI uses `fmt.Errorf("failed: %v", err)` instead of `%w`. The `%v` verb creates a new error that loses the error chain -- callers cannot use `errors.Is` or `errors.As` on it.

```go
// WRONG: breaks error chain
if err := s.repo.Save(ctx, order); err != nil {
    return fmt.Errorf("failed to save order: %v", err)
}

// CORRECT: preserves error chain for errors.Is/errors.As
if err := s.repo.Save(ctx, order); err != nil {
    return fmt.Errorf("saving order: %w", err)
}
```

Put this in CLAUDE.md: "Wrap errors with %w, not %v. Drop the 'failed to' prefix -- the caller adds context."

## Context Propagation

Every function that touches I/O -- HTTP, database, filesystem, external services -- takes `context.Context` as its first argument. The AI sometimes creates functions without it, then adds it later as an afterthought.

```
All functions that perform I/O must accept context.Context as the first parameter.
Do not create context.Background() inside library code -- receive it from the caller.
Only main() and top-level handlers should create contexts.
```

```go
// BAD: creates its own context, ignoring cancellation from above
func (r *PostgresRepo) FindByID(id string) (*Order, error) {
    ctx := context.Background()  // request cancellation is lost
    row := r.db.QueryRow(ctx, "SELECT ...", id)
    // ...
}

// GOOD: respects the caller's context
func (r *PostgresRepo) FindByID(ctx context.Context, id string) (*Order, error) {
    row := r.db.QueryRow(ctx, "SELECT ...", id)
    // ...
}
```

## Struct Design and Constructors

Go does not have constructors, but the `New` function pattern is the established convention. The AI knows this but sometimes skips validation.

```go
type ServerConfig struct {
    Host         string
    Port         int
    ReadTimeout  time.Duration
    WriteTimeout time.Duration
    Logger       *slog.Logger
}

func NewServer(cfg ServerConfig) (*Server, error) {
    if cfg.Port <= 0 || cfg.Port > 65535 {
        return nil, fmt.Errorf("invalid port: %d", cfg.Port)
    }
    if cfg.Logger == nil {
        cfg.Logger = slog.Default()
    }
    if cfg.ReadTimeout == 0 {
        cfg.ReadTimeout = 30 * time.Second
    }
    if cfg.WriteTimeout == 0 {
        cfg.WriteTimeout = 30 * time.Second
    }

    return &Server{
        host:         cfg.Host,
        port:         cfg.Port,
        readTimeout:  cfg.ReadTimeout,
        writeTimeout: cfg.WriteTimeout,
        logger:       cfg.Logger,
    }, nil
}
```

The pattern: config struct in, pointer to private-field struct out. Defaults applied in the constructor. This is idiomatic and the AI handles it well when you point to an existing example.

## CLI Tool Generation with Cobra

Cobra is the standard for Go CLIs, and the AI knows its patterns well. The key is to keep commands thin -- they parse flags and call into a service layer.

```
Generate a cobra CLI command at cmd/import.go for importing orders from CSV.
Follow the pattern in cmd/export.go.

The command should:
- Accept a --file flag (required) for the CSV path
- Accept a --dry-run flag (default false) to preview without writing
- Accept a --batch-size flag (default 100) for batch insert size
- Call internal/order.ImportService.Import() with the parsed options
- Print a summary: imported count, skipped count, error count

Keep the cobra command thin -- parsing and output only. Business logic stays in the service.
```

```go
var importCmd = &cobra.Command{
    Use:   "import",
    Short: "Import orders from a CSV file",
    RunE: func(cmd *cobra.Command, args []string) error {
        file, _ := cmd.Flags().GetString("file")
        dryRun, _ := cmd.Flags().GetBool("dry-run")
        batchSize, _ := cmd.Flags().GetInt("batch-size")

        svc, err := order.NewImportService(db, logger)
        if err != nil {
            return fmt.Errorf("creating import service: %w", err)
        }

        result, err := svc.Import(cmd.Context(), order.ImportOptions{
            FilePath:  file,
            DryRun:    dryRun,
            BatchSize: batchSize,
        })
        if err != nil {
            return fmt.Errorf("importing orders: %w", err)
        }

        fmt.Fprintf(cmd.OutOrStdout(), "Imported: %d\nSkipped: %d\nErrors: %d\n",
            result.Imported, result.Skipped, result.Errors)
        return nil
    },
}

func init() {
    rootCmd.AddCommand(importCmd)
    importCmd.Flags().String("file", "", "path to CSV file (required)")
    importCmd.Flags().Bool("dry-run", false, "preview without writing")
    importCmd.Flags().Int("batch-size", 100, "number of records per batch insert")
    importCmd.MarkFlagRequired("file")
}
```

## Real Example: REST Handler with Middleware

Here is the full prompt sequence for generating a REST handler with proper error handling and middleware. This produces production-ready code in four steps.

**Step 1 -- Define types and interfaces:**

```
Create the following in internal/order/types.go:
- Order struct with fields: ID, CustomerID, Items []OrderItem, Status, CreatedAt
- OrderItem struct: SKU, Quantity, UnitPrice
- OrderFilter struct: CustomerID (optional), Status (optional), Limit, Offset
- OrderService interface: Create, GetByID, List methods
- All methods accept context.Context as first param, return (result, error)
```

**Step 2 -- Create the handler:**

```
Create an HTTP handler at internal/order/handler.go.
Use chi router. The handler struct holds an OrderService interface and a logger.

Endpoints:
- POST /orders -- create order, return 201 with Location header
- GET /orders/{id} -- get by ID, return 404 if not found
- GET /orders -- list with ?customer_id, ?status, ?limit, ?offset query params

Parse JSON with json.NewDecoder (not ioutil.ReadAll).
Respond with a writeJSON helper that sets Content-Type.
Use a structured error response: {"error": "message", "code": "NOT_FOUND"}.

Do NOT use any framework beyond chi for routing.
```

```go
type OrderHandler struct {
    service OrderService
    logger  *slog.Logger
}

func NewOrderHandler(service OrderService, logger *slog.Logger) *OrderHandler {
    return &OrderHandler{service: service, logger: logger}
}

func (h *OrderHandler) Routes() chi.Router {
    r := chi.NewRouter()
    r.Post("/", h.create)
    r.Get("/{id}", h.getByID)
    r.Get("/", h.list)
    return r
}

func (h *OrderHandler) create(w http.ResponseWriter, r *http.Request) {
    var req CreateOrderRequest
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        writeError(w, http.StatusBadRequest, "INVALID_BODY", "invalid request body")
        return
    }

    if err := req.Validate(); err != nil {
        writeError(w, http.StatusBadRequest, "VALIDATION_FAILED", err.Error())
        return
    }

    order, err := h.service.Create(r.Context(), req)
    if err != nil {
        h.logger.Error("creating order", "error", err)
        writeError(w, http.StatusInternalServerError, "INTERNAL", "failed to create order")
        return
    }

    w.Header().Set("Location", fmt.Sprintf("/orders/%s", order.ID))
    writeJSON(w, http.StatusCreated, order)
}
```

**Step 3 -- Add middleware:**

```
Create middleware in internal/middleware/:
1. RequestID -- generates a UUID, adds to context and X-Request-ID header
2. Logger -- logs method, path, status, duration using slog; reads request ID from context
3. Recoverer -- catches panics, logs stack trace, returns 500

Each middleware is a func(http.Handler) http.Handler.
Use the context for passing request ID -- not headers internally.
```

```go
func RequestID(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        id := uuid.NewString()
        ctx := context.WithValue(r.Context(), requestIDKey, id)
        w.Header().Set("X-Request-ID", id)
        next.ServeHTTP(w, r.WithContext(ctx))
    })
}

func Logger(logger *slog.Logger) func(http.Handler) http.Handler {
    return func(next http.Handler) http.Handler {
        return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
            start := time.Now()
            wrapped := &statusRecorder{ResponseWriter: w, status: http.StatusOK}

            next.ServeHTTP(wrapped, r)

            logger.Info("request",
                "method", r.Method,
                "path", r.URL.Path,
                "status", wrapped.status,
                "duration", time.Since(start),
                "request_id", GetRequestID(r.Context()),
            )
        })
    }
}
```

**Step 4 -- Wire it up and test:**

```
Create cmd/server/main.go that wires everything together:
- Load config from environment variables
- Create pgx connection pool
- Create repository, service, handler
- Set up chi router with middleware stack: RequestID, Logger, Recoverer
- Mount /orders routes
- Graceful shutdown on SIGINT/SIGTERM

Then write table-driven tests for the handler in internal/order/handler_test.go.
Mock the OrderService interface. Test all status codes and error paths.
Use httptest only -- no external dependencies.
```

This four-step sequence produces a complete, idiomatic Go HTTP service. Each step is reviewable in isolation, and the dependencies flow in one direction: handler depends on service interface, service interface is defined in the domain package.

## Next Steps

- [Testing Strategies](../04-architecture/testing.md) -- Framework-agnostic testing patterns
- [Writing Code](../02-workflows/writing-code.md) -- General code generation techniques
- [The CLAUDE.md File](../01-foundations/claude-md.md) -- Configure project-wide conventions
