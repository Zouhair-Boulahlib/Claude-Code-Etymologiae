---
description: Security audit for the current codebase
---

Perform a security review of this project:

1. **Dependencies** — Check for known vulnerabilities (`npm audit` / `pip audit` / equivalent)
2. **Secrets** — Scan for hardcoded API keys, passwords, tokens in source files
3. **Input validation** — Check API endpoints for missing validation
4. **Auth/AuthZ** — Verify authentication and authorization are properly enforced
5. **SQL/NoSQL injection** — Check database queries for injection vulnerabilities
6. **XSS** — Check for unsanitized output in templates/responses
7. **CORS** — Verify CORS configuration is not overly permissive
8. **Environment** — Check that .env files are gitignored, secrets use env vars

Report findings by severity: CRITICAL / HIGH / MEDIUM / LOW.
For each finding, specify the file, line, and recommended fix.
