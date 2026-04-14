# Code Map Workflow Design

Design document for the live code-mapping system: hooks, change tracking, and targeted updates.

Status: DESIGN — not yet implemented
Last updated: 2026-04-14

---

## Goals

1. **Correctness** (non-negotiable): Code map files always reflect actual code.
2. **Minimal token usage** (non-negotiable target): Update commands never re-read the whole codebase; ideally never re-read source files at all.
3. **Project agnosticism** (desired): The tracking mechanism and change list format are reusable across projects; only a config file is project-specific.

---

## System Overview

```
[Edit/Write/Bash tool fires]
         ↓
[PostToolUse hook: parse diff/content → append structured entries to pending_*.md files]
         ↓
[.claude/pending_*.md: one file per section, accumulates entries between update runs]
         ↓
[/update-{section}: reads only its own pending_*.md file,
 makes targeted line edits to code map file, clears pending file]
```

The hook does **syntactic extraction** (cheap, shell-based, no LLM tokens).
The update commands do **semantic classification** (reads only one pending file, no source file re-reads in the common case).

---

## Components

### 1. `pending_*.md` files — per-section change lists

Five temporary files at `.claude/`:
- `.claude/pending_class-inventory.md`
- `.claude/pending_dep-graph.md`
- `.claude/pending_override-map.md`
- `.claude/pending_autoload-map.md`
- `.claude/pending_input-map.md`

Each accumulates entries written by hook scripts. Cleared (truncated to empty) when the corresponding update command processes them.

**Entry format:**

```
## {ISO-timestamp} | {OP} | {relative/file/path.gd}
{change lines}
---
```

`{OP}` is one of: `EDIT`, `NEW`, `DELETE`, `RENAME`, `REREAD`

**Change lines for EDIT entries** (one per syntactic change detected in diff):

```
+func method_name(arg: Type) -> ReturnType
-func old_method()
+signal thing_happened(value: int)
-signal old_signal()
+extends NewParent
-extends OldParent
+class_name NewName
-class_name OldName
+dep: ClassName
-dep: ClassName
+autoload: GameState.matter
-autoload: GameState.matter
+input: _input
-input: _unhandled_input
+override: _on_merge_grid_closed
-override: _draw_grid_overlays
REREAD
```

Change lines have no section tags — each hook script writes directly to the relevant pending files based on which section each change line affects. A single EDIT to a file that changes `extends` (affects class-inventory, dep-graph, override-map) will write entries to all three of those pending files.

**NEW entry:** No change lines — the update command reads the new file in full.

```
## 2026-04-14T10:31:00 | NEW | scenes/game/new_class.gd
---
```

**DELETE entry:** No change lines — the update command removes all references to this file from the code map.

```
## 2026-04-14T10:32:00 | DELETE | scenes/game/old_file.gd
---
```

**RENAME entry:** No change lines — the update command finds all references to the old path and updates them to the new path. No source file re-read needed (content unchanged). If the class_name also changed, a separate EDIT entry from `track_edit.sh` covers that.

```
## 2026-04-14T10:35:00 | RENAME | scenes/game/old_name.gd → scenes/game/new_name.gd
---
```

**REREAD line:** Appended by the hook when a change is detected in a file but cannot be reliably parsed (e.g., changes inside function bodies that might affect type annotations). The update command re-reads only the changed file in this case — not the whole codebase, but not zero either. This is the correctness fallback.

A `REREAD` line causes the hook to write a REREAD entry to **all five** pending files (since any section may be affected).

**Full example (pending_class-inventory.md):**

```
## 2026-04-14T10:30:00 | EDIT | scenes/game/building_manager.gd
+func begin_new_thing(arg: PlaceableDefinition) -> void
-signal old_signal()
---
## 2026-04-14T10:31:00 | NEW | scenes/game/new_manager.gd
---
## 2026-04-14T10:32:00 | DELETE | scenes/game/old_overlay.gd
---
```

The same file edit may also produce an entry in `pending_dep-graph.md` (e.g., if `+dep: PlaceableDefinition` was detected), but only class-inventory-relevant changes appear in `pending_class-inventory.md`.

---

### 2. Hook scripts

Three shell scripts stored in `.claude/hooks/`:

**`track_edit.sh`** — runs PostToolUse on Edit tool
- Reads stdin JSON, extracts `tool_input.file_path`
- Checks if file matches source patterns from `code_map_config.json`
- Runs `git diff HEAD -- <file>` to get the diff
- Parses diff lines for syntactic changes (see §Hook Parsing Logic)
- For each change detected, appends to the relevant pending files based on the change type:
  - `func`, `signal`, `class_name` → `pending_class-inventory.md`
  - `extends`, `class_name` → also `pending_dep-graph.md`
  - `extends`, `func <input_handler>`, `func <project_virtual>` → also `pending_override-map.md`
  - `dep:` → `pending_dep-graph.md`
  - `autoload:` → `pending_autoload-map.md`
  - `input:` → `pending_input-map.md` and `pending_override-map.md`
  - `override:` → `pending_override-map.md`
  - `REREAD` (fallback) → all five pending files

**`track_new.sh`** — runs PostToolUse on Write tool
- Reads stdin JSON, extracts `tool_input.file_path`
- Checks if file matches source patterns
- Runs `git ls-files --error-unmatch "$file_path" 2>/dev/null` to distinguish new vs. overwrite:
  - Exit 0 (tracked): file existed before → append REREAD entry to all five pending files
  - Non-zero (untracked): genuinely new file → append NEW entry to all five pending files

**`track_delete.sh`** — runs PostToolUse on Bash tool
- Reads stdin JSON
- Runs `git status --porcelain` and filters for source file patterns from `code_map_config.json`
- For `^D ` entries: appends DELETE entry to all five pending files
- For `^R ` entries (renames via `git mv`): appends RENAME entry to all five pending files
- Fallback: plain `mv` produces `^D ` + `^?? ` entries; only the DELETE side is tracked (the new file will be absent from the code map until the next full update — not silent corruption, just an incomplete entry)
- No-op if no tracked source files were affected

---

### 3. Hook configuration — `settings.json`

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit",
        "hooks": [{"type": "command", "command": "bash .claude/hooks/track_edit.sh"}]
      },
      {
        "matcher": "Write",
        "hooks": [{"type": "command", "command": "bash .claude/hooks/track_new.sh"}]
      },
      {
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": "bash .claude/hooks/track_delete.sh"}]
      }
    ]
  }
}
```

---

### 4. Project config — `.claude/code_map_config.json`

This is the **only project-specific file** in the tracking system. The hook scripts and update commands read from it; changing it adapts the system to a new project.

```json
{
  "source_patterns": [
    "scenes/**/*.gd",
    "scripts/**/*.gd"
  ],
  "autoloads": ["GameState", "EventBus", "Catalog", "Settings"],
  "input_handlers": ["_input", "_unhandled_input", "_gui_input"],
  "project_virtuals": [
    "_on_merge_grid_closed",
    "_draw_grid_overlays",
    "_can_place_at_cell"
  ],
  "code_map_sections": {
    "class-inventory": ".claude/code_map_classes.md",
    "dep-graph": ".claude/code_map_deps.md",
    "override-map": ".claude/code_map_overrides.md",
    "autoload-map": ".claude/code_map_autoloads.md",
    "input-map": ".claude/code_map_input.md"
  }
}
```

To adapt to a new project: update `source_patterns`, `autoloads`, `input_handlers`, `project_virtuals`, and `code_map_sections` to match the new project's structure.

---

### 5. Hook parsing logic (for `track_edit.sh`)

The script parses `git diff HEAD -- <file>` output. Lines beginning with `+` (added) or `-` (removed) are scanned with the following patterns. Each match produces one change line written to the relevant pending file(s).

| Pattern (regex on diff line) | Change line produced | Pending files written |
|------------------------------|---------------------|----------------------|
| `^[+-]func (\w+)\(([^)]*)\)( -> \S+)?:?$` | `±func name(args) -> ret` | class-inventory |
| `^[+-]signal (\w+)` | `±signal name(args)` | class-inventory |
| `^[+-]extends (\w+)` | `±extends Name` | class-inventory, dep-graph, override-map |
| `^[+-]class_name (\w+)` | `±class_name Name` | class-inventory, dep-graph |
| `^[+-]\s*var \w+:\s*([A-Z]\w+)` (uppercase type = project class) | `±dep: ClassName` | dep-graph |
| `^[+-]\s*(AUTOLOAD)\.([\w.]+)` (AUTOLOAD from config) | `±autoload: Name.property` | autoload-map |
| `^[+-]func (INPUT_HANDLER)\(` (from config) | `±input: handler_name` | input-map, override-map |
| `^[+-]func (PROJECT_VIRTUAL)\(` (from config) | `±override: method_name` | override-map |

If any matched line falls inside a function body (indented), write `REREAD` to all five pending files instead — body-level changes (local variable types, inline autoload accesses) are too noisy to parse reliably from a diff.

If no lines match any pattern but the file did change, write `REREAD` to all five pending files as a fallback.

**Project class allowlist:** At invocation time, `track_edit.sh` builds the set of known project class names by running:
```
grep -rh "^class_name " scenes/ scripts/ --include="*.gd" | awk '{print $2}'
```
Only type annotations matching a name in this set are recorded as dep-graph edges. This avoids false positives from Godot built-in types (which do not declare `class_name`).

---

### 6. Update command behavior

Each `/update-{section}` command works as follows:

1. Read the corresponding `pending_{section}.md` file
2. If empty or absent: nothing to do — report "No pending changes for {section}"
3. For each entry in the pending file:
   - **EDIT with change lines**: apply targeted edits to the code map file based on the change lines — no source file re-read
   - **NEW**: re-read the new source file in full, add its entry to the code map
   - **DELETE**: remove all references to the deleted file from the code map
   - **RENAME**: find all references to the old path in the code map and update them to the new path — no source file re-read
   - **REREAD**: re-read only the affected source file, update the relevant section of the code map
4. Apply **idempotency checks** before writing: if the change line to be added already exists in the code map (same text, same file), skip it. This prevents duplicate entries if a pending file is processed twice (e.g., session crash before clearing).
5. Clear `pending_{section}.md` (truncate to empty) after all entries are processed.

The update command **never reads source files it wasn't directed to** by its pending file.

---

### 7. Entry clearing

Each pending file is independent. An entry in `pending_class-inventory.md` is cleared when `/update-class-inventory` runs — regardless of whether any other section's pending file has been processed. There is no shared state between pending files.

**Example:**

An edit to `building_manager.gd` that adds a new func and a new dep causes:
- `pending_class-inventory.md` gets: `+func begin_new_thing(...)`
- `pending_dep-graph.md` gets: `+dep: PlaceableDefinition`

Running `/update-class-inventory` reads and clears `pending_class-inventory.md`. `pending_dep-graph.md` is untouched until `/update-dep-graph` runs.

Running `/update-code-map` (umbrella) processes all five pending files in sequence, clearing each one after it is processed.

**NEW and DELETE entries** appear in all five pending files (written by the hook). They are independently cleared when each section's update command runs.

---

### 8. Project agnosticism

The following components are **fully project-agnostic** (no project-specific logic):
- `track_edit.sh`, `track_new.sh`, `track_delete.sh` — read all patterns from config
- `pending_*.md` format
- Entry clearing logic
- The general structure of update command behavior

The following are **project-specific**:
- `code_map_config.json` — source patterns, autoload names, virtual methods
- The code map files themselves (`.claude/code_map_*.md`)
- The update command skill files (they describe the code map structure)

To bring this workflow to a new project:
1. Copy the three hook scripts and `settings.json` hook config
2. Write a `code_map_config.json` for the new project
3. Create the code map files appropriate for that project's language/structure
4. Write update command skills describing the new code map format

---

## Implementation Plan

1. Write `code_map_config.json` for ExoFarm
2. Write and test `track_edit.sh`
3. Write and test `track_new.sh`
4. Write and test `track_delete.sh`
5. Add hook entries to `settings.json`
6. Rewrite the five `/update-{section}` skill files to use the new pending-file-driven behavior (with REREAD fallback and idempotency checks)
7. Update `/update-code-map` umbrella to process and clear all five pending files

---

## Open Questions

- **Dep-graph type identification (RESOLVED)**: Rather than an exclusion list of Godot built-ins, the hook uses an allowlist: at invocation time, run `grep -rh "^class_name " scenes/ scripts/ --include="*.gd" | awk '{print $2}'` to build the set of known project class names. Only type annotations matching a name in this set are recorded as dep-graph edges. This works because all project scripts declare `class_name` (enforced by CLAUDE.md), while Godot built-ins do not.
- **Rename detection (RESOLVED)**: Source file renames must use `git mv` (enforced by CLAUDE.md convention). `track_delete.sh` detects `^R ` entries in git status and produces RENAME entries. Plain `mv` falls back to DELETE-only (new file absent from code map until next full update — acceptable).
- **Write tool on existing files (RESOLVED)**: `track_new.sh` runs `git ls-files --error-unmatch` to distinguish new (untracked) files from overwrites of existing (tracked) files. Untracked → NEW entry; tracked → REREAD entry.
- **Entry clearing (RESOLVED)**: Five separate `pending_{section}.md` files (one per code map section). Each hook script writes directly to the relevant pending files based on which section each change type affects. Each update command reads and clears only its own pending file. Idempotency: update commands check before applying to prevent duplicate entries if a pending file is processed twice.
