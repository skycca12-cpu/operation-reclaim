extends RefCounted

const SPEED := 1150.0

var shots: Array[Dictionary] = []


func fire(origin: Vector2, direction: Vector2, distance: float, damage: float, hits: int, color: Color) -> void:
	shots.append({
		"pos": origin, "direction": direction, "remaining": distance,
		"damage": damage, "hits": hits, "color": color, "hit_ids": {},
	})


func update(delta: float, enemies: Array[Dictionary], damage_enemy: Callable) -> void:
	for i in range(shots.size() - 1, -1, -1):
		var shot := shots[i]
		var travel := minf(SPEED * delta, shot.remaining)
		var start: Vector2 = shot.pos
		var direction: Vector2 = shot.direction
		var hit_ids: Dictionary = shot.hit_ids
		while shot.hits > 0:
			var closest := -1
			var first_contact := INF
			for j in range(enemies.size()):
				var enemy := enemies[j]
				if enemy.hp <= 0.0 or hit_ids.has(enemy.spawn_id):
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
					closest = j
					first_contact = entry
			if closest < 0:
				break
			hit_ids[enemies[closest].spawn_id] = true
			shot.hits -= 1
			damage_enemy.call(closest, shot.damage, "player")
		shot.pos = start + direction * travel
		shot.remaining -= travel
		if shot.remaining <= 0.0 or shot.hits <= 0:
			shots.remove_at(i)


static func enemy_radius(enemy: Dictionary) -> float:
	if enemy.boss:
		return 34.0
	return 15.0 if enemy.kind == "brute" else 12.0
