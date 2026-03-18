# YOLO Mode (Dangerously Skip Permissions)

> Run Claude Code without permission prompts. Powerful when you trust the task, dangerous when you don't.

## What It Is

YOLO mode auto-approves all tool calls - file reads, writes, bash commands, everything - without asking for confirmation. No "Allow?" prompts. No pauses. Pure speed.

```bash
# Launch in YOLO mode
claude --dangerously-skip-permissions
```

Or configure it in settings to auto-approve specific patterns.

## When to Use It

### 1. Greenfield Scaffolding
You're starting a new project from scratch. There's nothing to break.

```bash
claude --dangerously-skip-permissions
> "Create a new Express API with TypeScript, ESLint, Jest, and Docker setup"
```

No existing code to damage. Let it rip.

### 2. Throwaway Prototypes
Building a proof-of-concept you'll delete tomorrow. Speed matters, safety doesn't.

### 3. Isolated Test Environments
Running in a container, VM, or CI environment where damage is contained and reversible.

```bash
# In a Docker container or CI job
claude --dangerously-skip-permissions
> "Run the full test suite and fix any failures"
```

### 4. Repetitive Bulk Operations
Renaming 200 files, updating imports across the codebase, formatting everything. Tasks where every individual step is safe but the confirmation fatigue is real.

### 5. Personal Side Projects
Solo dev, no team, git history available. The blast radius of any mistake is just you.

## When NOT to Use It

### 1. Production Codebases
One wrong `rm -rf` or `git push --force` and you're having a very bad day. Always review in production repos.

### 2. Shared Repositories
Other people's work is at stake. A careless file deletion or force push affects the whole team.

### 3. Security-Sensitive Code
Auth, encryption, payment processing. You want to review every line.

### 4. Database Operations
Migrations, data transformations, anything touching persistent state. One bad query can corrupt data irreversibly.

### 5. When You Don't Understand the Codebase
If you can't predict what the AI might do, you need the permission prompts as guardrails.

## Safer Alternative: Selective Permissions

Instead of full YOLO, auto-approve only safe commands:

```json
// .claude/settings.json
{
  "permissions": {
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "Bash(npm run test)",
      "Bash(npm run lint)",
      "Bash(npm run build)",
      "Bash(git status)",
      "Bash(git diff*)",
      "Bash(git log*)"
    ]
  }
}
```

This gives you speed on safe operations while still prompting for writes, deletes, and arbitrary bash commands.

## The Middle Ground: YOLO + Git Safety Net

If you do use YOLO mode, always have a safety net:

```bash
# Before YOLO session: create a checkpoint
git stash  # or commit your current state

# Run YOLO
claude --dangerously-skip-permissions

# After: review everything
git diff                    # see what changed
git diff --stat             # overview of changed files
git checkout -- .           # nuclear option: undo everything
```

## Quick Decision Framework

| Situation | YOLO? |
|-----------|-------|
| New project, no existing code | Yes |
| Throwaway prototype | Yes |
| CI/CD pipeline (isolated) | Yes |
| Bulk rename/format | Yes |
| Production repo | No |
| Shared team repo | Selective permissions |
| Security-sensitive code | No |
| Database operations | No |
| Unfamiliar codebase | No |

## The Rule

**Use YOLO mode when the cost of a mistake is low and the cost of confirmation is high.** If either condition is not met, use selective permissions instead.
