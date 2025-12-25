extends RefCounted
class_name WinChecker

# Preload ReelObject class
const ReelObjectClass = preload("res://Scripts/ReelObject.gd")

# Result structure for a single win
class WinResult:
	var payline_index: int = -1
	var symbol: String = ""
	var match_count: int = 0
	var payout: int = 0
	var multiplier: float = 1.0
	var positions: Array = []  # Array of {reel, row} positions
	var has_wild: bool = false
	var has_free_spin: bool = false

	func _to_string() -> String:
		var mult_str = "" if multiplier == 1.0 else " (x%.1f)" % multiplier
		return "Payline %d: %dx %s = %d coins%s" % [payline_index, match_count, symbol, payout, mult_str]

# Check all paylines and return array of WinResult
static func check_wins(visible_symbols: Array, paylines: Array, symbol_payouts: Dictionary) -> Array:
	var wins: Array = []

	for payline_idx in range(paylines.size()):
		var payline = paylines[payline_idx]
		var win = check_payline(visible_symbols, payline, payline_idx, symbol_payouts)
		if win != null:
			wins.append(win)

	return wins

# Check a single payline for wins
# visible_symbols: 2D array [reel][row] of symbol names
# payline: Array of row indices for each reel
static func check_payline(visible_symbols: Array, payline: Array, payline_index: int, symbol_payouts: Dictionary) -> WinResult:
	if payline.size() == 0 or visible_symbols.size() == 0:
		return null

	# Get symbols on this payline
	var payline_symbols: Array = []
	var positions: Array = []

	for reel_idx in range(min(payline.size(), visible_symbols.size())):
		var row_idx = payline[reel_idx]
		if row_idx < visible_symbols[reel_idx].size():
			payline_symbols.append(visible_symbols[reel_idx][row_idx])
			positions.append({"reel": reel_idx, "row": row_idx})
		else:
			return null  # Invalid payline configuration

	if payline_symbols.size() < 3:
		return null  # Need at least 3 symbols for a win

	# Find the first non-wild symbol to determine the matching symbol
	var matching_symbol = ""
	var has_wild = false
	var multiplier = 1.0
	var found_free_spin = false

	for symbol in payline_symbols:
		# Check for special symbol types
		if GameConfig.is_wild(symbol):
			has_wild = true
		if GameConfig.is_free_spin(symbol):
			found_free_spin = true

		var mult = GameConfig.get_multiplier(symbol)
		if mult > 1.0:
			multiplier *= mult

		# Find first non-wild, non-multiplier symbol
		if matching_symbol == "" and not GameConfig.is_wild(symbol):
			var obj = GameConfig.get_reel_object(symbol)
			if obj == null or obj.type == ReelObjectClass.Type.STANDARD:
				matching_symbol = symbol

	# If all symbols are wild, use "wild" as the matching symbol
	if matching_symbol == "":
		matching_symbol = payline_symbols[0]

	# Count consecutive matching symbols from left (including wilds)
	var match_count = 0
	var matched_positions = []

	for i in range(payline_symbols.size()):
		var symbol = payline_symbols[i]
		var is_match = false

		if symbol == matching_symbol:
			is_match = true
		elif GameConfig.is_wild(symbol):
			# Wild matches anything
			is_match = true
		elif _symbols_match(symbol, matching_symbol):
			is_match = true

		if is_match:
			match_count += 1
			matched_positions.append(positions[i])
		else:
			break  # Stop at first non-match

	# Check if we have a winning combination (3+ matches)
	if match_count >= 3:
		var base_payout = get_payout(matching_symbol, match_count, symbol_payouts)

		# If matching symbol has no payout but we have wilds, check wild payout
		if base_payout == 0 and has_wild:
			base_payout = get_payout("wild", match_count, symbol_payouts)

		if base_payout > 0:
			var result = WinResult.new()
			result.payline_index = payline_index
			result.symbol = matching_symbol
			result.match_count = match_count
			result.multiplier = multiplier
			result.payout = int(base_payout * multiplier)
			result.positions = matched_positions
			result.has_wild = has_wild
			result.has_free_spin = found_free_spin
			return result

	return null

# Check if two symbols match (considering wilds)
static func _symbols_match(symbol_a: String, symbol_b: String) -> bool:
	if symbol_a == symbol_b:
		return true
	if GameConfig.is_wild(symbol_a) or GameConfig.is_wild(symbol_b):
		return true
	return false

# Get payout for a symbol and match count
static func get_payout(symbol: String, match_count: int, symbol_payouts: Dictionary) -> int:
	if not symbol_payouts.has(symbol):
		return 0

	var payouts = symbol_payouts[symbol]
	var count_str = str(match_count)

	if payouts.has(count_str):
		return int(payouts[count_str])

	# If exact match count not found, try lower counts
	for i in range(match_count, 2, -1):
		var key = str(i)
		if payouts.has(key):
			return int(payouts[key])

	return 0

# Calculate total payout from all wins
static func calculate_total_payout(wins: Array) -> int:
	var total = 0
	for win in wins:
		total += win.payout
	return total

# Check if any wins contain a free spin symbol
static func has_free_spin(wins: Array) -> bool:
	for win in wins:
		if win.has_free_spin:
			return true
	return false

# Check visible symbols for any free spin symbols (even without winning)
static func check_free_spins(visible_symbols: Array) -> int:
	var count = 0
	for reel in visible_symbols:
		for symbol in reel:
			if GameConfig.is_free_spin(symbol):
				count += 1
	return count
