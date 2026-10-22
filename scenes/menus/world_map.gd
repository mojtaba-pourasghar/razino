extends RazinoScreen
## UI-05 — نقشهٔ جهان.
##
## GDD §3 asks for one world rather than ten separate scenes: places the
## player has already been stay open, and each chapter opens a new part of the
## same map. The regions below are the five from the GDD's world map.

const REGIONS := [
	{"id": "centre", "icon": "clock", "name": "منطقهٔ مرکزی شهر", "desc": "مدرسه، میدان ساعت، کتابخانه و خانهٔ شخصیت‌ها. نقطهٔ شروع و بازگشت.", "opens_with": "season_01"},
	{"id": "nature", "icon": "map", "name": "منطقهٔ طبیعت", "desc": "جنگل نشانه‌ها، آبشار، رودخانه و مسیرهای کوهستانی.", "opens_with": "season_03"},
	{"id": "invent", "icon": "gear", "name": "منطقهٔ اختراع‌ها", "desc": "کارگاه مانی، آزمایشگاه علمی و انبار قطعه‌ها.", "opens_with": "season_04"},
	{"id": "far", "icon": "star", "name": "منطقهٔ دوردست", "desc": "رصدخانه، دریاچه و ایستگاه پژوهشی.", "opens_with": "season_05"},
	{"id": "under", "icon": "key", "name": "منطقهٔ زیرزمینی", "desc": "مسیرهای مخفی، تالار نمادها و دستگاه مرکزی.", "opens_with": "season_08"},
]

func _ready() -> void:
	configure("نقشهٔ جهان", "UI-04", "worldmap", true)
	super._ready()

func build_content() -> void:
	content.add_child(Style.make_banner("BG_WORLD_MAP", 200))

	var list := make_scroll()
	for region in REGIONS:
		list.add_child(_region_card(region))

func _region_card(region: Dictionary) -> Control:
	var needs := String(region["opens_with"])
	# A region opens once its chapter has been reached, not only finished, so
	# the map grows with the story rather than lagging behind it.
	var open := GameState.is_chapter_unlocked(needs)

	var card := Style.make_night_card()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", Palette.PAD_MD)
	card.add_child(row)

	row.add_child(Style.make_art_frame("region_%s" % String(region["id"]),
		String(region.get("icon", "map")), Vector2(150, 96), open))

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	col.add_child(Style.make_title(String(region["name"]), Palette.FS_HEADING,
		Palette.SNOW if open else Palette.SNOW_SOFT))
	col.add_child(Style.make_body(String(region["desc"]), Palette.FS_CAPTION, Palette.SNOW_SOFT))
	if not open:
		var entry := ContentManager.catalog_entry(needs)
		col.add_child(Style.make_body(
			"با رسیدن به «%s» باز می‌شود." % String(entry.get("title", needs)),
			Palette.FS_CAPTION, Palette.LOCKED))
	return card
