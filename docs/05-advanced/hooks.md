# Hooks & Automation

> Automate repetitive tasks, enforce guardrails, and integrate Claude Code into your workflow with event-driven hooks.

## What Are Hooks?

Hooks are shell commands that Claude Code runs automatically when specific events occur during a session. Think of them like git hooks, but for your AI coding workflow. A hook fires, runs your command, and the result influences what happens next.

Use cases:

- Auto-format code after every file write
- Block dangerous commands before they execute
- Send notifications when long tasks finish
- Run linters automatically so Claude sees the output
- Enforce project-specific rules that go beyond CLAUDE.md

## Hook Types

Claude Code supports four hook events:

| Event | Fires When | Typical Use |
|-------|-----------|-------------|
| `PreToolUse` | Before a tool call executes | Block or modify dangerous operations |
| `PostToolUse` | After a tool call completes | Lint, format, validate output |
| `Notification` | Claude Code sends a notification | Custom alerts (Slack, sound, etc.) |
| `UserPromptSubmit` | User submits a prompt | Transform or log prompts |

Each hook receives context about the event as JSON on stdin and can influence behavior through its exit code and stdout.

---

## Configuring Hooks

Hooks live in your settings files. You can define them at three levels:

- **User-level**: `~/.claude/settings.json` -- applies to all projects
- **Project-level**: `.claude/settings.json` -- shared with your team via git
- **Local project-level**: `.claude/settings.local.json` -- your personal overrides

The structure:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hook": "python3 /path/to/my-hook.py"
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hook": "/path/to/format-check.sh"
      }
    ]
  }
}
```

### Key Fields

- **`matcher`** -- regex matched against the tool name. `"Bash"` matches the Bash tool. `"Write|Edit"` matches either. `""` or omitting it matches all tools.
- **`hook`** -- the shell command to run. It receives event JSON on stdin.

---

## How Hooks Communicate

### Exit Codes

| Exit Code | Meaning |
|-----------|---------|
| 0 | Success -- proceed normally |
| 2 | Block -- abort the tool call (PreToolUse only) |
| Any other | Error -- logged but does not block execution |

### Stdin

Your hook receives JSON on stdin describing the event. For `PreToolUse` and `PostToolUse`, this includes the tool name and its parameters:

```json
{
  "tool_name": "Bash",
  "tool_input": {
    "command": "rm -rf /tmp/build"
  }
}
```

### Stdout

For `PreToolUse` hooks that exit with code 0, any stdout is shown to Claude as additional context. For hooks that exit with code 2 (block), the stdout becomes the reason shown for blocking.

---

## Practical Hook Examples

### 1. Auto-Format on File Write

Run Prettier every time Claude writes or edits a file:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hook": "npx prettier --write \"$CLAUDE_FILE_PATH\" 2>/dev/null || true"
      }
    ]
  }
}
```

The `|| true` ensures formatting failures do not interrupt Claude's workflow. The formatted result is what gets saved.

### 2. Block Dangerous Commands

Prevent Claude from running destructive commands even in permissive mode:

```bash
#!/usr/bin/env bash
# save as: ~/.claude/hooks/block-dangerous.sh

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')

# Block force pushes
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force'; then
  echo "BLOCKED: Force push is not allowed. Use --force-with-lease instead."
  exit 2
fi

# Block production database access
if echo "$COMMAND" | grep -qE 'psql.*prod|mysql.*production'; then
  echo "BLOCKED: Direct production database access is prohibited."
  exit 2
fi

# Block rm -rf on important paths
if echo "$COMMAND" | grep -qE 'rm\s+-rf\s+(/|~|/home|/etc|/var)'; then
  echo "BLOCKED: Refusing to remove system-critical paths."
  exit 2
fi

exit 0
```

Configure it:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hook": "bash ~/.claude/hooks/block-dangerous.sh"
      }
    ]
  }
}
```

### 3. Auto-Lint After Edits

Run ESLint after every file modification and feed results back to Claude:

```bash
#!/usr/bin/env bash
# save as: .claude/hooks/post-lint.sh

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

# Only lint JS/TS files
if [[ "$FILE" =~ \.(js|ts|jsx|tsx)$ ]]; then
  RESULT=$(npx eslint "$FILE" --format compact 2>&1)
  if [ $? -ne 0 ]; then
    echo "Lint errors found in $FILE:"
    echo "$RESULT"
  fi
fi

exit 0
```

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hook": "bash .claude/hooks/post-lint.sh"
      }
    ]
  }
}
```

When this hook outputs lint errors, Claude sees them and can fix the issues in a follow-up edit -- automatically creating a self-correcting loop.

### 4. Custom Slack Notification

Get a Slack message when Claude finishes a long task:

```bash
#!/usr/bin/env bash
# save as: ~/.claude/hooks/slack-notify.sh

INPUT=$(cat)
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Task complete"')

curl -s -X POST "$SLACK_WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d "{\"text\": \"Claude Code: $MESSAGE\"}" \
  > /dev/null 2>&1

exit 0
```

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hook": "bash ~/.claude/hooks/slack-notify.sh"
      }
    ]
  }
}
```

### 5. Log All Prompts for Audit

Keep a local log of every prompt sent to Claude:

```bash
#!/usr/bin/env bash
# save as: .claude/hooks/log-prompt.sh

INPUT=$(cat)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""')

echo "[$TIMESTAMP] $PROMPT" >> .claude/prompt-audit.log

exit 0
```

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hook": "bash .claude/hooks/log-prompt.sh"
      }
    ]
  }
}
```

### 6. Auto-Run Tests After Code Changes

Trigger relevant tests after Claude modifies source files:

```bash
#!/usr/bin/env bash
# save as: .claude/hooks/auto-test.sh

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

# Skip non-source files
[[ "$FILE" =~ \.(test|spec)\.(js|ts)$ ]] && exit 0
[[ ! "$FILE" =~ \.(js|ts|jsx|tsx)$ ]] && exit 0

# Derive test file path
TEST_FILE="${FILE%.ts}.test.ts"
TEST_FILE="${TEST_FILE%.tsx}.test.tsx"

if [ -f "$TEST_FILE" ]; then
  RESULT=$(npx jest "$TEST_FILE" --no-coverage 2>&1 | tail -20)
  echo "Test results for $TEST_FILE:"
  echo "$RESULT"
fi

exit 0
```

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hook": "bash .claude/hooks/auto-test.sh"
      }
    ]
  }
}
```

---

## Debugging Hooks

When a hook does not behave as expected:

**Check that the hook is executable:**

```bash
chmod +x .claude/hooks/my-hook.sh
```

**Test it manually by piping JSON to stdin:**

```bash
echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | bash .claude/hooks/block-dangerous.sh
echo $?
```

**Use stderr for debug logging** -- stderr does not get captured as hook output:

```bash
echo "DEBUG: received input: $INPUT" >&2
```

**Common pitfalls:**

- Hook path is relative but your working directory is not what you expect. Use absolute paths or paths relative to the project root.
- The `jq` command is not installed. Hooks run in your system shell, so all dependencies must be available.
- Matcher regex is wrong. `"Write"` matches `"Write"` and `"NotebookEdit"` -- be specific with `"^Write$"` if needed.
- Hook takes too long. Hooks that run for more than a few seconds degrade the interactive experience. Keep them fast.

---

## Hooks vs. Other Automation

| Approach | Best For |
|----------|---------|
| Hooks | Automatic enforcement, formatting, notifications -- things that should always happen |
| CLAUDE.md instructions | Behavioral guidance, conventions, preferences -- things Claude should know |
| Custom skills | Reusable multi-step workflows triggered on demand |
| Permissions allow list | Auto-approving known-safe commands |

Hooks are the "always on" automation layer. They do not depend on Claude remembering instructions -- they run regardless.

## Next Steps

- [Custom Skills](custom-skills.md) -- Build reusable slash commands for complex workflows
- [MCP Servers](mcp-servers.md) -- Extend Claude Code with external tool integrations
- [Token Optimization](token-optimization.md) -- Keep hook output concise to save context
- [CI/CD Integration](ci-cd.md) -- Automation patterns for your pipeline
