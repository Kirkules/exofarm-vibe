#!/usr/bin/env bash
# track_edit.sh — PostToolUse hook for Edit tool
# Appends structured change entries to the relevant pending_*.md files.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG="$PROJECT_ROOT/.claude/code_map_config.json"
PENDING_DIR="$PROJECT_ROOT/.claude"

# Read tool input JSON from stdin
INPUT="$(cat)"
FILE_PATH="$(echo "$INPUT" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('tool_input', {}).get('file_path', ''))" 2>/dev/null || true)"

[ -z "$FILE_PATH" ] && exit 0

# Deduplication: Claude Code fires PostToolUse twice per tool call in parallel.
# mkdir is atomic on Unix — only one concurrent caller wins; the other exits cleanly.
DEDUP_KEY="$(python3 -c "import hashlib; print(hashlib.md5('$FILE_PATH'.encode()).hexdigest()[:8])")_$(date +%s)"
mkdir "/tmp/claude_hook_dedup_${DEDUP_KEY}" 2>/dev/null || exit 0

# Make path relative to project root
REL_PATH="${FILE_PATH#$PROJECT_ROOT/}"

# Check if file matches source patterns
PATTERNS="$(python3 -c "
import json
with open('$CONFIG') as f:
    c = json.load(f)
for p in c['source_patterns']:
    print(p)
" 2>/dev/null)"

matched=false
for pattern in $PATTERNS; do
    # Convert glob to find-compatible check
    dir_part="${pattern%%/**}"
    if [[ "$REL_PATH" == $pattern ]] || python3 -c "
import fnmatch, sys
sys.exit(0 if fnmatch.fnmatch('$REL_PATH', '$pattern') else 1)
" 2>/dev/null; then
        matched=true
        break
    fi
done

[ "$matched" = false ] && exit 0

# Get diff
DIFF="$(git -C "$PROJECT_ROOT" diff HEAD -- "$FILE_PATH" 2>/dev/null || true)"
[ -z "$DIFF" ] && exit 0

# Read config values
read -r -d '' PYTHON_EXTRACT <<'PYEOF' || true
import json, sys

config_path, diff = sys.argv[1], sys.stdin.read()
with open(config_path) as f:
    c = json.load(f)

autoloads = c.get('autoloads', [])
input_handlers = c.get('input_handlers', [])
project_virtuals = c.get('project_virtuals', [])

# Build known project class allowlist from class_name declarations + autoloads
# (Autoloads intentionally omit class_name to avoid Godot singleton conflicts)
import subprocess, fnmatch, os
result = subprocess.run(
    ['grep', '-rh', '^class_name ', 'scenes/', 'scripts/', '--include=*.gd'],
    cwd=os.path.dirname(os.path.dirname(config_path)),
    capture_output=True, text=True
)
project_classes = set(autoloads)  # seed with autoload names
for line in result.stdout.splitlines():
    parts = line.strip().split()
    if len(parts) >= 2:
        project_classes.add(parts[1])

import re

changes = {
    'class-inventory': [],
    'dep-graph': [],
    'override-map': [],
    'autoload-map': [],
    'input-map': [],
}
reread_all = False

for line in diff.splitlines():
    if not line or line[0] not in ('+', '-'):
        continue
    sign = line[0]
    content = line[1:]

    # Skip diff header lines
    if content.startswith('++') or content.startswith('--'):
        continue

    indented = content != content.lstrip()

    # func declaration (plain or static)
    m = re.match(r'^(?:static\s+)?func (\w+)\(([^)]*)\)(\s*->\s*\S+)?', content.strip())
    if m:
        fname = m.group(1)
        args = m.group(2)
        ret = (m.group(3) or '').strip()
        sig = f'func {fname}({args}){" " + ret if ret else ""}'
        if indented:
            reread_all = True
            break
        if fname in input_handlers:
            changes['input-map'].append(f'{sign}{sig}')
            changes['override-map'].append(f'{sign}input: {fname}')
        elif fname in project_virtuals:
            changes['override-map'].append(f'{sign}override: {fname}')
        else:
            changes['class-inventory'].append(f'{sign}{sig}')
        continue

    # signal declaration
    m = re.match(r'^signal (\w+.*)', content.strip())
    if m:
        if indented:
            reread_all = True
            break
        changes['class-inventory'].append(f'{sign}signal {m.group(1)}')
        continue

    # extends
    m = re.match(r'^extends (\w+)', content.strip())
    if m:
        if indented:
            reread_all = True
            break
        val = f'extends {m.group(1)}'
        changes['class-inventory'].append(f'{sign}{val}')
        changes['dep-graph'].append(f'{sign}{val}')
        changes['override-map'].append(f'{sign}{val}')
        continue

    # class_name
    m = re.match(r'^class_name (\w+)', content.strip())
    if m:
        if indented:
            reread_all = True
            break
        val = f'class_name {m.group(1)}'
        changes['class-inventory'].append(f'{sign}{val}')
        changes['dep-graph'].append(f'{sign}{val}')
        continue

    # typed var (dep-graph): only project-defined types
    m = re.match(r'^(?:var|@onready var|const)\s+\w+\s*:\s*([A-Z]\w*)', content.strip())
    if m:
        typename = m.group(1)
        if typename in project_classes:
            if indented:
                reread_all = True
                break
            changes['dep-graph'].append(f'{sign}dep: {typename}')
        continue

    # autoload access
    for al in autoloads:
        m = re.match(rf'^{re.escape(al)}\.([\w.]+)', content.strip())
        if m:
            if indented:
                reread_all = True
                break
            changes['autoload-map'].append(f'{sign}autoload: {al}.{m.group(1)}')
            break

if reread_all:
    print('REREAD')
else:
    import json as _json
    print(_json.dumps(changes))
PYEOF

TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%S)"

RESULT="$(echo "$DIFF" | python3 - "$CONFIG" <<< "$DIFF" 2>/dev/null || true)"
# Re-run properly: pass config path as arg, diff via stdin
RESULT="$(echo "$DIFF" | python3 -c "$PYTHON_EXTRACT" "$CONFIG" 2>/dev/null || echo "REREAD")"

append_entry() {
    local pending_file="$1"
    local content="$2"
    printf '%s\n' "$content" >> "$pending_file"
}

if [ "$RESULT" = "REREAD" ]; then
    # Write REREAD entry to all five pending files
    SECTIONS=("class-inventory" "dep-graph" "override-map" "autoload-map" "input-map")
    PENDING_NAMES=("pending_class-inventory.md" "pending_dep-graph.md" "pending_override-map.md" "pending_autoload-map.md" "pending_input-map.md")
    for i in "${!SECTIONS[@]}"; do
        PENDING="$PENDING_DIR/${PENDING_NAMES[$i]}"
        {
            echo "## $TIMESTAMP | REREAD | $REL_PATH"
            echo "---"
        } >> "$PENDING"
    done
else
    # Parse JSON result and write to relevant pending files
    python3 - "$CONFIG" "$RESULT" "$PENDING_DIR" "$TIMESTAMP" "$REL_PATH" <<'PYEOF2'
import json, sys, os

config_path, result_json, pending_dir, timestamp, rel_path = sys.argv[1:]
changes = json.loads(result_json)

section_to_pending = {
    'class-inventory': 'pending_class-inventory.md',
    'dep-graph': 'pending_dep-graph.md',
    'override-map': 'pending_override-map.md',
    'autoload-map': 'pending_autoload-map.md',
    'input-map': 'pending_input-map.md',
}

for section, lines in changes.items():
    if not lines:
        continue
    pending_file = os.path.join(pending_dir, section_to_pending[section])
    with open(pending_file, 'a') as f:
        f.write(f'## {timestamp} | EDIT | {rel_path}\n')
        for line in lines:
            f.write(line + '\n')
        f.write('---\n')
PYEOF2
fi

exit 0
