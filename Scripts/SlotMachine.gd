extends Node2D

# Signals
signal spin_complete(wins: Array, total_payout: int)

# Reel container reference
@onready var reel_container: HBoxContainer = $ReelContainer
@onready var reel_background: TextureRect = $ReelBackground
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

# Free spin state
var free_spins_remaining: int = 0

# Preloaded scripts
var grid_overlay_script = preload("res://Scripts/GridOverlay.gd")
var coin_script = preload("res://Scripts/CoinAnimation.gd")
var payout_display_script = preload("res://Scripts/PayoutDisplay.gd")
var currency_converter_script = preload("res://Scripts/CurrencyConverter.gd")
var day_end_screen_script = preload("res://Scripts/DayEndScreen.gd")

# Payout display reference
var payout_display: Panel

# Currency converter
var currency_converter: Panel
var currency_button: Button
var currency_hud: Control
var coins_value_label: Label
var nuggets_value_label: Label
var bars_value_label: Label

# Day end screen
var day_end_screen: Control

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

	# Reel background now uses TextureRect with reelbackground.png

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

	# Create payout display above reels
	_create_payout_display()

	# Create currency HUD and converter
	_create_currency_ui()

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
	var padding_h = 20.0  # Horizontal padding
	var padding_v = 20.0  # Vertical padding
	reel_background.offset_left = -(total_width / 2) - padding_h
	reel_background.offset_right = (total_width / 2) + padding_h
	reel_background.offset_top = -(reel_height / 2) - padding_v
	reel_background.offset_bottom = (reel_height / 2) + padding_v

	# Update lever position (just right of reel background)
	lever.offset_left = (total_width / 2) + padding_h - 15
	lever.offset_right = lever.offset_left + 60

	# Update payout display position
	if payout_display and is_instance_valid(payout_display):
		payout_display.offset_left = reel_background.offset_left
		payout_display.offset_right = reel_background.offset_right
		payout_display.offset_top = reel_background.offset_top - 90
		payout_display.offset_bottom = reel_background.offset_top - 5

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

func _create_payout_display():
	# Remove existing payout display if any
	if payout_display and is_instance_valid(payout_display):
		payout_display.queue_free()

	# Create new payout display
	payout_display = Panel.new()
	payout_display.set_script(payout_display_script)
	payout_display.name = "PayoutDisplay"

	# Position just above the reel background
	var bg_top = reel_background.offset_top
	payout_display.offset_left = reel_background.offset_left
	payout_display.offset_right = reel_background.offset_right
	payout_display.offset_top = bg_top - 90
	payout_display.offset_bottom = bg_top - 5

	add_child(payout_display)

func _create_currency_ui():
	# Get the HUD layer
	var hud = get_node_or_null("../HUD")
	if not hud:
		return

	# Create currency HUD panel on the right side
	currency_hud = Panel.new()
	currency_hud.name = "CurrencyHUD"
	currency_hud.offset_left = 1720
	currency_hud.offset_top = 480
	currency_hud.offset_right = 1900
	currency_hud.offset_bottom = 700

	var hud_style = StyleBoxFlat.new()
	hud_style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	hud_style.border_width_left = 2
	hud_style.border_width_top = 2
	hud_style.border_width_right = 2
	hud_style.border_width_bottom = 2
	hud_style.border_color = Color(0.6, 0.5, 0.2, 1.0)
	hud_style.corner_radius_top_left = 8
	hud_style.corner_radius_top_right = 8
	hud_style.corner_radius_bottom_left = 8
	hud_style.corner_radius_bottom_right = 8
	currency_hud.add_theme_stylebox_override("panel", hud_style)
	hud.add_child(currency_hud)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)
	vbox.offset_left = 10
	vbox.offset_right = -10
	vbox.offset_top = 10
	vbox.offset_bottom = -10
	currency_hud.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "Currency"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Coins row
	var coins_row_data = _create_currency_row("Coins:", Color(1.0, 0.85, 0.3))
	vbox.add_child(coins_row_data.row)
	coins_value_label = coins_row_data.value

	# Nuggets row
	var nuggets_row_data = _create_currency_row("Nuggets:", Color(1.0, 0.65, 0.2))
	vbox.add_child(nuggets_row_data.row)
	nuggets_value_label = nuggets_row_data.value

	# Bars row
	var bars_row_data = _create_currency_row("Bars:", Color(1.0, 0.45, 0.1))
	vbox.add_child(bars_row_data.row)
	bars_value_label = bars_row_data.value

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Exchange button
	currency_button = Button.new()
	currency_button.text = "Exchange"
	currency_button.custom_minimum_size = Vector2(0, 35)
	currency_button.pressed.connect(_on_currency_button_pressed)
	vbox.add_child(currency_button)

	# Create currency converter dialog (hidden by default)
	currency_converter = Panel.new()
	currency_converter.set_script(currency_converter_script)
	currency_converter.name = "CurrencyConverter"
	currency_converter.visible = false
	currency_converter.set_anchors_preset(Control.PRESET_CENTER)
	currency_converter.offset_left = -225
	currency_converter.offset_right = 225
	currency_converter.offset_top = -200
	currency_converter.offset_bottom = 200
	currency_converter.closed.connect(_on_currency_converter_closed)
	hud.add_child(currency_converter)

	# Connect to currency changes
	GameConfig.currency_changed.connect(_on_currency_value_changed)

	# Create day end screen (fullscreen overlay)
	day_end_screen = Control.new()
	day_end_screen.set_script(day_end_screen_script)
	day_end_screen.name = "DayEndScreen"
	day_end_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	day_end_screen.z_index = 20  # Above everything
	hud.add_child(day_end_screen)

	# Initial update
	_update_currency_hud()

func _create_currency_row(label_text: String, color: Color) -> Dictionary:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)

	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	label.custom_minimum_size = Vector2(70, 0)
	row.add_child(label)

	var value = Label.new()
	value.text = "0"
	value.add_theme_font_size_override("font_size", 16)
	value.add_theme_color_override("font_color", Color.WHITE)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value)

	return {"row": row, "value": value}

func _update_currency_hud():
	if not currency_hud or not is_instance_valid(currency_hud):
		return

	if coins_value_label and is_instance_valid(coins_value_label):
		coins_value_label.text = str(GameConfig.casino_coins)
	if nuggets_value_label and is_instance_valid(nuggets_value_label):
		nuggets_value_label.text = str(GameConfig.gold_nuggets)
	if bars_value_label and is_instance_valid(bars_value_label):
		bars_value_label.text = str(GameConfig.gold_bars)

func _on_currency_button_pressed():
	if currency_converter and is_instance_valid(currency_converter):
		currency_converter.show_dialog()

func _on_currency_converter_closed():
	pass  # Dialog handles its own visibility

func _on_currency_value_changed(_currency_type: String, _new_amount: int):
	_update_currency_hud()

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

# Get the currently visible symbols on all reels
# Returns 2D array: [reel_index][row_index] = symbol_name
func _get_visible_symbols() -> Array:
	var visible_symbols: Array = []
	var visible_rows = GameConfig.visible_rows

	for reel_idx in range(reel_panels.size()):
		var reel_symbols: Array = []
		var reel_config = GameConfig.get_reel_symbols(reel_idx)
		var reelslots = GameConfig.reelslots

		# Calculate which symbol is at the top of the visible area
		var top_symbol_index = final_symbols[reel_idx]

		# Get symbols for each visible row
		for row in range(visible_rows):
			var symbol_index = (top_symbol_index + row) % reelslots
			if symbol_index < reel_config.size():
				reel_symbols.append(reel_config[symbol_index])
			else:
				reel_symbols.append("")

		visible_symbols.append(reel_symbols)

	return visible_symbols

func _on_spin_pressed():
	if not GameConfig.game_started:
		return

	# Check if we can spin (free spin or have enough credits/time)
	var using_free_spin = free_spins_remaining > 0
	if not using_free_spin:
		if is_spinning or GameConfig.casino_coins < GameConfig.spin_cost or GameConfig.hours_remaining < GameConfig.hours_per_spin:
			return
		GameConfig.spend_casino_coins(GameConfig.spin_cost)
		# Use time and check if day ends
		var can_continue = GameConfig.use_time(GameConfig.hours_per_spin)
		if not can_continue:
			# Day ended - the DayEndScreen will show via signal
			_update_credits_display()
			_update_hud()
			_update_currency_hud()
			return
	else:
		if is_spinning:
			return
		free_spins_remaining -= 1
		print("Free spin used! %d remaining" % free_spins_remaining)

	_update_credits_display()
	_update_hud()
	_update_currency_hud()

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

	# Get visible symbols and check for wins
	var visible_symbols = _get_visible_symbols()
	var wins = WinChecker.check_wins(visible_symbols, GameConfig.paylines, GameConfig.symbol_payouts)
	var total_payout = WinChecker.calculate_total_payout(wins)

	# Check for free spin symbols
	var free_spin_count = WinChecker.check_free_spins(visible_symbols)
	if free_spin_count > 0:
		free_spins_remaining += free_spin_count
		print("Free spins awarded: %d (total: %d)" % [free_spin_count, free_spins_remaining])

	# Award winnings
	if total_payout > 0:
		GameConfig.add_casino_coins(total_payout)
		_update_credits_display()
		_update_hud()
		_update_currency_hud()

		# Play win effects
		_play_flame_effect()
		sfx_slot_win.play()

		# Spawn coins based on payout (1 coin per 10 credits, min 3, max 20)
		var coin_count = clampi(total_payout / 10, 3, 20)
		_spawn_coins(coin_count)

		# Debug: Print wins
		for win in wins:
			print(win)

	# Emit signal with win data
	spin_complete.emit(wins, total_payout)

func _spawn_coins(count: int = -1):
	var num_coins = count if count > 0 else coins_to_spawn
	for i in range(num_coins):
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
	# Position flame above the reels (at top of reel background)
	flame_effect.position.y = reel_background.offset_top - 120

	# Scale flame to match reel background width (flame frame is 512px wide)
	var bg_width = reel_background.offset_right - reel_background.offset_left
	var flame_scale = bg_width / 512.0
	flame_effect.scale = Vector2(flame_scale, flame_scale)

	flame_effect.frame = 0
	flame_effect.visible = true
	flame_effect.modulate.a = 1.0

	# Play fire crackle sound
	sfx_fire_crackle.play()

	# Animate through 56 frames (8 columns x 7 rows)
	var tween = create_tween()
	for i in range(56):
		tween.tween_property(flame_effect, "frame", i, 0.06)

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
	if GameConfig.casino_coins < GameConfig.spin_cost or GameConfig.hours_remaining < GameConfig.hours_per_spin:
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
