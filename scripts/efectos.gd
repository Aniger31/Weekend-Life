class_name Efectos
extends RefCounted
# Efectos visuales sencillos: vapor, destellos, textos flotantes.

static var _suave: Texture2D

static func textura_suave() -> Texture2D:
	if _suave == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 0.9))
		g.set_color(1, Color(1, 1, 1, 0.0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(0.5, 0.0)
		t.width = 48
		t.height = 48
		_suave = t
	return _suave

# Vapor que sube. Devuelve el nodo para poder liberarlo (queue_free) después.
static func vapor(padre: Node, pos: Vector2, escala: float = 1.0) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = textura_suave()
	p.position = pos
	p.amount = 9
	p.lifetime = 1.6
	p.direction = Vector2(0, -1)
	p.spread = 18.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 16.0 * escala
	p.initial_velocity_max = 28.0 * escala
	p.scale_amount_min = 0.25 * escala
	p.scale_amount_max = 0.55 * escala
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.0))
	g.add_point(0.25, Color(1, 1, 1, 0.55))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0.0))
	p.color_ramp = g
	p.z_index = 20
	padre.add_child(p)
	return p

# Ráfaga de estrellitas (al completar una tarea)
static func chispas(padre: Node, pos: Vector2, cantidad: int = 8) -> void:
	var tex := load("res://assets/props/estrella.png") as Texture2D
	for i in cantidad:
		var s := Sprite2D.new()
		s.texture = tex
		s.position = pos
		s.scale = Vector2.ONE * randf_range(0.5, 0.9)
		s.z_index = 40
		padre.add_child(s)
		var ang := randf() * TAU
		var dist := randf_range(30.0, 70.0)
		var tw := s.create_tween().set_parallel(true)
		tw.tween_property(s, "position", pos + Vector2(cos(ang), sin(ang)) * dist, 0.7).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(s, "modulate:a", 0.0, 0.7)
		tw.tween_property(s, "rotation", randf_range(-2.0, 2.0), 0.7)
		tw.chain().tween_callback(s.queue_free)

static func texto_flotante(padre: Node, pos: Vector2, texto: String, color: Color = UiEstilos.CREMA) -> void:
	var l := UiEstilos.etiqueta(texto, 26, color, 8)
	l.position = pos - Vector2(60, 0)
	l.custom_minimum_size = Vector2(120, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.z_index = 50
	padre.add_child(l)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", pos.y - 46, 1.1).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 1.1).set_delay(0.4)
	tw.chain().tween_callback(l.queue_free)
