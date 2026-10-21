# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Amber's Dialog System is a visual dialog/narrative editor built in Godot 4.1+. It uses a GraphEdit-based architecture where dialog flows are represented as interconnected nodes, exporting to JSON format for use in games.

**Main Entry Point:** `Editor.tscn` / `Editor.gd`

## Running the Project

Open in Godot 4.1+ and run. No build step required - it's a Godot project.

## Architecture

### Node-Orchestration Pattern

The system uses a central orchestrator pattern:
- **Editor.gd** (1,268 lines) - Central controller managing the entire graph
- Each node type manages its own data via `node_data` dictionaries
- Data flows through `node_stack` dictionary tracking nodes by type

### Node Types (tracked in Editor.node_stack)

| Type | File | Purpose |
|------|------|---------|
| DIALOG | GraphNode.gd | Narrative dialog lines with paperdoll system |
| EVENT | EventNode.gd | Complex events: splits, checks, wardrobe, subtrees, reactions |
| LOGIC | Feature.gd | Conditionals and variable operations |
| CHOICE | Option.gd | Player choice branches |
| IMAGE | ImageNode.gd | Paperdoll/image display |
| TRANSITION | Transition.gd | Scene/locale transitions |
| APPEND | AppendNode.gd | Text append nodes |
| OFFRAMP | Offramp.gd | Exit points to other files/trees |
| ONRAMP | Onramp.gd | Entry points from other files |

### Key Patterns

1. **Node Factory:** `Editor.get_new_node(type)` creates nodes
2. **Signal-Based Cleanup:** Nodes emit signals to parent, use `get_parent().remove_node(self)` pattern
3. **Serialization:** All state in `node_data` dictionaries, compiled via `compile_nodes_into_json()`
4. **Node Naming:** `{TYPE}_{INDEX}` format (e.g., `DIALOG_001`, `EVENT_042`)

### Data Persistence (FileDialog.gd)

- Saves to `{exe_dir}/DialogEditSaves/`
- Mirror save to `{exe_dir}/XLUtilities/inbox/` for external tools
- JSON stringification of complete node graph

## Text Syntax Highlighting (CodeEdit.gd)

These patterns are highlighted in dialog text:
- `| {emoji_name} |` - Emoji insertion
- `<< {expression} >>` - Character expressions
- `!! {signal} !!` - Signal emission
- `+({variables})` / `-({variables})` - Variable manipulation
- `+ {inventory} +` / `- {inventory} -` - Inventory changes

## Keyboard Shortcuts

- **Ctrl/Cmd + S** - Save file
- **Ctrl/Cmd + O** - Open file
- **Ctrl/Cmd + N** - New file
- **Ctrl/Cmd + D** - Duplicate selected
- **Ctrl/Cmd + 0** - Go to start
- **Ctrl/Cmd + E** - Go to end
- **Right Click** - New node
- **Alt + F** - New feature node
- **Del** - Delete selected nodes

## Important Files for Common Tasks

- **Adding new node types:** Study `EventNode.gd` (most complex), create paired `.gd` + `.tscn`, add to `Editor.get_new_node()`
- **Modifying serialization:** `Editor.compile_nodes_into_json()`, ensure `update_data()` is called on nodes
- **UI themes:** `Assets/UI/*.tres`
- **Choice icons:** `Assets/UI/choice_icon/` (100+ emoji icons)

## Headless Layout Tool (LayoutTool.gd)

Lets dialog trees be written as JSON outside the editor without their nodes overlapping. `layout.bat` runs this project headless with the 4.1 console build from the sibling `harem-heaven/executable/`. It loads the tree through the editor's normal load path, so node sizes come from the real scenes and follow any future change to them.

```
layout.bat --layout=act/eden/my_tree --place --check
```

- `--layout=` takes a path relative to `DialogEditSaves` (`.json` optional), or an absolute path.
- `--place` positions every node that has no `offset_x`/`offset_y`. A node goes right of the node that leads into it (left of the node it leads to if nothing leads in, or below everything if neither). Positions snap to the 20px grid, with at least `--gap` (default 40px, two snaps) to every other node. Spacing is measured against what each node actually draws, which matters for the editor's cheat sheet: its text spills about 1100px below its frame. Nodes that already have a position are never moved. It writes the offsets, plus `size_x`/`size_y` for every node, back to the file, and to the `XLUtilities/inbox/` copy when the file is under `DialogEditSaves`. `--dry-run` skips the write.
- `--check` lists node pairs closer than `--gap` (negative means overlapping), and menus whose choices don't run top to bottom in their DIALOG's "go to" order. It exits 1 if it finds either. Its scope is the nodes placed in this run, else the nodes named in `--nodes=A,B`, else every node.
- Menu order matters because the game sorts a menu's choices by each CHOICE's `offset_y`. `--place` keeps a new menu in "go to" order: siblings stack downward, and a gate (LOGIC leading to a CHOICE) gets its choice placed before the next sibling. When adding a choice to an existing menu, put it in the right position in the DIALOG's "go to" list and let `--check` confirm the result.
- Look for output lines starting `[layout]`; the editor's own `print(dialog)` adds a lot of noise around them.
- Headless runs in a 64x64 window, which under the project's `canvas_items` stretch skews font oversampling and inflates text heights about 2x. `Editor._enter_tree()` turns off content scaling in layout mode, after which measured sizes match the windowed editor exactly.

Every node's `update_data()` saves its laid-out `size_x`/`size_y`. On load they are restored once the first layout pass has settled. Control sizes never go below their content's minimum, so a node whose content has since grown still fits. This also keeps nodes the user resized at their resized size after reopening the file.

## Known Bugs

- Connections sometimes don't link properly when opening old files
- Crashes when creating/opening files while another is open

## Development Notes

- Each node type has paired `.gd` script and `.tscn` scene
- Always call `update_data()` on nodes before serialization
- JSON format changes affect backward compatibility with saved files
- `Global.gd` is an autoload singleton for shared state
