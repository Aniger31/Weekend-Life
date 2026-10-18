extends Sprite2D

func _process(delta):

	rotation += delta

	position.x += 50 * delta
