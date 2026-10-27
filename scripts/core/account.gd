extends Node
## The player's account on the Razino server.
##
## Signing in is a phone number and a six-digit code; there is no password
## anywhere in this game. The players are eight to twelve and the phone is a
## parent's, which is the arrangement the parental zone already assumes.
##
## Nothing in chapter one needs an account. Signing in is what makes a bought
## chapter follow a child from a phone to a tablet, so the game asks for it
## when they buy something and never before — a login wall in front of a
## children's game is a wall in front of a child who just wants to play.

signal signed_in(player: Dictionary)
signal signed_out()
signal code_sent(seconds_valid: int)
signal auth_failed(code: String, message: String)

## Where the token lives between sessions.
##
## This is an ordinary file in user://. Godot has no binding to the Android
## keystore, so a rooted device can read it — which is worth stating plainly
## rather than implying a safety that is not there. What it protects is worth
## exactly one account's chapter list, and the server can revoke it.
const TOKEN_PATH := "user://account.cfg"

var token: String = ""
var player: Dictionary = {}

func _ready() -> void:
	_load_token()

func is_signed_in() -> bool:
	return not token.is_empty()

# — signing in ————————————————————————————————————————————

## Asks the server to text a code to this phone.
##
## The answer is the same whether or not that phone has an account, so this
## cannot be used to find out who plays; the game must not add a "this number
## is not registered" message on top of it.
func request_code(phone: String) -> void:
	var body := {"phone": phone}
	_post("auth/request-code", body, func(ok: bool, data: Dictionary):
		if ok:
			code_sent.emit(int(data.get("expires_in", 180)))
		else:
			auth_failed.emit(String(data.get("error", "network")),
				String(data.get("message", "ارتباط با سرور برقرار نشد."))))

## Trades a code for a token.
func verify(phone: String, code: String) -> void:
	_post("auth/verify", {"phone": phone, "code": code},
		func(ok: bool, data: Dictionary):
			if not ok:
				auth_failed.emit(String(data.get("error", "network")),
					String(data.get("message", "ارتباط با سرور برقرار نشد.")))
				return
			token = String(data.get("token", ""))
			player = data.get("user", {})
			_save_token()
			Log.info("Account", "signed in as %s" % player.get("phone", "?"))
			signed_in.emit(player))

## Forgets this device's token. The server is told so the token stops
## working; if that call fails the token is dropped locally anyway, because a
## player who tapped "sign out" must end up signed out either way.
func sign_out() -> void:
	if is_signed_in():
		_post("auth/logout", {}, func(_ok: bool, _data: Dictionary): pass, true)
	token = ""
	player = {}
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TOKEN_PATH))
	Log.info("Account", "signed out")
	signed_out.emit()

# — plumbing ———————————————————————————————————————————————

func _post(path: String, body: Dictionary, done: Callable,
		authed: bool = false) -> void:
	var base := ContentEndpoints.api_base_url()
	if base.is_empty():
		done.call(false, {"error": "offline",
			"message": "این نسخه به سرور وصل نیست."})
		return

	var request := HTTPRequest.new()
	add_child(request)
	request.request_completed.connect(
		func(_result: int, code: int, _headers: PackedStringArray, data: PackedByteArray):
			request.queue_free()
			var parsed: Variant = JSON.parse_string(data.get_string_from_utf8())
			var dict: Dictionary = parsed if parsed is Dictionary else {}
			done.call(code >= 200 and code < 300, dict))

	var headers := ["Content-Type: application/json", "Accept: application/json"]
	if authed and is_signed_in():
		headers.append("Authorization: Bearer %s" % token)

	var url := "%s/v1/%s" % [base.rstrip("/"), path]
	var err := request.request(url, headers, HTTPClient.METHOD_POST,
		JSON.stringify(body))
	if err != OK:
		request.queue_free()
		done.call(false, {"error": "network",
			"message": "ارتباط با سرور برقرار نشد."})

func _save_token() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("account", "token", token)
	cfg.set_value("account", "player", player)
	cfg.save(TOKEN_PATH)

func _load_token() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(TOKEN_PATH) != OK:
		return
	token = String(cfg.get_value("account", "token", ""))
	player = cfg.get_value("account", "player", {})
	if is_signed_in():
		Log.info("Account", "signed in from a saved token")
