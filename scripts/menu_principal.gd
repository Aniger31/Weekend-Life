extends Node2D
# Menú principal: arranca la música de fondo (si ya suena, no la reinicia).

func _ready() -> void:
	Musica.iniciar()
	Musica.modo_juego()
