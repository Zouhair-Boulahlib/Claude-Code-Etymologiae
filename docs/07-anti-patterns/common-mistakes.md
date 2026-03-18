# Common Mistakes

> Patterns that feel productive but lead to problems. Learn from others' pain.

## 1. The Blind Accept
Approving every diff without reading it. AI-generated code can be subtly wrong in ways that compile and pass tests but break in production.

**The fix:** Read every diff. If it's too large, the task was too large. Break it down.

## 2. The Context Dump
Pasting 500 lines of logs with "fix this."

**The fix:** Extract the relevant error and explain what you're seeing.

## 3. The Infinite Loop
Going back and forth fixing one thing that breaks another, 12 rounds deep.

**The fix:** After round 3, stop. Read the code. Understand the problem. Then give one informed prompt.

## 4. The Yak Shave
AI installs a library for a 5-line task.

**The fix:** "Validate email with a regex. Don't add dependencies."

## 5. The God Prompt
One massive prompt building an entire feature at once.

**The fix:** One feature at a time, reviewed and committed before moving to the next.

## 6. The Test Afterthought
Writing all code first, then "add tests." Tests end up testing implementation, not behavior.

**The fix:** Ask for tests alongside (or before) the implementation.

## 7. The Security Bypass
"CORS is blocking, disable it." These features exist for a reason.

**The fix:** Fix the root cause. Configure CORS properly for your dev origin.

## 8. The Over-Engineered Solution
You asked for a config loader. You got 4 interfaces, 3 abstract classes, 2 registries.

**The fix:** "Simple function. No classes, no factories, just a plain object."

## 9. The Stale Context Trap
Long conversations where early code has changed but AI references the original.

**The fix:** Start new conversations at natural breakpoints.

## 10. The Undocumented Magic
AI uses framework features you don't understand.

**The fix:** "Explain why you used useImperativeHandle here."

## The Meta-Lesson
Every anti-pattern comes from treating AI as a black box instead of a collaborator. You are the engineer. The AI is your tool.

## Next Steps
- [Over-Engineering Traps](over-engineering.md)
- [Debugging AI Output](debugging-ai.md)
