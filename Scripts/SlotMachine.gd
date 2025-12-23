extends Node2D

# Symbol strips for each reel (VBoxContainer that scrolls)
@onready var reel1_strip: VBoxContainer = $ReelContainer/Reel1/ClipContainer/SymbolStrip


@onready var spin_button: Button = $SpinButton
@onready var credits_label: Label = $CreditsLabel
@onready var lever: Control = $Lever
@onready var lever_button: Button = $Lever/LeverButton
@onready var lever_sprite: Sprite2D = $Lever/LeverSprite

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
@export var reelslots: int = 10  # Number of actual symbol positions (0-9)
@export var spin_direction_down: bool = true  # true = down, false = up
const WRAP_BUFFER: int = 3  # Extra symbols at end for seamless wrap
const SYMBOL_HEIGHT: float = 100.0
const SYMBOL_SPACING: float = 0.0
const SYMBOL_TOTAL_HEIGHT: float = SYMBOL_HEIGHT + SYMBOL_SPACING

# Spin state
var credits: int = 100
var hours_remaining: float = 8.0
const HOURS_PER_SPIN: float = 0.5
const SPIN_COST: int = 1
var is_spinning: bool = false
var spin_time: float = 0.0
var spin_duration: float = 2.5

# Per-reel state (single reel for testing)
var reel_strips: Array = []
var reel_speeds: Array = [0.0]
var reel_positions: Array = [0.0]
var reels_stopped: Array = [false]
var final_symbols: Array = [0]

# Spin physics
const BASE_SPEED: float = 2000.0
const DECEL_RATE: float = 800.0

# Win symbol index (Bar = index 3)
const WIN_SYMBOL = 3


# Lever state
var lever_start_pos: Vector2
var is_lever_pulling: bool = false
const LEVER_FRAMES: int = 4

func _ready():
	spin_button.pressed.connect(_on_spin_pressed)
	lever_button.pressed.connect(_on_lever_clicked)
	lever_start_pos = lever.position

	reel_strips = [reel1_strip]

	# Load symbol textures from the first reel's children
	for child in reel1_strip.get_children():
		if child is TextureRect:
			symbol_textures.append(child.texture)

	# Update symbol visibility based on reelslots
	_update_symbol_visibility()

	# Initialize reels at fixed position (Symbol1 = Payline centered)
	reel_positions[0] = 1 * SYMBOL_TOTAL_HEIGHT  # Start at symbol index 1 (Payline)
	_update_reel_position(0)

	# Initialize HUD
	_update_hud()

func _update_symbol_visibility():
	# Show all symbols (main + wrap buffer)
	var total_symbols = reelslots + WRAP_BUFFER
	for strip in reel_strips:
		var children = strip.get_children()
		for i in range(children.size()):
			if children[i] is TextureRect:
				children[i].visible = i < total_symbols

func _process(delta):
	if is_spinning:
		spin_time += delta
		_update_spin(delta)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_on_lever_clicked()

func _update_spin(delta):
	for i in range(1):  # Single reel
		if reels_stopped[i]:
			continue

		# Calculate when this reel should start stopping
		var stop_start_time = spin_duration * 0.4

		if spin_time > stop_start_time:
			# Decelerate
			reel_speeds[i] = max(0, reel_speeds[i] - DECEL_RATE * delta)

			if reel_speeds[i] <= 0:
				# Snap to nearest symbol
				_stop_reel(i)
				continue

		# Update position based on spin direction
		if spin_direction_down:
			reel_positions[i] -= reel_speeds[i] * delta
			# Keep position positive for modulo
			var main_strip_height = reelslots * SYMBOL_TOTAL_HEIGHT
			if reel_positions[i] < 0:
				reel_positions[i] += main_strip_height
		else:
			reel_positions[i] += reel_speeds[i] * delta
		_update_reel_position(i)

	# Check if stopped
	if reels_stopped[0]:
		_stop_spin()

func _stop_reel(reel_index: int):
	reels_stopped[reel_index] = true
	reel_speeds[reel_index] = 0

	# Play reel stop sound
	sfx_reel_stop.play()

	# Snap to nearest symbol position within main slots (0 to reelslots-1)
	var main_strip_height = reelslots * SYMBOL_TOTAL_HEIGHT
	var current_pos = fmod(reel_positions[reel_index], main_strip_height)
	var symbol_index = int(round(current_pos / SYMBOL_TOTAL_HEIGHT)) % reelslots
	reel_positions[reel_index] = symbol_index * SYMBOL_TOTAL_HEIGHT
	final_symbols[reel_index] = symbol_index

	_update_reel_position(reel_index)

func _update_reel_position(reel_index: int):
	# Move the strip up as position increases (symbols scroll down)
	var strip = reel_strips[reel_index]
	# Use modulo for seamless looping over the main symbols only
	var main_strip_height = reelslots * SYMBOL_TOTAL_HEIGHT
	var visual_pos = fmod(reel_positions[reel_index], main_strip_height)
	# Offset to center symbol on payline (payline at 95px, symbol center at 50px)
	var payline_offset = 45.0
	strip.position.y = -visual_pos + payline_offset

func _on_spin_pressed():
	if is_spinning or credits < SPIN_COST or hours_remaining < HOURS_PER_SPIN:
		return

	credits -= SPIN_COST
	hours_remaining -= HOURS_PER_SPIN
	_update_credits_display()
	_update_hud()

	is_spinning = true
	spin_time = 0.0
	reels_stopped = [false]
	spin_button.disabled = true
	lever_button.disabled = true

	# Reset position to beginning of strip
	reel_positions[0] = 0.0

	for strip in reel_strips:
		strip.visible = true

	# Play spin start sound and looping reel spin
	sfx_spin_start.play()
	sfx_reel_spin.play()

	# Start spinning
	reel_speeds[0] = BASE_SPEED + randf_range(-200, 200)

func _stop_spin():
	is_spinning = false

	# Stop the spinning sound
	sfx_reel_spin.stop()

	# No win check for single reel test - just re-enable buttons
	spin_button.disabled = false
	lever_button.disabled = false


func _update_credits_display():
	credits_label.text = "Credits: " + str(credits)

func _update_hud():
	amount_label.text = "$" + str(credits)
	due_label.text = str(int(hours_remaining))

func _on_lever_clicked():
	if is_spinning or is_lever_pulling or lever_button.disabled or credits < SPIN_COST or hours_remaining < HOURS_PER_SPIN:
		return

	is_lever_pulling = true
	lever_button.disabled = true

	# Animate lever sprite frames (pull down animation)
	var tween = create_tween()
	# Go through frames 0 -> 1 -> 2 -> 3 (pull down)
	tween.tween_property(lever_sprite, "frame", 1, 0.05)
	tween.tween_property(lever_sprite, "frame", 2, 0.05)
	tween.tween_property(lever_sprite, "frame", 3, 0.05)
	tween.tween_callback(_start_spin_from_lever)
	# Go back 3 -> 2 -> 1 -> 0 (return)
	tween.tween_interval(0.1)
	tween.tween_property(lever_sprite, "frame", 2, 0.06)
	tween.tween_property(lever_sprite, "frame", 1, 0.06)
	tween.tween_property(lever_sprite, "frame", 0, 0.06)
	tween.tween_callback(_on_lever_reset)

func _start_spin_from_lever():
	_on_spin_pressed()

func _on_lever_reset():
	is_lever_pulling = false
	lever_sprite.frame = 0
	if not is_spinning:
		lever_button.disabled = false
