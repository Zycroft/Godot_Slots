extends Panel
class_name PayoutDisplay

# Preload ReelObject class
const ReelObjectClass = preload("res://Scripts/ReelObject.gd")

# Container for payout entries
var payout_container: HBoxContainer

# Style
var panel_style: StyleBoxFlat

const ICON_SIZE = 48
const ENTRY_SPACING = 25

func _ready():
	# Create panel background style
	panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.6, 0.5, 0.2, 1.0)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left = 15
	panel_style.content_margin_right = 15
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8

	add_theme_stylebox_override("panel", panel_style)

	# Create container for payout entries
	payout_container = HBoxContainer.new()
	payout_container.name = "PayoutContainer"
	payout_container.add_theme_constant_override("separation", ENTRY_SPACING)
	payout_container.set_anchors_preset(Control.PRESET_CENTER)
	payout_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(payout_container)

	# Build payout display from config
	_build_payout_display()

	# Connect to config changes
	GameConfig.config_changed.connect(_on_config_changed)

func _on_config_changed():
	_build_payout_display()

func _build_payout_display():
	# Clear existing entries
	for child in payout_container.get_children():
		child.queue_free()

	# Get payouts from config
	var symbol_payouts = GameConfig.symbol_payouts
	var symbols = GameConfig.symbols

	# Sort symbols by their 3-match payout value (highest first)
	var sorted_symbols = symbols.keys()
	sorted_symbols.sort_custom(func(a, b):
		var payout_a = _get_base_payout(a, symbol_payouts)
		var payout_b = _get_base_payout(b, symbol_payouts)
		return payout_a > payout_b
	)

	# Create entry for each symbol
	for symbol_name in sorted_symbols:
		var entry = _create_payout_entry(symbol_name, symbol_payouts)
		if entry:
			payout_container.add_child(entry)

func _get_base_payout(symbol: String, payouts: Dictionary) -> int:
	if payouts.has(symbol) and payouts[symbol].has("3"):
		return int(payouts[symbol]["3"])
	return 0

func _create_payout_entry(symbol_name: String, symbol_payouts: Dictionary) -> Control:
	if not symbol_payouts.has(symbol_name):
		return null

	var payouts = symbol_payouts[symbol_name]
	var reel_obj = GameConfig.get_reel_object(symbol_name)

	# Container for this entry
	var entry = HBoxContainer.new()
	entry.add_theme_constant_override("separation", 6)

	# Symbol icon
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = GameConfig.get_symbol_texture(symbol_name)
	entry.add_child(icon)

	# Payout text (show 3-match payout)
	var label = Label.new()
	label.add_theme_font_size_override("font_size", 20)

	# Determine text color based on rarity or special type
	var text_color = Color(1.0, 0.9, 0.4, 1.0)  # Default gold
	var payout_text = ""

	if reel_obj:
		text_color = reel_obj.get_rarity_color()

		# Special symbol type display
		match reel_obj.type:
			ReelObjectClass.Type.WILD:
				payout_text = "WILD"
				text_color = Color(0.9, 0.3, 0.9, 1.0)  # Purple for wild
			ReelObjectClass.Type.MULTIPLIER:
				payout_text = "x" + str(reel_obj.multiplier_value)
				text_color = Color(0.3, 0.9, 0.3, 1.0)  # Green for multiplier
			ReelObjectClass.Type.FREE_SPIN:
				payout_text = "FREE"
				text_color = Color(0.3, 0.8, 1.0, 1.0)  # Cyan for free spin
			ReelObjectClass.Type.SHOP_KEY:
				payout_text = "SHOP"
				text_color = Color(1.0, 0.6, 0.2, 1.0)  # Orange for shop
			_:
				if payouts.has("3"):
					payout_text = "x3=" + str(payouts["3"])
	else:
		# Fallback for symbols without reel_object data
		if payouts.has("3"):
			payout_text = "x3=" + str(payouts["3"])

	label.add_theme_color_override("font_color", text_color)
	label.text = payout_text

	entry.add_child(label)

	# Add separator
	var sep = VSeparator.new()
	sep.add_theme_constant_override("separation", 8)
	entry.add_child(sep)

	return entry

# Animate a win highlight for a specific symbol
func highlight_symbol(symbol_name: String, duration: float = 1.0):
	for child in payout_container.get_children():
		if child is HBoxContainer:
			var icon = child.get_child(0) as TextureRect
			if icon and icon.texture == GameConfig.get_symbol_texture(symbol_name):
				var tween = create_tween()
				tween.tween_property(child, "modulate", Color(1.5, 1.5, 0.5, 1.0), 0.1)
				tween.tween_property(child, "modulate", Color(1, 1, 1, 1), duration)
				break

# Highlight all winning symbols
func highlight_wins(wins: Array):
	for win in wins:
		highlight_symbol(win.symbol, 1.5)
