extends Sprite2D

@export var animation_speed: float = 10.0  # Frames per second
@export var start_frame: int = 45
@export var end_frame: int = 51
@export var drop_distance: float = 100.0
@export var bounce_height: float = 30.0
@export var bounce_duration: float = 0.3
@export var bounce_horizontal: float = 20.0  # How far left/right to bounce
@export var auto_start: bool = false  # Set to false to wait for trigger

var frame_timer: float = 0.0
var start_y: float
var start_x: float
var is_dropping: bool = false
var is_bouncing: bool = false
var bounce_timer: float = 0.0
var bounce_direction: float = 1.0
var land_sound: AudioStreamPlayer

func _ready():
	frame = start_frame
	start_y = position.y
	start_x = position.x
	randomize()

	# Create audio player for landing sound
	land_sound = AudioStreamPlayer.new()
	land_sound.stream = load("res://Audio/SFX/coin_land.mp3")
	add_child(land_sound)

	if auto_start:
		visible = true
		is_dropping = true
	else:
		visible = false

func drop():
	# Reset and start the drop animation
	position.y = start_y
	position.x = start_x
	frame = start_frame
	frame_timer = 0.0
	bounce_timer = 0.0
	is_bouncing = false
	is_dropping = true
	visible = true

func _process(delta):
	if not is_dropping:
		return

	if is_bouncing:
		bounce_timer += delta
		var bounce_progress = bounce_timer / bounce_duration
		if bounce_progress >= 1.0:
			# Bounce finished, hide coin
			is_bouncing = false
			is_dropping = false
			visible = false
			frame = start_frame
			position.y = start_y
			position.x = start_x
		else:
			# Bounce up and down using sine curve
			var landed_y = start_y + drop_distance
			var bounce_offset = sin(bounce_progress * PI) * bounce_height
			position.y = landed_y - bounce_offset
			# Move horizontally during bounce
			position.x = start_x + (bounce_progress * bounce_horizontal * bounce_direction)
	else:
		frame_timer += delta * animation_speed
		if frame_timer >= 1.0:
			frame_timer -= 1.0
			frame += 1
			if frame > end_frame:
				# Start bouncing
				is_bouncing = true
				frame = end_frame
				bounce_direction = 1.0 if randf() > 0.5 else -1.0
				land_sound.play()
			else:
				# Calculate drop per frame
				var frame_count = end_frame - start_frame
				var drop_per_frame = drop_distance / frame_count
				var frames_elapsed = frame - start_frame
				position.y = start_y + (frames_elapsed * drop_per_frame)
