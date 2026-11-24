extends RefCounted

const ZombieVisual = preload("res://scripts/reclaim/zombie_visual.gd")

const SPEED := 1150.0
const BUCKET := 128.0

var shots: Array[Dictionary] = []


func fire(origin: Vector2, direction: Vector2, distance: float, damage: float, hits: int, color: Color, muzzle_offset := Vector2.ZERO, speed_factor := 1.0, ricochets := 0) -> void:
	shots.append({
		"pos": origin, "direction": direction, "remaining": distance,
		"damage": damage, "hits": hits, "ricochets": maxi(0, ricochets), "color": color, "hit_ids": {},
		"muzzle_offset": muzzle_offset, "traveled": 0.0, "speed": SPEED * speed_factor,
	})


func update(delta: float, enemies: Array[Dictionary], damage_enemy: Callable) -> void:
	var buckets: Dictionary = {}
	if shots.is_empty():
		return
	if enemies.size() >= 250:
		for enemy in enemies:
			var cell := Vector2i((Vector2(enemy.pos) / BUCKET).floor())
			if not buckets.has(cell): buckets[cell] = []
			buckets[cell].append(enemy)
	for i in range(shots.size() - 1, -1, -1):
		var shot := shots[i]
		var travel := minf(float(shot.speed) * delta, shot.remaining)
		var start: Vector2 = shot.pos
		var direction: Vector2 = shot.direction
		var hit_ids: Dictionary = shot.hit_ids
		var candidates: Array = enemies
		if not buckets.is_empty():
			candidates = []
			var end := start + direction * travel
			var first := Vector2i(((start.min(end) - Vector2.ONE * 72.0) / BUCKET).floor())
			var last := Vector2i(((start.max(end) + Vector2.ONE * 72.0) / BUCKET).floor())
			for y in range(first.y, last.y + 1):
				for x in range(first.x, last.x + 1):
					candidates.append_array(buckets.get(Vector2i(x, y), []))
		while shot.hits > 0:
			var closest: Dictionary = {}
			var first_contact := INF
			for enemy: Dictionary in candidates:
				if enemy.hp <= 0.0 or enemy.get("underground", false) or hit_ids.has(enemy.spawn_id):
					continue
				var offset: Vector2 = enemy.pos - start
				var forward := offset.dot(direction)
				var radius := enemy_radius(enemy)
				# Find where the swept projectile segment enters the enemy circle.
				var lateral := offset.cross(direction)
				var chord_squared := radius * radius - lateral * lateral
				if chord_squared < 0.0:
					continue
				var half_chord := sqrt(chord_squared)
				var entry := maxf(0.0, forward - half_chord)
				if forward + half_chord >= 0.0 and entry <= travel and entry < first_contact:
					closest = enemy
					first_contact = entry
			if closest.is_empty():
				break
			hit_ids[closest.spawn_id] = true
			shot.hits -= 1
			var index := enemies.find(closest)
			var impact := start + direction * first_contact
			if index >= 0:
				damage_enemy.call(index, shot.damage, "player")
			if int(shot.ricochets) > 0:
				var remaining := float(shot.remaining) - first_contact
				var bounce := _bounce_direction(enemies, impact, hit_ids, remaining)
				if not bounce.is_zero_approx():
					shot.ricochets -= 1
					shot.hits = maxi(1, shot.hits)
					shot.direction = bounce
					travel = first_contact
					break
		shot.pos = start + direction * travel
		shot.remaining -= travel
		shot.traveled += travel
		if shot.remaining <= 0.0 or shot.hits <= 0:
			shots.remove_at(i)


static func _bounce_direction(enemies: Array[Dictionary], impact: Vector2, hit_ids: Dictionary, remaining: float) -> Vector2:
	var closest := Vector2.ZERO
	var limit := remaining * remaining
	for enemy in enemies:
		if float(enemy.hp) <= 0.0 or enemy.get("underground", false) or hit_ids.has(enemy.spawn_id):
			continue
		var offset: Vector2 = enemy.pos - impact
		var distance := offset.length_squared()
		if distance > 0.0 and distance <= limit:
			limit = distance
			closest = offset
	return closest.normalized()


static func enemy_radius(enemy: Dictionary) -> float:
	if enemy.boss:
		return 44.0
	if enemy.has("variant"):
		return ZombieVisual.RADIUS * float(enemy.get("art_scale", 1.0))
	return 15.0 if enemy.kind == "brute" else 12.0
