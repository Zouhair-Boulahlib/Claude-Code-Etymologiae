# Commands (Slash Commands)

Ready-to-use slash commands for Claude Code. These are reusable prompt templates invoked with `/command-name`.

## Available Commands

| Command | Purpose |
|---------|---------|
| /review | Review staged changes for bugs, security, and style |
| /test-gen | Generate tests for recently changed files |
| /refactor-check | Find refactoring opportunities without making changes |
| /doc-gen | Generate or update documentation for changed code |
| /security-check | Full security audit of the codebase |

## Installation

Copy the `.md` files into your project's `.claude/commands/` directory:

```bash
mkdir -p .claude/commands
cp starter-kit/commands/*.md .claude/commands/
```

Or use the install script: `./install.sh commands`

## Creating Custom Commands

Create a `.md` file in `.claude/commands/` with:

```markdown
---
description: Short description shown in command list
---

Your prompt template here. This is what Claude receives when you type /command-name.
```

The filename becomes the command name: `review.md` → `/review`
