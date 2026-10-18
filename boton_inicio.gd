extends TextureButton
# Botón "JUGAR": flota suavemente, crece un poquito al pasar el mouse
# y al hacer clic te lleva a la casa de la nutria.

var tiempo := 0.0
var posicion_inicial := Vector2.ZERO

func _ready():
	posicion_inicial = position
	pivot_offset = size / 2.0   # para que crezca desde el centro
	mouse_entered.connect(_al_entrar_mouse)
	mouse_exited.connect(_al_salir_mouse)
	pressed.connect(_al_presionar)

func _process(delta):
	tiempo += delta
	position.y = posicion_inicial.y + sin(tiempo * 2.0) * 5

func _al_entrar_mouse():
	create_tween().tween_property(self, "scale", Vector2(1.06, 1.06), 0.1)

func _al_salir_mouse():
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.1)

func _al_presionar():
	get_tree().change_scene_to_file("res://casa_nutri.tscn")
