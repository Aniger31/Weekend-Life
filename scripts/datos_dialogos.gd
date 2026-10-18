class_name DatosDialogos
extends RefCounted
# Todo el contenido narrativo: NPC, las 9 interacciones, café y rechazos.
# Para cambiar un diálogo, un tiempo (horas) o un costo de energía, edita aquí.

const NPCS := {
	"berny": {
		"nombre": "Berny", "especie": "oso",
		"hoja": "res://assets/sprites/berny_sheet.png",
		"retrato": "res://assets/sprites/retrato_berny.png",
		"color": Color(0.70, 0.44, 0.20),
		"cafe": "¡Hola, Nutrilda! ¿Podrías servirme una taza de café? Hoy he trabajado muchísimo.",
		"gracias_cafe": "¡Gracias, Nutrilda! Justo lo que necesitaba.",
		"comprension": [
			"No te preocupes, Nutrilda. Lo entiendo perfectamente.",
			"Claro, gracias por ser sincera. Buscaré otra forma.",
			"Está bien, amiga. ¡Descansa!",
		],
	},
	"sam": {
		"nombre": "Sam", "especie": "conejo",
		"hoja": "res://assets/sprites/sam_sheet.png",
		"retrato": "res://assets/sprites/retrato_sam.png",
		"color": Color(0.80, 0.55, 0.50),
		"cafe": "¡Hola, Nutrilda! ¿Tienes un poquito de café para mí? Necesito descansar un momento.",
		"gracias_cafe": "¡Qué rico! Gracias, Nutrilda, me hacía falta.",
		"comprension": [
			"¡Sin problema, Nutrilda! Cuídate mucho.",
			"Tranquila, lo entiendo. ¡Gracias por avisarme!",
			"No pasa nada, será en otra ocasión.",
		],
	},
	"bisente": {
		"nombre": "Bisente", "especie": "bisonte",
		"hoja": "res://assets/sprites/bisente_sheet.png",
		"retrato": "res://assets/sprites/retrato_bisente.png",
		"color": Color(0.42, 0.30, 0.22),
		"cafe": "¡Buenas, Nutrilda! ¿Me prepararías una taza de café? Un poco de energía me vendría muy bien.",
		"gracias_cafe": "¡Gracias, amiga! Con esto aguanto lo que sea.",
		"comprension": [
			"Está bien, amiga. Gracias de todos modos.",
			"Lo entiendo. Cada quien tiene sus cosas, ¡nos vemos!",
			"Sin problema. Ánimo con tus pendientes.",
		],
	},
}

const NOMBRE_NUTRILDA := "Nutrilda"

# Respuestas educadas para rechazar (genéricas)
const RECHAZOS := [
	"Lo siento, tal vez en otro momento.",
	"Lo siento, tal vez en otro día.",
	"Hoy no puedo, tengo algunas cosas pendientes.",
	"Me gustaría ayudarte, pero necesito terminar mis propias tareas.",
	"Esta vez no podré ayudarte, espero que lo entiendas.",
	"Gracias por pensar en mí, pero hoy necesito dedicar tiempo a mis responsabilidades.",
]
# Se prefieren cuando la energía está en un tercio o menos
const RECHAZOS_CANSADA := [
	"Lo siento, hoy estoy muy cansada y necesito descansar.",
	"Ahora mismo estoy sin energía; primero necesito recuperarme con un café.",
	"Me gustaría ayudarte, pero hoy necesito descansar y recuperar fuerzas.",
]
const SIN_TIEMPO := "Me gustaría, pero ya no me alcanza el tiempo de hoy. Perdona."

# --- Peticiones de café ---
const CAFE_ACEPTA := "¡Claro! Enseguida te sirvo una taza."
const CAFE_SIN_STOCK := "Lo siento, ahora mismo no tengo café preparado. Tendría que preparar un poco."
const CAFE_PIENSA_CON := "Tengo %d taza(s) de café. Si le sirvo una a %s, me quedará menos para recargar mi propia energía."
const CAFE_PIENSA_SIN := "Todavía no tengo café preparado. Si le digo que sí, tendría que prepararlo primero."

# --- Las nueve interacciones (horas = tiempo que consume, energia = costo) ---
const FAVORES := [
	{
		"id": 0, "npc": "berny", "horas": 3, "energia": 25.0,
		"npc_dice": "¡Hola, Nutrilda! ¿Me ayudas a reparar el techo de mi casa? La lluvia llegará pronto y necesito terminarlo hoy.",
		"piensa": "Si ayudo a Berny, perderé varias horas que necesito para terminar mis tareas del fin de semana. Pero me preocupa que su casa se dañe.",
		"acepta": "¡Claro, Berny! Te ayudaré a reparar el techo.",
		"pantalla": "¡Ayudaste a Berny a reparar su techo!",
		"rechaza": "Lo siento, Berny. Hoy tengo varias cosas que terminar. Espero que puedas conseguir ayuda antes de que llueva.",
	},
	{
		"id": 1, "npc": "berny", "horas": 4, "energia": 30.0,
		"npc_dice": "¡Nutrilda! ¿Puedes cuidar a mis tres sobrinos toda la tarde? Necesito salir a comprar materiales para mi taller.",
		"piensa": "Si acepto, pasaré toda la tarde cuidándolos y probablemente no termine de organizar mi huerto.",
		"acepta": "Está bien, Berny. Yo los cuidaré esta tarde.",
		"pantalla": "¡Cuidaste a los sobrinos de Berny!",
		"rechaza": "Lo siento, Berny. Hoy no puedo cuidar a los niños porque tengo mis propias responsabilidades. Tal vez puedas pedirle ayuda a otro vecino.",
	},
	{
		"id": 2, "npc": "berny", "horas": 2, "energia": 15.0,
		"npc_dice": "¡Hola! ¿Me ayudas a llevar todas estas provisiones al almacén? Son demasiadas para mí y quiero terminar antes del anochecer.",
		"piensa": "Quiero ayudar a Berny, pero todavía tengo que recoger mis herramientas y preparar la comida. Si acepto, podría quedarme sin tiempo.",
		"acepta": "¡Por supuesto, Berny! Vamos a llevar todo al almacén.",
		"pantalla": "¡Transportaste las provisiones de Berny!",
		"rechaza": "Lo siento, Berny. Hoy necesito terminar mis propias tareas. Puedo recomendarte dónde conseguir un carrito para transportar tus provisiones.",
	},
	{
		"id": 3, "npc": "sam", "horas": 5, "energia": 35.0,
		"npc_dice": "¡Hola, Nutrilda! ¿Me ayudas a plantar mi cosecha de esta temporada?",
		"piensa": "Si le ayudo a Sam, estaré muy cansada y no sé si acabaré mis pendientes del fin de semana, pero es mi amigo.",
		"acepta": "¡Está bien, te ayudaré a plantar tu cosecha, Sam!",
		"pantalla": "¡Ayudaste a Sam a plantar su cosecha de temporada!",
		"rechaza": "No, Sam, lo siento. Este fin de semana tengo muchas cosas que terminar. Tal vez pueda ayudarte el próximo fin de semana.",
	},
	{
		"id": 4, "npc": "sam", "horas": 4, "energia": 25.0,
		"npc_dice": "¡Nutrilda! ¿Puedes ayudarme a decorar mi madriguera y preparar comida para la fiesta de esta noche? ¡Quiero que todo quede perfecto!",
		"piensa": "Me gustaría ayudar a Sam para que su fiesta salga bien, pero tengo que terminar de reparar la cerca de mi jardín antes de que oscurezca.",
		"acepta": "¡Claro, Sam! Te ayudaré con la decoración y la comida.",
		"pantalla": "¡Ayudaste a Sam a preparar su fiesta!",
		"rechaza": "Lo siento, Sam. Me encantaría ayudarte, pero hoy necesito reparar la cerca de mi jardín. ¡Espero que tu fiesta salga genial!",
	},
	{
		"id": 5, "npc": "sam", "horas": 3, "energia": 20.0,
		"npc_dice": "¡Oye, Nutrilda! ¿Me ayudas a recolectar y empacar todas mis zanahorias? Tengo un pedido grande que debo entregar mañana.",
		"piensa": "Si acepto, podré ayudar a Sam a ganar dinero, pero todavía necesito ir al mercado y comprar semillas para mi próxima cosecha.",
		"acepta": "¡Sí, Sam! Vamos a recolectar y empacar esas zanahorias.",
		"pantalla": "¡Ayudaste a Sam con su pedido de zanahorias!",
		"rechaza": "Lo siento, Sam. Hoy necesito hacer unas compras importantes para mi propia cosecha. Espero que puedas terminar tu pedido.",
	},
	{
		"id": 6, "npc": "bisente", "horas": 3, "energia": 25.0,
		"npc_dice": "¡Eh, Nutrilda! Necesito mover estos troncos pesados hasta mi granero. ¿Me echas una mano antes de que se haga de noche?",
		"piensa": "Bisente necesita ayuda, pero yo también tengo que recoger leña para mi casa. Si acepto, quizá no consiga suficiente para pasar la noche.",
		"acepta": "Está bien, Bisente. Te ayudaré a mover los troncos.",
		"pantalla": "¡Ayudaste a Bisente a mover los troncos!",
		"rechaza": "Lo siento, Bisente. Necesito recoger leña para mi casa antes de que oscurezca. Hoy no puedo ayudarte.",
	},
	{
		"id": 7, "npc": "bisente", "horas": 6, "energia": 40.0,
		"npc_dice": "¡Hola! ¿Puedes ayudarme a construir una cerca alrededor de mi terreno? Quiero terminarla hoy para que mis animales no se escapen.",
		"piensa": "Quiero que sus animales estén seguros, pero mañana tengo que entregar un encargo y todavía no he reunido los materiales necesarios.",
		"acepta": "¡Por supuesto, Bisente! Vamos a construir esa cerca.",
		"pantalla": "¡Ayudaste a Bisente a construir su cerca!",
		"rechaza": "Lo siento, Bisente. Tengo un encargo que debo preparar para mañana. No puedo construir la cerca hoy.",
	},
	{
		"id": 8, "npc": "bisente", "horas": 4, "energia": 20.0,
		"npc_dice": "¡Nutrilda! ¿Me acompañas al pueblo a comprar suministros? No quiero ir solo y necesito cargar varias cosas pesadas.",
		"piensa": "Me gustaría acompañarlo para hacerle compañía, pero ya está anocheciendo y todavía debo alimentar a mis animales y preparar mi casa para dormir.",
		"acepta": "¡Está bien, Bisente! Te acompañaré al pueblo.",
		"pantalla": "¡Acompañaste a Bisente al pueblo!",
		"rechaza": "Lo siento, Bisente. Ya está oscureciendo y necesito cuidar de mis animales y preparar mi casa. Quizá puedas pedirle a alguien que te acompañe mañana.",
	},
]

static func favores_de(npc: String) -> Array:
	return FAVORES.filter(func(f): return f["npc"] == npc)

# Elige cómo rechaza Nutrilda. Si está cansada, prioriza los diálogos de cansancio.
static func frase_rechazo(especifica: String, cansada: bool) -> String:
	if cansada:
		return RECHAZOS_CANSADA.pick_random()
	if especifica != "" and randf() < 0.65:
		return especifica
	return RECHAZOS.pick_random()
