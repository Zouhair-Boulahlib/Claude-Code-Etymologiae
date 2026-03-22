#!/usr/bin/env bash
set -euo pipefail

# Etymologiae Starter Kit Installer
# Usage: ./install.sh [component...] [--target <dir>]
#   Components: all, templates, hooks, commands, agents
#   --target <dir>  Install into specified directory (default: current directory)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="."
COMPONENTS=()

# Colors (respect NO_COLOR)
if [ -z "${NO_COLOR:-}" ] && [ -t 1 ]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    GREEN='' YELLOW='' RED='' BLUE='' BOLD='' NC=''
fi

info()  { echo -e "${BLUE}[info]${NC}  $1"; }
ok()    { echo -e "${GREEN}[ok]${NC}    $1"; }
warn()  { echo -e "${YELLOW}[warn]${NC}  $1"; }
err()   { echo -e "${RED}[error]${NC} $1"; }

usage() {
    cat <<EOF
${BOLD}Etymologiae Starter Kit Installer${NC}

Usage: ./install.sh [component...] [--target <dir>]

Components:
  all         Install everything (default if no component specified)
  templates   Copy CLAUDE.md templates to .claude/templates/
  hooks       Copy hook definitions to .claude/settings-hooks/
  commands    Copy slash commands to .claude/commands/
  agents      Copy agent definitions to .claude/agents/

Options:
  --target <dir>   Target project directory (default: current directory)
  --list           List available components without installing
  --dry-run        Show what would be installed without doing it
  --help           Show this help message

Examples:
  ./install.sh                     # Install everything into current project
  ./install.sh commands hooks      # Install only commands and hooks
  ./install.sh --target ~/myapp    # Install into specific project
  ./install.sh --list              # Show what's available
EOF
}

list_components() {
    echo -e "\n${BOLD}Available Components${NC}\n"

    echo -e "${BOLD}Templates${NC} (CLAUDE.md starter files):"
    for f in "$SCRIPT_DIR"/templates/claude-md-*.md; do
        [ -f "$f" ] && echo "  - $(basename "$f" .md | sed 's/claude-md-//')"
    done

    echo -e "\n${BOLD}Hooks${NC} (automation triggers):"
    for f in "$SCRIPT_DIR"/hooks/*.json; do
        [ -f "$f" ] && echo "  - $(basename "$f" .json)"
    done

    echo -e "\n${BOLD}Commands${NC} (slash commands):"
    for f in "$SCRIPT_DIR"/commands/*.md; do
        [ -f "$f" ] && [ "$(basename "$f")" != "README.md" ] && echo "  - /$(basename "$f" .md)"
    done

    echo -e "\n${BOLD}Agents${NC} (specialized subagents):"
    for f in "$SCRIPT_DIR"/agents/*.md; do
        [ -f "$f" ] && [ "$(basename "$f")" != "README.md" ] && echo "  - $(basename "$f" .md)"
    done
    echo ""
}

DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            TARGET_DIR="$2"
            shift 2
            ;;
        --list)
            list_components
            exit 0
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        all|templates|hooks|commands|agents)
            COMPONENTS+=("$1")
            shift
            ;;
        *)
            err "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Default to all if no components specified
if [ ${#COMPONENTS[@]} -eq 0 ]; then
    COMPONENTS=(all)
fi

# Expand 'all' into individual components
if [[ " ${COMPONENTS[*]} " =~ " all " ]]; then
    COMPONENTS=(templates hooks commands agents)
fi

# Resolve target directory
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd || echo "$TARGET_DIR")"

if [ ! -d "$TARGET_DIR" ]; then
    err "Target directory does not exist: $TARGET_DIR"
    exit 1
fi

echo -e "\n${BOLD}Etymologiae Starter Kit${NC}"
echo -e "Installing: ${GREEN}${COMPONENTS[*]}${NC}"
echo -e "Target:     ${BLUE}$TARGET_DIR${NC}\n"

if $DRY_RUN; then
    warn "Dry run mode — no files will be copied\n"
fi

INSTALLED=0
SKIPPED=0

copy_file() {
    local src="$1"
    local dest="$2"

    if $DRY_RUN; then
        if [ -f "$dest" ]; then
            warn "[dry-run] Would skip (exists): $(basename "$dest")"
        else
            info "[dry-run] Would copy: $(basename "$dest")"
        fi
        return
    fi

    if [ -f "$dest" ]; then
        warn "Skipping (already exists): $(basename "$dest")"
        ((SKIPPED++)) || true
        return
    fi

    cp "$src" "$dest"
    ok "Installed: $(basename "$dest")"
    ((INSTALLED++)) || true
}

# Install templates
if [[ " ${COMPONENTS[*]} " =~ " templates " ]]; then
    info "Installing CLAUDE.md templates..."
    dest_dir="$TARGET_DIR/.claude/templates"
    mkdir -p "$dest_dir"

    for f in "$SCRIPT_DIR"/templates/claude-md-*.md; do
        [ -f "$f" ] && copy_file "$f" "$dest_dir/$(basename "$f")"
    done
    echo ""
fi

# Install hooks
if [[ " ${COMPONENTS[*]} " =~ " hooks " ]]; then
    info "Installing hooks..."
    dest_dir="$TARGET_DIR/.claude/settings-hooks"
    mkdir -p "$dest_dir"

    for f in "$SCRIPT_DIR"/hooks/*.json; do
        [ -f "$f" ] && copy_file "$f" "$dest_dir/$(basename "$f")"
    done

    echo ""
    warn "Hooks are installed as reference files in .claude/settings-hooks/"
    warn "To activate a hook, merge its contents into .claude/settings.json"
    echo ""
fi

# Install commands
if [[ " ${COMPONENTS[*]} " =~ " commands " ]]; then
    info "Installing slash commands..."
    dest_dir="$TARGET_DIR/.claude/commands"
    mkdir -p "$dest_dir"

    for f in "$SCRIPT_DIR"/commands/*.md; do
        [ -f "$f" ] && [ "$(basename "$f")" != "README.md" ] && copy_file "$f" "$dest_dir/$(basename "$f")"
    done
    echo ""
fi

# Install agents
if [[ " ${COMPONENTS[*]} " =~ " agents " ]]; then
    info "Installing agent definitions..."
    dest_dir="$TARGET_DIR/.claude/agents"
    mkdir -p "$dest_dir"

    for f in "$SCRIPT_DIR"/agents/*.md; do
        [ -f "$f" ] && [ "$(basename "$f")" != "README.md" ] && copy_file "$f" "$dest_dir/$(basename "$f")"
    done
    echo ""
fi

# Summary
if ! $DRY_RUN; then
    echo -e "${BOLD}Done!${NC} ${GREEN}$INSTALLED installed${NC}, ${YELLOW}$SKIPPED skipped${NC}.\n"

    if [ $INSTALLED -gt 0 ]; then
        echo -e "Next steps:"
        echo -e "  1. Copy a CLAUDE.md template to your project root and customize it"
        echo -e "  2. Activate hooks by merging them into .claude/settings.json"
        echo -e "  3. Try a slash command: type /review in Claude Code"
        echo -e "  4. Reference an agent: 'Use the code-reviewer agent to review src/'"
        echo ""
    fi
fi
