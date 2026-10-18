class_name FramesUtil
extends RefCounted
# Construye SpriteFrames (para AnimatedSprite2D) desde hojas de sprites o archivos sueltos.

# filas: [{"nombre": "idle", "n": 4, "fps": 4.0, "loop": true}, ...]  (una fila de la hoja por animación)
static func de_hoja(hoja: Texture2D, cw: int, ch: int, filas: Array) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for r in filas.size():
		var f: Dictionary = filas[r]
		var nombre: String = f["nombre"]
		sf.add_animation(nombre)
		sf.set_animation_speed(nombre, f["fps"])
		sf.set_animation_loop(nombre, f.get("loop", true))
		for i in int(f["n"]):
			var at := AtlasTexture.new()
			at.atlas = hoja
			at.region = Rect2(i * cw, r * ch, cw, ch)
			sf.add_frame(nombre, at)
	return sf

# Carga prefijo_00.jpg … prefijo_NN.jpg como una animación.
static func de_secuencia(prefijo: String, n: int, nombre: String, fps: float, loop: bool) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	sf.add_animation(nombre)
	sf.set_animation_speed(nombre, fps)
	sf.set_animation_loop(nombre, loop)
	for i in n:
		sf.add_frame(nombre, load("res://assets/escenas/%s_%02d.jpg" % [prefijo, i]))
	return sf

# Animaciones estándar de las hojas
const FILAS_NUTRILDA := [
	{"nombre": "idle", "n": 4, "fps": 3.0}, {"nombre": "caminar", "n": 8, "fps": 11.0},
	{"nombre": "hablar", "n": 4, "fps": 8.0}, {"nombre": "barrer", "n": 6, "fps": 8.0},
	{"nombre": "preparar", "n": 6, "fps": 7.0}, {"nombre": "comer", "n": 4, "fps": 5.0},
	{"nombre": "leer", "n": 4, "fps": 2.0}, {"nombre": "serie", "n": 4, "fps": 2.5},
	{"nombre": "dormir", "n": 4, "fps": 1.5},
]
const FILAS_NPC := [
	{"nombre": "idle", "n": 4, "fps": 3.0}, {"nombre": "caminar", "n": 8, "fps": 11.0},
	{"nombre": "hablar", "n": 4, "fps": 8.0},
]
