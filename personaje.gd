extends Sprite2D
# Script para los personajes (nutria y oso).
# - "controlable": si es true, se mueve con flechas o WASD.
# - "hablando": cuando es true, el personaje rebota como si estuviera hablando.
# - "puede_moverse": se apaga mientras hay un diálogo.
# Los pies del personaje están en su posición (ver "offset" en la escena).

@export var controlable := false
@export var velocidad := 180.0
# Zona por donde puede caminar (x, y, ancho, alto), medida en los pies.
@export var area := Rect2(180, 260, 780, 285)

var hablando := false
var puede_moverse := true

var tiempo := 0.0
var escala_base := Vector2.ONE

func _ready():
	escala_base = scale

func _process(delta):
	tiempo += delta

	# --- Movimiento con teclado (solo la nutria) ---
	var dir := Vector2.ZERO
	if controlable and puede_moverse:
		dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		dir += Vector2(
			int(Input.is_physical_key_pressed(KEY_D)) - int(Input.is_physical_key_pressed(KEY_A)),
			int(Input.is_physical_key_pressed(KEY_S)) - int(Input.is_physical_key_pressed(KEY_W)))
		dir = dir.limit_length(1.0)

	if dir != Vector2.ZERO:
		position += dir * velocidad * delta
		position = position.clamp(area.position, area.end)
		if dir.x != 0.0:
			flip_h = dir.x < 0.0
		# Caminar: se balancea y da saltitos
		rotation = sin(tiempo * 10.0) * 0.05
		scale = Vector2(escala_base.x, escala_base.y * (1.0 + abs(sin(tiempo * 10.0)) * 0.04))
	elif hablando:
		# Hablar: rebote rápido
		var rebote = abs(sin(tiempo * 12.0))
		rotation = sin(tiempo * 6.0) * 0.02
		scale = Vector2(escala_base.x * (1.0 - rebote * 0.02), escala_base.y * (1.0 + rebote * 0.04))
	else:
		# Quieto: respira suavemente
		rotation = lerp(rotation, 0.0, 10.0 * delta)
		scale = Vector2(escala_base.x, escala_base.y * (1.0 + sin(tiempo * 2.0) * 0.012))
