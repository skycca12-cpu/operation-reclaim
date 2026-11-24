extends SceneTree

const Catalog = preload("res://scripts/reclaim/augment_catalog.gd")
const Data = preload("res://scripts/reclaim/data.gd")
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Control = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	var cards: Dictionary = {}
	for card in Catalog.cards():
		cards[card.id] = card
	for card in cards.values():
		var hero := 0
		for i in range(Data.CHARACTERS.size()):
			if Data.CHARACTERS[i].id == card.hero:
				hero = i
		game.set("player_index", hero)
		game.call("_reset_run")
		game.call("_show_screen", "play")
		game.set("repair_drone_level", 1)
		var structures: Array = game.get("structures")
		for kind in ["basic", "heavy", "rocket", "electric", "flame", "freeze", "aa", "clinic", "supply"]:
			structures.append({"kind": kind, "cell": Vector2i(1, 1), "hp": 1.0, "max_hp": 1.0, "level": 1})
		var acquired: Dictionary = game.get("acquired_augments")
		var candidate: bool = not String(card.key).is_empty()
		var gates := _eligible(game, card) == (candidate and String(card.requires).is_empty())
		if card.requires != "":
			var prerequisite: Dictionary = cards[card.requires].duplicate()
			prerequisite.count = card.required_count
			acquired[card.requires] = prerequisite
		gates = gates and _eligible(game, card) == candidate
		if card.hero != "":
			game.set("player_index", (hero + 1) % Data.CHARACTERS.size())
			gates = gates and not _eligible(game, card)
			game.set("player_index", hero)
		if candidate:
			var maxed: Dictionary = card.duplicate()
			maxed.count = card.limit
			acquired[card.id] = maxed
			gates = gates and not _eligible(game, card)
			acquired.erase(card.id)
		gates = gates and card.rarity == Catalog.RARITIES[int(card.stars) - 1]
		var effect := "not_run"
		if String(card.key) in ["hp", "ricochet", "pellet_focus"] and candidate:
			effect = "pass" if _test_effect(game, card) else "fail"
		print("AUGMENT_AUDIT ", JSON.stringify({"id": card.id, "candidate": candidate, "gates": gates, "effect": effect}))
		if not gates or effect == "fail":
			failures += 1
	game.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)


func _eligible(game: Control, card: Dictionary) -> bool:
	return game.call("_eligible_augments").has(card)


func _test_effect(game: Control, card: Dictionary) -> bool:
	game.call("_rebuild_csv_stats")
	var base_hp: float = game.call("_effective_player_max_hp")
	var base_stat: float = game.call("_csv_bonus", card.key)
	var projectiles = game.get("player_projectiles")
	game.set("player_facing", Vector2.RIGHT)
	game.call("_attack_player")
	var base_heading: Vector2 = projectiles.shots[0].direction
	projectiles.shots.clear()

	game.call("_choose_csv_augment", card)
	if card.key == "hp":
		var max_hp: float = game.call("_effective_player_max_hp")
		var hero_index: int = game.get("player_index")
		var increment := float(Data.CHARACTERS[hero_index].hp) * float(card.amount) / 100.0
		if card.trigger == "":
			return is_equal_approx(max_hp, base_hp + increment)
		game.call("_attack_player")
		var active: float = game.call("_effective_player_max_hp")
		game.set("run_seconds", 4.0)
		game.call("_attack_player")
		game.set("run_seconds", 5.0)
		var renewed: float = game.call("_effective_player_max_hp")
		game.set("run_seconds", 9.0)
		return is_equal_approx(max_hp, base_hp) and is_equal_approx(active, base_hp + increment) and is_equal_approx(renewed, active) and is_equal_approx(float(game.call("_effective_player_max_hp")), base_hp)

	game.call("_attack_player")
	if card.key == "pellet_focus":
		return absf(projectiles.shots[0].direction.angle()) < absf(base_heading.angle())

	var shot: Dictionary = projectiles.shots[0]
	if int(shot.ricochets) != int(base_stat + float(card.amount)):
		return false
	projectiles.shots.resize(1)
	var origin: Vector2 = shot.pos
	var direction: Vector2 = shot.direction
	var enemies: Array[Dictionary] = game.get("enemies")
	enemies.append(game.call("_make_enemy", "normal", origin + direction * 40.0, false))
	enemies.append(game.call("_make_enemy", "normal", origin + direction * 40.0 + direction.orthogonal() * 55.0, false))
	var first_hp: float = enemies[0].hp
	var second_hp: float = enemies[1].hp
	var hit := Callable(game, "_damage_enemy")
	projectiles.update(0.06, enemies, hit)
	var first_hit := float(enemies[0].hp) < first_hp and float(enemies[1].hp) == second_hp
	projectiles.update(0.12, enemies, hit)
	return first_hit and float(enemies[1].hp) < second_hp
