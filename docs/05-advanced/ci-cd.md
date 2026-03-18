# CI/CD Integration

Claude Code can run headless in CI/CD pipelines -- no terminal, no interactive
prompts. This opens up automated code review, PR generation, changelog creation,
and more. But it requires careful setup to control costs, manage secrets, and
produce reliable results.

## Headless Mode

Claude Code runs non-interactively with the `--print` flag (or `-p`). This sends
a single prompt, prints the response, and exits. No conversation, no follow-up.

```bash
claude -p "Summarize the changes in this diff" < changes.diff
```

Key flags for CI usage:

```bash
# Single prompt, print result, exit
claude -p "your prompt here"

# Pipe input via stdin
git diff HEAD~1 | claude -p "Review this diff for bugs"

# Set output format for machine-readable results
claude -p "List all TODO comments" --output-format json

# Use a specific model
claude -p "Review this code" --model claude-sonnet-4-20250514
```

## GitHub Actions: Automated Code Review

A complete workflow that reviews every PR automatically.

```yaml
name: AI Code Review

on:
  pull_request:
    types: [opened, synchronize]

permissions:
  contents: read
  pull-requests: write

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Install Claude Code
        run: npm install -g @anthropic-ai/claude-code

      - name: Get PR diff
        id: diff
        run: |
          git diff origin/${{ github.base_ref }}...HEAD > pr_diff.txt

      - name: Run AI review
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          claude -p "$(cat <<'PROMPT'
          Review the following pull request diff. Focus on:
          - Bugs and logic errors
          - Security issues (injection, auth bypass, data exposure)
          - Performance problems
          - Missing error handling

          Be specific. Reference file names and line numbers.
          If the code looks good, say so briefly. Do not pad your
          review with generic advice.

          The diff:
          $(cat pr_diff.txt)
          PROMPT
          )" > review_output.txt

      - name: Post review comment
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const review = fs.readFileSync('review_output.txt', 'utf8');
            await github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              body: `## AI Code Review\n\n${review}`
            });
```

### Cost Control

CI runs can get expensive fast. Add guards:

```yaml
      - name: Check diff size
        id: size_check
        run: |
          DIFF_LINES=$(wc -l < pr_diff.txt)
          if [ "$DIFF_LINES" -gt 2000 ]; then
            echo "skip=true" >> $GITHUB_OUTPUT
            echo "Diff too large for AI review ($DIFF_LINES lines)"
          else
            echo "skip=false" >> $GITHUB_OUTPUT
          fi

      - name: Run AI review
        if: steps.size_check.outputs.skip != 'true'
        # ... rest of the step
```

Also consider:
- Run only on PRs to `main`, not feature-to-feature branches
- Use `claude-sonnet-4-20250514` instead of `claude-opus-4-0-20250115` for routine reviews (cheaper, faster)
- Cache nothing -- each run should be stateless
- Set a max-tokens limit to cap output costs

## GitLab CI: Automated Review

The same pattern adapted for GitLab CI.

```yaml
ai-review:
  stage: review
  image: node:20
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
  before_script:
    - npm install -g @anthropic-ai/claude-code
  script:
    - git diff origin/$CI_MERGE_REQUEST_TARGET_BRANCH_NAME...HEAD > diff.txt
    - |
      DIFF_LINES=$(wc -l < diff.txt)
      if [ "$DIFF_LINES" -gt 2000 ]; then
        echo "Diff too large, skipping AI review"
        exit 0
      fi
    - |
      claude -p "Review this merge request diff for bugs, security
      issues, and missing error handling. Be concise and specific.

      $(cat diff.txt)" > review.txt
    - cat review.txt
  artifacts:
    paths:
      - review.txt
    expire_in: 1 week
  variables:
    ANTHROPIC_API_KEY: $ANTHROPIC_API_KEY
```

## Automated PR Creation

Use Claude Code to create PRs from issue descriptions.

```yaml
name: Auto-implement Issue

on:
  issues:
    types: [labeled]

jobs:
  implement:
    if: contains(github.event.label.name, 'auto-implement')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Claude Code
        run: npm install -g @anthropic-ai/claude-code

      - name: Create branch
        run: |
          BRANCH="auto/issue-${{ github.event.issue.number }}"
          git checkout -b "$BRANCH"
          echo "BRANCH=$BRANCH" >> $GITHUB_ENV

      - name: Implement changes
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          claude -p "Implement the following issue. Make minimal,
          focused changes. Follow existing code patterns.

          Issue #${{ github.event.issue.number }}:
          ${{ github.event.issue.title }}

          ${{ github.event.issue.body }}"

      - name: Commit and push
        run: |
          git add -A
          git diff --cached --quiet && exit 0
          git commit -m "Auto-implement #${{ github.event.issue.number }}"
          git push -u origin "$BRANCH"

      - name: Create PR
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          gh pr create \
            --title "Auto: ${{ github.event.issue.title }}" \
            --body "Automated implementation of #${{ github.event.issue.number }}.
            **This PR was generated by AI and requires human review.**" \
            --label "ai-generated"
```

**Warning:** Auto-implementation should always create a PR for human review, never
push directly to main. Treat AI-generated PRs with the same scrutiny as code from
an unfamiliar contributor.

## Automated Changelog Generation

Generate changelogs from commit history before a release.

```bash
#!/bin/bash
# scripts/generate-changelog.sh

LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -z "$LAST_TAG" ]; then
  COMMITS=$(git log --oneline)
else
  COMMITS=$(git log "$LAST_TAG"..HEAD --oneline)
fi

claude -p "Generate a changelog from these commits. Group by:
- Features
- Bug Fixes
- Breaking Changes
- Other

Use concise, user-facing language. Skip merge commits and CI changes.
Format as Markdown.

Commits:
$COMMITS"
```

## Pre-Commit Hook

Use Claude Code as a pre-commit check for catching obvious issues. Keep it
fast -- long hooks kill developer flow.

```bash
#!/bin/bash
# .git/hooks/pre-commit

STAGED=$(git diff --cached --name-only --diff-filter=ACMR)
if [ -z "$STAGED" ]; then
  exit 0
fi

DIFF=$(git diff --cached)

# Only run on small diffs to keep it fast
DIFF_LINES=$(echo "$DIFF" | wc -l)
if [ "$DIFF_LINES" -gt 300 ]; then
  exit 0
fi

RESULT=$(echo "$DIFF" | claude -p "Quick check: are there any obvious
bugs, leaked secrets, or debug statements (console.log, print, debugger)
in this diff? Reply YES or NO, followed by a one-line explanation if YES." \
  --model claude-sonnet-4-20250514)

if echo "$RESULT" | grep -qi "^YES"; then
  echo "AI pre-commit warning:"
  echo "$RESULT"
  echo ""
  echo "Commit anyway with --no-verify to skip this check."
  exit 1
fi
```

**Cost note:** This runs on every commit. Use the cheapest viable model and keep
the prompt short. Consider making it opt-in rather than default.

## Security Scanning with AI

Augment traditional SAST tools with AI-powered analysis.

```yaml
      - name: AI security scan
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          # Focus on files changed in this PR
          FILES=$(git diff --name-only origin/main...HEAD | grep -E '\.(js|ts|py|go)$')
          if [ -z "$FILES" ]; then
            echo "No relevant files changed"
            exit 0
          fi

          for file in $FILES; do
            claude -p "Analyze this file for security vulnerabilities.
            Check for: injection flaws, broken auth, sensitive data
            exposure, XXE, broken access control, misconfigurations.
            Only report real issues, not style preferences.

            File: $file
            $(cat "$file")" >> security_report.txt
          done
```

## Cost Considerations

AI in CI adds up. Budget accordingly.

| Use Case | Model | Estimated Cost/Run | Frequency |
|---|---|---|---|
| PR review | Sonnet | $0.02-0.10 | Per PR |
| Security scan | Sonnet | $0.05-0.20 | Per PR |
| Changelog | Sonnet | $0.01-0.03 | Per release |
| Pre-commit | Haiku | $0.001-0.005 | Per commit |
| Auto-implement | Opus | $0.50-2.00 | Per issue |

**Tips to control spend:**
- Gate AI steps behind labels or file-change filters
- Set diff size limits -- do not feed 10,000-line diffs to AI
- Use cheaper models for simple checks
- Run expensive steps only on PRs to protected branches
- Monitor monthly spend with Anthropic's usage dashboard
- Consider caching results for identical diffs (rare but possible)

## Debugging CI Failures

When Claude Code behaves differently in CI than locally:

1. **Check the API key.** Most failures are auth issues.
2. **Check the prompt.** Shell variable expansion can mangle prompts in CI.
   Use heredocs or read from files.
3. **Check the diff size.** Large diffs may hit token limits silently.
4. **Check the model.** CI might default to a different model than your local setup.
5. **Add `set -x` temporarily** to see exactly what commands are running.

CI integration makes Claude Code a team-wide tool rather than an individual one.
Start with automated PR reviews -- low risk, high value -- and expand from there.
