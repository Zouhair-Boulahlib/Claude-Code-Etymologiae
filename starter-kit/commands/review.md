---
description: Review staged changes for bugs, security, and style
---

Review all staged changes (`git diff --cached`) for:

1. **Bugs** — Logic errors, null checks, off-by-one, race conditions
2. **Security** — Injection, auth bypass, data exposure, hardcoded secrets
3. **Style** — Naming, consistency with existing code, unnecessary complexity
4. **Performance** — N+1 queries, missing indexes, unnecessary allocations

For each issue found:
- State the file and line
- Explain the problem
- Suggest a fix

If everything looks good, say so briefly.
