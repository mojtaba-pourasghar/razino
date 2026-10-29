class_name Palette
extends RefCounted
## Razino's visual identity: the night-town direction.
##
## Every value here was sampled by hue family from the approved mockup
## (assets/art/reference/direction.png) rather than chosen, so the game and
## the direction cannot drift apart.
##
## Three rules shape it, and the screens go flat the moment one is broken:
##
##  · THE GROUND IS INDIGO, NOT NAVY. Cooler and darker than before, so a
##    painted scene sits in front of it instead of competing with it.
##  · TEAL IS THE EDGE AND THE LIVE THING. Every rim, every meter, every
##    "this is on" is teal. It is what the eye follows.
##  · AMBER IS THE ACTION, AND THERE IS ONE PER SCREEN. Not frames, not
##    plaques, not decoration. The earlier palette spent gold on frames AND
##    buttons and nothing stood out against anything.
# — surfaces ————————————————————————————————————————————————
const NIGHT         := Color("050A16")  # behind everything, and bar tracks
const PANEL_DEEP    := Color("0A1426")  # the body of every panel
const PANEL         := Color("0F1C30")  # raised rows, item slots
const PANEL_LIGHT   := Color("17293F")  # the lit edge of a surface
## The thin rim around every panel and button.
const PANEL_EDGE    := Color("2E93A3")

# — the action colour ——————————————————————————————————————
## One amber button per screen, and nothing else amber.
const ACTION        := Color("E7AB38")
const ACTION_LIGHT  := Color("FFC65A")
const ACTION_DEEP   := Color("A5661C")

# — metal (frames and plaques only, and sparing) ————————————
## Burnt bronze, not gold. Gold frames plus gold buttons were half of why
## the previous direction read as a generic dark fantasy theme.
const GOLD_BRIGHT   := Color("C9953A")
const GOLD          := Color("A87C33")
const GOLD_DEEP     := Color("6B4A1C")
const GOLD_DARK     := Color("2A1D0C")

## Kept so older screens still compile. Nothing in this direction is green
## and nothing draws these.
const IVY           := Color("2A7E8C")
const IVY_LIGHT     := Color("3FB3B8")
const IVY_DEEP      := Color("12404A")

# — the seven accents from the mockup's palette strip ——————
const BLUE          := Color("2A6FA8")  # loading, information
const TEAL          := Color("22B8C4")  # toggles, progress, experience
const GREEN         := Color("64D075")  # success, confirm
const GOLD_LIGHT    := Color("F2CE85")  # plaque text, emphasis
const ORANGE        := Color("E7AB38")  # coins, soft warning
const RUBY          := Color("D3332A")  # hearts, health, danger
const PURPLE        := Color("7448AF")  # gems, premium

# Older names kept pointing at the measured colours, so the screens that
# already speak this vocabulary keep working.
const TEAL_LIGHT    := Color("5FE0E6")
const TEAL_DEEP     := Color("12707A")
const RUBY_LIGHT    := Color("E8686D")
const EMERALD       := GREEN
const AMETHYST      := PURPLE
const SAPPHIRE      := BLUE

# — parchment (anything the player reads) ————————————————
const PARCHMENT     := Color("F6E3C5")
const PARCHMENT_DIM := Color("E3C089")
const INK           := Color("3A2A15")
const INK_SOFT      := Color("6A5436")

# — text on dark ————————————————————————————————————————————
const SNOW          := Color("F2F6FA")
const SNOW_SOFT     := Color("9DB4C4")
const LOCKED        := Color("6A7681")  # a locked card is pale, not hidden

# — geometry ——————————————————————————————————————————————
const R_SM := 8.0
const R_MD := 16.0
const R_LG := 24.0
## A pill is as round as it is tall; this is "round enough" for any height.
const R_PILL := 999.0

## Thickness of the gilded edge. Two lines plus a bevel read as metal where
## a single stroke reads as a border.
const FRAME_W := 3.0
const FRAME_INNER_W := 1.0

## Minimum touch target in logical units (GDD §7.2 asks for ~48).
const TOUCH_MIN := 58.0
## The round controls in the mockup — back, gear, menu icons.
const MEDALLION := 56.0

const PAD_XS := 6
const PAD_SM := 12
const PAD_MD := 20
const PAD_LG := 32

# — type scale (logical units at 1280x720) ————————————————
const FS_DISPLAY := 54
const FS_TITLE   := 32
const FS_HEADING := 26
const FS_BODY    := 22
const FS_LABEL   := 20
const FS_CAPTION := 16
