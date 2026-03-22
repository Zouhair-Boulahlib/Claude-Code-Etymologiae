---
description: Generate tests for recently changed files
---

Look at `git diff --name-only HEAD~1` to find recently changed source files.

For each changed file that doesn't have corresponding tests:
1. Create a test file following the project's test conventions
2. Cover the happy path and 2-3 edge cases
3. Use the existing test framework and patterns found in the project

For files that already have tests, check if the changes are covered by existing tests. If not, add missing test cases.

Run the tests after writing them to verify they pass.
