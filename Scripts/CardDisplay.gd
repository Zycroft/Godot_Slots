extends Control

# Displays owned loyalty cards on the left side of the screen

var card_container: VBoxContainer

# Card colors for visual distinction
const CARD_COLORS = {
	"reel": Color(0.2, 0.6, 0.9),      # Blue
	"payline": Color(0.2, 0.8, 0.3),   # Green
	"symbol": Color(0.9, 0.6, 0.2)     # Orange
}

func _ready():
	_build_display()
	GameConfig.card_purchased.connect(_on_card_purchased)
	GameConfig.game_reset.connect(_on_game_reset)

func _on_game_reset():
	_refresh_cards()

func _build_display():
	# Create container for cards
	card_container = VBoxContainer.new()
	card_container.name = "CardContainer"
	card_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_container.add_theme_constant_override("separation", 5)
	add_child(card_container)

	# Title
	var title = Label.new()
	title.text = "MY CARDS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	card_container.add_child(title)

	# Separator
	var sep = HSeparator.new()
	card_container.add_child(sep)

	# Display any existing cards
	_refresh_cards()

func _on_card_purchased(card_id: String):
	_add_card_visual(card_id)

func _refresh_cards():
	# Clear existing card visuals (keep title and separator)
	while card_container.get_child_count() > 2:
		var child = card_container.get_child(2)
		card_container.remove_child(child)
		child.queue_free()

	# Add visuals for all owned cards
	for card_id in GameConfig.owned_cards:
		_add_card_visual(card_id)

func _add_card_visual(card_id: String):
	if not GameConfig.CARD_DEFINITIONS.has(card_id):
		return

	var card = GameConfig.CARD_DEFINITIONS[card_id]

	# Create a colored panel for the card
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(120, 50)

	# Style the panel
	var style = StyleBoxFlat.new()
	style.bg_color = CARD_COLORS.get(card_id, Color(0.5, 0.5, 0.5))
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0, 0, 0)
	panel.add_theme_stylebox_override("panel", style)

	# Card label
	var label = Label.new()
	label.text = card["description"]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	panel.add_child(label)

	card_container.add_child(panel)
