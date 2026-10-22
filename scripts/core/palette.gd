class_name Palette
extends RefCounted
## Razino's visual identity — ornate storybook, not flat UI.
##
## The look is a painted scene seen THROUGH a gilded frame: deep teal-navy
## panels edged in gold, parchment for anything the player reads closely, and
## jewel colours for the things they collect. Every colour the game draws comes
## from here, which is what keeps sixteen screens looking like one product.

# — panels (the dark lacquer the gold sits on) ————————————
const NIGHT         := Color("0B1C2C")  # deepest, behind everything
const PANEL         := Color("12293E")  # standard panel fill
const PANEL_LIGHT   := Color("1B3A54")  # raised / hovered panel
const PANEL_DEEP    := Color("081524")  # inset wells, list rows

# — gold (the frame metal; always a gradient, never flat) ——
const GOLD_BRIGHT   := Color("F2D27E")  # top highlight on the bevel
const GOLD          := Color("D9AE55")  # the body of the metal
const GOLD_DEEP     := Color("A77B28")  # shadow side of the bevel
const GOLD_DARK     := Color("6B4C15")  # the line that separates metal from panel

# — jewels (actions and collectables) ——————————————————————
const TEAL          := Color("1F7F8C")  # secondary action
const TEAL_LIGHT    := Color("2FA3B2")
const TEAL_DEEP     := Color("12535C")
const RUBY          := Color("C4453F")  # danger, hearts
const RUBY_LIGHT    := Color("E0635C")
const EMERALD       := Color("3E8E5A")  # success, confirm
const AMETHYST      := Color("7B5BA6")  # gems, premium
const SAPPHIRE      := Color("3C6CB5")

# — parchment (reading surfaces) ————————————————————————————
const PARCHMENT     := Color("F2E3C3")
const PARCHMENT_DIM := Color("DCC9A2")
const INK           := Color("3A2A15")
const INK_SOFT      := Color("6A5436")

# — text on dark ————————————————————————————————————————————
const SNOW          := Color("F6EFE2")
const SNOW_SOFT     := Color("BBC7D4")
const LOCKED        := Color("4A5A6B")

# — geometry ——————————————————————————————————————————————
const R_SM := 8.0
const R_MD := 14.0
const R_LG := 22.0

## Thickness of the gilded edge. Two lines plus a bevel read as "metal" where
## a single stroke reads as "border".
const FRAME_W := 3.0
const FRAME_INNER_W := 1.0

## Minimum touch target in logical units (GDD §7.2 asks for ~48).
const TOUCH_MIN := 58.0

const PAD_XS := 6
const PAD_SM := 12
const PAD_MD := 20
const PAD_LG := 32

# — type scale (logical units at 1280x720) ————————————————
const FS_DISPLAY := 54
const FS_TITLE   := 36
const FS_HEADING := 28
const FS_BODY    := 24
const FS_LABEL   := 20
const FS_CAPTION := 17
