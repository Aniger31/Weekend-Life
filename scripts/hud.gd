class_name Hud
extends CanvasLayer
# Interfaz: reloj, barra de energía, café, lista de pendientes, avisos y barra de acción.

signal pidio_beber_cafe

const UI := "res://assets/ui/"
const BADGE_DIA := Vector2(200, 75)
const BADGE_NOCHE := Vector2(200, 61)
const BADGE_POS := Vector2(322, 8)
const ENERGIA_POS := Vector2(532, 12)
const ENERGIA_TAM := Vector2(340, 38.4)
# zona interior del track de la barra (fracciones del arte original)
const TRACK_X0 := 0.4816
const TRACK_X1 := 0.9574
const TRACK_Y0 := 0.305
const TRACK_Y1 := 0.70

var _raiz: Control
var _reloj_tex: TextureRect
var _lbl_hora: Label
var _lbl_dia: Label
var _energia_tex: TextureRect
var _energia_fill: Panel
var _lbl_energia: Label
var _cafe_btn: Button
var _lbl_cafe: Label
var _btn_pend: Button
var _panel: NinePatchRect
var _vbox: VBoxContainer
var _lbl_pend: Label
var _lbl_tiempo: Label
var _lbl_derrota: Label
var _toast_caja: HBoxContainer
var _toast_panel: PanelContainer
var _toast_lbl: Label
var _toast_tw: Tween
var _accion: PanelContainer
var _accion_lbl: Label
var _accion_barra: ProgressBar
var _prompt: PanelContainer
var _prompt_lbl: Label
var _ayuda: Label
var _filas := {}                       # uid -> Control
var _energia_vis := 0.0
var _energia_tw: Tween
var _panel_visible := true
var _modo_cafe := false                # durante "beber café" solo se ve el mensaje
var _noche := false
var _ocultar_panel_forzado := false
var _atenuado := false

func _ready() -> void:
	layer = 10
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_raiz)
	_construir_barra_superior()
	_construir_panel_pendientes()
	_construir_avisos()
	_construir_accion()
	_construir_prompt()
	_ayuda = UiEstilos.etiqueta("Clic o WASD: moverte  ·  E / Espacio: usar  ·  C: beber café  ·  Tab: pendientes  ·  Esc: pausa", 15, Color(1, 0.97, 0.88), 6)
	_ayuda.position = Vector2(14, 620)
	_raiz.add_child(_ayuda)

# ------------------------------------------------------------------ construcción
func _construir_barra_superior() -> void:
	var banner := TextureRect.new()
	banner.texture = load(UI + "banner_dia_descanso.png")
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	banner.position = Vector2(10, 8)
	banner.size = Vector2(300, 51)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(banner)

	_reloj_tex = TextureRect.new()
	_reloj_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_reloj_tex.stretch_mode = TextureRect.STRETCH_SCALE
	_reloj_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_reloj_tex)
	_lbl_hora = UiEstilos.etiqueta("07:00", 34, Color(0.22, 0.12, 0.06))
	_lbl_hora.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_hora.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_reloj_tex.add_child(_lbl_hora)
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", UiEstilos.caja(UiEstilos.CREMA, UiEstilos.MARRON, 12, 3, 3))
	pill.position = Vector2(362, 80)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl_dia = UiEstilos.etiqueta("Sábado", 17, UiEstilos.MARRON)
	_lbl_dia.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_dia.custom_minimum_size = Vector2(110, 0)
	pill.add_child(_lbl_dia)
	_raiz.add_child(pill)
	_poner_badge(false)

	_energia_tex = TextureRect.new()
	_energia_tex.texture = load(UI + "energia_base.png")
	_energia_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_energia_tex.stretch_mode = TextureRect.STRETCH_SCALE
	_energia_tex.position = ENERGIA_POS
	_energia_tex.size = ENERGIA_TAM
	_energia_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_energia_tex)
	_energia_fill = Panel.new()
	_energia_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_energia_tex.add_child(_energia_fill)
	_lbl_energia = UiEstilos.etiqueta("Energía: 70 / 100", 16, Color(0.22, 0.12, 0.06))
	_lbl_energia.position = Vector2(13, 0)
	_lbl_energia.size = Vector2(148, ENERGIA_TAM.y)
	_lbl_energia.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_energia_tex.add_child(_lbl_energia)

	_cafe_btn = Button.new()
	_cafe_btn.focus_mode = Control.FOCUS_NONE
	_cafe_btn.position = Vector2(884, 10)
	_cafe_btn.size = Vector2(128, 44)
	_cafe_btn.tooltip_text = "Beber café (C)"
	for est in ["normal", "hover", "pressed", "disabled"]:
		var c := UiEstilos.CREMA if est != "hover" else Color(1, 0.97, 0.88)
		_cafe_btn.add_theme_stylebox_override(est, UiEstilos.caja(c, UiEstilos.MARRON, 16, 4, 3))
	_cafe_btn.pressed.connect(func(): pidio_beber_cafe.emit())
	_raiz.add_child(_cafe_btn)
	var taza := TextureRect.new()
	taza.texture = load("res://assets/props/taza.png")
	taza.expand_mode = TextureRect.EXPAND_IGNORE_SIZE      # (primero expand_mode, luego size)
	taza.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	taza.position = Vector2(8, 6)
	taza.size = Vector2(34, 32)
	taza.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cafe_btn.add_child(taza)
	_lbl_cafe = UiEstilos.etiqueta("x 0", 24, UiEstilos.MARRON)
	_lbl_cafe.position = Vector2(48, 5)
	_cafe_btn.add_child(_lbl_cafe)
	var tecla := UiEstilos.etiqueta("C", 13, UiEstilos.MARRON_CLARO)
	tecla.position = Vector2(106, 22)
	_cafe_btn.add_child(tecla)

	_btn_pend = UiEstilos.boton("Pendientes", "neutro", 18)
	_btn_pend.position = Vector2(1022, 10)
	_btn_pend.size = Vector2(122, 44)
	_btn_pend.tooltip_text = "Mostrar u ocultar la lista (Tab)"
	_btn_pend.pressed.connect(alternar_pendientes)
	_raiz.add_child(_btn_pend)

func _poner_badge(noche: bool) -> void:
	_noche = noche
	var tam := BADGE_NOCHE if noche else BADGE_DIA
	_reloj_tex.texture = load(UI + ("badge_noche.png" if noche else "badge_dia.png"))
	_reloj_tex.size = tam
	_reloj_tex.position = BADGE_POS + Vector2(0, (BADGE_DIA.y - tam.y) / 2.0)
	_lbl_hora.position = Vector2(tam.x * 0.43, tam.y * 0.12)
	_lbl_hora.size = Vector2(tam.x * 0.50, tam.y * 0.76)

func _construir_panel_pendientes() -> void:
	_panel = NinePatchRect.new()
	_panel.texture = load(UI + "panel_pendientes.png")
	_panel.patch_margin_left = 30
	_panel.patch_margin_right = 30
	_panel.patch_margin_top = 76
	_panel.patch_margin_bottom = 30
	_panel.position = Vector2(846, 104)
	_panel.size = Vector2(300, 340)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_panel)
	_vbox = VBoxContainer.new()
	_vbox.position = Vector2(34, 80)
	_vbox.size = Vector2(238, 10)
	_vbox.add_theme_constant_override("separation", 1)
	_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_vbox)
	_lbl_pend = UiEstilos.etiqueta("Pendientes: 9", 19, UiEstilos.MARRON)
	_vbox.add_child(_lbl_pend)
	_lbl_tiempo = UiEstilos.etiqueta("", 14, UiEstilos.MARRON_CLARO)
	_lbl_tiempo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_tiempo.custom_minimum_size = Vector2(238, 0)
	_lbl_derrota = UiEstilos.etiqueta("", 15, UiEstilos.ROJO)
	_lbl_derrota.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_derrota.custom_minimum_size = Vector2(238, 0)

func _construir_avisos() -> void:
	_toast_caja = HBoxContainer.new()
	_toast_caja.alignment = BoxContainer.ALIGNMENT_CENTER
	_toast_caja.position = Vector2(0, 118)
	_toast_caja.size = Vector2(840, 54)
	_toast_caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_caja.modulate.a = 0.0
	_raiz.add_child(_toast_caja)
	_toast_panel = PanelContainer.new()
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.add_theme_stylebox_override("panel", UiEstilos.caja(UiEstilos.CREMA, UiEstilos.MARRON, 18, 4, 6))
	_toast_caja.add_child(_toast_panel)
	var m := MarginContainer.new()
	for lado in ["left", "right"]:
		m.add_theme_constant_override("margin_" + lado, 20)
	for lado in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + lado, 7)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.add_child(m)
	_toast_lbl = UiEstilos.etiqueta("", 21, UiEstilos.MARRON)
	_toast_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m.add_child(_toast_lbl)

func _construir_accion() -> void:
	_accion = PanelContainer.new()
	_accion.add_theme_stylebox_override("panel", UiEstilos.caja(UiEstilos.CREMA, UiEstilos.MARRON, 18, 4, 6))
	_accion.position = Vector2(376, 556)
	_accion.custom_minimum_size = Vector2(400, 0)
	_accion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_accion.visible = false
	_raiz.add_child(_accion)
	var m := MarginContainer.new()
	for lado in ["left", "right"]:
		m.add_theme_constant_override("margin_" + lado, 18)
	for lado in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + lado, 8)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_accion.add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(v)
	_accion_lbl = UiEstilos.etiqueta("", 21, UiEstilos.MARRON)
	_accion_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_accion_lbl)
	_accion_barra = ProgressBar.new()
	_accion_barra.show_percentage = false
	_accion_barra.custom_minimum_size = Vector2(0, 14)
	_accion_barra.max_value = 1.0
	_accion_barra.add_theme_stylebox_override("background", UiEstilos.caja(Color(0.93, 0.85, 0.7), UiEstilos.MARRON, 7, 2))
	_accion_barra.add_theme_stylebox_override("fill", UiEstilos.caja(UiEstilos.VERDE_BARRA, Color(0.3, 0.4, 0.2), 7, 2))
	_accion_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(_accion_barra)

func _construir_prompt() -> void:
	_prompt = PanelContainer.new()
	_prompt.add_theme_stylebox_override("panel", UiEstilos.caja(Color(0.99, 0.95, 0.85, 0.96), UiEstilos.MARRON, 14, 3, 4))
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.visible = false
	_raiz.add_child(_prompt)
	var m := MarginContainer.new()
	for lado in ["left", "right"]:
		m.add_theme_constant_override("margin_" + lado, 12)
	for lado in ["top", "bottom"]:
		m.add_theme_constant_override("margin_" + lado, 5)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.add_child(m)
	_prompt_lbl = UiEstilos.etiqueta("", 18, UiEstilos.MARRON)
	m.add_child(_prompt_lbl)

# ------------------------------------------------------------------ conexión
func conectar(p: Node) -> void:
	p.reloj.cambio.connect(_al_cambiar_reloj)
	p.energia.cambio.connect(_al_cambiar_energia)
	p.cafe.cambio.connect(_al_cambiar_cafe)
	p.tareas.cambiaron.connect(_al_cambiar_tareas)
	p.tareas.tarea_completada.connect(_al_completar_tarea)
	refrescar_todo()

func refrescar_todo() -> void:
	var p := Partida
	_al_cambiar_reloj(p.reloj.minutos, p.reloj.dia)
	_energia_vis = p.energia.valor
	_dibujar_energia()
	_al_cambiar_cafe(p.cafe.tazas)
	_reconstruir_filas()
	actualizar_pendientes()

func _al_cambiar_reloj(minutos: float, dia: int) -> void:
	var noche := minutos >= Config.HORA_DESCANSO_NOCTURNO * 60.0 or minutos < 6.0 * 60.0
	if noche != _noche:
		_poner_badge(noche)
	_lbl_hora.text = SistemaReloj.texto_hora(minutos)
	_lbl_dia.text = Config.NOMBRES_DIA[dia]
	actualizar_pendientes()

func _al_cambiar_energia(valor: float, _maximo: float) -> void:
	if _energia_tw:
		_energia_tw.kill()
	_energia_tw = create_tween()
	_energia_tw.tween_method(func(v: float):
		_energia_vis = v
		_dibujar_energia(), _energia_vis, valor, 0.6)

func _dibujar_energia() -> void:
	var max_e: float = Partida.energia.maximo
	var ratio := clampf(_energia_vis / max_e, 0.0, 1.0)
	var baja: bool = _energia_vis <= max_e * Config.FRACCION_ENERGIA_BAJA + 0.001
	_lbl_energia.text = "Energía: %d / %d" % [int(round(_energia_vis)), int(max_e)]
	_lbl_energia.add_theme_color_override("font_color", UiEstilos.ROJO if baja else Color(0.22, 0.12, 0.06))
	var x0 := ENERGIA_TAM.x * TRACK_X0 + 2.0
	var x1 := ENERGIA_TAM.x * TRACK_X1 - 2.0
	var y0 := ENERGIA_TAM.y * TRACK_Y0 + 1.5
	var y1 := ENERGIA_TAM.y * TRACK_Y1 - 1.5
	_energia_fill.position = Vector2(x0, y0)
	_energia_fill.size = Vector2(maxf(0.0, (x1 - x0) * ratio), y1 - y0)
	_energia_fill.visible = ratio > 0.005
	var col := UiEstilos.ROJO if baja else UiEstilos.VERDE_BARRA
	_energia_fill.add_theme_stylebox_override("panel", UiEstilos.caja(col, col.darkened(0.45), int((y1 - y0) / 2.0), 1))

func _al_cambiar_cafe(tazas: int) -> void:
	_lbl_cafe.text = "x %d" % tazas

# ------------------------------------------------------------------ pendientes
func alternar_pendientes() -> void:
	_panel_visible = not _panel_visible
	_aplicar_visibilidad_panel()

func forzar_ocultar_panel(ocultar: bool) -> void:
	_ocultar_panel_forzado = ocultar
	_aplicar_visibilidad_panel()

# Hace casi transparente la lista mientras Nutrilda actúa justo debajo de ella (comer, café)
func atenuar_panel(v: bool) -> void:
	_atenuado = v
	_aplicar_visibilidad_panel()

func _aplicar_visibilidad_panel() -> void:
	var visible_ahora := _panel_visible and not _ocultar_panel_forzado
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", (0.15 if _atenuado else 1.0) if visible_ahora else 0.0, 0.25)
	_panel.visible = true
	if not visible_ahora:
		tw.tween_callback(func(): _panel.visible = _panel_visible and not _ocultar_panel_forzado)

func _al_cambiar_tareas() -> void:
	_reconstruir_filas()
	actualizar_pendientes()

func _reconstruir_filas() -> void:
	var lista: Array = Partida.tareas.lista
	var uids := lista.map(func(t): return t["uid"])
	# Quita filas de tareas que ya no existen (salvo las que están animando su salida)
	for uid in _filas.keys():
		var f = _filas[uid]
		if not is_instance_valid(f):
			_filas.erase(uid)
		elif not uids.has(uid) and not f.has_meta("saliendo"):
			f.queue_free()
			_filas.erase(uid)
	var faltan := false
	for t in lista:
		if not _filas.has(t["uid"]):
			faltan = true
	if faltan:       # tareas nuevas (cambio de día / partida nueva): se rehace toda la lista en orden
		for uid in _filas.keys():
			if is_instance_valid(_filas[uid]):
				_filas[uid].queue_free()
		_filas.clear()
		for t in lista:
			var fila := _crear_fila(t)
			_vbox.add_child(fila)
			_filas[t["uid"]] = fila
	_reordenar_pie()

func _reordenar_pie() -> void:
	for n in [_lbl_tiempo, _lbl_derrota]:
		if n.get_parent() == _vbox:
			_vbox.remove_child(n)
		_vbox.add_child(n)
	_ajustar_alto.call_deferred()

func _ajustar_alto() -> void:
	_vbox.size.y = 0
	_panel.size.y = 80.0 + _vbox.get_combined_minimum_size().y + 40.0

func _crear_fila(t: Dictionary) -> Control:
	var info: Dictionary = Config.TAREAS[t["tipo"]]
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	fila.custom_minimum_size = Vector2(0, 26)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var chk := TextureRect.new()
	chk.name = "Chk"
	chk.texture = load(UI + "check_off.png")
	chk.custom_minimum_size = Vector2(22, 22)
	chk.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chk.stretch_mode = TextureRect.STRETCH_SCALE
	chk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(chk)
	var ico := TextureRect.new()
	ico.texture = _icono(info["icono"])
	ico.custom_minimum_size = Vector2(30, 24)
	ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ico.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(ico)
	var nombre: String = info["nombre"]
	var lbl := UiEstilos.etiqueta(nombre, 16, UiEstilos.MARRON)
	lbl.name = "Lbl"
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(150, 0)
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fila.add_child(lbl)
	if t["arrastrada"]:
		var tag := UiEstilos.etiqueta("ayer", 12, Color(0.78, 0.45, 0.12))
		tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		fila.add_child(tag)
	return fila

func _icono(nombre: String) -> Texture2D:
	var ruta := UI + "icono_%s.png" % nombre
	if ResourceLoader.exists(ruta):
		return load(ruta)
	return load("res://assets/props/%s.png" % ("libro_a" if nombre == "libro" else "laptop_a"))

func _al_completar_tarea(t: Dictionary) -> void:
	var fila = _filas.get(t["uid"])
	if fila == null or not is_instance_valid(fila):
		return
	fila.set_meta("saliendo", true)
	(fila.get_node("Chk") as TextureRect).texture = load(UI + "check_on.png")
	var lbl: Label = fila.get_node("Lbl")
	lbl.add_theme_color_override("font_color", Color(0.5, 0.45, 0.38))
	var tachon := ColorRect.new()
	tachon.color = UiEstilos.MARRON
	tachon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tachon.position = Vector2(0, lbl.size.y / 2.0)
	tachon.size = Vector2(0, 2.5)
	lbl.add_child(tachon)
	var tw := create_tween()
	tw.tween_property(tachon, "size:x", minf(lbl.size.x, lbl.get_minimum_size().x + 4.0), 0.35)
	tw.tween_interval(0.5)
	tw.tween_property(fila, "modulate:a", 0.0, 0.3)
	tw.tween_property(fila, "custom_minimum_size:y", 0.0, 0.25)
	tw.tween_callback(func():
		_filas.erase(t["uid"])
		if is_instance_valid(fila):
			fila.queue_free()
		_ajustar_alto.call_deferred())

func actualizar_pendientes() -> void:
	if _lbl_pend == null:
		return
	var tr: SistemaTareas = Partida.tareas
	var n := tr.cuantas_pendientes()
	var restante: float = Partida.reloj.restante_fin_de_semana()
	var rojo := tr.esta_en_rojo(restante)
	_lbl_pend.text = "Pendientes: %d" % n if n > 0 else "¡Todo listo!"
	_lbl_pend.add_theme_color_override("font_color", UiEstilos.ROJO if rojo else (UiEstilos.VERDE if n == 0 else UiEstilos.MARRON))
	var progreso := "Completadas: %d de %d" % [tr.completadas, tr.generadas]
	_lbl_tiempo.text = "%s\nNecesitas: %s\nQuedan: %s" % [progreso, SistemaReloj.texto_duracion(tr.minutos_necesarios()), SistemaReloj.texto_duracion(restante)] if n > 0 else progreso
	_lbl_tiempo.add_theme_color_override("font_color", UiEstilos.ROJO if rojo else UiEstilos.MARRON_CLARO)
	if tr.advertencia_activa():
		_lbl_derrota.text = "¡Se acaba el tiempo! %d s" % int(ceil(tr.segundos_para_derrota()))
	else:
		_lbl_derrota.text = ""
	_lbl_derrota.visible = _lbl_derrota.text != ""

# ------------------------------------------------------------------ avisos, acción, prompt
func aviso(texto: String, rojo: bool = false) -> void:
	if _modo_cafe:
		return                         # al beber café solo se muestra "Estás recargando energía"
	_toast_lbl.text = texto
	_toast_lbl.add_theme_color_override("font_color", UiEstilos.ROJO if rojo else UiEstilos.MARRON)
	_toast_panel.reset_size()
	if _toast_tw:
		_toast_tw.kill()
	_toast_caja.modulate.a = 1.0
	_toast_tw = create_tween()
	_toast_tw.tween_interval(3.4)
	_toast_tw.tween_property(_toast_caja, "modulate:a", 0.0, 0.5)

func ocultar_aviso() -> void:
	if _toast_tw:
		_toast_tw.kill()
	_toast_caja.modulate.a = 0.0

func mostrar_accion(texto: String, solo_mensaje: bool = false) -> void:
	_modo_cafe = solo_mensaje
	if solo_mensaje:
		ocultar_aviso()
		ocultar_prompt()
	_accion_lbl.text = texto
	_accion_barra.value = 0.0
	_accion.visible = true
	_accion_barra.visible = not solo_mensaje
	_accion.reset_size()
	_accion.position = Vector2((1152.0 - _accion.size.x) / 2.0, 556)

func progreso_accion(p: float) -> void:
	_accion_barra.value = p

func ocultar_accion() -> void:
	_accion.visible = false
	_modo_cafe = false

func mostrar_prompt(texto: String, pos: Vector2) -> void:
	if _modo_cafe:
		return
	_prompt_lbl.text = texto
	_prompt.visible = true
	_prompt.reset_size()
	_prompt.position = Vector2(clampf(pos.x - _prompt.size.x / 2.0, 6.0, 1146.0 - _prompt.size.x), maxf(pos.y - _prompt.size.y, 64.0))

func ocultar_prompt() -> void:
	_prompt.visible = false

func mostrar_barra_superior(v: bool) -> void:
	_raiz.visible = v
