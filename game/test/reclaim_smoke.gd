extends SceneTree

const Data = preload("res://scripts/reclaim/data.gd")
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	_check(packed != null, "main scene resource loads")
	if packed == null:
		_finish()
		return
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	_check(game.get("screen") == "boot", "game opens on the loading screen")
	game.call("_finish_boot")
	_check(game.get("screen") == "menu", "loading screen hands over to the main menu")
	game.call("_choose_character", 2)
	_check(game.get("screen") == "difficulty", "character choice opens difficulty selection")
	game.call("_choose_difficulty", 4)
	_check(game.get("screen") == "intro" and game.get("difficulty_index") == 4, "difficulty choice opens the prologue")
	_check(Data.CHARACTERS.size() == 4, "four selectable operators in data")
	_check(Data.ENEMIES.size() == 5, "five enemy families in data")
	_check(Data.TURRETS.size() == 7, "seven turret families in data")
	_check(Data.augment_catalog().size() == 50, "30 common and 20 hero augments in data")
	game.set("player_index", 1)
	game.set("difficulty_index", 1)
	game.call("_start_new_run")
	await process_frame
	_check(game.get("screen") == "landing", "new run starts with the landing cut")
	game.call("skip_landing")
	await process_frame
	var structures: Array = game.get("structures")
	_check(game.get("screen") == "play", "new run enters playable screen")
	_check(structures.size() == 1 and structures[0].kind == "hq", "run begins with the HQ tent only")
	_check(game.get("stage") == 1, "new run starts at stage one")
	var before_x: float = (game.get("player_pos") as Vector2).x
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_D
	ev.keycode = KEY_D
	ev.pressed = true
	Input.parse_input_event(ev)
	for _i in range(10): await process_frame
	var ev_up := ev.duplicate()
	ev_up.pressed = false
	Input.parse_input_event(ev_up)
	await process_frame
	_check((game.get("player_pos") as Vector2).x > before_x + 1.0, "holding D moves the player (WASD regression)")
	_check(String(game.call("_validate_placement", "wall", Vector2i(3, 0))) != "", "north entrance remains permanently open")
	_check(String(game.call("_validate_placement", "wall", Vector2i(3, 2))) != "", "a wall cannot block the north escape route")
	_check(String(game.call("_validate_placement", "clinic", Vector2i(6, 4))) != "", "two-cell building stays within the seven-by-seven area")
	_check(String(game.call("_validate_placement", "basic", Vector2i(6, 6))) == "", "valid one-cell turret placement is accepted")
	game.call("_select_build", "basic")
	game.call("_try_place_at", game.call("_cell_world", Vector2i(6, 6)))
	structures = game.get("structures")
	_check(structures.size() == 2 and structures[1].kind == "basic", "player-built turret is installed")
	_check(String(game.call("_validate_placement", "clinic", Vector2i(1, 1))) == "", "first unique facility can be installed")
	game.call("_select_build", "clinic")
	game.call("_try_place_at", game.call("_cell_world", Vector2i(1, 1)))
	_check(String(game.call("_validate_placement", "clinic", Vector2i(1, 4))) != "", "facility types are limited to one each")
	game.set("player_pos", game.call("_cell_world", Vector2i(2, 3)))
	game.call("_move_player", Vector2(80, 0))
	_check((game.get("player_pos") as Vector2).x < 0.0, "player collides with HQ footprint")
	for i in range(5):
		structures.append({"kind": "heavy", "cell": Vector2i(i, 0), "hp": 100.0, "max_hp": 100.0, "level": 1, "cool": 0.0})
	game.set("money", 500)
	game.set("player_index", 1)
	_check(String(game.call("_validate_placement", "rocket", Vector2i(0, 6))).contains("한도"), "ordinary operator cap is six total turrets")
	game.set("player_index", 3)
	_check(String(game.call("_validate_placement", "rocket", Vector2i(0, 6))) == "", "Han Yujin can place up to eight turrets")
	game.set("player_index", 1)
	game.set("player_pos", Vector2(200, 150))
	game.set("player_facing", Vector2.RIGHT)
	game.set("aim_screen", Vector2(game.size.x * 0.5 + 150.0, game.size.y * 0.5))
	var enemies: Array = game.get("enemies")
	var target: Dictionary = game.call("_make_enemy", "normal", game.get("player_pos") + Vector2(120, 0), false)
	enemies.append(target)
	var old_hp: float = target.hp
	game.call("_attack_player")
	_check(target.hp < old_hp, "automatic rifle attack reduces a targeted enemy's health")
	enemies.clear()
	var player_pos: Vector2 = game.get("player_pos")
	var zombie := _spawn_test_zombie(game, player_pos + Vector2(120, 0), 1.0)
	var kills_before: int = game.get("kills")
	var effects: Array = game.get("effects")
	var effects_before := effects.size()
	var zombie_pos: Vector2 = zombie.pos
	game.call("_attack_player")
	_check(enemies.is_empty() and game.get("kills") == kills_before + 1, "last zombie is removed and credited")
	_check(effects.size() == effects_before + 1 and effects.back().b == zombie_pos, "lethal rifle shot draws its tracer to the removed zombie")

	var decoy := _spawn_test_zombie(game, player_pos + Vector2(0, 120), 100.0)
	_spawn_test_zombie(game, player_pos + Vector2(100, 0), 1.0)
	var rear := _spawn_test_zombie(game, player_pos + Vector2(180, 0), 100.0)
	game.set("player_pierce", 1)
	game.call("_attack_player")
	_check(enemies.size() == 2 and rear.hp < 100.0 and decoy.hp == 100.0, "piercing rifle shot hits the next zombie after a lethal hit shifts the array")
	game.set("player_pierce", 0)

	enemies.clear()
	game.set("player_index", 3)
	_spawn_test_zombie(game, player_pos + Vector2(70, 0), 1.0)
	effects_before = effects.size()
	game.call("_attack_player")
	_check(enemies.is_empty() and effects.size() == effects_before + 1 and effects.back().b == player_pos + Vector2(70, 0), "lethal chainsaw hit draws its effect to the removed zombie")

	game.set("player_index", 2)
	game.set("player_drone_level", 1)
	game.set("drone_timer", 0.0)
	_spawn_test_zombie(game, player_pos + Vector2(120, 0), 1.0)
	effects_before = effects.size()
	game.call("_update_player", 0.01)
	_check(enemies.is_empty() and effects.size() == effects_before + 1 and effects.back().b == player_pos + Vector2(120, 0), "lethal drone hit draws its effect to the removed zombie")
	game.set("player_drone_level", 0)
	game.set("player_index", 1)

	var pursuer := _spawn_test_zombie(game, player_pos + Vector2(120, 0), 100.0)
	var distance_before: float = pursuer.pos.distance_to(player_pos)
	game.call("_update_enemies", 0.1)
	_check(pursuer.target == "player" and pursuer.pos.distance_to(player_pos) < distance_before, "normal zombie targets and approaches the player")
	pursuer.pos = player_pos + Vector2(25, 0)
	pursuer.cool = 0.0
	var health_before: float = game.get("player_hp")
	game.call("_update_enemies", 0.1)
	_check(game.get("player_hp") < health_before, "normal zombie damages the player in melee range")
	enemies.clear()
	game.set("stage_elapsed", 21.95)
	game.call("_update_spawn", 0.1)
	_check(game.get("stage") == 2, "wave stage advances on elapsed time")
	game.call("_toggle_pause")
	_check(game.get("screen") == "pause", "pause overlay opens")
	game.call("_close_pause")
	_check(game.get("screen") == "play", "pause overlay resumes the run")
	_check(Data.BOSSES.has(40) and Data.BOSSES.has(80) and Data.BOSSES.has(100), "boss data includes stages 40, 80 and 100")
	game.queue_free()
	await process_frame
	_finish()


func _spawn_test_zombie(game: Node, position: Vector2, hp: float) -> Dictionary:
	var enemies: Array = game.get("enemies")
	var zombie: Dictionary = game.call("_make_enemy", "normal", position, false)
	zombie.hp = hp
	enemies.append(zombie)
	return zombie


func _check(condition: bool, context: String) -> void:
	if not condition and context not in failures:
		failures.append(context)


func _finish() -> void:
	if failures.is_empty():
		print("[reclaim-tests] PASS: boot, roster, enemies, augments, HQ-only start, construction rules, collision, turret caps, lethal combat, zombie AI, timed stages and pause")
		quit(0)
	else:
		for failure in failures: push_error("[reclaim-tests] " + failure)
		quit(1)
