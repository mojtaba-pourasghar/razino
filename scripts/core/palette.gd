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

## The 2D restyle. The colours still come from the approved sheets, but they
## are used flat now: one fill, one lighter band, one darker lip. Nothing in
## this palette is a gradient stop any more.
# — surfaces (sampled from the approved sheets) ——————————
const NIGHT         := Color("01101C")  # behind everything, and bar tracks
const PANEL_DEEP    := Color("02182A")  # the body of every panel
const PANEL         := Color("052942")  # raised rows, item slots
const PANEL_LIGHT   := Color("0A3A5C")  # the lit top of a gradient
## The steel hairline around every panel and button in the sheets.
const PANEL_EDGE    := Color("2E6E96")

# — the action colour ——————————————————————————————————————
## Every call to action in the sheets is this petrol teal inside a gold
## frame: "شروع بازی", "ادامه", "ذخیره", "دریافت".
const ACTION        := Color("EEB43E")  # gold IS the action here
const ACTION_LIGHT  := Color("F3C34F")
const ACTION_DEEP   := Color("D68A1C")

# — gold (frames and plaques only) ————————————————————————
const GOLD_BRIGHT   := Color("EEB43E")
const GOLD          := Color("EEB43E")
const GOLD_DEEP     := Color("A46C23")  # corner brackets, gold edges
const GOLD_DARK     := Color("3E2F10")  # the line that seats metal on panel

## The ivy that grows over every corner in the sheets. It is the signature
## of this design and it was missing entirely from the first pass, which is
## most of why the screens read as a generic dark theme with gold lines.
const IVY           := Color("537D4A")
const IVY_LIGHT     := Color("7CA863")
const IVY_DEEP      := Color("2E4A2B")

# — the seven accents from the mockup's palette strip ——————
const BLUE          := Color("22749F")  # loading, experience, information
const TEAL          := Color("22C3B4")  # toggles, progress, experience
const GREEN         := Color("64D075")  # success, confirm
const GOLD_LIGHT    := Color("FDD075")  # plaque text, emphasis
const ORANGE        := Color("FCB34B")  # coins, soft warning
const RUBY          := Color("D3332A")  # hearts, health, danger
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
const PARCHMENT     := Color("F6E3C5")
const PARCHMENT_DIM := Color("E3C089")
const INK           := Color("3A2A15")
const INK_SOFT      := Color("6A5436")

# — text on dark ————————————————————————————————————————————
const SNOW          := Color("F2F6FA")
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
