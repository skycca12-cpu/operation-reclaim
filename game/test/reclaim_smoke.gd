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
	var enemies: Array = game.get("enemies")
	var player_pos: Vector2 = game.get("player_pos")
	var projectiles: RefCounted = game.get("player_projectiles")
	_test_attack_modes(game, player_pos)
	game.set("player_facing", Vector2.RIGHT)
	var effects: Array = game.get("effects")
	var effects_before: int
	enemies.clear()
	projectiles.shots.clear()
	game.set("player_magazine", 30)
	var decoy := _spawn_test_zombie(game, player_pos + Vector2(0, 120), 100.0)
	_spawn_test_zombie(game, player_pos + Vector2(100, 0), 1.0)
	var rear := _spawn_test_zombie(game, player_pos + Vector2(180, 0), 100.0)
	game.set("player_pierce", 1)
	game.call("_attack_player")
	_step_projectiles(game, 0.25)
	_check(enemies.size() == 2 and rear.hp < 100.0 and decoy.hp == 100.0, "piercing projectile hits the next zombie after the first is removed")
	var rear_hp: float = rear.hp
	_step_projectiles(game, 0.25)
	_check(rear.hp == rear_hp, "a projectile cannot damage the same zombie twice")
	game.set("player_pierce", 0)

	enemies.clear()
	game.set("player_index", 3)
	_spawn_test_zombie(game, player_pos + Vector2(70, 0), 1.0)
	effects_before = effects.size()
	game.call("_attack_player")
	_check(enemies.is_empty() and effects.size() == effects_before + 1 and effects.back().b == player_pos + Vector2(70, 0), "lethal chainsaw hit draws its effect to the removed zombie")

	game.set("player_index", 2)
	game.set("player_attack_timer", 1.0)
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


func _test_attack_modes(game: Control, origin: Vector2) -> void:
	var enemies: Array = game.get("enemies")
	var projectiles: RefCounted = game.get("player_projectiles")
	enemies.clear()
	projectiles.shots.clear()
	game.set("player_attack_timer", 0.0)
	var distant := _spawn_test_zombie(game, origin + Vector2(600, 0), 100.0)
	var dead := _spawn_test_zombie(game, origin + Vector2(20, 0), 0.0)
	game.call("_update_player_attack", 0.01)
	_check(projectiles.shots.is_empty() and game.get("player_magazine") == 30, "automatic mode rejects dead and out-of-range enemies")
	enemies.erase(dead)
	var kills_before: int = game.get("kills")
	var next := _spawn_test_zombie(game, origin + Vector2(-180, -80), 100.0)
	var diagonal := Vector2(70, 45)
	_spawn_test_zombie(game, origin + diagonal, 1.0)
	game.call("_update_player_attack", 0.01)
	_check(projectiles.shots.size() == 1 and game.get("player_facing").is_equal_approx(diagonal.normalized()), "automatic mode fires toward the nearest live zombie without a click")
	_check(game.get("kills") == kills_before, "a projectile must travel before dealing damage")
	_step_projectiles(game, 0.2)
	_check(game.get("kills") == kills_before + 1 and enemies.size() == 2, "automatic shot safely removes a lethal target")
	game.call("_update_player_attack", 0.2)
	_step_projectiles(game, 0.25)
	_check(next.hp < 100.0 and distant.hp == 100.0, "automatic mode retargets after a kill")
	next.pos = origin + Vector2(650, 0)
	game.set("player_magazine", 1)
	var last := _spawn_test_zombie(game, origin + Vector2(0, -120), 1.0)
	game.call("_update_player_attack", 0.2)
	_check(game.get("player_magazine") == 0 and game.get("player_reload_timer") > 0.0, "automatic mode starts reloading on the final round")
	_step_projectiles(game, 0.2)
	_check(not enemies.has(last) and distant.hp == 100.0, "automatic mode ignores a previous target that moved out of range")
	next.pos = origin + Vector2(0, 120)
	game.call("_update_player_attack", 1.8)
	_check(game.get("player_magazine") == 29 and projectiles.shots.size() == 1, "automatic mode resumes after reload")
	_step_projectiles(game, 0.25)
	enemies.clear()
	_spawn_test_zombie(game, origin + Vector2(120, 0), 1.0)
	game.call("_update_player_attack", 0.2)
	_step_projectiles(game, 0.2)
	_check(enemies.is_empty() and game.get("kills") == kills_before + 3, "last zombie is removed and credited without an array error")

	var tab := InputEventKey.new()
	tab.keycode = KEY_TAB
	tab.pressed = true
	root.push_input(tab.duplicate(), true)
	tab.echo = true
	root.push_input(tab.duplicate(), true)
	_check(game.get("manual_attack"), "Tab changes mode once despite key repeat")
	var aim := game.size * 0.5 + Vector2(-165, 76)
	var motion := InputEventMouseMotion.new()
	motion.position = aim
	root.push_input(motion.duplicate(), true)
	game.call("_update_player_attack", 0.2)
	_check(projectiles.shots.is_empty() and game.get("player_facing").is_equal_approx(Vector2(-165, 76).normalized()), "manual mode tracks mouse without firing")
	var hq_on_screen: Vector2 = game.call("_world_to_screen", game.call("_hq_position"))
	_press_fire(hq_on_screen, true)
	game.call("_update_player_attack", 0.01)
	_check(projectiles.shots.size() == 1 and game.get("selected_entity") == -1, "manual firing over a structure does not open its inspector")
	game.call("_update_player_attack", 0.2)
	_check(projectiles.shots.size() == 2, "holding manual fire repeats after weapon cooldown")
	_press_fire(aim, false)
	game.call("_update_player_attack", 0.2)
	_check(projectiles.shots.size() == 2, "releasing manual fire stops new shots")
	_step_projectiles(game, 1.0)
	_check(projectiles.shots.is_empty(), "missed projectiles expire at maximum range")

	_press_fire(aim, true)
	for octant in range(8):
		var direction := Vector2.from_angle(TAU * (float(octant) + 0.18) / 8.0)
		motion.position = game.size * 0.5 + direction * 120.0
		root.push_input(motion.duplicate(), true)
		game.call("_update_player_attack", 0.2)
		_check(not projectiles.shots.is_empty() and projectiles.shots.back().direction.is_equal_approx(direction), "manual shot preserves continuous angle in octant %d" % octant)
		_step_projectiles(game, 1.0)
	game.set("player_magazine", 1)
	game.call("_update_player_attack", 0.2)
	_check(game.get("player_reload_timer") > 0.0, "manual final round starts automatic reload")
	game.call("_update_player_attack", 1.8)
	_check(game.get("player_magazine") == 29, "manual fire resumes if held through reload")
	game.set("player_magazine", 1)
	game.call("_update_player_attack", 0.2)
	_press_fire(aim, false)
	game.call("_update_player_attack", 1.8)
	game.call("_refresh_hud")
	_check(game.get("player_magazine") == 30 and game.get("combat_label").text.contains("수동 [Tab]  ·  탄약 30 / 30"), "released trigger reloads without firing and HUD shows mode and ammo")

	# A build placement press must not start manual fire.
	game.set("build_mode", true)
	_press_fire(aim, true)
	game.call("_update_player_attack", 0.2)
	_check(game.get("player_magazine") == 30, "construction click does not shoot")
	_press_fire(aim, false)
	game.set("build_mode", false)

	var move := InputEventKey.new()
	move.physical_keycode = KEY_D
	move.pressed = true
	Input.parse_input_event(move.duplicate())
	Input.flush_buffered_events()
	_press_fire(aim, true)
	game.call("_try_dash")
	game.call("_update_player", 0.05)
	var dash_position: Vector2 = game.get("player_pos")
	_check(dash_position.x > origin.x and is_equal_approx(dash_position.y, origin.y) and game.get("player_magazine") == 29, "dash follows movement input while firing toward the cursor")
	move.pressed = false
	Input.parse_input_event(move.duplicate())
	Input.flush_buffered_events()
	_press_fire(aim, false)
	tab.echo = false
	root.push_input(tab.duplicate(), true)
	_check(not game.get("manual_attack"), "Tab switches back to automatic")
	game.set("dash_timer", 0.0)
	game.set("player_pos", origin)


func _step_projectiles(game: Node, delta: float) -> void:
	game.get("player_projectiles").update(delta, game.get("enemies"), Callable(game, "_damage_enemy"))


func _press_fire(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	root.push_input(event, true)


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
		print("[reclaim-tests] PASS: boot, roster, enemies, augments, HQ-only start, construction rules, collision, turret caps, combat modes, 360-degree projectiles, reload, lethal combat, zombie AI, timed stages and pause")
		quit(0)
	else:
		for failure in failures: push_error("[reclaim-tests] " + failure)
		quit(1)
