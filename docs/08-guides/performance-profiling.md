# Performance Profiling with AI

> Claude Code cannot run your profiler, attach to your process, or observe your production traffic. What it can do is interpret profiling data you share and suggest targeted optimizations. This guide covers how to feed profiling output to AI effectively and get actionable results.

## The Fundamental Rule

**AI optimizes what you measure. It cannot measure for you.**

Claude Code has no access to your running application, no ability to time queries, no way to capture flame graphs. Your job is measurement. Its job is interpretation and code changes.

The workflow is always:

```
You measure -> You share data -> AI analyzes -> AI suggests fix -> You measure again
```

Skip the measurement step and you get guesses. Sometimes educated guesses, but guesses.

---

## Sharing Profiling Data Effectively

### What to Include

Every performance prompt needs three things:

1. **The measurement** -- actual numbers, not vibes
2. **The target** -- what "fast enough" means
3. **The relevant code or query** -- what produced the measurement

```
Bad:  "The API is slow, make it faster"

Good: "GET /api/orders takes 3.2s for users with 500+ orders.
       Target: under 300ms.
       Here's the EXPLAIN ANALYZE output for the main query: [paste]
       Here's the endpoint code: [file path]"
```

### Describing Flame Graphs

You cannot paste a flame graph image into Claude Code. Describe it:

```
The flame graph for GET /api/dashboard shows:
- 62% of time in OrderService.getRecentOrders()
  - 45% in database query (SQL execution)
  - 17% in JSON serialization of results
- 23% in UserService.getPermissions()
  - All 23% is a single DB query
- 15% in middleware stack (auth, logging, etc.)

Total request time: 1.8s
The hot path is clearly OrderService -> DB query at 45%.
```

This gives the AI exactly what it needs to focus on the right function.

---

## Database Query Optimization

This is where AI shines most. SQL optimization has clear, well-understood patterns and the AI can read EXPLAIN output fluently.

### Sharing EXPLAIN ANALYZE Output

```
This query runs on the orders table (12M rows) and takes 3.2s:

SELECT o.*, u.name, u.email
FROM orders o
JOIN users u ON u.id = o.user_id
WHERE o.user_id = $1
  AND o.created_at > NOW() - INTERVAL '90 days'
ORDER BY o.created_at DESC
LIMIT 50;

EXPLAIN ANALYZE output:

Limit (cost=45123.45..45123.57 rows=50 width=312) (actual time=3201.45..3201.52 rows=50 loops=1)
  -> Sort (cost=45123.45..45234.56 rows=44521 width=312) (actual time=3201.44..3201.48 rows=50 loops=1)
        Sort Key: o.created_at DESC
        Sort Method: top-N heapsort  Memory: 89kB
        -> Hash Join (cost=8.45..43210.67 rows=44521 width=312) (actual time=0.12..3180.34 rows=44521 loops=1)
              -> Seq Scan on orders o (cost=0.00..41234.00 rows=44521 width=256) (actual time=0.08..3150.21 rows=44521 loops=1)
                    Filter: (user_id = 1234 AND created_at > '2024-01-15')
                    Rows Removed by Filter: 11955479
Planning Time: 0.15 ms
Execution Time: 3201.67 ms

Target: under 200ms. What indexes do I need?
```

The AI will immediately spot the sequential scan on 12M rows and suggest:

```sql
CREATE INDEX idx_orders_user_created ON orders (user_id, created_at DESC);
```

This is a composite index that covers the WHERE clause and the ORDER BY, eliminating the sequential scan and the sort. Typical result: 3200ms down to 2-5ms.

### Fixing N+1 Queries

Share the pattern you suspect:

```
This endpoint takes 4.5s. I suspect N+1 queries.
Here's the service method:

async function getOrdersWithItems(userId: string) {
  const orders = await db.query('SELECT * FROM orders WHERE user_id = $1', [userId]);

  for (const order of orders) {
    order.items = await db.query(
      'SELECT * FROM order_items WHERE order_id = $1', [order.id]
    );
    for (const item of order.items) {
      item.product = await db.query(
        'SELECT * FROM products WHERE id = $1', [item.product_id]
      );
    }
  }

  return orders;
}

The user has 200 orders with an average of 5 items each.
That's 1 + 200 + 1000 = 1201 queries. Fix it.
```

The AI will rewrite it to use JOINs or batched queries:

```typescript
async function getOrdersWithItems(userId: string) {
  const result = await db.query(`
    SELECT
      o.id as order_id, o.created_at, o.total,
      oi.id as item_id, oi.quantity, oi.price,
      p.id as product_id, p.name, p.sku
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.id
    JOIN products p ON p.id = oi.product_id
    WHERE o.user_id = $1
    ORDER BY o.created_at DESC
  `, [userId]);

  return groupByOrder(result.rows);
}
```

One query instead of 1201. Typical improvement: 4.5s down to 50ms.

---

## Frontend Performance

### React Profiler Output

Share React Profiler data as text:

```
React Profiler results for the Dashboard page:

Component render times (commit #1, mount):
  <Dashboard>          14.2ms
    <OrderTable>       892.3ms  <-- problem
      <OrderRow> x200  4.1ms each (820ms total)
        <PriceCell>    0.3ms each
    <Sidebar>          12.1ms
    <Chart>            45.6ms

On re-render (state update from filter change):
  <OrderTable>       876.5ms  <-- re-renders everything
    <OrderRow> x200  still 4.1ms each

OrderRow does not use React.memo. The filter change causes
all 200 rows to re-render even though only the visible ones change.
```

The AI will suggest memoization, virtualization, or both:

```tsx
const OrderRow = React.memo(function OrderRow({ order }: Props) {
  return (
    <tr>
      <td>{order.id}</td>
      <td>{order.customer}</td>
      <td><PriceCell amount={order.total} /></td>
    </tr>
  );
});

// For 200+ rows, add virtualization:
import { useVirtualizer } from '@tanstack/react-virtual';
```

### Bundle Size Analysis

```
webpack-bundle-analyzer output:

Total bundle: 1.82MB (gzipped: 512KB)
  node_modules/moment: 287KB (67KB gzipped)  <-- 13% of gzipped
  node_modules/lodash: 71KB (24KB gzipped)
  src/components:      145KB (41KB gzipped)
  node_modules/chart.js: 203KB (62KB gzipped)

Lighthouse Performance score: 54
Largest Contentful Paint: 4.2s
Total Blocking Time: 890ms

Target: Lighthouse 85+, LCP under 2.5s.
The moment.js import is only used for date formatting in 3 files.
```

The AI will suggest replacing moment with a lighter alternative and lazy-loading chart.js:

```typescript
// Replace moment (287KB) with date-fns (tree-shakeable, ~5KB for format)
import { format } from 'date-fns';

// Lazy-load Chart component
const Chart = lazy(() => import('./Chart'));
```

---

## Node.js Profiling

### Sharing --prof Output

Process the V8 profiler output and share the summary:

```bash
# Generate the profile
node --prof app.js
# Process it
node --prof-process isolate-0x*.log > processed-profile.txt
```

Then share the relevant section:

```
V8 profile processed output (statistical profiling, 10s sample):

[JavaScript]:
   ticks  total  nonlib   name
   3842   38.4%   45.2%  LazyCompile: *processOrder /app/services/order.js:45
   1923   19.2%   22.6%  LazyCompile: *validateSchema /app/middleware/validate.js:12
    812    8.1%    9.6%  LazyCompile: *serializeResponse /app/utils/serialize.js:78

processOrder is 38% of all JS execution.
validateSchema runs on every request and takes 19%.
The schema validation uses ajv but recompiles the schema on every call.

Target: reduce overall CPU usage by 50% to handle 2x throughput.
```

The AI will spot the schema recompilation immediately:

```javascript
// Before: schema compiled on every request
function validateSchema(schema, data) {
  const validate = ajv.compile(schema);  // expensive!
  return validate(data);
}

// After: compile once, reuse
const compiledSchemas = new Map();

function validateSchema(schema, data) {
  const key = JSON.stringify(schema);
  if (!compiledSchemas.has(key)) {
    compiledSchemas.set(key, ajv.compile(schema));
  }
  return compiledSchemas.get(key)(data);
}
```

### Heap Snapshot Analysis

You cannot share a heap snapshot file directly. Describe the findings:

```
Chrome DevTools heap snapshot for the API server after running for 2 hours:

Total heap: 1.4GB (expected: ~200MB)
Top retained objects:
  - Array (connected to RequestLogger): 380MB
    - Contains 2.1M entries of {timestamp, url, headers, body}
  - Map (connected to SessionCache): 290MB
    - 450K entries, oldest from 9 hours ago
  - Buffer objects: 210MB
    - Linked to file upload temp storage, not being cleaned up

The RequestLogger array grows without bound.
SessionCache entries never expire.
Temp upload buffers are not released after processing.
```

---

## Python Profiling

### cProfile Results

```
Running cProfile on generate_report(account_id=5432):

         2847563 function calls in 12.453 seconds

   Ordered by: cumulative time

   ncalls  tottime  percall  cumtime  percall filename:lineno(function)
        1    0.001    0.001   12.453   12.453 reports.py:23(generate_report)
      847    0.012    0.000   11.234    0.013 db.py:89(execute_query)
      847    9.876    0.012    9.876    0.012 {method 'execute' of 'cursor'}
        1    0.234    0.234    0.891    0.891 reports.py:67(aggregate_results)
   845000    0.543    0.000    0.543    0.000 reports.py:112(format_currency)
        1    0.087    0.087    0.328    0.328 reports.py:95(build_pdf)

847 database queries taking 11.2s out of 12.4s total.
format_currency is called 845K times (once per data cell).
Target: under 2 seconds.
```

The AI sees two problems: 847 queries (N+1 again) and 845K function calls for formatting. It will suggest batching the queries and vectorizing the formatting.

### memory_profiler Output

```
Line #    Mem usage    Increment  Occurrences   Line Contents
    23    45.2 MiB     45.2 MiB           1   def process_csv(filepath):
    24    45.2 MiB      0.0 MiB           1       data = []
    25   512.8 MiB    467.6 MiB           1       with open(filepath) as f:
    26   512.8 MiB      0.0 MiB           1           reader = csv.DictReader(f)
    27  1024.3 MiB    511.5 MiB     2000000           for row in reader:
    28  1024.3 MiB      0.0 MiB     2000000               data.append(transform(row))
    29  1024.3 MiB      0.0 MiB           1       return aggregate(data)

Loading 2M rows into memory. Peak: 1GB. Machine has 2GB available.
Target: process without exceeding 200MB.
```

The AI will suggest streaming/chunked processing instead of loading everything into a list.

---

## JVM Profiling

### Thread Dumps

```
Thread dump taken during high CPU (95%) on the order-service pod:

"http-nio-8080-exec-12" RUNNABLE
    at com.app.service.OrderService.calculateTax(OrderService.java:234)
    at com.app.service.OrderService.processOrder(OrderService.java:189)
    at com.app.controller.OrderController.create(OrderController.java:45)

"http-nio-8080-exec-14" BLOCKED
    waiting for lock on com.app.service.InventoryService.checkStock
    held by "http-nio-8080-exec-12"

23 of 25 executor threads are BLOCKED waiting on InventoryService.checkStock.
The method uses a synchronized block around a database call.
```

The AI will identify the lock contention and suggest removing synchronization in favor of database-level locking or optimistic concurrency.

### GC Logs

```
GC log summary over 5 minutes:

[GC (Allocation Failure) 1.2G->890M(2G), 0.345 secs]  -- 48 occurrences
[Full GC (Ergonomics) 1.8G->1.1G(2G), 4.567 secs]     -- 3 occurrences

Young gen collections: 48 times, avg 345ms each
Full GC: 3 times, avg 4.5s each (app freezes)
Heap: 2GB max, consistently above 80% usage
Allocation rate: ~500MB/s

The service processes batch imports. Each import creates ~2M short-lived DTOs.
```

---

## Load Testing Interpretation

### Sharing k6 Results

```
k6 load test results for POST /api/orders:

scenarios: {
  ramp: { executor: 'ramping-vus', stages: [
    { duration: '2m', target: 50 },
    { duration: '5m', target: 200 },
    { duration: '2m', target: 0 }
  ]}
}

Results:
  http_req_duration:
    avg=234ms   min=12ms   med=89ms   max=18234ms   p(90)=456ms   p(95)=2341ms   p(99)=12453ms
  http_req_failed:  4.2% (842 of 20041)
  iterations:       20041

The p95 is 2.3s but median is 89ms. Huge variance.
Errors start appearing at ~120 concurrent users.
All errors are 503 (connection pool exhausted).

Database connection pool: max 20 connections.
Server: 2 pods, 2 CPU cores each.
```

The AI will identify the connection pool as the bottleneck and suggest pool sizing, connection timeouts, and possibly query optimization to reduce connection hold time.

---

## Common AI-Suggested Optimizations

These are the patterns the AI reaches for most often -- because they are the most common actual bottlenecks:

| Problem | AI Suggestion | Typical Impact |
|---------|--------------|----------------|
| Sequential scan on large table | Add composite index | 100-1000x |
| N+1 queries | JOIN or batched query | 10-100x |
| No caching on repeated reads | Add Redis/in-memory cache | 5-50x |
| Loading full dataset into memory | Pagination, streaming, cursors | Memory 80%+ reduction |
| Synchronous blocking in async code | Convert to non-blocking | 2-10x throughput |
| Re-computing on every request | Memoize or precompute | 2-20x |
| Large bundle shipped to client | Code splitting, lazy loading | 30-60% size reduction |
| Missing connection pool limits | Pool sizing + timeouts | Eliminates crashes |

---

## When AI Gets Performance Wrong

### Premature Optimization

You say "make this faster" without measurements. The AI rewrites clean, readable code into an unreadable optimized version that saves 2ms on something that runs once per day.

**Fix:** Always include current measurement and target. If a function takes 5ms and runs once per request, optimizing it is not worth the complexity.

### Micro-Benchmark Traps

The AI suggests replacing `Array.map` with a for-loop because "it's faster in benchmarks." The difference is 0.003ms per call. Your actual bottleneck is a 2-second database query.

**Fix:** Share the full profile, not just one function. The AI needs to see proportions.

### Caching Everything

The AI defaults to "add a cache" for any performance problem. But caching introduces invalidation complexity, stale data bugs, and memory pressure.

**Fix:** Ask explicitly: "What are the tradeoffs of caching here? What invalidation strategy would we need?"

### Assuming Index Solves Everything

Sometimes the AI suggests an index on a column that already has one. Or suggests an index that would hurt write performance on a write-heavy table.

**Fix:** Share existing indexes along with your EXPLAIN output:

```
Existing indexes on the orders table:
  - PRIMARY KEY (id)
  - idx_orders_user_id (user_id)
  - idx_orders_status (status)
  - idx_orders_created (created_at)
```

---

## Real Scenario: API Endpoint 2.5s to 120ms

Here is a complete walkthrough of an actual optimization session.

**Step 1: Measure and share.**

```
GET /api/dashboard/summary takes 2.5s.

I ran EXPLAIN ANALYZE on the three queries this endpoint makes:

Query 1 (total revenue, 1.8s):
  SELECT SUM(total) FROM orders WHERE merchant_id = $1 AND status = 'completed'
  Seq Scan on orders (rows=12000000, filtered to 45000)

Query 2 (order count by status, 0.5s):
  SELECT status, COUNT(*) FROM orders WHERE merchant_id = $1 GROUP BY status
  Seq Scan on orders

Query 3 (recent orders, 0.2s):
  SELECT * FROM orders WHERE merchant_id = $1 ORDER BY created_at DESC LIMIT 10
  Index Scan using idx_orders_created (already fast)

Query 3 is fine. Queries 1 and 2 are doing full table scans on 12M rows.
There's an index on merchant_id but the planner isn't using it for
queries 1 and 2 because merchant_id has low cardinality (only 50 merchants).
```

**Step 2: AI suggests composite indexes and query restructuring.**

```sql
-- Composite index that covers both query 1 and query 2
CREATE INDEX idx_orders_merchant_status ON orders (merchant_id, status)
  INCLUDE (total);

-- The INCLUDE (total) means query 1 becomes an index-only scan
-- No need to visit the table at all
```

**Step 3: AI also spots an opportunity to combine queries.**

```sql
-- One query instead of two
SELECT
  status,
  COUNT(*) as count,
  SUM(CASE WHEN status = 'completed' THEN total ELSE 0 END) as revenue
FROM orders
WHERE merchant_id = $1
GROUP BY status;
```

**Step 4: Measure again.**

```
After adding the composite index and combining queries:
- Single query: 45ms (down from 2.3s combined)
- Query 3 (unchanged): 75ms
- Total endpoint: 120ms

2.5s -> 120ms. 20x improvement.
```

---

## What AI Cannot Do

Be clear about the boundaries:

- **Cannot profile your running application.** It needs you to run `perf`, `cProfile`, Chrome DevTools, `EXPLAIN ANALYZE`, or whatever tool fits your stack.
- **Cannot observe production behavior.** It does not know your traffic patterns, data distribution, or actual usage unless you tell it.
- **Cannot benchmark its suggestions.** After it suggests an optimization, you must measure whether it actually helped.
- **Cannot know your data distribution.** An index that is perfect for uniform data may be useless if 90% of rows have the same value. Share cardinality information.
- **Cannot account for infrastructure.** It does not know your connection pool settings, pod memory limits, CDN configuration, or network topology unless you provide them.

The best performance sessions look like a conversation:

```
You:  "Here's the profile. The hot path is X."
AI:   "Add this index and restructure the query like this."
You:  "Done. It went from 3.2s to 400ms. Still above 200ms target."
AI:   "The remaining time is likely serialization. Add a projection
       to select only the columns the frontend needs."
You:  "Down to 150ms. Good enough."
```

Each round: you measure, AI suggests, you measure again. That feedback loop is what produces real results.

## Next Steps

- [Prompt Patterns](../03-prompts/prompt-patterns.md) -- Template #12 covers the performance investigation pattern
- [Token Optimization](../05-advanced/token-optimization.md) -- Keep profiling data sharing efficient
