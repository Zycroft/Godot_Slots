extends RefCounted
class_name ReelObject

# Reel object types
enum Type {
	STANDARD,    # Normal symbol with base payout
	WILD,        # Matches any symbol
	MULTIPLIER,  # Multiplies payline payout
	FREE_SPIN,   # Grants a free spin (no time cost)
	SHOP_KEY     # Opens the loyalty shop
}

# Reel object rarity
enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC
}

# Object properties
var id: String = ""
var display_name: String = ""
var type: Type = Type.STANDARD
var rarity: Rarity = Rarity.COMMON
var texture_path: String = ""

# Payout for single symbol on payline (some objects pay just for appearing)
var single_payout: int = 0

# Standard payout multipliers (for matching symbols)
var payouts: Dictionary = {}  # { "3": 10, "4": 25, "5": 100 }

# Special properties
var multiplier_value: float = 1.0  # For MULTIPLIER type
var is_wild: bool = false          # For WILD type
var wild_excludes: Array = []      # Symbols this wild can't substitute for

# Initialize from dictionary (loaded from config)
static func from_dict(data: Dictionary) -> RefCounted:
	var script = load("res://Scripts/ReelObject.gd")
	var obj = script.new()

	if data.has("id"):
		obj.id = data["id"]
	if data.has("name"):
		obj.display_name = data["name"]
	if data.has("texture"):
		obj.texture_path = data["texture"]

	# Parse type
	if data.has("type"):
		match data["type"]:
			"standard": obj.type = Type.STANDARD
			"wild":
				obj.type = Type.WILD
				obj.is_wild = true
			"multiplier": obj.type = Type.MULTIPLIER
			"free_spin": obj.type = Type.FREE_SPIN
			"shop_key": obj.type = Type.SHOP_KEY

	# Parse rarity
	if data.has("rarity"):
		match data["rarity"]:
			"common": obj.rarity = Rarity.COMMON
			"uncommon": obj.rarity = Rarity.UNCOMMON
			"rare": obj.rarity = Rarity.RARE
			"epic": obj.rarity = Rarity.EPIC

	# Payouts
	if data.has("payouts"):
		obj.payouts = data["payouts"]
	if data.has("single_payout"):
		obj.single_payout = int(data["single_payout"])

	# Special properties
	if data.has("multiplier"):
		obj.multiplier_value = float(data["multiplier"])
	if data.has("wild_excludes"):
		obj.wild_excludes = data["wild_excludes"]

	return obj

# Convert to dictionary (for saving)
func to_dict() -> Dictionary:
	var type_str = "standard"
	match type:
		Type.WILD: type_str = "wild"
		Type.MULTIPLIER: type_str = "multiplier"
		Type.FREE_SPIN: type_str = "free_spin"
		Type.SHOP_KEY: type_str = "shop_key"

	var rarity_str = "common"
	match rarity:
		Rarity.UNCOMMON: rarity_str = "uncommon"
		Rarity.RARE: rarity_str = "rare"
		Rarity.EPIC: rarity_str = "epic"

	return {
		"id": id,
		"name": display_name,
		"type": type_str,
		"rarity": rarity_str,
		"texture": texture_path,
		"payouts": payouts,
		"single_payout": single_payout,
		"multiplier": multiplier_value,
		"wild_excludes": wild_excludes
	}

# Get payout for a specific match count
func get_payout(match_count: int) -> int:
	var count_str = str(match_count)
	if payouts.has(count_str):
		return int(payouts[count_str])
	return 0

# Check if this object can substitute for another symbol (wild logic)
func can_substitute_for(symbol_id: String) -> bool:
	if not is_wild:
		return false
	if symbol_id in wild_excludes:
		return false
	return true

# Get rarity color for UI
func get_rarity_color() -> Color:
	match rarity:
		Rarity.COMMON: return Color(0.7, 0.7, 0.7, 1.0)    # Gray
		Rarity.UNCOMMON: return Color(0.3, 0.8, 0.3, 1.0)  # Green
		Rarity.RARE: return Color(0.3, 0.5, 1.0, 1.0)      # Blue
		Rarity.EPIC: return Color(0.7, 0.3, 0.9, 1.0)      # Purple
	return Color.WHITE

# Get type display string
func get_type_string() -> String:
	match type:
		Type.STANDARD: return "Standard"
		Type.WILD: return "Wild"
		Type.MULTIPLIER: return "x" + str(multiplier_value) + " Multiplier"
		Type.FREE_SPIN: return "Free Spin"
		Type.SHOP_KEY: return "Shop Key"
	return "Unknown"
