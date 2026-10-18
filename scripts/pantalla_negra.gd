class_name PantallaNegra
extends CanvasLayer
# Transiciones en pantalla negra con texto (visitas, favores aceptados, cambio de día).

signal clic
signal _despertar

var _raiz: Control
var _fondo: ColorRect
var _caja: VBoxContainer

func _ready() -> void:
	layer = 20
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_raiz)
	_fondo = ColorRect.new()
	_fondo.color = Color(0.04, 0.03, 0.03, 0.0)
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_fondo)
	_caja = VBoxContainer.new()
	_caja.set_anchors_preset(Control.PRESET_FULL_RECT)
	_caja.alignment = BoxContainer.ALIGNMENT_CENTER
	_caja.add_theme_constant_override("separation", 14)
	_caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_caja)

func esta_cubierta() -> bool:
	return _fondo.color.a > 0.01

func cubrir(t: float = 0.5) -> void:
	_fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_fondo, "color:a", 1.0, t)
	await tw.finished

func descubrir(t: float = 0.5) -> void:
	for c in _caja.get_children():
		c.queue_free()
	var tw := create_tween()
	tw.tween_property(_fondo, "color:a", 0.0, t)
	await tw.finished
	_fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE

func limpiar_texto() -> void:
	for c in _caja.get_children():
		c.queue_free()

# Añade una línea que aparece con fundido. Devuelve el Label para poder modificarlo.
func linea(texto: String, tam: int = 38, color: Color = UiEstilos.CREMA, fade: float = 0.6) -> Label:
	var l := UiEstilos.etiqueta(texto, tam, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(900, 0)
	l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	l.modulate.a = 0.0
	_caja.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "modulate:a", 1.0, fade)
	await tw.finished
	return l

# "10:00  →  13:00" avanzando suavemente (se usa una flecha dibujada con texto ASCII)
func progreso_hora(desde: float, hasta: float, dur: float) -> void:
	var l := UiEstilos.etiqueta("", 46, UiEstilos.AMARILLO)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	l.custom_minimum_size = Vector2(700, 0)
	_caja.add_child(l)
	var ini := SistemaReloj.texto_hora(desde)
	var tw := create_tween()
	tw.tween_method(func(v: float): l.text = "%s  >>  %s" % [ini, SistemaReloj.texto_hora(v)], desde, hasta, dur)
	await tw.finished

func esperar(t: float, saltable: bool = true) -> void:
	var fin := [false]
	var tm := get_tree().create_timer(t, false)
	tm.timeout.connect(func():
		if not fin[0]:
			fin[0] = true
			_despertar.emit())
	if saltable:
		clic.connect(func():
			if not fin[0]:
				fin[0] = true
				_despertar.emit(), CONNECT_ONE_SHOT)
	await _despertar

func _input(event: InputEvent) -> void:
	if not esta_cubierta():
		return
	if event is InputEventMouseButton and event.pressed:
		clic.emit()
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interactuar"):
		clic.emit()
