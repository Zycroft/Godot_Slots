extends Control

const GRID_SIZE: int = 20
const LINE_COLOR: Color = Color(1, 0, 0, 0.5)  # Red with 50% transparency

func _draw():
	var rect_size = size

	# Draw vertical lines
	for x in range(0, int(rect_size.x) + 1, GRID_SIZE):
		draw_line(Vector2(x, 0), Vector2(x, rect_size.y), LINE_COLOR, 1.0)

	# Draw horizontal lines
	for y in range(0, int(rect_size.y) + 1, GRID_SIZE):
		draw_line(Vector2(0, y), Vector2(rect_size.x, y), LINE_COLOR, 1.0)

	# Draw center line (payline) in a different color
	var center_y = rect_size.y / 2
	draw_line(Vector2(0, center_y), Vector2(rect_size.x, center_y), Color(0, 1, 0, 0.8), 2.0)
