extends Node2D

# Symbol strips for each reel (VBoxContainer that scrolls)
@onready var reel1_strip: VBoxContainer = $ReelContainer/Reel1/ClipContainer/SymbolStrip
@onready var reel2_strip: VBoxContainer = $ReelContainer/Reel2/ClipContainer/SymbolStrip
@onready var reel3_strip: VBoxContainer = $ReelContainer/Reel3/ClipContainer/SymbolStrip

# Explosion AnimatedSprite2D nodes
@onready var explosion1: AnimatedSprite2D = $ReelContainer/Reel1/Explosion
@onready var explosion2: AnimatedSprite2D = $ReelContainer/Reel2/Explosion
@onready var explosion3: AnimatedSprite2D = $ReelContainer/Reel3/Explosion

@onready var spin_button: Button = $SpinButton
@onready var credits_label: Label = $CreditsLabel
@onready var lever: TextureButton = $Lever

# HUD labels
@onready var amount_label: Label = $"../HUD/Marker/AmountLabel"
@onready var due_label: Label = $"../HUD/Marker/DueLabel"

# Audio players
@onready var sfx_spin_start: AudioStreamPlayer = $SFX/SpinStart
@onready var sfx_reel_spin: AudioStreamPlayer = $SFX/ReelSpin
@onready var sfx_reel_stop: AudioStreamPlayer = $SFX/ReelStop
@onready var sfx_slot_win: AudioStreamPlayer = $SFX/SlotWin

# Symbol textures - loaded at runtime
var symbol_textures: Array = []

# Reel configuration
const SYMBOL_HEIGHT: float = 200.0
const SYMBOL_SPACING: float = 40.0
const SYMBOL_TOTAL_HEIGHT: float = SYMBOL_HEIGHT + SYMBOL_SPACING
const NUM_SYMBOLS: int = 5
const VISIBLE_OFFSET: float = 50.0  # Offset to center symbol in view

# Spin state
var credits: int = 100
var hours_remaining: float = 8.0
const HOURS_PER_SPIN: float = 0.5
const SPIN_COST: int = 1
var is_spinning: bool = false
var spin_time: float = 0.0
var spin_duration: float = 2.5

# Per-reel state
var reel_strips: Array = []
var reel_speeds: Array = [0.0, 0.0, 0.0]
var reel_positions: Array = [0.0, 0.0, 0.0]
var reels_stopped: Array = [false, false, false]
var final_symbols: Array = [0, 0, 0]

# Spin physics
const BASE_SPEED: float = 2000.0
const DECEL_RATE: float = 800.0

# Win symbol index (Bar = index 3)
const WIN_SYMBOL = 3

var is_exploding: bool = false
var explosions_finished: int = 0

# Lever state
var lever_start_pos: Vector2
var is_lever_pulling: bool = false

func _ready():
	spin_button.pressed.connect(_on_spin_pressed)
	lever.pressed.connect(_on_lever_pressed)
	lever_start_pos = lever.position

	# Connect explosion animation finished signals
	explosion1.animation_finished.connect(_on_explosion_finished)
	explosion2.animation_finished.connect(_on_explosion_finished)
	explosion3.animation_finished.connect(_on_explosion_finished)

	reel_strips = [reel1_strip, reel2_strip, reel3_strip]

	# Load symbol textures from the first reel's children
	for child in reel1_strip.get_children():
		if child is TextureRect:
			symbol_textures.append(child.texture)

	# Initialize reels at random positions
	for i in range(3):
		var start_symbol = randi() % NUM_SYMBOLS
		reel_positions[i] = start_symbol * SYMBOL_TOTAL_HEIGHT
		_update_reel_position(i)

	# Initialize HUD
	_update_hud()

func _process(delta):
	if is_spinning:
		spin_time += delta
		_update_spin(delta)

func _update_spin(delta):
	for i in range(3):
		if reels_stopped[i]:
			continue

		# Calculate when this reel should start stopping
		var stop_start_time = spin_duration * (0.4 + i * 0.15)

		if spin_time > stop_start_time:
			# Decelerate
			reel_speeds[i] = max(0, reel_speeds[i] - DECEL_RATE * delta)

			if reel_speeds[i] <= 0:
				# Snap to nearest symbol
				_stop_reel(i)
				continue

		# Increase position to scroll symbols downward (strip moves up, symbols appear from top)
		reel_positions[i] += reel_speeds[i] * delta

		# Wrap position
		var total_strip_height = NUM_SYMBOLS * SYMBOL_TOTAL_HEIGHT
		if reel_positions[i] >= total_strip_height:
			reel_positions[i] = fmod(reel_positions[i], total_strip_height)

		_update_reel_position(i)

	# Check if all stopped
	if reels_stopped[0] and reels_stopped[1] and reels_stopped[2]:
		_stop_spin()

func _stop_reel(reel_index: int):
	reels_stopped[reel_index] = true
	reel_speeds[reel_index] = 0

	# Play reel stop sound
	sfx_reel_stop.play()

	# Snap to nearest symbol position
	var symbol_index = int(round(reel_positions[reel_index] / SYMBOL_TOTAL_HEIGHT)) % NUM_SYMBOLS
	reel_positions[reel_index] = symbol_index * SYMBOL_TOTAL_HEIGHT
	final_symbols[reel_index] = symbol_index

	_update_reel_position(reel_index)

func _update_reel_position(reel_index: int):
	# Move the strip down (positive Y) so symbols scroll downward into view
	# We offset by the total height to keep symbols visible as they wrap
	var strip = reel_strips[reel_index]
	var total_strip_height = NUM_SYMBOLS * SYMBOL_TOTAL_HEIGHT
	strip.position.y = reel_positions[reel_index] - total_strip_height + VISIBLE_OFFSET

func _on_spin_pressed():
	if is_spinning or is_exploding or credits < SPIN_COST or hours_remaining < HOURS_PER_SPIN:
		return

	credits -= SPIN_COST
	hours_remaining -= HOURS_PER_SPIN
	_update_credits_display()
	_update_hud()

	is_spinning = true
	spin_time = 0.0
	reels_stopped = [false, false, false]
	spin_button.disabled = true
	lever.disabled = true

	# Hide explosions and show reel strips
	explosion1.visible = false
	explosion2.visible = false
	explosion3.visible = false

	for strip in reel_strips:
		strip.visible = true

	# Play spin start sound and looping reel spin
	sfx_spin_start.play()
	sfx_reel_spin.play()

	# Start spinning - each reel at slightly different speed for variety
	for i in range(3):
		reel_speeds[i] = BASE_SPEED + randf_range(-200, 200)

func _stop_spin():
	is_spinning = false

	# Stop the spinning sound
	sfx_reel_spin.stop()

	# Check for win (all same symbol)
	if final_symbols[0] == WIN_SYMBOL and final_symbols[1] == WIN_SYMBOL and final_symbols[2] == WIN_SYMBOL:
		_play_explosion()
		credits += 50
		_update_credits_display()
	else:
		spin_button.disabled = false
		lever.disabled = false

func _play_explosion():
	is_exploding = true
	explosions_finished = 0

	# Play win sound
	sfx_slot_win.play()

	# Hide the reel strips and show explosions
	for strip in reel_strips:
		strip.visible = false

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

func _on_explosion_finished():
	explosions_finished += 1

	# Wait for all 3 explosions to finish
	if explosions_finished >= 3:
		explosions_finished = 0
		is_exploding = false
		spin_button.disabled = false
		lever.disabled = false

func _update_credits_display():
	credits_label.text = "Credits: " + str(credits)

func _update_hud():
	amount_label.text = "$" + str(credits)
	due_label.text = str(int(hours_remaining))

func _on_lever_pressed():
	if is_spinning or is_exploding or is_lever_pulling or credits < SPIN_COST or hours_remaining < HOURS_PER_SPIN:
		return

	is_lever_pulling = true
	lever.disabled = true

	# Animate lever pull down
	var tween = create_tween()
	tween.tween_property(lever, "position:y", lever_start_pos.y + 100, 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_start_spin_from_lever)
	tween.tween_property(lever, "position:y", lever_start_pos.y, 0.3).set_ease(Tween.EASE_OUT).set_delay(0.1)
	tween.tween_callback(_on_lever_reset)

func _start_spin_from_lever():
	_on_spin_pressed()

func _on_lever_reset():
	is_lever_pulling = false
	if not is_spinning and not is_exploding:
		lever.disabled = false
