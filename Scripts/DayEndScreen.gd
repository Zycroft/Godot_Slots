extends Control
class_name DayEndScreen

# Signals
signal continue_pressed

# UI Elements
var panel: Panel
var title_label: Label
var result_label: Label
var stats_label: Label
var continue_button: Button

# Animation
var fade_tween: Tween

func _ready():
	# Start hidden
	visible = false
	modulate.a = 0

	_build_ui()

	# Connect to day ended signal
	GameConfig.day_ended.connect(_on_day_ended)

func _build_ui():
	# Full screen dimmer
	var dimmer = ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.7)
	add_child(dimmer)

	# Center panel
	panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -300
	panel.offset_right = 300
	panel.offset_top = -200
	panel.offset_bottom = 200

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.08, 0.15, 0.95)
	panel_style.border_width_left = 4
	panel_style.border_width_top = 4
	panel_style.border_width_right = 4
	panel_style.border_width_bottom = 4
	panel_style.border_color = Color(0.7, 0.6, 0.3, 1.0)
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.corner_radius_bottom_left = 16
	panel_style.corner_radius_bottom_right = 16
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 30
	vbox.offset_right = -30
	vbox.offset_top = 30
	vbox.offset_bottom = -30
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	# Title
	title_label = Label.new()
	title_label.text = "Day Complete!"
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	# Result (success or fail)
	result_label = Label.new()
	result_label.text = "MARKER COVERED!"
	result_label.add_theme_font_size_override("font_size", 28)
	result_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(result_label)

	# Separator
	vbox.add_child(HSeparator.new())

	# Stats
	stats_label = Label.new()
	stats_label.text = "Coins Earned: $0\nMarker: $0\nGold Nuggets: 0\nGold Bars: 0"
	stats_label.add_theme_font_size_override("font_size", 20)
	stats_label.add_theme_color_override("font_color", Color.WHITE)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(stats_label)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Continue button
	continue_button = Button.new()
	continue_button.text = "Continue to Next Day"
	continue_button.custom_minimum_size = Vector2(200, 50)
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continue_button.pressed.connect(_on_continue_pressed)
	vbox.add_child(continue_button)

func _on_day_ended(day_number: int, success: bool, coins_earned: int):
	# Update display
	title_label.text = "Day %d Complete!" % day_number

	if success:
		result_label.text = "MARKER COVERED!"
		result_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.3))
		continue_button.text = "Continue to Day %d" % (day_number + 1)
	else:
		result_label.text = "MARKER NOT COVERED"
		result_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
		continue_button.text = "Try Again (Day %d)" % (day_number + 1)

	var marker = GameConfig.marker_amount
	var nuggets = GameConfig.gold_nuggets
	var bars = GameConfig.gold_bars

	stats_label.text = "Coins Earned: $%d\nMarker Required: $%d\n\nGold Nuggets: %d\nGold Bars: %d" % [
		coins_earned, marker, nuggets, bars
	]

	# Show the screen with fade in
	_show_screen()

func _show_screen():
	visible = true
	modulate.a = 0

	if fade_tween:
		fade_tween.kill()

	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _hide_screen():
	if fade_tween:
		fade_tween.kill()

	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.3)
	fade_tween.tween_callback(func(): visible = false)

func _on_continue_pressed():
	_hide_screen()

	# Start next day
	GameConfig.start_next_day()

	continue_pressed.emit()
