# Hooks

Ready-to-use hooks for Claude Code. Copy any hook file's contents into your project's `.claude/settings.json` or `~/.claude/settings.json`.

## Available Hooks

| Hook | Event | Purpose |
|------|-------|---------|
| format-on-save | PostToolUse | Auto-format files after Claude edits them |
| test-before-commit | PreToolUse | Run tests before git commit |
| lint-after-edit | PostToolUse | Run ESLint --fix after file edits |
| notify-on-stop | Stop | Desktop notification when task completes |

## Installation

1. Copy the hook you want from its JSON file
2. Merge it into your `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [...]
  }
}
```

Or use the install script: `./install.sh hooks`

## Customization

- Change `npx prettier` to your formatter (e.g., `black` for Python, `gofmt` for Go)
- Change `npm test` to your test runner
- Change `npx eslint` to your linter
- Combine multiple hooks by merging their event arrays
