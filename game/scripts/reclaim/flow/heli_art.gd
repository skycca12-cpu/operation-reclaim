extends RefCounted

# PNG cells, frame order, and pivots follow the supplied animation.json.
const CELL := Vector2(443, 443)
const CLIPS := {
	"side": [preload("res://assets/reclaim/jeju/intro/helicopter_side.png"), 10.0, Vector2(0.5, 0.5), true],
	"quarter": [preload("res://assets/reclaim/jeju/intro/helicopter_quarter.png"), 10.0, Vector2(0.5, 0.5), true],
	"dust": [preload("res://assets/reclaim/jeju/intro/landing_dust.png"), 10.0, Vector2(0.5, 0.88), false],
	"wind": [preload("res://assets/reclaim/jeju/intro/rotor_wind.png"), 10.0, Vector2(0.5, 0.5), true],
	"fire": [preload("res://assets/reclaim/jeju/intro/fire.png"), 12.0, Vector2(0.5, 0.88), true],
	"smoke": [preload("res://assets/reclaim/jeju/intro/smoke.png"), 10.0, Vector2(0.5, 0.88), true],
	"embers": [preload("res://assets/reclaim/jeju/intro/embers.png"), 10.0, Vector2(0.5, 0.88), true],
}


static func draw_clip(canvas: CanvasItem, kind: String, age: float, pivot: Vector2, extent: Vector2, opacity := 1.0) -> void:
	if age < 0.0 or opacity <= 0.0:
		return
	var clip: Array = CLIPS[kind]
	var frame := floori(age * float(clip[1]))
	if frame >= 8 and not bool(clip[3]):
		return
	frame %= 8
	var anchor: Vector2 = clip[2]
	var source := Rect2(Vector2(frame % 4, frame / 4) * CELL, CELL)
	canvas.draw_texture_rect_region(clip[0], Rect2(pivot - extent * anchor, extent), source, Color(1, 1, 1, opacity))
