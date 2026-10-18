class_name VinetaAccion
extends CanvasLayer
# Muestra la ILUSTRACIÓN animada de una actividad (AnimatedSprite2D con los fotogramas)
# dentro de un marco, sobre el escenario oscurecido. El HUD queda visible encima.

const CENTRO := Vector2(470, 352)
const DEF := {
	"lavar_platos": {"prefijo": "platos", "n": 10, "modo": "progreso", "tam": Vector2(620, 349)},
	"dormir": {"prefijo": "cama", "n": 10, "modo": "progreso", "tam": Vector2(380, 474)},
	"trapear": {"prefijo": "trapear", "n": 6, "modo": "loop", "fps": 6.0, "tam": Vector2(600, 450)},
	"regar": {"prefijo": "regar", "n": 6, "modo": "loop", "fps": 6.0, "tam": Vector2(370, 444)},
	"beber_cafe": {"prefijo": "cafe", "n": 6, "modo": "loop", "fps": 5.0, "tam": Vector2(600, 450)},
}

var _raiz: Control
var _fondo: ColorRect
var _marco: Panel
var _anim: AnimatedSprite2D
var _modo := ""
var _n := 1
var _frames_cache := {}
var _tw_entrada: Tween

func _ready() -> void:
	layer = 5
	_raiz = Control.new()
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.visible = false
	add_child(_raiz)
	_fondo = ColorRect.new()
	_fondo.color = Color(0.05, 0.03, 0.02, 0.55)
	_fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	_raiz.add_child(_fondo)
	_marco = Panel.new()
	_marco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_marco)
	_anim = AnimatedSprite2D.new()
	_raiz.add_child(_anim)

func tiene(id: String) -> bool:
	return DEF.has(id)

func mostrar(id: String) -> void:
	var d: Dictionary = DEF[id]
	if not _frames_cache.has(id):
		_frames_cache[id] = FramesUtil.de_secuencia(d["prefijo"], d["n"], "a", d.get("fps", 1.0), d["modo"] == "loop")
	_anim.sprite_frames = _frames_cache[id]
	var tam: Vector2 = d["tam"]
	var tex: Texture2D = _anim.sprite_frames.get_frame_texture("a", 0)
	_anim.scale = Vector2(tam.x / tex.get_width(), tam.y / tex.get_height())
	_anim.position = CENTRO
	_marco.position = CENTRO - tam / 2.0 - Vector2(14, 14)
	_marco.size = tam + Vector2(28, 28)
	_marco.add_theme_stylebox_override("panel", UiEstilos.caja(UiEstilos.CREMA, UiEstilos.MARRON, 24, 7, 10))
	_modo = d["modo"]
	_n = d["n"]
	_anim.animation = "a"
	_anim.frame = 0
	_anim.speed_scale = 1.0
	if _modo == "loop":
		_anim.play("a")
	else:
		_anim.stop()
	_raiz.modulate.a = 0.0
	_raiz.visible = true
	if _tw_entrada:
		_tw_entrada.kill()
	_tw_entrada = create_tween()
	_tw_entrada.tween_property(_raiz, "modulate:a", 1.0, 0.35)
	var base := _marco.scale
	_marco.pivot_offset = _marco.size / 2.0
	_marco.scale = base * 0.92
	_tw_entrada.parallel().tween_property(_marco, "scale", base, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# Para las animaciones por progreso (platos, cama): p va de 0 a 1.
func progreso(p: float) -> void:
	if _modo == "progreso":
		_anim.frame = clampi(int(p * _n), 0, _n - 1)

func ocultar() -> void:
	if not _raiz.visible:
		return
	var tw := create_tween()
	tw.tween_property(_raiz, "modulate:a", 0.0, 0.3)
	await tw.finished
	_raiz.visible = false
	_anim.stop()

func esta_visible() -> bool:
	return _raiz.visible
