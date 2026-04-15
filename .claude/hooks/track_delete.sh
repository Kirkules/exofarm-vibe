#!/usr/bin/env bash
# track_delete.sh — PostToolUse hook for Bash tool
# Detects deleted or renamed source files via git status and appends
# DELETE or RENAME entries to all five pending_*.md files.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG="$PROJECT_ROOT/.claude/code_map_config.json"
PENDING_DIR="$PROJECT_ROOT/.claude"

TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%S)"

PENDING_FILES=(
    "$PENDING_DIR/pending_class-inventory.md"
    "$PENDING_DIR/pending_dep-graph.md"
    "$PENDING_DIR/pending_override-map.md"
    "$PENDING_DIR/pending_autoload-map.md"
    "$PENDING_DIR/pending_input-map.md"
)

# Get source patterns for filtering
PATTERNS="$(python3 -c "
import json
with open('$CONFIG') as f:
    c = json.load(f)
for p in c['source_patterns']:
    print(p)
" 2>/dev/null)"

matches_source() {
    local path="$1"
    while IFS= read -r pattern; do
        if python3 -c "import fnmatch, sys; sys.exit(0 if fnmatch.fnmatch('$path', '$pattern') else 1)" 2>/dev/null; then
            return 0
        fi
    done <<< "$PATTERNS"
    return 1
}

append_to_all() {
    local op="$1"
    local entry="$2"
    for pending in "${PENDING_FILES[@]}"; do
        {
            echo "## $TIMESTAMP | $op | $entry"
            echo "---"
        } >> "$pending"
    done
}

# Parse git status --porcelain for tracked-file events
while IFS= read -r status_line; do
    xy="${status_line:0:2}"
    rest="${status_line:3}"

    case "$xy" in
        " D"|"D ")
            # Deleted file
            if matches_source "$rest"; then
                append_to_all "DELETE" "$rest"
            fi
            ;;
        R*)
            # Renamed file: format is "old_path -> new_path" in porcelain v1
            # or "old\0new" in porcelain v2; use porcelain v1 format here
            # "R  old_path -> new_path"
            old_path="${rest% -> *}"
            new_path="${rest#* -> }"
            if matches_source "$old_path" || matches_source "$new_path"; then
                append_to_all "RENAME" "$old_path → $new_path"
            fi
            ;;
    esac
done < <(git -C "$PROJECT_ROOT" status --porcelain 2>/dev/null)

exit 0
