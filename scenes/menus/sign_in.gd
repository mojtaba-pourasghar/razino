extends RazinoScreen
## UI-23 — ورود با کد پیامکی.
##
## Two steps on one screen: a phone number, then the code that arrives. The
## second step replaces the first rather than opening a new screen, so a
## child can see the number they typed while they wait for the message.
##
## This screen is never in the way. Chapter one plays without an account at
## all; signing in is what makes a bought chapter follow a child from a phone
## to a tablet, so the game asks here and nowhere else.

enum Step { PHONE, CODE }

var _step: int = Step.PHONE
var _phone: String = ""
var _seconds_left: int = 0

var _body: VBoxContainer
var _field: LineEdit
var _action: Button
var _notice: Label
var _countdown: Label

func _ready() -> void:
	configure("ورود", "UI-04")
	super._ready()
	Account.code_sent.connect(_on_code_sent)
	Account.signed_in.connect(_on_signed_in)
	Account.auth_failed.connect(_on_failed)

func _exit_tree() -> void:
	for sig in [Account.code_sent, Account.signed_in, Account.auth_failed]:
		for conn in sig.get_connections():
			if (conn["callable"] as Callable).get_object() == self:
				sig.disconnect(conn["callable"])

func build_content() -> void:
	if Account.is_signed_in():
		_build_signed_in()
		return

	content.add_child(_card())
	_render()

## A drawn card, not a painted panel. The painted plate draws its corner
## ornament at source size, and this card is four rows tall — the gold landed
## straight across the heading.
func _card() -> Control:
	var wrap := CenterContainer.new()
	wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var card := Style.make_night_card()
	card.custom_minimum_size.x = 520
	wrap.add_child(card)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", Palette.PAD_SM)
	card.add_child(_body)
	return wrap

func _render() -> void:
	for child in _body.get_children():
		child.queue_free()

	var heading := "شمارهٔ موبایلت را بنویس" if _step == Step.PHONE \
		else "کدی که پیامک شد را بنویس"
	_body.add_child(Style.make_title(heading, Palette.FS_HEADING))

	var why := "با ورود، فصل‌هایی که خریده‌ای روی هر دستگاهی که وارد شوی باز می‌مانند." \
		if _step == Step.PHONE else "پیامک به %s فرستاده شد." % Fa.digits(_phone)
	_body.add_child(Style.make_body(why, Palette.FS_CAPTION, Palette.SNOW_SOFT))

	_field = LineEdit.new()
	# Digits only, and a numeric keypad on a phone — a child should never
	# have to find the number row on a Persian keyboard.
	_field.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER
	_field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_field.max_length = 11 if _step == Step.PHONE else 6
	_field.placeholder_text = "۰۹۱۲۳۴۵۶۷۸۹" if _step == Step.PHONE else "۱۲۳۴۵۶"
	_field.text_submitted.connect(func(_t): _submit())
	_body.add_child(_field)
	_field.grab_focus()

	_action = Style.make_button("فرستادن کد" if _step == Step.PHONE else "ورود")
	_action.pressed.connect(_submit)
	_body.add_child(_action)

	if _step == Step.CODE:
		_countdown = Style.make_body("", Palette.FS_CAPTION, Palette.SNOW_SOFT)
		_countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_body.add_child(_countdown)
		var again := Style.make_button("شمارهٔ دیگر", "quiet")
		again.pressed.connect(func():
			_step = Step.PHONE
			_render())
		_body.add_child(again)
		set_process(true)

	_notice = Style.make_body("", Palette.FS_CAPTION, Palette.RUBY_LIGHT)
	_notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.add_child(_notice)

func _process(delta: float) -> void:
	if _step != Step.CODE or _countdown == null:
		return
	_seconds_left = maxi(0, _seconds_left - int(delta * 1000.0) / 1000)
	_countdown.text = "" if _seconds_left <= 0 \
		else "این کد تا %s ثانیهٔ دیگر معتبر است." % Fa.num(_seconds_left)

func _submit() -> void:
	AudioManager.play_sfx("SFX_UI_TAP")
	_notice.text = ""
	_action.disabled = true
	if _step == Step.PHONE:
		_phone = _field.text.strip_edges()
		Account.request_code(_phone)
	else:
		Account.verify(_phone, _field.text.strip_edges())

func _on_code_sent(seconds_valid: int) -> void:
	_step = Step.CODE
	_seconds_left = seconds_valid
	_render()

func _on_signed_in(_p: Dictionary) -> void:
	Router.go("UI-04")

func _on_failed(_code: String, message: String) -> void:
	if _action != null:
		_action.disabled = false
	if _notice != null:
		_notice.text = message

func _build_signed_in() -> void:
	content.add_child(_card())
	var col := _body
	col.add_child(Style.make_title("وارد شده‌ای", Palette.FS_HEADING))
	col.add_child(Style.make_body(
		String(Account.player.get("phone", "")), Palette.FS_LABEL, Palette.SNOW))
	var out := Style.make_button("خروج از حساب", "quiet")
	out.pressed.connect(func():
		Account.sign_out()
		Router.go("UI-04"))
	col.add_child(out)
