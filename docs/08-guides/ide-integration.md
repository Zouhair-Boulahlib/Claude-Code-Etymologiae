# IDE Integration Deep Dives

> Claude Code lives in the terminal. Your IDE lives everywhere else. The best workflow uses both -- and never confuses which tool does what.

## The Core Principle

IDEs are superior at navigation, autocomplete, syntax highlighting, and refactoring symbols. Claude Code is superior at understanding intent, reading across files, generating non-trivial code, and executing multi-step tasks. Stop trying to make one replace the other. Use them together.

## VS Code Integration

### Terminal Setup

VS Code's integrated terminal is where most people run Claude Code. A few settings make this dramatically better.

Open `settings.json` and add:

```json
{
  "terminal.integrated.defaultProfile.linux": "bash",
  "terminal.integrated.fontSize": 13,
  "terminal.integrated.scrollback": 10000,
  "terminal.integrated.enablePersistentSessions": true
}
```

### The Split Pane Workflow

The most productive VS Code layout for Claude Code work:

1. **Left pane** -- your editor, open to the file you're working on
2. **Bottom pane** -- Claude Code terminal session
3. **Right pane** (optional) -- a second terminal for running tests, servers, or git

Set this up with keyboard shortcuts:

```
Ctrl+`          -- toggle terminal panel
Ctrl+Shift+`    -- create new terminal
Ctrl+Shift+5    -- split terminal horizontally
Ctrl+\          -- split editor vertically
```

When Claude Code modifies a file, VS Code detects the change and reloads it automatically. You see the diff in real time in your editor while the conversation continues in the terminal below.

### VS Code Tasks for Claude Code

Create `.vscode/tasks.json` to invoke Claude Code for common operations:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Claude: Review Current File",
      "type": "shell",
      "command": "claude",
      "args": ["-p", "Review this file for bugs, style issues, and potential improvements: ${file}"],
      "presentation": {
        "reveal": "always",
        "panel": "dedicated"
      }
    },
    {
      "label": "Claude: Write Tests for Current File",
      "type": "shell",
      "command": "claude",
      "args": ["-p", "Write unit tests for ${file}. Follow existing test patterns in the project."],
      "presentation": {
        "reveal": "always",
        "panel": "dedicated"
      }
    },
    {
      "label": "Claude: Explain Function",
      "type": "shell",
      "command": "claude",
      "args": ["-p", "Explain what the function at line ${lineNumber} in ${file} does. Be specific about edge cases."],
      "presentation": {
        "reveal": "always",
        "panel": "dedicated"
      }
    }
  ]
}
```

Bind these to keyboard shortcuts in `keybindings.json`:

```json
[
  {
    "key": "ctrl+shift+r",
    "command": "workbench.action.tasks.runTask",
    "args": "Claude: Review Current File"
  },
  {
    "key": "ctrl+shift+t",
    "command": "workbench.action.tasks.runTask",
    "args": "Claude: Write Tests for Current File"
  }
]
```

---

## JetBrains Integration (IntelliJ, WebStorm, PyCharm)

### Terminal Setup

JetBrains IDEs have a capable built-in terminal. Open it with `Alt+F12`. Claude Code runs here with no special configuration.

For a better experience, increase the terminal buffer:

**Settings > Tools > Terminal > Shell tab width** -- set scrollback to at least 5000 lines.

### JetBrains AI vs Claude Code

JetBrains ships its own AI assistant. Here is when to use each:

| Task | JetBrains AI | Claude Code |
|------|-------------|-------------|
| Inline code completion | Yes | No |
| Single-line suggestions | Yes | No |
| Multi-file refactoring | Limited | Yes |
| Understanding project architecture | No | Yes |
| Writing tests from scratch | Basic | Yes |
| Explaining complex code | Basic | Detailed |
| Git commit messages | Yes | Yes |
| Executing shell commands | No | Yes |

The practical rule: let JetBrains AI handle the small stuff (autocomplete, quick fixes). Reach for Claude Code when the task requires reading multiple files, reasoning about architecture, or producing more than a few lines of code.

### The JetBrains Workflow

1. Use **Find in Files** (`Ctrl+Shift+F`) to locate what you need
2. Use **Navigate to Symbol** (`Ctrl+Alt+Shift+N`) to jump to definitions
3. Switch to the terminal (`Alt+F12`) and tell Claude Code what to do
4. Use **Local History** (`Right-click > Local History > Show History`) as a safety net -- JetBrains tracks every file change, including those made by Claude Code

---

## Neovim Integration

### Terminal Splits

Neovim's built-in terminal works well for Claude Code sessions:

```vim
" Open Claude Code in a horizontal split
:split | terminal claude

" Open Claude Code in a vertical split
:vsplit | terminal claude

" Useful keybindings for your init.lua or init.vim
nnoremap <leader>cc :vsplit \| terminal claude<CR>
nnoremap <leader>ct :split \| terminal claude<CR>
```

To switch between the editor and the Claude Code terminal:

```
Ctrl+w h/j/k/l   -- move between splits
Ctrl+w =          -- equalize split sizes
Ctrl+\ Ctrl+n     -- exit terminal mode back to normal mode
i                  -- re-enter terminal mode to type
```

### Tmux Integration

For serious Neovim users, tmux provides a more robust setup than Neovim's built-in terminal:

```bash
# .tmux.conf additions for Claude Code work
set -g mouse on
set -g history-limit 50000

# Split pane with Claude Code session
bind C split-window -h 'claude'

# Quick switch between editor and Claude Code
bind h select-pane -L
bind l select-pane -R
```

The typical tmux layout:

```
+-------------------+-------------------+
|                   |                   |
|   Neovim          |   Claude Code     |
|   (editing)       |   (conversation)  |
|                   |                   |
+-------------------+-------------------+
|          tests / server / logs        |
+---------------------------------------+
```

Create this layout with a script:

```bash
#!/bin/bash
# dev-session.sh -- launch a tmux development session
SESSION="dev"

tmux new-session -d -s $SESSION -n main
tmux split-window -h -t $SESSION:main
tmux send-keys -t $SESSION:main.1 'claude' C-m
tmux split-window -v -t $SESSION:main.0
tmux send-keys -t $SESSION:main.2 'npm run dev' C-m
tmux select-pane -t $SESSION:main.0
tmux attach -t $SESSION
```

---

## The Hybrid Workflow

The highest-productivity pattern combines IDE strengths with Claude Code strengths in a deliberate sequence.

### For Understanding Code

1. **IDE**: Use Go to Definition, Find References, Call Hierarchy to build a mental map
2. **Claude Code**: "Explain the data flow from the API endpoint in `routes/orders.ts` through to the database write. What validations happen along the way?"

### For Writing New Code

1. **IDE**: Create the file, write the imports, scaffold the structure
2. **Claude Code**: "Implement the `OrderService.processRefund` method. Follow the pattern in `processPayment` but handle partial refunds."
3. **IDE**: Use autocomplete and type checking to fix any small issues

### For Debugging

1. **IDE**: Set breakpoints, inspect variables, identify the problem area
2. **Claude Code**: "The `calculateDiscount` function returns NaN when the cart has items with zero quantity. The relevant code is in `src/services/pricing.ts`. Explain why and fix it."

### For Refactoring

1. **IDE**: Use Rename Symbol for simple renames (faster, safer)
2. **Claude Code**: Use for structural refactors -- extracting classes, changing patterns, migrating APIs

---

## When to Use Copilot vs Claude Code

GitHub Copilot and Claude Code serve different purposes. Use both.

**Use Copilot for:**
- Line-by-line completion as you type
- Boilerplate code (constructors, getters, simple functions)
- Repetitive patterns (writing the fifth similar API endpoint)
- Inline documentation strings

**Use Claude Code for:**
- Tasks that require reading existing code first
- Multi-file changes that need consistency
- Anything that requires reasoning ("why is this broken?")
- Tasks you'd describe in a sentence, not a keystroke

They do not compete. Copilot works at the keystroke level. Claude Code works at the task level.

---

## Terminal Multiplexer Patterns

### Persistent Sessions with tmux

Claude Code sessions are valuable. A long conversation has accumulated context. Use tmux to keep sessions alive:

```bash
# Start a named session
tmux new -s project-name

# Detach without killing
Ctrl+b d

# Reattach later
tmux attach -t project-name

# List all sessions
tmux ls
```

### Screen as an Alternative

```bash
# Start a named session
screen -S project-name

# Detach
Ctrl+a d

# Reattach
screen -r project-name
```

Both tmux and screen survive SSH disconnections, accidental terminal closes, and system sleep/wake cycles. Your Claude Code conversation keeps running.

---

## Keyboard Shortcut Cheat Sheet

### VS Code + Claude Code

| Action | Shortcut |
|--------|----------|
| Toggle terminal | `Ctrl+`` ` |
| New terminal | `Ctrl+Shift+`` ` |
| Split terminal | `Ctrl+Shift+5` |
| Focus editor | `Ctrl+1` |
| Focus terminal | `Ctrl+`` ` |
| Open file by name | `Ctrl+P` |
| Go to symbol | `Ctrl+Shift+O` |
| Find in files | `Ctrl+Shift+F` |

### Neovim + tmux

| Action | Shortcut |
|--------|----------|
| Switch tmux pane | `Ctrl+b arrow` |
| Split tmux horizontal | `Ctrl+b "` |
| Split tmux vertical | `Ctrl+b %` |
| Exit Neovim terminal mode | `Ctrl+\ Ctrl+n` |
| Neovim split | `:split` / `:vsplit` |
| Neovim file finder | `:Telescope find_files` |

### General Terminal

| Action | Shortcut |
|--------|----------|
| Clear terminal | `Ctrl+L` |
| Search command history | `Ctrl+R` |
| Cancel current command | `Ctrl+C` |
| Send EOF | `Ctrl+D` |

---

## File Navigation: IDE Finds, Claude Code Understands

The most efficient pattern for working with unfamiliar code:

1. Use your IDE's file tree or fuzzy finder to locate candidate files
2. Open them in the editor to scan visually
3. Ask Claude Code to explain the relationships between what you found:

```
I found these files that seem related to payment processing:
- src/services/payment-service.ts
- src/services/stripe-client.ts
- src/models/payment.ts
- src/api/routes/payments.ts

Explain how they connect. What's the call flow for a new payment?
```

This is faster than asking Claude Code to search for files (which it can do, but your IDE's indexing is instant). And it is faster than trying to trace the code yourself (which Claude Code does in seconds).

Use each tool for what it does best.
