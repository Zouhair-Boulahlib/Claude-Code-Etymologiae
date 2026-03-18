# Claude Code Etymologiae

<p align="center">
  <img src="assets/cover.jpg" alt="Etymologiae manuscript page — Isidore of Seville, circa 7th century" width="600">
</p>
<p align="center">
  <em>Page from the original <a href="https://en.wikipedia.org/wiki/Etymologiae">Etymologiae</a> by Isidore of Seville (c. 560-636 AD) — the first encyclopedia of the Western world.</em>
</p>

> *Etymologiae* — inspired by Isidore of Seville's encyclopedic work that organized all knowledge of its time. This repository aims to do the same for AI-assisted programming: a living encyclopedia of patterns, practices, and hard-won lessons.

---

## What This Is

A practical, opinionated guide for developers who use **Claude Code** (the CLI tool) in their daily workflow. Not marketing material — real patterns from real projects, written by developers for developers.

Whether you're a solo dev shipping side projects or part of a team managing a large codebase, this guide helps you get the most out of AI-assisted development without losing control of your craft.

## Table of Contents

### I. Foundations
- [Getting Started](docs/01-foundations/getting-started.md) — Setup, configuration, and first principles
- [Mental Models](docs/01-foundations/mental-models.md) — How to think about AI-assisted development
- [The CLAUDE.md File](docs/01-foundations/claude-md.md) — Your project's instruction manual

### II. Daily Workflows
- [Reading & Understanding Code](docs/02-workflows/reading-code.md) — Navigate unfamiliar codebases fast
- [Writing Code](docs/02-workflows/writing-code.md) — From prompts to production-ready code
- [Debugging](docs/02-workflows/debugging.md) — Systematic approaches to finding and fixing bugs
- [Refactoring](docs/02-workflows/refactoring.md) — Safe, incremental improvements
- [Code Review](docs/02-workflows/code-review.md) — Using AI as a second pair of eyes
- [Git Workflows](docs/02-workflows/git-workflows.md) — Commits, PRs, and branch management

### III. Prompt Engineering
- [Effective Prompting](docs/03-prompts/effective-prompting.md) — Write prompts that get results
- [Context Management](docs/03-prompts/context-management.md) — Work within and around context limits
- [Multi-Step Tasks](docs/03-prompts/multi-step-tasks.md) — Break complex work into manageable pieces
- [Prompt Patterns](docs/03-prompts/prompt-patterns.md) — Reusable templates for common scenarios

### IV. Architecture & Design
- [Project Setup](docs/04-architecture/project-setup.md) — Structure projects for AI-friendly development
- [Testing Strategies](docs/04-architecture/testing.md) — Write tests that AI can help maintain
- [Documentation](docs/04-architecture/documentation.md) — Keep docs alive with AI assistance

### V. Advanced Patterns
- [Hooks & Automation](docs/05-advanced/hooks.md) — Automate repetitive workflows
- [MCP Servers](docs/05-advanced/mcp-servers.md) — Extend capabilities with custom tools
- [Custom Skills](docs/05-advanced/custom-skills.md) — Build reusable slash commands
- [Multi-Agent Workflows](docs/05-advanced/multi-agent.md) — Parallelize work across agents
- [CI/CD Integration](docs/05-advanced/ci-cd.md) — AI in your pipeline

### VI. Team Practices
- [Team Conventions](docs/06-team/conventions.md) — Shared standards for AI-assisted teams
- [Security Considerations](docs/06-team/security.md) — Keep secrets safe, review AI output
- [Onboarding Developers](docs/06-team/onboarding.md) — Help new team members get productive

### VII. Anti-Patterns
- [Common Mistakes](docs/07-anti-patterns/common-mistakes.md) — What NOT to do
- [Over-Engineering Traps](docs/07-anti-patterns/over-engineering.md) — When AI makes things worse
- [Debugging AI Output](docs/07-anti-patterns/debugging-ai.md) — When the suggestions are wrong

---

## Philosophy

1. **You are the engineer.** AI is a tool, not a replacement for understanding.
2. **Simplicity wins.** If you can't explain the generated code, don't ship it.
3. **Context is everything.** Better input = better output. Always.
4. **Trust but verify.** Read every diff before committing.
5. **Stay sharp.** Use AI to amplify your skills, not to avoid learning.

## Contributing

This is a living document. If you have patterns that work, anti-patterns you've discovered, or corrections to make — PRs are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[MIT](LICENSE) — Use it, share it, build on it.
