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
	"rifle": [Color("#e4b276"), 1.4, 0],
	"shotgun": [Color("#ffc67f"), 4.5, 1],
	"saw": [Color("#ffa154"), 2.5, 0],
	"explosive": [Color("#ff8d57"), 6.0, 1],
	"electric": [Color("#7bbcff"), 1.0, 2],
	"fire": [Color("#fb8a49"), 2.0, 1],
	"cold": [Color("#88dfff"), 0.7, 2],
	"drone": [Color("#c6a2ef"), 1.2, 0],
}


static func frame(canvas: CanvasItem, appearance: int, column: int, center: Vector2, tint := Color.WHITE, flipped := false) -> void:
	var id := clampi(appearance, 0, COUNT - 1)
	var offset := Vector2(-ORIGIN.x, ORIGIN.y) if flipped else ORIGIN
	var extent := Vector2(-FOOTPRINT.x, FOOTPRINT.y) if flipped else FOOTPRINT
	var source := Rect2(Vector2(column, id % PAGE_SIZE) * FRAME, FRAME)
	canvas.draw_texture_rect_region(PAGES[id / PAGE_SIZE], Rect2(center + offset, extent), source, tint)


static func reaction(canvas: CanvasItem, enemy: Dictionary, center: Vector2, age: float, tint: Color) -> void:
	var hit: Array = IMPACTS.get(String(enemy.get("hit_style", "rifle")), IMPACTS.rifle)
	var direction: Vector2 = enemy.get("hit_direction", Vector2.DOWN)
	var recoil := direction * float(hit[1]) * maxf(0.0, 1.0 - age / 0.23)
	var phase := mini(3, int(age * 13.0) + int(hit[2]))
	var accent: Color = hit[0]
	frame(canvas, enemy.appearance, 11 + phase, center + recoil,
		tint.lerp(accent, 0.44 * maxf(0.0, 1.0 - age / 0.25)), direction.x < -0.25)
