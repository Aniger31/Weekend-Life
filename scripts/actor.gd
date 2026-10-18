class_name Actor
extends AnimatedSprite2D
# Personaje animado (Nutrilda y los visitantes). El origen del nodo está en los PIES.
# Se mueve siguiendo una ruta de puntos y cambia de animación solo (idle / caminar).

signal llego

const ESCALA := 0.62
const ANCHO_CELDA := 240
const ALTO_CELDA := 300
const PIES_Y := 282

var velocidad := 175.0
var animacion_base := "idle"        # lo que hace cuando no camina
var ruta: Array = []
var moviendo := false
var _cancelar := false

func _ready() -> void:
	centered = false
	offset = Vector2(-ANCHO_CELDA / 2.0, -PIES_Y)
	scale = Vector2(ESCALA, ESCALA)

func cargar_hoja(ruta_hoja: String, filas: Array) -> void:
	sprite_frames = FramesUtil.de_hoja(load(ruta_hoja), ANCHO_CELDA, ALTO_CELDA, filas)
	play("idle")

func reproducir(nombre: String) -> void:
	animacion_base = nombre
	if not moviendo and sprite_frames.has_animation(nombre):
		play(nombre)

func mirar_hacia(x: float) -> void:
	if absf(x - position.x) > 2.0:
		flip_h = x < position.x

# Camina por la ruta. Devuelve true si llegó, false si la cancelaron.
func seguir_ruta(puntos: Array) -> bool:
	detener()
	if puntos.is_empty():
		return true
	ruta = puntos.duplicate()
	moviendo = true
	_cancelar = false
	play("caminar")
	await llego
	return not _cancelar

func detener() -> void:
	if moviendo:
		_cancelar = true
		ruta.clear()
		moviendo = false
		llego.emit()
		_cancelar = true
	_volver_a_base()

func _volver_a_base() -> void:
	if sprite_frames and sprite_frames.has_animation(animacion_base):
		play(animacion_base)

func _process(delta: float) -> void:
	if not moviendo:
		return
	var paso := velocidad * delta
	while paso > 0.0 and not ruta.is_empty():
		var destino: Vector2 = ruta[0]
		var d := position.distance_to(destino)
		if d <= paso:
			position = destino
			paso -= d
			ruta.pop_front()
		else:
			var dir := (destino - position) / d
			position += dir * paso
			if absf(dir.x) > 0.15:
				flip_h = dir.x < 0.0
			paso = 0.0
	if ruta.is_empty():
		moviendo = false
		_cancelar = false
		_volver_a_base()
		llego.emit()
