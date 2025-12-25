extends Panel
class_name CurrencyConverter

# Signals
signal closed

# UI Elements
var title_label: Label
var coins_label: VBoxContainer
var nuggets_label: VBoxContainer
var bars_label: VBoxContainer

var coins_to_nuggets_btn: Button
var nuggets_to_bars_btn: Button
var close_btn: Button

var coins_slider: HSlider
var nuggets_slider: HSlider
var coins_amount_label: Label
var nuggets_amount_label: Label

# Conversion rates (from CurrencyManager)
const COINS_PER_NUGGET = 100
const NUGGETS_PER_BAR = 10

# Style
var panel_style: StyleBoxFlat

func _ready():
	_setup_style()
	_build_ui()
	_update_display()

	# Connect to currency changes
	GameConfig.currency_changed.connect(_on_currency_changed)

func _setup_style():
	panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.06, 0.12, 0.95)
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(0.7, 0.6, 0.3, 1.0)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.content_margin_left = 20
	panel_style.content_margin_right = 20
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 20
	add_theme_stylebox_override("panel", panel_style)

func _build_ui():
	custom_minimum_size = Vector2(450, 400)

	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_vbox.add_theme_constant_override("separation", 15)
	add_child(main_vbox)

	# Title
	title_label = Label.new()
	title_label.text = "Currency Exchange"
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4, 1.0))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(title_label)

	# Separator
	main_vbox.add_child(HSeparator.new())

	# Current balances
	var balances_hbox = HBoxContainer.new()
	balances_hbox.add_theme_constant_override("separation", 30)
	balances_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_child(balances_hbox)

	coins_label = _create_currency_label("Coins", Color(1.0, 0.85, 0.3))
	nuggets_label = _create_currency_label("Nuggets", Color(1.0, 0.65, 0.2))
	bars_label = _create_currency_label("Bars", Color(1.0, 0.45, 0.1))
	balances_hbox.add_child(coins_label)
	balances_hbox.add_child(nuggets_label)
	balances_hbox.add_child(bars_label)

	# Separator
	main_vbox.add_child(HSeparator.new())

	# Coins to Nuggets conversion
	var coins_section = VBoxContainer.new()
	coins_section.add_theme_constant_override("separation", 8)
	main_vbox.add_child(coins_section)

	var coins_header = Label.new()
	coins_header.text = "Convert Coins → Nuggets (%d coins = 1 nugget)" % COINS_PER_NUGGET
	coins_header.add_theme_font_size_override("font_size", 16)
	coins_header.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	coins_section.add_child(coins_header)

	var coins_hbox = HBoxContainer.new()
	coins_hbox.add_theme_constant_override("separation", 10)
	coins_section.add_child(coins_hbox)

	coins_slider = HSlider.new()
	coins_slider.min_value = 0
	coins_slider.max_value = 1
	coins_slider.step = 1
	coins_slider.custom_minimum_size = Vector2(200, 30)
	coins_slider.value_changed.connect(_on_coins_slider_changed)
	coins_hbox.add_child(coins_slider)

	coins_amount_label = Label.new()
	coins_amount_label.text = "0 nuggets"
	coins_amount_label.add_theme_font_size_override("font_size", 16)
	coins_amount_label.custom_minimum_size = Vector2(100, 0)
	coins_hbox.add_child(coins_amount_label)

	coins_to_nuggets_btn = Button.new()
	coins_to_nuggets_btn.text = "Convert"
	coins_to_nuggets_btn.custom_minimum_size = Vector2(80, 30)
	coins_to_nuggets_btn.pressed.connect(_on_convert_coins_pressed)
	coins_hbox.add_child(coins_to_nuggets_btn)

	# Nuggets to Bars conversion
	var nuggets_section = VBoxContainer.new()
	nuggets_section.add_theme_constant_override("separation", 8)
	main_vbox.add_child(nuggets_section)

	var nuggets_header = Label.new()
	nuggets_header.text = "Convert Nuggets → Bars (%d nuggets = 1 bar)" % NUGGETS_PER_BAR
	nuggets_header.add_theme_font_size_override("font_size", 16)
	nuggets_header.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	nuggets_section.add_child(nuggets_header)

	var nuggets_hbox = HBoxContainer.new()
	nuggets_hbox.add_theme_constant_override("separation", 10)
	nuggets_section.add_child(nuggets_hbox)

	nuggets_slider = HSlider.new()
	nuggets_slider.min_value = 0
	nuggets_slider.max_value = 1
	nuggets_slider.step = 1
	nuggets_slider.custom_minimum_size = Vector2(200, 30)
	nuggets_slider.value_changed.connect(_on_nuggets_slider_changed)
	nuggets_hbox.add_child(nuggets_slider)

	nuggets_amount_label = Label.new()
	nuggets_amount_label.text = "0 bars"
	nuggets_amount_label.add_theme_font_size_override("font_size", 16)
	nuggets_amount_label.custom_minimum_size = Vector2(100, 0)
	nuggets_hbox.add_child(nuggets_amount_label)

	nuggets_to_bars_btn = Button.new()
	nuggets_to_bars_btn.text = "Convert"
	nuggets_to_bars_btn.custom_minimum_size = Vector2(80, 30)
	nuggets_to_bars_btn.pressed.connect(_on_convert_nuggets_pressed)
	nuggets_hbox.add_child(nuggets_to_bars_btn)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(spacer)

	# Close button
	close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(120, 40)
	close_btn.pressed.connect(_on_close_pressed)
	main_vbox.add_child(close_btn)

	# Center the close button
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

func _create_currency_label(label_name: String, color: Color) -> VBoxContainer:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)

	var name_label = Label.new()
	name_label.text = label_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", color)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	var amount_label = Label.new()
	amount_label.text = "0"
	amount_label.name = "Amount"
	amount_label.add_theme_font_size_override("font_size", 24)
	amount_label.add_theme_color_override("font_color", Color.WHITE)
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(amount_label)

	return vbox

func _update_display():
	# Update balance labels
	var coins = GameConfig.casino_coins
	var nuggets = GameConfig.gold_nuggets
	var bars = GameConfig.gold_bars

	coins_label.get_node("Amount").text = str(coins)
	nuggets_label.get_node("Amount").text = str(nuggets)
	bars_label.get_node("Amount").text = str(bars)

	# Update slider ranges
	var max_nuggets = GameConfig.get_max_nuggets_convertible()
	coins_slider.max_value = max(1, max_nuggets)
	coins_slider.value = min(coins_slider.value, max_nuggets)
	coins_to_nuggets_btn.disabled = max_nuggets == 0

	var max_bars = GameConfig.get_max_bars_convertible()
	nuggets_slider.max_value = max(1, max_bars)
	nuggets_slider.value = min(nuggets_slider.value, max_bars)
	nuggets_to_bars_btn.disabled = max_bars == 0

	_update_slider_labels()

func _update_slider_labels():
	var nugget_count = int(coins_slider.value)
	var coin_cost = nugget_count * COINS_PER_NUGGET
	coins_amount_label.text = "%d nugget%s\n(%d coins)" % [nugget_count, "" if nugget_count == 1 else "s", coin_cost]

	var bar_count = int(nuggets_slider.value)
	var nugget_cost = bar_count * NUGGETS_PER_BAR
	nuggets_amount_label.text = "%d bar%s\n(%d nuggets)" % [bar_count, "" if bar_count == 1 else "s", nugget_cost]

func _on_coins_slider_changed(_value: float):
	_update_slider_labels()

func _on_nuggets_slider_changed(_value: float):
	_update_slider_labels()

func _on_convert_coins_pressed():
	var count = int(coins_slider.value)
	if count > 0:
		if GameConfig.convert_coins_to_nuggets(count):
			coins_slider.value = 0
			_update_display()

func _on_convert_nuggets_pressed():
	var count = int(nuggets_slider.value)
	if count > 0:
		if GameConfig.convert_nuggets_to_bars(count):
			nuggets_slider.value = 0
			_update_display()

func _on_close_pressed():
	closed.emit()
	hide()

func _on_currency_changed(_currency_type: String, _new_amount: int):
	_update_display()

func show_dialog():
	_update_display()
	show()
