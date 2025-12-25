extends RefCounted
class_name LoyaltyCard

# Self-reference for static factory methods
static var _script: GDScript

static func _static_init():
	_script = load("res://Scripts/LoyaltyCard.gd")

# Card rarities with different durations
enum Rarity { COMMON, UNCOMMON, RARE, EPIC }

# Card effect types
enum EffectType {
	ADD_REEL,
	ADD_PAYLINE,
	ADD_HOURS,
	REDUCE_MARKER,
	PAYOUT_MULTIPLIER,
	OPEN_SHOP
}

# Rarity colors
const RARITY_COLORS = {
	Rarity.COMMON: Color(0.6, 0.6, 0.6),      # Gray
	Rarity.UNCOMMON: Color(0.3, 0.8, 0.3),    # Green
	Rarity.RARE: Color(0.3, 0.5, 1.0),        # Blue
	Rarity.EPIC: Color(0.8, 0.4, 1.0)         # Purple
}

const RARITY_NAMES = {
	Rarity.COMMON: "Common",
	Rarity.UNCOMMON: "Uncommon",
	Rarity.RARE: "Rare",
	Rarity.EPIC: "Epic"
}

# Duration in days for each rarity (0 = permanent)
const RARITY_DURATION = {
	Rarity.COMMON: 1,      # Rest of current day
	Rarity.UNCOMMON: 2,    # Current day + next day
	Rarity.RARE: 5,        # Next 5 days
	Rarity.EPIC: 0         # Permanent
}

# Card instance data
var id: String
var name: String
var description: String
var rarity: Rarity
var effect_type: EffectType
var effect_value: float
var days_remaining: int  # 0 = permanent, -1 = expired
var activated_on_day: int

# Cost in gold nuggets (epic costs gold bars)
var nugget_cost: int
var bar_cost: int

func _init(card_id: String = "", card_rarity: Rarity = Rarity.COMMON):
	id = card_id
	rarity = card_rarity
	days_remaining = RARITY_DURATION[rarity]
	activated_on_day = 0

static func create_reel_card(card_rarity: Rarity):
	var card = _script.new("reel_" + RARITY_NAMES[card_rarity].to_lower(), card_rarity)
	card.name = "Reel Card"
	card.effect_type = EffectType.ADD_REEL
	card.effect_value = 1.0

	match card_rarity:
		Rarity.COMMON:
			card.description = "+1 Reel (today)"
			card.nugget_cost = 1
		Rarity.UNCOMMON:
			card.description = "+1 Reel (2 days)"
			card.nugget_cost = 2
		Rarity.RARE:
			card.description = "+1 Reel (5 days)"
			card.nugget_cost = 5
		Rarity.EPIC:
			card.description = "+1 Reel (permanent)"
			card.bar_cost = 1

	return card

static func create_payline_card(card_rarity: Rarity):
	var card = _script.new("payline_" + RARITY_NAMES[card_rarity].to_lower(), card_rarity)
	card.name = "Payline Card"
	card.effect_type = EffectType.ADD_PAYLINE
	card.effect_value = 1.0

	match card_rarity:
		Rarity.COMMON:
			card.description = "+1 Payline (today)"
			card.nugget_cost = 1
		Rarity.UNCOMMON:
			card.description = "+1 Payline (2 days)"
			card.nugget_cost = 2
		Rarity.RARE:
			card.description = "+1 Payline (5 days)"
			card.nugget_cost = 4
		Rarity.EPIC:
			card.description = "+1 Payline (permanent)"
			card.bar_cost = 1

	return card

static func create_hours_card(card_rarity: Rarity):
	var card = _script.new("hours_" + RARITY_NAMES[card_rarity].to_lower(), card_rarity)
	card.name = "Time Card"
	card.effect_type = EffectType.ADD_HOURS

	match card_rarity:
		Rarity.COMMON:
			card.description = "+1 Hour (today)"
			card.effect_value = 1.0
			card.nugget_cost = 1
		Rarity.UNCOMMON:
			card.description = "+2 Hours (today)"
			card.effect_value = 2.0
			card.nugget_cost = 2
		Rarity.RARE:
			card.description = "+4 Hours (today)"
			card.effect_value = 4.0
			card.nugget_cost = 3
		Rarity.EPIC:
			card.description = "+2 Hours/day"
			card.effect_value = 2.0
			card.bar_cost = 1

	return card

static func create_marker_card(card_rarity: Rarity):
	var card = _script.new("marker_" + RARITY_NAMES[card_rarity].to_lower(), card_rarity)
	card.name = "Marker Card"
	card.effect_type = EffectType.REDUCE_MARKER

	match card_rarity:
		Rarity.COMMON:
			card.description = "-$10 Marker (today)"
			card.effect_value = 10.0
			card.nugget_cost = 1
		Rarity.UNCOMMON:
			card.description = "-$25 Marker (2 days)"
			card.effect_value = 25.0
			card.nugget_cost = 2
		Rarity.RARE:
			card.description = "-$50 Marker (5 days)"
			card.effect_value = 50.0
			card.nugget_cost = 4
		Rarity.EPIC:
			card.description = "-25% Marker (permanent)"
			card.effect_value = 0.25  # 25% reduction
			card.bar_cost = 2

	return card

static func create_payout_card(card_rarity: Rarity):
	var card = _script.new("payout_" + RARITY_NAMES[card_rarity].to_lower(), card_rarity)
	card.name = "Payout Card"
	card.effect_type = EffectType.PAYOUT_MULTIPLIER

	match card_rarity:
		Rarity.COMMON:
			card.description = "+10% Payouts (today)"
			card.effect_value = 1.1
			card.nugget_cost = 2
		Rarity.UNCOMMON:
			card.description = "+15% Payouts (2 days)"
			card.effect_value = 1.15
			card.nugget_cost = 3
		Rarity.RARE:
			card.description = "+25% Payouts (5 days)"
			card.effect_value = 1.25
			card.nugget_cost = 5
		Rarity.EPIC:
			card.description = "+20% Payouts (permanent)"
			card.effect_value = 1.2
			card.bar_cost = 2

	return card

# Generate a random card with weighted rarity
static func generate_random_card():
	# Weighted rarity selection
	var roll = randf()
	var card_rarity: Rarity
	if roll < 0.50:
		card_rarity = Rarity.COMMON
	elif roll < 0.80:
		card_rarity = Rarity.UNCOMMON
	elif roll < 0.95:
		card_rarity = Rarity.RARE
	else:
		card_rarity = Rarity.EPIC

	# Random card type
	var card_types = ["reel", "payline", "hours", "marker", "payout"]
	var card_type = card_types[randi() % card_types.size()]

	match card_type:
		"reel":
			return create_reel_card(card_rarity)
		"payline":
			return create_payline_card(card_rarity)
		"hours":
			return create_hours_card(card_rarity)
		"marker":
			return create_marker_card(card_rarity)
		"payout":
			return create_payout_card(card_rarity)

	return create_reel_card(card_rarity)  # Fallback

# Generate a pack of cards (player chooses one)
static func generate_pack(pack_size: int = 3) -> Array:
	var cards: Array = []
	for i in range(pack_size):
		cards.append(generate_random_card())
	return cards

func get_rarity_color() -> Color:
	return RARITY_COLORS[rarity]

func get_rarity_name() -> String:
	return RARITY_NAMES[rarity]

func get_cost_text() -> String:
	if bar_cost > 0:
		return "%d Bar%s" % [bar_cost, "s" if bar_cost > 1 else ""]
	else:
		return "%d Nugget%s" % [nugget_cost, "s" if nugget_cost > 1 else ""]

func can_afford() -> bool:
	if bar_cost > 0:
		return GameConfig.gold_bars >= bar_cost
	else:
		return GameConfig.gold_nuggets >= nugget_cost

func is_expired() -> bool:
	return days_remaining < 0

func is_permanent() -> bool:
	return days_remaining == 0

# Called at the start of each day to check expiration
func tick_day() -> bool:
	if days_remaining > 0:
		days_remaining -= 1
		if days_remaining <= 0 and rarity != Rarity.EPIC:
			days_remaining = -1  # Expired
			return false  # Card expired
	return true  # Card still active

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"rarity": rarity,
		"effect_type": effect_type,
		"effect_value": effect_value,
		"days_remaining": days_remaining,
		"activated_on_day": activated_on_day,
		"nugget_cost": nugget_cost,
		"bar_cost": bar_cost
	}

static func from_dict(data: Dictionary):
	var card = _script.new()
	card.id = data.get("id", "")
	card.name = data.get("name", "")
	card.description = data.get("description", "")
	card.rarity = data.get("rarity", Rarity.COMMON)
	card.effect_type = data.get("effect_type", EffectType.ADD_REEL)
	card.effect_value = data.get("effect_value", 1.0)
	card.days_remaining = data.get("days_remaining", 1)
	card.activated_on_day = data.get("activated_on_day", 0)
	card.nugget_cost = data.get("nugget_cost", 0)
	card.bar_cost = data.get("bar_cost", 0)
	return card
