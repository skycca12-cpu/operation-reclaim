extends RefCounted

const COUNT := 50
const PAGE_SIZE := 5
const FRAME := Vector2(72, 72)
const FOOTPRINT := Vector2(108.8, 108.8)
const ORIGIN := Vector2(-54.4, -58.48)
const PAGES: Array[Texture2D] = [
	preload("res://assets/reclaim/zombies/population/page_0.png"),
	preload("res://assets/reclaim/zombies/population/page_1.png"),
	preload("res://assets/reclaim/zombies/population/page_2.png"),
	preload("res://assets/reclaim/zombies/population/page_3.png"),
	preload("res://assets/reclaim/zombies/population/page_4.png"),
	preload("res://assets/reclaim/zombies/population/page_5.png"),
	preload("res://assets/reclaim/zombies/population/page_6.png"),
	preload("res://assets/reclaim/zombies/population/page_7.png"),
	preload("res://assets/reclaim/zombies/population/page_8.png"),
	preload("res://assets/reclaim/zombies/population/page_9.png"),
]
const IMPACTS := {
	"rifle": Color("#e4b276"),
	"shotgun": Color("#ffc67f"),
	"saw": Color("#ffa154"),
	"explosive": Color("#ff8d57"),
	"electric": Color("#7bbcff"),
	"fire": Color("#fb8a49"),
	"cold": Color("#88dfff"),
	"drone": Color("#c6a2ef"),
}


static func frame(canvas: CanvasItem, appearance: int, column: int, center: Vector2, tint := Color.WHITE, flipped := false) -> void:
	var id := clampi(appearance, 0, COUNT - 1)
	var extent := Vector2(-FOOTPRINT.x, FOOTPRINT.y) if flipped else FOOTPRINT
	var source := Rect2(Vector2(column, id % PAGE_SIZE) * FRAME, FRAME)
	canvas.draw_texture_rect_region(PAGES[id / PAGE_SIZE], Rect2(center + ORIGIN, extent), source, tint)
