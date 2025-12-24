extends Control

# Loyalty Cashier store with shop dialog

var teller_sprite: Sprite2D
var shop_button: Button
var restart_button: Button
var shop_dialog: Control

# Animation settings (13x12 grid sprite sheet with 156 frames)
var teller_texture: Texture2D
const FRAME_COUNT = 156
const COLUMNS = 13
const FRAME_WIDTH = 256
const FRAME_HEIGHT = 256
var current_frame: int = 0
var animation_timer: float = 0.0
const FRAME_DURATION = 0.12

func _ready():
	_build_shop_button()
	_build_restart_button()
	_build_shop_dialog()

func _process(delta):
	_animate_teller(delta)

func _animate_teller(delta):
	if teller_sprite == null:
		return
	animation_timer += delta
	if animation_timer >= FRAME_DURATION:
		animation_timer = 0.0
		current_frame = (current_frame + 1) % FRAME_COUNT
		@warning_ignore("integer_division")
		var col: int = current_frame % COLUMNS
		@warning_ignore("integer_division")
		var row: int = current_frame / COLUMNS
		teller_sprite.region_rect = Rect2(col * FRAME_WIDTH, row * FRAME_HEIGHT, FRAME_WIDTH, FRAME_HEIGHT)

func _build_shop_button():
	# Container for sprite and button
	var container = Control.new()
	container.name = "ShopContainer"
	container.position = Vector2(-20, 50)
	container.size = Vector2(128, 128)
	add_child(container)

	# Load and setup animated teller sprite
	teller_texture = load("res://Assets/sprite_sheet_256_5px.png")
	teller_sprite = Sprite2D.new()
	teller_sprite.texture = teller_texture
	teller_sprite.centered = false
	teller_sprite.region_enabled = true
	teller_sprite.region_rect = Rect2(0, 0, FRAME_WIDTH, FRAME_HEIGHT)
	teller_sprite.scale = Vector2(0.5, 0.5)  # Scale 256x256 to 128x128
	teller_sprite.position = Vector2(0, 0)
	container.add_child(teller_sprite)

	# Invisible button overlay
	shop_button = Button.new()
	shop_button.flat = true
	shop_button.custom_minimum_size = Vector2(128, 128)
	shop_button.size = Vector2(128, 128)
	shop_button.position = Vector2(0, 0)
	shop_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	shop_button.pressed.connect(_open_shop)
	var transparent_style = StyleBoxEmpty.new()
	shop_button.add_theme_stylebox_override("normal", transparent_style)
	shop_button.add_theme_stylebox_override("hover", transparent_style)
	shop_button.add_theme_stylebox_override("pressed", transparent_style)
	shop_button.add_theme_stylebox_override("focus", transparent_style)
	container.add_child(shop_button)

func _build_restart_button():
	restart_button = Button.new()
	restart_button.text = "Restart\nGame"
	restart_button.custom_minimum_size = Vector2(128, 60)
	restart_button.position = Vector2(-20, 190)
	restart_button.add_theme_font_size_override("font_size", 16)
	restart_button.pressed.connect(_on_restart_pressed)
	add_child(restart_button)

func _on_restart_pressed():
	GameConfig.reset_game()

func _build_shop_dialog():
	# Create the shop dialog (hidden by default)
	shop_dialog = Control.new()
	shop_dialog.name = "ShopDialog"
	shop_dialog.position = Vector2(0, 0)
	shop_dialog.size = Vector2(1920, 1080)
	shop_dialog.visible = false

	# We need to add it to the HUD so it layers properly
	call_deferred("_add_dialog_to_root")

func _add_dialog_to_root():
	# Add to HUD CanvasLayer for proper layering
	var hud = get_parent()
	if hud:
		hud.add_child(shop_dialog)
		_setup_dialog_content()

func _setup_dialog_content():
	# Dimmer background - cover entire screen
	var dimmer = ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.position = Vector2(0, 0)
	dimmer.size = Vector2(1920, 1080)
	dimmer.color = Color(0, 0, 0, 0.6)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	shop_dialog.add_child(dimmer)

	# Dialog panel - centered on screen using absolute position
	var panel = PanelContainer.new()
	panel.name = "DialogPanel"
	panel.custom_minimum_size = Vector2(500, 400)
	panel.size = Vector2(500, 400)
	panel.position = Vector2((1920 - 500) / 2.0, (1080 - 400) / 2.0)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 1)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.8, 0.6, 0.2)
	panel.add_theme_stylebox_override("panel", style)
	shop_dialog.add_child(panel)

	# Content container
	var vbox = VBoxContainer.new()
	vbox.name = "Content"
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.name = "Title"
	title.text = "LOYALTY CASHIER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	vbox.add_child(title)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Today's Special Offers"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(subtitle)

	# Separator
	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Cards container (will be populated with random cards)
	var cards_container = HBoxContainer.new()
	cards_container.name = "CardsContainer"
	cards_container.add_theme_constant_override("separation", 20)
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(cards_container)

	# Close button in center container
	var btn_container = CenterContainer.new()
	vbox.add_child(btn_container)

	var close_btn = Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(120, 40)
	close_btn.pressed.connect(_close_shop)
	btn_container.add_child(close_btn)

func _open_shop():
	_populate_random_cards()
	shop_dialog.visible = true

func _close_shop():
	shop_dialog.visible = false

func _populate_random_cards():
	var cards_container = shop_dialog.get_node("DialogPanel/Content/CardsContainer")

	# Clear existing cards
	for child in cards_container.get_children():
		child.queue_free()

	# Get all card types and shuffle them
	var card_ids = GameConfig.CARD_DEFINITIONS.keys()
	card_ids.shuffle()

	# Show 3 random cards (or all if less than 3)
	var num_cards = mini(3, card_ids.size())
	for i in range(num_cards):
		var card_id = card_ids[i]
		var card_widget = _create_card_widget(card_id)
		cards_container.add_child(card_widget)

func _create_card_widget(card_id: String) -> Control:
	var card = GameConfig.CARD_DEFINITIONS[card_id]

	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 8)

	# Card panel with color
	var card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(130, 100)

	var card_colors = {
		"reel": Color(0.2, 0.5, 0.8),
		"payline": Color(0.2, 0.7, 0.3),
		"symbol": Color(0.8, 0.5, 0.2)
	}

	var card_style = StyleBoxFlat.new()
	card_style.bg_color = card_colors.get(card_id, Color(0.4, 0.4, 0.4))
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	card_panel.add_theme_stylebox_override("panel", card_style)
	container.add_child(card_panel)

	# Card content
	var card_vbox = VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 5)
	card_panel.add_child(card_vbox)

	# Card name
	var name_label = Label.new()
	name_label.text = card["name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	card_vbox.add_child(name_label)

	# Card description
	var desc_label = Label.new()
	desc_label.text = card["description"]
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 18)
	desc_label.add_theme_color_override("font_color", Color(1, 1, 1))
	card_vbox.add_child(desc_label)

	# Buy button
	var buy_btn = Button.new()
	buy_btn.text = "$" + str(GameConfig.get_card_cost(card_id))
	buy_btn.custom_minimum_size = Vector2(130, 35)
	buy_btn.add_theme_font_size_override("font_size", 16)
	buy_btn.pressed.connect(_on_buy_card.bind(card_id, container))
	buy_btn.disabled = not GameConfig.can_afford_card(card_id)
	container.add_child(buy_btn)

	return container

func _on_buy_card(card_id: String, _widget: Control):
	if GameConfig.buy_card(card_id):
		# Refresh the dialog to update button states
		_populate_random_cards()
