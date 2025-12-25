extends Node
class_name DayManager

# Signals
signal day_started(day_number: int, marker_amount: int)
signal day_ended(day_number: int, success: bool, coins_earned: int)
signal marker_updated(current_coins: int, marker_amount: int)
signal hours_updated(hours_remaining: float)

# Day state
var current_day: int = 1
var marker_amount: int = 0
var starting_hours: float = 8.0
var hours_remaining: float = 8.0

# Marker progression (increases each day)
const BASE_MARKER: int = 50
const MARKER_INCREMENT: int = 25  # Additional coins required per day
const BASE_HOURS: float = 8.0
const HOURS_INCREMENT: float = 0.5  # Additional hours per day (slight increase)

# Day history for tracking progress
var day_history: Array = []  # Array of {day, marker, earned, success}

# Calculate marker for a specific day
static func calculate_marker_for_day(day: int) -> int:
	return BASE_MARKER + ((day - 1) * MARKER_INCREMENT)

# Calculate hours for a specific day
static func calculate_hours_for_day(day: int) -> float:
	return BASE_HOURS + ((day - 1) * HOURS_INCREMENT)

# Start a new day
func start_day(day_number: int = -1) -> void:
	if day_number > 0:
		current_day = day_number

	# Calculate marker and hours for this day
	marker_amount = calculate_marker_for_day(current_day)
	starting_hours = calculate_hours_for_day(current_day)
	hours_remaining = starting_hours

	day_started.emit(current_day, marker_amount)
	marker_updated.emit(0, marker_amount)
	hours_updated.emit(hours_remaining)

# Use time (called on each spin)
func use_time(hours: float) -> bool:
	hours_remaining -= hours
	hours_updated.emit(hours_remaining)

	if hours_remaining <= 0:
		hours_remaining = 0
		_end_day()
		return false  # Day ended
	return true  # Can continue

# Check if day should end
func should_day_end() -> bool:
	return hours_remaining <= 0

# Get progress percentage toward marker
func get_marker_progress(current_coins: int) -> float:
	if marker_amount <= 0:
		return 1.0
	return clampf(float(current_coins) / float(marker_amount), 0.0, 1.0)

# Check if marker is covered
func is_marker_covered(current_coins: int) -> bool:
	return current_coins >= marker_amount

# End the current day
func _end_day() -> void:
	# This will be called by GameConfig when it detects hours_remaining <= 0
	pass

# Process end of day (called by GameConfig)
func end_day(coins_earned: int) -> Dictionary:
	var success = coins_earned >= marker_amount

	# Record history
	var day_record = {
		"day": current_day,
		"marker": marker_amount,
		"earned": coins_earned,
		"success": success
	}
	day_history.append(day_record)

	day_ended.emit(current_day, success, coins_earned)

	return day_record

# Advance to next day
func advance_day() -> void:
	current_day += 1
	start_day()

# Get current day info
func get_day_info() -> Dictionary:
	return {
		"day": current_day,
		"marker": marker_amount,
		"hours_remaining": hours_remaining,
		"starting_hours": starting_hours
	}

# Reset for new game
func reset() -> void:
	current_day = 1
	marker_amount = 0
	hours_remaining = BASE_HOURS
	starting_hours = BASE_HOURS
	day_history.clear()

# Save/Load support
func to_dict() -> Dictionary:
	return {
		"current_day": current_day,
		"marker_amount": marker_amount,
		"hours_remaining": hours_remaining,
		"starting_hours": starting_hours,
		"day_history": day_history
	}

func from_dict(data: Dictionary) -> void:
	if data.has("current_day"):
		current_day = int(data["current_day"])
	if data.has("marker_amount"):
		marker_amount = int(data["marker_amount"])
	if data.has("hours_remaining"):
		hours_remaining = float(data["hours_remaining"])
	if data.has("starting_hours"):
		starting_hours = float(data["starting_hours"])
	if data.has("day_history"):
		day_history = data["day_history"]
