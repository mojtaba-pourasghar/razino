class_name DialoguePanel
extends PanelContainer
## UI-07 — کادر دیالوگ و انتخاب.
##
## GDD §5 screen 2 asks for: a readable Persian dialogue box that does not sit
## over the important part of the picture, a way to replay the line, and two
## or three clearly tappable choices at decision points.
##
## Subtitles appear in step with the recorded line rather than all at once, so
## a child still learning to read can follow the voice. When no recording
## exists yet, the pacing falls back to a reading estimate — and the panel
## says so, rather than pretending a line was voiced.

signal continue_pressed()
signal choice_selected(choice_id: String)

const REVEAL_CHARS_PER_SECOND := 34.0

var _speaker: Label
var _text: RichTextLabel
var _choices: VBoxContainer
var _continue: Button
var _replay: Button
var _speaker_plate: Control

var _full_text: String = ""
var _revealed: float = 0.0
var _revealing: bool = false
var _current_audio: String = ""

func _ready() -> void:
	Style.attach(self)
	add_theme_stylebox_override("panel", OrnateBox.make(
		OrnateBox.Kind.PARCHMENT, Color("FBF1DA"), Palette.PARCHMENT_DIM,
		Palette.R_LG, 3.0).with_margins(Palette.PAD_LG, Palette.PAD_SM))

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	add_child(col)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", Palette.PAD_SM)
	col.add_child(top)
	# The speaker's name sits on a small navy plate centred over the text,
	# as the panel sheet draws it, which also keeps it from being read as
	# the first word of the line.
	top.add_child(_spacer())
	var name_plate := PanelContainer.new()
	name_plate.add_theme_stylebox_override("panel", UiBox.make(UiBox.Kind.BUTTON, 28, 4))
	name_plate.custom_minimum_size = Vector2(170, 38)
	name_plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_speaker = Style.make_title("", Palette.FS_LABEL, Palette.GOLD_LIGHT)
	_speaker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_speaker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_speaker.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_plate.add_child(_speaker)
	_speaker_plate = name_plate
	top.add_child(name_plate)
	top.add_child(_spacer())

	_replay = Style.make_button("پخش دوباره", "quiet")
	_replay.custom_minimum_size = Vector2(150, RazinoUI.TOUCH_MIN)
	_replay.pressed.connect(_replay_line)

	_text = RichTextLabel.new()
	_text.bbcode_enabled = false
	_text.fit_content = true
	_text.custom_minimum_size.y = 40
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_color_override("default_color", Palette.INK)
	_text.add_theme_font_size_override("normal_font_size", Style.scaled(Palette.FS_BODY))
	if Style.font_regular != null:
		_text.add_theme_font_override("normal_font", Style.font_regular)
	# RichTextLabel has no horizontal_alignment; it follows the layout and
	# text direction instead, which is what makes Persian read correctly here.
	_text.layout_direction = Control.LAYOUT_DIRECTION_RTL
	_text.text_direction = Control.TEXT_DIRECTION_RTL
	col.add_child(_text)

	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", Palette.PAD_SM)
	col.add_child(_choices)

	# A small gold button at the end of the line, not a bar across the box:
	# the box is for reading. The replay button, when a line is voiced,
	# sits at the other end of the same row.
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", Palette.PAD_SM)
	col.add_child(bottom)
	bottom.add_child(_replay)
	bottom.add_child(_spacer())
	_continue = Style.make_button("ادامه", "gold")
	_continue.custom_minimum_size = Vector2(160, RazinoUI.TOUCH_MIN)
	_continue.pressed.connect(_on_continue)
	bottom.add_child(_continue)

	AudioManager.voice_finished.connect(_on_voice_finished)
	set_process(false)

## Which short sound stands in for each character's voice while their line
## types out. This is not speech and is not meant to pass for it: the ear
## takes the pitch as the character and reads the words off the screen,
## which is how a 2D game gives a cast voices without recording any. The
## real lines are recorded by people, and when a recording exists for a
## line it plays instead of this.
const VOICE_OF := {
	"arad": "VOICE_ARAD", "raha": "VOICE_RAHA", "mani": "VOICE_MANI",
	"player": "VOICE_PLAYER", "fandogh": "VOICE_FANDOGH",
	"azimi": "VOICE_AZIMI", "modir": "VOICE_MODIR",
}
## One blip every few letters. Every letter is a machine-gun; every word is
## too sparse to connect to the text.
const LETTERS_PER_BLIP := 3

var _blipped: int = 0
var _speaker_id: String = ""


func _process(delta: float) -> void:
	_revealed += delta * REVEAL_CHARS_PER_SECOND * (1.6 if Settings.reduce_motion else 1.0)
	var shown := int(_revealed)
	if shown >= _full_text.length():
		_finish_reveal()
		return
	_text.text = _full_text.substr(0, shown)
	_blip(shown)


## Sounds a letter, unless this line has a real recording playing over it,
## or the letter is a space — a blip on a gap between words sounds like a
## stutter rather than a voice.
func _blip(shown: int) -> void:
	if shown <= _blipped or _replay.visible:
		return
	_blipped = shown
	if shown % LETTERS_PER_BLIP != 0 or shown <= 0:
		return
	var letter := _full_text.substr(shown - 1, 1)
	if letter.strip_edges().is_empty():
		return
	var id := String(VOICE_OF.get(_speaker_id, "VOICE_NARRATOR"))
	AudioManager.play_sfx(id)

func _spacer() -> Control:
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return gap

func show_line(line: Dictionary, speaker_name: String) -> void:
	_choices.visible = false
	for c in _choices.get_children():
		c.queue_free()
	_continue.visible = true
	_continue.text = "ادامه"
	_speaker.text = speaker_name
	_speaker_plate.visible = not speaker_name.strip_edges().is_empty()
	_full_text = String(line.get("text", ""))
	_current_audio = String(line.get("audio_id", ""))
	_speaker_id = String(line.get("speaker_id", ""))
	_blipped = 0

	# A line with no recording yet is a production fact, not something to tell
	# a child in red letters on the dialogue box — it reads as the game being
	# broken. It goes to the log, where the people recording can see it, and
	# the replay button simply stays away.
	var has_clip := not _current_audio.is_empty() \
		and not AudioManager.missing_audio.has(_current_audio)
	_replay.visible = has_clip
	if not _current_audio.is_empty() and not has_clip:
		Log.info("Dialogue", "no recording for %s yet" % _current_audio)

	if Settings.subtitles_enabled:
		_revealed = 0.0
		_revealing = true
		_text.text = ""
		set_process(true)
	else:
		_text.text = _full_text
		_finish_reveal()

func show_choices(choices: Array, texts_by_id: Dictionary = {}) -> void:
	_finish_reveal()
	_continue.visible = false
	_choices.visible = true
	for c in _choices.get_children():
		c.queue_free()
	for entry in choices:
		var cd: Dictionary = entry
		var cid := String(cd.get("choice_id", ""))
		var label := String(texts_by_id.get(cid, cd.get("text", "")))
		var b := Style.make_button(label, "secondary")
		b.custom_minimum_size.y = maxf(Palette.TOUCH_MIN, 64)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var hint := String(cd.get("hint", ""))
		if not hint.is_empty():
			b.tooltip_text = hint
		b.pressed.connect(func():
			AudioManager.play_sfx("SFX_UI_CHOICE")
			choice_selected.emit(cid))
		_choices.add_child(b)

func is_revealing() -> bool:
	return _revealing

## Tapping while text is still appearing shows all of it at once, which is
## what a fast reader expects, rather than being made to wait.
func _on_continue() -> void:
	if _revealing:
		_finish_reveal()
		return
	AudioManager.play_sfx("SFX_UI_TAP")
	continue_pressed.emit()

func _finish_reveal() -> void:
	set_process(false)
	_revealing = false
	_text.text = _full_text

func _replay_line() -> void:
	if _current_audio.is_empty():
		return
	AudioManager.play_voice(_current_audio, _full_text)

func _on_voice_finished(_audio_id: String) -> void:
	_finish_reveal()
	if Settings.auto_advance and _continue.visible:
		continue_pressed.emit()
