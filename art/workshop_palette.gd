class_name WorkshopPalette
extends RefCounted

## The shop's shared placeholder look: the dark wood, brass and parchment colours of the counter
## (counter/counter_theme.tres), and the workbench art, so the counter and the inscribing table
## read as one place. Change a colour here to restyle every panel and card that uses it.

const WORKBENCH := preload("res://art/placeholder/workbench_wood.png")
## A nine-patch with LEATHER_MAT_MARGIN pixels of border on each side
const LEATHER_MAT := preload("res://art/placeholder/leather_mat.png")
const LEATHER_MAT_MARGIN := 28

const PANEL := Color(0.13, 0.11, 0.1)
const PANEL_SEE_THROUGH := Color(0.13, 0.11, 0.1, 0.96)
const BORDER := Color(0.45, 0.33, 0.2)
const CARD := Color(0.21, 0.16, 0.12)
const CARD_HOVER := Color(0.29, 0.22, 0.15)
const TEXT := Color(0.94, 0.9, 0.82)
const TEXT_DIM := Color(0.72, 0.66, 0.57)
## Headings, tags and notices
const BRASS := Color(0.96, 0.82, 0.46)
const TOOLTIP := Color(0.1, 0.09, 0.08, 0.97)
const TOOLTIP_BORDER := Color(0.6, 0.48, 0.3)
const DIM := Color(0, 0, 0, 0.6)


## A dark wood panel with a brass edge, like the counter's rulebook and supplier panels
static func panel_style(fill := PANEL, margin := 10.0, radius := 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(margin)
	return style


static func tooltip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = TOOLTIP
	style.border_color = TOOLTIP_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(10)
	return style
