class_name SistemaEnergia
extends RefCounted
# Barra de energía. Solo el café la recupera (dormir NO la restaura).

signal cambio(valor: float, maximo: float)
signal entro_en_baja

var maximo := Config.ENERGIA_MAX
var valor := Config.ENERGIA_INICIAL

func reiniciar() -> void:
	maximo = Config.ENERGIA_MAX
	valor = Config.ENERGIA_INICIAL
	cambio.emit(valor, maximo)

func esta_baja() -> bool:
	return valor <= maximo * Config.FRACCION_ENERGIA_BAJA + 0.001

func esta_llena() -> bool:
	return valor >= maximo - 0.001

func puede_pagar(costo: float) -> bool:
	return costo <= 0.0 or valor >= costo

func consumir(costo: float) -> void:
	if costo <= 0.0:
		return
	var estaba_baja := esta_baja()
	valor = maxf(0.0, valor - costo)
	cambio.emit(valor, maximo)
	if not estaba_baja and esta_baja():
		entro_en_baja.emit()

func recuperar(cantidad: float) -> void:
	valor = minf(maximo, valor + cantidad)   # nunca pasa del máximo
	cambio.emit(valor, maximo)
