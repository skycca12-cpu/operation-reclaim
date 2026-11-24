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
	"rifle": [Color("#e4b276"), 0],
	"shotgun": [Color("#ffc67f"), 1],
	"saw": [Color("#ffa154"), 0],
	"explosive": [Color("#ff8d57"), 1],
	"electric": [Color("#7bbcff"), 2],
	"fire": [Color("#fb8a49"), 1],
	"cold": [Color("#88dfff"), 2],
	"drone": [Color("#c6a2ef"), 0],
}


static func frame(canvas: CanvasItem, appearance: int, column: int, center: Vector2, tint := Color.WHITE, flipped := false) -> void:
	var id := clampi(appearance, 0, COUNT - 1)
	var extent := Vector2(-FOOTPRINT.x, FOOTPRINT.y) if flipped else FOOTPRINT
	var source := Rect2(Vector2(column, id % PAGE_SIZE) * FRAME, FRAME)
	canvas.draw_texture_rect_region(PAGES[id / PAGE_SIZE], Rect2(center + ORIGIN, extent), source, tint)


static func reaction(canvas: CanvasItem, enemy: Dictionary, center: Vector2, age: float, tint: Color) -> void:
	var hit: Array = IMPACTS.get(String(enemy.get("hit_style", "rifle")), IMPACTS.rifle)
	var phase := mini(3, int(age * 13.0) + int(hit[1]))
	frame(canvas, enemy.appearance, 11 + phase, center, impact_tint(enemy, age, tint))


static func directional_reaction(canvas: CanvasItem, enemy: Dictionary, column: int, center: Vector2,
		camera: Transform2D, age: float, tint: Color) -> void:
	var direction: Vector2 = enemy.get("hit_direction", Vector2.ZERO)
	var amount := sin(clampf(age / 0.24, 0.0, 1.0) * PI)
	var pivot := center + Vector2(0.0, 41.5)
	var braced := int(enemy.appearance) % 8 == 7
	if braced:
		pivot.x += [-15.0, -6.0, 6.0, 17.0][int(enemy.row)]
	var tilt := direction.x * amount * (0.024 if braced else 0.075)
	var bend := absf(direction.y) * amount * (0.018 if braced else 0.04)
	var turn := Transform2D(tilt, Vector2(1.0, 1.0 - bend), 0.0, Vector2.ZERO)
	canvas.draw_set_transform_matrix(camera * Transform2D(turn.x, turn.y, pivot - turn * pivot))
	frame(canvas, enemy.appearance, column, center, impact_tint(enemy, age, tint))
	canvas.draw_set_transform_matrix(camera)


static func impact_tint(enemy: Dictionary, age: float, tint: Color) -> Color:
	var hit: Array = IMPACTS.get(String(enemy.get("hit_style", "rifle")), IMPACTS.rifle)
	return tint.lerp(hit[0], 0.44 * clampf(1.0 - age / 0.25, 0.0, 1.0))
