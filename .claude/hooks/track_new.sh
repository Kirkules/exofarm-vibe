#!/usr/bin/env bash
# track_new.sh — PostToolUse hook for Write tool
# Appends NEW or REREAD entry to all five pending_*.md files.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG="$PROJECT_ROOT/.claude/code_map_config.json"
PENDING_DIR="$PROJECT_ROOT/.claude"

# Read tool input JSON from stdin
INPUT="$(cat)"
FILE_PATH="$(echo "$INPUT" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('tool_input', {}).get('file_path', ''))" 2>/dev/null || true)"

[ -z "$FILE_PATH" ] && exit 0

# Make path relative to project root
REL_PATH="${FILE_PATH#$PROJECT_ROOT/}"

# Check if file matches source patterns
matched=false
while IFS= read -r pattern; do
    if python3 -c "import fnmatch, sys; sys.exit(0 if fnmatch.fnmatch('$REL_PATH', '$pattern') else 1)" 2>/dev/null; then
        matched=true
        break
    fi
done < <(python3 -c "
import json
with open('$CONFIG') as f:
    c = json.load(f)
for p in c['source_patterns']:
    print(p)
" 2>/dev/null)

[ "$matched" = false ] && exit 0

TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%S)"

PENDING_FILES=(
    "$PENDING_DIR/pending_class-inventory.md"
    "$PENDING_DIR/pending_dep-graph.md"
    "$PENDING_DIR/pending_override-map.md"
    "$PENDING_DIR/pending_autoload-map.md"
    "$PENDING_DIR/pending_input-map.md"
)

# Determine if file is new (untracked) or an overwrite of an existing tracked file
if git -C "$PROJECT_ROOT" ls-files --error-unmatch "$FILE_PATH" > /dev/null 2>&1; then
    OP="REREAD"
else
    OP="NEW"
fi

for pending in "${PENDING_FILES[@]}"; do
    {
        echo "## $TIMESTAMP | $OP | $REL_PATH"
        echo "---"
    } >> "$pending"
done

exit 0
