# Agents

Specialized agent definitions for Claude Code. Each agent is a focused expert you can delegate tasks to.

## Available Agents

| Agent | Model | Purpose |
|-------|-------|---------|
| code-reviewer | Sonnet | Review code for bugs, security, and style |
| test-writer | Sonnet | Write comprehensive tests for source files |
| architect | Opus | Analyze architecture and plan implementations |
| security-auditor | Sonnet | Audit code for security vulnerabilities |
| doc-writer | Sonnet | Generate and update documentation |

## Installation

Copy the `.md` files into your project's `.claude/agents/` directory:

```bash
mkdir -p .claude/agents
cp starter-kit/agents/*.md .claude/agents/
```

Or use the install script: `./install.sh agents`

## Usage

Once installed, Claude Code can delegate to these agents using the Agent tool. You can also reference them explicitly:

```
Use the code-reviewer agent to review the changes in src/api/
```

## Customization

Edit the agent files to match your project's needs:
- Change the `model` field (opus for complex tasks, sonnet for fast tasks, haiku for simple tasks)
- Add project-specific rules to the agent's instructions
- Adjust the `tools` list to restrict or expand capabilities
