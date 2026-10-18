class_name SistemaTareas
extends RefCounted
# Lista de pendientes (checklist). Solo guarda las tareas ACTIVAS: al completarse
# se eliminan de la lista y se cuentan como completadas.

signal cambiaron
signal tarea_completada(tarea: Dictionary)
signal advertencia           # llevas más de 2 min reales en rojo
signal derrota               # sigues en rojo tras la advertencia

var lista: Array = []        # [{uid, tipo, arrastrada}]
var completadas := 0
var generadas := 0
var seg_en_rojo := 0.0
var _advertencia_emitida := false
var _derrota_emitida := false
var _uid := 0

func reiniciar() -> void:
	lista.clear()
	completadas = 0
	generadas = 0
	_resetear_rojo()
	for tipo in Config.ORDEN_TAREAS:
		_agregar(tipo, false)
	cambiaron.emit()

func _agregar(tipo: String, arrastrada: bool) -> void:
	_uid += 1
	generadas += 1
	lista.append({"uid": _uid, "tipo": tipo, "arrastrada": arrastrada})

func hay_pendiente(tipo: String) -> bool:
	for t in lista:
		if t["tipo"] == tipo:
			return true
	return false

# Cambio de día: lo que quedó pendiente pasa al día siguiente y las tareas
# diarias que ya hiciste vuelven a aparecer.
func iniciar_dia_nuevo() -> void:
	for t in lista:
		t["arrastrada"] = true
	for tipo in Config.ORDEN_TAREAS:
		if Config.TAREAS[tipo]["diaria"] and not hay_pendiente(tipo):
			_agregar(tipo, false)
	_resetear_rojo()
	cambiaron.emit()

# Completa UNA tarea pendiente de ese tipo. Devuelve false si no había ninguna
# (así una tarea no puede completarse dos veces por accidente).
func completar(tipo: String) -> bool:
	for i in lista.size():
		if lista[i]["tipo"] == tipo:
			var t: Dictionary = lista[i]
			lista.remove_at(i)
			completadas += 1
			tarea_completada.emit(t)
			cambiaron.emit()
			return true
	return false

func cuantas_pendientes() -> int:
	return lista.size()

# Minutos de juego que hacen falta para terminar todo lo pendiente.
func minutos_necesarios() -> float:
	var total := 0.0
	for t in lista:
		var act: String = Config.actividad_de_tarea(t["tipo"])
		if act != "":
			total += float(Config.ACTIVIDADES[act]["min"])
	return total

# El contador se pone en rojo cuando ya NO alcanza el tiempo del fin de semana.
func esta_en_rojo(minutos_restantes: float) -> bool:
	return lista.size() > 0 and minutos_necesarios() > minutos_restantes

func _resetear_rojo() -> void:
	seg_en_rojo = 0.0
	_advertencia_emitida = false
	_derrota_emitida = false

func advertencia_activa() -> bool:
	return _advertencia_emitida

func segundos_para_derrota() -> float:
	return maxf(0.0, Config.ADVERTENCIA_SEG + Config.DERROTA_SEG_TRAS_ADVERTENCIA - seg_en_rojo)

# Se llama cada frame con el tiempo REAL transcurrido.
func actualizar_rojo(delta: float, en_rojo: bool) -> void:
	if not en_rojo:
		if seg_en_rojo > 0.0 or _advertencia_emitida:
			_resetear_rojo()
		return
	seg_en_rojo += delta
	if not _advertencia_emitida and seg_en_rojo >= Config.ADVERTENCIA_SEG:
		_advertencia_emitida = true
		advertencia.emit()
	if _advertencia_emitida and not _derrota_emitida \
			and seg_en_rojo >= Config.ADVERTENCIA_SEG + Config.DERROTA_SEG_TRAS_ADVERTENCIA:
		_derrota_emitida = true
		derrota.emit()
