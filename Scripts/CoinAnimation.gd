extends Sprite2D

@export var animation_speed: float = 10.0  # Frames per second

var frame_timer: float = 0.0

func _process(delta):
	frame_timer += delta * animation_speed
	if frame_timer >= 1.0:
		frame_timer -= 1.0
		frame = (frame + 1) % hframes
