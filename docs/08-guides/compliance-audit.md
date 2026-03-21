# Compliance and Audit Trails

> Using AI in regulated industries is not a question of whether you can -- it is a question of how you document it. Finance, healthcare, and government have hard requirements for traceability, review, and data handling. This guide covers practical compliance patterns for AI-assisted development.

## The Compliance Challenge

AI-generated code introduces a question that traditional development never had to answer: who is the author? When a regulator asks "who wrote this payment processing logic and what was their review process?", the answer cannot be "an AI wrote it and I glanced at it." You need a documented, auditable chain from requirement to implementation to review to deployment.

The good news: the tools for this already exist. Git, code review systems, and CI pipelines can all capture the information you need. You just need to use them deliberately.

## Audit Trail Requirements

Regulators care about four things:

1. **Who** wrote or modified the code
2. **What** changed and why
3. **When** the change was made
4. **Who reviewed and approved it**

For AI-assisted development, add a fifth: **how was AI involved in this change?**

### Git as Your Audit Log

Every commit is an audit record. Make them count.

**Bad -- opaque commit:**
```
fix stuff
```

**Good -- auditable commit:**
```
fix: prevent duplicate charge on payment retry

When a payment times out and the client retries, the server was creating
a new charge instead of checking for an existing pending charge with the
same idempotency key. Added a lookup-before-create pattern using the
idempotency_key column on the charges table.

Addresses: JIRA-4521
Reviewed-by: sarah@company.com
Co-Authored-By: Claude <noreply@anthropic.com>
```

This commit tells an auditor everything: what changed, why, the ticket reference, who reviewed it, and that AI was involved.

## Git Blame and AI Attribution

### The Co-Authored-By Convention

When AI contributes to code, mark it in the commit:

```
Co-Authored-By: Claude <noreply@anthropic.com>
```

This is a Git convention -- GitHub and GitLab render it in their UIs. When someone runs `git blame` on a file, the commit message shows AI involvement.

### Why Attribution Matters

Without attribution, your git history looks like a developer wrote everything solo. Six months later, when a bug surfaces in the payment module, the team assumes the original developer fully understood every line. If AI generated portions of that code, the attribution changes how the team approaches debugging and review.

### Automating Attribution

Add a Git hook to enforce the trailer when needed. In `.claude/settings.json`:

```json
{
  "hooks": {
    "postCommit": {
      "command": "git log -1 --format='%B' | grep -q 'Co-Authored-By' || echo 'WARNING: Commit may need AI co-author attribution'"
    }
  }
}
```

Or enforce it in CI:

```yaml
# .github/workflows/compliance.yml
- name: Check AI attribution
  run: |
    commits=$(git log origin/main..HEAD --format='%H')
    for sha in $commits; do
      # If the branch was created with Claude Code, verify attribution
      if git log -1 --format='%B' $sha | grep -qi 'claude\|ai-assisted'; then
        git log -1 --format='%B' $sha | grep -q 'Co-Authored-By' || {
          echo "Commit $sha mentions AI but lacks Co-Authored-By trailer"
          exit 1
        }
      fi
    done
```

## Code Review Requirements

In regulated environments, AI output is not a shortcut past review -- it is an additional reason for review.

### Human Review Sign-Off

Every AI-assisted change must have a human reviewer who:

1. **Read the code** -- not skimmed, read
2. **Understood the logic** -- could explain it without referencing the AI prompt
3. **Verified correctness** -- tested or confirmed the behavior matches requirements
4. **Signed off explicitly** -- approved the PR with their name attached

GitHub's branch protection rules enforce this:

```yaml
# Branch protection settings (configure in GitHub UI)
# Required reviews: 2 (for regulated code paths)
# Dismiss stale reviews: yes
# Require review from code owners: yes
# Require signed commits: yes (for audit trail)
```

### Review Checklist for Regulated Code

```markdown
## Compliance Review -- AI-Assisted Change

### Attribution
- [ ] Co-Authored-By trailer present in all AI-assisted commits
- [ ] Ticket/requirement reference in commit message
- [ ] Change description explains the "why", not just the "what"

### Correctness
- [ ] Reviewer can explain the logic without referencing the AI prompt
- [ ] Edge cases are handled (not just the happy path)
- [ ] Error handling follows the project's established patterns
- [ ] No hallucinated APIs or non-existent library methods

### Compliance-Specific
- [ ] No PII/PHI in code comments, logs, or error messages
- [ ] Encryption standards met for data at rest and in transit
- [ ] Access control checks present on all data endpoints
- [ ] Audit logging added for state-changing operations
- [ ] Data retention policies reflected in code (TTLs, cleanup jobs)
```

## Data Handling: PII, PHI, and Sensitive Data

### The Rule

**Never include real PII, PHI, or production data in AI prompts.** AI prompts may be logged, transmitted to API servers, and retained. Pasting a patient record, credit card number, or customer email into a Claude Code session is a compliance violation in most regulatory frameworks.

### What Counts as Sensitive Data

| Framework | Sensitive Data Examples |
|---|---|
| HIPAA | Patient names, diagnoses, treatment records, insurance IDs |
| PCI-DSS | Card numbers, CVVs, cardholder names, transaction amounts with identifiers |
| SOC2 | Customer data, access credentials, internal system details |
| GDPR | Any data that identifies a natural person |

### Safe Practices

**Instead of pasting real data, describe the shape:**

```
# BAD -- real patient data in prompt
"Fix the bug with this patient record:
{name: 'John Smith', ssn: '123-45-6789', diagnosis: 'Type 2 Diabetes'}"

# GOOD -- synthetic data with the same structure
"Fix the bug. Here is a sample record with the same shape as production:
{name: 'Test User', ssn: '000-00-0000', diagnosis: 'TEST_CONDITION'}"
```

**Use redacted logs:**

```
# BAD
"Here is the error log from production: [paste with customer emails]"

# GOOD
"Here is the error log with PII redacted:
[2024-01-15 10:23:45] ERROR PaymentService: Charge failed for
customer_id=REDACTED, amount=REDACTED, error=card_declined"
```

### .claudeignore for Compliance

Your `.claudeignore` must exclude files that contain or could contain sensitive data:

```
# .claudeignore -- compliance configuration

# Environment and secrets
.env
.env.*
*.pem
*.key
*.p12
credentials.json
service-account*.json

# Data files that may contain PII/PHI
data/
exports/
reports/
backups/
*.csv
*.xlsx

# Configuration with connection strings or credentials
config/production.yml
config/staging.yml
docker-compose.prod.yml

# Audit logs (may contain user actions with PII)
logs/
*.log

# Database seeds with real data
seeds/production/
fixtures/production/

# Compliance documentation with internal details
compliance/internal/
security/penetration-tests/
```

## Regulatory Framework Considerations

### SOC2

SOC2 cares about controls around data access and change management.

**What SOC2 auditors look for:**
- Evidence that code changes are reviewed before deployment
- Access controls on production systems
- Logging of who did what and when
- Incident response procedures

**AI-specific controls:**
- Document that AI tools are part of your development process (update your System Description)
- Ensure AI-generated code goes through the same review pipeline as human-written code
- Verify that AI tools do not have access to production data or credentials
- Log AI tool usage as part of your change management records

### HIPAA

HIPAA requires protections for Protected Health Information (PHI).

**AI-specific controls:**
- AI tools must not process PHI -- enforce via `.claudeignore` and team policy
- If Claude Code runs in your development environment, ensure no PHI is accessible in the file system
- Code that handles PHI must have human-written, human-reviewed access control logic
- Audit every AI-assisted change to PHI-handling code paths

### PCI-DSS

PCI-DSS governs payment card data handling.

**AI-specific controls:**
- AI tools must never see card numbers, CVVs, or cardholder data
- Payment processing code changes require documented review by a qualified developer
- AI-generated payment code must be tested against PCI-DSS requirements (encryption, tokenization, access control)
- Maintain a log of which code in the cardholder data environment was AI-assisted

## Documentation Requirements

### Architecture Decision Records (ADRs)

For significant AI-assisted changes, create an ADR:

```markdown
# ADR-027: Refactor Payment Retry Logic

## Status
Accepted

## Context
The existing retry logic for failed payments uses a fixed 3-retry approach
with no backoff. This causes duplicate charges when the payment processor
is slow but not down.

## Decision
Implement idempotency-key-based retry with exponential backoff. AI (Claude
Code) was used to generate the initial implementation, which was then
reviewed and modified by the payments team.

## AI Involvement
- Initial implementation generated by Claude Code
- Human modifications: added idempotency key validation, adjusted backoff
  intervals to match processor SLA, added circuit breaker threshold
- Reviewed by: @sarah (payments lead), @mike (security)
- All commits tagged with Co-Authored-By

## Consequences
- Duplicate charges eliminated for timeout scenarios
- Retry behavior is now configurable per payment processor
- Added dependency on Redis for idempotency key storage
```

### Change Logs for Regulated Modules

Maintain a change log for compliance-critical modules:

```markdown
# Payment Module Change Log

| Date | Change | Author | AI-Assisted | Reviewer | Ticket |
|---|---|---|---|---|---|
| 2024-01-15 | Added idempotency key retry | Dev A | Yes | Sarah, Mike | PAY-421 |
| 2024-01-10 | Fixed decimal rounding in EUR | Dev B | No | Sarah | PAY-418 |
| 2024-01-08 | Added PSD2 SCA flow | Dev A | Yes | Mike, Sarah | PAY-400 |
```

## Testing Requirements for AI-Generated Code

Regulated industries often require higher test coverage for critical paths. AI-generated code in those paths should exceed the baseline.

### Coverage Thresholds

```json
// jest.config.js or vitest.config.ts -- per-directory thresholds
{
  "coverageThreshold": {
    "global": {
      "branches": 80,
      "functions": 80,
      "lines": 80
    },
    "src/payments/": {
      "branches": 95,
      "functions": 95,
      "lines": 95
    },
    "src/auth/": {
      "branches": 95,
      "functions": 95,
      "lines": 95
    }
  }
}
```

### Mutation Testing

For critical AI-generated code, consider mutation testing -- it verifies that your tests actually catch bugs, not just exercise code paths:

```bash
# Using Stryker for JavaScript/TypeScript
npx stryker run --mutate 'src/payments/**/*.ts'
```

If AI-generated code has high line coverage but low mutation score, the tests are weak. The code looks tested but is not actually verified.

## Policy Template: AI-Assisted Development Policy

Use this as a starting point for your team's formal policy.

```markdown
# AI-Assisted Development Policy
Version: 1.0
Effective: [DATE]
Owner: [ENGINEERING LEAD]

## Scope
This policy applies to all software development activities where AI tools
(including but not limited to Claude Code, GitHub Copilot, and ChatGPT)
are used to generate, modify, or review code.

## Approved Tools
- Claude Code (CLI) -- approved for code generation and review
- [List other approved tools]

## Prohibited Uses
- Processing PII, PHI, or payment card data through AI tools
- Using AI to generate security-critical cryptographic implementations
- Using AI output without human review in regulated code paths
- Sharing proprietary algorithms or trade secrets in AI prompts

## Required Practices
1. All AI-assisted commits must include a Co-Authored-By trailer
2. All AI-assisted changes to regulated modules require two human reviewers
3. Developers must read and understand all AI-generated code before committing
4. AI-generated code in critical paths must meet elevated test coverage (95%)
5. Architecture decisions influenced by AI must be documented in ADRs

## Data Handling
- Never paste production data into AI prompts
- Use synthetic or redacted data when describing bugs or data shapes
- Maintain .claudeignore to exclude sensitive files from AI context
- Regularly audit .claudeignore as new sensitive files are added

## Audit Trail
- Git commit history serves as the primary audit log
- Co-Authored-By trailers identify AI involvement
- PR reviews document human sign-off
- ADRs document AI involvement in architectural decisions

## Review Frequency
This policy is reviewed quarterly by [TEAM/ROLE].
```

## Real Scenario: Refactoring a Payment Module Under PCI-DSS

Your team needs to refactor the payment processing module to support a new payment provider. The module is in PCI-DSS scope. Here is how to use AI safely.

**Step 1 -- Set up guardrails:**

```
# .claudeignore additions for this work
config/payment-providers/*.yml    # contains API keys in some envs
src/payments/test-fixtures/real/  # contains real transaction samples
```

**Step 2 -- Explore without exposing data:**

```
"Read src/payments/processor.ts and explain the current payment flow.
Do not read any config files or test fixtures -- they may contain
sensitive data. Just the source code."
```

**Step 3 -- Generate the refactored code:**

```
"Refactor the PaymentProcessor class to support multiple providers
via a strategy pattern. The interface should support: charge, refund,
and getStatus. Each provider implements the interface. Keep the existing
Stripe implementation and add a skeleton for the new Adyen provider.

Requirements:
- All card data must be tokenized before reaching our code
- Never log card numbers, even partially
- All API calls must use TLS
- Add idempotency keys to all charge operations
- Include error handling that does not leak provider details to the client"
```

**Step 4 -- Review with compliance focus:**

```
"Review the refactored payment module against PCI-DSS requirements:
1. Is card data ever stored or logged?
2. Are all external API calls over TLS?
3. Is error handling safe (no card details in error messages)?
4. Are idempotency keys properly generated and stored?
5. Is the provider abstraction complete (no Stripe-specific code leaking
   through the interface)?"
```

**Step 5 -- Commit with full attribution:**

```bash
git commit -m "$(cat <<'EOF'
refactor: extract payment provider strategy pattern

Refactored PaymentProcessor to support multiple payment providers via
a strategy interface. Added Adyen provider skeleton alongside existing
Stripe implementation.

Key changes:
- PaymentProvider interface (charge, refund, getStatus)
- StripeProvider and AdyenProvider implementations
- Idempotency key generation for all charge operations
- Sanitized error responses (no provider details exposed to clients)

Addresses: PAY-523
PCI-DSS reviewed: no card data storage, TLS enforced, errors sanitized

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

**Step 6 -- Two-reviewer sign-off:**

The PR requires two approvals from developers with PCI-DSS training. Both reviewers confirm they read the code, understood the logic, and verified the compliance checklist.

**Step 7 -- Update the change log and ADR.**

This process is more work than a typical PR. That is the point. Regulated code demands more rigor, and AI assistance does not reduce that requirement -- it just changes who does the initial drafting.

## CLAUDE.md Directives for Regulated Projects

```markdown
# Compliance requirements

## General
- Never read files matching: *.pem, *.key, .env*, credentials.json
- Never include real customer data, PII, or PHI in code comments or logs
- All error messages must be generic -- no internal details, no stack traces to clients

## Payment code (src/payments/)
- All card data must be tokenized -- never store raw card numbers
- All external API calls must use HTTPS -- no HTTP fallbacks
- Include idempotency keys on all state-changing operations
- Log transaction IDs but never amounts with customer identifiers

## Commit requirements
- Always include a ticket reference (PAY-XXX, AUTH-XXX)
- Always include Co-Authored-By if AI assisted
- Commit messages must explain WHY, not just WHAT
```

## Next Steps

- [Security Considerations](../06-team/security.md) -- Broader security practices for AI-assisted development
- [Code Review](../02-workflows/code-review.md) -- Review processes that support compliance requirements
- [Database Work](database-work.md) -- Safe migration practices for regulated data stores
