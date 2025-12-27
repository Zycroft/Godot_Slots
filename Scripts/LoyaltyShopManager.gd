extends Node
class_name LoyaltyShopManager

const LoyaltyCardClass = preload("res://Scripts/LoyaltyCard.gd")

# Signals
signal shop_opened
signal shop_closed
signal card_activated(card)
signal card_expired(card)

# Shop availability
var shop_open: bool = false
var shop_open_hour: float = 0.0
var shop_close_hour: float = 0.0

# Active cards
var active_cards: Array = []

# Current pack (3 cards to choose from)
var current_pack: Array = []

# Bonus tracking from cards
var bonus_reels: int = 0
var bonus_paylines: int = 0
var bonus_hours: float = 0.0
var marker_reduction: float = 0.0
var marker_reduction_percent: float = 0.0
var payout_multiplier: float = 1.0

func _init():
	pass

# Called when a new day starts - generates shop availability window
func on_day_started(day_hours: float) -> void:
	# Shop hours are based on hours_remaining (counts down from day_hours to 0)
	# shop_open_hour = hours_remaining when shop OPENS (higher value)
	# shop_close_hour = hours_remaining when shop CLOSES (lower value)

	# Shop opens when 25-50% of time remains (50-75% through the day)
	var min_open = day_hours * 0.25
	var max_open = day_hours * 0.50
	shop_open_hour = randf_range(min_open, max_open)

	# Shop stays open for 1-3 hours
	var shop_duration = randf_range(1.0, 3.0)
	shop_close_hour = shop_open_hour - shop_duration

	# Ensure close hour doesn't go below minimum and window stays valid
	var min_close_hour = 0.5
	if shop_close_hour < min_close_hour:
		shop_close_hour = min_close_hour

	# Ensure shop_open_hour > shop_close_hour (valid window)
	# If clamping made the window invalid, adjust shop_open_hour
	if shop_open_hour <= shop_close_hour:
		shop_open_hour = shop_close_hour + minf(shop_duration, 1.0)

	shop_open = false

	# Tick all active cards for the new day
	_tick_active_cards()

	# Recalculate bonuses
	_recalculate_bonuses()

# Check if shop should be open based on remaining hours
func check_shop_availability(hours_remaining: float) -> bool:
	var was_open = shop_open

	# Shop is open when hours_remaining is between close_hour and open_hour
	shop_open = hours_remaining <= shop_open_hour and hours_remaining >= shop_close_hour

	if shop_open and not was_open:
		shop_opened.emit()
	elif not shop_open and was_open:
		shop_closed.emit()

	return shop_open

# Generate a new pack of cards
func generate_new_pack() -> Array:
	current_pack = LoyaltyCardClass.generate_pack(3)
	return current_pack

# Purchase a card from the current pack
func purchase_card(card_index: int) -> bool:
	if card_index < 0 or card_index >= current_pack.size():
		return false

	var card = current_pack[card_index]

	# Check if player can afford the card
	if not card.can_afford():
		return false

	# Deduct cost
	if card.bar_cost > 0:
		if not GameConfig.currency_manager.spend_currency(
			GameConfig.currency_manager.CurrencyType.GOLD_BARS, card.bar_cost):
			return false
	else:
		if not GameConfig.currency_manager.spend_currency(
			GameConfig.currency_manager.CurrencyType.GOLD_NUGGETS, card.nugget_cost):
			return false

	# Activate the card
	card.activated_on_day = GameConfig.current_day
	active_cards.append(card)

	# Apply immediate effects
	_apply_card_effect(card)

	# Recalculate all bonuses
	_recalculate_bonuses()

	card_activated.emit(card)

	# Clear the pack after purchase
	current_pack.clear()

	return true

# Apply a card's effect
func _apply_card_effect(card) -> void:
	match card.effect_type:
		LoyaltyCardClass.EffectType.ADD_HOURS:
			# Immediate effect - add hours to current day
			if card.rarity != LoyaltyCardClass.Rarity.EPIC:
				GameConfig.hours_remaining += card.effect_value
				if GameConfig.day_manager:
					GameConfig.day_manager.hours_remaining += card.effect_value

# Tick all active cards (called at day start)
func _tick_active_cards() -> void:
	# Collect indices of expired cards (iterate backwards for safe removal)
	var i = active_cards.size() - 1
	while i >= 0:
		var card = active_cards[i]
		if not card.tick_day():
			# Remove by index (O(1) for last element, O(n) for others but avoids search)
			active_cards.remove_at(i)
			card_expired.emit(card)
		i -= 1

# Recalculate all bonuses from active cards
func _recalculate_bonuses() -> void:
	bonus_reels = 0
	bonus_paylines = 0
	bonus_hours = 0.0
	marker_reduction = 0.0
	marker_reduction_percent = 0.0
	payout_multiplier = 1.0

	for card in active_cards:
		if card.is_expired():
			continue

		match card.effect_type:
			LoyaltyCardClass.EffectType.ADD_REEL:
				bonus_reels += int(card.effect_value)
			LoyaltyCardClass.EffectType.ADD_PAYLINE:
				bonus_paylines += int(card.effect_value)
			LoyaltyCardClass.EffectType.ADD_HOURS:
				# Epic hours cards add hours each day
				if card.rarity == LoyaltyCardClass.Rarity.EPIC:
					bonus_hours += card.effect_value
			LoyaltyCardClass.EffectType.REDUCE_MARKER:
				if card.rarity == LoyaltyCardClass.Rarity.EPIC:
					marker_reduction_percent += card.effect_value
				else:
					marker_reduction += card.effect_value
			LoyaltyCardClass.EffectType.PAYOUT_MULTIPLIER:
				payout_multiplier *= card.effect_value

# Get total reels (base + bonus)
func get_total_reels(base_reels: int) -> int:
	return base_reels + bonus_reels

# Get total paylines (base + bonus)
func get_total_paylines(base_paylines: int) -> int:
	return base_paylines + bonus_paylines

# Get adjusted marker amount
func get_adjusted_marker(base_marker: int) -> int:
	var adjusted = float(base_marker)
	adjusted -= marker_reduction
	adjusted *= (1.0 - marker_reduction_percent)
	return maxi(0, int(adjusted))

# Get payout with multiplier applied
func get_adjusted_payout(base_payout: int) -> int:
	return int(float(base_payout) * payout_multiplier)

# Get bonus hours for the day
func get_bonus_hours() -> float:
	return bonus_hours

# Get active cards of a specific type
func get_active_cards_by_type(effect_type: int) -> Array:
	var result: Array = []
	for card in active_cards:
		if card.effect_type == effect_type and not card.is_expired():
			result.append(card)
	return result

# Get all active cards
func get_all_active_cards() -> Array:
	var result: Array = []
	for card in active_cards:
		if not card.is_expired():
			result.append(card)
	return result

# Reset for new game
func reset() -> void:
	active_cards.clear()
	current_pack.clear()
	shop_open = false
	_recalculate_bonuses()

# Save/Load support
func to_dict() -> Dictionary:
	var cards_data: Array = []
	for card in active_cards:
		cards_data.append(card.to_dict())

	return {
		"active_cards": cards_data,
		"shop_open_hour": shop_open_hour,
		"shop_close_hour": shop_close_hour
	}

func from_dict(data: Dictionary) -> void:
	active_cards.clear()

	if data.has("active_cards"):
		for card_data in data["active_cards"]:
			active_cards.append(LoyaltyCardClass.from_dict(card_data))

	if data.has("shop_open_hour"):
		shop_open_hour = data["shop_open_hour"]
	if data.has("shop_close_hour"):
		shop_close_hour = data["shop_close_hour"]

	_recalculate_bonuses()
