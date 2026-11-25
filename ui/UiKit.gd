class_name UiKit
extends RefCounted
## Small helpers so every screen uses the same big, kid-friendly text and buttons.
## Owner: Alex. Replace with a proper Theme resource when the art style is decided.

const INK := Color("#212529")
const GREEN := Color("#2f9e44")
const CREAM := Color("#fff9db")


static func label(text: String, size: int = 28, color: Color = INK, outline: int = 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	return l


static func rich(size: int = 32, width: float = 600.0) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.custom_minimum_size = Vector2(width, 0)
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_color_override("default_color", INK)
	return r


static func button(text: String, size: int = 28, color: Color = GREEN) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", size)
	b.custom_minimum_size = Vector2(120, 64)  # large touch target for Grade 4 hands
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.set_corner_radius_all(18)
		sb.set_content_margin_all(12)
		match state:
			"hover":
				sb.bg_color = color.lightened(0.15)
			"pressed":
				sb.bg_color = color.darkened(0.2)
			"disabled":
				sb.bg_color = Color("#adb5bd")
			"focus":
				sb.bg_color = Color(0, 0, 0, 0)
				sb.draw_center = false
			_:
				sb.bg_color = color
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color("#f1f3f5"))
	return b


static func panel(bg: Color = CREAM, radius: int = 24) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(24)
	sb.border_color = Color("#495057")
	sb.set_border_width_all(3)
	p.add_theme_stylebox_override("panel", sb)
	return p
