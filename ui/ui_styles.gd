class_name UiStyles
extends RefCounted
## Names of the type variations in the project theme (res://ui/main_theme.tres). Code picks a
## look by setting `theme_type_variation` to one of these; the look itself lives in the theme.

## Large title text
const HEADER_LABEL := &"HeaderLabel"
## Small, muted text for hints and notes
const CAPTION_LABEL := &"CaptionLabel"
## Gold highlight text, such as a section name or a status
const TAG_LABEL := &"TagLabel"
## Large gold text for money
const MONEY_LABEL := &"MoneyLabel"
## A parchment panel, for papers and cards
const PAPER_PANEL := &"PaperPanel"
## Dark text on parchment
const PAPER_TEXT := &"PaperText"
const ACCEPT_BUTTON := &"AcceptButton"
const REFUSE_BUTTON := &"RefuseButton"
## A strip across the top of the screen, like the day's clock bar
const BAR_PANEL := &"BarPanel"
## A card the player picks up or opens, like a palette card or an item card, and how it looks
## under the mouse
const CARD_PANEL := &"CardPanel"
const CARD_PANEL_HOVER := &"CardPanelHover"
## A dark tooltip, for tooltips that show bright rune and material colours (the board's)
const DARK_TOOLTIP_PANEL := &"DarkTooltipPanel"

const CALENDAR_DAY := &"CalendarDay"
const CALENDAR_TODAY := &"CalendarToday"
const CALENDAR_PAST := &"CalendarPast"
const CALENDAR_OUTSIDE := &"CalendarOutside"
const CALENDAR_DAY_NUMBER := &"CalendarDayNumber"
const CALENDAR_WEEKDAY := &"CalendarWeekday"
const CALENDAR_SEASONAL_EVENT := &"CalendarSeasonalEvent"
const CALENDAR_APPLICATION_DAY := &"CalendarApplicationDay"
const CALENDAR_LETTER := &"CalendarLetter"
const CALENDAR_DEADLINE := &"CalendarDeadline"
const CALENDAR_CUSTOMER_RETURN := &"CalendarCustomerReturn"

## Every variation above, so a test can check the theme defines them all
const ALL: Array[StringName] = [
	HEADER_LABEL,
	CAPTION_LABEL,
	TAG_LABEL,
	MONEY_LABEL,
	PAPER_PANEL,
	PAPER_TEXT,
	ACCEPT_BUTTON,
	REFUSE_BUTTON,
	BAR_PANEL,
	CARD_PANEL,
	CARD_PANEL_HOVER,
	DARK_TOOLTIP_PANEL,
	CALENDAR_DAY,
	CALENDAR_TODAY,
	CALENDAR_PAST,
	CALENDAR_OUTSIDE,
	CALENDAR_DAY_NUMBER,
	CALENDAR_WEEKDAY,
	CALENDAR_SEASONAL_EVENT,
	CALENDAR_APPLICATION_DAY,
	CALENDAR_LETTER,
	CALENDAR_DEADLINE,
	CALENDAR_CUSTOMER_RETURN,
]
