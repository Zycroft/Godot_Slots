extends Control

# Loyalty Cashier button that opens the shop dialog

var cashier_button: Button
var restart_button: Button
var shop_dialog: Control

func _ready():
	_build_cashier_button()
	_build_restart_button()
	_build_shop_dialog()

func _build_cashier_button():
	cashier_button = Button.new()
	cashier_button.text = "Loyalty\nCashier"
	cashier_button.custom_minimum_size = Vector2(140, 80)
	cashier_button.add_theme_font_size_override("font_size", 18)
	cashier_button.pressed.connect(_open_shop)
	add_child(cashier_button)

func _build_restart_button():
	restart_button = Button.new()
	restart_button.text = "Restart\nGame"
	restart_button.custom_minimum_size = Vector2(140, 60)
	restart_button.position = Vector2(0, 100)
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
	panel.position = Vector2((1920 - 500) / 2, (1080 - 400) / 2)

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
