# YOLO Mode (Dangerously Skip Permissions)

> Run without permission prompts. Powerful when you trust the task, dangerous when you don't.

## What It Is

YOLO mode auto-approves all tool calls - file reads, writes, bash commands, everything - without asking for confirmation.

```bash
claude --dangerously-skip-permissions
```

Or selectively in settings:

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run *)",
      "Bash(git *)",
      "Read",
      "Glob",
      "Grep"
    ]
  }
}
```

---

## Real-World YOLO Scenarios

### 1. VPN Connection via CLI

When no GUI is available or you want automation, use FortiClient CLI or openfortivpn:

```bash
claude --dangerously-skip-permissions
> "Connect to the corporate VPN using openfortivpn with the config in ~/.vpn/config"
```

YOLO lets it run `sudo openfortivpn` without prompting. Useful in headless environments, CI runners, or when you're SSHed into a dev box.

### 2. Auto-Merge GitLab MRs with PAT

No GitLab MCP server? No problem. YOLO mode + a Personal Access Token:

```bash
export GITLAB_TOKEN="glpat-xxxxxxxxxxxx"
claude --dangerously-skip-permissions
> "List all open MRs on project myteam/backend that have 2+ approvals
   and no pipeline failures. Merge them all."
```

Claude will use `curl` or `glab` CLI to hit the GitLab API directly:

```bash
# What Claude does behind the scenes:
glab mr list --state opened --repo myteam/backend
glab mr merge 142 --yes
glab mr merge 158 --yes
```

Without YOLO, you'd approve each `curl`/`glab` call individually. With 15 MRs to merge, that's 30+ permission prompts avoided.

### 3. GitHub PRs with gh CLI

Bulk PR operations become seamless:

```bash
claude --dangerously-skip-permissions
> "Create a PR from feature/auth to main with a summary of all commits.
   Then create PRs for all branches matching 'fix/*' that are ahead of main."
```

Claude runs `gh pr create`, `gh pr merge`, `gh pr review` without interruption.

### 4. Jira Automation with PAT

No Jira MCP connector? Use the REST API directly:

```bash
export JIRA_TOKEN="your-pat-token"
export JIRA_URL="https://yourcompany.atlassian.net"
claude --dangerously-skip-permissions
> "Move all tickets in sprint 'Sprint 24' that are still 'In Progress'
   but have merged PRs to 'Done'. Add a comment with the merge commit hash."
```

Claude uses `curl` to hit the Jira API:

```bash
# Fetches sprint tickets
curl -s -H "Authorization: Bearer $JIRA_TOKEN" "$JIRA_URL/rest/agile/1.0/sprint/42/issue"

# Transitions each ticket
curl -X POST -H "Authorization: Bearer $JIRA_TOKEN"   "$JIRA_URL/rest/api/3/issue/PROJ-123/transitions"   -d '{"transition":{"id":"31"}}'
```

### 5. Browser Automation via JavaScript (Chrome Tools)

When no API or MCP connector exists, fall back to browser automation. YOLO mode is essential here because browser interactions generate dozens of tool calls:

```bash
claude --dangerously-skip-permissions
> "Log into the admin dashboard at admin.internal.com,
   go to Settings > Users, export the user list as CSV"
```

**Prefer JavaScript execution over click interactions** for speed and reliability:

```javascript
// Instead of clicking through 5 pages:
// Claude runs this via the javascript_tool
const response = await fetch('/api/admin/users?format=csv', {
  headers: { 'Authorization': `Bearer ${getAuthToken()}` }
});
const csv = await response.text();
// Downloads directly - no UI navigation needed
```

This is 10x faster than simulating clicks and handles dynamic content better.

**Other browser YOLO scenarios:**
- Scraping internal tools that have no API
- Filling out forms in legacy systems
- Taking screenshots of dashboards for reports
- Testing user flows end-to-end

### 6. Greenfield Project Scaffolding

Starting from scratch - nothing to break:

```bash
claude --dangerously-skip-permissions
> "Create a Spring Boot 3.4 project with hexagonal architecture,
   JPA, PostgreSQL, JWT auth, Docker Compose, and GitHub Actions CI"
```

50+ files created without a single permission prompt.

### 7. Bulk Codebase Operations

Renaming, reformatting, updating imports across hundreds of files:

```bash
claude --dangerously-skip-permissions
> "Rename all instances of 'UserDTO' to 'UserResponse' across the entire
   codebase, update imports, and fix any test references"
```

### 8. CI/CD Pipeline Operations

In isolated environments where damage is contained:

```bash
# In a Docker container or CI job
claude --dangerously-skip-permissions
> "Run the full test suite, fix any compilation errors, re-run tests,
   then generate a coverage report"
```

### 9. Infrastructure as Code

When working with Terraform, Ansible, or Docker in a dev environment:

```bash
claude --dangerously-skip-permissions
> "Update the Terraform config to add a new Redis instance,
   run terraform plan, show me the diff"
```

### 10. The API Fallback Pattern

**When no API connector, MCP server, or CLI tool exists for a service, YOLO + browser is your fallback:**

```
Has CLI tool? (gh, glab, aws, kubectl) --> Use it directly
Has API + PAT?                         --> Use curl/fetch
Has MCP server?                        --> Use MCP tools
None of the above?                     --> Browser automation via Chrome tools
```

YOLO mode makes all of these frictionless because each approach generates multiple tool calls that would otherwise require individual approval.

---

## When NOT to Use YOLO Mode

| Situation | Why |
|-----------|-----|
| Production databases | One bad query = data loss |
| Shared repos without a branch | Force push risk |
| Security-sensitive code | Must review every line |
| Unfamiliar codebase | Can't predict what AI might do |
| Anything with `rm -rf` potential | Irreversible |
| Payment/billing integrations | Real money at stake |

---

## The Safety Net: YOLO + Git

Always have a rollback plan:

```bash
# Before YOLO session
git stash  # or commit current state

# Run YOLO
claude --dangerously-skip-permissions

# After: review everything
git diff                    # see what changed
git diff --stat             # overview
git checkout -- .           # nuclear undo
```

---

## Selective Permissions (The Middle Ground)

Instead of full YOLO, auto-approve only safe operations:

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "Bash(npm run *)",
      "Bash(git status)",
      "Bash(git diff*)",
      "Bash(git log*)",
      "Bash(gh pr *)",
      "Bash(curl -s *)",
      "Bash(glab *)"
    ]
  }
}
```

Speed on safe operations, prompts on writes and deletes.

---

## Quick Decision Framework

| Scenario | YOLO? | Why |
|----------|-------|-----|
| Greenfield project | Yes | Nothing to break |
| Bulk rename/format | Yes | Git safety net |
| CI/CD pipeline (isolated) | Yes | Contained environment |
| VPN/CLI automation | Yes | Single known command |
| PAT-based API calls (GitLab, Jira) | Yes | Auditable, reversible |
| Browser automation (no API) | Yes | Too many tool calls otherwise |
| gh CLI bulk PR operations | Yes | Safe with branch protection |
| Production repo | No | High blast radius |
| Database migrations | No | Irreversible |
| Security code changes | No | Must review |

## The Rule

**Use YOLO mode when the cost of a mistake is low and the cost of confirmation is high.** If either condition is not met, use selective permissions instead.
