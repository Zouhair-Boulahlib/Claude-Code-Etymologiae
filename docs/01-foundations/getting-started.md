# Getting Started

> Install, configure, and understand the fundamentals before writing your first prompt.

## Installation

```bash
npm install -g @anthropic-ai/claude-code
```

Verify it's working:

```bash
claude --version
```

## First Run

Navigate to your project directory and start a session:

```bash
cd your-project
claude
```

That's it. You're in an interactive session with full access to your codebase.

## Essential Configuration

### The CLAUDE.md File

The single most impactful thing you can do is create a `CLAUDE.md` file in your project root. This is your project's instruction manual — it's loaded into every conversation automatically.

```markdown
# CLAUDE.md

## Project Overview
Brief description of what this project does.

## Tech Stack
- Language/framework versions
- Key dependencies

## Development Commands
- `npm run dev` — start development server
- `npm test` — run test suite
- `npm run lint` — check code style

## Code Conventions
- We use TypeScript strict mode
- Tests go in __tests__ directories
- Use named exports, not default exports

## Architecture Notes
- src/api/ — REST endpoints
- src/services/ — business logic
- src/db/ — database access layer
```

### Why CLAUDE.md Matters

Without it, every conversation starts from zero. The AI reads your code but doesn't know:
- Which commands to run
- What conventions your team follows
- What's intentional vs. accidental in your codebase
- How to run tests or verify changes

With a good CLAUDE.md, conversations are **dramatically** more productive from the first prompt.

### Settings

Your personal settings live at `~/.claude/settings.json`. Project settings go in `.claude/settings.json` (committed to git for team sharing).

Key settings to know:

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run test)",
      "Bash(npm run lint)"
    ]
  }
}
```

This auto-approves specific commands so you're not clicking "allow" repeatedly for safe operations.

## Your First Productive Session

Don't start with "build me an app." Start with something you already understand:

1. **Navigate an unfamiliar file**: "Explain what `src/auth/middleware.ts` does and how it connects to the request pipeline"
2. **Fix a small bug**: "The login form doesn't clear error messages after a successful retry. Fix it."
3. **Write a test**: "Write a unit test for the `calculateDiscount` function in `src/pricing.ts`"

These small wins teach you how the tool thinks and where it needs guidance.

## What to Expect

**It will be right most of the time** — for straightforward tasks, the output is often production-ready.

**It will sometimes be wrong** — especially with complex business logic, edge cases, or code that depends on runtime state it can't see.

**It gets better with context** — the more you tell it (via CLAUDE.md, clear prompts, and conversation history), the better the results.

**You still need to review everything** — treat AI output like a junior developer's PR. Read the diff. Run the tests. Understand what changed.

## Next Steps

- [Mental Models](mental-models.md) — How to think about AI-assisted development
- [The CLAUDE.md File](claude-md.md) — Deep dive into project configuration
- [Effective Prompting](../03-prompts/effective-prompting.md) — Write prompts that get results
