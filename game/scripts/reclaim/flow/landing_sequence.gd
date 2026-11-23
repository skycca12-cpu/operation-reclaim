extends RefCounted
## In-world landing sequence drawn on the real Jeju map, right before control
## is handed to the player:
##   descend → touchdown + dust → operator disembarks → HQ tent is assembled
##   → helicopter lifts off and leaves the screen → finished.
## The helicopter is completely gone before the first controllable frame, so
## the first play frame shows only the military tent HQ (spec requirement).

const HeliArt = preload("res://scripts/reclaim/flow/heli_art.gd")

const T_TOUCHDOWN := 2.8
const T_DISEMBARK := 3.2
const T_WALK_END := 4.4
const T_BUILD_START := 4.0
const T_BUILD_END := 6.6
const T_LIFTOFF := 6.9
const T_END := 9.6

var t := 0.0
var done := false
var lz := Vector2.ZERO
var player_start := Vector2.ZERO
var hq_center := Vector2.ZERO
var exit_dir := Vector2(0.8, -0.6).normalized()
var sfx: Node = null
var _thumped := false
var _build_cues := 0


func setup(landing_zone: Vector2, start_pos: Vector2, hq_world_center: Vector2, sfx_node: Node) -> void:
	t = 0.0
	done = false
	lz = landing_zone
	player_start = start_pos
	hq_center = hq_world_center
	sfx = sfx_node
	_thumped = false
	_build_cues = 0


func skip() -> void:
	t = T_END
	done = true
	if sfx: sfx.set_rotor(0.0)


func update(delta: float) -> void:
	if done:
		return
	t += delta
	if not _thumped and t >= T_TOUCHDOWN:
		_thumped = true
		if sfx: sfx.play("thump", -2.0)
	if t >= T_BUILD_START + float(_build_cues) * 0.95 and _build_cues < 3:
		_build_cues += 1
		if sfx: sfx.play("build", -6.0, 1.0 + 0.06 * _build_cues)
	if sfx:
		var level := 1.0
		if t > T_LIFTOFF: level = clampf(1.0 - (t - T_LIFTOFF) / (T_END - T_LIFTOFF), 0.0, 1.0)
		elif t > T_TOUCHDOWN: level = 0.65
		sfx.set_rotor(level, 1.0 if t < T_TOUCHDOWN else 0.92)
	if t >= T_END:
		done = true
		if sfx: sfx.set_rotor(0.0)


func altitude() -> float:
	if t < T_TOUCHDOWN:
		return lerpf(1.6, 0.0, ease(t / T_TOUCHDOWN, 0.45))
	if t < T_LIFTOFF:
		return 0.0
	return lerpf(0.0, 1.8, clampf((t - T_LIFTOFF) / 1.6, 0.0, 1.0))


func heli_world() -> Vector2:
	if t < T_LIFTOFF:
		return lz
	var k := maxf(0.0, t - T_LIFTOFF - 0.5)
	return lz + exit_dir * (k * k * 260.0)


func heli_visible() -> bool:
	return not done


func player_visible() -> bool:
	return t >= T_DISEMBARK


## Camera/player position while the cut plays (camera follows player_pos).
func player_world() -> Vector2:
	var door := lz + Vector2(0, 26)
	if t < T_DISEMBARK:
		return door
	var k := clampf((t - T_DISEMBARK) / (T_WALK_END - T_DISEMBARK), 0.0, 1.0)
	return door.lerp(player_start, k)


func player_moving() -> bool:
	return t >= T_DISEMBARK and t < T_WALK_END


func hq_ratio() -> float:
	return clampf((t - T_BUILD_START) / (T_BUILD_END - T_BUILD_START), 0.0, 1.0) if t >= T_BUILD_START - 0.6 else -1.0


func caption() -> String:
	if t < T_TOUCHDOWN: return "LZ ALPHA 하강 중 · 착륙 지점 확보"
	if t < T_BUILD_START: return "착륙 완료 · 대원 하차"
	if t < T_BUILD_END: return "지휘본부 군용 텐트 설치 중  %d%%" % int(hq_ratio() * 100.0)
	return "헬기 이탈 · 작전 개시 준비"


func draw(c: CanvasItem, to_screen: Callable) -> void:
	if done:
		return
	var alt := altitude()
	var hp: Vector2 = to_screen.call(heli_world())
	# rotor wash dust: expands while the helicopter is low, low-frame step growth
	var wash := clampf(1.0 - alt / 0.8, 0.0, 1.0)
	if wash > 0.0 and t < T_LIFTOFF + 1.2:
		var center: Vector2 = to_screen.call(lz)
		var step := floorf(t * 8.0) / 8.0
		for i in range(26):
			var ang := float(i) / 26.0 * TAU + float(i % 3) * 0.2
			var r := 40.0 + fmod(step * 90.0 + float(i * 17), 120.0)
			var a := 0.45 * wash * (1.0 - (r - 40.0) / 120.0)
			c.draw_circle(center + Vector2.from_angle(ang) * r, 7.0 + float(i % 4) * 2.0, Color(0.62, 0.56, 0.46, a))
		c.draw_circle(center, 70.0, Color(0.6, 0.55, 0.45, 0.10 * wash))
	var fade := 1.0
	if t > T_END - 0.8: fade = clampf((T_END - t) / 0.8, 0.0, 1.0)
	var heading := -0.5 * (alt / 1.6) if t < T_LIFTOFF else exit_dir.angle() * clampf((t - T_LIFTOFF) / 1.0, 0.0, 1.0)
	HeliArt.draw_top(c, hp, 1.0, heading, t * 20.0, alt, fade)


func draw_overlay(c: CanvasItem, view: Vector2) -> void:
	if done:
		return
	var bar := view.y * 0.08
	c.draw_rect(Rect2(0, 0, view.x, bar), Color(0, 0, 0, 0.85))
	c.draw_rect(Rect2(0, view.y - bar, view.x, bar), Color(0, 0, 0, 0.85))
	var font := ThemeDB.fallback_font
	c.draw_string(font, Vector2(0, view.y - bar * 0.38), caption(), HORIZONTAL_ALIGNMENT_CENTER, view.x, 20, Color(1, 0.92, 0.86))
	c.draw_string(font, Vector2(0, bar * 0.62), "Esc / Space 건너뛰기", HORIZONTAL_ALIGNMENT_RIGHT, view.x - 24, 14, Color(0.8, 0.72, 0.76))


## Stage-by-stage HQ tent assembly (crates → frame → canvas → antenna).
static func draw_tent_build(c: CanvasItem, bounds: Rect2, center: Vector2, ratio: float) -> void:
	if ratio < 0.0:
		return
	var crate := Color("#5d6343")
	var crate_dark := Color("#33371f")
	var shown := int(clampf(ratio / 0.3, 0.0, 1.0) * 3.0 + 1.0) if ratio < 0.3 else 3
	for i in range(shown):
		var p := Vector2(bounds.position.x - 18 + i * 14, bounds.end.y + 4 - i * 3)
		c.draw_rect(Rect2(p, Vector2(14, 11)), crate_dark)
		c.draw_rect(Rect2(p + Vector2(1, 1), Vector2(12, 9)), crate)
	if ratio >= 0.3:
		var k := clampf((ratio - 0.3) / 0.35, 0.0, 1.0)
		var pole_h := 34.0 * k
		for x in [bounds.position.x + 6, center.x, bounds.end.x - 6]:
			c.draw_line(Vector2(x, bounds.end.y - 4), Vector2(x, bounds.end.y - 4 - pole_h), Color("#c9b98d"), 2.0)
		c.draw_line(Vector2(bounds.position.x + 6, bounds.end.y - 4 - pole_h), Vector2(bounds.end.x - 6, bounds.end.y - 4 - pole_h), Color("#c9b98d"), 2.0)
	if ratio >= 0.65:
		var k := clampf((ratio - 0.65) / 0.35, 0.0, 1.0)
		var body := bounds.grow(-5)
		body.position.y = body.end.y - body.size.y * k
		body.size.y *= k
		c.draw_rect(body, Color("#6b7058"))
		if k > 0.6:
			var a := (k - 0.6) / 0.4
			c.draw_colored_polygon(PackedVector2Array([Vector2(bounds.position.x - 2, bounds.position.y + 4), Vector2(center.x, bounds.position.y - 12 * a), Vector2(bounds.end.x + 2, bounds.position.y + 4)]), Color("#8f7456", a))
	# progress pip bar
	c.draw_rect(Rect2(center.x - 40, bounds.position.y - 18, 80, 5), Color(0, 0, 0, 0.75))
	c.draw_rect(Rect2(center.x - 40, bounds.position.y - 18, 80 * ratio, 5), Color("#e7c46a"))
	c.draw_string(ThemeDB.fallback_font, Vector2(center.x - 40, bounds.position.y - 24), "HQ 설치 %d%%" % int(ratio * 100.0), HORIZONTAL_ALIGNMENT_LEFT, 120, 12, Color("#f2edf0"))
