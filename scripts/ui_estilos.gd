class_name UiEstilos
extends RefCounted
# Colores y estilos compartidos para que toda la interfaz se vea como el arte original.

const CREMA := Color(0.992, 0.937, 0.827)
const CREMA_OSC := Color(0.96, 0.87, 0.70)
const MARRON := Color(0.25, 0.15, 0.09)
const MARRON_CLARO := Color(0.43, 0.30, 0.18)
const VERDE := Color(0.43, 0.55, 0.37)
const VERDE_BARRA := Color(0.52, 0.68, 0.32)
const ROJO := Color(0.83, 0.27, 0.22)
const AMARILLO := Color(0.96, 0.75, 0.25)

static func caja(bg: Color, borde: Color = MARRON, radio: int = 18, grosor: int = 4, sombra: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = borde
	s.set_border_width_all(grosor)
	s.set_corner_radius_all(radio)
	if sombra > 0:
		s.shadow_color = Color(0, 0, 0, 0.28)
		s.shadow_size = sombra
		s.shadow_offset = Vector2(0, 3)
	return s

static func etiqueta(texto: String, tam: int = 20, color: Color = MARRON, contorno: int = 0) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	if contorno > 0:
		l.add_theme_color_override("font_outline_color", Color(0.22, 0.13, 0.07))
		l.add_theme_constant_override("outline_size", contorno)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

# estilo: "si" (verde), "no" (crema), "neutro"
static func boton(texto: String, estilo: String = "neutro", tam: int = 24) -> Button:
	var b := Button.new()
	b.text = texto
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", tam)
	var bg := CREMA
	var bg_h := Color(1.0, 0.97, 0.88)
	var txt := MARRON
	if estilo == "si":
		bg = VERDE
		bg_h = Color(0.50, 0.63, 0.43)
		txt = Color(1, 0.97, 0.88)
	b.add_theme_color_override("font_color", txt)
	b.add_theme_color_override("font_hover_color", txt)
	b.add_theme_color_override("font_pressed_color", txt)
	b.add_theme_color_override("font_disabled_color", Color(0.55, 0.47, 0.38))
	b.add_theme_stylebox_override("normal", caja(bg, MARRON, 16, 4, 4))
	b.add_theme_stylebox_override("hover", caja(bg_h, MARRON, 16, 4, 4))
	b.add_theme_stylebox_override("pressed", caja(bg.darkened(0.1), MARRON, 16, 4, 2))
	b.add_theme_stylebox_override("disabled", caja(Color(0.86, 0.80, 0.70), Color(0.5, 0.4, 0.3), 16, 3, 0))
	return b

static func tex(ruta: String) -> Texture2D:
	return load(ruta)
