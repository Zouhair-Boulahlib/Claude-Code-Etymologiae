# Scaling Build Processes with AI

> From solo project to team-scale -- architecture patterns that survive growth.

Scaling AI-assisted development is not about doing the same thing louder. What works for one developer breaks at five. What works at five collapses at twenty. Each stage demands different conventions, tooling, and discipline.

## 1. The Scaling Continuum

### Solo Developer

Everything lives in your head. One CLAUDE.md, one set of conventions, one person who knows the project. AI assistance is frictionless because context is implicit.

### Small Team (2--5 developers)

The first cracks appear. Developer A writes `camelCase` services, developer B writes `kebab-case` services. The AI follows whoever committed last.

What breaks first:
- **CLAUDE.md conflicts.** Two developers add contradictory instructions in the same week.
- **Inconsistent conventions.** AI output varies because conventions are implicit, not documented.
- **Permission drift.** One developer allows `Bash(npm publish)` locally; another denies it.

Fix: commit CLAUDE.md and `.claude/settings.json` to version control. Treat them like linter config -- team-level, not personal.

### Medium Team (5--15 developers)

Build times slow down. CI pipelines become bottlenecks. AI generates code that passes local tests but breaks integration.

What breaks:
- **Build pipeline contention.** CI queue grows, feedback loops slow to 20+ minutes.
- **Module boundaries blur.** AI imports across package boundaries because nobody told it not to.
- **Code review throughput.** More AI-generated PRs than humans can review carefully.

Fix: modularize, parallelize builds, add automated quality gates.

### Large Team / Enterprise (15+ developers)

Convention enforcement matters more than individual productivity. A single inconsistent pattern replicated across 30 developers becomes a codebase-wide problem.

What breaks:
- **Governance.** No clear policy on what AI can and cannot do.
- **Knowledge silos.** Teams customize CLAUDE.md independently, creating incompatible setups.
- **Accumulated tech debt.** Unreviewed AI code compounds over months.

Fix: platform teams, shared skills, inner-source model, architectural decision records.

## 2. Progressive Modularization with AI

### Signs It's Time to Split

- Build times exceed 5 minutes for a single-line change.
- Two teams routinely edit the same files.
- AI-generated imports cross logical boundaries (billing code importing auth internals).
- Test failures cascade -- changing one feature breaks tests in another.

### Using AI to Identify Module Boundaries

```
Analyze the import graph in src/. Find clusters of files that import
each other heavily but have few imports to the rest of the codebase.
List each cluster with its files and the cross-cluster dependencies.
```

For targeted analysis:

```
List all files in src/ that import from both src/features/payments/
and src/features/auth/. These are the coupling points I need to resolve
before splitting these into separate packages.
```

### CLAUDE.md Per Module

Once you split, each module gets its own CLAUDE.md:

```
project/
  CLAUDE.md                  # Global rules, monorepo structure
  packages/
    payments/
      CLAUDE.md              # "Stripe SDK. No direct DB access. Use @acme/db-client."
    auth/
      CLAUDE.md              # "JWT-based. Redis session store. Never import from payments."
    shared/
      CLAUDE.md              # "No framework dependencies. Pure TypeScript utilities."
```

Claude Code merges these hierarchically -- module-level adds specifics, root sets global rules.

### Extracting a Module with AI

```
Extract all payment-related logic from src/features/ into packages/payments/.
Requirements:
- Create a public API in packages/payments/src/index.ts
- Do NOT change the public interface -- existing callers must work unchanged
- Move tests alongside their source files
- Update all imports in the rest of the codebase
- List any circular dependencies that prevent clean extraction
```

The key instruction: "do NOT change the public interface." Without it, the AI refactors the interface to be cleaner -- which breaks every caller.

## 3. Build Pipeline Architecture

### Parallelizing CI

A serial pipeline that runs lint, typecheck, unit tests, integration tests, and build in sequence will crush velocity at 10+ developers. Use AI to restructure:

```
Our CI pipeline runs sequentially and takes 12 minutes:
1. Install dependencies (2 min)  2. Lint (1 min)
3. Type check (2 min)  4. Unit tests (4 min)  5. Integration tests (3 min)

Rewrite the GitHub Actions workflow to run lint, type check, and unit
tests in parallel after install. Integration tests run after unit tests
pass. Target: under 6 minutes.
```

The pattern: `install` job caches `node_modules`, then `lint`, `typecheck`, and `unit-tests` run as parallel jobs using `needs: install`. Integration tests use `needs: unit-tests`. Build time drops from 12 minutes to the length of the longest parallel path.

### Test Splitting and Caching

```
Our test suite has 847 files and takes 14 minutes on one runner.
Split into 4 shards using Jest's --shard flag with a GitHub Actions
matrix strategy. Balance shards by test duration, not file count.
```

```
Analyze our CI pipeline and identify cacheable artifacts. We use pnpm,
TypeScript, and Prisma. Suggest a caching strategy that covers
dependencies, TypeScript build info, Prisma client generation, and
test fixtures.
```

### Automated PR Review at Scale

When your team generates 20+ PRs per day, use Claude Code in CI for a first pass:

```yaml
ai-review:
  runs-on: ubuntu-latest
  if: github.event_name == 'pull_request'
  steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 0
    - name: AI Review
      run: |
        git diff origin/main...HEAD | claude -p \
          "Review this diff. Flag: security issues, missing error handling,
           broken patterns from CLAUDE.md, missing tests for new logic.
           Skip style issues -- the linter handles those.
           Format: bullet list, file:line for each issue."
```

This does not replace human review. It catches mechanical issues so humans focus on architecture and business logic.

### Monorepo Build Tools with AI

AI helps configure tools like Turborepo, Nx, and Bazel:

**Turborepo:**
```
We have a pnpm monorepo with packages/api, packages/web, packages/shared,
and packages/workers. Create a turbo.json that builds shared first,
runs tests per-package in parallel, caches build and test outputs,
and defines a deploy pipeline that builds, tests, then deploys in order.
```

**Gradle multi-module:**
```
Our Gradle project has 12 modules. Build takes 9 minutes.
Analyze settings.gradle.kts and the dependency graph between modules.
Suggest: which modules can build in parallel, which are on the critical
path, and whether any dependencies are unnecessary.
```

**Bazel:**
```
Generate BUILD files for the Java packages under src/main/java/com/acme/.
Use the existing BUILD file in src/main/java/com/acme/core/ as a
template. Infer dependencies from import statements.
```

## 4. Architectural Decision Records (ADRs) with AI

### Why ADRs Matter More at Scale

At three developers, decisions happen in a Slack thread. At thirty, nobody remembers why the team chose PostgreSQL over DynamoDB. ADRs are the institutional memory. With AI scaling your team's output, decisions happen faster -- and are forgotten faster.

### Drafting ADRs with AI

```
Write an ADR for migrating internal service communication from REST to
gRPC. Context:
- 14 internal services, average 200ms latency per REST call
- Some endpoints chain 3-4 service calls, compounding latency
- Team has zero gRPC experience
- Must maintain REST for external/partner APIs

Format: Title, Status (proposed), Context, Decision, Consequences
(positive and negative), Alternatives Considered.
```

### ADR Template

Store at `docs/adr/template.md` and reference in CLAUDE.md. Sections: Title, Status (proposed/accepted/deprecated/superseded), Date, Authors, Context (with metrics and constraints), Decision, Consequences (positive, negative, neutral), and Alternatives Considered (table format with pros, cons, and rejection reason).

Then in CLAUDE.md:

```markdown
## ADRs
- Template: docs/adr/template.md
- When proposing architectural changes, draft an ADR first
- Number sequentially: ADR-001, ADR-002, etc.
```

### Maintaining ADR Consistency Across Teams

Add an AI check to your PR workflow:

```
This PR adds a new ADR. Review it against our template in docs/adr/template.md.
Check: all sections present, alternatives considered (at least 2), consequences
include both positive and negative, context includes measurable motivation.
```

## 5. Anti-Patterns That Kill Scale

### The "Works on My Machine" CLAUDE.md

Developer A adds:

```markdown
## My Preferences
- Use tabs for indentation
- I like functional style, avoid classes
- Always use console.log for debugging
```

Personal config masquerading as project convention. When developer B picks up the project, the AI produces code in A's style.

**Fix:** personal preferences go in `~/.claude/CLAUDE.md` (user-level, never committed). Project CLAUDE.md documents team-agreed conventions only.

### Over-Abstraction at Scale

AI loves abstractions. Ask it to build a service, and it produces a `BaseService<T>`, a `ServiceFactory`, a `ServiceRegistry`, and three layers of middleware. Multiply by 30 developers.

**Fix:** prevent it in CLAUDE.md:

```markdown
## Anti-patterns
- Do not create abstract base classes unless 3+ concrete implementations exist
- Do not create factory patterns for classes instantiated in only one place
- Prefer duplication over premature abstraction
```

### Configuration Drift Between Environments

AI fixes a bug in staging by changing an environment variable. The fix never reaches production config. Three weeks later, the bug resurfaces in production.

**Fix:** store non-secret config in version-controlled files and audit:

```
Review config/staging.yaml and config/production.yaml. List every key
that exists in one but not the other, and every key where the value
differs. Flag differences that look unintentional.
```

### The "Golden Path" Trap

A platform team mandates one exact AI workflow, one CLAUDE.md template, one set of allowed commands for every team. Frontend, infrastructure, and data pipeline teams all fight the constraints.

**Fix:** shared foundation (root CLAUDE.md, shared permissions), but let teams extend per module. A golden path is a starting point, not a cage.

### Technical Debt from Unreviewed AI Code

AI generates code fast. Review is slow. Teams merge with cursory review because the AI "probably got it right." Six months later: patterns nobody understands, error handling nobody verified, edge cases nobody tested.

**Fix:** review standards do not change because the author is an AI. They should be stricter -- AI code is confident, compiles cleanly, and passes the tests it wrote for itself. That makes bugs harder to spot.

## 6. Team Scaling Patterns

### Code Ownership and CLAUDE.md Scoping

```
project/
  CLAUDE.md                        # Global: architecture, shared conventions
  packages/
    payments/
      CLAUDE.md                    # Owned by payments team
      CODEOWNERS                   # @acme/payments-team
    auth/
      CLAUDE.md                    # Owned by identity team
      CODEOWNERS                   # @acme/identity-team
```

Each team controls AI instructions for their domain. Root sets boundaries; modules set domain rules.

### Platform Team Patterns

A platform team provides shared infrastructure for AI-assisted development:

- **Shared custom skills.** Reusable slash commands like `/deploy-staging` or `/run-migration`.
- **Shared hooks.** Pre-commit hooks that validate AI output (e.g., naming conventions).
- **MCP servers.** Internal tools exposed to Claude Code -- database queries, deploy status, feature flags.

### Inner-Source Model

When contributing to another team's code with AI:

```
I'm making a change to packages/auth/ owned by the identity team.
Read packages/auth/CLAUDE.md and follow their conventions exactly.
The change: add a `lastLoginAt` timestamp to the user session.
Match their existing patterns in packages/auth/src/services/.
```

The critical instruction: "follow their conventions exactly." Without it, the AI follows whatever conventions it saw most recently.

### Quality Gates for AI-Generated Code

Add automated CI checks: coverage threshold (fail below 80%), cyclomatic complexity limit (fail above 15 per function via ESLint), and import boundary validation (fail if cross-package imports bypass public APIs). These gates run on every PR and enforce the same standard regardless of whether a human or AI wrote the code.

## 7. Real Scenario: From 3 Devs to 30

### Starting Point: 3 Developers

One repo, one CLAUDE.md, one CI pipeline. Everyone knows the codebase. Build time: 3 minutes. No problems yet.

### At 5 Developers

AI output becomes inconsistent. One developer's code uses `async/await`, another's uses `.then()` chains.

- [ ] Expand CLAUDE.md with explicit code standards and canonical examples
- [ ] Commit `.claude/settings.json` with team-agreed permissions
- [ ] Add a linter rule for the most common inconsistency

### At 10 Developers

Build times hit 8 minutes. Two teams form. AI-generated PRs stack up in the review queue.

- [ ] Split into 3--4 packages with clear boundaries and per-module CLAUDE.md
- [ ] Parallelize CI: lint, typecheck, and unit tests run simultaneously
- [ ] Add test sharding across 4 runners
- [ ] Set up automated AI PR review as a first pass
- [ ] Establish CODEOWNERS per package

### At 20 Developers

Four teams. Conventions diverge. The auth team's error-handling pattern contradicts the billing team's.

- [ ] Create a platform team for shared tooling and CI
- [ ] Write ADRs for major decisions (retrospectively if needed)
- [ ] Build shared custom skills for common workflows
- [ ] Add quality gates: coverage thresholds, complexity limits, import boundaries
- [ ] Audit CLAUDE.md files across packages for contradictions

### At 30 Developers

Review capacity is the bottleneck, not development speed.

- [ ] Formalize AI code review standards (what to check, what to trust)
- [ ] Run periodic codebase audits: "Find patterns that contradict CLAUDE.md"
- [ ] Add environment configuration drift detection to CI
- [ ] Track metrics: build time, review turnaround, test flake rate
- [ ] Revisit build tools -- consider Turborepo, Nx, or Bazel if package graph exceeds 10 nodes

## Scaling Checklist

| Stage | Key Actions |
|-------|------------|
| 1--3 devs | CLAUDE.md with basics, .claudeignore, shared settings.json |
| 4--5 devs | Explicit conventions, canonical code examples, linter rules |
| 6--10 devs | Modularize, parallelize CI, test sharding, automated AI review |
| 11--20 devs | Platform team, ADRs, shared skills, quality gates, CODEOWNERS |
| 21--30 devs | Governance policies, codebase audits, metrics tracking, build tool evaluation |

## Next Steps

- [Project Setup](project-setup.md) -- Structure projects for AI-friendly development
- [Monorepo Strategies](../08-guides/monorepo-strategies.md) -- Managing AI context across packages
- [CI/CD Integration](../05-advanced/ci-cd.md) -- Running Claude Code in pipelines
- [Team Conventions](../06-team/conventions.md) -- Standardizing AI workflows across teams
- [Common Mistakes](../07-anti-patterns/common-mistakes.md) -- Anti-patterns to avoid
