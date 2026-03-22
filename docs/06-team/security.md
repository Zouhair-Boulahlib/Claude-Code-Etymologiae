# Security Considerations

AI-assisted development introduces new attack surfaces and new classes of mistakes.
The code Claude generates is only as secure as your review process. This guide
covers the practical security concerns -- what to watch for, what to lock down,
and how to build a review process that catches AI-specific vulnerabilities.

## Secrets Management

The most common security failure with AI tools is leaking secrets.

### The .claudeignore File

Create a `.claudeignore` file in your repo root. It works like `.gitignore` but
controls what Claude Code can read.

```
# .claudeignore

# Environment and secrets
.env
.env.*
*.pem
*.key
*.p12
*.pfx
credentials.json
service-account.json
secrets/

# Cloud configuration with credentials
.aws/
.gcp/
.azure/

# Local developer configs that may contain tokens
.claude/credentials
.npmrc
.pypirc

# CI secrets
.github/secrets/
```

### Rules for Secrets

1. **Never paste secrets into a Claude Code prompt.** The conversation may be
   logged, cached, or sent to the API.
2. **Never commit `.env` files.** This is not AI-specific, but AI makes it easier
   to accidentally include them in broad commits.
3. **Use environment variables for all secrets.** If Claude generates code that
   hardcodes a credential, reject it immediately.
4. **Audit AI-generated config files.** Claude sometimes generates example configs
   with placeholder values like `sk-your-key-here`. These can end up committed
   if you are not careful.

```bash
# Quick check for potential secrets in staged files
git diff --cached | grep -iE '(api_key|secret|password|token|credential).*='
```

## Reviewing AI Output for Vulnerabilities

Claude generates functional code that often has subtle security gaps. Here are
the patterns to watch for.

### Injection Flaws

AI frequently builds queries or commands by string concatenation.

```typescript
// DANGEROUS -- AI-generated code that looks clean but is vulnerable
app.get('/search', (req, res) => {
  const query = req.query.q;
  const results = db.query(`SELECT * FROM products WHERE name LIKE '%${query}%'`);
  res.json(results);
});
```

```typescript
// SAFE -- parameterized query
app.get('/search', (req, res) => {
  const query = req.query.q;
  const results = db.query(
    'SELECT * FROM products WHERE name LIKE $1',
    [`%${query}%`]
  );
  res.json(results);
});
```

Check every database query, shell command, and template rendering in AI output.

### Cross-Site Scripting (XSS)

AI may render user input without sanitization, especially in server-rendered HTML.

```typescript
// DANGEROUS -- direct interpolation of user input
app.get('/profile', (req, res) => {
  res.send(`<h1>Welcome, ${req.query.name}</h1>`);
});
```

Verify that all user input is escaped before rendering. In React, this is handled
by default -- but `dangerouslySetInnerHTML` bypasses it, and AI sometimes uses it.

### Authentication and Authorization Bypass

AI-generated route handlers sometimes skip auth middleware or implement incomplete
authorization checks.

```typescript
// MISSING -- no auth middleware, no ownership check
app.delete('/api/posts/:id', async (req, res) => {
  await Post.findByIdAndDelete(req.params.id);
  res.json({ success: true });
});

// CORRECT -- auth + ownership verification
app.delete('/api/posts/:id', authenticate, async (req, res) => {
  const post = await Post.findById(req.params.id);
  if (!post) return res.status(404).json({ error: 'Not found' });
  if (post.authorId !== req.user.id) return res.status(403).json({ error: 'Forbidden' });
  await post.deleteOne();
  res.json({ success: true });
});
```

For every endpoint Claude generates, ask: who can call this, and should they be
able to?

### Insecure Defaults

AI tends toward making things work over making things secure.

Common insecure defaults in AI-generated code:
- CORS set to `*` (allow all origins)
- JWT tokens with no expiration
- HTTP instead of HTTPS in URLs
- Debug mode enabled
- Overly permissive file permissions
- Missing rate limiting
- Disabled CSRF protection

## Permission Modes

Claude Code has permission settings that control what it can do. Use them.

### Recommended Project Settings

```json
{
  "permissions": {
    "allow": [
      "Read(*)",
      "Bash(npm test*)",
      "Bash(npm run lint*)",
      "Bash(npm run build*)"
    ],
    "deny": [
      "Bash(curl*)",
      "Bash(wget*)",
      "Bash(rm -rf /)*",
      "Bash(chmod 777*)",
      "Bash(git push*)",
      "Bash(npm publish*)",
      "Bash(npx*)",
      "Write(.env*)"
    ]
  }
}
```

Why deny `curl` and `wget`? AI might fetch remote scripts and execute them.
Why deny `npx`? It can download and run arbitrary packages.

Adjust based on your workflow, but start restrictive and open up as needed.

## Audit Logging

Track what Claude Code does, especially in shared environments.

### What to Log

- Commands executed via Bash tool
- Files created or modified
- External network requests (if allowed)
- Packages installed or suggested

### How to Review

After a Claude Code session that involved code changes:

```bash
# Review all changes before committing
git diff

# Check for new files that should not exist
git status

# Look for new dependencies
git diff package.json  # or requirements.txt, go.mod, etc.

# Search for common security anti-patterns in changed files
git diff --name-only | xargs grep -l 'eval\|exec\|dangerouslySetInnerHTML\|innerHTML'
```

## Supply Chain Risks

AI may suggest packages you have never heard of. This is a real attack vector.

### The Problem

Claude might suggest:

```bash
npm install super-useful-auth-helper
```

That package might:
- Not exist (and a typosquatter could register it later)
- Exist but be unmaintained
- Exist but contain malicious code
- Be a real package but overkill for what you need

### The Mitigation

Before installing any AI-suggested package:

1. **Verify it exists** on npmjs.com, PyPI, or the relevant registry.
2. **Check the download count.** Under 1,000 weekly downloads is a yellow flag.
3. **Check the last publish date.** Over 2 years without updates is a red flag.
4. **Read the source.** For small packages, skim the actual code.
5. **Check if you even need it.** AI sometimes suggests a package for something
   you can write in 10 lines.

```bash
# Quick npm package check
npm view super-useful-auth-helper --json 2>/dev/null | jq '{
  name: .name,
  version: .version,
  downloads: .downloads,
  modified: .time.modified,
  dependencies: (.dependencies | length)
}'
```

## Secure CLAUDE.md Practices

Your CLAUDE.md file shapes AI behavior. A malicious or careless CLAUDE.md can
cause problems.

**Do:**
- Commit CLAUDE.md to version control so changes are reviewed
- Include security requirements ("always validate input", "always use parameterized queries")
- Reference your security documentation and coding standards
- Specify which patterns are security-critical and must not be shortcut

**Do not:**
- Put secrets or internal URLs in CLAUDE.md
- Include credentials for staging or dev environments
- Reference internal security vulnerabilities that should not be in version control
- Use CLAUDE.md instructions that override safe defaults ("always approve file writes")

## OWASP Considerations for AI-Generated Code

Map the OWASP Top 10 to AI-specific risks.

| OWASP Risk | AI-Specific Concern |
|---|---|
| A01: Broken Access Control | AI often skips authorization checks on endpoints |
| A02: Cryptographic Failures | AI may use outdated algorithms (MD5, SHA1 for passwords) |
| A03: Injection | AI defaults to string interpolation over parameterized queries |
| A04: Insecure Design | AI builds what you ask for, does not question the design |
| A05: Security Misconfiguration | AI uses permissive defaults to get things working |
| A06: Vulnerable Components | AI may suggest outdated or unknown packages |
| A07: Auth Failures | AI may implement auth patterns with known weaknesses |
| A08: Data Integrity Failures | AI may skip input validation or integrity checks |
| A09: Logging Failures | AI rarely adds security logging unless asked |
| A10: SSRF | AI may construct URLs from user input without validation |

## Security Checklist for AI-Assisted PRs

Use this checklist for every PR that includes AI-generated code.

```markdown
## Security Review -- AI-Generated Code

### Input Handling
- [ ] All user input is validated (type, length, format)
- [ ] SQL queries use parameterized statements, not string concatenation
- [ ] Shell commands do not include unsanitized user input
- [ ] File paths are validated and restricted to expected directories

### Authentication and Authorization
- [ ] All endpoints have appropriate auth middleware
- [ ] Authorization checks verify the requesting user owns/can access the resource
- [ ] Tokens have expiration and are validated on each request
- [ ] No hardcoded credentials or API keys

### Data Protection
- [ ] Sensitive data is not logged or exposed in error messages
- [ ] PII is handled according to data retention policies
- [ ] Responses do not leak internal system details
- [ ] CORS is configured for specific origins, not wildcard

### Dependencies
- [ ] All new packages have been verified (popularity, maintenance, source)
- [ ] No packages with known vulnerabilities (run npm audit / pip audit)
- [ ] Dependencies are pinned to specific versions

### Configuration
- [ ] No debug flags or development settings in production code
- [ ] Security headers are present (CSP, HSTS, X-Frame-Options)
- [ ] Rate limiting is applied to public endpoints
- [ ] Error messages do not reveal stack traces or internal paths

### AI-Specific Checks
- [ ] Code has been manually traced, not just visually scanned
- [ ] No hallucinated API methods or non-existent library functions
- [ ] No overly permissive defaults added "to make it work"
- [ ] Business logic matches the actual requirements, not a plausible interpretation
```

## Incident Response

If you discover that AI-generated code introduced a vulnerability:

1. **Fix the vulnerability first.** Do not waste time assigning blame.
2. **Check for similar patterns.** If AI generated one insecure endpoint, it
   likely generated others the same way. Search the codebase.
3. **Update CLAUDE.md.** Add a specific instruction to prevent the same class
   of vulnerability. For example: "All database queries MUST use parameterized
   statements. Never use string interpolation for SQL."
4. **Update your review checklist.** Add the specific failure to catch it next time.
5. **Share the finding.** In your team retro, discuss what was missed and why.

Security with AI is not fundamentally different from security without it. The
difference is volume and speed -- AI generates more code faster, which means
more surface area to review. The answer is not to slow down. It is to build
review processes that scale with the output.

## Next Steps

- [Starter Kit: Security Command](../../starter-kit/commands/security-check.md) -- Ready-to-use security audit command
- [Code Review](../02-workflows/code-review.md) -- Review process for catching security issues
