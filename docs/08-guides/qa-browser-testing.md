# Claude in Chrome for QA Teams

> Browser automation as a testing superpower -- when APIs don't exist, Chrome becomes your API.

Most QA work assumes you have an API to test against. But the real world is full of admin panels with no API, third-party dashboards you can only view in a browser, and legacy systems where the UI is the only interface. Claude in Chrome turns the browser into a programmable testing tool -- and JavaScript execution is the feature that makes it fast.

---

## 1. JavaScript Over Interactions: The Speed Multiplier

Every click-based interaction follows an expensive sequence: find element, scroll into view, click, wait for animation, wait for DOM update, verify result. A single click takes 200-500ms. A form with 10 fields takes 2-5 seconds just for inputs.

JavaScript execution via `javascript_tool` skips the entire visual pipeline. A script extracting 200 table rows as JSON runs in ~50ms. No scrolling, no waiting for CSS transitions, no retry logic.

### Decision Table

| Task | Approach | Why |
|------|----------|-----|
| Extract data from a table | JS | `querySelectorAll` returns all rows instantly |
| Fill a form with test data | JS | Set `.value`, dispatch `change` events in one script |
| Click a button that triggers navigation | Click | JS cannot follow the redirect |
| Test a drag-and-drop workflow | Click | Drag events need precise mouse simulation |
| Validate error messages after bad input | Hybrid | JS sets values, click submits, JS reads errors |
| Check if a button is disabled | JS | Read the `disabled` property directly |
| Navigate through a multi-step wizard | Hybrid | JS fills each step, clicks advance to the next |

Rule of thumb: if you are **reading** the DOM or **setting values**, use JS. If you are **triggering navigation** or **native browser features**, use clicks.

### Pattern 1: Bulk Data Validation

```javascript
// Extract all rows from an order table as structured JSON
const rows = Array.from(document.querySelectorAll('table#orders tbody tr'));
const data = rows.map(row => {
  const cells = row.querySelectorAll('td');
  return {
    orderId: cells[0]?.textContent.trim(),
    customer: cells[1]?.textContent.trim(),
    amount: cells[2]?.textContent.trim(),
    status: cells[3]?.textContent.trim(),
    date: cells[4]?.textContent.trim()
  };
});
JSON.stringify(data, null, 2);
```

For React apps where data lives in component state:

```javascript
// Extract data directly from React's fiber tree
const el = document.querySelector('[data-testid="order-table"]');
const fiberKey = Object.keys(el).find(k => k.startsWith('__reactFiber'));
let current = el[fiberKey];
while (current && !current.memoizedProps?.orders) { current = current.return; }
JSON.stringify(current?.memoizedProps?.orders || 'Not found');
```

### Pattern 2: Form Validation Testing

```javascript
const emailInput = document.querySelector('input[name="email"]');
const testCases = [
  { value: '', expectedError: 'Email is required' },
  { value: 'notanemail', expectedError: 'Invalid email format' },
  { value: 'valid@example.com', expectedError: null }
];

const results = testCases.map(tc => {
  // Use native setter -- React overrides .value, so direct assignment
  // does not trigger synthetic events
  const nativeSetter = Object.getOwnPropertyDescriptor(
    HTMLInputElement.prototype, 'value').set;
  nativeSetter.call(emailInput, tc.value);
  emailInput.dispatchEvent(new Event('input', { bubbles: true }));
  emailInput.dispatchEvent(new Event('blur', { bubbles: true }));

  const errorEl = emailInput.closest('.form-group')?.querySelector('.error-message');
  const actualError = errorEl?.textContent.trim() || null;
  return { input: tc.value, expected: tc.expectedError, actual: actualError,
           pass: tc.expectedError === actualError };
});
JSON.stringify(results, null, 2);
```

### Pattern 3: State Machine Validation

```javascript
const currentStatus = document.querySelector('[data-testid="order-status"]')?.textContent.trim();
const actions = Array.from(document.querySelectorAll('[data-testid^="action-"]'));
const actionStates = actions.map(btn => ({
  action: btn.dataset.testid.replace('action-', ''),
  enabled: !btn.disabled && !btn.classList.contains('disabled'),
  visible: btn.offsetParent !== null
}));
JSON.stringify({ currentStatus, enabledActions: actionStates.filter(a => a.enabled) }, null, 2);
```

Run this for each status in the lifecycle and you get a full transition matrix without clicking a single button.

---

## 2. Validating UI Against Database: The Testcontainers Pattern

### The Problem

"The UI shows 142 orders, but the database has 147. Which 5 are missing?" Unit tests mock the database. Integration tests check happy paths. Nobody manually counts rows.

**Step 1: Extract UI data via Chrome JS** (use the table extraction pattern above).

**Step 2: Query database via Docker exec:**

```bash
docker exec postgres-container psql -U app_user -d app_db -t -A -F '|' -c \
  "SELECT id, name, email, role, TO_CHAR(created_at, 'YYYY-MM-DD') FROM users ORDER BY id;"
```

Flags: `-t` (tuples only), `-A` (unaligned), `-F '|'` (pipe delimiter). Clean, parseable output.

**Step 3: Ask Claude to compare both datasets** and format mismatches as a table showing field name, UI value, DB value, and match status.

### Docker Exec Comparison Patterns

```bash
# User count
docker exec postgres-container psql -U app -d mydb -t -c \
  "SELECT COUNT(*) FROM users WHERE active = true;"

# Financial totals
docker exec postgres-container psql -U app -d mydb -t -c \
  "SELECT TO_CHAR(SUM(amount), 'FM$999,999,999.00') FROM payments WHERE status = 'completed';"

# Latest records
docker exec postgres-container psql -U app -d mydb -t -A -F '|' -c \
  "SELECT id, customer_name, total, status FROM orders ORDER BY created_at DESC LIMIT 5;"
```

### Testcontainers for Reproducible QA

Spin up a database with known seed data, run the app against it, validate the UI shows exactly what you seeded.

**Java:**

```java
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.containers.GenericContainer;

public class UIValidationTest {
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16")
        .withDatabaseName("qa_db").withUsername("qa_user").withPassword("qa_pass")
        .withInitScript("seed-data.sql");

    static GenericContainer<?> app = new GenericContainer<>("myapp:latest")
        .withExposedPorts(8080).dependsOn(postgres)
        .withEnv("DATABASE_URL", postgres.getJdbcUrl());

    @Test
    void uiMatchesSeedData() throws Exception {
        postgres.start();
        app.start();
        String appUrl = "http://localhost:" + app.getMappedPort(8080);
        // Navigate Claude in Chrome to appUrl, extract table data via JS
        // Compare against seed-data.sql expected values
        Connection conn = DriverManager.getConnection(postgres.getJdbcUrl(), "qa_user", "qa_pass");
        ResultSet rs = conn.createStatement().executeQuery("SELECT COUNT(*) FROM users");
        rs.next();
        assertEquals(50, rs.getInt(1));  // seed-data.sql inserts 50 users
    }
}
```

**Python:**

```python
from testcontainers.postgres import PostgresContainer
from testcontainers.core.container import DockerContainer
import psycopg2

def test_ui_matches_database():
    with PostgresContainer("postgres:16") as postgres:
        conn = psycopg2.connect(postgres.get_connection_url())
        cursor = conn.cursor()
        with open("seed-data.sql") as f:
            cursor.execute(f.read())
        conn.commit()

        with DockerContainer("myapp:latest") \
            .with_exposed_ports(8080) \
            .with_env("DATABASE_URL", postgres.get_connection_url()) as app:
            app_url = f"http://localhost:{app.get_exposed_port(8080)}"
            # Navigate Claude in Chrome to app_url, extract data, compare
            cursor.execute("SELECT COUNT(*) FROM orders")
            assert cursor.fetchone()[0] == 100  # seed-data.sql inserts 100 orders
```

---

## 3. Playwright CLI vs Claude in Chrome: Use Cases and Caveats

### When Playwright Wins

Playwright is for **repeatable, automated, cross-browser testing** in CI.

```bash
npx playwright test                              # Run all tests
npx playwright test --headed --debug             # Visible browser + debugger
npx playwright test tests/orders.spec.ts         # Specific file
npx playwright codegen http://localhost:3000      # Record interactions as code
```

Playwright excels at: regression suites (every PR), cross-browser (Chromium/Firefox/WebKit), visual regression (`toHaveScreenshot()`), CI integration, performance testing, large parameterized test matrices, parallel execution.

```typescript
import { test, expect } from '@playwright/test';

test('order table shows correct data', async ({ page }) => {
  await page.goto('/admin/orders');
  await page.waitForSelector('table#orders tbody tr');
  const rows = await page.$$eval('table#orders tbody tr', trs =>
    trs.map(tr => ({
      orderId: tr.querySelectorAll('td')[0]?.textContent?.trim(),
      status: tr.querySelectorAll('td')[3]?.textContent?.trim()
    }))
  );
  expect(rows.length).toBeGreaterThan(0);
});
```

### When Claude in Chrome Wins

Claude in Chrome is for **one-off investigation, exploratory testing, and cross-system verification**.

- **Exploratory testing** -- "Something looks wrong on the dashboard. Check the numbers."
- **One-off validations** -- "We migrated 50K users. Spot-check 10 profiles." Never run again.
- **Internal tools with no test infra** -- No test suite, no test IDs, team is gone.
- **Cross-system verification** -- "Does the Stripe total match our DB?"
- **Non-technical QA** -- Natural language prompts, no code required.

### The Hybrid Approach

Playwright for CI regression. Chrome for exploratory + edge cases. When Chrome finds a bug, write a Playwright test to lock it down.

### Five Caveats of Claude in Chrome

**1. No persistence.** Sessions are ephemeral. Document bugs immediately, then write Playwright tests.

**2. Auth state management.** Inherits the browser session. Safe on staging. Risky on production -- never run destructive operations against prod.

**3. Timing and async content.** SPAs load data asynchronously. Extract too early, get an empty table.

```javascript
// Wait for content before extracting
function waitForData(selector, timeout = 10000) {
  return new Promise((resolve, reject) => {
    const start = Date.now();
    const check = () => {
      const els = document.querySelectorAll(selector);
      if (els.length > 0) resolve(els.length);
      else if (Date.now() - start > timeout) reject(new Error('Timeout'));
      else setTimeout(check, 200);
    };
    check();
  });
}
await waitForData('table#orders tbody tr');
```

**4. Selector fragility.** Prefer `data-testid` over CSS classes. Fall back to `aria-label` before `nth-child`.

```javascript
// Fragile
document.querySelector('.MuiTable-root .MuiTableBody-root tr:nth-child(3) td.amount');
// Stable
document.querySelector('[data-testid="order-row-3"] [data-testid="order-amount"]');
```

**5. Alert/dialog blocking.** Override before testing:

```javascript
window.alert = (msg) => console.log('ALERT:', msg);
window.confirm = (msg) => { console.log('CONFIRM:', msg); return true; };
window.prompt = (msg, def) => { console.log('PROMPT:', msg); return def || ''; };
window.onbeforeunload = null;
```

---

## 4. When No API or Connector Exists (The Killer Feature)

### The Fallback Hierarchy

```
1. REST/GraphQL API    -- Best. Fast, structured, scriptable.
2. CLI tool            -- Good. docker exec, psql, aws cli, stripe cli.
3. MCP server          -- Good. Database MCP, Slack MCP, custom servers.
4. Claude in Chrome    -- Last resort. But when it's all you have, it's everything.
```

### Scenario 1: Validating Stripe Dashboard Against Your DB

Extract payment rows from the Stripe dashboard via `javascript_tool`, query your database via `docker exec psql`, ask Claude to reconcile and identify the specific payments causing a discrepancy.

```javascript
// On Stripe dashboard -- extract payment rows
const paymentRows = Array.from(document.querySelectorAll('table tbody tr'));
const payments = paymentRows.map(row => {
  const cells = row.querySelectorAll('td');
  return { id: cells[0]?.textContent.trim(), amount: cells[1]?.textContent.trim(),
           status: cells[2]?.textContent.trim(), date: cells[3]?.textContent.trim() };
});
JSON.stringify({ payments, count: payments.length }, null, 2);
```

### Scenario 2: Checking Analytics Dashboards

GA and Mixpanel have APIs, but they are rate-limited and require OAuth. Sometimes you just need to check a number. For apps using shadow DOM:

```javascript
const deepQuery = (root, selector) => {
  const result = root.querySelector(selector);
  if (result) return result;
  for (const el of root.querySelectorAll('*')) {
    if (el.shadowRoot) { const f = deepQuery(el.shadowRoot, selector); if (f) return f; }
  }
  return null;
};
JSON.stringify({ metric: deepQuery(document, '.metrics-summary')?.textContent.trim() });
```

### Scenario 3: Legacy CRM Data Extraction

No API. No export. No docs. Just HTML from 2012.

```javascript
const rows = Array.from(document.querySelectorAll('tr.contact-row, tr.dataRow, tr[id^="contact_"]'));
const getText = (row, selectors) => {
  for (const sel of selectors) {
    const el = row.querySelector(sel);
    if (el?.textContent.trim()) return el.textContent.trim();
  }
  return null;
};
const contacts = rows.map(row => ({
  name: getText(row, ['.contact-name', 'td:nth-child(1) a', 'td.name']),
  email: getText(row, ['.contact-email', 'td:nth-child(2)', 'td.email']),
  phone: getText(row, ['.contact-phone', 'td:nth-child(3)', 'td.phone'])
})).filter(c => c.name);
JSON.stringify({ count: contacts.length, contacts }, null, 2);
```

### The QA Validation Workflow

Every Chrome-based QA session follows the same pattern:

| Step | Tool | Action |
|------|------|--------|
| Navigate | `navigate` | Go to the target page |
| Wait | `javascript_tool` | Poll for async content |
| Override | `javascript_tool` | Disable alerts/confirms |
| Extract | `javascript_tool` | `querySelectorAll` + JSON |
| Compare | Claude reasoning | Match against DB or expected values |
| Report | Claude output | Formatted mismatch table |

---

## 5. CLAUDE.md for QA Sessions

```markdown
## QA Mode

When I say "QA mode" or "browser testing":

### Browser interaction rules
- Prefer JavaScript execution over clicks for data extraction
- Always extract data as JSON -- never describe what you see, give me raw data
- Use querySelectorAll with data-testid attributes when available
- Fall back to semantic selectors (aria-label) before CSS classes
- Wait for async content before extracting

### Safety rules
- NEVER click delete, remove, or destructive action buttons
- NEVER submit forms unless I explicitly ask
- Read-only by default -- extract and report, do not modify

### Dialog handling
- Override window.alert, window.confirm, and window.prompt at page start
- Log overridden messages to console instead of blocking

### Data extraction format
- Return JSON from all JS extraction
- Include record counts alongside the data
- For tables: column headers as keys, rows as objects
- For dashboards: metric labels and values as key-value pairs

### Comparison rules
- Format mismatches as markdown table: field, UI value, DB value, match
- Always include summary: total records, matches, mismatches

### Environment
- Staging URL: https://staging.example.com
- Database container: postgres-staging
- Database name: app_staging
- Database user: qa_readonly
```

---

## 6. Quick Reference: QA Prompt Templates

**Data extraction:**

```
QA mode. Navigate to [URL]. Extract all rows from the [table name] table
as JSON. Include all visible columns. Return the count and the data.
```

**UI vs database comparison:**

```
QA mode. I need to verify the UI matches the database.
Step 1: Navigate to [URL] and extract all [entity] records as JSON.
Step 2: I will provide the database query results.
Step 3: Compare both datasets and show me a mismatch report.
Start with Step 1.
```

**Form validation check:**

```
QA mode. Navigate to [URL]. Test the [form name] form validation:
1. Submit with all fields empty -- capture all error messages
2. Enter invalid email "[bad value]" -- capture the email error
3. Fill all fields with valid data -- confirm no errors appear
Use JavaScript to set values and trigger validation. Return results as JSON.
```

**Exploratory testing:**

```
QA mode. Navigate to [URL]. I suspect there's a bug with [description].
1. Check the current state of [element/section]
2. Extract the relevant data as JSON
3. Tell me if anything looks wrong: missing data, wrong formats,
   unexpected values, zero-width elements, overflow
```

**Cross-system reconciliation:**

```
QA mode. I need to reconcile data between [System A] and [System B].
System A ([URL]): Navigate and extract [data description] as JSON.
System B: I will provide the data from [source].
After extracting from System A, compare and show discrepancies.
```

**Post-migration spot check:**

```
QA mode. We just migrated [entity] data. Spot-check these records:
IDs: [id1, id2, id3, id4, id5]
For each: navigate to detail page at [URL pattern], extract all fields as JSON.
I will compare against the migration source.
```

---

## 7. Summary Table

| Tool | Best For | Speed | Repeatability | Setup | Cross-System |
|------|----------|-------|---------------|-------|--------------|
| **Playwright** | Regression suites, CI, cross-browser | Fast (parallel) | High | Medium | No |
| **Chrome JS** | Data extraction, validation, bulk checks | Very fast (~50ms) | None (ephemeral) | Zero | Yes |
| **Chrome Clicks** | Navigation, uploads, drag-and-drop | Slow (200-500ms/step) | None (ephemeral) | Zero | Yes |
| **Docker exec** | Database queries, data verification | Fast | High (scriptable) | Low | No |
| **Testcontainers** | Reproducible QA with seed data | Medium (startup) | High | Medium | No |

| Scenario | Recommended Approach |
|----------|---------------------|
| Regression testing in CI | Playwright |
| "Does the UI match the DB?" one-off check | Chrome JS + Docker exec |
| Exploratory testing of a new feature | Chrome JS + Clicks |
| Cross-system reconciliation (Stripe vs DB) | Chrome JS + Docker exec |
| Reproducible QA across environments | Testcontainers + Chrome JS |
| Visual regression detection | Playwright with `toHaveScreenshot()` |
| Legacy system data extraction | Chrome JS (the only option) |
| Load testing / performance benchmarks | Playwright or k6, not Chrome |
| Non-technical team member doing QA | Chrome (natural language prompts) |
| Bug found in exploratory session | Chrome to find it, Playwright to lock it down |

---

## Next Steps

- [MCP Servers](../05-advanced/mcp-servers.md) -- Setting up the Claude in Chrome MCP server and other connectors
- [Testing](../04-architecture/testing.md) -- How AI-assisted testing fits into your broader test strategy
- [Database Work](database-work.md) -- Query patterns for the database side of UI validation
