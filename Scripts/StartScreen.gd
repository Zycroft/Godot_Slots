extends Control

# Start screen with difficulty selection

signal game_started

var panel: PanelContainer
var button_group: ButtonGroup
var selected_difficulty: String = "normal"

func _ready():
	_build_start_screen()
	GameConfig.game_reset.connect(_on_game_reset)

func _on_game_reset():
	visible = true

func _build_start_screen():
	# Full screen background
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.1, 0.1, 0.15, 1)
	add_child(bg)

	# Center container for the panel
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	# Main panel
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(550, 400)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 1)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.8, 0.6, 0.2)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	# Content
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "LUCKY SLOTS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	vbox.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Select Difficulty"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(subtitle)

	# Separator
	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Create button group for radio behavior
	button_group = ButtonGroup.new()

	# Difficulty radio buttons container
	var buttons_container = VBoxContainer.new()
	buttons_container.add_theme_constant_override("separation", 12)
	vbox.add_child(buttons_container)

	# Create radio buttons for each difficulty
	var is_first = true
	for diff_id in GameConfig.DIFFICULTIES:
		var diff = GameConfig.DIFFICULTIES[diff_id]
		var radio_row = _create_radio_button(diff_id, diff, is_first)
		buttons_container.add_child(radio_row)
		is_first = false

	# Separator before start button
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)

	# Start Game button
	var btn_container = CenterContainer.new()
	vbox.add_child(btn_container)

	var start_btn = Button.new()
	start_btn.text = "START GAME"
	start_btn.custom_minimum_size = Vector2(200, 60)
	start_btn.add_theme_font_size_override("font_size", 24)
	start_btn.pressed.connect(_on_start_pressed)
	btn_container.add_child(start_btn)

func _create_radio_button(diff_id: String, diff: Dictionary, is_default: bool) -> Control:
	var container = HBoxContainer.new()
	container.add_theme_constant_override("separation", 5)

	# Radio button (CheckBox with button group acts as radio)
	var radio = CheckBox.new()
	radio.text = diff["name"]
	radio.button_group = button_group
	radio.button_pressed = is_default
	radio.add_theme_font_size_override("font_size", 20)
	radio.toggled.connect(_on_difficulty_toggled.bind(diff_id))
	container.add_child(radio)

	# Info label
	var info = Label.new()
	var card_mult = diff["card_cost_multiplier"]
	var card_text = ""
	if card_mult < 1.0:
		card_text = "Card costs: 50%"
	elif card_mult > 1.0:
		card_text = "Card costs: 200%"
	else:
		card_text = "Card costs: Normal"

	info.text = "$%d  |  %d hours  |  %s" % [diff["credits"], int(diff["hours"]), card_text]
	info.add_theme_font_size_override("font_size", 16)
	info.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(info)

	if is_default:
		selected_difficulty = diff_id

	return container

func _on_difficulty_toggled(toggled: bool, diff_id: String):
	if toggled:
		selected_difficulty = diff_id

func _on_start_pressed():
	GameConfig.start_game(selected_difficulty)
	game_started.emit()
	visible = false
