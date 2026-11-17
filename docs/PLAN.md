# Implementation Plan

## 1. Status and context
- Status: AGREED
- Project: WoW Forever Gear Assistant (Addon)
- Goal: Create a Pawn-like addon for the WoW Forever edition that helps players decide on the best gear using dynamic stat learning and preset weights.
- Agreement: Confirmed
- Context inspected: Web research on WoW Forever mechanics (hidden stats) and Icy Veins/Wowhead data availability.

## 2. Agreed requirements

REQ-001 — Dynamic Stat Learning: The addon must use the WoW API to fetch item stats at runtime and cache them in `SavedVariables` to handle the "hidden stats" mechanic of WoW Forever.
REQ-002 — Multi-stat Net Value Scoring: The addon must calculate a net score for an item by weighing the gains and losses of all relevant stats (e.g., Strength vs. Intellect) based on user-defined weights.
REQ-003 — Preset System: The addon must provide pre-defined weight profiles (Presets) for different classes/specs to ensure a "plug-and-play" experience.
REQ-004 — Configurable Weights: Weights must be stored in a way that allows easy updates (e.g., a dedicated configuration table) without modifying the core logic.
REQ-005 — Versatile Icon Design: The addon icon must be designed to work both as a standalone minimap icon and as a compatible element for integration into UI bars or "icon bags".
REQ-006 — UI Access: The addon must provide a way to access its features/settings via a toggleable interface.
REQ-007 — Automatic Class/Spec Detection: The UI must automatically detect the player's current class and specialization upon activation to provide relevant presets and information immediately.
REQ-008 — Contextual Spec Selection: The UI must feature a selection menu (dropdown) where the default option is the currently active specialization. The menu must only display the valid specializations for the detected class, preventing any irrelevant selections.
REQ-009 — Stat Cap & Diminishing Returns Awareness: The scoring engine must account for stat caps or diminishing returns, ensuring that adding more of a stat that is already at its effective limit provides less value.

## 3. Scope boundaries
- Included: Item stat caching, gear scoring (net value & cap-aware), preset management, basic comparison feedback, versatile icon design, toggleable UI, automatic class/spec detection, and contextual spec selection.
- Excluded: Combat rotation guides, combat log analysis, or complex character simulation.
- Existing behavior to preserve: None (New project).

## 4. Agreed design and organization
The addon should follow a modular structure:
- `Core/DataManager`: Handles API interaction and `SavedVariables` caching.
- `Core/ScoringEngine`: Handles the mathematical calculation of item scores (Net Value & Cap-aware).
- `Core/PresetManager`: Manages the loading and selection of weight profiles.
- `UI/ComparisonDisplay`: Provides visual feedback to the user when comparing items.
- `UI/MainFrame`: Handles the main menu/bag interface and minimap interaction.

## 5. Ordered builder tasks

### PL-001 — Implement Data Manager
- Requirements covered: REQ-001
- Required outcome: A system that listens for item load events and stores item stats in a local cache.
- Relevant files or modules: Proposed `DataManager.lua`
- Dependencies: None
- Completion check: Ability to print cached stats of a recently seen item to the chat.

### PL-002 — Implement Advanced Scoring Engine
- Requirements covered: REQ-002, REQ-009
- Required outcome: A sophisticated engine that calculates net value (gains vs losses) and adjusts weights based on stat caps/diminishing returns.
- Relevant files or modules: Proposed `ScoringEngine.lua`
- Dependencies: PL-001
- Completion check: Correctly identifying that an item with high Strength but also high Intellect is better than one with only Strength, and accounting for stat caps.

### PL-003 — Implement Preset and Configuration System
- Requirements covered: REQ-003, REQ-004
- Required outcome: A system to load predefined weight tables and allow the user to switch between them.
- Relevant files or modules: Proposed `PresetManager.lua` and `Config.lua`
- Dependencies: PL-002
- Completion check: Switching presets changes the calculated scores of items.

### PL-004 — Implement Basic Comparison UI
- Requirements covered: REQ-003
- Required outcome: A simple visual indicator (e.g., text on tooltip or chat message) showing if a new item is better than the current gear.
- Relevant files or modules: Proposed `UI.lua`
- Dependencies: PL-003
- Completion check: Seeing a "Better/Worse" message when hovering over a new item.

### PL-005 — Implement Versatile Icon and UI
- Requirements covered: REQ-005, REQ-006, REQ-007, REQ-008
- Required outcome: A functional, versatile icon (minimap/bar compatible) that toggles a UI which automatically detects the player's class/spec and provides a contextual dropdown menu for selection.
- Relevant files or modules: Proposed `UI.lua` and `Minimap.lua`
- Dependencies: PL-003, PL-004
- Completion check: The icon is versatile and the UI correctly identifies the player's class/spec, showing only valid spec options in the dropdown.

## 6. Verification and acceptance
- Verify that item stats are correctly cached after the first time an item is seen.
- Verify that the scoring engine correctly calculates net value (gains vs losses) and respects stat caps.
- Verify that changing a preset correctly updates the scoring of all items.
- Verify that the icon is versatile and the UI correctly identifies the player's class/spec, showing only valid spec options in the dropdown.

## 7. Open questions and unapproved proposals
- How to handle synchronization of presets if the user wants to use them across different characters?
- Should the addon include a way to automatically download updated presets from a remote source?

## 8. Builder boundaries
Implement only this plan's agreed scope. Do not add features like combat analysis or rotation guides. If implementation reveals a need for a different data structure for the cache, report it.
