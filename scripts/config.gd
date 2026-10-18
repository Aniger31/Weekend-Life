extends Node
# =====================================================================
#  CONFIGURACIÓN CENTRALIZADA  (autoload "Config")
#  Todos los tiempos, costos de energía y cantidades de café están aquí.
#  Cambia un número y el juego completo se ajusta.
# =====================================================================

# ---------------- RELOJ ----------------
const MIN_INICIO_DIA := 7 * 60          # el día empieza a las 7:00
const MIN_FIN_DIA := 22 * 60            # y termina a las 22:00
const NOMBRES_DIA := ["Sábado", "Domingo"]
# Minutos de juego que pasan por cada segundo real cuando Nutrilda no está
# haciendo nada. Pon 0 para que el tiempo SOLO avance al realizar actividades.
const RITMO_TIEMPO_LIBRE := 1.0
const HORA_DESCANSO_NOCTURNO := 19      # desde esta hora, dormir cuenta como "descanso nocturno"
const HORA_ATARDECER := 17              # el escenario empieza a oscurecer

# ---------------- ENERGÍA ----------------
const ENERGIA_MAX := 100.0
const ENERGIA_INICIAL := 70.0
const FRACCION_ENERGIA_BAJA := 1.0 / 3.0   # barra roja y avisos de cansancio
const ENERGIA_POR_CAFE := 25.0             # lo que recupera beber UNA taza

# ---------------- CAFÉ ----------------
const CAFE_INICIAL := 0
const CAFE_POR_PREPARACION := 2            # tazas que salen de cada preparación
const CAFE_MAXIMO := 6
const CAFE_NPC_MIN := 10                   # minutos que toma servirle café a un amigo
const CAFE_NPC_ENERGIA := 3.0

# ---------------- VISITAS ----------------
const VISITA_MIN_SEG := 180.0              # 3 minutos reales
const VISITA_MAX_SEG := 360.0              # 6 minutos reales
const VISITA_PROB_CAFE := 0.4              # probabilidad de que la visita sea para pedir café
const VISITA_MIN_RESTANTE := 90            # no hay visitas si quedan menos de N minutos de juego
# Atajos para probar sin esperar (F9 = visita ya, F10 = +60 min de juego). Ponlo en false al publicar.
const ATAJOS_DE_PRUEBA := true

# ---------------- PENDIENTES / DERROTA ----------------
const ADVERTENCIA_SEG := 120.0             # en rojo más de 2 min reales -> pantalla WARNING
const DERROTA_SEG_TRAS_ADVERTENCIA := 60.0 # si sigue en rojo tras la advertencia -> fin de juego

# ---------------- ACTIVIDADES ----------------
# min = minutos de juego | energia = costo | seg = duración real de la animación
# tarea = pendiente que completa ("" si ninguno)
const ACTIVIDADES := {
	"preparar_cafe": {"nombre": "Preparar café", "texto": "Preparando café…", "min": 15, "energia": 3.0, "seg": 4.5, "tarea": "cafe", "sfx": "cafe_preparar"},
	"beber_cafe": {"nombre": "Beber café", "texto": "Estás recargando energía", "min": 10, "energia": 0.0, "seg": 4.5, "tarea": "", "sfx": "cafe_beber"},
	"comer": {"nombre": "Comer en la mesita", "texto": "Comiendo…", "min": 30, "energia": 0.0, "seg": 5.0, "tarea": "comer", "sfx": "comer"},
	"trapear": {"nombre": "Trapear la casa", "texto": "Trapeando…", "min": 45, "energia": 15.0, "seg": 6.0, "tarea": "trapear", "sfx": "trapear"},
	"lavar_platos": {"nombre": "Lavar los platos", "texto": "Lavando los platos…", "min": 30, "energia": 10.0, "seg": 6.0, "tarea": "platos", "sfx": "platos"},
	"regar": {"nombre": "Regar las plantas", "texto": "Regando las plantas…", "min": 20, "energia": 5.0, "seg": 5.0, "tarea": "regar", "sfx": "regar"},
	"leer": {"nombre": "Leer un libro", "texto": "Leyendo…", "min": 60, "energia": 0.0, "seg": 5.0, "tarea": "leer", "sfx": "leer"},
	"ver_serie": {"nombre": "Ver una serie", "texto": "Viendo una serie…", "min": 90, "energia": 0.0, "seg": 6.0, "tarea": "serie", "sfx": "serie"},
	"barrer": {"nombre": "Barrer el piso", "texto": "Barriendo…", "min": 30, "energia": 10.0, "seg": 5.5, "tarea": "barrer", "sfx": "barrer"},
	"dormir": {"nombre": "Dormir", "texto": "Descansando…", "min": 120, "energia": 0.0, "seg": 7.0, "tarea": "descanso", "sfx": "dormir"},
}

# ---------------- LISTA DE PENDIENTES ----------------
# diaria = reaparece el domingo si ya la hiciste el sábado
const TAREAS := {
	"cafe": {"nombre": "Preparar café", "icono": "cafe", "diaria": true},
	"comer": {"nombre": "Comer en la mesita", "icono": "comer", "diaria": true},
	"trapear": {"nombre": "Trapear la casa", "icono": "escoba", "diaria": false},
	"platos": {"nombre": "Lavar los platos", "icono": "platos", "diaria": true},
	"regar": {"nombre": "Regar las plantas", "icono": "planta", "diaria": false},
	"barrer": {"nombre": "Barrer el piso", "icono": "escoba", "diaria": false},
	"leer": {"nombre": "Leer un libro", "icono": "libro", "diaria": true},
	"serie": {"nombre": "Ver una serie", "icono": "serie", "diaria": true},
	"descanso": {"nombre": "Organizar el descanso nocturno", "icono": "cama", "diaria": true},
}
const ORDEN_TAREAS := ["cafe", "comer", "trapear", "platos", "regar", "barrer", "leer", "serie", "descanso"]

func actividad_de_tarea(tipo: String) -> String:
	for id in ACTIVIDADES:
		if ACTIVIDADES[id]["tarea"] == tipo:
			return id
	return ""

func _ready() -> void:
	_registrar_entradas()

# Acciones de teclado (se registran por código para no depender de project.godot)
func _registrar_entradas() -> void:
	_accion("interactuar", [KEY_E, KEY_SPACE])
	_accion("beber_cafe", [KEY_C])
	_accion("alternar_pendientes", [KEY_TAB])
	_accion("opcion_1", [KEY_1, KEY_KP_1])
	_accion("opcion_2", [KEY_2, KEY_KP_2])

func _accion(nombre: String, teclas: Array) -> void:
	if not InputMap.has_action(nombre):
		InputMap.add_action(nombre)
	for k in teclas:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(nombre, ev)
