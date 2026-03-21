# Code Review with AI Assistance

> Use AI as a second pair of eyes that never gets tired, never skims, and never feels awkward pointing out issues.

## Why AI-Assisted Review Works

Human reviewers are good at judging design decisions, architectural fit, and business logic correctness. They are bad at catching off-by-one errors in line 247, noticing a missing null check in one of twelve similar functions, or spotting that a new SQL query runs inside a loop.

AI is the opposite. It doesn't understand your business, but it will catch the mechanical issues every time. Use both.

## Review Your Own Code Before Pushing

The highest-leverage habit: review your own diff with AI before anyone else sees it.

```
"Review the current git diff. Look for bugs, security issues, missing
error handling, and anything that doesn't match the patterns in the
rest of the codebase. Be critical."
```

This catches the obvious stuff before it wastes a human reviewer's time. The phrase "be critical" matters -- without it, the AI tends toward politeness.

### Pre-Push Checklist Prompt

```
"Review my staged changes and check:
1. Are there any unhandled error cases?
2. Did I leave any debug code, console.logs, or TODOs?
3. Are there any obvious performance issues (N+1 queries, unnecessary
   re-renders, missing indexes)?
4. Does the code match the patterns used elsewhere in this codebase?
5. Are there any security concerns (unsanitized input, exposed secrets,
   missing auth checks)?"
```

This is worth running before every push. It takes seconds and regularly catches things.

## Surface-Level vs. Deep Review

There is a big difference between asking the AI to glance at code and asking it to think hard. You control the depth.

### Surface-Level Review

```
"Scan src/api/orders.ts for obvious issues -- typos, unused imports,
inconsistent naming."
```

Fast, cheap, catches low-hanging fruit. Good for a quick sanity check.

### Deep Review

```
"Do a thorough review of src/api/orders.ts. For each function:
1. Trace the data flow from input to output
2. Identify every place where an exception could be thrown and check
   that it's handled
3. Check that database queries are parameterized (no SQL injection)
4. Verify that authorization is checked before data access
5. Look for race conditions if any state is shared

Explain each issue you find with the specific line and what could go wrong."
```

This takes longer and uses more tokens, but it catches real bugs. Use it for critical paths -- payment processing, authentication, data mutations.

## Reviewing Pull Requests

### Quick PR Review

```
"Review the diff in this PR: gh pr diff 142. Summarize what it does in
2-3 sentences, then list any concerns."
```

Good for getting oriented on a PR before diving into the code yourself.

### Targeted PR Review

Focus the AI on what matters most for a given change:

```
"Review PR #142. This adds a new payment provider integration.
Focus on:
- Are API keys or secrets handled safely?
- Is the error handling robust enough for a payment flow?
- Are there any cases where a charge could succeed but we fail to
  record it?
- Does the retry logic have a maximum attempt limit?"
```

Domain-specific review questions get domain-relevant answers.

### Reviewing for Breaking Changes

```
"Review the diff from PR #87. Does this change any public API contracts?
Check for:
- Changed function signatures
- Renamed or removed exports
- Modified response shapes
- Changed error types or error messages that callers might depend on
- Database migration that alters existing columns"
```

This is especially useful for library code or shared services where consumers might break silently.

## Security Review

AI is surprisingly good at spotting security issues -- it has seen every vulnerability pattern in its training data.

### General Security Scan

```
"Review src/api/ for security vulnerabilities. Check for:
- SQL injection (raw queries with string interpolation)
- XSS (unsanitized user input rendered in responses)
- CSRF (state-changing operations without token validation)
- Missing authentication or authorization checks
- Sensitive data in logs or error messages
- Hardcoded secrets or credentials
- Path traversal in file operations
- Open redirects"
```

### Auth-Specific Review

```
"Trace the authentication flow from login to authenticated request.
Start at src/api/auth/login.ts and follow the token through middleware
to a protected endpoint. Check for:
- Token validation completeness (expiry, signature, issuer)
- Session fixation vulnerabilities
- Timing attacks on password comparison
- Rate limiting on login attempts
- Secure cookie flags (HttpOnly, Secure, SameSite)"
```

### Dependency Review

```
"Review package.json for known risky patterns:
- Are there dependencies that are wildly out of date?
- Any packages with known vulnerabilities? (check against recent CVEs
  you know about)
- Are there dependencies that seem unnecessary for what this project does?
- Any packages that request excessive permissions?"
```

## Catching Specific Bug Patterns

### N+1 Query Detection

```
"Check src/api/orders.ts for N+1 query problems. Look for any database
call inside a loop, or any place where we fetch a list and then query
related data one record at a time instead of using a join or batch query."
```

### Race Condition Detection

```
"Review src/services/inventory.ts for race conditions. We run multiple
API server instances. Look for any check-then-act patterns where the
state could change between the check and the action, especially around
stock decrement."
```

### Memory Leak Detection

```
"Review src/hooks/useWebSocket.ts for memory leaks. Check that:
- Event listeners are removed on cleanup
- Subscriptions are unsubscribed on unmount
- Timers and intervals are cleared
- WebSocket connections are closed properly"
```

## Reviewing for Patterns and Anti-Patterns

### Pattern Consistency

```
"Compare the error handling in src/api/products.ts with src/api/orders.ts.
Are they following the same pattern? If not, show me the differences and
suggest which approach is more robust."
```

### Anti-Pattern Detection

```
"Review src/services/ for these anti-patterns:
- God objects (classes doing too many things)
- Circular dependencies between modules
- Business logic in controllers instead of services
- Hardcoded configuration that should be environment variables
- Catch blocks that swallow errors silently"
```

### Code Smell Scan

```
"Look at src/services/user.ts and flag any code smells:
- Functions longer than 30 lines
- More than 3 levels of nesting
- Boolean parameters that change function behavior
- Functions with more than 4 parameters
- Duplicated logic that could be extracted"
```

## Structuring Review Feedback

Ask the AI to categorize its findings by severity:

```
"Review the diff and categorize issues as:
- BLOCKER: Must fix before merge (bugs, security issues, data loss risks)
- SHOULD FIX: Important but not urgent (error handling gaps, missing edge cases)
- NIT: Style and preference (naming, formatting, minor improvements)

Only flag real issues. Don't generate feedback for the sake of having feedback."
```

The last sentence matters. Without it, you get a list of 15 "suggestions" where 12 are noise.

## Reviewing AI-Generated Code

When the AI wrote the code, a different AI session (or the same session with a pointed prompt) should review it.

```
"I used AI to generate the following code for user registration.
Review it skeptically -- assume it has bugs. Check:
- Edge cases the generator might have missed
- Assumptions about input format or availability
- Error handling that looks correct but fails under real conditions
- Security issues that a code generator commonly introduces"
```

The word "skeptically" changes the review posture. Without it, the AI tends to confirm that code is correct rather than challenge it.

## The Review Workflow in Practice

A practical daily workflow:

```bash
# Before pushing your branch
claude "Review my staged changes for bugs, security issues, and style problems"

# Before requesting review from a teammate
claude "Review the full diff between main and this branch: git diff main...HEAD"

# When reviewing someone else's PR
claude "Review the diff from PR #203. Summarize the changes, then list concerns
        ordered by severity. Focus on correctness and security, not style."

# After the PR is approved but before merge
claude "One final check on PR #203 -- any issues with the database migration?
        Is it reversible? Could it lock tables in production?"
```

## What AI Review Cannot Replace

AI review catches mechanical issues reliably. It does not replace human judgment on:

- **Architectural decisions** -- "Should this be a microservice or a module?" requires business context
- **Product correctness** -- "Does this match what the user actually needs?" requires domain knowledge
- **Team conventions** -- AI knows general best practices but not your team's specific agreements unless they are documented in CLAUDE.md
- **Deployment risk** -- "Is this safe to ship on a Friday?" requires operational context

Use AI review to handle the tedious, repeatable checks. Save human review bandwidth for decisions that require judgment.

## Next Steps

- [Refactoring](refactoring.md) -- Restructuring code after review identifies problems
- [Git Workflows](git-workflows.md) -- Managing commits and PRs around the review cycle
- [Common Mistakes](../07-anti-patterns/common-mistakes.md) -- Anti-patterns that reviewers should catch
- [Security Considerations](../06-team/security.md) -- Security-focused review checklist
