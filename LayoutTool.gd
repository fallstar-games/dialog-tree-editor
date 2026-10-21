extends RefCounted
# Headless layout mode: loads a dialog tree through the real editor, measures every
# node's laid-out bounds, and places/checks nodes so none overlap. Lets trees be
# authored as JSON without opening the editor.
#
#   layout.bat --layout=<tree> [--place] [--check] [--dry-run] [--nodes=A,B] [--gap=40]
#
# <tree> is absolute, or relative to DialogEditSaves (".json" optional).
# --place    Positions every node that has no offset_x/offset_y in the file, right of
#            the node that leads into it (or left of the node it leads to), on the
#            snap grid, at least --gap from every other node. Nodes that already have
#            a position are never moved. Writes offsets plus size_x/size_y for all
#            nodes back to the file, and to the XLUtilities/inbox mirror when the file
#            is under DialogEditSaves. --dry-run reports without writing.
# --check    Lists node pairs closer than --gap (negative = overlapping), and menus
#            whose choices don't run top to bottom in "go to" order (the game orders
#            a menu by offset_y). Scope: the nodes placed this run, else --nodes, else
#            every node. Exits 1 if anything is found.
#
# Output lines are prefixed "[layout]"; the editor's own prints are noise.

const SNAP := 20 # GraphEdit's default snapping_distance (Editor.tscn doesn't override it)
const DEFAULT_GAP := SNAP * 2
const COLUMN_GAP := SNAP * 4 # horizontal step between a node and the next in its chain
const MAX_SEARCH_STEPS := 2000 # snap steps tried in a column before giving up on a spot
const WATCHDOG_SECONDS := 120

# Nodes the editor positions itself on load, so their bounds don't belong in the check
const IGNORED_NODES := ["End"]

var editor: GraphEdit
var args := {}
var gap := DEFAULT_GAP
var raw := {} # the tree exactly as read from disk; only offsets/sizes get written back
var rects := {} # node name -> Rect2 in canvas space, as drawn (see _drawn_rect)
var node_sizes := {} # node name -> the node's own size, which is what gets saved
var placed: Array[String] = []

static func get_args() -> Dictionary:
	var out := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv = a.substr(2).split("=", true, 1)
			out[kv[0]] = kv[1] if kv.size() > 1 else ""
	return out

static func is_requested() -> bool:
	return get_args().has("layout")

func run(_editor: GraphEdit) -> void:
	editor = _editor
	args = get_args()
	gap = int(args.get("gap", DEFAULT_GAP))
	# A load that never finishes would otherwise leave a headless process running forever
	editor.get_tree().create_timer(WATCHDOG_SECONDS).timeout.connect(func():
		_log("ERROR timed out after %ds" % WATCHDOG_SECONDS)
		editor.get_tree().quit(3))
	var code := await _run()
	editor.get_tree().quit(code)

func _run() -> int:
	var path := _resolve_path(args["layout"])
	if not FileAccess.file_exists(path):
		_log("ERROR file not found: " + path)
		return 2
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		_log("ERROR not a dialog tree: " + path)
		return 2
	raw = parsed

	# Load through the editor's own path so sizes come from the real scenes
	await editor.get_tree().process_frame
	editor.selected_file_path = path
	editor._on_file_dialog_load_file()
	await editor.graph_loaded
	await editor.get_tree().process_frame
	_measure()
	_log("loaded %s (%d nodes)" % [path, rects.size()])

	if args.has("place"):
		_place()
		if not args.has("dry-run"):
			_write(path)

	if args.has("check"):
		return _check()
	return 0

func _resolve_path(p: String) -> String:
	p = p.replace("\\", "/")
	if not p.ends_with(".json"):
		p += ".json"
	if p.is_absolute_path():
		return p
	return Global.get_save_dir().path_join(p)

func _measure() -> void:
	for child in editor.get_children():
		if child is GraphNode and child.visible and not String(child.name) in IGNORED_NODES:
			rects[String(child.name)] = _drawn_rect(child)
			node_sizes[String(child.name)] = child.size

# A node's own rect grown to cover any visible content drawn outside it. Tree nodes
# fit their content, but the editor's cheat sheet draws its text far below its frame.
func _drawn_rect(node: GraphNode) -> Rect2:
	var r := Rect2(node.position_offset, node.size)
	var stack: Array = node.get_children()
	while not stack.is_empty():
		var d = stack.pop_back()
		stack.append_array(d.get_children())
		if d is Control and d.is_visible_in_tree():
			var offset: Vector2 = (d.global_position - node.global_position) / editor.zoom
			r = r.merge(Rect2(node.position_offset + offset, d.size))
	return r

func _is_unplaced(n: String) -> bool:
	return raw.has(n) and raw[n] is Dictionary and not (raw[n].has("offset_x") and raw[n].has("offset_y"))

######## Placement ########

func _place() -> void:
	var pending: Array[String] = []
	for n in raw.keys():
		if _is_unplaced(n) and rects.has(n):
			pending.append(n)
	pending.sort()
	if pending.is_empty():
		_log("place: nothing to place")
		return
	# Unplaced nodes must not act as obstacles at the editor's default spawn spot
	for n in pending:
		rects.erase(n)
	var sizes := {}
	for n in pending:
		sizes[n] = editor.get_node(n).size

	# Walk forward from positioned nodes, so a chain fans out left to right. A node's
	# first new target goes in the nearest free spot level with it; later ones stack
	# below that, so siblings read top to bottom in "go to" order. A gate (LOGIC
	# leading to a CHOICE) gets its choice placed straight away and the next sibling
	# goes below both, since the game orders a menu by each CHOICE's offset_y
	var queue: Array[String] = []
	for n in raw.keys():
		if rects.has(n):
			queue.append(n)
	queue.sort()
	while not pending.is_empty():
		while not queue.is_empty():
			var from: String = queue.pop_front()
			var r: Rect2 = rects[from]
			var below := -INF # bottom of the last target placed for `from`
			for to in _targets(from):
				if to in pending:
					var x := _snap_up(r.end.x + COLUMN_GAP)
					if below == -INF:
						_put(to, sizes[to], x, r.position.y, false)
					else:
						_put(to, sizes[to], x, below + gap, true)
					below = rects[to].end.y
					pending.erase(to)
					queue.append(to)
					for n in _gate_chain(to, pending):
						var g: Rect2 = rects[queue.back()]
						_put(n, sizes[n], _snap_up(g.end.x + COLUMN_GAP), g.position.y, true)
						below = max(below, rects[n].end.y)
						pending.erase(n)
						queue.append(n)
		if pending.is_empty():
			break
		# Nothing positioned leads into what's left: anchor on a positioned node it
		# leads to, else start a fresh row below everything
		var n: String = _pick_root(pending)
		var succ := ""
		for to in _targets(n):
			if rects.has(to):
				succ = to
				break
		if succ != "":
			var r: Rect2 = rects[succ]
			_put(n, sizes[n], _snap_down(r.position.x - COLUMN_GAP - sizes[n].x), r.position.y, false)
		else:
			var bounds := _bounds()
			_put(n, sizes[n], _snap_down(bounds.position.x), bounds.end.y + COLUMN_GAP, true)
		pending.erase(n)
		queue.append(n)

# The unplaced LOGIC gates and CHOICE that follow `from`, when its single-target
# chain ends in a CHOICE; empty otherwise
func _gate_chain(from: String, pending: Array[String]) -> Array[String]:
	var chain: Array[String] = []
	var cur := from
	while cur.begins_with("LOGIC_") and _targets(cur).size() == 1:
		var next: String = _targets(cur)[0]
		if not next in pending or next in chain:
			return []
		chain.append(next)
		if next.begins_with("CHOICE_"):
			return chain
		cur = next
	return []

func _pick_root(pending: Array[String]) -> String:
	for n in pending:
		if n.begins_with("ONRAMP_"):
			return n
	return pending[0]

func _targets(n: String) -> Array:
	if raw.has(n) and raw[n] is Dictionary and raw[n].get("go to") is Array:
		return raw[n]["go to"]
	return []

# Search the column in snap steps for the nearest spot that clears everything by
# `gap`: alternating below/above y (below first), or only below when down_only
func _put(n: String, size: Vector2, x: float, y: float, down_only: bool) -> void:
	var base := _snap_up(y)
	var r := Rect2(Vector2(x, base), size)
	var found := false
	for i in MAX_SEARCH_STEPS:
		var steps: int = i if down_only else int(ceil(i / 2.0)) * (1 if i % 2 == 1 else -1)
		r.position.y = base + steps * SNAP
		if _first_conflict(r) == "":
			found = true
			break
	if not found:
		_log("WARNING no free spot found for %s; check will flag it" % n)
	rects[n] = r
	placed.append(n)
	editor.get_node(n).position_offset = r.position
	_log("placed %s at (%d, %d)" % [n, r.position.x, r.position.y])

func _first_conflict(r: Rect2) -> String:
	for other in rects:
		if _gap_between(r, rects[other]) < gap:
			return other
	return ""

func _bounds() -> Rect2:
	var b := Rect2()
	var first := true
	for n in rects:
		b = rects[n] if first else b.merge(rects[n])
		first = false
	return b

# Separation along whichever axis separates the rects; negative when they overlap
static func _gap_between(a: Rect2, b: Rect2) -> float:
	var gx = max(b.position.x - a.end.x, a.position.x - b.end.x)
	var gy = max(b.position.y - a.end.y, a.position.y - b.end.y)
	return max(gx, gy)

static func _snap_up(v: float) -> float:
	return ceil(v / SNAP) * SNAP

static func _snap_down(v: float) -> float:
	return floor(v / SNAP) * SNAP

######## Check ########

func _check() -> int:
	var scope: Array = placed.duplicate()
	if scope.is_empty() and args.get("nodes", "") != "":
		scope = Array(args["nodes"].split(",", false))
	var names := rects.keys()
	names.sort()
	var bad := 0
	for i in names.size():
		for j in range(i + 1, names.size()):
			var a: String = names[i]
			var b: String = names[j]
			if not scope.is_empty() and not (a in scope or b in scope):
				continue
			var g := _gap_between(rects[a], rects[b])
			if g < gap:
				bad += 1
				_log("TOO CLOSE %s <-> %s gap=%dpx" % [a, b, g])
	var what := "all nodes" if scope.is_empty() else "%d node(s)" % scope.size()
	_log("check: %d pair(s) under %dpx, scope %s" % [bad, gap, what])
	var misordered := _check_menu_order(scope)
	_log("check: %d menu(s) out of order" % misordered)
	bad += misordered
	return 1 if bad > 0 else 0

# The game sorts a menu by each CHOICE's offset_y. A menu's choices, in its DIALOG's
# "go to" order (through LOGIC gates and ONRAMPs, as choice discovery walks them),
# must therefore sit strictly top to bottom. Only menus touching the scope are checked:
# hand-laid trees often list "go to" in some other order than their menus show.
func _check_menu_order(scope: Array) -> int:
	var bad := 0
	var names := raw.keys()
	names.sort()
	for d in names:
		if not d.begins_with("DIALOG_"):
			continue
		var choices: Array[String] = []
		_collect_choices(d, choices, {})
		if choices.size() < 2:
			continue
		if not scope.is_empty() and not choices.any(func(c): return c in scope):
			continue
		for i in range(1, choices.size()):
			var a: String = choices[i - 1]
			var b: String = choices[i]
			if rects.has(a) and rects.has(b) and rects[b].position.y <= rects[a].position.y:
				bad += 1
				_log("MENU ORDER %s: %s (y=%d) shows above %s (y=%d)" % [d, b, rects[b].position.y, a, rects[a].position.y])
				break
	return bad

func _collect_choices(n: String, out: Array[String], seen: Dictionary) -> void:
	for t in _targets(n):
		if seen.has(t):
			continue
		seen[t] = true
		if t.begins_with("CHOICE_"):
			out.append(t)
		elif t.begins_with("LOGIC_") or t.begins_with("ONRAMP_"):
			_collect_choices(t, out, seen)

######## Write ########

func _write(path: String) -> void:
	var changed := not placed.is_empty()
	for n in raw.keys():
		if not rects.has(n) or not raw[n] is Dictionary:
			continue
		var d: Dictionary = raw[n]
		var r: Rect2 = rects[n]
		if n in placed:
			d["offset_x"] = int(r.position.x)
			d["offset_y"] = int(r.position.y)
		var size: Vector2 = node_sizes.get(n, r.size)
		var sx := ceili(size.x)
		var sy := ceili(size.y)
		if d.get("size_x") != sx or d.get("size_y") != sy:
			d["size_x"] = sx
			d["size_y"] = sy
			changed = true
	if not changed:
		_log("write: no changes")
		return
	# Same serialization as FileDialog's save
	var text := JSON.stringify(raw)
	_store(path, text)
	var save_dir := Global.get_save_dir().replace("\\", "/")
	if not save_dir.ends_with("/"):
		save_dir += "/"
	var norm := path.replace("\\", "/")
	if norm.begins_with(save_dir):
		var exe_dir := OS.get_executable_path().get_base_dir()
		_store(exe_dir.path_join("XLUtilities").path_join("inbox").path_join(norm.substr(save_dir.length())), text)

func _store(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_log("ERROR could not write " + path)
		return
	f.store_string(text)
	_log("wrote " + path)

static func _log(s: String) -> void:
	print("[layout] " + s)
