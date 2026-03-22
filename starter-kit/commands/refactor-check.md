---
description: Find refactoring opportunities in a file or directory
---

Analyze the specified file or directory for refactoring opportunities:

1. **Duplication** — Code repeated in multiple places that could be extracted
2. **Long functions** — Functions over 40 lines that should be split
3. **Deep nesting** — More than 3 levels of if/else or loops
4. **God objects** — Classes/modules doing too many things
5. **Dead code** — Unused functions, variables, imports

For each finding:
- Explain what to improve and why
- Rate priority: high / medium / low
- Suggest the specific refactoring (extract function, split module, etc.)

Do NOT make changes — just report findings.
