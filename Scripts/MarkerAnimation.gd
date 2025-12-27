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
var fly_in_tween: Tween

# Labels for display (cached references)
var amount_label: Label
var due_label: Label
var day_label: Label
var progress_bar: ProgressBar

# Fly-in state tracking to prevent redundant animations
var _is_flying_in: bool = false
var _has_flown_in: bool = false

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
	amount_label = $AmountLabel
	due_label = $DueLabel

	# Create day label
	day_label = Label.new()
	day_label.name = "DayLabel"
	day_label.add_theme_font_size_override("font_size", 20)
	day_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_label.offset_left = -60
	day_label.offset_top = 130
	day_label.offset_right = 380
	day_label.offset_bottom = 160
	day_label.text = "Day 1"
	add_child(day_label)

	# Create progress bar for marker
	progress_bar = ProgressBar.new()
	progress_bar.name = "MarkerProgress"
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 0
	progress_bar.show_percentage = false
	progress_bar.offset_left = 40
	progress_bar.offset_top = 245
	progress_bar.offset_right = 280
	progress_bar.offset_bottom = 260

	# Style the progress bar
	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = Color(0.2, 0.6, 0.2, 1.0)
	bar_style.corner_radius_top_left = 4
	bar_style.corner_radius_top_right = 4
	bar_style.corner_radius_bottom_left = 4
	bar_style.corner_radius_bottom_right = 4
	progress_bar.add_theme_stylebox_override("fill", bar_style)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.3, 0.1, 0.1, 0.8)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4
	progress_bar.add_theme_stylebox_override("background", bg_style)

	progress_bar.visible = false  # Hide progress bar for now
	add_child(progress_bar)

	# Create audio players
	swoosh_sound = AudioStreamPlayer.new()
	swoosh_sound.stream = load("res://Audio/SFX/swoosh.mp3")
	add_child(swoosh_sound)

	slap_sound = AudioStreamPlayer.new()
	slap_sound.stream = load("res://Audio/SFX/slap.mp3")
	add_child(slap_sound)

	# Connect to game signals
	GameConfig.config_changed.connect(_on_config_changed)
	GameConfig.game_reset.connect(_on_game_reset)
	GameConfig.currency_changed.connect(_on_currency_changed)
	GameConfig.day_started.connect(_on_day_started)

func _exit_tree():
	# Disconnect signals to prevent memory leaks
	if GameConfig.config_changed.is_connected(_on_config_changed):
		GameConfig.config_changed.disconnect(_on_config_changed)
	if GameConfig.game_reset.is_connected(_on_game_reset):
		GameConfig.game_reset.disconnect(_on_game_reset)
	if GameConfig.currency_changed.is_connected(_on_currency_changed):
		GameConfig.currency_changed.disconnect(_on_currency_changed)
	if GameConfig.day_started.is_connected(_on_day_started):
		GameConfig.day_started.disconnect(_on_day_started)

	# Kill active tweens
	if frame_tween and frame_tween.is_valid():
		frame_tween.kill()
	if fly_in_tween and fly_in_tween.is_valid():
		fly_in_tween.kill()

func _on_config_changed():
	# Only fly in once per game session, and only when not already flying
	if GameConfig.game_started and not _has_flown_in and not _is_flying_in:
		_fly_in()
	_update_display()

func _on_game_reset():
	# Reset to off-screen position
	position = start_position
	visible = false
	_has_flown_in = false
	_is_flying_in = false

	# Kill any active tweens
	if frame_tween and frame_tween.is_valid():
		frame_tween.kill()
	if fly_in_tween and fly_in_tween.is_valid():
		fly_in_tween.kill()

func _on_currency_changed(_currency_type: String, _new_amount: int):
	_update_display()

func _on_day_started(day_number: int, _marker: int):
	if day_label:
		day_label.text = "Day %d" % day_number
	_update_display()

func _update_display():
	if not visible:
		return

	# Update marker display: show coins / marker
	if amount_label:
		var coins = GameConfig.casino_coins
		var marker = GameConfig.marker_amount
		if marker > 0:
			amount_label.text = "$%d / $%d" % [coins, marker]
		else:
			amount_label.text = "$%d" % coins

	# Update hours display
	if due_label:
		due_label.text = "%.1f hrs" % GameConfig.hours_remaining

	# Update day label
	if day_label:
		day_label.text = "Day %d" % GameConfig.current_day

	# Update progress bar
	if progress_bar:
		var progress = GameConfig.get_marker_progress() * 100.0
		progress_bar.value = progress

		# Change color based on progress
		var bar_style = progress_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if bar_style:
			if progress >= 100:
				bar_style.bg_color = Color(0.2, 0.8, 0.2, 1.0)  # Green - covered
			elif progress >= 50:
				bar_style.bg_color = Color(0.8, 0.8, 0.2, 1.0)  # Yellow - halfway
			else:
				bar_style.bg_color = Color(0.8, 0.3, 0.2, 1.0)  # Red - behind

func _fly_in():
	_is_flying_in = true
	visible = true
	position = start_position

	# Show animated sprite, hide static background during fly-in
	anim_sprite.visible = true
	anim_sprite.frame = 0
	background.visible = false

	# Play swoosh sound
	swoosh_sound.play()

	# Kill any existing tweens before creating new ones
	if frame_tween and frame_tween.is_valid():
		frame_tween.kill()
	if fly_in_tween and fly_in_tween.is_valid():
		fly_in_tween.kill()

	# Animate through sprite sheet frames during fly-in
	var fly_duration = 2.025  # 80% slower than original 1.125s
	frame_tween = create_tween()
	frame_tween.tween_method(_set_frame, 0, TOTAL_FRAMES - 1, fly_duration)

	# Create fly-in animation with easing
	fly_in_tween = create_tween()
	fly_in_tween.set_ease(Tween.EASE_OUT)
	fly_in_tween.set_trans(Tween.TRANS_BACK)
	fly_in_tween.tween_property(self, "position", end_position, fly_duration)
	fly_in_tween.tween_callback(_on_fly_in_complete)

func _set_frame(frame_num: int):
	anim_sprite.frame = frame_num

func _on_fly_in_complete():
	_is_flying_in = false
	_has_flown_in = true

	# Switch from animated sprite to static background
	anim_sprite.visible = false
	background.visible = true

	# Play slap sound when it lands
	slap_sound.play()

	# Add a small shake effect
	var original_pos = position
	var shake_tween = create_tween()
	shake_tween.tween_property(self, "position", original_pos + Vector2(-5, 5), 0.03)
	shake_tween.tween_property(self, "position", original_pos + Vector2(3, -3), 0.03)
	shake_tween.tween_property(self, "position", original_pos, 0.03)

	# Update display with initial values
	_update_display()
