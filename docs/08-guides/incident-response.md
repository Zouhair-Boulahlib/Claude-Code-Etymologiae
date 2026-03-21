# Incident Response with AI

> At 2 AM when the pager fires, you do not need an AI that writes elegant code. You need one that reads fast, explains clearly, and does not make things worse.

## The Incident Workflow

Production incidents follow a predictable structure. AI can help at every stage -- but its role changes depending on the phase.

```
TRIAGE       -> What is broken? How bad is it? Who is affected?
DIAGNOSE     -> Why is it broken? What changed?
FIX          -> What is the smallest change that stops the bleeding?
VERIFY       -> Is it actually fixed? Are there side effects?
POSTMORTEM   -> What happened, why, and how do we prevent it?
```

The critical rule: **AI assists, you decide.** During an incident, every change to production must be a deliberate human decision. The AI reads logs, suggests hypotheses, and drafts fixes. You evaluate, approve, and deploy.

---

## CLAUDE.md for Incident Mode

Add an incident-mode section to your project's CLAUDE.md that constrains Claude Code's behavior under pressure:

```markdown
## Incident Mode

When I say "incident mode" or "production issue":
- DO NOT modify any files unless I explicitly say "make this change"
- Default to read-only analysis: read code, explain behavior, trace call paths
- Keep responses short and actionable -- no essays
- Always state your confidence level: "high confidence", "likely", "uncertain"
- If you suggest a fix, also state what could go wrong if the fix is incorrect
- Prioritize speed of diagnosis over completeness of explanation
```

This is critical. Under pressure, you do not want the AI eagerly editing files. You want it thinking out loud while you decide what to do.

---

## Phase 1: Triage

The first minutes of an incident are about understanding scope. AI excels at parsing noisy signals quickly.

### Parsing Error Logs

```
Incident mode. Here's the last 50 lines from our API error log:

[2026-03-21 02:14:33] ERROR pool.acquire() timeout after 30000ms
[2026-03-21 02:14:33] ERROR pool.acquire() timeout after 30000ms
[2026-03-21 02:14:34] ERROR pool.acquire() timeout after 30000ms
[2026-03-21 02:14:35] ERROR Request failed: POST /api/orders - 503
[2026-03-21 02:14:35] ERROR pool.acquire() timeout after 30000ms
[2026-03-21 02:14:36] WARN  Health check failed: database unreachable
[2026-03-21 02:14:36] ERROR Request failed: GET /api/users/me - 503
...

What pattern do you see? What is the most likely root cause?
```

The AI will identify the pattern immediately -- database connection pool exhaustion -- without you needing to read through every line.

### Assessing Impact

```
Given that pool.acquire timeouts started at 02:14 and all POST /api/orders
and GET /api/users endpoints are returning 503:

1. What user-facing functionality is affected?
2. Are background jobs (in src/jobs/) also affected?
3. Is the database itself down, or just the connection pool?

Read src/db/pool.ts and src/db/health-check.ts to answer.
```

Structured questions get structured answers. During an incident, you do not have time for open-ended exploration.

---

## Phase 2: Diagnose

Once you know what is broken, the AI helps figure out why.

### Sharing Monitoring Data

You cannot paste a Grafana dashboard into a terminal. But you can describe what you see:

```
Metrics from the last hour:
- DB connection pool: 50/50 connections in use (max pool size), 200+ waiting
- DB query latency p99: 12 seconds (normally 50ms)
- Active DB transactions: 50 (normally 5-10)
- CPU on DB server: 15% (not the bottleneck)
- Recent deploys: v2.4.7 deployed at 01:30, ~45 min before incident started

Read the migration that shipped in v2.4.7. Check for long-running
transactions or missing indexes.
```

Concrete numbers. Specific time ranges. A clear hypothesis to investigate. The AI now has enough to be useful.

### Tracing Code Paths

```
The connection pool exhaustion started after v2.4.7 deployed.
The only code change in that version is src/services/order-service.ts.

Read the diff between v2.4.6 and v2.4.7 for that file. Look for:
- New database queries that might not release connections
- Missing await on async database calls
- Transactions that are opened but not committed/rolled back in error paths
```

This is where AI shines. It can read a diff, trace every code path, and spot the missing `finally { connection.release() }` that a tired human would miss at 2 AM.

---

## Phase 3: Fix

### The Minimal Fix Rule

During an incident, the correct fix is the smallest possible change that stops the impact. Not the best fix. Not the clean fix. The smallest one.

```
You identified that the new bulk order endpoint opens a transaction but
doesn't release the connection if the inventory check throws.

Give me the MINIMAL fix -- the fewest lines changed that prevent connection
leaks. Do not refactor anything else. Do not improve error handling elsewhere.
Show me the exact change.
```

### Safe Fix Patterns

**Feature flags** -- the safest "fix" is often turning off the broken feature:

```
The bulk order endpoint is leaking connections. What's the fastest way to
disable just that endpoint without affecting other order operations?

Options:
1. Feature flag (if we have one)
2. Return 503 from the route handler
3. Revert the v2.4.7 deployment

Which is safest? Show me the code for the fastest option.
```

**Rollbacks** -- when the fix is unclear, rollback is almost always correct:

```
Show me the git commands to revert to v2.4.6. I need:
1. The revert command
2. Confirmation that v2.4.6 doesn't include the order-service change
3. Any database migrations in v2.4.7 that would need to be rolled back
```

### What NOT to Do During an Incident

Do **not** ask the AI to:

- Refactor the connection pooling system
- Add comprehensive error handling across all services
- Rewrite the database layer to prevent future issues
- Improve the monitoring setup

These are all good ideas. They are all postmortem tasks. During the incident, they will introduce new bugs under pressure and delay resolution. One change, one problem, one fix.

---

## Phase 4: Verify

After applying the fix, verify it worked. AI helps you think about what to check.

```
I applied the connection release fix and deployed. What should I monitor
to confirm the fix is working?

Current state:
- Pool connections in use: dropping from 50 to 30 (good sign)
- 503 errors: still occurring but less frequent
- Deploy completed 2 minutes ago
```

The AI will remind you to check things you might forget at 2 AM: background job queues, cache invalidation, webhook retries that stacked up during the outage.

---

## Phase 5: Postmortem

This is where AI earns its keep. Writing postmortems is tedious but valuable. AI does it in seconds.

```
The incident is resolved. Write a postmortem document with these sections:

**Timeline:**
- 01:30 - v2.4.7 deployed with bulk order endpoint
- 02:14 - Connection pool exhaustion detected
- 02:18 - On-call engineer paged
- 02:25 - Root cause identified (missing connection release in error path)
- 02:31 - Fix deployed
- 02:35 - Connection pool recovered, 503 errors stopped

**Impact:**
- 21 minutes of degraded API service
- All order and user endpoints returned 503
- ~340 failed API requests based on error logs

**Root cause:**
Missing connection.release() in the catch block of
OrderService.processBulkOrder()

Generate the full postmortem with: summary, timeline, root cause analysis,
impact assessment, action items, and lessons learned.
```

### Runbook Generation

After fixing an issue, use AI to document the fix for next time:

```
Based on this incident, write a runbook for "Database Connection Pool
Exhaustion" that covers:

1. How to detect it (symptoms, metrics, alerts)
2. Immediate mitigation steps
3. Common root causes to check
4. How to safely restart the connection pool without dropping requests
5. Escalation contacts

Format it for our wiki. Keep it skimmable -- someone will read this
at 2 AM under stress.
```

This turns tribal knowledge into documented procedures. One incident produces a runbook that saves the next engineer hours of panic.

---

## Real Scenario: Connection Pool Exhaustion at 2 AM

Here is a complete incident response transcript showing how to use Claude Code effectively. Each prompt is deliberate and constrained.

**02:18 -- Page received.**

```
Incident mode. Production API returning 503s. Error logs show:
"pool.acquire() timeout after 30000ms" repeated every second.
Started approximately 02:14. What should I check first?
```

**02:20 -- AI suggests checking pool metrics, recent deploys, and active transactions.**

```
Pool: 50/50 in use, 200 waiting. Last deploy: v2.4.7 at 01:30.
Read the changes in v2.4.7 -- specifically any files in src/services/
or src/db/. Look for connection handling issues.
```

**02:23 -- AI identifies the missing connection release.**

```
Show me the exact fix. Only the lines that need to change in
src/services/order-service.ts. Nothing else.
```

**02:25 -- AI provides a 3-line fix: add `finally { connection.release() }` to the try block.**

```
Make this change to src/services/order-service.ts.
```

**02:27 -- Fix applied. Deploy triggered.**

```
Fix deployed. Pool usage dropping. What else should I verify before
going back to sleep?
```

**02:35 -- All clear. Connection pool back to normal. 503s stopped.**

Total AI cost for this incident: approximately $1.50. Time to resolution: 17 minutes. Without AI, reading the diff, tracing the code path, and writing the fix would take 30-45 minutes -- assuming you find the right file quickly at 2 AM.

---

## Communication Templates

During an incident, you also need to communicate with stakeholders. AI drafts these instantly.

### Initial Status Update

```
Write a status update for our status page:

Service: Acme API
Impact: Orders and user authentication endpoints returning errors
Start time: 02:14 UTC
Status: Investigating
Audience: External customers, non-technical
```

AI output (edit as needed):

```
[Investigating] API Service Degradation

We are currently investigating an issue affecting our API service.
Some requests to the orders and authentication endpoints may fail or
experience delays. Our engineering team is actively working on a resolution.

We will provide an update within 30 minutes.

Started: March 21, 2026 02:14 UTC
```

### Resolution Update

```
Write the resolution update. Fixed at 02:35 UTC. Root cause was a
connection handling bug in a recent deployment. No data was lost.
Keep it non-technical.
```

### Internal Stakeholder Notification

```
Write a Slack message for the #engineering channel summarizing the incident.
Include: what happened, impact, fix, and who was involved. Technical
audience. Brief.
```

---

## Incident Response Checklist

Keep this in your team's runbook:

- [ ] Declare "incident mode" in your Claude Code session
- [ ] Share concrete data: error logs, metrics, timestamps
- [ ] Ask structured questions -- one at a time
- [ ] Constrain the AI to read-only analysis until you decide to act
- [ ] Apply the minimal fix, not the ideal fix
- [ ] Verify the fix with specific metrics
- [ ] Draft the postmortem while the incident is fresh
- [ ] Generate a runbook if this is a new failure mode
- [ ] Send status updates to stakeholders throughout

The AI is your fastest reader, your calmest analyst, and your most patient writer at 2 AM. Let it do those jobs. Keep the decision-making for yourself.
