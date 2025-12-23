extends Control

const SYMBOL_HEIGHT: float = 100.0

# Payline colors for each row
const PAYLINE_COLORS: Array = [
	Color(1, 0, 0, 0.8),    # Red - top row
	Color(0, 1, 0, 0.8),    # Green - middle row
	Color(0, 0, 1, 0.8),    # Blue - bottom row
]

func _draw():
	var rect_size = size
	var num_rows = int(rect_size.y / SYMBOL_HEIGHT)

	# Draw payline for each visible row
	for row in range(num_rows):
		var y_pos = (row * SYMBOL_HEIGHT) + (SYMBOL_HEIGHT / 2.0)
		var color = PAYLINE_COLORS[row % PAYLINE_COLORS.size()]
		draw_line(Vector2(0, y_pos), Vector2(rect_size.x, y_pos), color, 2.0)
