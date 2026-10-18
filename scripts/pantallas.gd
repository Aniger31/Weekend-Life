class_name Pantallas
extends CanvasLayer
# Pantallas a pantalla completa: introducción, advertencia, derrota y pausa.
# Funcionan aunque el juego esté en pausa (process_mode = always).

signal _elegido(valor: String)

var _raiz: Control
var _en_pausa := false

func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS

func _nueva_base(color: Color) -> Control:
	if _raiz and is_instance_valid(_raiz):
		_raiz.queue_free()
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_raiz)
	var fondo := ColorRect.new()
	fondo.color = color
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(fondo)
	return _raiz

func _cerrar() -> void:
	if _raiz and is_instance_valid(_raiz):
		var r := _raiz
		_raiz = null
		var tw := r.create_tween()
		tw.tween_property(r, "modulate:a", 0.0, 0.25)
		tw.tween_callback(r.queue_free)

func _tarjeta(ancho: float, alto: float) -> Panel:
	var p := Panel.new()
	p.size = Vector2(ancho, alto)
	p.position = Vector2((1152.0 - ancho) / 2.0, (648.0 - alto) / 2.0)
	p.add_theme_stylebox_override("panel", UiEstilos.caja(Color(0.99, 0.95, 0.85, 0.98), UiEstilos.MARRON, 28, 6, 12))
	_raiz.add_child(p)
	return p

func _texto(padre: Control, texto: String, pos: Vector2, ancho: float, tam: int, color: Color = UiEstilos.MARRON, centrado: bool = true) -> Label:
	var l := UiEstilos.etiqueta(texto, tam, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART      # (primero el autowrap, luego el tamaño)
	l.custom_minimum_size = Vector2(ancho, 0)
	l.position = pos
	l.size = Vector2(ancho, 10)
	if centrado:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	padre.add_child(l)
	return l

# ------------------------------------------------------------------ introducción
func intro() -> void:
	var base := _nueva_base(Color(0.1, 0.12, 0.06, 0.0))
	var fondo := TextureRect.new()
	fondo.texture = load("res://backgrounds/fondo3.jpeg")
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	fondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fondo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.add_child(fondo)
	base.move_child(fondo, 0)
	var vel := ColorRect.new()
	vel.color = Color(0.12, 0.09, 0.05, 0.55)
	vel.set_anchors_preset(Control.PRESET_FULL_RECT)
	vel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.add_child(vel)

	# --- página 1: bienvenida ---
	var t := _tarjeta(880, 380)
	var retr := TextureRect.new()
	retr.texture = load("res://assets/sprites/retrato_nutrilda.png")
	retr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	retr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	retr.position = Vector2(352, 18)
	retr.size = Vector2(176, 176)
	t.add_child(retr)
	_texto(t, "¡Bienvenido al primer fin de semana de Nutrilda!", Vector2(40, 204), 800, 40)
	_texto(t, "Haz clic para continuar", Vector2(40, 320), 800, 20, UiEstilos.MARRON_CLARO)
	t.modulate.a = 0.0
	create_tween().tween_property(t, "modulate:a", 1.0, 0.6)
	await _esperar_clic()

	# --- página 2: objetivo y controles ---
	t.queue_free()
	var t2 := _tarjeta(940, 500)
	_texto(t2, "Tu objetivo", Vector2(40, 22), 860, 36, UiEstilos.VERDE)
	_texto(t2, "Tus amigos pueden pedirte favores, pero tú también tienes responsabilidades. Aprende a decidir cuándo ayudar y cuándo decir que no. ¡Administra tu tiempo y energía para terminar el fin de semana!", Vector2(50, 72), 840, 26)
	var ctrl := "Clic en un objeto o WASD / flechas: moverte\nE o Espacio: usar lo que tienes cerca\nC: beber café  ·  Tab: lista de pendientes  ·  Esc: pausa\nEl café es la única forma de recuperar energía."
	_texto(t2, ctrl, Vector2(50, 238), 840, 22, UiEstilos.MARRON_CLARO)
	var b := UiEstilos.boton("¡Comenzar!", "si", 30)
	b.position = Vector2(320, 392)
	b.size = Vector2(300, 66)
	b.pressed.connect(func(): _elegido.emit("ok"))
	t2.add_child(b)
	await _elegido
	_cerrar()

func _esperar_clic() -> void:
	var fin := [false]
	var sub := func(e: InputEvent):
		if fin[0]:
			return
		if (e is InputEventMouseButton and e.pressed) or e.is_action_pressed("ui_accept") or e.is_action_pressed("interactuar"):
			fin[0] = true
			_elegido.emit("clic")
	_raiz.gui_input.connect(sub)
	await _elegido
	if is_instance_valid(_raiz) and _raiz.gui_input.is_connected(sub):
		_raiz.gui_input.disconnect(sub)

# ------------------------------------------------------------------ advertencia
func advertencia(segundos: int) -> void:
	get_tree().paused = true
	var base := _nueva_base(Color(0.45, 0.07, 0.05, 0.62))
	var t := _tarjeta(860, 360)
	t.add_theme_stylebox_override("panel", UiEstilos.caja(Color(1.0, 0.94, 0.84, 0.99), UiEstilos.ROJO, 28, 8, 14))
	_texto(t, "WARNING", Vector2(30, 24), 800, 60, UiEstilos.ROJO)
	_texto(t, "¡Tienes demasiadas tareas pendientes!", Vector2(30, 104), 800, 36)
	_texto(t, "Ya no te alcanza el tiempo para terminar todo. Si sigue así, perderás el fin de semana en %d segundos. Rechazar un favor a tiempo también es cuidar de ti." % segundos, Vector2(50, 170), 760, 22, UiEstilos.MARRON_CLARO)
	var b := UiEstilos.boton("Entendido", "si", 28)
	b.position = Vector2(280, 270)
	b.size = Vector2(300, 64)
	b.pressed.connect(func(): _elegido.emit("ok"))
	t.add_child(b)
	base.modulate.a = 0.0
	create_tween().tween_property(base, "modulate:a", 1.0, 0.3)
	await _elegido
	_cerrar()
	get_tree().paused = false

# ------------------------------------------------------------------ derrota
# Devuelve "reiniciar" o "menu"
func derrota() -> String:
	get_tree().paused = true
	var base := _nueva_base(Color(0.07, 0.04, 0.03, 0.9))
	var t := _tarjeta(900, 430)
	_texto(t, "¡Se acabó el tiempo!", Vector2(30, 36), 840, 54, UiEstilos.ROJO)
	_texto(t, "Aceptaste más responsabilidades de las que podías manejar.", Vector2(50, 130), 800, 30)
	_texto(t, "La próxima vez recuerda: decir «no» con respeto es una forma de cuidar tu tiempo, tu energía y a las personas que quieres.", Vector2(60, 238), 780, 22, UiEstilos.MARRON_CLARO)
	var b1 := UiEstilos.boton("Reiniciar partida", "si", 26)
	b1.position = Vector2(110, 340)
	b1.size = Vector2(320, 64)
	b1.pressed.connect(func(): _elegido.emit("reiniciar"))
	t.add_child(b1)
	var b2 := UiEstilos.boton("Menú principal", "neutro", 26)
	b2.position = Vector2(470, 340)
	b2.size = Vector2(320, 64)
	b2.pressed.connect(func(): _elegido.emit("menu"))
	t.add_child(b2)
	base.modulate.a = 0.0
	create_tween().tween_property(base, "modulate:a", 1.0, 0.5)
	var r: String = await _elegido
	get_tree().paused = false
	return r

# ------------------------------------------------------------------ pausa
# Devuelve "seguir", "reiniciar" o "menu"
func pausa() -> String:
	get_tree().paused = true
	var base := _nueva_base(Color(0.06, 0.04, 0.02, 0.6))
	var t := _tarjeta(520, 420)
	_texto(t, "Pausa", Vector2(20, 26), 480, 50)
	var nombres := [["Continuar", "seguir", "si"], ["Reiniciar partida", "reiniciar", "neutro"], ["Menú principal", "menu", "neutro"]]
	for i in nombres.size():
		var b := UiEstilos.boton(nombres[i][0], nombres[i][2], 26)
		b.position = Vector2(80, 112 + i * 92)
		b.size = Vector2(360, 66)
		var v: String = nombres[i][1]
		b.pressed.connect(func(): _elegido.emit(v))
		t.add_child(b)
	_en_pausa = true
	var r: String = await _elegido
	_en_pausa = false
	get_tree().paused = false
	_cerrar()
	return r

func _input(event: InputEvent) -> void:
	if _en_pausa and event.is_action_pressed("ui_cancel"):
		_elegido.emit("seguir")
