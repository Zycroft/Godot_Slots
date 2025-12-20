extends Node2D

# AnimatedSprite2D nodes for each reel
@onready var reel1_anim: AnimatedSprite2D = $ReelContainer/Reel1/SymbolContainer/Node2D/AnimatedSprite2D
@onready var reel2_anim: AnimatedSprite2D = $ReelContainer/Reel2/SymbolContainer/Symbol/Node2D/AnimatedSprite2D
@onready var reel3_anim: AnimatedSprite2D = $ReelContainer/Reel3/SymbolContainer/Node2D/AnimatedSprite2D

# Explosion AnimatedSprite2D nodes
@onready var explosion1: AnimatedSprite2D = $ReelContainer/Reel1/SymbolContainer/Node2D/Explosion
@onready var explosion2: AnimatedSprite2D = $ReelContainer/Reel2/SymbolContainer/Symbol/Node2D/Explosion
@onready var explosion3: AnimatedSprite2D = $ReelContainer/Reel3/SymbolContainer/Node2D/Explosion

@onready var spin_button: Button = $SpinButton
@onready var credits_label: Label = $CreditsLabel

var credits: int = 100
var is_spinning: bool = false
var spin_time: float = 0.0
var spin_duration: float = 2.5
var reels_stopped: Array = [false, false, false]
var final_frames: Array = [0, 0, 0]

# Orange frame index (frame 3 based on your sprite sheet - 4th symbol)
const ORANGE_FRAME = 3

var is_exploding: bool = false

func _ready():
	spin_button.pressed.connect(_on_spin_pressed)

	# Connect explosion animation finished signals
	explosion1.animation_finished.connect(_on_explosion_finished)
	explosion2.animation_finished.connect(_on_explosion_finished)
	explosion3.animation_finished.connect(_on_explosion_finished)

	# Stop animations initially and show a random frame
	reel1_anim.stop()
	reel2_anim.stop()
	reel3_anim.stop()

	# Set random starting frames
	reel1_anim.frame = randi() % 16
	reel2_anim.frame = randi() % 16
	reel3_anim.frame = randi() % 16

func _process(delta):
	if is_spinning:
		spin_time += delta
		_update_spin()

func _update_spin():
	var anims = [reel1_anim, reel2_anim, reel3_anim]

	for i in range(3):
		if reels_stopped[i]:
			continue

		var stop_time = spin_duration * (0.5 + i * 0.2)

		if spin_time > stop_time:
			# Stop this reel on orange (frame 3)
			reels_stopped[i] = true
			anims[i].stop()
			anims[i].frame = ORANGE_FRAME
			final_frames[i] = ORANGE_FRAME

			# Check if all stopped
			if reels_stopped[0] and reels_stopped[1] and reels_stopped[2]:
				_stop_spin()

func _on_spin_pressed():
	if is_spinning or is_exploding or credits <= 0:
		return

	credits -= 1
	_update_credits_display()

	is_spinning = true
	spin_time = 0.0
	reels_stopped = [false, false, false]
	spin_button.disabled = true

	# Hide explosions and show reel symbols for new spin
	explosion1.visible = false
	explosion2.visible = false
	explosion3.visible = false

	reel1_anim.visible = true
	reel2_anim.visible = true
	reel3_anim.visible = true

	# Start all reel animations
	reel1_anim.play("Spin1")
	reel2_anim.play("Spin1")
	reel3_anim.play("Spin1")

func _stop_spin():
	is_spinning = false

	# Check for win (all oranges)
	if final_frames[0] == ORANGE_FRAME and final_frames[1] == ORANGE_FRAME and final_frames[2] == ORANGE_FRAME:
		_play_explosion()
		credits += 50
		_update_credits_display()
	else:
		spin_button.disabled = false

func _play_explosion():
	is_exploding = true

	# Hide the reel symbols and show explosions
	reel1_anim.visible = false
	reel2_anim.visible = false
	reel3_anim.visible = false

	explosion1.visible = true
	explosion2.visible = true
	explosion3.visible = true

	# Play the explosion animation on all reels
	explosion1.frame = 0
	explosion2.frame = 0
	explosion3.frame = 0

	explosion1.play("Explode")
	explosion2.play("Explode")
	explosion3.play("Explode")

var explosions_finished: int = 0

func _on_explosion_finished():
	explosions_finished += 1

	# Wait for all 3 explosions to finish
	if explosions_finished >= 3:
		explosions_finished = 0
		is_exploding = false

		# Keep explosions visible on the last frame
		# Don't hide them or switch back to reel symbols

		spin_button.disabled = false

func _update_credits_display():
	credits_label.text = "Credits: " + str(credits)
