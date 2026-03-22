# CLAUDE.md — CLI Tool Project

## Project
[PROJECT_NAME] — Command-line tool that [what it does].
Built with [Go / Rust / Python / Node.js].

## Commands
- `[build command]` — build binary
- `[test command]` — run tests
- `[install command]` — install locally
- `[PROJECT_NAME] --help` — show usage

## Architecture
- Entry point: [cmd/main.go / src/main.rs / cli.py / bin/index.ts]
- Commands in [cmd/ / src/commands/ / commands/]
- Shared utilities in [internal/ / src/lib/ / utils/]
- Configuration loading: [flags → env vars → config file → defaults]

## CLI Conventions
- Exit code 0 for success, 1 for user errors, 2 for system errors
- Stderr for errors and warnings, stdout for program output
- Support --json flag for machine-readable output
- Support --quiet and --verbose flags
- Color output respects NO_COLOR environment variable

## Code Conventions
- [Language-specific conventions]
- All user-facing messages are clear and actionable
- Long operations show progress indicators
- Destructive operations require --force or confirmation prompt

## Do NOT
- Print stack traces to users — show friendly error messages
- Require internet access for local-only operations
- Break backward compatibility in minor versions
- Hard-code paths — use OS-appropriate defaults
