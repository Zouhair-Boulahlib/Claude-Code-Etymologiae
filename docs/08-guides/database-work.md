# AI-Assisted Database Work

> Migrations, schema design, and query optimization -- with guardrails that prevent you from dropping production data at 2am.

## The Cardinal Rule

**Never let AI run migrations directly.** Generate them, review them, then run them yourself. A bad migration is not a bad deployment you can roll back -- it is data loss, corrupted foreign keys, or a table lock that takes your app down for an hour. Treat every AI-generated migration as a rough draft.

## Writing Migrations With AI

AI knows the syntax for every framework. Your job is to verify it does the right thing.

### Rails

```
"Generate a Rails migration to add a `cancelled_at` timestamp to orders.
Nullable, no default, include a partial index. Generate both up and down
methods -- do not use `change`."
```

```ruby
class AddCancelledAtToOrders < ActiveRecord::Migration[7.1]
  def up
    add_column :orders, :cancelled_at, :datetime, null: true
    add_index :orders, :cancelled_at, where: "cancelled_at IS NOT NULL",
              name: "index_orders_on_cancelled_at_partial"
  end

  def down
    remove_index :orders, name: "index_orders_on_cancelled_at_partial"
    remove_column :orders, :cancelled_at
  end
end
```

The prompt asks for `up` and `down` instead of `change`. The `change` method cannot always auto-reverse complex migrations. Be explicit.

### Prisma

```
"Add a ProjectMember join model between User and Project with a role enum
(OWNER, EDITOR, VIEWER). Unique constraint on [userId, projectId]."
```

After generating, run `npx prisma migrate dev --create-only` to create the migration file without applying it. Read the SQL. Then apply.

### Flyway / Liquibase

Same principle: tell the AI the exact format (Flyway versioned SQL, Liquibase YAML/XML), specify columns with types and constraints, and always request a rollback block. The framework syntax is boilerplate -- the AI gets it right. The schema decisions are where you need to pay attention.

## Schema Design Prompts

AI iterates on table structures quickly, but it tends to over-normalize or under-normalize. Anchor it with explicit constraints.

```
"Design a PostgreSQL schema for a multi-tenant SaaS billing system.
Constraints:
- Tenants are called 'organizations'
- Each org has multiple users, each user belongs to exactly one org
- Subscriptions are per-org, not per-user
- Track monthly invoices with line items
- All tables: created_at, updated_at, UUID primary keys
- Include indexes for: 'all invoices for an org' and 'active subscriptions
  expiring in the next 7 days'
Output CREATE TABLE statements in dependency order."
```

Without the constraints section, AI will make assumptions -- subscriptions per-user, integer IDs, missing indexes. Before accepting any AI-generated schema, check: Are foreign keys correct? Are cascade deletes appropriate? Did it forget unique constraints? (It often does.)

## Query Optimization

Copy `EXPLAIN ANALYZE` output and paste it. Give context about table size.

```
"Here is the EXPLAIN ANALYZE for a slow query. Table has 1.85M rows:

Seq Scan on orders  (cost=0.00..45892.00 rows=234 width=312)
                    (actual time=892.341..1204.553 rows=28 loops=1)
  Filter: ((user_id = 'abc-123') AND (created_at > ...))
  Rows Removed by Filter: 1850432
Execution Time: 1204.601 ms

Suggest how to optimize."
```

The AI identifies the sequential scan and recommends a composite index:

```sql
CREATE INDEX idx_orders_user_created ON orders (user_id, created_at DESC);
```

Always verify by running `EXPLAIN ANALYZE` again after adding the index. The AI reasons from the plan you provided -- it cannot see your actual database.

## N+1 Query Detection

AI spots N+1 patterns effectively when shown the code.

```
"Look at getOrdersForUser in src/services/orderService.ts. It loads
orders then loops to load products. Is this N+1? Fix it with Prisma."
```

The classic N+1 and its fix:

```typescript
// BAD: 1 query for orders + N queries for products
const orders = await prisma.order.findMany({ where: { userId } });
for (const order of orders) {
  order.products = await prisma.product.findMany({
    where: { orderId: order.id },
  });
}

// GOOD: 1 query with eager loading
const orders = await prisma.order.findMany({
  where: { userId },
  include: { products: true },
});
```

## Indexing Strategies

Describe your query patterns and let AI suggest indexes.

```
"Here are our 5 most common queries:
1. SELECT * FROM users WHERE email = ? (login)
2. SELECT * FROM orders WHERE user_id = ? AND status = 'active' ORDER BY created_at DESC
3. SELECT * FROM products WHERE category_id = ? AND price BETWEEN ? AND ?
4. SELECT COUNT(*) FROM events WHERE org_id = ? AND created_at > ?
5. SELECT * FROM sessions WHERE token = ? AND expires_at > NOW()

Suggest indexes. Explain single-column vs composite for each."
```

AI will suggest composite indexes matching filter + sort order. Review carefully -- partial indexes with `NOW()` in the predicate are not always useful, and the AI cannot see your data distribution or cardinality. This is exactly the kind of thing you catch in review.

## Safe Patterns

**Always generate reversible migrations.** Include this in every prompt:

```
"Generate both up and down migrations. The down must fully reverse
the up without data loss."
```

**Always backup before schema changes:**

```bash
pg_dump -Fc mydb > backup_before_migration_$(date +%Y%m%d_%H%M%S).dump
```

**Tell the AI your database.** Without it, you get MySQL syntax in a Postgres project:

```
"We use PostgreSQL 15. Generate a migration to add a JSONB column
called metadata to events. Include a GIN index. No MySQL syntax."
```

If your project always uses the same database, put it in CLAUDE.md once.

## Real Scenario: The Silent Data Loss

You ask: "We renamed the `phone` field to `phone_number` on users. Generate a migration."

The AI generates:

```sql
ALTER TABLE users DROP COLUMN phone;
ALTER TABLE users ADD COLUMN phone_number VARCHAR(20);
```

This runs. Tests pass because factories populate `phone_number`. But every real user just lost their phone number. The column was dropped before the new one was created.

What the migration should be:

```sql
ALTER TABLE users RENAME COLUMN phone TO phone_number;
```

Or, if a type change is also needed:

```sql
ALTER TABLE users ADD COLUMN phone_number VARCHAR(20);
UPDATE users SET phone_number = phone;
ALTER TABLE users DROP COLUMN phone;
```

AI will generate the destructive version if you do not say "preserve data." Put it in CLAUDE.md so you never have to remember.

## CLAUDE.md Directives for Database Work

```markdown
# Database rules

## Migrations
- NEVER use DROP TABLE or DROP COLUMN without first migrating data
- Always generate both up and down migrations
- Column renames must use RENAME, not DROP + ADD
- NOT NULL columns must have a DEFAULT or a backfill step
- Always remind me to backup before running migrations

## Queries
- Never use SELECT * in production code -- list columns explicitly
- Always use parameterized queries -- never string interpolation
- Use include/eager loading -- no N+1 loops
- Add LIMIT to any query that could return unbounded results

## Schema changes
- All tables must have id, created_at, and updated_at
- Use UUIDs for primary keys
- Foreign keys must specify ON DELETE behavior explicitly
- Add indexes for any new query pattern in the same PR
```

These directives apply to every conversation. When AI generates a migration that drops a column, these rules kick in and it will add the data migration step -- or at least flag the conflict.

## When AI Gets It Wrong

AI struggles with things it cannot see: your actual data volume, column cardinality, lock implications of ALTER TABLE on large production tables, and migration ordering when multiple developers touch the same schema.

Provide context: "This table has 50M rows and we deploy with zero downtime." That single sentence changes the strategy entirely -- the AI will suggest adding nullable columns first, backfilling, then adding constraints, instead of a single ALTER TABLE that locks the table for minutes.

## Next Steps

- [Monorepo Strategies](monorepo-strategies.md) -- Managing AI context across multiple packages
- [Testing](../04-architecture/testing.md) -- Testing AI-generated database code
- [Common Mistakes](../07-anti-patterns/common-mistakes.md) -- Broader patterns of AI misuse
