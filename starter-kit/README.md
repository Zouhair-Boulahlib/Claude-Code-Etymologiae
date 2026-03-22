# Starter Kit

Ready-to-use configurations for Claude Code. Copy what you need, customize for your project.

## What's Inside

```
starter-kit/
├── templates/          # CLAUDE.md templates for different project types
│   ├── claude-md-rest-api.md
│   ├── claude-md-frontend.md
│   ├── claude-md-fullstack.md
│   ├── claude-md-cli-tool.md
│   └── claude-md-microservices.md
├── hooks/              # Automation triggers
│   ├── format-on-save.json
│   ├── test-before-commit.json
│   ├── lint-after-edit.json
│   └── notify-on-stop.json
├── commands/           # Slash commands
│   ├── review.md           # /review — code review
│   ├── test-gen.md         # /test-gen — generate tests
│   ├── refactor-check.md   # /refactor-check — find improvements
│   ├── doc-gen.md          # /doc-gen — generate docs
│   └── security-check.md   # /security-check — security audit
├── agents/             # Specialized subagents
│   ├── code-reviewer.md
│   ├── test-writer.md
│   ├── architect.md
│   ├── security-auditor.md
│   └── doc-writer.md
└── install.sh          # One-command installer
```

## Quick Start

```bash
# Clone the repo
git clone https://github.com/Zouhair-Boulahlib/Claude-Code-Etymologiae.git
cd Claude-Code-Etymologiae/starter-kit

# Install everything into your project
./install.sh --target ~/your-project

# Or install specific components
./install.sh commands agents --target ~/your-project

# See what's available
./install.sh --list

# Preview without installing
./install.sh --dry-run --target ~/your-project
```

## Manual Installation

If you prefer to pick and choose:

```bash
# Copy a CLAUDE.md template
cp templates/claude-md-rest-api.md ~/your-project/CLAUDE.md
# Edit the [PLACEHOLDER] values

# Copy slash commands
mkdir -p ~/your-project/.claude/commands
cp commands/review.md ~/your-project/.claude/commands/

# Copy agents
mkdir -p ~/your-project/.claude/agents
cp agents/code-reviewer.md ~/your-project/.claude/agents/

# Copy a hook (then merge into settings.json)
cat hooks/format-on-save.json
```

## Customization

Every file is meant to be edited. The templates include `[PLACEHOLDER]` markers — replace them with your project's specifics.

- **Templates**: Change tech stack, commands, conventions to match your project
- **Hooks**: Swap `prettier` for `black`, `eslint` for `golangci-lint`, etc.
- **Commands**: Add project-specific context, adjust review criteria
- **Agents**: Change models, add project rules, adjust tool access
