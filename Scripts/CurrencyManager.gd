extends Node
class_name CurrencyManager

# Signals
signal currency_changed(currency_type: String, new_amount: int)
signal conversion_completed(from_type: String, to_type: String, amount: int)

# Currency types
enum CurrencyType {
	CASINO_COINS,
	GOLD_NUGGETS,
	GOLD_BARS
}

# Currency amounts
var casino_coins: int = 0
var gold_nuggets: int = 0
var gold_bars: int = 0

# Conversion rates (how many of source currency = 1 of target)
const COINS_PER_NUGGET: int = 100
const NUGGETS_PER_BAR: int = 10

# Get currency by type
func get_currency(type: CurrencyType) -> int:
	match type:
		CurrencyType.CASINO_COINS:
			return casino_coins
		CurrencyType.GOLD_NUGGETS:
			return gold_nuggets
		CurrencyType.GOLD_BARS:
			return gold_bars
	return 0

# Get currency name for display
static func get_currency_name(type: CurrencyType) -> String:
	match type:
		CurrencyType.CASINO_COINS:
			return "Casino Coins"
		CurrencyType.GOLD_NUGGETS:
			return "Gold Nuggets"
		CurrencyType.GOLD_BARS:
			return "Gold Bars"
	return "Unknown"

# Get currency short name
static func get_currency_short_name(type: CurrencyType) -> String:
	match type:
		CurrencyType.CASINO_COINS:
			return "Coins"
		CurrencyType.GOLD_NUGGETS:
			return "Nuggets"
		CurrencyType.GOLD_BARS:
			return "Bars"
	return "?"

# Add currency
func add_currency(type: CurrencyType, amount: int) -> void:
	if amount <= 0:
		return

	match type:
		CurrencyType.CASINO_COINS:
			casino_coins += amount
			currency_changed.emit("casino_coins", casino_coins)
		CurrencyType.GOLD_NUGGETS:
			gold_nuggets += amount
			currency_changed.emit("gold_nuggets", gold_nuggets)
		CurrencyType.GOLD_BARS:
			gold_bars += amount
			currency_changed.emit("gold_bars", gold_bars)

# Spend currency (returns true if successful)
func spend_currency(type: CurrencyType, amount: int) -> bool:
	if amount <= 0:
		return false

	match type:
		CurrencyType.CASINO_COINS:
			if casino_coins >= amount:
				casino_coins -= amount
				currency_changed.emit("casino_coins", casino_coins)
				return true
		CurrencyType.GOLD_NUGGETS:
			if gold_nuggets >= amount:
				gold_nuggets -= amount
				currency_changed.emit("gold_nuggets", gold_nuggets)
				return true
		CurrencyType.GOLD_BARS:
			if gold_bars >= amount:
				gold_bars -= amount
				currency_changed.emit("gold_bars", gold_bars)
				return true
	return false

# Check if conversion is possible
func can_convert_coins_to_nuggets(nugget_count: int = 1) -> bool:
	return casino_coins >= (nugget_count * COINS_PER_NUGGET)

func can_convert_nuggets_to_bars(bar_count: int = 1) -> bool:
	return gold_nuggets >= (bar_count * NUGGETS_PER_BAR)

# Get max convertible amounts
func get_max_nuggets_from_coins() -> int:
	return casino_coins / COINS_PER_NUGGET

func get_max_bars_from_nuggets() -> int:
	return gold_nuggets / NUGGETS_PER_BAR

# Perform conversions (one-way, irreversible)
func convert_coins_to_nuggets(nugget_count: int = 1) -> bool:
	var coins_needed = nugget_count * COINS_PER_NUGGET
	if casino_coins < coins_needed:
		return false

	casino_coins -= coins_needed
	gold_nuggets += nugget_count

	currency_changed.emit("casino_coins", casino_coins)
	currency_changed.emit("gold_nuggets", gold_nuggets)
	conversion_completed.emit("casino_coins", "gold_nuggets", nugget_count)
	return true

func convert_nuggets_to_bars(bar_count: int = 1) -> bool:
	var nuggets_needed = bar_count * NUGGETS_PER_BAR
	if gold_nuggets < nuggets_needed:
		return false

	gold_nuggets -= nuggets_needed
	gold_bars += bar_count

	currency_changed.emit("gold_nuggets", gold_nuggets)
	currency_changed.emit("gold_bars", gold_bars)
	conversion_completed.emit("gold_nuggets", "gold_bars", bar_count)
	return true

# Reset casino coins only (end of day)
func reset_casino_coins() -> void:
	casino_coins = 0
	currency_changed.emit("casino_coins", casino_coins)

# Full reset (new game)
func reset_all() -> void:
	casino_coins = 0
	gold_nuggets = 0
	gold_bars = 0
	currency_changed.emit("casino_coins", casino_coins)
	currency_changed.emit("gold_nuggets", gold_nuggets)
	currency_changed.emit("gold_bars", gold_bars)

# Save/Load support
func to_dict() -> Dictionary:
	return {
		"casino_coins": casino_coins,
		"gold_nuggets": gold_nuggets,
		"gold_bars": gold_bars
	}

func from_dict(data: Dictionary) -> void:
	if data.has("casino_coins"):
		casino_coins = int(data["casino_coins"])
	if data.has("gold_nuggets"):
		gold_nuggets = int(data["gold_nuggets"])
	if data.has("gold_bars"):
		gold_bars = int(data["gold_bars"])

	currency_changed.emit("casino_coins", casino_coins)
	currency_changed.emit("gold_nuggets", gold_nuggets)
	currency_changed.emit("gold_bars", gold_bars)
