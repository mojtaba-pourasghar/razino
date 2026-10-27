class_name Palette
extends RefCounted
## Razino's visual identity, sampled from the approved mockup sheet.
##
## Every value here was read off the reference image rather than chosen, so
## the game and the mockup cannot drift apart. docs/UI_SPEC.md records where
## each one was taken from and how the screens assemble them.
##
## The rule that shapes everything: GOLD IS FRAME AND PLAQUE, NEVER THE
## ACTION. The main button is deep petrol blue with a gold edge. An earlier
## pass spent gold on both the frames and the buttons, and the screens read
## flat because nothing stood out against anything.

# — surfaces (sampled from the approved sheets) ——————————
const NIGHT         := Color("081420")  # behind everything, almost black
const PANEL_DEEP    := Color("021F2F")  # the body of a framed panel
const PANEL         := Color("06283A")  # rows and inset wells
const PANEL_LIGHT   := Color("0B3146")  # title plaque, raised surfaces

# — the action colour ——————————————————————————————————————
## Every call to action in the sheets is this petrol teal inside a gold
## frame: "شروع بازی", "ادامه", "ذخیره", "دریافت".
const ACTION        := Color("0F666C")
const ACTION_LIGHT  := Color("1B9298")
const ACTION_DEEP   := Color("073B42")

# — gold (frames and plaques only) ————————————————————————
const GOLD_BRIGHT   := Color("EABD65")  # the metal of the frames and plaques
const GOLD          := Color("D9A94F")  # the lit band across a plaque
const GOLD_DEEP     := Color("795D22")  # shadow side of the bevel
const GOLD_DARK     := Color("3E2F10")  # the line that seats metal on panel

## The ivy that grows over every corner in the sheets. It is the signature
## of this design and it was missing entirely from the first pass, which is
## most of why the screens read as a generic dark theme with gold lines.
const IVY           := Color("537D4A")
const IVY_LIGHT     := Color("7CA863")
const IVY_DEEP      := Color("2E4A2B")

# — the seven accents from the mockup's palette strip ——————
const BLUE          := Color("389AE0")  # selected, active tab
const TEAL          := Color("22C3B4")  # toggles, progress, experience
const GREEN         := Color("64D075")  # success, confirm
const GOLD_LIGHT    := Color("FDD075")  # plaque text, emphasis
const ORANGE        := Color("FCB34B")  # coins, soft warning
const RUBY          := Color("D74148")  # hearts, danger, delete
const PURPLE        := Color("7448AF")  # gems, premium

# Older names kept pointing at the measured colours, so the screens that
# already speak this vocabulary keep working.
const TEAL_LIGHT    := Color("6FE6D6")
const TEAL_DEEP     := Color("1C8C7F")
const RUBY_LIGHT    := Color("E8686D")
const EMERALD       := GREEN
const AMETHYST      := PURPLE
const SAPPHIRE      := BLUE

# — parchment (anything the player reads) ————————————————
const PARCHMENT     := Color("F8DCAA")
const PARCHMENT_DIM := Color("E3C089")
const INK           := Color("3A2A15")
const INK_SOFT      := Color("6A5436")

# — text on dark ————————————————————————————————————————————
const SNOW          := Color("F6EFE2")
const SNOW_SOFT     := Color("A9BDC9")
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
