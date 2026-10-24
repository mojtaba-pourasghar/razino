extends RazinoScreen
## UI-21 — کوله‌بار مرحله.
##
## GDD §5.8 puts a choice between the player and every stage: two tools out of
## the pack, two companions out of four. That narrow choice is where this
## game's strategy lives — there is no energy bar and no timer, so if the
## choice is not real the stage has no shape.
##
## Nothing here can be bought past. A tool the player does not own is shown
## greyed with its coin price and a way to the shop, never a way to pay now,
## and no stage needs a bought tool to be finished.

var _chapter_id: String = ""
var _stage_id: String = ""

var _tools: Array = []
var _companions: Array = []
var _start: Button
var _counts: Label
var _tool_row: HBoxContainer
var _comp_row: HBoxContainer

func _ready() -> void:
	var payload := Router.take_payload()
	_chapter_id = String(payload.get("chapter_id", GameState.current_chapter))
	_stage_id = String(payload.get("stage_id", ""))
	configure("کوله‌بار", "UI-20", "panel", true)
	super._ready()

func build_content() -> void:
	var stage := StageEngine.stage(_stage_id)
	if stage.is_empty():
		content.add_child(make_notice("این مرحله پیدا نشد."))
		return

	# What the stage asks, above what to take into it — the question is what
	# makes one tool a better idea than another.
	content.add_child(Style.make_two_line_plaque(
		String(stage.get("title", "")), String(stage.get("secret", ""))))

	# Both racks scroll together: five tools and four companions do not fit a
	# phone in portrait, and the start button must stay reachable without
	# scrolling past it.
	var rack := make_scroll()

	var tools := Style.make_section("ابزار")
	rack.add_child(tools)
	_tool_row = HBoxContainer.new()
	_tool_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_tool_row.add_theme_constant_override("separation", Palette.PAD_SM)
	Style.section_body(tools).add_child(_tool_row)

	var comps := Style.make_section("همراه")
	rack.add_child(comps)
	_comp_row = HBoxContainer.new()
	_comp_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_comp_row.add_theme_constant_override("separation", Palette.PAD_SM)
	Style.section_body(comps).add_child(_comp_row)

	_counts = Style.make_body("", Palette.FS_LABEL, Palette.SNOW_SOFT)
	_counts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_counts)

	_start = Style.make_button("بزن بریم", "primary")
	_start.pressed.connect(_go)
	content.add_child(_start)

	_rebuild()

func _rebuild() -> void:
	for row in [_tool_row, _comp_row]:
		for child in row.get_children():
			child.queue_free()

	for t: Dictionary in Loadout.TOOLS:
		_tool_row.add_child(_tool_card(t))
	for c: Dictionary in Loadout.COMPANIONS:
		_comp_row.add_child(_companion_card(c))

	var ready := _tools.size() == StageEngine.TOOL_SLOTS \
		and _companions.size() == StageEngine.COMPANION_SLOTS
	_counts.text = "ابزار %s از %s · همراه %s از %s" % [
		Fa.num(_tools.size()), Fa.num(StageEngine.TOOL_SLOTS),
		Fa.num(_companions.size()), Fa.num(StageEngine.COMPANION_SLOTS)]
	_start.disabled = not ready

func _tool_card(t: Dictionary) -> Control:
	var id := String(t["id"])
	var owned := bool(GameState.owned_tools.get(id, false))
	var chosen := id in _tools

	var card := _card(String(t["icon"]), String(t["name"]), String(t["does"]),
		chosen, owned, "" if owned else "%s سکه" % Fa.num(int(t["price"])))
	if owned:
		card.pressed.connect(func(): _toggle(_tools, id, StageEngine.TOOL_SLOTS))
	else:
		# Not owned: the card says the price and points at the shop. It never
		# offers to buy from here, because a buy button on the way into a
		# stage is exactly the pressure the design refuses (GDD §5.6).
		card.tooltip_text = "%s سکه — در فروشگاه" % Fa.num(int(t["price"]))
		card.pressed.connect(func(): Router.go("UI-11"))
	return card

func _companion_card(c: Dictionary) -> Control:
	var id := String(c["id"])
	var chosen := id in _companions
	var line := "%s — %s" % [String(c["ability"]), String(c["does"])]
	var card := _card(String(c["icon"]), String(c["name"]), line, chosen, true)
	card.pressed.connect(func(): _toggle(_companions, id, StageEngine.COMPANION_SLOTS))
	return card

## One pickable tile. A chosen one is lit and ticked; an unowned one is pale
## with its lock, so the player can see the whole set and what it would take
## to have it — showing only what they own would hide the game's own shape.
func _card(icon: String, name: String, line: String, chosen: bool,
		owned: bool, note: String = "") -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(164, 168)
	b.focus_mode = Control.FOCUS_ALL
	var tint := Palette.ACTION if chosen else Palette.PANEL_DEEP
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(state, OrnateBox.make(
			OrnateBox.Kind.BUTTON,
			tint.lightened(0.18 if state == "hover" else 0.08),
			tint.darkened(0.25), Palette.R_MD, 3.0
		).with_margins(Palette.PAD_SM, Palette.PAD_SM))

	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", Palette.PAD_XS)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(col)

	var badge := IconRect.new(icon, 56.0,
		Palette.GOLD_BRIGHT if owned else Palette.LOCKED)
	badge.medallion = true
	# A missing tool is pale, so the rack shows at a glance what is in the
	# pack and what is still in the shop.
	badge.painted = owned
	badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(badge)

	var title := Style.make_body(name, Palette.FS_LABEL,
		Palette.SNOW if owned else Palette.LOCKED, false)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)

	var sub := Style.make_body(line, Palette.FS_CAPTION,
		Palette.SNOW_SOFT if owned else Palette.LOCKED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(sub)

	if chosen:
		var tick := IconRect.new("check", 26.0, Palette.GREEN)
		tick.painted = false
		tick.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(tick)
	elif not note.is_empty():
		# The price, not a buy button. On the way into a stage a buy button is
		# exactly the pressure the design refuses, so this only says what the
		# tool costs and where it is sold.
		var price := HBoxContainer.new()
		price.layout_direction = Control.LAYOUT_DIRECTION_RTL
		price.alignment = BoxContainer.ALIGNMENT_CENTER
		price.add_theme_constant_override("separation", 4)
		var coin := IconRect.new("coin", 20.0, Palette.ORANGE)
		coin.painted = false
		price.add_child(coin)
		price.add_child(Style.make_body(note, Palette.FS_CAPTION, Palette.ORANGE, false))
		col.add_child(price)
	return b

## Picking past the limit drops the oldest pick rather than refusing the tap.
## A child who taps a fourth tool meant to take it; being told "no" four times
## teaches nothing about the limit, and swapping shows it immediately.
func _toggle(into: Array, id: String, limit: int) -> void:
	AudioManager.play_sfx("SFX_UI_TAP")
	if id in into:
		into.erase(id)
	else:
		into.append(id)
		while into.size() > limit:
			into.pop_front()
	_rebuild()

func _go() -> void:
	AudioManager.play_sfx("SFX_UI_TAP")
	Router.go("UI-06", {"chapter_id": _chapter_id, "stage_id": _stage_id,
		"tools": _tools.duplicate(), "companions": _companions.duplicate()})
