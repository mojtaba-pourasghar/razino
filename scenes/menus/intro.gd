extends RazinoScreen
## UI-02 — معرفی اولیه. A short, skippable explanation of the controls, then
## on to making a character. Nothing here is a quiz; it is one screen a child
## reads once.

const STEPS := [
	{"title": "به رازینو خوش آمدی", "body": "شهر رازینو ده راز دارد. تو عضو تازهٔ گروهی هستی که دنبالشان می‌گردد: آراد، رها، مانی و فندق."},
	{"title": "بگرد و بررسی کن", "body": "هر چیزی که عجیب به نظر می‌رسد را لمس کن. چیزهایی که پیدا می‌کنی در دفترچهٔ سرنخ‌ها می‌نشینند."},
	{"title": "انتخاب کن", "body": "گاهی باید تصمیم بگیری. هیچ تصمیمی تو را به بن‌بست نمی‌برد، ولی داستان را عوض می‌کند."},
	{"title": "سرنخ‌ها را کنار هم بگذار", "body": "دو سرنخ که کنار هم بنشینند، گاهی جواب سومی می‌سازند. اشتباه‌زدن هیچ هزینه‌ای ندارد."},
]

var _step: int = 0
var _title: Label
var _body: Label
var _dots: HBoxContainer
var _next: Button

func _ready() -> void:
	configure("", "", "splash")
	super._ready()

## The card is sized by what is written on it and floated in the middle of
## the screen. It used to expand to fill every pixel of height it was given,
## which turned four short lines into a parchment slab taller than the
## picture above it, with the paging dots stranded at the far bottom.
func build_content() -> void:
	var lift := Control.new()
	lift.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(lift)

	var card := Style.make_card()
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	content.add_child(card)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", Palette.PAD_MD)
	card.add_child(col)

	col.add_child(Style.make_banner("BG_INTRO_RAZINO", 170))

	# Both start at the right, where Persian is read from. The constant says
	# LEFT because alignment is resolved against the layout direction, and
	# this screen is laid out right to left -- asking for RIGHT here puts the
	# heading on the left, which is where it used to sit, on the opposite
	# side of the card from the sentence below it.
	_title = Style.make_title("", Palette.FS_HEADING, Palette.INK)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col.add_child(_title)
	_body = Style.make_body("", Palette.FS_BODY, Palette.INK_SOFT)
	_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_body.custom_minimum_size.y = 76
	col.add_child(_body)

	_dots = HBoxContainer.new()
	_dots.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots.add_theme_constant_override("separation", Palette.PAD_SM)
	col.add_child(_dots)

	# One clear way on, one quiet way out, each the width of its own words.
	# Stretching "بعدی" across the screen made a two-syllable button the
	# largest thing on it.
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", Palette.PAD_MD)
	content.add_child(buttons)

	_next = Style.make_button("بعدی", "primary", "play")
	_next.custom_minimum_size.x = 240
	_next.pressed.connect(_advance)
	buttons.add_child(_next)

	var skip := Style.make_button("رد کردن", "quiet")
	skip.custom_minimum_size.x = 150
	skip.pressed.connect(_finish)
	buttons.add_child(skip)

	var drop := Control.new()
	drop.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(drop)

	_render()

func _render() -> void:
	var s: Dictionary = STEPS[_step]
	_title.text = String(s["title"])
	_body.text = String(s["body"])
	_next.text = "بعدی" if _step < STEPS.size() - 1 else "بساز و شروع کن"
	for c in _dots.get_children():
		c.queue_free()
	for i in STEPS.size():
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(12, 12)
		dot.color = Palette.GOLD if i == _step else Palette.PARCHMENT_DIM
		_dots.add_child(dot)

func _advance() -> void:
	AudioManager.play_sfx("SFX_UI_TAP")
	if _step < STEPS.size() - 1:
		_step += 1
		_render()
	else:
		_finish()

func _finish() -> void:
	GameState.set_flag("intro_seen", true)
	SaveManager.mark_dirty()
	Router.go("UI-03")
