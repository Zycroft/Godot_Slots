extends Control

# Loyalty Cashier store with shop dialog

const LoyaltyCardClass = preload("res://Scripts/LoyaltyCard.gd")

var teller_sprite: Sprite2D
var shop_button: Button
var restart_button: TextureButton
var shop_dialog: Control
var shop_status_label: Label
var shop_closed_overlay: ColorRect

# Animation settings (8x7 grid sprite sheets with 56 frames each)
var teller_textures: Array[Texture2D] = []
var idle_texture: Texture2D
var current_texture_index: int = 0
const FRAME_COUNT = 50  # Skip last 6 frames which may be blank
const COLUMNS = 8
const FRAME_WIDTH = 256
const FRAME_HEIGHT = 256
var current_frame: int = 0
var animation_timer: float = 0.0
const FRAME_DURATION = 0.12

# Idle transition state
var in_idle: bool = false
var idle_frames_remaining: int = 0
const MIN_IDLE_FRAMES = 15
const MAX_IDLE_FRAMES = 40

# Store background animation (13x12 grid, 512x512 frames)
var store_anim_sprite: Sprite2D
var store_anim_texture: Texture2D
var store_anim_frame: int = 0
var store_anim_timer: float = 0.0
const STORE_FRAME_COUNT = 150  # Skip last 6 frames
const STORE_COLUMNS = 13
const STORE_FRAME_WIDTH = 512
const STORE_FRAME_HEIGHT = 512
const STORE_FRAME_DURATION = 0.1

func _ready():
	_build_shop_button()
	_build_restart_button()
	_build_shop_dialog()

	# Connect to shop signals
	GameConfig.shop_opened.connect(_on_shop_opened)
	GameConfig.shop_closed.connect(_on_shop_closed)

	# Set initial button state (shop starts closed)
	_update_shop_button_state()

func _exit_tree():
	# Disconnect signals to prevent memory leaks
	if GameConfig.shop_opened.is_connected(_on_shop_opened):
		GameConfig.shop_opened.disconnect(_on_shop_opened)
	if GameConfig.shop_closed.is_connected(_on_shop_closed):
		GameConfig.shop_closed.disconnect(_on_shop_closed)

func _process(delta):
	_animate_teller(delta)
	_animate_store_background(delta)

func _animate_store_background(delta):
	# Early exit if dialog not visible (most common case) or sprite not ready
	if not shop_dialog or not shop_dialog.visible or not store_anim_sprite:
		return

	store_anim_timer += delta
	if store_anim_timer >= STORE_FRAME_DURATION:
		store_anim_timer = 0.0
		store_anim_frame = (store_anim_frame + 1) % STORE_FRAME_COUNT
		@warning_ignore("integer_division")
		var col: int = store_anim_frame % STORE_COLUMNS
		@warning_ignore("integer_division")
		var row: int = store_anim_frame / STORE_COLUMNS
		store_anim_sprite.region_rect = Rect2(col * STORE_FRAME_WIDTH, row * STORE_FRAME_HEIGHT, STORE_FRAME_WIDTH, STORE_FRAME_HEIGHT)

func _animate_teller(delta):
	if teller_sprite == null:
		return

	animation_timer += delta
	if animation_timer >= FRAME_DURATION:
		animation_timer = 0.0
		current_frame += 1

		if in_idle:
			# Playing idle animation between main animations
			idle_frames_remaining -= 1
			if idle_frames_remaining <= 0:
				# Done with idle, start next main animation
				_start_next_animation()
			elif current_frame >= FRAME_COUNT:
				# Loop idle animation if needed
				current_frame = 0
		else:
			# Playing main animation
			if current_frame >= FRAME_COUNT:
				# Main animation done, switch to idle
				_start_idle()

		# Always update sprite region for current frame (no early returns)
		@warning_ignore("integer_division")
		var col: int = current_frame % COLUMNS
		@warning_ignore("integer_division")
		var row: int = current_frame / COLUMNS
		teller_sprite.region_rect = Rect2(col * FRAME_WIDTH, row * FRAME_HEIGHT, FRAME_WIDTH, FRAME_HEIGHT)

func _start_idle():
	in_idle = true
	current_frame = 0
	idle_frames_remaining = randi_range(MIN_IDLE_FRAMES, MAX_IDLE_FRAMES)
	# Switch to idle texture and force immediate display of frame 0
	teller_sprite.texture = idle_texture
	teller_sprite.region_rect = Rect2(0, 0, FRAME_WIDTH, FRAME_HEIGHT)
	teller_sprite.queue_redraw()

func _start_next_animation():
	in_idle = false
	current_frame = 0
	current_texture_index = randi() % teller_textures.size()
	# Switch texture and force immediate display of frame 0
	teller_sprite.texture = teller_textures[current_texture_index]
	teller_sprite.region_rect = Rect2(0, 0, FRAME_WIDTH, FRAME_HEIGHT)
	teller_sprite.queue_redraw()

func _build_shop_button():
	# Container for sprite and button
	var container = Control.new()
	container.name = "ShopContainer"
	container.position = Vector2(-20, 50)
	container.size = Vector2(128, 128)
	add_child(container)

	# Load all 3 cashier animation textures
	teller_textures.append(load("res://Assets/cashierbook_anim.png"))
	teller_textures.append(load("res://Assets/cashiersleep_anim.png"))
	teller_textures.append(load("res://Assets/cashiersmile_anim.png"))

	# Load idle animation texture
	idle_texture = load("res://Assets/cashieridle_anim.png")

	# Pick a random starting animation
	current_texture_index = randi() % teller_textures.size()

	# Setup animated teller sprite (single sprite for both animation and transition)
	teller_sprite = Sprite2D.new()
	teller_sprite.texture = teller_textures[current_texture_index]
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
	var restart_texture = load("res://Assets/but_restart.png")
	restart_button = TextureButton.new()
	restart_button.texture_normal = restart_texture
	restart_button.custom_minimum_size = Vector2(154, 154)  # 20% bigger
	restart_button.position = Vector2(-20, 190)
	restart_button.ignore_texture_size = true
	restart_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
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
	# Load store animation texture
	store_anim_texture = load("res://Assets/store_anim.png")

	# Animated store background - cover entire screen
	store_anim_sprite = Sprite2D.new()
	store_anim_sprite.name = "StoreBackground"
	store_anim_sprite.texture = store_anim_texture
	store_anim_sprite.centered = false
	store_anim_sprite.region_enabled = true
	store_anim_sprite.region_rect = Rect2(0, 0, STORE_FRAME_WIDTH, STORE_FRAME_HEIGHT)
	# Scale 512x512 to fill 1920x1080
	store_anim_sprite.scale = Vector2(1920.0 / STORE_FRAME_WIDTH, 1080.0 / STORE_FRAME_HEIGHT)
	store_anim_sprite.position = Vector2(0, 0)
	shop_dialog.add_child(store_anim_sprite)

	# Semi-transparent overlay for readability
	var dimmer = ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.position = Vector2(0, 0)
	dimmer.size = Vector2(1920, 1080)
	dimmer.color = Color(0, 0, 0, 0.4)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	shop_dialog.add_child(dimmer)

	# Dialog panel - centered on screen using absolute position
	var panel = PanelContainer.new()
	panel.name = "DialogPanel"
	panel.custom_minimum_size = Vector2(600, 480)
	panel.size = Vector2(600, 480)
	panel.position = Vector2((1920 - 600) / 2.0, (1080 - 480) / 2.0)

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
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# Title
	var title = Label.new()
	title.name = "Title"
	title.text = "LOYALTY CASHIER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2))
	vbox.add_child(title)

	# Currency display
	var currency_row = HBoxContainer.new()
	currency_row.name = "CurrencyRow"
	currency_row.alignment = BoxContainer.ALIGNMENT_CENTER
	currency_row.add_theme_constant_override("separation", 30)
	vbox.add_child(currency_row)

	var nuggets_label = Label.new()
	nuggets_label.name = "NuggetsLabel"
	nuggets_label.text = "Nuggets: 0"
	nuggets_label.add_theme_font_size_override("font_size", 16)
	nuggets_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.2))
	currency_row.add_child(nuggets_label)

	var bars_label = Label.new()
	bars_label.name = "BarsLabel"
	bars_label.text = "Bars: 0"
	bars_label.add_theme_font_size_override("font_size", 16)
	bars_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.1))
	currency_row.add_child(bars_label)

	# Separator
	var sep = HSeparator.new()
	vbox.add_child(sep)

	# Subtitle
	var subtitle = Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "Choose a card to purchase"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(subtitle)

	# Cards container (will be populated with random cards)
	var cards_container = HBoxContainer.new()
	cards_container.name = "CardsContainer"
	cards_container.add_theme_constant_override("separation", 15)
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(cards_container)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Close button in center container
	var btn_container = CenterContainer.new()
	vbox.add_child(btn_container)

	var close_btn = Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(120, 40)
	close_btn.pressed.connect(_close_shop)
	btn_container.add_child(close_btn)

	# Shop closed overlay
	shop_closed_overlay = ColorRect.new()
	shop_closed_overlay.name = "ShopClosedOverlay"
	shop_closed_overlay.position = panel.position
	shop_closed_overlay.size = panel.size
	shop_closed_overlay.color = Color(0, 0, 0, 0.7)
	shop_closed_overlay.visible = false
	shop_dialog.add_child(shop_closed_overlay)

	var closed_label = Label.new()
	closed_label.text = "SHOP CLOSED\nCome back later!"
	closed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	closed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	closed_label.add_theme_font_size_override("font_size", 32)
	closed_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	closed_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	shop_closed_overlay.add_child(closed_label)

func _open_shop():
	_update_currency_display()
	_populate_random_cards()
	_update_shop_status()
	shop_dialog.visible = true

func _close_shop():
	shop_dialog.visible = false

func _update_currency_display():
	var nuggets_label = shop_dialog.get_node_or_null("DialogPanel/Content/CurrencyRow/NuggetsLabel")
	var bars_label = shop_dialog.get_node_or_null("DialogPanel/Content/CurrencyRow/BarsLabel")

	if nuggets_label:
		nuggets_label.text = "Nuggets: %d" % GameConfig.gold_nuggets
	if bars_label:
		bars_label.text = "Bars: %d" % GameConfig.gold_bars

func _update_shop_status():
	if shop_closed_overlay:
		shop_closed_overlay.visible = not GameConfig.is_shop_open

func _on_shop_opened():
	_update_shop_status()
	_update_shop_button_state()

func _on_shop_closed():
	_update_shop_status()
	_update_shop_button_state()

func _update_shop_button_state():
	if shop_button:
		shop_button.disabled = not GameConfig.is_shop_open
		if GameConfig.is_shop_open:
			shop_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			teller_sprite.modulate = Color(1, 1, 1, 1)
		else:
			shop_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
			teller_sprite.modulate = Color(0.5, 0.5, 0.5, 1)  # Dim when closed

func _populate_random_cards():
	var cards_container = shop_dialog.get_node("DialogPanel/Content/CardsContainer")

	# Clear existing cards
	for child in cards_container.get_children():
		child.queue_free()

	# Generate new pack using shop manager
	var pack = GameConfig.shop_manager.generate_new_pack()

	# Show all cards in the pack
	for i in range(pack.size()):
		var card = pack[i]
		var card_widget = _create_card_widget(card, i)
		cards_container.add_child(card_widget)

func _create_card_widget(card: LoyaltyCardClass, card_index: int) -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 6)

	# Rarity label
	var rarity_label = Label.new()
	rarity_label.text = card.get_rarity_name()
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 12)
	rarity_label.add_theme_color_override("font_color", card.get_rarity_color())
	container.add_child(rarity_label)

	# Card panel with rarity-colored border
	var card_panel = PanelContainer.new()
	card_panel.custom_minimum_size = Vector2(160, 140)

	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.12, 0.12, 0.18, 1.0)
	card_style.border_width_left = 3
	card_style.border_width_top = 3
	card_style.border_width_right = 3
	card_style.border_width_bottom = 3
	card_style.border_color = card.get_rarity_color()
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	card_panel.add_theme_stylebox_override("panel", card_style)
	container.add_child(card_panel)

	# Card content
	var card_vbox = VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 8)
	card_panel.add_child(card_vbox)

	# Card name
	var name_label = Label.new()
	name_label.text = card.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1))
	card_vbox.add_child(name_label)

	# Card description
	var desc_label = Label.new()
	desc_label.text = card.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	card_vbox.add_child(desc_label)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_vbox.add_child(spacer)

	# Cost label
	var cost_label = Label.new()
	cost_label.text = card.get_cost_text()
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 14)
	if card.bar_cost > 0:
		cost_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.1))
	else:
		cost_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.2))
	card_vbox.add_child(cost_label)

	# Buy button
	var buy_btn = Button.new()
	buy_btn.text = "Purchase"
	buy_btn.custom_minimum_size = Vector2(160, 35)
	buy_btn.add_theme_font_size_override("font_size", 14)
	buy_btn.pressed.connect(_on_buy_card.bind(card_index))
	buy_btn.disabled = not card.can_afford() or not GameConfig.is_shop_open
	container.add_child(buy_btn)

	return container

func _on_buy_card(card_index: int):
	if GameConfig.shop_manager.purchase_card(card_index):
		_update_currency_display()
		# Generate new pack after purchase
		_populate_random_cards()
