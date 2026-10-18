class_name MenuAcciones
extends CanvasLayer
# Pequeño menú junto a un objeto con varias actividades (ej.: alfombra -> leer / ver serie).

signal _resultado(id: String)

var _raiz: Control
var _panel: PanelContainer
var _col: VBoxContainer
var _items: Array = []

func _ready() -> void:
	layer = 11
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	_raiz.visible = false
	_raiz.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed:
			_resultado.emit(""))
	add_child(_raiz)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiEstilos.caja(Color(0.99, 0.95, 0.85, 0.98), UiEstilos.MARRON, 20, 5, 8))
	_raiz.add_child(_panel)
	var margen := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 14)
	_panel.add_child(margen)
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 8)
	margen.add_child(_col)

# items: [{id, texto, detalle, ok, razon}] -> devuelve el id elegido o "" si cancelan
func elegir(items: Array, ancla: Vector2) -> String:
	_items = items
	for c in _col.get_children():
		c.queue_free()
	_col.add_child(UiEstilos.etiqueta("¿Qué quieres hacer?", 20, UiEstilos.MARRON_CLARO))
	for i in items.size():
		var it: Dictionary = items[i]
		var b := UiEstilos.boton("%d · %s" % [i + 1, it["texto"]], "si" if it.get("ok", true) else "neutro", 22)
		b.custom_minimum_size = Vector2(320, 50)
		b.disabled = not it.get("ok", true)
		b.pressed.connect(func(): _resultado.emit(it["id"]))
		_col.add_child(b)
		var d := it.get("detalle", "") as String
		if not it.get("ok", true) and it.get("razon", "") != "":
			d = it["razon"]
		if d != "":
			var l := UiEstilos.etiqueta(d, 16, UiEstilos.ROJO if not it.get("ok", true) else UiEstilos.MARRON_CLARO)
			_col.add_child(l)
	_raiz.visible = true
	_panel.reset_size()
	await get_tree().process_frame
	var tam := _panel.size
	_panel.position = Vector2(clampf(ancla.x - tam.x / 2.0, 12.0, 1152.0 - tam.x - 12.0), clampf(ancla.y - tam.y - 20.0, 70.0, 648.0 - tam.y - 12.0))
	var id: String = await _resultado
	_raiz.visible = false
	return id

func _input(event: InputEvent) -> void:
	if not _raiz.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_resultado.emit("")
	for i in 2:
		if event.is_action_pressed("opcion_%d" % (i + 1)) and i < _items.size() and _items[i].get("ok", true):
			get_viewport().set_input_as_handled()
			_resultado.emit(_items[i]["id"])
