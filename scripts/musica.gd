extends Node
# Música de fondo continua + efectos de sonido (autoload "Musica").
# Vive fuera de las escenas, así que NO se reinicia al cambiar de escena.

const RUTA_FONDO := "res://audio de fondo/Weekend's life - jam.wav"
const RUTA_FIN := "res://audio de fondo/regi31 -Fin Juego.wav"
const SFX := ["clic", "tarea", "aceptar", "rechazar", "advertencia", "cansancio", "visita", "cafe_preparar",
	"cafe_beber", "barrer", "trapear", "platos", "regar", "comer", "leer", "serie", "dormir"]
const VOL_MUSICA := -8.0
const VOL_SFX := -4.0

var _fondo: AudioStreamPlayer
var _fin: AudioStreamPlayer
var _sfx: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _modo_fin := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS     # sigue sonando aunque el juego esté en pausa
	_fondo = _crear_reproductor(RUTA_FONDO)
	_fin = _crear_reproductor(RUTA_FIN)
	for n in SFX:
		var s = load("res://assets/sfx/%s.wav" % n)
		if s:
			_sfx[n] = s
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.volume_db = VOL_SFX
		add_child(p)
		_pool.append(p)

func _crear_reproductor(ruta: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	var st = load(ruta)
	if st is AudioStreamWAV:
		st.loop_mode = AudioStreamWAV.LOOP_FORWARD
		st.loop_begin = 0
		st.loop_end = int(st.get_length() * st.mix_rate)
	p.stream = st
	p.volume_db = VOL_MUSICA
	p.finished.connect(p.play)      # respaldo: si no hubiera loop, vuelve a empezar
	add_child(p)
	return p

# Se llama desde el menú; si ya está sonando no la reinicia.
func iniciar() -> void:
	if not _fondo.playing and not _modo_fin:
		_fondo.play()

# Pista de "Fin Juego" para el final de la partida y los créditos.
func modo_fin() -> void:
	if _modo_fin:
		return
	_modo_fin = true
	_cruzar(_fondo, _fin)

func modo_juego() -> void:
	if not _modo_fin and _fondo.playing:
		return
	_modo_fin = false
	_cruzar(_fin, _fondo)

func _cruzar(sale: AudioStreamPlayer, entra: AudioStreamPlayer) -> void:
	entra.volume_db = -40.0
	entra.play()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(entra, "volume_db", VOL_MUSICA, 1.2)
	tw.tween_property(sale, "volume_db", -40.0, 1.2)
	tw.chain().tween_callback(func():
		sale.stop()
		sale.volume_db = VOL_MUSICA)

func sfx(nombre: String) -> void:
	if not _sfx.has(nombre):
		return
	for p in _pool:
		if not p.playing:
			p.stream = _sfx[nombre]
			p.play()
			return
	_pool[0].stream = _sfx[nombre]
	_pool[0].play()
