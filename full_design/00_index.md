# ExoFarm — Game Plan
**Title: ExoFarm**

## Document Structure

The full design lives in `full_design/`, split across multiple files by topic
area (listed in the Table of Contents below, each shown with its filename).
Every file uses its own local heading hierarchy: `#` for the file's own title
(one per file), `##` for topic sections, `###` for their subsections. Don't
skip levels.

**When adding a new section:**
1. Decide which existing file it belongs to. If it doesn't fit any file
   cleanly, that's worth flagging rather than forcing — consider whether a
   new file is warranted instead.
2. Add one line to the Table of Contents below at the same time, showing both
   the section name and its filename — don't defer this.
3. Use `##` for a new topic section within a file, `###` for its subsections.

**Cross-reference links** between sections — including references within the
*same* file — always use the form `[Text](filename.md#anchor)`, always
including the filename explicitly, even for same-file references. This keeps
every link unambiguous and correct regardless of which file it's read from or
later moved to. Anchors follow standard GitHub/CommonMark slugification:
lowercase the heading text, strip characters that aren't
letters/digits/hyphens/spaces, then replace spaces with hyphens (consecutive
spaces or removed characters can produce a double hyphen — e.g.
`## Food & Nutrition` becomes `#food--nutrition`). Anchors depend only on
heading *text*, not heading *level* or which file it lives in, so moving a
section to a different file only requires updating its link's filename
prefix, not the anchor itself.

**Validating links**: run `python3 full_design/check_links.py` after any edit
that adds, moves, or renames a section — it checks every cross-reference link
in this directory against the actual headings in its target file and reports
anything broken. Run this after any batch of edits, not just once at the end.

## Table of Contents

- **[Design Principles](01_design_principles.md)**
  - [Design Principles](01_design_principles.md#design-principles)
- **[Story & World](02_story_and_world.md)**
  - [Run Structure (Roguelike)](02_story_and_world.md#run-structure-roguelike)
  - [Meta-Progression & Earth Hub](02_story_and_world.md#meta-progression--earth-hub)
  - [Background Story & Gameplay-Story Integration](02_story_and_world.md#background-story--gameplay-story-integration)
- **[Core Loop & Grid](03_core_loop_and_grid.md)**
  - [Platform & Core Loop Redesign (In Progress)](03_core_loop_and_grid.md#platform--core-loop-redesign-in-progress)
  - [Crew Selection](03_core_loop_and_grid.md#crew-selection)
  - [Farm Site Selection](03_core_loop_and_grid.md#farm-site-selection)
  - [Season Structure](03_core_loop_and_grid.md#season-structure)
  - [Technology & Progression](03_core_loop_and_grid.md#technology--progression)
- **[Buildings & Economy](04_buildings_and_economy.md)**
  - [Resources](04_buildings_and_economy.md#resources)
  - [Building Schema](04_buildings_and_economy.md#building-schema)
  - [Basic Resource Production](04_buildings_and_economy.md#basic-resource-production)
  - [Farm/Production](04_buildings_and_economy.md#farmproduction)
  - [Deposit Discovery](04_buildings_and_economy.md#deposit-discovery)
  - [Fuel](04_buildings_and_economy.md#fuel)
  - [Water](04_buildings_and_economy.md#water)
  - [Scanner Station](04_buildings_and_economy.md#scanner-station)
  - [Research Lab](04_buildings_and_economy.md#research-lab)
  - [Food/Meal Conversion](04_buildings_and_economy.md#foodmeal-conversion)
  - [Fabrication](04_buildings_and_economy.md#fabrication)
  - [Protection](04_buildings_and_economy.md#protection)
  - [Storage](04_buildings_and_economy.md#storage)
  - [Inventory](04_buildings_and_economy.md#inventory)
- **[Settlers & Exploration](05_settlers_and_exploration.md)**
  - [Settlers](05_settlers_and_exploration.md#settlers)
  - [Exploration Tasks](05_settlers_and_exploration.md#exploration-tasks)
  - [Standing Assignments](05_settlers_and_exploration.md#standing-assignments)
  - [Food & Nutrition](05_settlers_and_exploration.md#food--nutrition)
- **[Planets & Scoring](06_planets_and_scoring.md)**
  - [Exoplanet Types](06_planets_and_scoring.md#exoplanet-types)
  - [Win / Lose Conditions](06_planets_and_scoring.md#win--lose-conditions)
- **[Production & Technical](07_production_and_technical.md)**
  - [Development Standards](07_production_and_technical.md#development-standards)
  - [Art Design](07_production_and_technical.md#art-design)
  - [Code Architecture](07_production_and_technical.md#code-architecture)
  - [Backend & Data Persistence](07_production_and_technical.md#backend--data-persistence)
  - [Authentication, Security & Privacy](07_production_and_technical.md#authentication-security--privacy)
  - [Testing Strategy](07_production_and_technical.md#testing-strategy)
  - [Monetization](07_production_and_technical.md#monetization)
- **[Roadmap](08_roadmap.md)**
  - [Development Phases](08_roadmap.md#development-phases)

---

## Overview

**Engine:** Godot v4.6.1
**Genre:** Single-player roguelike grid-based farm settlement builder
**Reference:** Backpack Brawl (grid/inventory UI inspiration)
**Tone:** Cozy with low-level survival tension. Easy to pick up and start a run. Forgiving
season-to-season, but critical failures are possible. The feeling is pioneering optimism,
not desperate survival.

---

## Premise

A small team of human settlers is sent to an exoplanet ahead of a potential larger
colonization effort. Their mission: determine whether humans could live and farm there.
The player manages their farm settlement across a finite number of seasons, ultimately
producing a "report" — a score representing how well humanity could thrive on that world.

The player's home base is Earth (or an Earth-adjacent hub), from which all runs are
launched. Each run is a different exoplanet. There is always another planet to explore;
the game never signals "you are done."

Faster-than-light travel (via wormhole or similar) is established technology in this
setting. The settlement maintains contact with Earth throughout each run.
