class_name SistemaReloj
extends RefCounted
# Reloj del juego: día (0 = sábado, 1 = domingo) y minutos desde las 0:00.

signal cambio(minutos: float, dia: int)
signal dia_terminado(dia: int)

var dia := 0
var minutos := float(Config.MIN_INICIO_DIA)
var _fin_emitido := false

func reiniciar() -> void:
	dia = 0
	minutos = float(Config.MIN_INICIO_DIA)
	_fin_emitido = false
	cambio.emit(minutos, dia)

func nuevo_dia() -> void:
	dia += 1
	minutos = float(Config.MIN_INICIO_DIA)
	_fin_emitido = false
	cambio.emit(minutos, dia)

func avanzar(m: float) -> void:
	if _fin_emitido or m <= 0.0:
		return
	var antes := int(minutos)
	minutos = minf(minutos + m, float(Config.MIN_FIN_DIA))
	if int(minutos) != antes:
		cambio.emit(minutos, dia)
	if minutos >= float(Config.MIN_FIN_DIA):
		_fin_emitido = true
		dia_terminado.emit(dia)

func es_ultimo_dia() -> bool:
	return dia >= Config.NOMBRES_DIA.size() - 1

func dia_terminado_ya() -> bool:
	return _fin_emitido

func restante_dia() -> float:
	return float(Config.MIN_FIN_DIA) - minutos

func restante_fin_de_semana() -> float:
	var dias_despues := Config.NOMBRES_DIA.size() - 1 - dia
	return restante_dia() + dias_despues * float(Config.MIN_FIN_DIA - Config.MIN_INICIO_DIA)

func es_noche() -> bool:
	return minutos >= Config.HORA_DESCANSO_NOCTURNO * 60.0

func nombre_dia() -> String:
	return Config.NOMBRES_DIA[dia]

func hora_texto() -> String:
	return texto_hora(minutos)

static func texto_hora(m: float) -> String:
	var t := int(m)
	return "%02d:%02d" % [t / 60, t % 60]

static func texto_duracion(m: float) -> String:
	var t := int(round(m))
	var h := t / 60
	var mm := t % 60
	if h == 0:
		return "%d min" % mm
	if mm == 0:
		return "%d h" % h
	return "%d h %d min" % [h, mm]
