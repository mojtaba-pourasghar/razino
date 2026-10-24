class_name Loadout
extends RefCounted
## What the player takes into a stage (GDD §5.4 and §5.6).
##
## The tables are here rather than in the content because they are the same
## in every chapter: a tool does the same thing in the clock tower as in the
## forest, and the four companions are the cast of the whole series. Content
## asks for them through the story vocabulary — StageEngine.carrying() and
## accompanied_by() — so a scene can open a route for the right loadout
## without this file knowing anything about that scene.
##
## Two tools and two companions. The limit is the strategy: the GDD is
## explicit that the pressure in this game comes from a narrow choice, never
## from a timer or an energy bar.

## The five tools. `free` ones are in the pack from the first stage; the rest
## are bought with coins, never with real money, and none of them is required
## to finish anything (GDD §5.6, "هیچ معمای ضروری با پرداخت حل نمی‌شود").
const TOOLS := [
	{"id": "TOOL_LANTERN", "name": "فانوس", "icon": "lamp",
	 "does": "در جاهای تاریک می‌بینی", "price": 0, "free": true},
	{"id": "TOOL_MAGNIFIER", "name": "ذره‌بین", "icon": "magnifier",
	 "does": "جزئیات ریز روی اشیاء را می‌بینی", "price": 0, "free": true},
	{"id": "TOOL_ROPE", "name": "طناب", "icon": "rope",
	 "does": "به جاهای بلند یا پایین می‌رسی", "price": 120, "free": false},
	{"id": "TOOL_COMPASS", "name": "قطب‌نما", "icon": "compass",
	 "does": "در جنگل و زیرزمین جهت را گم نمی‌کنی", "price": 150, "free": false},
	{"id": "TOOL_TOOLBOX", "name": "جعبه‌ابزار مانی", "icon": "gear",
	 "does": "یک مانع مکانیکی را باز می‌کنی", "price": 200, "free": false},
]

## The four companions. Each ability may be used twice in a stage and
## recharges for free between stages; none of them solves a puzzle, they only
## make the search smaller.
##
## فندق is marked `always`: his nose works whether or not he was picked, so a
## child who is stuck is never left completely alone. He still takes a slot
## when chosen, because the choice has to cost something to be a choice.
const COMPANIONS := [
	{"id": "raha", "name": "رها", "icon": "magnifier", "ability": "نگاه دوباره",
	 "does": "یک چیز بررسی‌نشده را برجسته می‌کند — جواب را نمی‌گوید", "always": false},
	{"id": "mani", "name": "مانی", "icon": "gear", "ability": "جعبه‌ابزار",
	 "does": "یک مانع مکانیکی را باز می‌کند", "always": false},
	{"id": "arad", "name": "آراد", "icon": "compass", "ability": "راه میان‌بر",
	 "does": "یک مسیر فرعی با سرنخ اختیاری باز می‌کند", "always": false},
	{"id": "fandogh", "name": "فندق", "icon": "friend", "ability": "بو کشیدن",
	 "does": "جهت کلی سرنخ بعدی را نشان می‌دهد — همیشه در دسترس", "always": true},
]

const USES_PER_STAGE := 2

static func tool(tool_id: String) -> Dictionary:
	for t: Dictionary in TOOLS:
		if String(t["id"]) == tool_id:
			return t
	return {}

static func companion(character_id: String) -> Dictionary:
	for c: Dictionary in COMPANIONS:
		if String(c["id"]) == character_id:
			return c
	return {}
