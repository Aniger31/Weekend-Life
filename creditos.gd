extends Control
# Pantalla de créditos: el texto sube solo. Con clic, Enter, Espacio o Esc
# se salta. Al terminar vuelves al menú (si venías de jugar) o se cierra el juego (si diste SALIR).

const VELOCIDAD := 70.0   # píxeles por segundo

# Edita aquí los créditos. Puedes usar [font_size=40]...[/font_size] para
# cambiar el tamaño y [color=#ffd98a]...[/color] para el color.
# (Ojo: no uses corchetes [ ] para tus textos, usa paréntesis.)
var texto_creditos := """[center]
[font_size=60][color=#ffe9b0]Weekend Life[/color][/font_size]
Tu descanso también importa


[font_size=34][color=#ffd98a]Un juego de[/color][/font_size]
WorkBeats


[font_size=34][color=#ffd98a]Personajes[/color][/font_size]
Nutrilda, la nutria
Berny, el oso
Sam, el conejo
Bisente, el bisonte


[font_size=34][color=#ffd98a]Arte[/color][/font_size]
Chealsea Rincón


[font_size=34][color=#ffd98a]Programación[/color][/font_size]
Diana Martínez, Fernanda Francisca

[font_size=34][color=#ffd98a]Audio[/color][/font_size]
Regina Hernández

[font_size=34][color=#ffd98a]Hecho con[/color][/font_size]
Godot Engine
Tipografía Fredoka One (SIL Open Font License)
Audio Tool 


[font_size=44][color=#ffe9b0]¡Gracias por jugar!

[/color][/font_size]
[/center]"""

@onready var texto: RichTextLabel = $Texto
var listo := false

func _ready():
	Musica.iniciar()
	texto.text = texto_creditos
	await get_tree().process_frame   # esperamos a que calcule su altura
	texto.position.y = get_viewport_rect().size.y
	listo = true

func _process(delta):
	if not listo:
		return
	texto.position.x = (get_viewport_rect().size.x - texto.size.x) / 2.0
	texto.position.y -= VELOCIDAD * delta
	if texto.position.y + texto.size.y < 0.0:
		terminar()

func _input(event):
	var clic = event is InputEventMouseButton and event.pressed
	if clic or event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		terminar()

func terminar():
	if Partida.creditos_vuelven_al_menu:      # venías de terminar el fin de semana
		Partida.creditos_vuelven_al_menu = false
		get_tree().change_scene_to_file("res://main.tscn")
	else:                                      # venías del botón SALIR
		get_tree().quit()
