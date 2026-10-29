extends RazinoScreen
## UI-20 — مرحله‌های فصل.
##
## GDD §5.8 makes the stage the thing a player picks, plays and replays, so
## this is the screen between a chapter and the game. It shows every stage in
## order with what the player earned from it: stars, clues found, whether it
## was ever done without a hint.
##
## Locking is the same honesty the chapter list keeps: a locked stage says
## which one opens it, and never offers a way to pay past it — there isn't
## one.

var _chapter_id: String = ""

## Which tab the list is filtered by.
##
## These used to read «اصلی / فرعی / تکمیل‌شده» — main, side, completed —
## while the filter behind them was really open, locked and done. A chapter
## has no side quests, so "فرعی" was where every locked stage went, and a
## player on a fresh save saw one lonely row under "اصلی" with no sign that
## nine more stages existed. The labels now say what the filter does.
const TABS := ["همه", "در دسترس", "تمام‌شده"]

var _tab: int = 0
var _tab_row: HBoxContainer
var _list: VBoxContainer

func _ready() -> void:
	var payload := Router.take_payload()
	_chapter_id = String(payload.get("chapter_id", GameState.current_chapter))
	if _chapter_id.is_empty():
		_chapter_id = "season_01"
	configure("مأموریت‌ها", "UI-04", "panel", true, "star")
	super._ready()

func build_content() -> void:
	# The stage list lives in the chapter's own story file, so the chapter
	# has to be loaded before there is anything to show.
	if StageEngine.chapter_id != _chapter_id:
		if not StoryEngine.load_chapter(_chapter_id):
			content.add_child(make_notice("این فصل روی دستگاه خوانده نشد."))
			return

	_tab_row = HBoxContainer.new()
	_tab_row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	_tab_row.add_theme_constant_override("separation", Palette.PAD_SM)
	content.add_child(_tab_row)

	_list = make_scroll()
	_build_tabs()
	_build_list()

func _build_tabs() -> void:
	for child in _tab_row.get_children():
		child.queue_free()
	var buttons := Style.make_tabs(TABS, _tab)
	for i in buttons.size():
		var index := i
		buttons[i].size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buttons[i].pressed.connect(func():
			_tab = index
			_build_tabs()
			_build_list())
		_tab_row.add_child(buttons[i])

func _build_list() -> void:
	for child in _list.get_children():
		child.queue_free()
	var shown := 0
	for stage: Dictionary in StageEngine.stages:
		var id := String(stage.get("stage_id", ""))
		var done := GameState.is_stage_complete(id)
		var open := StageEngine.is_open(id)
		# Tab 0 is the whole chapter, so the road ahead is visible from the
		# first minute; tab 1 is what can be played now; tab 2 is behind.
		var keep := _tab == 0 \
			or (_tab == 1 and open and not done) or (_tab == 2 and done)
		if not keep:
			continue
		_list.add_child(_quest_row(stage, open, done))
		shown += 1
	if shown == 0:
		var none := Style.make_body("اینجا چیزی نیست.", Palette.FS_LABEL,
			Palette.SNOW_SOFT)
		none.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list.add_child(none)

## One row of the sheet's quest list: a diamond badge, the title over its
## one-line instruction, a progress count on the far side, and a chevron.
## A locked row keeps the same shape but goes grey and loses the chevron.
func _quest_row(stage: Dictionary, open: bool, done: bool) -> Control:
	var id := String(stage.get("stage_id", ""))

	# A PanelContainer holding a real row, with a flat Button laid over it
	# for the press. An anchored row inside a Button contributes no height to
	# it, so the first version of this came out as a twenty-pixel strip with
	# the badge hanging out of both ends.
	var card := PanelContainer.new()
	var box := UiBox.painted(UiBox.Kind.BUTTON, 16, 12)
	if box == null:
		box = UiBox.make(UiBox.Kind.BUTTON, 16, 12)
	card.add_theme_stylebox_override("panel", box)

	var row := HBoxContainer.new()
	row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	row.add_theme_constant_override("separation", Palette.PAD_MD)
	card.add_child(row)

	var badge := _Badge.new()
	badge.locked = not open
	badge.custom_minimum_size = Vector2(56, 56)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(badge)

	var col := VBoxContainer.new()
	col.layout_direction = Control.LAYOUT_DIRECTION_RTL
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 3)
	row.add_child(col)
	var ink := Palette.SNOW if open else Palette.LOCKED
	col.add_child(Style.make_title(String(stage.get("title", id)),
		Palette.FS_LABEL, ink))
	var sub := Style.make_body(
		String(stage.get("secret", "")) if open else "مرحلهٔ قبل را تمام کن.",
		Palette.FS_CAPTION, Palette.SNOW_SOFT if open else Palette.LOCKED)
	sub.autowrap_mode = TextServer.AUTOWRAP_OFF
	sub.clip_text = true
	col.add_child(sub)

	if open:
		var record := GameState.stage_record(id)
		var count := Style.make_body("%s / %s" % [
			Fa.num(int(record.get("stars", 0))),
			Fa.num(StageEngine.STAR_THRESHOLDS.size())],
			Palette.FS_LABEL, Palette.GOLD_BRIGHT, false)
		count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(count)
		var chevron := IconRect.new("play", 26.0, Palette.SNOW_SOFT)
		chevron.painted = false
		chevron.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(chevron)

		var hit := Button.new()
		hit.flat = true
		hit.focus_mode = Control.FOCUS_ALL
		hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			hit.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		hit.pressed.connect(func(): Router.go("UI-21", {
			"chapter_id": _chapter_id, "stage_id": id}))
		card.add_child(hit)
	return card

class _Badge extends Control:
	## The diamond the sheet puts at the head of every quest row — gold when
	## the quest is open, a grey padlock when it is not.
	var locked: bool = false
	func _draw() -> void:
		var ci := get_canvas_item()
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.46
		var hull := PackedVector2Array([
			c + Vector2(0, -r), c + Vector2(r, 0),
			c + Vector2(0, r), c + Vector2(-r, 0)])
		CI.poly(ci, hull, Palette.PANEL_DEEP if locked else Palette.GOLD_DEEP)
		var inner := PackedVector2Array()
		for p in hull:
			inner.append(c + (p - c) * 0.68)
		CI.poly(ci, inner, Palette.NIGHT if locked else Palette.GOLD_BRIGHT)
		var ring := hull.duplicate(); ring.append(hull[0])
		CI.polyline(ci, ring, Palette.LOCKED if locked else Palette.GOLD_BRIGHT, 2.0)
		if locked:
			GameIcons.draw(ci, "lock", c, r * 0.42, Palette.LOCKED)

