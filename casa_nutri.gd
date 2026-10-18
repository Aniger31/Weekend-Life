extends Node2D
# =====================================================================
#  CASA DE NUTRILDA — escena principal del juego.
#  Orquesta los sistemas (reloj, energía, café, tareas, visitas) y la
#  interfaz. La lógica de cada sistema vive en scripts/sistema_*.gd.
# =====================================================================

enum Estado { INTRO, LIBRE, CAMINANDO, MENU, ACCION, VISITA, TRANSICION, FIN }

const ESC_FONDO := 0.72
const PUERTA := Vector2(1052, 352)
const AREA_CAMINABLE := Rect2(125, 235, 880, 330)           # donde pueden pisar los PIES
const OBSTACULOS := [
	Rect2(120, 90, 225, 260),     # cama
	Rect2(795, 448, 215, 130),    # mesita
	Rect2(100, 318, 95, 117),     # planta
	Rect2(520, 376, 110, 62),     # puf
	Rect2(138, 462, 92, 84),      # escoba y trapeador
]
const RADIO_USO := 75.0
const ASIENTO_MESA := Vector2(902, 522)
const ASIENTO_PUF := Vector2(575, 414)
const POS_CAMA := Vector2(243, 232)
const ZONAS := {
	"cama": {"nombre": "Cama", "rect": Rect2(150, 95, 190, 230), "punto": Vector2(250, 360), "acciones": ["dormir"], "marca": Vector2(245, 205)},
	"fregadero": {"nombre": "Fregadero", "rect": Rect2(515, 98, 112, 100), "punto": Vector2(572, 246), "acciones": ["lavar_platos"], "marca": Vector2(570, 150)},
	"cafetera": {"nombre": "Cafetera", "rect": Rect2(770, 92, 90, 82), "punto": Vector2(812, 246), "acciones": ["preparar_cafe", "beber_cafe"], "marca": Vector2(812, 140)},
	"mesita": {"nombre": "Mesita", "rect": Rect2(800, 452, 205, 112), "punto": Vector2(905, 438), "acciones": ["comer"], "marca": Vector2(902, 482)},
	"planta": {"nombre": "Planta", "rect": Rect2(92, 300, 105, 135), "punto": Vector2(234, 432), "acciones": ["regar"], "marca": Vector2(145, 345)},
	"puf": {"nombre": "Puf", "rect": Rect2(520, 362, 110, 80), "punto": Vector2(575, 470), "acciones": ["leer", "ver_serie"], "marca": Vector2(575, 395)},
	"limpieza": {"nombre": "Escoba y trapeador", "rect": Rect2(135, 430, 100, 115), "punto": Vector2(268, 522), "acciones": ["trapear", "barrer"], "marca": Vector2(185, 470)},
}

var estado := Estado.INTRO
var _orden := 0
var _dia_pendiente := false
var _advertencia_pendiente := false
var _derrota_pendiente := false
var _pausado := false
var _factor_sueno := 0.0
var _acum_hud := 0.0
var _teclado_moviendo := false

var fondo_tex: Texture2D
var ambiente: CanvasModulate
var mundo: Node2D
var efectos: Node2D
var marcadores: Node2D
var nutria: Actor
var visitante: Actor
var oclusor_mesa: Node2D
var oclusor_cama: Node2D
var plato: Sprite2D
var prop_libro: AnimatedSprite2D
var prop_laptop: AnimatedSprite2D
var escoba: Sprite2D
var hud: Hud
var dialogo: DialogoUI
var menu: MenuAcciones
var vineta: VinetaAccion
var pantalla: PantallaNegra
var pantallas: Pantallas
var visitas: SistemaVisitas
var astar: AStarGrid2D
var retrato_nutrilda: Texture2D

# ===================================================================== inicio
func _ready() -> void:
	Partida.nueva_partida()
	Musica.iniciar()
	Musica.modo_juego()
	retrato_nutrilda = load("res://assets/sprites/retrato_nutrilda.png")
	_construir_mundo()
	_construir_interfaz()
	_preparar_astar()
	hud.conectar(Partida)
	Partida.reloj.cambio.connect(func(m: float, _d: int): _aplicar_ambiente(m))
	Partida.reloj.dia_terminado.connect(func(_d: int): _dia_pendiente = true)
	Partida.energia.entro_en_baja.connect(_al_entrar_en_baja)
	Partida.tareas.advertencia.connect(func(): _advertencia_pendiente = true)
	Partida.tareas.derrota.connect(func(): _derrota_pendiente = true)
	visitas = SistemaVisitas.new()
	visitas.puede_interrumpir = _puede_visita
	visitas.visita_lista.connect(_al_llegar_visita)
	add_child(visitas)
	_aplicar_ambiente(Partida.reloj.minutos)
	_comenzar.call_deferred()

func _comenzar() -> void:
	await pantallas.intro()
	estado = Estado.LIBRE
	visitas.iniciar()
	hud.aviso("¡Buenos días! Hoy es sábado. Haz clic en los objetos brillantes.")

func _construir_mundo() -> void:
	fondo_tex = load("res://backgrounds/fondo1.jpeg")
	var fondo := Sprite2D.new()
	fondo.texture = fondo_tex
	fondo.position = Vector2(576, 324)
	fondo.scale = Vector2(ESC_FONDO, ESC_FONDO)
	fondo.z_index = -100
	add_child(fondo)
	ambiente = CanvasModulate.new()
	add_child(ambiente)
	mundo = Node2D.new()
	mundo.y_sort_enabled = true
	add_child(mundo)
	_prop_fijo("puf", Vector2(575, 440))
	_prop_fijo("set_limpieza", Vector2(184, 546))
	oclusor_mesa = _crear_oclusor(Rect2(838, 446, 126, 134))
	oclusor_cama = _crear_oclusor(Rect2(147, 150, 190, 176))
	nutria = Actor.new()
	nutria.cargar_hoja("res://assets/sprites/nutrilda_sheet.png", FramesUtil.FILAS_NUTRILDA)
	nutria.position = Vector2(520, 330)
	mundo.add_child(nutria)
	visitante = Actor.new()
	visitante.visible = false
	mundo.add_child(visitante)
	efectos = Node2D.new()
	efectos.z_index = 30
	add_child(efectos)
	plato = Sprite2D.new()
	plato.texture = load("res://assets/props/plato.png")
	plato.position = Vector2(902, 494)
	plato.scale = Vector2(0.62, 0.62)
	plato.z_index = 8
	plato.visible = false
	add_child(plato)
	prop_libro = _prop_animado(["libro_a", "libro_b"], 1.4)
	prop_laptop = _prop_animado(["laptop_a", "laptop_b", "laptop_c"], 2.2)
	escoba = Sprite2D.new()
	escoba.texture = load("res://assets/props/escoba_mano.png")
	escoba.centered = false
	escoba.offset = Vector2(-17, -4)
	escoba.scale = Vector2(1.2, 1.2)
	escoba.visible = false
	escoba.z_index = 2
	nutria.add_child(escoba)
	marcadores = Node2D.new()
	marcadores.z_index = 12
	add_child(marcadores)
	var estrella := load("res://assets/props/estrella.png") as Texture2D
	for id in ZONAS:
		var s := Sprite2D.new()
		s.texture = estrella
		s.position = ZONAS[id]["marca"]
		s.modulate.a = 0.8
		marcadores.add_child(s)
		var tw := s.create_tween().set_loops()
		tw.tween_property(s, "scale", Vector2(1.25, 1.25), 0.7).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(s, "modulate:a", 0.35, 0.7)
		tw.tween_property(s, "scale", Vector2(0.8, 0.8), 0.7).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(s, "modulate:a", 0.85, 0.7)

func _prop_fijo(nombre: String, base: Vector2) -> void:
	var s := Sprite2D.new()
	s.texture = load("res://assets/props/%s.png" % nombre)
	s.centered = false
	s.offset = Vector2(-s.texture.get_width() / 2.0, -s.texture.get_height())
	s.position = base
	mundo.add_child(s)

func _prop_animado(nombres: Array, fps: float) -> AnimatedSprite2D:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation("a")
	sf.set_animation_speed("a", fps)
	sf.set_animation_loop("a", true)
	for n in nombres:
		sf.add_frame("a", load("res://assets/props/%s.png" % n))
	var a := AnimatedSprite2D.new()
	a.sprite_frames = sf
	a.z_index = 15
	a.visible = false
	add_child(a)
	return a

# Copia de un pedazo del fondo que se dibuja ENCIMA de Nutrilda (para que parezca
# sentada tras la mesa o acostada bajo la cobija).
func _crear_oclusor(rect: Rect2) -> Node2D:
	var cont := Node2D.new()                         # su posición = la BASE del recorte (para ordenar por profundidad)
	cont.position = Vector2(rect.position.x, rect.end.y)
	cont.visible = false
	var s := Sprite2D.new()
	s.texture = fondo_tex
	s.centered = false
	s.region_enabled = true
	# El fondo está a escala 0.72 con su esquina en (0,0): pixel de pantalla / 0.72 = pixel de la textura
	s.region_rect = Rect2(rect.position / ESC_FONDO, rect.size / ESC_FONDO)
	s.scale = Vector2(ESC_FONDO, ESC_FONDO)
	s.position = Vector2(0, -rect.size.y)
	cont.add_child(s)
	mundo.add_child(cont)
	return cont

func _construir_interfaz() -> void:
	hud = Hud.new()
	add_child(hud)
	hud.pidio_beber_cafe.connect(func(): _intentar_actividad("beber_cafe"))
	vineta = VinetaAccion.new()
	add_child(vineta)
	menu = MenuAcciones.new()
	add_child(menu)
	dialogo = DialogoUI.new()
	add_child(dialogo)
	pantalla = PantallaNegra.new()
	add_child(pantalla)
	pantallas = Pantallas.new()
	add_child(pantallas)

# ===================================================================== caminar
func es_transitable(p: Vector2) -> bool:
	if not AREA_CAMINABLE.has_point(p):
		return false
	for o in OBSTACULOS:
		if (o as Rect2).has_point(p):
			return false
	return true

func _preparar_astar() -> void:
	astar = AStarGrid2D.new()
	astar.region = Rect2i(0, 0, 72, 41)
	astar.cell_size = Vector2(16, 16)
	astar.offset = Vector2(8, 8)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	for x in 72:
		for y in 41:
			astar.set_point_solid(Vector2i(x, y), not es_transitable(Vector2(x * 16 + 8, y * 16 + 8)))

func _celda_libre(p: Vector2) -> Vector2i:
	var c := Vector2i(clampi(int(p.x / 16.0), 0, 71), clampi(int(p.y / 16.0), 0, 40))
	if not astar.is_point_solid(c):
		return c
	for r in range(1, 12):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var n := c + Vector2i(dx, dy)
				if astar.is_in_boundsv(n) and not astar.is_point_solid(n):
					return n
	return c

func _ruta(desde: Vector2, hasta: Vector2) -> Array:
	var a := _celda_libre(desde)
	var b := _celda_libre(hasta)
	var puntos: Array = Array(astar.get_point_path(a, b))
	if not puntos.is_empty():
		puntos.pop_front()
	if es_transitable(hasta):
		if not puntos.is_empty() and (puntos.back() as Vector2).distance_to(hasta) < 14.0:
			puntos.pop_back()
		puntos.append(hasta)
	return puntos

func _caminar_a(p: Vector2) -> bool:
	return await nutria.seguir_ruta(_ruta(nutria.position, p))

# ===================================================================== entrada
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and Config.ATAJOS_DE_PRUEBA:
		if event.physical_keycode == KEY_F9:
			visitas.forzar_visita()
			hud.aviso("[Prueba] Visita en camino")
		elif event.physical_keycode == KEY_F10:
			Partida.reloj.avanzar(60)
			hud.aviso("[Prueba] +60 minutos")
	if event.is_action_pressed("ui_cancel"):
		_pausar()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_clic(make_input_local(event).position)
	elif event.is_action_pressed("interactuar") and not event.is_echo():
		_interactuar()
	elif event.is_action_pressed("beber_cafe") and not event.is_echo():
		_pedir_beber()
	elif event.is_action_pressed("alternar_pendientes"):
		hud.alternar_pendientes()

func _libre() -> bool:
	return estado == Estado.LIBRE or estado == Estado.CAMINANDO

func _clic(pos: Vector2) -> void:
	if not _libre():
		return
	var z := _zona_en(pos)
	if z != "":
		_ir_a_zona(z)
	elif AREA_CAMINABLE.grow(30).has_point(pos):
		_orden += 1
		estado = Estado.CAMINANDO
		var mi := _orden
		var ok := await _caminar_a(pos)
		if mi == _orden:
			estado = Estado.LIBRE

func _zona_en(pos: Vector2) -> String:
	var mejor := ""
	var area_mejor := INF
	for id in ZONAS:
		var r: Rect2 = ZONAS[id]["rect"]
		if r.has_point(pos) and r.get_area() < area_mejor:
			mejor = id
			area_mejor = r.get_area()
	return mejor

func _zona_cercana() -> String:
	var mejor := ""
	var d_mejor := RADIO_USO
	for id in ZONAS:
		var d := nutria.position.distance_to(ZONAS[id]["punto"])
		if d <= d_mejor:
			mejor = id
			d_mejor = d
	return mejor

func _ir_a_zona(id: String) -> void:
	_orden += 1
	var mi := _orden
	estado = Estado.CAMINANDO
	hud.ocultar_prompt()
	var ok := await _caminar_a(ZONAS[id]["punto"])
	if mi != _orden or not ok:
		return
	estado = Estado.LIBRE
	nutria.mirar_hacia((ZONAS[id]["marca"] as Vector2).x)
	await _usar_zona(id)

func _interactuar() -> void:
	if estado != Estado.LIBRE:
		return
	var z := _zona_cercana()
	if z == "":
		hud.aviso("Acércate a un objeto brillante (o haz clic en él) y pulsa E o Espacio.")
		return
	nutria.mirar_hacia((ZONAS[z]["marca"] as Vector2).x)
	await _usar_zona(z)

func _pedir_beber() -> void:
	if estado == Estado.CAMINANDO:
		_orden += 1
		nutria.detener()
		estado = Estado.LIBRE
	if estado == Estado.LIBRE:
		await _intentar_actividad("beber_cafe")

func _usar_zona(id: String) -> void:
	var acciones: Array = ZONAS[id]["acciones"]
	var elegido: String = acciones[0]
	if acciones.size() > 1:
		estado = Estado.MENU
		hud.ocultar_prompt()
		var items: Array = []
		for a in acciones:
			items.append(_item_menu(a))
		elegido = await menu.elegir(items, ZONAS[id]["marca"])
		estado = Estado.LIBRE
	if elegido != "":
		await _intentar_actividad(elegido)

func _nombre_actividad(id: String) -> String:
	if id == "dormir":
		return "Organizar el descanso nocturno" if Partida.reloj.es_noche() else "Echar una siesta"
	return Config.ACTIVIDADES[id]["nombre"]

func _item_menu(id: String) -> Dictionary:
	var a: Dictionary = Config.ACTIVIDADES[id]
	var razon := _validar(id)
	var detalle := SistemaReloj.texto_duracion(a["min"])
	if a["energia"] > 0:
		detalle += "  ·  Energía -%d" % int(a["energia"])
	if id == "beber_cafe":
		detalle += "  ·  +%d energía" % int(Config.ENERGIA_POR_CAFE)
	return {"id": id, "texto": _nombre_actividad(id), "detalle": detalle, "ok": razon == "", "razon": razon}

# ===================================================================== actividades
# Devuelve el motivo por el que NO se puede hacer, o "" si se puede.
func _validar(id: String) -> String:
	var a: Dictionary = Config.ACTIVIDADES[id]
	var reloj: SistemaReloj = Partida.reloj
	if id == "dormir":
		if reloj.restante_dia() < 15.0:
			return "Ya casi es hora de dormir."
	elif reloj.restante_dia() < float(a["min"]):
		return "No te alcanza el tiempo de hoy."
	if a["energia"] > 0.0 and not Partida.energia.puede_pagar(a["energia"]):
		return "Estás muy cansada: prepara y bebe café."
	match id:
		"preparar_cafe":
			if Partida.cafe.esta_lleno():
				return "Ya hay suficiente café preparado."
		"beber_cafe":
			if not Partida.cafe.hay():
				return "No hay café: prepara un poco primero."
			if Partida.energia.esta_llena():
				return "Tu energía ya está al máximo."
		_:
			var tarea: String = a["tarea"]
			if tarea != "" and id != "dormir" and not Partida.tareas.hay_pendiente(tarea):
				return "Eso ya lo hiciste por ahora."
	return ""

func _intentar_actividad(id: String) -> void:
	if estado != Estado.LIBRE:
		return
	var razon := _validar(id)
	if razon != "":
		hud.aviso(razon, true)
		Musica.sfx("cansancio" if razon.begins_with("Estás muy cansada") else "advertencia")
		return
	await _ejecutar(id)

func _esperar(seg: float) -> void:
	await get_tree().create_timer(seg, false).timeout

func _ejecutar(id: String) -> void:
	var a: Dictionary = Config.ACTIVIDADES[id]
	estado = Estado.ACCION
	hud.ocultar_prompt()
	hud.ocultar_aviso()
	marcadores.visible = false
	var minutos: float = a["min"]
	if id == "dormir":
		minutos = minf(minutos, Partida.reloj.restante_dia())
	var seg: float = a["seg"]
	var era_noche := Partida.reloj.es_noche()
	hud.mostrar_accion(a["texto"], id == "beber_cafe")
	hud.atenuar_panel(id == "comer" or id == "preparar_cafe")
	Musica.sfx(a["sfx"])
	var acum := [0.0]
	var tw := create_tween()
	tw.tween_method(func(f: float):
		Partida.reloj.avanzar((f - acum[0]) * minutos)
		acum[0] = f
		hud.progreso_accion(f), 0.0, 1.0, seg)
	await _presentar(id, seg)
	if tw.is_running():
		await tw.finished
	hud.ocultar_accion()
	hud.atenuar_panel(false)
	_aplicar_efectos(id, era_noche)
	marcadores.visible = true
	estado = Estado.LIBRE
	await _revisar_pendientes()

func _aplicar_efectos(id: String, era_noche: bool) -> void:
	var a: Dictionary = Config.ACTIVIDADES[id]
	Partida.energia.consumir(a["energia"])
	match id:
		"preparar_cafe":
			var n := Partida.cafe.preparar()
			Efectos.texto_flotante(efectos, Vector2(812, 120), "+%d café" % n)
		"beber_cafe":
			Partida.cafe.servir()
			Partida.energia.recuperar(Config.ENERGIA_POR_CAFE)
			Partida.stats["cafes_bebidos"] += 1
			Efectos.texto_flotante(efectos, nutria.position + Vector2(0, -150), "+%d energía" % int(Config.ENERGIA_POR_CAFE), UiEstilos.AMARILLO)
	var tarea: String = a["tarea"]
	if tarea == "":
		return
	if id == "dormir" and not era_noche:
		hud.aviso("Solo fue una siesta: aún es temprano para tu descanso nocturno.")
		return
	if Partida.tareas.completar(tarea):
		Musica.sfx("tarea")
		Efectos.chispas(efectos, nutria.position + Vector2(0, -90), 9)

func _al_entrar_en_baja() -> void:
	hud.aviso("Estás muy cansada. Prepara café y bebe una taza, o descansa.", true)
	Musica.sfx("cansancio")

# ----- presentaciones (animación de cada actividad)
func _presentar(id: String, seg: float) -> void:
	match id:
		"preparar_cafe": await _pres_preparar(seg)
		"comer": await _pres_comer(seg)
		"leer": await _pres_puf("leer", prop_libro, seg)
		"ver_serie": await _pres_puf("serie", prop_laptop, seg)
		"barrer": await _pres_barrer(seg)
		"dormir": await _pres_dormir(seg)
		_: await _pres_vineta(id, seg)

func _pres_vineta(id: String, seg: float) -> void:
	nutria.visible = false
	vineta.mostrar(id)
	var tp := create_tween()
	tp.tween_method(vineta.progreso, 0.0, 1.0, maxf(0.1, seg - 0.4))
	await tp.finished
	await vineta.ocultar()
	nutria.visible = true

func _pres_preparar(seg: float) -> void:
	nutria.reproducir("preparar")
	var vapor := Efectos.vapor(efectos, Vector2(812, 128))
	await _esperar(seg)
	vapor.emitting = false
	get_tree().create_timer(2.0, false).timeout.connect(vapor.queue_free)
	nutria.reproducir("idle")

func _pres_comer(seg: float) -> void:
	var origen := nutria.position
	oclusor_mesa.visible = true
	var tw := create_tween()
	tw.tween_property(nutria, "position", ASIENTO_MESA, 0.7)
	await tw.finished
	nutria.flip_h = false
	nutria.reproducir("comer")
	plato.visible = true
	var vapor := Efectos.vapor(efectos, Vector2(902, 482), 0.6)
	await _esperar(maxf(0.1, seg - 1.5))
	vapor.queue_free()
	plato.visible = false
	var tw2 := create_tween()
	tw2.tween_property(nutria, "position", origen, 0.7)
	await tw2.finished
	oclusor_mesa.visible = false
	nutria.reproducir("idle")

func _pres_puf(anim: String, prop: AnimatedSprite2D, seg: float) -> void:
	var origen := nutria.position
	var tw := create_tween()
	tw.tween_property(nutria, "position", ASIENTO_PUF, 0.7)
	await tw.finished
	nutria.flip_h = false
	nutria.reproducir(anim)
	prop.position = ASIENTO_PUF + (Vector2(0, -50) if anim == "leer" else Vector2(0, -34))
	prop.visible = true
	prop.play("a")
	await _esperar(maxf(0.1, seg - 1.5))
	prop.visible = false
	prop.stop()
	var tw2 := create_tween()
	tw2.tween_property(nutria, "position", origen, 0.7)
	await tw2.finished
	nutria.reproducir("idle")

func _pres_barrer(seg: float) -> void:
	nutria.reproducir("barrer")
	escoba.visible = true
	var swing := escoba.create_tween().set_loops()
	swing.tween_property(escoba, "rotation", 0.5, 0.35).set_trans(Tween.TRANS_SINE)
	swing.tween_property(escoba, "rotation", -0.2, 0.35).set_trans(Tween.TRANS_SINE)
	var puntos := [Vector2(330, 470), Vector2(450, 520), Vector2(560, 490), Vector2(680, 525), Vector2(790, 490), Vector2(700, 420), Vector2(450, 420)]
	var t_tramo := (seg - 0.6) / puntos.size()
	for p in puntos:
		nutria.flip_h = p.x < nutria.position.x
		escoba.position = Vector2(-70 if nutria.flip_h else 36, -84) / ESC_PROP
		var tw := create_tween()
		tw.tween_property(nutria, "position", p, t_tramo)
		await tw.finished
	swing.kill()
	escoba.visible = false
	nutria.reproducir("idle")

const ESC_PROP := 0.62

func _pres_dormir(seg: float) -> void:
	var origen := nutria.position
	var t1 := seg * 0.42
	# 1) ilustración: tender la cama
	nutria.visible = false
	vineta.mostrar("dormir")
	var tp := create_tween()
	tp.tween_method(vineta.progreso, 0.0, 1.0, maxf(0.1, t1 - 0.4))
	await tp.finished
	await vineta.ocultar()
	# 2) Nutrilda duerme bajo la cobija mientras anochece
	nutria.position = POS_CAMA
	nutria.flip_h = false
	nutria.visible = true
	oclusor_cama.visible = true
	nutria.reproducir("dormir")
	var oscuro := create_tween()
	oscuro.tween_method(_set_sueno, 0.0, 1.0, 1.0)
	var restante := maxf(0.2, seg - t1 - 1.0)
	var zzz_n := 0
	while restante > 0.0:
		_lanzar_zzz(zzz_n)
		zzz_n += 1
		await _esperar(minf(0.9, restante))
		restante -= 0.9
	var claro := create_tween()
	claro.tween_method(_set_sueno, 1.0, 0.0, 0.8)
	await claro.finished
	oclusor_cama.visible = false
	nutria.position = origen
	nutria.reproducir("idle")

func _set_sueno(v: float) -> void:
	_factor_sueno = v
	_aplicar_ambiente(Partida.reloj.minutos)

func _lanzar_zzz(i: int) -> void:
	var z := Sprite2D.new()
	z.texture = load("res://assets/props/zzz.png")
	z.position = Vector2(290 + (i % 2) * 14, 110)
	z.scale = Vector2(0.4, 0.4)
	efectos.add_child(z)
	var tw := z.create_tween().set_parallel(true)
	tw.tween_property(z, "position", z.position + Vector2(26, -56), 1.6)
	tw.tween_property(z, "scale", Vector2(0.75, 0.75), 1.6)
	tw.tween_property(z, "modulate:a", 0.0, 1.6).set_delay(0.5)
	tw.chain().tween_callback(z.queue_free)

# ===================================================================== ambiente
func _aplicar_ambiente(minutos: float) -> void:
	var h := minutos / 60.0
	var col := Color.WHITE
	if h > Config.HORA_ATARDECER:
		var t := clampf((h - Config.HORA_ATARDECER) / 2.0, 0.0, 1.0)
		col = Color.WHITE.lerp(Color(1.0, 0.88, 0.74), t)
		var t2 := clampf((h - 19.0) / 3.0, 0.0, 1.0)
		col = col.lerp(Color(0.60, 0.64, 0.88), t2)
	ambiente.color = col.darkened(0.45 * _factor_sueno)

# ===================================================================== frame a frame
func _process(delta: float) -> void:
	if estado == Estado.INTRO:
		return
	if _libre():
		if Config.RITMO_TIEMPO_LIBRE > 0.0:
			Partida.reloj.avanzar(delta * Config.RITMO_TIEMPO_LIBRE)
		_mover_con_teclado(delta)
	if estado in [Estado.LIBRE, Estado.CAMINANDO, Estado.ACCION, Estado.MENU]:
		var rojo := Partida.tareas.esta_en_rojo(Partida.reloj.restante_fin_de_semana())
		Partida.tareas.actualizar_rojo(delta, rojo)
	_acum_hud += delta
	if _acum_hud >= 0.5:
		_acum_hud = 0.0
		hud.actualizar_pendientes()
	_actualizar_prompt()
	_revisar_pendientes()

func _mover_con_teclado(delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	dir += Vector2(
		int(Input.is_physical_key_pressed(KEY_D)) - int(Input.is_physical_key_pressed(KEY_A)),
		int(Input.is_physical_key_pressed(KEY_S)) - int(Input.is_physical_key_pressed(KEY_W)))
	dir = dir.limit_length(1.0)
	if dir == Vector2.ZERO:
		if _teclado_moviendo:
			_teclado_moviendo = false
			nutria.play(nutria.animacion_base)
		return
	if estado == Estado.CAMINANDO:
		_orden += 1
		nutria.detener()
		estado = Estado.LIBRE
	var paso := dir * nutria.velocidad * delta
	var intento := nutria.position + Vector2(paso.x, 0)
	if es_transitable(intento):
		nutria.position = intento
	intento = nutria.position + Vector2(0, paso.y)
	if es_transitable(intento):
		nutria.position = intento
	if absf(dir.x) > 0.1:
		nutria.flip_h = dir.x < 0.0
	if not _teclado_moviendo:
		_teclado_moviendo = true
		nutria.play("caminar")

func _actualizar_prompt() -> void:
	if estado != Estado.LIBRE:
		hud.ocultar_prompt()
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		return
	var z := _zona_cercana()
	var hover := _zona_en(get_global_mouse_position())
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if hover != "" else Input.CURSOR_ARROW)
	if z != "":
		var acc: Array = ZONAS[z]["acciones"]
		var txt: String = ZONAS[z]["nombre"] if acc.size() > 1 else _nombre_actividad(acc[0])
		hud.mostrar_prompt("E / Espacio  ·  %s" % txt, ZONAS[z]["marca"] + Vector2(0, -22))
	elif hover != "":
		hud.mostrar_prompt(ZONAS[hover]["nombre"], ZONAS[hover]["marca"] + Vector2(0, -22))
	else:
		hud.ocultar_prompt()

func _revisar_pendientes() -> void:
	if estado != Estado.LIBRE:
		return
	if _dia_pendiente:
		_dia_pendiente = false
		_terminar_dia()
	elif _derrota_pendiente:
		_derrota_pendiente = false
		_mostrar_derrota()
	elif _advertencia_pendiente:
		_advertencia_pendiente = false
		_mostrar_advertencia()

func _pausar() -> void:
	if _pausado or estado == Estado.INTRO or estado == Estado.FIN or estado == Estado.TRANSICION:
		return
	_pausado = true
	var r := await pantallas.pausa()
	_pausado = false
	match r:
		"reiniciar":
			get_tree().reload_current_scene()
		"menu":
			get_tree().change_scene_to_file("res://main.tscn")

func _mostrar_advertencia() -> void:
	estado = Estado.MENU
	hud.ocultar_prompt()
	Musica.sfx("advertencia")
	await pantallas.advertencia(int(Config.DERROTA_SEG_TRAS_ADVERTENCIA))
	estado = Estado.LIBRE

func _mostrar_derrota() -> void:
	estado = Estado.FIN
	visitas.detener()
	hud.ocultar_prompt()
	Musica.sfx("advertencia")
	var r := await pantallas.derrota()
	if r == "reiniciar":
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file("res://main.tscn")

# ===================================================================== visitas
func _puede_visita() -> bool:
	return _libre() and not _dia_pendiente and not _derrota_pendiente and not _advertencia_pendiente \
		and Partida.reloj.restante_dia() >= float(Config.VISITA_MIN_RESTANTE) and not _pausado

func _al_llegar_visita(v: Dictionary) -> void:
	_orden += 1
	nutria.detener()
	_teclado_moviendo = false
	estado = Estado.VISITA
	var npc: Dictionary = DatosDialogos.NPCS[v["npc"]]
	hud.ocultar_prompt()
	hud.ocultar_aviso()
	hud.forzar_ocultar_panel(true)
	marcadores.visible = false
	Musica.sfx("visita")
	await pantalla.cubrir(0.5)
	await pantalla.linea("¡Tienes una visita!", 54, UiEstilos.AMARILLO)
	await pantalla.linea("%s entró en tu casa." % npc["nombre"], 40)
	await pantalla.esperar(1.8)
	visitante.cargar_hoja(npc["hoja"], FramesUtil.FILAS_NPC)
	visitante.position = PUERTA
	visitante.modulate.a = 1.0
	visitante.visible = true
	await pantalla.descubrir(0.5)
	var destino := _punto_encuentro()
	await visitante.seguir_ruta([destino])
	visitante.mirar_hacia(nutria.position.x)
	nutria.mirar_hacia(visitante.position.x)
	var se_fue_con_nutrilda := false
	if v["tipo"] == "favor":
		se_fue_con_nutrilda = await _dialogo_favor(v["favor"], npc)
	else:
		await _dialogo_cafe(npc)
	dialogo.ocultar()
	if not se_fue_con_nutrilda:
		await _despedir_visitante()
	visitante.visible = false
	visitas.visita_terminada()
	hud.forzar_ocultar_panel(false)
	marcadores.visible = true
	estado = Estado.LIBRE
	await _revisar_pendientes()

func _punto_encuentro() -> Vector2:
	var x := nutria.position.x + 190.0
	if x > 960.0:
		x = nutria.position.x - 190.0
	return Vector2(clampf(x, 260.0, 960.0), clampf(nutria.position.y, 300.0, 400.0))

func _despedir_visitante() -> void:
	await visitante.seguir_ruta([PUERTA])
	var tw := create_tween()
	tw.tween_property(visitante, "modulate:a", 0.0, 0.3)
	await tw.finished

func _decir_npc(npc: Dictionary, texto: String) -> void:
	visitante.reproducir("hablar")
	await dialogo.decir(npc["nombre"], texto, npc["color"], load(npc["retrato"]))
	visitante.reproducir("idle")

func _decir_nutrilda(texto: String, pensando: bool = false) -> void:
	if not pensando:
		nutria.reproducir("hablar")
	await dialogo.decir(DatosDialogos.NOMBRE_NUTRILDA, texto, UiEstilos.VERDE, retrato_nutrilda, pensando)
	nutria.reproducir("idle")

# Devuelve true si Nutrilda acepta y se va con el amigo (pantalla negra).
func _dialogo_favor(f: Dictionary, npc: Dictionary) -> bool:
	await _decir_npc(npc, f["npc_dice"])
	await _decir_nutrilda(f["piensa"], true)
	var energia_ok := Partida.energia.puede_pagar(f["energia"])
	var tiempo_ok := Partida.reloj.restante_dia() >= float(f["horas"]) * 60.0
	var razon := ""
	if not energia_ok:
		razon = "Estás demasiado cansada"
	elif not tiempo_ok:
		razon = "No hay tiempo suficiente hoy"
	var opciones := [
		{"texto": "Sí, acepto", "estilo": "si", "detalle": "%d h  ·  Energía -%d" % [f["horas"], int(f["energia"])],
			"habilitado": energia_ok and tiempo_ok, "razon": razon},
		{"texto": "No, rechazo amablemente", "estilo": "no", "detalle": "Sin gasto de tiempo ni de energía", "habilitado": true},
	]
	var i := await dialogo.elegir(opciones)
	if i == 0:
		await _decir_nutrilda(f["acepta"])
		dialogo.ocultar()
		await _favor_aceptado(f, npc)
		return true
	# --- rechaza ---
	Partida.stats["favores_rechazados"] += 1
	Musica.sfx("rechazar")
	var cansada := Partida.energia.esta_baja() or not energia_ok
	await _decir_nutrilda(DatosDialogos.frase_rechazo(f["rechaza"], cansada))
	await _decir_npc(npc, (npc["comprension"] as Array).pick_random())
	return false

func _favor_aceptado(f: Dictionary, npc: Dictionary) -> void:
	Partida.stats["favores_aceptados"] += 1
	Musica.sfx("aceptar")
	await pantalla.cubrir(0.6)
	visitante.visible = false
	await pantalla.linea(f["pantalla"], 42, UiEstilos.AMARILLO)
	var horas: int = f["horas"]
	await pantalla.linea("Han pasado %d hora%s..." % [horas, "" if horas == 1 else "s"], 34)
	var ini := Partida.reloj.minutos
	var fin := minf(ini + horas * 60.0, float(Config.MIN_FIN_DIA))
	await pantalla.progreso_hora(ini, fin, 2.2)
	Partida.reloj.avanzar(horas * 60.0)
	Partida.energia.consumir(f["energia"])
	await pantalla.linea("Energía  -%d" % int(f["energia"]), 30, Color(1.0, 0.62, 0.55))
	await pantalla.esperar(1.6)
	await pantalla.descubrir(0.6)
	var pend := Partida.tareas.cuantas_pendientes()
	if pend > 0 and not _dia_pendiente:
		hud.aviso("Ayudaste a %s, pero tus %d pendientes siguen esperando." % [npc["nombre"], pend])

func _dialogo_cafe(npc: Dictionary) -> void:
	await _decir_npc(npc, npc["cafe"])
	var tazas: int = Partida.cafe.tazas
	var piensa := (DatosDialogos.CAFE_PIENSA_CON % [tazas, npc["nombre"]]) if tazas > 0 else DatosDialogos.CAFE_PIENSA_SIN
	await _decir_nutrilda(piensa, true)
	var energia_ok := Partida.energia.puede_pagar(Config.CAFE_NPC_ENERGIA)
	var tiempo_ok := Partida.reloj.restante_dia() >= float(Config.CAFE_NPC_MIN)
	var detalle := "-1 taza  ·  %d min  ·  Energía -%d" % [Config.CAFE_NPC_MIN, int(Config.CAFE_NPC_ENERGIA)] if tazas > 0 else "No tienes café preparado"
	var opciones := [
		{"texto": "Sí, acepto", "estilo": "si", "detalle": detalle,
			"habilitado": tazas == 0 or (energia_ok and tiempo_ok), "razon": "Estás demasiado cansada" if not energia_ok else "No hay tiempo suficiente"},
		{"texto": "No, rechazo amablemente", "estilo": "no", "detalle": "No gastas café, energía ni tiempo", "habilitado": true},
	]
	var i := await dialogo.elegir(opciones)
	if i == 0:
		if tazas > 0:
			await _decir_nutrilda(DatosDialogos.CAFE_ACEPTA)
			dialogo.ocultar()
			await _entregar_cafe()
			Partida.cafe.servir()
			Partida.reloj.avanzar(Config.CAFE_NPC_MIN)
			Partida.energia.consumir(Config.CAFE_NPC_ENERGIA)
			Partida.stats["cafes_servidos"] += 1
			await _decir_npc(npc, npc["gracias_cafe"])
		else:
			await _decir_nutrilda(DatosDialogos.CAFE_SIN_STOCK)
			await _decir_npc(npc, (npc["comprension"] as Array).pick_random())
	else:
		Musica.sfx("rechazar")
		var cansada := Partida.energia.esta_baja()
		await _decir_nutrilda(DatosDialogos.frase_rechazo("", cansada))
		await _decir_npc(npc, (npc["comprension"] as Array).pick_random())

# Animación de entrega: la taza vuela de Nutrilda al visitante
func _entregar_cafe() -> void:
	Musica.sfx("cafe_beber")
	var taza := Sprite2D.new()
	taza.texture = load("res://assets/props/taza.png")
	taza.position = nutria.position + Vector2(0, -85)
	taza.z_index = 40
	efectos.add_child(taza)
	var destino := visitante.position + Vector2(0, -85)
	var medio := (taza.position + destino) / 2.0 + Vector2(0, -50)
	var tw := create_tween()
	tw.tween_property(taza, "position", medio, 0.45).set_ease(Tween.EASE_OUT)
	tw.tween_property(taza, "position", destino, 0.45).set_ease(Tween.EASE_IN)
	await tw.finished
	Efectos.chispas(efectos, destino, 7)
	var vapor := Efectos.vapor(efectos, destino + Vector2(0, -14), 0.6)
	await _esperar(0.9)
	vapor.queue_free()
	taza.queue_free()

# ===================================================================== fin de día / fin de fin de semana
func _terminar_dia() -> void:
	estado = Estado.TRANSICION
	hud.ocultar_prompt()
	visitas.detener()
	if Partida.reloj.es_ultimo_dia():
		await _fin_de_semana()
	else:
		await _noche_y_nuevo_dia()

func _noche_y_nuevo_dia() -> void:
	hud.ocultar_aviso()
	Musica.sfx("dormir")
	await pantalla.cubrir(0.9)
	await pantalla.linea("Son las 10:00 p. m.", 32, Color(0.85, 0.8, 0.7))
	await pantalla.linea("Nutrilda se fue a dormir…", 52)
	var pend := Partida.tareas.cuantas_pendientes()
	if pend > 0:
		await pantalla.linea("Tus %d pendientes pasan al domingo." % pend, 28, Color(1.0, 0.8, 0.6))
	await pantalla.esperar(3.4)
	pantalla.limpiar_texto()
	Partida.reloj.nuevo_dia()
	Partida.tareas.iniciar_dia_nuevo()
	_dia_pendiente = false
	nutria.position = Vector2(520, 330)
	nutria.reproducir("idle")
	await pantalla.linea(Partida.reloj.nombre_dia(), 64, UiEstilos.AMARILLO)
	await pantalla.linea("¡Buenos días, Nutrilda!", 34)
	await pantalla.esperar(2.0)
	await pantalla.descubrir(0.9)
	visitas.reanudar()
	estado = Estado.LIBRE
	hud.aviso("Domingo: tu último día. ¡Aprovecha bien tu tiempo!")

func _fin_de_semana() -> void:
	hud.ocultar_aviso()
	Musica.modo_fin()
	await pantalla.cubrir(1.0)
	await pantalla.linea("¡Se terminó tu fin de semana!", 56, UiEstilos.AMARILLO)
	var tr: SistemaTareas = Partida.tareas
	var st: Dictionary = Partida.stats
	await pantalla.linea("Pendientes completados: %d de %d" % [tr.completadas, tr.generadas], 30)
	await pantalla.linea("Favores aceptados: %d  ·  Favores rechazados: %d" % [st["favores_aceptados"], st["favores_rechazados"]], 28)
	var mensaje := "Decir «no» a tiempo también es cuidar de ti."
	if tr.cuantas_pendientes() == 0:
		mensaje = "¡Lo lograste! Ayudaste y también cuidaste de tu tiempo."
	elif st["favores_aceptados"] >= 4:
		mensaje = "Dijiste que sí a casi todo… y tus pendientes lo notaron."
	await pantalla.linea(mensaje, 30, Color(1.0, 0.86, 0.6))
	await pantalla.esperar(7.0)
	estado = Estado.FIN
	Partida.creditos_vuelven_al_menu = true
	get_tree().change_scene_to_file("res://creditos.tscn")
