# Onboarding Developers to AI-Assisted Workflows

> How to bring a team from zero to productive with AI coding tools -- without the backlash.

## The Reality of Adoption

Most developers fall into one of three camps when you introduce AI coding tools:

- **Enthusiasts** (20%) -- already using Copilot or ChatGPT, will adopt immediately
- **Pragmatists** (60%) -- open to it, but need to see concrete value before committing
- **Skeptics** (20%) -- concerned about code quality, job security, or "doing it properly"

All three groups are reasonable. Your onboarding plan needs to address all of them.

## Setting Up a New Developer's Environment

Before anyone writes their first AI-assisted line of code, get the infrastructure right.

### 1. Install and Verify

```bash
npm install -g @anthropic-ai/claude-code
claude --version
```

### 2. Configure Project-Level Settings

Commit a `.claude/settings.json` to the repo so every developer starts with the same baseline:

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run test)",
      "Bash(npm run lint)",
      "Bash(npm run build)",
      "Bash(git status)",
      "Bash(git diff)"
    ]
  }
}
```

This pre-approves safe commands. Without it, new developers spend their first hour clicking "allow" on every trivial operation, which poisons the first impression.

### 3. Write a Comprehensive CLAUDE.md

This is the single highest-leverage onboarding action. A good CLAUDE.md means every developer -- new or experienced -- gets useful output from their first session.

```markdown
# CLAUDE.md

## Project Overview
E-commerce API serving the mobile app and admin dashboard.

## Tech Stack
- Node.js 20, TypeScript 5.3, Express 4
- PostgreSQL 15, Prisma ORM
- Jest for tests, ESLint + Prettier for formatting

## Commands
- `npm run dev` -- start dev server on port 3000
- `npm test` -- run all tests
- `npm run test:watch` -- run tests in watch mode
- `npm run lint` -- lint and format check
- `npm run db:migrate` -- run pending migrations

## Code Conventions
- Named exports only, no default exports
- Error handling: throw AppError instances, caught by global handler
- Tests live in __tests__ directories next to source files
- Use Prisma transactions for multi-table writes
- API responses follow { data, error, meta } envelope pattern

## Architecture
- src/routes/ -- Express route handlers (thin, delegate to services)
- src/services/ -- Business logic (no HTTP concepts here)
- src/repositories/ -- Database access via Prisma
- src/middleware/ -- Auth, validation, error handling
- src/types/ -- Shared TypeScript interfaces
```

### 4. Set Up Personal Settings

Each developer creates `~/.claude/settings.json` for their preferences:

```json
{
  "permissions": {
    "allow": [
      "Bash(git log*)",
      "Bash(git show*)"
    ]
  }
}
```

## The Learning Curve: What to Expect

### Week 1: Orientation

Developers are learning the tool's interface, not its capabilities. Expect:

- **Overly vague prompts** -- "fix this", "make it work"
- **Frustration with wrong answers** -- they don't know how to course-correct yet
- **Either over-trust or under-trust** -- accepting everything blindly, or rejecting everything reflexively

**Goals for week 1:**
- Every developer has run at least 10 sessions
- Every developer has had one "that was actually useful" moment
- Nobody has merged unreviewed AI code to main

### Week 2: Pattern Recognition

Developers start noticing what works and what doesn't. Expect:

- **Better prompts** -- they start providing file paths and constraints
- **Faster rejection of bad output** -- they recognize when the AI is off-track
- **Questions about best practices** -- "should I use this for X?"

**Goals for week 2:**
- Developers can explain when AI is useful vs. when to code manually
- At least one developer has shared a useful prompt pattern with the team
- PR review times for AI-assisted code are converging with manual code

### Week 4: Integration

AI tools become part of the regular workflow, not a separate activity. Expect:

- **Natural tool switching** -- using AI for boilerplate, manual coding for business logic
- **CLAUDE.md contributions** -- developers adding conventions they wish the AI knew
- **Fewer but better prompts** -- quality over quantity

**Goals for week 4:**
- Team has a shared collection of prompt patterns that work for your codebase
- CLAUDE.md has been updated at least 3 times based on real usage
- No one is spending more time fighting the tool than it saves

## First Week Checklist

```
[ ] Claude Code installed and authenticated
[ ] Project CLAUDE.md reviewed and understood
[ ] .claude/settings.json configured with safe commands
[ ] Completed guided task: "Explain what src/<core-module> does"
[ ] Completed guided task: "Write a test for <existing-function>"
[ ] Completed guided task: "Fix <known-small-bug> in <specific-file>"
[ ] Read the anti-patterns doc (common-mistakes.md)
[ ] Participated in one AI-assisted code review
[ ] Asked at least one question in team channel about AI workflow
[ ] Did NOT merge any AI code without manual review
```

## First Month Milestones

| Milestone | How to measure |
|-----------|---------------|
| Every dev has 20+ sessions logged | Check usage |
| CLAUDE.md updated by 3+ team members | Git blame |
| Team prompt patterns documented | Shared doc or wiki |
| AI-assisted PRs pass review at same rate as manual | PR metrics |
| At least one developer has become a team resource | Peer recognition |
| No production incidents from unreviewed AI code | Incident log |
| Skeptics have found at least one use case they like | Ask them directly |

## First Tasks to Assign with AI Assistance

Start with tasks where the risk is low and the feedback is fast.

**Tier 1 -- Day 1-2 (zero risk):**
- "Use Claude Code to explain what `src/services/billing.ts` does"
- "Ask it to find all the places we handle authentication errors"
- "Have it generate a summary of our API endpoints"

**Tier 2 -- Day 3-5 (low risk, fast feedback):**
- "Write unit tests for `calculateShippingCost` in `src/services/shipping.ts`"
- "Add input validation to the `POST /orders` endpoint"
- "Refactor the duplicated error handling in `src/routes/users.ts` and `src/routes/products.ts`"

**Tier 3 -- Week 2 (medium risk, real work):**
- "Add pagination to the `GET /products` endpoint following the pattern in `GET /orders`"
- "Fix the race condition in the inventory update flow -- see issue #342"
- "Extract the email templating logic into its own service module"

Do not start anyone on greenfield feature development or security-critical code. Those require judgment that comes with tool familiarity.

## Common Resistance and How to Address It

### "It's going to write bad code"

**Response:** It writes code the way a fast, well-read junior developer does. Sometimes excellent, sometimes wrong. That is why we review everything. Show them a concrete example where AI output needed correction, and another where it was spot-on.

### "I'm faster without it"

**Response:** Probably true for week 1. Probably false by week 4. Suggest a time-boxed experiment: use it for one specific task type (tests, boilerplate, refactoring) for two weeks, then evaluate. Do not mandate usage for everything.

### "It doesn't understand our codebase"

**Response:** It understands what we tell it. Improve the CLAUDE.md together. This resistance is actually useful -- it means the developer cares about context, which makes them a good contributor to the project configuration.

### "What about code quality?"

**Response:** Same code review standards apply. AI-generated code goes through the same PR process. If anything, AI code gets more scrutiny early on -- which is correct.

### "Is this going to replace us?"

**Response:** Be honest. AI makes developers faster, not redundant. The bottleneck was never typing speed -- it was understanding, judgment, and decisions. Those are still human. Developers who learn to use AI tools effectively become more valuable, not less.

## Mentoring Patterns

### Pair-with-AI Sessions

Schedule 30-minute sessions where a senior developer works alongside a newer AI user:

```
Senior: "Let's fix this bug together using Claude Code."
        *shows how to write a precise prompt*
        *shows how to read the diff critically*
        *shows when to reject and re-prompt vs. accept and adjust*
```

This transfers tacit knowledge about tool interaction that documentation cannot capture.

### Prompt Review

During the first two weeks, review prompts the same way you review code. Not to judge, but to improve:

```
Original:  "fix the user service"
Coaching:  "Try: 'In src/services/user.ts, the updateProfile method
            doesn't validate the email field before saving. Add
            validation that checks for valid format and uniqueness.'"
```

### Office Hours

Designate one hour per week where anyone can bring an AI workflow question. Topics that always come up:

- "It keeps suggesting X, but we do Y -- how do I stop that?"
- "My conversation got long and the output got worse -- what happened?"
- "It wrote something that works but I don't understand it -- is that okay?"

## Measuring Adoption

Track these metrics, but do not turn them into targets:

- **Session frequency** -- are people actually using the tool?
- **Task completion time** -- for comparable tasks, is there a trend?
- **PR iteration count** -- are AI-assisted PRs requiring more or fewer rounds?
- **CLAUDE.md commit frequency** -- is the team investing in shared context?
- **Self-reported satisfaction** -- monthly pulse check, one question: "Is AI tooling making you more productive?"

Avoid measuring lines of code generated, prompts per day, or acceptance rate. These incentivize quantity over quality, which is the opposite of what you want.

## The Long Game

Adoption is not a switch you flip. It is a skill the team develops over weeks and months. The goal is not "everyone uses AI for everything." The goal is "everyone knows when and how to use AI effectively, and does so by choice."

The teams that succeed treat AI tools the way they treat any other engineering tool -- with curiosity, skepticism, practice, and iteration.

## Next Steps

- [Common Mistakes](../07-anti-patterns/common-mistakes.md) -- Patterns to avoid from day one
- [Effective Prompting](../03-prompts/effective-prompting.md) -- The prompting guide to share with new users
- [The CLAUDE.md File](../01-foundations/claude-md.md) -- Deep dive into project configuration
