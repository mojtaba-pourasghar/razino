extends RazinoScreen
## UI-19 — کوله‌پشتی, as the approved sheet draws it: the pack on one side,
## a tabbed grid of what is in it on the other, and the capacity along the
## bottom.
##
## The grid shows what GameState actually holds. Empty slots stay visible so
## the player can see there is room, which is what the sheet does too.

const TABS := ["همه", "وسایل", "سرنخ‌ها", "یادداشت‌ها"]
const CAPACITY := 30

## Which icon stands for each item the content can hand out.
const ITEM_ICONS := {
	"ITEM_MAP_PIECE": "map", "ITEM_NOTEBOOK": "book", "ITEM_BRASS_KEY": "key",
	"ITEM_GEAR_TEN": "gear", "ITEM_TOOLS": "gear", "ITEM_LEVER": "gear",
	"ITEM_UNDERMAP": "map", "ITEM_RECORDER": "speaker", "ITEM_TENTH_KEY": "key",
}

var _tab: int = 0
var _tab_row: HBoxContainer
var _grid: GridContainer
var _capacity: Label

func _ready() -> void:
	configure("کوله‌پشتی", "UI-04", "panel", true)
	super._ready()

func build_content() -> void:
	var body := HBoxContainer.new()
	body.layout_direction = Control.LAYOUT_DIRECTION_LTR
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", Palette.PAD_MD)
	content.add_child(body)

	# — the pack itself —
	var pack := Style.make_section()
	pack.custom_minimum_size.x = 280
	body.add_child(pack)
	var pcol := Style.section_body(pack)
	var art := Medallion.new("backpack", 180.0, false)
	art.icon_colour = Palette.GOLD_BRIGHT
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pcol.add_child(art)
	var plate := Style.make_corner_plaque("کوله‌پشتی", Palette.FS_HEADING)
	pcol.add_child(plate)
	_capacity = Style.make_body("", Palette.FS_CAPTION, Palette.SNOW_SOFT, false)
	_capacity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pcol.add_child(_capacity)

	# — the grid —
	var right := Style.make_section()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	var rcol := Style.section_body(right)

	_tab_row = HBoxContainer.new()
	_tab_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_tab_row.add_theme_constant_override("separation", Palette.PAD_SM)
	rcol.add_child(_tab_row)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rcol.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 6
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", Palette.PAD_SM)
	_grid.add_theme_constant_override("v_separation", Palette.PAD_SM)
	scroll.add_child(_grid)

	_build_tabs()
	_build_grid()

func _build_tabs() -> void:
	for child in _tab_row.get_children():
		child.queue_free()
	var buttons := Style.make_tabs(TABS, _tab)
	for i in buttons.size():
		var index := i
		buttons[i].pressed.connect(func():
			_tab = index
			_build_tabs()
			_build_grid())
		_tab_row.add_child(buttons[i])

func _build_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	var icons := _icons_for_tab()
	for icon: String in icons:
		_grid.add_child(Style.make_item_slot(icon))
	# Empty slots stay on show, so the player can see there is room.
	for _i in maxi(0, 18 - icons.size()):
		_grid.add_child(Style.make_item_slot(""))
	_capacity.text = "ظرفیت کوله‌پشتی: %s / %s" % [
		Fa.num(GameState.inventory.size() + GameState.clues.size()), Fa.num(CAPACITY)]

func _icons_for_tab() -> Array:
	var out: Array = []
	var want_items := _tab == 0 or _tab == 1
	var want_clues := _tab == 0 or _tab == 2
	if want_items:
		for item_id in GameState.inventory.keys():
			out.append(String(ITEM_ICONS.get(String(item_id), "star")))
	if want_clues:
		for _clue_id in GameState.clues.keys():
			out.append("magnifier")
	if _tab == 3:
		# Notes are the clue journal's own screen; this tab points at it
		# rather than duplicating it.
		out.append("book")
	return out
