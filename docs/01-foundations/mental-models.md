# Mental Models

> How to think about AI-assisted development so you use it effectively, not recklessly.

## The Pair Programmer Model

The most useful mental model: **AI is a pair programmer who has read a lot of code but has never worked at your company.**

This means:
- It knows language idioms, design patterns, and library APIs extremely well
- It doesn't know your business domain, team decisions, or why things are the way they are
- It can suggest solutions fast, but you need to validate they fit your context

## Input Quality = Output Quality

This isn't a vending machine where you press a button and get a result. It's more like a conversation with a very capable colleague who needs context to give good advice.

```
Bad:  "fix the bug"
OK:   "fix the login bug"
Good: "Users report that login fails silently when the email contains a '+' character.
       The auth endpoint is in src/api/auth.ts. Fix the email validation."
```

The quality difference in output between these three prompts is enormous.

## The Context Window Is Your Shared Workspace

Think of the context window as a shared whiteboard. Everything you and the AI have discussed is on that whiteboard. When it fills up, older content gets compressed or lost.

Implications:
- **Front-load important context** — put the most critical information early
- **Don't repeat yourself** — if you said it once, it's on the whiteboard
- **Start fresh for new topics** — a new conversation is cheaper than fighting stale context
- **Use CLAUDE.md for persistent context** — anything that should survive across sessions goes there

## Verification Levels

Not all AI output needs the same level of scrutiny:

| Task | Risk Level | Verification Needed |
|------|-----------|-------------------|
| Explain code | Low | Sanity check |
| Write a test | Low-Medium | Run it, check coverage |
| Fix a typo/style issue | Low | Glance at diff |
| Implement a feature | Medium | Full code review |
| Modify auth/security code | High | Line-by-line review |
| Database migrations | High | Test on staging first |
| Delete/modify existing logic | High | Understand why before approving |

## The 80/20 Rule

AI handles roughly 80% of most tasks extremely well. The remaining 20% — edge cases, business logic nuances, integration points — is where your expertise matters most.

Don't try to get AI to handle that last 20% through increasingly complex prompts. Instead:
1. Let AI do the 80% fast
2. Review and adjust the output yourself
3. Move on

## When to Use AI vs. When Not To

### Great use cases:
- Boilerplate code and repetitive patterns
- Understanding unfamiliar codebases
- Writing tests for existing code
- Refactoring with clear rules (rename, extract, restructure)
- Git operations (commits, PRs, branch management)
- Debugging with clear error messages

### Use with caution:
- Complex business logic (AI doesn't know your domain rules)
- Performance optimization (needs profiling data it can't see)
- Security-critical code (always review line-by-line)
- Architectural decisions (AI optimizes locally, not globally)

### Avoid:
- Blindly accepting large diffs you haven't read
- Using AI to avoid understanding code you maintain
- Generating code in areas you have zero familiarity with

## The Sharpening Effect

The best developers using AI tools get **better** at their craft, not worse. Why?

- Reading more code (reviewing AI output) builds pattern recognition
- Explaining problems clearly (prompting) forces you to think precisely
- Seeing alternative approaches (AI suggestions) broadens your toolkit
- Spending less time on boilerplate means more time on hard problems

The danger is the opposite: using AI as a crutch to avoid thinking. If you find yourself accepting code without understanding it, stop. Read it. Learn from it. Then move on.

## Next Steps

- [The CLAUDE.md File](claude-md.md) — Configure your project for better AI collaboration
- [Effective Prompting](../03-prompts/effective-prompting.md) — Put these mental models into practice
