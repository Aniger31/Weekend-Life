class_name SistemaCafe
extends RefCounted
# Inventario de tazas de café disponibles. Preparar y beber son acciones distintas.

signal cambio(tazas: int)

var tazas := Config.CAFE_INICIAL

func reiniciar() -> void:
	tazas = Config.CAFE_INICIAL
	cambio.emit(tazas)

func hay() -> bool:
	return tazas > 0

func esta_lleno() -> bool:
	return tazas >= Config.CAFE_MAXIMO

func preparar(cantidad: int = Config.CAFE_POR_PREPARACION) -> int:
	var antes := tazas
	tazas = mini(tazas + cantidad, Config.CAFE_MAXIMO)
	cambio.emit(tazas)
	return tazas - antes

# Gasta una taza. Devuelve false si no había.
func servir() -> bool:
	if tazas <= 0:
		return false
	tazas -= 1
	cambio.emit(tazas)
	return true
