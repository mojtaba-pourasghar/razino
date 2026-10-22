extends RazinoScreen
## UI-18 — اعلان‌ها و جوایز, as the approved sheet draws it: the list of what
## happened on one side, the reward waiting to be claimed on the other.
##
## Everything shown here is derived from real progress. Nothing is invented
## to fill the list — an empty list says it is empty.

var _list: VBoxContainer
var _reward: VBoxContainer
var _selected: int = 0
var _entries: Array = []

func _ready() -> void:
	configure("اعلان‌ها و جوایز", "UI-04", "panel", true)
	super._ready()

func build_content() -> void:
	_entries = _collect()

	var body := HBoxContainer.new()
	body.layout_direction = Control.LAYOUT_DIRECTION_LTR
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", Palette.PAD_MD)
	content.add_child(body)

	var left := Style.make_section()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(left)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	Style.section_body(left).add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", Palette.PAD_SM)
	scroll.add_child(_list)

	var right := Style.make_section("جایزهٔ مأموریت")
	right.custom_minimum_size.x = 360
	body.add_child(right)
	_reward = Style.section_body(right)

	_build_list()
	_build_reward()

func _build_list() -> void:
	for child in _list.get_children():
		child.queue_free()
	if _entries.is_empty():
		_list.add_child(Style.make_quote("هنوز خبری نیست. وقتی چیزی پیدا کنی اینجا می‌آید."))
		return
	for i in _entries.size():
		var e: Dictionary = _entries[i]
		var card := Style.make_list_card(String(e["icon"]), String(e["title"]),
			String(e["body"]), String(e.get("when", "")), int(e.get("badge", 0)))
		var index := i
		var tap := Button.new()
		tap.flat = true
		tap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tap.pressed.connect(func():
			_selected = index
			_build_reward())
		card.add_child(tap)
		_list.add_child(card)

func _build_reward() -> void:
	for child in _reward.get_children():
		child.queue_free()
	if _entries.is_empty():
		_reward.add_child(Style.make_quote("جایزه‌ای در انتظار نیست."))
		return
	var e: Dictionary = _entries[clampi(_selected, 0, _entries.size() - 1)]

	var chest := Medallion.new(String(e["icon"]), 120.0, false)
	chest.icon_colour = Palette.GOLD_BRIGHT
	chest.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_reward.add_child(chest)

	var title := Style.make_title(String(e["title"]), Palette.FS_HEADING, Palette.GOLD_LIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reward.add_child(title)
	_reward.add_child(Style.make_quote(String(e["body"])))

	var rewards: Array = e.get("rewards", [])
	if not rewards.is_empty():
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", Palette.PAD_MD)
		for r: Dictionary in rewards:
			row.add_child(Style.make_reward(String(r["icon"]), int(r["amount"]),
				r.get("colour", Palette.GOLD_BRIGHT)))
		_reward.add_child(row)

	var claim := Style.make_button("دریافت", "primary", "check")
	claim.custom_minimum_size.y = 62
	claim.disabled = rewards.is_empty()
	claim.pressed.connect(func():
		for r: Dictionary in rewards:
			if String(r["icon"]) == "coin":
				GameState.coins += int(r["amount"])
			elif String(r["icon"]) == "gem":
				GameState.gems += int(r["amount"])
		AudioManager.play_sfx("SFX_UI_TAP")
		Router.go("UI-18"))
	_reward.add_child(claim)

## Reads the player's real progress. Nothing here is invented: if a chapter
## was not finished, no card claims it was.
func _collect() -> Array:
	var out: Array = []
	for cid in GameState.chapter_progress.keys():
		var chapter_id := String(cid)
		var entry := ContentManager.catalog_entry(chapter_id)
		var title := String(entry.get("title", chapter_id))
		if GameState.is_chapter_complete(chapter_id):
			out.append({
				"icon": "trophy", "title": "فصل تمام شد",
				"body": "«%s» را تا آخر رفتی." % title,
				"rewards": [
					{"icon": "coin", "amount": 500, "colour": Palette.ORANGE},
					{"icon": "gem", "amount": 5, "colour": Palette.BLUE},
				],
			})
		else:
			out.append({
				"icon": "map", "title": "مأموریت باز",
				"body": "«%s» هنوز تمام نشده." % title,
			})
	var clue_count := GameState.clues.size()
	if clue_count > 0:
		out.append({
			"icon": "magnifier", "title": "سرنخ تازه",
			"body": "%s سرنخ در دفترچه داری." % Fa.num(clue_count),
			"badge": clue_count,
		})
	if GameState.inventory.size() > 0:
		out.append({
			"icon": "box", "title": "وسیله برداشتی",
			"body": "%s چیز در کوله‌پشتی داری." % Fa.num(GameState.inventory.size()),
		})
	return out
