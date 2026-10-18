extends Node
# Estado de la partida (autoload "Partida"). Agrupa los sistemas independientes.

var reloj := SistemaReloj.new()
var energia := SistemaEnergia.new()
var cafe := SistemaCafe.new()
var tareas := SistemaTareas.new()
var stats := {}
var creditos_vuelven_al_menu := false

func _ready() -> void:
	nueva_partida()

func nueva_partida() -> void:
	reloj.reiniciar()
	energia.reiniciar()
	cafe.reiniciar()
	tareas.reiniciar()
	stats = {"favores_aceptados": 0, "favores_rechazados": 0, "cafes_servidos": 0, "cafes_bebidos": 0}
