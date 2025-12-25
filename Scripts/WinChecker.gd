extends RefCounted
class_name WinChecker

# Result structure for a single win
class WinResult:
	var payline_index: int = -1
	var symbol: String = ""
	var match_count: int = 0
	var payout: int = 0
	var positions: Array = []  # Array of {reel, row} positions

	func _to_string() -> String:
		return "Payline %d: %dx %s = %d coins" % [payline_index, match_count, symbol, payout]

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

	# Count consecutive matching symbols from left
	var first_symbol = payline_symbols[0]
	var match_count = 1
	var matched_positions = [positions[0]]

	for i in range(1, payline_symbols.size()):
		if payline_symbols[i] == first_symbol:
			match_count += 1
			matched_positions.append(positions[i])
		else:
			break  # Stop at first non-match

	# Check if we have a winning combination (3+ matches)
	if match_count >= 3:
		var payout = get_payout(first_symbol, match_count, symbol_payouts)
		if payout > 0:
			var result = WinResult.new()
			result.payline_index = payline_index
			result.symbol = first_symbol
			result.match_count = match_count
			result.payout = payout
			result.positions = matched_positions
			return result

	return null

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
