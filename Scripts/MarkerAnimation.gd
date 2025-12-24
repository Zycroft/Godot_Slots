extends Control

# Animates the High Roller marker flying in from bottom right

var start_position: Vector2
var end_position: Vector2
var swoosh_sound: AudioStreamPlayer
var slap_sound: AudioStreamPlayer

# Sprite sheet animation
var anim_sprite: Sprite2D
var background: TextureRect
const TOTAL_FRAMES = 49  # 7x7 sprite sheet
var frame_tween: Tween

func _ready():
	# Store the final destination position
	end_position = position

	# Start hidden off-screen (bottom right)
	start_position = Vector2(1920 + 200, 1080 + 200)
	position = start_position
	visible = false

	# Get references to child nodes
	anim_sprite = $AnimSprite
	background = $Background

	# Create audio players
	swoosh_sound = AudioStreamPlayer.new()
	swoosh_sound.stream = load("res://Audio/SFX/swoosh.mp3")
	add_child(swoosh_sound)

	slap_sound = AudioStreamPlayer.new()
	slap_sound.stream = load("res://Audio/SFX/slap.mp3")
	add_child(slap_sound)

	# Connect to game start signal
	GameConfig.config_changed.connect(_on_config_changed)
	GameConfig.game_reset.connect(_on_game_reset)

func _on_config_changed():
	if GameConfig.game_started and not visible:
		_fly_in()

func _on_game_reset():
	# Reset to off-screen position
	position = start_position
	visible = false

func _fly_in():
	visible = true
	position = start_position

	# Show animated sprite, hide static background during fly-in
	anim_sprite.visible = true
	anim_sprite.frame = 0
	background.visible = false

	# Play swoosh sound
	swoosh_sound.play()

	# Animate through sprite sheet frames during fly-in
	var fly_duration = 2.025  # 80% slower than original 1.125s
	frame_tween = create_tween()
	frame_tween.tween_method(_set_frame, 0, TOTAL_FRAMES - 1, fly_duration)

	# Create fly-in animation with easing
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "position", end_position, fly_duration)
	tween.tween_callback(_on_fly_in_complete)

func _set_frame(frame_num: int):
	anim_sprite.frame = frame_num

func _on_fly_in_complete():
	# Switch from animated sprite to static background
	anim_sprite.visible = false
	background.visible = true

	# Play slap sound when it lands
	slap_sound.play()

	# Add a small shake effect
	var original_pos = position
	var tween = create_tween()
	tween.tween_property(self, "position", original_pos + Vector2(-5, 5), 0.03)
	tween.tween_property(self, "position", original_pos + Vector2(3, -3), 0.03)
	tween.tween_property(self, "position", original_pos, 0.03)
