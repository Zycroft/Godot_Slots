extends Node2D

# Reel container reference
@onready var reel_container: HBoxContainer = $ReelContainer
@onready var reel_background: Panel = $ReelBackground
@onready var flame_effect: Sprite2D = $FlameEffect

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
@onready var sfx_fire_crackle: AudioStreamPlayer = $SFX/FireCrackle

# Constants
const WRAP_BUFFER: int = 3
const SYMBOL_HEIGHT: float = 100.0
const SYMBOL_SPACING: float = 0.0
const SYMBOL_TOTAL_HEIGHT: float = SYMBOL_HEIGHT + SYMBOL_SPACING
const BASE_SPEED: float = 2000.0
const DECEL_RATE: float = 800.0

# Spin state
var is_spinning: bool = false
var spin_time: float = 0.0

# Per-reel state (dynamically sized)
var reel_panels: Array = []
var reel_strips: Array = []
var reel_speeds: Array = []
var reel_positions: Array = []
var reels_stopped: Array = []
var final_symbols: Array = []

# Lever state
var lever_start_pos: Vector2
var is_lever_pulling: bool = false

# Preloaded scripts
var grid_overlay_script = preload("res://Scripts/GridOverlay.gd")
var coin_script = preload("res://Scripts/CoinAnimation.gd")

# Coin spawning
var coin_texture: Texture2D
@export var coins_to_spawn: int = 5
@export var coin_spawn_delay: float = 0.1

# Style for reel panels
var reel_style: StyleBoxFlat

func _ready():
	spin_button.pressed.connect(_on_spin_pressed)
	lever_button.pressed.connect(_on_lever_clicked)
	lever_start_pos = lever.position

	# Create background panel style with 4px border
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.35, 0.35, 0.35, 1)
	bg_style.border_width_left = 4
	bg_style.border_width_top = 4
	bg_style.border_width_right = 4
	bg_style.border_width_bottom = 4
	bg_style.border_color = Color(0, 0, 0, 1)
	reel_background.add_theme_stylebox_override("panel", bg_style)

	# Create reel panel style
	reel_style = StyleBoxFlat.new()
	reel_style.bg_color = Color(1, 1, 1, 1)
	reel_style.border_width_left = 2
	reel_style.border_width_top = 2
	reel_style.border_width_right = 2
	reel_style.border_width_bottom = 2
	reel_style.border_color = Color(0, 0, 0, 1)

	# Connect to config changes
	GameConfig.config_changed.connect(_on_config_changed)
	GameConfig.card_purchased.connect(_on_card_purchased)

	# Build initial reels from config
	_rebuild_reels()

	# Initialize HUD
	_update_hud()

	# Load coin texture
	coin_texture = load("res://Assets/SingleImages/output/gold_coin_strip.png")

func _on_config_changed():
	# Rebuild reels when config changes (only if not spinning)
	if not is_spinning:
		_rebuild_reels()
		_update_hud()

func _rebuild_reels():
	# Clear existing reels
	_clear_reels()

	# Get config values
	var num_reels = GameConfig.num_reels
	var visible_rows = GameConfig.visible_rows
	var reelslots = GameConfig.reelslots

	# Calculate dimensions
	var reel_height = visible_rows * SYMBOL_HEIGHT
	var reel_width = 104.0
	var reel_spacing = 30.0

	# Update container dimensions
	var total_width = (num_reels * reel_width) + ((num_reels - 1) * reel_spacing)
	reel_container.set("theme_override_constants/separation", int(reel_spacing))
	reel_container.offset_left = -total_width / 2
	reel_container.offset_right = total_width / 2
	reel_container.offset_top = -reel_height / 2
	reel_container.offset_bottom = reel_height / 2

	# Update background
	var padding = 30.0
	reel_background.offset_left = -(total_width / 2) - padding
	reel_background.offset_right = (total_width / 2) + padding
	reel_background.offset_top = -(reel_height / 2) - padding
	reel_background.offset_bottom = (reel_height / 2) + padding

	# Update lever position (just right of reel background)
	lever.offset_left = (total_width / 2) + padding - 15
	lever.offset_right = lever.offset_left + 60

	# Initialize arrays
	reel_panels = []
	reel_strips = []
	reel_speeds = []
	reel_positions = []
	reels_stopped = []
	final_symbols = []

	# Create reels
	for i in range(num_reels):
		_create_reel(i, reel_width, reel_height, reelslots)

	# Initialize reel positions
	for i in range(num_reels):
		reel_positions[i] = 1 * SYMBOL_TOTAL_HEIGHT
		_update_reel_position(i)

func _clear_reels():
	# Remove all existing reel panels
	for panel in reel_panels:
		if is_instance_valid(panel):
			panel.queue_free()
	reel_panels.clear()
	reel_strips.clear()

func _create_reel(reel_index: int, width: float, height: float, num_slots: int):
	# Create Panel
	var panel = Panel.new()
	panel.name = "Reel%d" % (reel_index + 1)
	panel.custom_minimum_size = Vector2(width, height)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.add_theme_stylebox_override("panel", reel_style)
	reel_container.add_child(panel)
	reel_panels.append(panel)

	# Create ClipContainer
	var clip = Control.new()
	clip.name = "ClipContainer"
	clip.clip_contents = true
	clip.set_anchors_preset(Control.PRESET_FULL_RECT)
	clip.offset_left = 2
	clip.offset_right = -2
	clip.offset_top = 2
	clip.offset_bottom = -2
	panel.add_child(clip)

	# Create SymbolStrip
	var strip = VBoxContainer.new()
	strip.name = "SymbolStrip"
	strip.offset_right = 100
	strip.offset_bottom = (num_slots + WRAP_BUFFER) * SYMBOL_TOTAL_HEIGHT
	strip.set("theme_override_constants/separation", 0)
	clip.add_child(strip)
	reel_strips.append(strip)

	# Get symbol configuration for this reel
	var reel_symbols = GameConfig.get_reel_symbols(reel_index)
	var total_symbols = num_slots + WRAP_BUFFER

	# Create symbols
	for slot_index in range(total_symbols):
		var symbol_index = slot_index % reel_symbols.size() if reel_symbols.size() > 0 else 0
		var symbol_name = reel_symbols[symbol_index] if symbol_index < reel_symbols.size() else "cherry"

		var tex_rect = TextureRect.new()
		tex_rect.name = "Symbol%d" % slot_index if slot_index < num_slots else "Symbol%d_wrap" % slot_index
		tex_rect.custom_minimum_size = Vector2(SYMBOL_HEIGHT, SYMBOL_HEIGHT)
		tex_rect.size = Vector2(SYMBOL_HEIGHT, SYMBOL_HEIGHT)
		tex_rect.texture = GameConfig.get_symbol_texture(symbol_name)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		strip.add_child(tex_rect)

	# Create GridOverlay
	var overlay = Control.new()
	overlay.name = "GridOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_script(grid_overlay_script)
	panel.add_child(overlay)

	# Initialize per-reel state
	reel_speeds.append(0.0)
	reel_positions.append(0.0)
	reels_stopped.append(false)
	final_symbols.append(0)

func _process(delta):
	if is_spinning:
		spin_time += delta
		_update_spin(delta)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_on_lever_clicked()

func _update_spin(delta):
	var num_reels = GameConfig.num_reels
	var reelslots = GameConfig.reelslots

	for i in range(num_reels):
		if reels_stopped[i]:
			continue

		# Calculate when this reel should start stopping (staggered)
		var stop_start_time = GameConfig.spin_duration * 0.4 + (i * GameConfig.reel_stop_delay)

		if spin_time > stop_start_time:
			# Decelerate
			reel_speeds[i] = max(0, reel_speeds[i] - DECEL_RATE * delta)

			if reel_speeds[i] <= 0:
				_stop_reel(i)
				continue

		# Update position based on spin direction
		if GameConfig.spin_direction_down:
			reel_positions[i] -= reel_speeds[i] * delta
			var main_strip_height = reelslots * SYMBOL_TOTAL_HEIGHT
			if reel_positions[i] < 0:
				reel_positions[i] += main_strip_height
		else:
			reel_positions[i] += reel_speeds[i] * delta
		_update_reel_position(i)

	# Check if all reels stopped
	var all_stopped = true
	for i in range(num_reels):
		if not reels_stopped[i]:
			all_stopped = false
			break
	if all_stopped:
		_stop_spin()

func _stop_reel(reel_index: int):
	reels_stopped[reel_index] = true
	reel_speeds[reel_index] = 0

	sfx_reel_stop.play()

	var reelslots = GameConfig.reelslots
	var main_strip_height = reelslots * SYMBOL_TOTAL_HEIGHT
	var current_pos = fmod(reel_positions[reel_index], main_strip_height)
	var symbol_index = int(round(current_pos / SYMBOL_TOTAL_HEIGHT)) % reelslots
	reel_positions[reel_index] = symbol_index * SYMBOL_TOTAL_HEIGHT
	final_symbols[reel_index] = symbol_index

	_update_reel_position(reel_index)

func _update_reel_position(reel_index: int):
	if reel_index >= reel_strips.size():
		return

	var strip = reel_strips[reel_index]
	var reelslots = GameConfig.reelslots

	var main_strip_height = reelslots * SYMBOL_TOTAL_HEIGHT
	var visual_pos = fmod(reel_positions[reel_index], main_strip_height)

	# Simply position the strip so symbols align with the visible area
	strip.position.y = -visual_pos

func _on_spin_pressed():
	if not GameConfig.game_started:
		return
	if is_spinning or GameConfig.credits < GameConfig.spin_cost or GameConfig.hours_remaining < GameConfig.hours_per_spin:
		return

	GameConfig.credits -= GameConfig.spin_cost
	GameConfig.hours_remaining -= GameConfig.hours_per_spin
	_update_credits_display()
	_update_hud()

	is_spinning = true
	spin_time = 0.0
	spin_button.disabled = true
	lever_button.disabled = true

	var num_reels = GameConfig.num_reels
	for i in range(num_reels):
		reels_stopped[i] = false
		reel_positions[i] = 0.0
		reel_speeds[i] = BASE_SPEED + randf_range(-200, 200)

	for strip in reel_strips:
		strip.visible = true

	sfx_spin_start.play()
	sfx_reel_spin.play()

func _stop_spin():
	is_spinning = false
	sfx_reel_spin.stop()
	spin_button.disabled = false
	lever_button.disabled = false

	# Play flame eruption effect
	_play_flame_effect()

	# Spawn coins when spin stops
	_spawn_coins()

func _spawn_coins():
	for i in range(coins_to_spawn):
		var coin = Sprite2D.new()
		coin.texture = coin_texture
		coin.hframes = 144
		coin.scale = Vector2(0.8, 0.8)

		# Random position across the tray area
		var base_x = randf_range(-200, 200)
		var base_y = 310  # Above the tray
		coin.position = Vector2(base_x, base_y)

		coin.set_script(coin_script)
		add_child(coin)

		# Trigger drop with delay
		var delay = i * coin_spawn_delay
		get_tree().create_timer(delay).timeout.connect(coin.drop)

		# Remove coin after animation finishes
		get_tree().create_timer(delay + 2.0).timeout.connect(coin.queue_free)

func _play_flame_effect():
	# Position flame at top of reel frame
	flame_effect.position.y = reel_background.offset_top
	flame_effect.frame = 0
	flame_effect.visible = true
	flame_effect.modulate.a = 1.0

	# Play fire crackle sound
	sfx_fire_crackle.play()

	# Animate through 14 frames (7 columns x 2 rows) - doubled duration
	var tween = create_tween()
	for i in range(14):
		tween.tween_property(flame_effect, "frame", i, 0.24)

	# Fade out at the end
	tween.tween_property(flame_effect, "modulate:a", 0.0, 1.2)
	tween.parallel().tween_property(sfx_fire_crackle, "volume_db", -40.0, 1.2)
	tween.tween_callback(func():
		flame_effect.visible = false
		sfx_fire_crackle.stop()
		sfx_fire_crackle.volume_db = 0.0
	)

func _update_credits_display():
	credits_label.text = "Credits: " + str(GameConfig.credits)

func _update_hud():
	amount_label.text = "$" + str(GameConfig.credits)
	due_label.text = str(int(GameConfig.hours_remaining))

func _on_lever_clicked():
	if not GameConfig.game_started:
		return
	if is_spinning or is_lever_pulling or lever_button.disabled:
		return
	if GameConfig.credits < GameConfig.spin_cost or GameConfig.hours_remaining < GameConfig.hours_per_spin:
		return

	is_lever_pulling = true
	lever_button.disabled = true

	var tween = create_tween()
	tween.tween_property(lever_sprite, "frame", 1, 0.05)
	tween.tween_property(lever_sprite, "frame", 2, 0.05)
	tween.tween_property(lever_sprite, "frame", 3, 0.05)
	tween.tween_callback(_start_spin_from_lever)
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

# Public method to update config at runtime
func apply_new_config(config_data: Dictionary):
	GameConfig.update_config(config_data)

func _on_card_purchased(card_id: String):
	match card_id:
		"reel":
			add_reel()
		"payline":
			add_payline()
		"symbol":
			add_symbol()

func add_reel():
	var new_num_reels = GameConfig.num_reels + 1

	# Create new reel with shuffled symbols
	var base_symbols = ["cherry", "lemon", "red7", "grape", "creature"]
	var new_reel_symbols = []
	for i in range(GameConfig.reelslots):
		new_reel_symbols.append(base_symbols[i % base_symbols.size()])
	new_reel_symbols.shuffle()

	var new_reels = GameConfig.reels.duplicate(true)
	new_reels.append({"symbols": new_reel_symbols})

	# Update existing paylines to match new reel count
	var new_paylines = GameConfig.paylines.duplicate(true)
	for i in range(new_paylines.size()):
		while new_paylines[i].size() < new_num_reels:
			new_paylines[i].append(0)

	GameConfig.update_config({
		"num_reels": new_num_reels,
		"reels": new_reels,
		"paylines": new_paylines
	})

func add_payline():
	var new_visible_rows = GameConfig.visible_rows + 1

	# Add a new payline on the new bottom row
	var new_paylines = GameConfig.paylines.duplicate(true)
	var new_payline = []
	for i in range(GameConfig.num_reels):
		new_payline.append(new_visible_rows - 1)
	new_paylines.append(new_payline)

	GameConfig.update_config({
		"visible_rows": new_visible_rows,
		"paylines": new_paylines
	})

func add_symbol():
	# List of available symbols to add
	var available_symbols = {
		"orange": "res://assets.sprites/Orange.tres",
		"plum": "res://assets.sprites/plum.tres",
		"star": "res://assets.sprites/star.tres",
		"crown": "res://assets.sprites/crown.tres",
		"diamond": "res://assets.sprites/Diamond.tres"
	}

	# Find a symbol not already in use
	var new_symbol_name = ""
	for symbol_name in available_symbols:
		if not GameConfig.symbols.has(symbol_name):
			new_symbol_name = symbol_name
			break

	if new_symbol_name == "":
		return  # All symbols already added

	# Add the new symbol
	var new_symbols = GameConfig.symbols.duplicate()
	new_symbols[new_symbol_name] = available_symbols[new_symbol_name]

	# Add the new symbol to all reels
	var new_reels = GameConfig.reels.duplicate(true)
	for reel in new_reels:
		if reel.has("symbols"):
			reel["symbols"].append(new_symbol_name)

	GameConfig.update_config({
		"symbols": new_symbols,
		"reels": new_reels
	})
