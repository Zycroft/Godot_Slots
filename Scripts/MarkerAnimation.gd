extends Control

# Animates the High Roller marker flying in from bottom right

var start_position: Vector2
var end_position: Vector2
var swoosh_sound: AudioStreamPlayer
var slap_sound: AudioStreamPlayer

func _ready():
	# Store the final destination position
	end_position = position

	# Start hidden off-screen (bottom right)
	start_position = Vector2(1920 + 200, 1080 + 200)
	position = start_position
	visible = false

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

	# Play swoosh sound
	swoosh_sound.play()

	# Create fly-in animation with easing
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "position", end_position, 1.125)
	tween.tween_callback(_on_fly_in_complete)

func _on_fly_in_complete():
	# Play slap sound when it lands
	slap_sound.play()

	# Add a small shake effect
	var original_pos = position
	var tween = create_tween()
	tween.tween_property(self, "position", original_pos + Vector2(-5, 5), 0.03)
	tween.tween_property(self, "position", original_pos + Vector2(3, -3), 0.03)
	tween.tween_property(self, "position", original_pos, 0.03)
