extends SceneTree

const ZombieVisual = preload("res://scripts/reclaim/zombie_visual.gd")
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
	_test_main_menu(game)
	game.call("_choose_character", 2)
	_check(game.get("screen") == "difficulty", "character choice opens difficulty selection")
	game.call("_choose_difficulty", 4)
	_check(game.get("screen") == "intro" and game.get("difficulty_index") == 4, "difficulty choice opens the prologue")
	_check(Data.CHARACTERS.size() == 4, "four selectable operators in data")
	_check(Data.ENEMIES.size() == 5, "five enemy families in data")
	_check(Data.TURRETS.size() == 7, "seven turret families in data")
	_check(Data.augment_catalog().size() == 52, "30 common and 22 hero augments in data")
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
	_check(String(game.call("_validate_placement", "wall", Vector2i(3, -1))) != "", "north entrance remains permanently open")
	_check(String(game.call("_validate_placement", "wall", Vector2i(3, 2))) != "", "a wall cannot block the north escape route")
	_check(String(game.call("_validate_placement", "clinic", Vector2i(7, 4))) != "", "two-cell building stays within the nine-by-nine area")
	_check(String(game.call("_validate_placement", "basic", Vector2i(7, 7))) == "", "outer expansion ring accepts a one-cell turret")
	var build_key := InputEventKey.new()
	build_key.physical_keycode = KEY_1
	build_key.keycode = KEY_1
	build_key.pressed = true
	root.push_input(build_key.duplicate(), true)
	_check(game.get("selected_build") == "basic", "1 selects a turret with the construction panel closed")
	game.call("_try_place_at", game.call("_cell_world", Vector2i(7, 7)))
	structures = game.get("structures")
	_check(structures.size() == 2 and structures[1].kind == "basic", "player-built turret is installed")
	_check(String(game.call("_validate_placement", "clinic", Vector2i(1, 1))) == "", "first unique facility can be installed")
	build_key.physical_keycode = KEY_F1
	build_key.keycode = KEY_F1
	root.push_input(build_key.duplicate(), true)
	_check(game.get("selected_build") == "clinic", "F1 selects a facility")
	game.call("_try_place_at", game.call("_cell_world", Vector2i(1, 1)))
	var supply_before: int = game.get("money")
	game.set("money", 200)
	game.call("_select_entity_at", game.call("_cell_world", Vector2i(7, 7)))
	build_key.physical_keycode = KEY_U
	build_key.keycode = KEY_U
	root.push_input(build_key.duplicate(), true)
	_check(structures[1].level == 2, "U upgrades the selected turret")
	game.set("money", supply_before)
	game.call("_close_inspector")
	build_key.physical_keycode = KEY_8
	build_key.keycode = KEY_8
	root.push_input(build_key.duplicate(), true)
	_check(game.get("selected_build") == "wall", "8 selects a wall")
	game.call("_cancel_build")
	_check(String(game.call("_validate_placement", "clinic", Vector2i(1, 4))) != "", "facility types are limited to one each")
	game.set("player_pos", game.call("_cell_world", Vector2i(2, 3)))
	game.call("_move_player", Vector2(80, 0))
	_check((game.get("player_pos") as Vector2).x < 0.0, "player collides with HQ footprint")
	var trap_cell := Vector2i(1, 4)
	var trap_center: Vector2 = game.call("_cell_world", trap_cell)
	game.set("player_pos", trap_center)
	_check(String(game.call("_validate_placement", "wall", trap_cell)).contains("대원") and
		String(game.call("_validate_placement", "supply", Vector2i(0, 4))).contains("대원"),
		"walls and two-cell facilities cannot be placed across the player")
	structures.append({"kind": "wall", "cell": trap_cell, "hp": 100.0})
	for step in range(10):
		game.call("_move_player", Vector2(4, 0))
	_check(game.get("player_pos").x > trap_center.x + 37.0, "player can walk out of a legacy overlapping structure")
	structures.pop_back()
	_test_combat_zoom_and_augments(game)
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
	effects_before = effects.filter(func(effect): return not effect.has("hit_angle")).size()
	game.call("_attack_player")
	_check(enemies.is_empty() and effects.filter(func(effect): return not effect.has("hit_angle")).size() == effects_before + 1 and effects.back().b == player_pos + Vector2(70, 0), "lethal chainsaw hit draws its effect to the removed zombie")

	game.set("player_index", 2)
	game.set("player_attack_timer", 1.0)
	game.set("player_drone_level", 1)
	game.set("drone_timer", 0.0)
	_spawn_test_zombie(game, player_pos + Vector2(120, 0), 1.0)
	effects_before = effects.filter(func(effect): return not effect.has("hit_angle")).size()
	game.call("_update_player", 0.01)
	_check(enemies.is_empty() and effects.filter(func(effect): return not effect.has("hit_angle")).size() == effects_before + 1 and effects.back().b == player_pos + Vector2(120, 0), "lethal drone hit draws its effect to the removed zombie")
	game.set("player_drone_level", 0)
	game.set("player_index", 1)

	var pursuer := _spawn_test_zombie(game, player_pos + Vector2(120, 0), 100.0)
	var distance_before: float = pursuer.pos.distance_to(player_pos)
	game.call("_update_enemies", 0.1)
	_check(pursuer.target == "player" and pursuer.moving and pursuer.pos.distance_to(player_pos) < distance_before, "normal zombie targets and approaches the player")
	pursuer.pos = player_pos + Vector2(25, 0)
	pursuer.cool = 0.0
	var health_before: float = game.get("player_hp")
	game.call("_update_enemies", 0.1)
	_check(game.get("player_hp") == health_before, "the raise phase does not inflict damage")
	game.call("_update_enemies", ZombieVisual.IMPACT_TIME)
	_check(game.get("player_hp") < health_before and pursuer.attack_until > game.get("run_seconds") and pursuer.attack_direction.is_equal_approx(Vector2.LEFT), "normal zombie damages the player and starts its attack animation")
	var saved_player_pos: Vector2 = game.get("player_pos")
	pursuer.cool = 0.0
	game.call("_update_enemies", 0.01)
	var before_dodge: float = game.get("player_hp")
	game.set("player_pos", saved_player_pos + Vector2(-80.0, 0.0))
	game.call("_update_enemies", ZombieVisual.IMPACT_TIME)
	_check(game.get("player_hp") == before_dodge, "stepping out of reach before impact makes the swing miss")
	game.set("player_pos", saved_player_pos)
	_test_normal_zombies(game, pursuer)
	enemies.clear()
	_test_structure_targets(game)
	enemies.clear()
	game.set("stage_elapsed", 21.95)
	game.call("_update_spawn", 0.1)
	_check(game.get("stage") == 2, "wave stage advances on elapsed time")
	_test_first_enemy_warning(game)
	_test_operator_hud(game)
	game.call("_toggle_pause")
	_check(game.get("screen") == "pause", "pause overlay opens")
	var time_at_pause: float = game.get("run_seconds")
	game.call("_show_settings", true)
	_check(game.get("screen") == "settings" and game.get("settings_from_pause"), "settings are available during pause")
	await process_frame
	_check(game.get("run_seconds") == time_at_pause, "combat stays paused while adjusting settings")
	game.call("_close_settings")
	_check(game.get("screen") == "pause", "closing in-game settings returns to pause")
	game.call("_close_pause")
	_check(game.get("screen") == "play", "pause overlay resumes the run")
	_check(Data.BOSSES.has(40) and Data.BOSSES.has(80) and Data.BOSSES.has(100), "boss data includes stages 40, 80 and 100")
	# Save mid-reload, then instantiate a fresh game to verify the disk round trip.
	game.set("manual_attack", true)
	game.set("player_magazine", 0)
	game.set("player_reload_timer", 0.8)
	var saved_position: Vector2 = game.get("player_pos")
	var saved_structure_count := structures.size()
	enemies.clear()
	var saved_zombie := _spawn_test_zombie(game, saved_position + Vector2(300, 0), 100.0)
	var saved_variant: int = saved_zombie.variant
	var saved_base: Dictionary = game.get("run_base_stats")
	game.call("_save_all")
	game.queue_free()
	await process_frame
	var resumed := packed.instantiate()
	root.add_child(resumed)
	resumed.call("_on_menu_continue")
	_check(resumed.get("screen") == "play" and resumed.get("stage") == 2, "continue restores the saved wave from disk")
	_check(resumed.get("player_pos").is_equal_approx(saved_position) and resumed.get("structures").size() == saved_structure_count, "continue restores player position and built structures")
	_check(resumed.get("manual_attack") and resumed.get("player_magazine") == 0 and is_equal_approx(resumed.get("player_reload_timer"), 0.8), "continue preserves manual mode and reload progress")
	var resumed_enemies: Array = resumed.get("enemies")
	_check(resumed_enemies.size() == 1 and resumed_enemies[0].variant == saved_variant, "continue restores the saved zombie appearance")
	_check(resumed.get("warned_enemies").has("boss40"), "continue remembers enemy types already announced")
	var restored_augments: Dictionary = resumed.get("acquired_augments")
	_check(restored_augments.size() == 1 and restored_augments.values()[0].stars == 5, "continue retains acquired rarity and stars")
	_check(resumed.get("run_base_stats") == saved_base, "continue retains the stat baseline")
	_check(not resumed.get("manual_trigger"), "continue requires a fresh manual trigger press")
	resumed.call("_update_player_attack", 0.9)
	_check(resumed.get("player_magazine") == 30 and resumed.get("player_projectiles").shots.is_empty(), "continued reload finishes without an unintended shot")
	resumed.set("saved_run", {"hero": 0})
	resumed.call("_load_saved_run")
	_check(not resumed.get("manual_attack") and resumed.get("player_magazine") == 6 and resumed.get("player_reload_timer") == 0.0, "legacy saves default to automatic mode and a full magazine")
	# Allow the 350 ms Continue cue to finish before freeing the scene.
	resumed.set_process(false)
	await create_timer(0.45).timeout
	_test_yujin(resumed)
	_test_spawn_multiplier(resumed)
	_test_character_augments(resumed)
	resumed.queue_free()
	await process_frame
	_finish()


func _test_character_augments(game: Control) -> void:
	game.set("player_index", 3)
	game.call("_reset_run")
	var options: Array = game.call("_eligible_augments")
	_check(options.any(func(card): return card.get("hero") == "yujin") and not options.any(func(card): return card.get("hero") == "harin"),
		"Yujin receives her own exclusive options without Harin cards")
	for card in options:
		if card.id == Data.YUJIN_REACH_AUGMENT:
			var reach: float = game.call("_weapon_range", Data.CHARACTERS[3])
			card.stars = 1
			game.call("_choose_augment", card)
			var upgraded: float = game.call("_weapon_range", Data.CHARACTERS[3])
			_check(is_equal_approx(upgraded, reach + 12.0) and is_equal_approx(game.get("player_mod_range"), 1.0),
				"Yujin extends the chainsaw without changing the turret range multiplier")
			break
	game.set("player_index", 2)
	game.call("_reset_run")
	options = game.call("_eligible_augments")
	var index := -1
	for i in range(options.size()):
		if options[i].id == Data.HARIN_MAGAZINE_AUGMENT:
			index = i
			break
	_check(index >= 0 and not options.any(func(card): return card.get("hero") == "yujin"), "Harin can find the exclusive magazine")
	if index < 0:
		return
	var magazine: Dictionary = options[index].duplicate()
	magazine.stars = 1
	magazine.rarity = "일반"
	for stack in range(1, 6):
		var preview: String = game.call("_augment_effect_text", magazine)
		_check(preview.contains("중첩 %d/5" % stack), "magazine displays its upcoming stack")
		game.call("_choose_augment", magazine)
		_check(game.call("_magazine_capacity") == 30 + stack * 5, "each magazine stack grants exactly five rounds")
	game.call("_choose_augment", magazine)
	options = game.call("_eligible_augments")
	_check(game.call("_magazine_capacity") == 55 and not options.any(func(card): return card.id == Data.HARIN_MAGAZINE_AUGMENT),
		"magazine caps at five stacks and disappears from future offers")
	game.set("manual_attack", true)
	game.set("manual_trigger", false)
	game.set("player_magazine", 0)
	game.set("player_reload_timer", 0.1)
	game.call("_update_player_attack", 0.2)
	_check(game.get("player_magazine") == 55, "reloading fills the upgraded magazine")
	game.call("_save_all")
	game.call("_load_saved_run")
	_check(game.call("_magazine_capacity") == 55 and game.get("player_magazine") == 55, "save and continue preserve the upgraded magazine")


func _test_spawn_multiplier(game: Control) -> void:
	var previous_interval := INF
	for index in range(Data.DIFFICULTIES.size()):
		game.set("difficulty_index", index)
		game.call("_reset_run")
		game.set("spawn_timer", 0.0)
		game.call("_update_spawn", 0.0)
		var enemies: Array = game.get("enemies")
		var interval: float = game.get("spawn_timer")
		_check(enemies.size() == 5, "difficulty %d spawns five enemies per early wave batch" % index)
		_check(interval < previous_interval, "difficulty %d preserves spawn interval ordering" % index)
		previous_interval = interval
	var active: Array = game.get("enemies")
	for i in range(70):
		game.set("spawn_timer", 0.0)
		game.call("_update_spawn", 0.0)
	_check(active.size() == 320, "larger wave batches respect the active enemy cap")


func _test_yujin(game: Control) -> void:
	game.set("player_index", 3)
	game.call("_reset_run")
	game.set("player_facing", Vector2.RIGHT)
	var origin: Vector2 = game.get("player_pos")
	game.call("_spawn_enemy", "normal", origin + Vector2(52, 0), false)
	game.call("_spawn_enemy", "normal", origin - Vector2(52, 0), false)
	var enemies: Array = game.get("enemies")
	var front_hp := float(enemies[0].hp)
	var back_hp := float(enemies[1].hp)
	game.call("_attack_player")
	var visual: RefCounted = game.get("_yujin_visual")
	_check(float(enemies[0].hp) < front_hp and is_equal_approx(float(enemies[1].hp), back_hp),
		"Yujin's chainsaw preserves forward-only melee damage")
	_check(float(visual.get("_attack_left")) > 0.0, "the real melee attack starts Yujin's cutting animation")
	visual.call("update", 1.0)
	_check(is_zero_approx(float(visual.get("_attack_left"))), "Yujin returns to idle after cutting ends")


func _test_operator_hud(game: Control) -> void:
	var card: Dictionary = Data.augment_catalog()[0].duplicate()
	card.rarity = "고급"
	card.stars = 2
	var original: Dictionary = game.call("_combat_stats")
	game.call("_choose_augment", card)
	card.stars = 5
	game.call("_choose_augment", card)
	var acquired: Dictionary = game.get("acquired_augments")
	_check(acquired.size() == 1 and acquired[card.id].stars == 5 and acquired[card.id].count == 2,
		"repeat acquisition updates the existing card, not a second card")
	var stats: Dictionary = game.call("_combat_stats")
	var paid_damage := float(original.damage) * (1.0 + 0.07 * 1.05) * (1.0 + 0.07 * 1.125)
	_check(is_equal_approx(float(stats.damage), paid_damage), "display damage equals the actual stacked weapon damage")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_C
	key.pressed = true
	root.push_input(key.duplicate(), true)
	_check(game.get("screen") == "info" and game.get("operator_info").visible, "C opens operator information")
	var before: float = game.get("run_seconds")
	game.call("_process", 0.2)
	_check(game.get("run_seconds") == before and not game.get("manual_trigger"), "operator information suspends combat and clears manual fire")
	root.push_input(key.duplicate(), true)
	_check(game.get("screen") == "play", "C closes operator information")


func _test_first_enemy_warning(game: Node) -> void:
	var panel: PanelContainer = game.get("field_warning")
	panel.call("clear")
	var warned: Dictionary = game.get("warned_enemies")
	warned.clear()
	game.call("_warn_enemy_once", "normal")
	game.call("_warn_enemy_once", "normal")
	game.call("_warn_enemy_once", "boss40")
	_check((panel.get("_pending") as Array).size() == 2, "spawn warns once per family and queues a boss independently")
	panel.call("update", 0.0, 2, "서하린")
	_check(panel.visible and panel.get("_speaker").text == "서하린" and panel.get("_portrait") != null, "warning uses the selected operator portrait and keeps playing")
	panel.call("update", 5.0, 2, "서하린")
	_check(panel.get("_line").text.contains("철갑 포식자") and game.get("screen") == "play", "boss warning follows normal warning without pausing combat")
	panel.call("update", 5.0, 2, "서하린")
	_check(not panel.visible, "field warning expires automatically")


func _test_main_menu(game: Control) -> void:
	var menu: Control = game.get("flow_menu")
	if menu == null:
		_check(false, "main menu controls are available")
		return
	var buttons: Dictionary = menu.get("buttons")
	var start: Button = buttons.start
	var settings: Button = buttons.settings
	_check(start.size.is_equal_approx(settings.size), "start and settings use identical button dimensions")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = settings.get_global_rect().get_center()
	root.push_input(click.duplicate(), true)
	_check(game.get("screen") == "menu" and menu.get("_selected") == "settings", "single click only selects the menu item")
	click.double_click = true
	root.push_input(click.duplicate(), true)
	_check(game.get("screen") == "settings", "double-click opens the selected menu item")
	game.set("dash_key", KEY_Q)
	game.set("pause_key", KEY_P)
	game.set("awaiting_binding", "dash")
	game.call("_reset_key_bindings")
	_check(game.get("dash_key") == KEY_SHIFT and game.get("pause_key") == KEY_ESCAPE and game.get("awaiting_binding") == "", "reset restores Shift and Escape and clears pending rebind")
	game.call("_close_settings")
	click.position = start.get_global_rect().get_center()
	click.double_click = false
	root.push_input(click.duplicate(), true)
	_check(game.get("screen") == "menu", "first click on start does not launch")
	click.double_click = true
	root.push_input(click.duplicate(), true)
	_check(game.get("screen") == "character", "double-click on start opens character selection")


func _test_structure_targets(game: Node) -> void:
	var enemies: Array = game.get("enemies")
	var structures: Array = game.get("structures")
	var wall_cell := Vector2i(5, 4)
	var wall_pos: Vector2 = game.call("_cell_world", wall_cell)
	structures.append({"kind": "wall", "cell": wall_cell, "hp": 100.0, "max_hp": 100.0})
	var wall: Dictionary = structures.back()
	game.set("player_pos", wall_pos + Vector2(65, 0))
	var attacker := _spawn_test_zombie(game, wall_pos + Vector2(41, 0), 100.0)
	attacker.cool = 0.0
	var health_before: float = game.get("player_hp")
	game.call("_update_enemies", 0.1)
	_check(wall.hp == 100.0, "wall is not damaged before the impact pose")
	game.call("_update_enemies", ZombieVisual.IMPACT_TIME)
	_check(attacker.target == "wall" and wall.hp < 100.0 and game.get("player_hp") == health_before, "a nearby wall takes priority over an in-reach player")
	var waiting_position: Vector2 = attacker.pos
	game.call("_update_enemies", 0.1)
	_check(attacker.pos.is_equal_approx(waiting_position), "zombie remains at a wall during attack cooldown")
	wall.hp = 0.0
	attacker.cool = 0.0
	game.call("_update_enemies", 0.1)
	_check(attacker.target == "player", "destroyed walls release the target")
	structures.pop_back()
	enemies.clear()
	var hq: Dictionary = structures[0]
	var hq_center: Vector2 = game.call("_entry_world_center", hq)
	var hq_attacker := _spawn_test_zombie(game, hq_center + Vector2(63, 0), 100.0)
	game.set("player_pos", hq_center + Vector2(510, 0))
	hq_attacker.cool = 0.0
	var hq_before: float = hq.hp
	game.call("_update_enemies", 0.1)
	game.call("_update_enemies", ZombieVisual.IMPACT_TIME)
	_check(hq.hp < hq_before, "zombie can damage the full-width HQ from the collision perimeter")
	enemies.clear()
	var facility := {"kind": "supply", "cell": Vector2i(5, 5), "hp": 100.0, "max_hp": 100.0}
	structures.append(facility)
	var facility_center: Vector2 = game.call("_entry_world_center", facility)
	var blocked := _spawn_test_zombie(game, facility_center + Vector2(65, 0), 100.0)
	game.set("player_pos", facility_center - Vector2(70, 0))
	blocked.cool = 0.0
	game.call("_update_enemies", 0.1)
	game.call("_update_enemies", ZombieVisual.IMPACT_TIME)
	_check(facility.hp < 100.0, "a facility blocking the pursuit route takes melee damage")
	structures.pop_back()


func _test_combat_zoom_and_augments(game: Control) -> void:
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	wheel.position = game.size * 0.5 + Vector2(30.0, 0.0)
	for i in range(12):
		root.push_input(wheel.duplicate(), true)
	_check(is_equal_approx(game.get("camera_zoom"), 2.4), "mouse wheel zooms the battlefield to its maximum")
	var camera_point := game.size * 0.5 + Vector2(115.2, 0)
	var world_point: Vector2 = game.call("_screen_to_world", camera_point)
	_check(world_point.is_equal_approx(game.get("player_pos") + Vector2(48.0, 0.0)), "zoomed clicks retain one-tile world accuracy")
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	for i in range(12):
		root.push_input(wheel.duplicate(), true)
	_check(is_equal_approx(game.get("camera_zoom"), 1.0), "mouse wheel returns to the original view")
	game.call("_offer_augments")
	var row := (game.get("augment_screen") as Control).find_child("AugmentCards", true, false) as HBoxContainer
	_check(row.get_child_count() == 3 and row.get_combined_minimum_size().x <= 600.0 and row.get_combined_minimum_size().x >= 560.0, "the three augment cards are enlarged but fit within a compact row")
	var reroll: Button = game.get("augment_reroll_button")
	_check(reroll.flat and reroll.size_flags_horizontal == Control.SIZE_SHRINK_CENTER, "reroll is compact instead of stretching")
	game.call("_reroll_augments")
	_check(reroll.disabled and row.get_child_count() == 3, "reroll is available exactly once and leaves three cards")
	game.call("_show_screen", "play")


func _test_normal_zombies(game: Node, enemy: Dictionary) -> void:
	var enemies: Array = game.get("enemies")
	var slot := enemies.find(enemy)
	var now: float = game.get("run_seconds")
	game.call("_update_zombie_corpses", now + ZombieVisual.DEATH_TIME)
	var bodies: Array = game.get("zombie_corpses")
	var deaths_before := bodies.size()
	var kills_before: int = game.get("kills")
	var money_before: int = game.get("money")
	game.call("_damage_enemy", slot, 1.0, "test")
	_check(enemy.hit_until > now and enemies.has(enemy), "nonlethal damage starts the hit animation")
	var hit_effects: Array = game.get("effects")
	_check(hit_effects.any(func(effect): return effect.has("hit_angle")), "visible hits emit impact sparks")
	game.call("_damage_enemy", slot, enemy.hp, "test")
	_check(not enemies.has(enemy) and game.get("kills") == kills_before + 1 and game.get("money") == money_before + 2, "death immediately removes the gameplay enemy and awards once")
	_check(bodies.size() == deaths_before + 1, "visible death creates one cosmetic corpse")
	var death_variant: int = bodies.back().variant if not bodies.is_empty() else -1
	var random: RandomNumberGenerator = game.get("_random")
	random.seed = 212
	var variants := {}
	for i in range(96):
		var zombie: Dictionary = game.call("_make_enemy", "normal", Vector2(800.0, 0.0), false)
		variants[zombie.variant] = [zombie.hp, zombie.speed, zombie.attack, zombie.reward]
	_check(variants.size() == 8 and variants.values().all(func(stats): return stats == variants.values()[0]), "eight random appearances share exactly the same normal zombie stats")
	_check(not bodies.is_empty() and bodies.back().variant == death_variant, "pool reuse cannot change a corpse visual")
	game.call("_update_zombie_corpses", now + ZombieVisual.DEATH_TIME * 0.5)
	_check(bodies.size() == deaths_before + 1, "corpse remains during its visible death frames")
	game.call("_update_zombie_corpses", now + ZombieVisual.DEATH_TIME + 0.01)
	_check(bodies.is_empty(), "corpse is removed at the end of the death animation")


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
		print("[reclaim-tests] PASS: boot, roster, enemies, augments, HQ-only start, construction rules, collision, turret caps, combat modes, 360-degree projectiles, reload, lethal combat, zombie AI and variants, combat zoom, menu and key reset, augments, wall priority, field warnings and save/continue")
		quit(0)
	else:
		for failure in failures: push_error("[reclaim-tests] " + failure)
		quit(1)
