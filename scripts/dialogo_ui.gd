class_name DialogoUI
extends CanvasLayer
# Cuadro de diálogo con retrato, texto que se escribe solo y botones de decisión.
#   await dialogo.decir("Berny", "Hola…", color, retrato)
#   var i = await dialogo.elegir([{texto, estilo, detalle, habilitado, razon}, …])

signal _avanzar
signal _elegido(indice: int)

const VEL_TEXTO := 55.0          # letras por segundo

var _raiz: Control
var _caja: Panel
var _nombre_panel: Panel
var _nombre: Label
var _retrato_marco: Panel
var _retrato: TextureRect
var _texto: Label
var _flecha: Control
var _fila_opciones: HBoxContainer
var _tw: Tween
var _modo := ""        # "", "decir", "elegir"
var _escribiendo := false
var _botones: Array[Button] = []
var _opciones_ok: Array[bool] = []

func _ready() -> void:
	layer = 12
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.visible = false
	add_child(_raiz)

	_caja = Panel.new()
	_caja.position = Vector2(40, 470)
	_caja.size = Vector2(1072, 156)
	_caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_caja)

	_retrato_marco = Panel.new()
	_retrato_marco.position = Vector2(20, 14)
	_retrato_marco.size = Vector2(128, 128)
	_retrato_marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caja.add_child(_retrato_marco)
	_retrato = TextureRect.new()
	_retrato.position = Vector2(4, 4)
	_retrato.size = Vector2(120, 120)
	_retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_retrato.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_retrato_marco.add_child(_retrato)

	_nombre_panel = Panel.new()
	_nombre_panel.position = Vector2(168, -24)
	_nombre_panel.size = Vector2(230, 44)
	_nombre_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caja.add_child(_nombre_panel)
	_nombre = UiEstilos.etiqueta("", 24, Color(1, 0.96, 0.85))
	_nombre.set_anchors_preset(Control.PRESET_FULL_RECT)
	_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nombre.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_nombre_panel.add_child(_nombre)

	_texto = UiEstilos.etiqueta("", 26, UiEstilos.MARRON_CLARO)
	_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texto.custom_minimum_size = Vector2(300, 0)
	_texto.position = Vector2(168, 26)
	_texto.size = Vector2(870, 118)
	_caja.add_child(_texto)

	_flecha = Control.new()
	_flecha.position = Vector2(1030, 118)
	_flecha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tri := Polygon2D.new()
	tri.polygon = PackedVector2Array([Vector2(0, 0), Vector2(22, 0), Vector2(11, 15)])
	tri.color = UiEstilos.VERDE
	_flecha.add_child(tri)
	_caja.add_child(_flecha)
	var tf := create_tween().set_loops()
	tf.tween_property(_flecha, "modulate:a", 0.25, 0.5)
	tf.tween_property(_flecha, "modulate:a", 1.0, 0.5)

	_fila_opciones = HBoxContainer.new()
	_fila_opciones.alignment = BoxContainer.ALIGNMENT_CENTER
	_fila_opciones.add_theme_constant_override("separation", 40)
	_fila_opciones.position = Vector2(0, 318)
	_fila_opciones.size = Vector2(1152, 120)
	_fila_opciones.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_fila_opciones)

func esta_activo() -> bool:
	return _raiz.visible

func _estilo_caja(pensando: bool) -> void:
	var bg := Color(0.93, 0.95, 0.91, 0.97) if pensando else Color(0.99, 0.95, 0.85, 0.97)
	_caja.add_theme_stylebox_override("panel", UiEstilos.caja(bg, Color(0.36, 0.24, 0.14), 22, 5, 6))

func decir(quien: String, texto: String, color: Color, retrato: Texture2D = null, pensando: bool = false) -> void:
	_raiz.visible = true
	_modo = "decir"
	_limpiar_opciones()
	_estilo_caja(pensando)
	_nombre.text = quien + (" (piensa)" if pensando else "")
	_nombre_panel.add_theme_stylebox_override("panel", UiEstilos.caja(color.darkened(0.1) if not pensando else Color(0.45, 0.52, 0.5), Color(0.36, 0.24, 0.14), 16, 4))
	_nombre_panel.size.x = maxf(210.0, 30.0 + _nombre.text.length() * 15.0)
	_retrato_marco.add_theme_stylebox_override("panel", UiEstilos.caja(color.lightened(0.55), Color(0.36, 0.24, 0.14), 64, 4))
	_retrato.texture = retrato
	_retrato_marco.visible = retrato != null
	_texto.position.x = 168.0 if retrato != null else 36.0
	_texto.size.x = 870.0 if retrato != null else 1000.0
	_texto.add_theme_color_override("font_color", Color(0.38, 0.40, 0.38) if pensando else UiEstilos.MARRON_CLARO)
	_texto.text = texto
	_texto.visible_ratio = 0.0
	_flecha.visible = false
	_escribiendo = true
	if _tw:
		_tw.kill()
	_tw = create_tween()
	_tw.tween_property(_texto, "visible_ratio", 1.0, maxf(0.15, texto.length() / VEL_TEXTO))
	_tw.finished.connect(_fin_escritura)
	await _avanzar
	_modo = ""

func _fin_escritura() -> void:
	_escribiendo = false
	_texto.visible_ratio = 1.0
	_flecha.visible = true

func ocultar() -> void:
	_modo = ""
	_limpiar_opciones()
	_raiz.visible = false

func _limpiar_opciones() -> void:
	for c in _fila_opciones.get_children():
		c.queue_free()
	_botones.clear()
	_opciones_ok.clear()

# opciones: [{texto, estilo ("si"/"no"), detalle, habilitado (bool), razon}]
func elegir(opciones: Array) -> int:
	_raiz.visible = true
	_limpiar_opciones()
	_modo = "elegir"
	for i in opciones.size():
		var o: Dictionary = opciones[i]
		var tarjeta := PanelContainer.new()       # fondo oscuro translúcido para que se lea sobre cualquier escenario
		tarjeta.add_theme_stylebox_override("panel", UiEstilos.caja(Color(0.14, 0.08, 0.04, 0.62), Color(0, 0, 0, 0), 20, 0))
		tarjeta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var margen := MarginContainer.new()
		for lado in ["left", "right", "top", "bottom"]:
			margen.add_theme_constant_override("margin_" + lado, 10)
		margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tarjeta.add_child(margen)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margen.add_child(col)
		var b := UiEstilos.boton(o["texto"], o.get("estilo", "neutro"), 25)
		b.custom_minimum_size = Vector2(330, 62)
		var ok: bool = o.get("habilitado", true)
		b.disabled = not ok
		b.pressed.connect(func(): _elegido.emit(i))
		col.add_child(b)
		var det := UiEstilos.etiqueta(o.get("detalle", ""), 19, Color(1, 0.96, 0.85), 7)
		det.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(det)
		if not ok and o.get("razon", "") != "":
			var r := UiEstilos.etiqueta(o["razon"], 18, Color(1, 0.72, 0.65), 7)
			r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			col.add_child(r)
		_fila_opciones.add_child(tarjeta)
		_botones.append(b)
		_opciones_ok.append(ok)
	var idx: int = await _elegido
	_limpiar_opciones()
	_modo = ""
	return idx

func _input(event: InputEvent) -> void:
	if not _raiz.visible:
		return
	if _modo == "decir":
		var clic: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
		var tecla: bool = (event.is_action_pressed("ui_accept") or event.is_action_pressed("interactuar")) and not event.is_echo()
		if clic or tecla:
			get_viewport().set_input_as_handled()
			if _escribiendo:
				if _tw:
					_tw.kill()
				_fin_escritura()
			else:
				_avanzar.emit()
	elif _modo == "elegir":
		for i in 2:
			if event.is_action_pressed("opcion_%d" % (i + 1)) and i < _opciones_ok.size() and _opciones_ok[i]:
				get_viewport().set_input_as_handled()
				_elegido.emit(i)
