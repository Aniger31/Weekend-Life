class_name SistemaVisitas
extends Node
# Genera visitas de los NPC cada 3–6 minutos REALES de juego. Si Nutrilda está
# ocupada (animación, diálogo, durmiendo…) la visita queda en espera.

signal visita_lista(visita: Dictionary)

var puede_interrumpir: Callable
var activo := false
var _restante := 0.0
var _en_espera := false
var _ultimo_npc := ""
var _favores_vistos: Array = []

func iniciar() -> void:
	activo = true
	_reprogramar()

func detener() -> void:
	activo = false

func visita_terminada() -> void:
	activo = true
	_reprogramar()

func forzar_visita() -> void:       # atajo de pruebas (F9)
	if activo:
		_en_espera = true

func segundos_para_visita() -> float:
	return _restante

func _reprogramar() -> void:
	_restante = randf_range(Config.VISITA_MIN_SEG, Config.VISITA_MAX_SEG)
	_en_espera = false

func _process(delta: float) -> void:
	if not activo:
		return
	if not _en_espera:
		_restante -= delta
		if _restante <= 0.0:
			_en_espera = true
		return
	if puede_interrumpir.is_valid() and puede_interrumpir.call():
		activo = false
		_en_espera = false
		visita_lista.emit(generar())

func generar() -> Dictionary:
	var npcs: Array = DatosDialogos.NPCS.keys()
	var candidatos := npcs.filter(func(n): return n != _ultimo_npc)
	var npc: String = candidatos.pick_random()
	_ultimo_npc = npc
	if randf() < Config.VISITA_PROB_CAFE:
		return {"npc": npc, "tipo": "cafe"}
	var favores := DatosDialogos.favores_de(npc)
	var nuevos := favores.filter(func(f): return not _favores_vistos.has(f["id"]))
	if nuevos.is_empty():          # ya viste los tres de este personaje: se repiten
		for f in favores:
			_favores_vistos.erase(f["id"])
		nuevos = favores
	var favor: Dictionary = nuevos.pick_random()
	_favores_vistos.append(favor["id"])
	return {"npc": npc, "tipo": "favor", "favor": favor}

func reanudar() -> void:           # tras el cambio de día: sigue la cuenta donde iba
	activo = true
