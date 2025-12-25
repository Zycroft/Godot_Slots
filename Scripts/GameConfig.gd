extends Node

# Preload ReelObject class
const ReelObjectClass = preload("res://Scripts/ReelObject.gd")

# Signals
signal config_changed
signal card_purchased(card_id: String)
signal game_reset

# Config file path
const CONFIG_PATH = "res://Config/game_config.json"

# Game configuration values
var num_reels: int = 5
var visible_rows: int = 3
var reelslots: int = 10
var spin_direction_down: bool = true
var spin_duration: float = 2.5
var reel_stop_delay: float = 0.3

# Symbol texture paths
var symbols: Dictionary = {}

# Symbol payouts (symbol_name -> { "3": payout, "4": payout, "5": payout })
var symbol_payouts: Dictionary = {}

# Reel objects (symbol_name -> ReelObject data dictionary)
var reel_objects: Dictionary = {}

# Cached ReelObject instances
var _reel_object_cache: Dictionary = {}

# Reel configurations (array of symbol names per reel)
var reels: Array = []

# Payline definitions (row indices for each reel)
var paylines: Array = []

# Game state
var credits: int = 100
var hours_remaining: float = 8.0
var spin_cost: int = 1
var hours_per_spin: float = 0.5

# Loyalty Card System
var owned_cards: Array = []
var card_cost_multiplier: float = 1.0

# Difficulty definitions
const DIFFICULTIES = {
	"easy": {
		"name": "Easy",
		"credits": 500,
		"hours": 24.0,
		"card_cost_multiplier": 0.5
	},
	"normal": {
		"name": "Normal",
		"credits": 100,
		"hours": 8.0,
		"card_cost_multiplier": 1.0
	},
	"hard": {
		"name": "Hard",
		"credits": 50,
		"hours": 4.0,
		"card_cost_multiplier": 2.0
	}
}

var current_difficulty: String = "normal"
var game_started: bool = false

# Card definitions (base costs)
const CARD_DEFINITIONS = {
	"reel": {
		"name": "Reel Card",
		"description": "+1 Reel",
		"base_cost": 50,
		"effect": "add_reel"
	},
	"payline": {
		"name": "Payline Card",
		"description": "+1 Row & Payline",
		"base_cost": 30,
		"effect": "add_payline"
	},
	"symbol": {
		"name": "Symbol Card",
		"description": "+1 Symbol",
		"base_cost": 100,
		"effect": "add_symbol"
	}
}

# Cached textures
var _symbol_textures: Dictionary = {}

func _ready():
	load_config()

func load_config(path: String = CONFIG_PATH) -> bool:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to open config file: " + path)
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("Failed to parse config JSON: " + json.get_error_message())
		return false

	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Config JSON root must be a dictionary")
		return false

	_apply_config(data)
	return true

func _apply_config(data: Dictionary):
	# Apply basic settings
	if data.has("num_reels"):
		num_reels = int(data["num_reels"])
	if data.has("visible_rows"):
		visible_rows = int(data["visible_rows"])
	if data.has("reelslots"):
		reelslots = int(data["reelslots"])
	if data.has("spin_direction_down"):
		spin_direction_down = bool(data["spin_direction_down"])
	if data.has("spin_duration"):
		spin_duration = float(data["spin_duration"])
	if data.has("reel_stop_delay"):
		reel_stop_delay = float(data["reel_stop_delay"])

	# Apply symbols
	if data.has("symbols"):
		symbols = data["symbols"]
		_load_symbol_textures()

	# Apply symbol payouts
	if data.has("symbol_payouts"):
		symbol_payouts = data["symbol_payouts"]

	# Apply reel objects
	if data.has("reel_objects"):
		reel_objects = data["reel_objects"]
		_load_reel_objects()

	# Apply reels
	if data.has("reels"):
		reels = data["reels"]

	# Apply paylines
	if data.has("paylines"):
		paylines = data["paylines"]

	# Apply game state
	if data.has("credits"):
		credits = int(data["credits"])
	if data.has("hours_remaining"):
		hours_remaining = float(data["hours_remaining"])
	if data.has("spin_cost"):
		spin_cost = int(data["spin_cost"])
	if data.has("hours_per_spin"):
		hours_per_spin = float(data["hours_per_spin"])

	# Emit signal so listeners can update
	config_changed.emit()

func _load_symbol_textures():
	_symbol_textures.clear()
	for symbol_name in symbols:
		var path = symbols[symbol_name]
		var texture = load(path)
		if texture:
			_symbol_textures[symbol_name] = texture
		else:
			push_warning("Failed to load symbol texture: " + path)

func _load_reel_objects():
	_reel_object_cache.clear()
	for obj_id in reel_objects:
		var obj_data = reel_objects[obj_id]
		var reel_obj = ReelObjectClass.from_dict(obj_data)
		_reel_object_cache[obj_id] = reel_obj

		# Also load texture into symbols cache if not already there
		if not symbols.has(obj_id) and obj_data.has("texture"):
			symbols[obj_id] = obj_data["texture"]
			var texture = load(obj_data["texture"])
			if texture:
				_symbol_textures[obj_id] = texture

func get_symbol_texture(symbol_name: String) -> Texture2D:
	if _symbol_textures.has(symbol_name):
		return _symbol_textures[symbol_name]
	return null

func get_reel_object(symbol_id: String):
	if _reel_object_cache.has(symbol_id):
		return _reel_object_cache[symbol_id]
	return null

func is_wild(symbol_id: String) -> bool:
	var obj = get_reel_object(symbol_id)
	if obj:
		return obj.is_wild
	return false

func get_multiplier(symbol_id: String) -> float:
	var obj = get_reel_object(symbol_id)
	if obj and obj.type == ReelObjectClass.Type.MULTIPLIER:
		return obj.multiplier_value
	return 1.0

func is_free_spin(symbol_id: String) -> bool:
	var obj = get_reel_object(symbol_id)
	if obj:
		return obj.type == ReelObjectClass.Type.FREE_SPIN
	return false

func get_reel_symbols(reel_index: int) -> Array:
	if reel_index < reels.size():
		var reel_data = reels[reel_index]
		if reel_data is Dictionary and reel_data.has("symbols"):
			return reel_data["symbols"]
	return []

func get_all_symbol_textures() -> Array:
	return _symbol_textures.values()

# Update config at runtime
func update_config(new_data: Dictionary):
	_apply_config(new_data)

# Reload config from file
func reload_config() -> bool:
	return load_config()

# Save current config to file
func save_config(path: String = CONFIG_PATH) -> bool:
	var data = {
		"num_reels": num_reels,
		"visible_rows": visible_rows,
		"reelslots": reelslots,
		"spin_direction_down": spin_direction_down,
		"spin_duration": spin_duration,
		"reel_stop_delay": reel_stop_delay,
		"symbols": symbols,
		"symbol_payouts": symbol_payouts,
		"reels": reels,
		"paylines": paylines,
		"credits": credits,
		"hours_remaining": hours_remaining,
		"spin_cost": spin_cost,
		"hours_per_spin": hours_per_spin
	}

	var json_text = JSON.stringify(data, "\t")
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Failed to open config file for writing: " + path)
		return false

	file.store_string(json_text)
	file.close()
	return true

# Difficulty methods
func start_game(difficulty: String) -> void:
	if not DIFFICULTIES.has(difficulty):
		difficulty = "normal"

	current_difficulty = difficulty
	var diff = DIFFICULTIES[difficulty]
	credits = diff["credits"]
	hours_remaining = diff["hours"]
	card_cost_multiplier = diff["card_cost_multiplier"]
	owned_cards.clear()
	game_started = true
	config_changed.emit()

func get_card_cost(card_id: String) -> int:
	if not CARD_DEFINITIONS.has(card_id):
		return 0
	return int(CARD_DEFINITIONS[card_id]["base_cost"] * card_cost_multiplier)

# Card system methods
func can_afford_card(card_id: String) -> bool:
	if not CARD_DEFINITIONS.has(card_id):
		return false
	return credits >= get_card_cost(card_id)

func buy_card(card_id: String) -> bool:
	if not can_afford_card(card_id):
		return false

	var cost = get_card_cost(card_id)
	credits -= cost
	owned_cards.append(card_id)
	card_purchased.emit(card_id)
	config_changed.emit()
	return true

func get_card_count(card_id: String) -> int:
	return owned_cards.count(card_id)

func reset_game() -> void:
	game_started = false
	owned_cards.clear()
	load_config()  # Reload original config
	game_reset.emit()
