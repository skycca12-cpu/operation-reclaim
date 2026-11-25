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
	_check(Data.TURRETS.size() == 7, "seven turret families including anti-air")
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
	_check(String(game.call("_validate_placement", "wall", Vector2i(3, -2))) != "", "north entrance remains permanently open")
	_check(String(game.call("_validate_placement", "wall", Vector2i(3, 2))) != "", "a wall cannot block the north escape route")
	_check(String(game.call("_validate_placement", "clinic", Vector2i(8, 4))) != "", "two-cell building stays within the eleven-by-eleven area")
	_check(String(game.call("_validate_placement", "basic", Vector2i(8, 8))) == "", "outer expansion ring accepts a one-cell turret")
	var panel_key := InputEventKey.new()
	panel_key.physical_keycode = KEY_B
	panel_key.keycode = KEY_B
	panel_key.pressed = true
	root.push_input(panel_key, true)
	var build_panel: Control = game.get("build_panel")
	await process_frame
	await process_frame
	_check(build_panel.visible and build_panel.size.x <= 270.0 and build_panel.size.y < 320.0,
		"B opens a compact construction panel")
	game.call("_select_build_tab", "wall")
	await process_frame
	await process_frame
	_check(build_panel.size.y < 170.0, "the wall tab collapses around its only option")
	var close_build := build_panel.find_child("CloseBuild", true, false) as Button
	game.call("_select_build", "wall")
	close_build.pressed.emit()
	_check(not build_panel.visible and not game.get("build_mode"), "close cancels the preview and hides the construction panel")
	var build_key := InputEventKey.new()
	build_key.physical_keycode = KEY_1
	build_key.keycode = KEY_1
	build_key.pressed = true
	root.push_input(build_key.duplicate(), true)
	_check(game.get("selected_build") == "basic", "1 selects a turret with the construction panel closed")
	game.call("_try_place_at", game.call("_cell_world", Vector2i(8, 8)))
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
	game.call("_select_entity_at", game.call("_cell_world", Vector2i(8, 8)))
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
	for i in range(9):
		structures.append({"kind": "heavy", "cell": Vector2i(i % 8, i / 8), "hp": 100.0, "max_hp": 100.0, "level": 1, "cool": 0.0})
	game.set("money", 500)
	game.set("player_index", 1)
	_check(String(game.call("_validate_placement", "rocket", Vector2i(0, 6))).contains("한도"), "ordinary operator cap is ten total turrets")
	game.set("player_index", 3)
	_check(String(game.call("_validate_placement", "rocket", Vector2i(0, 6))) == "", "Han Yujin can place above ten turrets")
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
	var contact := player_pos + Vector2(70, 0)
	_check(enemies.is_empty() and effects.size() == effects_before + 1 and effects.back().has("hit_angle")
		and effects.back().a == contact and effects.back().b == contact,
		"lethal chainsaw hit emits a spark at the removed zombie's position")

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
	_check(game.get("player_hp") == health_before, "the wind-up phase does not inflict damage")
	_check(not pursuer.attack_is_bite, "the first normal zombie strike is a claw attack")
	game.call("_update_enemies", ZombieVisual.IMPACT_TIME)
	_check(game.get("player_hp") < health_before and pursuer.attack_until > game.get("run_seconds") and pursuer.attack_direction.is_equal_approx(Vector2.LEFT), "normal zombie damages the player and starts its attack animation")
	var saved_player_pos: Vector2 = game.get("player_pos")
	pursuer.cool = 0.0
	game.call("_update_enemies", 0.01)
	_check(pursuer.attack_is_bite, "the next normal zombie strike is a bite")
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
	_test_harin_muzzle(resumed)
	_test_infantry_visuals(resumed)
	_test_yujin(resumed)
	_test_zombie_weapon_reactions(resumed)
	_test_dash_echoes(resumed)
	_test_operator_skills(resumed)
	_test_spawn_multiplier(resumed)
	_test_character_augments(resumed)
	_test_enemy_wall_cover(resumed)
	_test_jeju_battlefield(resumed)
	_test_repair_drone(resumed)
	_test_integrated_progression(resumed)
	_test_jeju_encounters(resumed)
	resumed.queue_free()
	await process_frame
	_finish()


func _test_jeju_encounters(game: Control) -> void:
	game.call("_reset_run")
	game.call("_show_screen", "play")
	var enemies: Array = game.get("enemies")
	var hq: Vector2 = game.call("_hq_position")
	var start := hq + Vector2(200.0, 0.0)
	game.call("_spawn_enemy", "S11", start, false)
	var siege: Dictionary = enemies[0]
	_check(siege.name == "공성형" and not siege.get("underground", false), "stage 46 specialist is a targetable siege enemy")
	game.set("player_pos", hq + Vector2(0.0, 500.0))
	game.call("_update_enemies", 0.1)
	_check(siege.pos.distance_to(hq) < start.distance_to(hq), "siege enemy approaches the base along the ground")
	var structures_before: Array = game.get("structures")
	var hp_before: float = structures_before[0].hp
	siege.pos = hq + Vector2(55.0, 0.0)
	siege.cool = 0.0
	game.call("_strike_structure", siege, 0)
	game.call("_resolve_normal_strike", siege, 0.4)
	_check(is_equal_approx(hp_before - float(structures_before[0].hp), float(siege.attack) * 3.0), "siege hit applies triple structure damage")
	game.call("_save_all")
	var saved: Dictionary = game.get("saved_run")
	saved.enemies[0].hole = {"open": true}
	game.call("_load_saved_run")
	_check(enemies.size() == 1 and enemies[0].name == "공성형" and not enemies[0].get("underground", false),
		"legacy worm saves restore the siege replacement on the surface")
	var initial_hp: float

	for wave in [20, 40, 60, 80, 100]:
		game.call("_reset_run")
		game.call("_show_screen", "play")
		var kind := "boss%d" % wave
		game.set("stage", wave)
		game.set("player_pos", hq + Vector2(210.0, 0.0))
		game.call("_spawn_enemy", kind, hq + Vector2(240.0, 0.0), true)
		game.call("_spawn_enemy", "normal", hq + Vector2(215.0, 35.0), false)
		var boss: Dictionary = enemies[0]
		var ally: Dictionary = enemies[1]
		var structures: Array = game.get("structures")
		var hq_hp: float = structures[0].hp
		initial_hp = float(game.get("player_hp"))
		boss.pattern_timer = 0.0
		game.call("_update_boss_pattern", boss, 0.0)
		_check(ZombieVisual.JEJU_ENEMIES.has(kind) and boss.art_scale == Data.BOSSES[wave].scale, "%s has dedicated art and a fixed size" % kind)
		if wave != 40:
			_check(boss.has("pattern_pos"), "%s telegraphs its signature attack" % kind)
			game.call("_update_boss_pattern", boss, 1.0)
		match wave:
			20:
				_check(ally.get("rage_until", 0.0) > game.get("run_seconds") and enemies.size() == 2, "commander buffs nearby zombies")
			40:
				var hp: float = boss.hp
				game.call("_damage_enemy", 0, 100.0, "test")
				_check(is_equal_approx(hp - float(boss.hp), 40.0), "armored boss reduces incoming damage while guarding")
			60:
				_check(game.get("player_hp") < initial_hp and enemies.size() == 2, "guardian's impact damages the player")
			80:
				_check(structures[0].hp < hq_hp, "demolisher's impact damages the headquarters")
			100:
				_check(enemies.size() == 5, "hive ruler summons three reinforcements")

	game.call("_reset_run")
	game.call("_show_screen", "play")
	game.set("player_pos", hq + Vector2(205.0, 0.0))
	game.call("_spawn_enemy", "S05", hq + Vector2(240.0, 0.0), false)
	var bomber: Dictionary = enemies[0]
	game.call("_update_special", bomber, 0, 0.2)
	_check(float(bomber.charge) > 0.0, "explosive special starts its fuse in range")
	game.set("player_pos", hq + Vector2(400.0, 0.0))
	initial_hp = float(game.get("player_hp"))
	game.call("_update_special", bomber, 0, 0.6)
	_check(enemies.is_empty() and game.get("player_hp") == initial_hp, "armed bomber detonates while a player who leaves the warning area avoids damage")

	game.call("_reset_run")
	game.call("_show_screen", "play")
	game.call("_spawn_enemy", "S10", hq + Vector2(240.0, 0.0), false)
	var ambusher: Dictionary = enemies[0]
	ambusher.ability_cool = 0.0
	game.call("_update_special", ambusher, 0, 0.01)
	_check(ambusher.underground and ambusher.has("burrow_warning"), "ambush starts with a ground warning")
	game.call("_update_special", ambusher, 0, 0.90)
	var particles: Array = game.get("effects")
	_check(not ambusher.underground and particles.any(func(effect): return effect.has("burrow_debris")), "ambusher emerges with debris after the warning")
	_check(ZombieVisual.injury_tier(66.0, 100.0) == 0 and ZombieVisual.injury_tier(65.0, 100.0) == 1
		and ZombieVisual.injury_tier(31.0, 100.0) == 1 and ZombieVisual.injury_tier(30.0, 100.0) == 2,
		"enemy damage frames switch at 65 and 30 percent health")
	_check(ZombieVisual.JEJU_MOTION.size() == 25, "all 20 special enemies and 5 bosses have motion atlases")


func _test_integrated_progression(game: Control) -> void:
	game.call("_reset_run")
	game.call("_show_screen", "play")
	var roster = preload("res://scripts/reclaim/special_enemies.gd")
	for index in range(20):
		var id := "S%02d" % (index + 1)
		var special: Dictionary = game.call("_make_enemy", id, Vector2(600, 450), false)
		var base_size := float(roster.definition(id).scale)
		var extra := float(special.art_scale) - base_size
		_check(special.special and extra >= 0.0 and extra <= 0.5
			and is_equal_approx(extra * 10.0, roundf(extra * 10.0))
			and ZombieVisual.JEJU_ENEMIES.has(id),
			"special enemy %s has dedicated art and a valid size tier" % id)
	var enemies: Array = game.get("enemies")
	var milestones := [20, 40, 60, 80, 100]
	game.set("augments_taken", 100)
	for wave: int in milestones:
		game.set("stage", wave - 1)
		game.set("stage_elapsed", 22.0)
		game.call("_update_spawn", 0.0)
		var boss_id := "boss%d" % wave
		var indices: Array = enemies.filter(func(enemy): return enemy.kind == boss_id)
		_check(indices.size() == 1, "wave %d spawns its boss exactly once" % wave)
		if indices.size() == 1:
			game.call("_damage_enemy", enemies.find(indices[0]), 1e8, "test")
	_check(game.get("augment_queue") == 10, "five boss kills queue ten choices")
	_check(game.get("screen") != "result", "the final boss alone does not win before the wave is complete")
	game.call("_reset_run")
	game.call("_show_screen", "play")
	var structures: Array = game.get("structures")
	structures.append({"kind": "clinic", "cell": Vector2i(1, 1), "hp": 520.0, "max_hp": 520.0, "level": 11})
	structures.append({"kind": "supply", "cell": Vector2i(1, 3), "hp": 580.0, "max_hp": 580.0, "level": 4})
	game.set("player_hp", 0.0)
	game.call("_update_progress", 0.0)
	_check(is_equal_approx(float(game.get("treatment_remaining")), 120.0), "a +10 clinic treats for 120 seconds")
	game.call("_start_expedition")
	var expedition: float = game.get("expedition_remaining")
	game.call("_update_facilities", 1.0)
	_check(expedition > 0.0 and game.get("expedition_remaining") < expedition, "expedition continues during treatment")
	game.call("_update_facilities", 120.0)
	_check(game.get("treatment_remaining") == 0.0 and game.get("player_hp") == game.get("player_max_hp"),
		"treatment restores full HP and returns control")
	game.set("player_xp", 1e8)
	game.call("_check_level_up")
	_check(game.get("augments_taken") == 100 and game.get("augment_queue") == 100, "XP queues 100 choices without discarding them")
	game.call("_show_screen", "play")
	var double_speed := InputEventKey.new()
	double_speed.physical_keycode = KEY_F6
	double_speed.keycode = KEY_F6
	double_speed.pressed = true
	root.push_input(double_speed, true)
	var start: float = game.get("run_seconds")
	game.call("_process", 0.05)
	_check(is_equal_approx(float(game.get("run_seconds")) - start, 0.10), "F6 doubles the simulation clock")


func _test_repair_drone(game: Control) -> void:
	game.call("_reset_run")
	game.set("money", 200)
	game.call("_select_build", "repair")
	var structures: Array = game.get("structures")
	_check(game.get("repair_drone_level") == 1 and structures.size() == 1 and not game.get("build_mode"),
		"repair drone installs immediately without occupying a construction cell")
	var wall := {"kind": "wall", "cell": Vector2i(7, 7), "hp": 20.0, "max_hp": 180.0, "level": 1}
	structures.append(wall)
	var start: Vector2 = game.get("repair_drone_pos")
	game.call("_update_repair_drone", 0.1)
	_check(start != game.get("repair_drone_pos") and wall.hp == 20.0, "drone begins moving before repairing")
	for i in range(35):
		game.call("_update_repair_drone", 0.1)
	_check(wall.hp > 20.0, "drone repairs the wall once it arrives")
	game.call("_upgrade_repair_drone")
	game.call("_save_all")
	game.call("_load_saved_run")
	_check(game.get("repair_drone_level") == 2, "repair drone upgrade survives save and reload")
	var legacy: Dictionary = game.get("saved_run")
	legacy.erase("repair_drone_level")
	legacy.structures.append({"kind": "repair", "x": 6, "y": 6, "hp": 90.0, "max_hp": 180.0, "level": 4})
	game.call("_load_saved_run")
	_check(game.get("repair_drone_level") == 4 and not structures.any(func(item): return item.kind == "repair"),
		"legacy repair towers become drones and free their building cell")
	game.call("_damage_structure", 1, 999.0)
	var effects: Array = game.get("effects")
	_check(effects.any(func(effect): return effect.has("debris")), "a destroyed wall emits debris")


func _test_jeju_battlefield(game: Control) -> void:
	var map: RefCounted = game.get("jeju_map")
	var bounds: Rect2 = map.get("bounds")
	_check(bounds.size == Vector2(2880, 2880), "the flat arena is exactly 60 by 60 construction-size cells")
	game.call("_reset_run")
	var hq: Vector2 = game.call("_hq_position")
	var spawn_sectors := {}
	for i in range(8):
		var angle := float(i) * TAU / 8.0
		var spawn: Vector2 = game.call("_land_spawn", angle, 820.0)
		_check(map.call("walkable", spawn, 42.0), "each spawn sector lies on flat ground")
		spawn_sectors[spawn] = true
		game.call("_reset_run")
		game.set("treatment_remaining", 60.0)
		game.call("_spawn_enemy", "normal", spawn, false)
		var mob: Array = game.get("enemies")
		for step in range(520):
			game.call("_update_enemies", 0.05)
		_check(mob.size() == 1 and Vector2(mob[0].pos).distance_to(hq) < 100.0,
			"a zombie can approach the HQ directly from sector %d" % i)
	_check(spawn_sectors.size() == 8, "all eight spawn sectors are distinct")
	for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		game.set("player_pos", direction * 340.0)
		game.call("_move_player", direction * 1800.0)
		var reached: Vector2 = game.get("player_pos")
		_check(map.call("walkable", reached, 13.0) and reached.dot(direction) > 1400.0,
			"the player walks freely until reaching the arena boundary")
	for zoom in [0.65, 1.0, 2.4]:
		var center: Vector2 = map.call("camera_center", bounds.position, Vector2(1280, 720), zoom)
		_check(center.is_equal_approx(bounds.position + Vector2(640, 360) / zoom), "camera stays inside arena bounds")
	game.call("_reset_run")
	game.set("spawn_timer", 0.0)
	game.call("_update_spawn", 0.0)
	var first_wave: Array = game.get("enemies")
	_check(first_wave.size() == 5 and first_wave.all(func(enemy): return Vector2(enemy.pos).distance_to(hq) >= 699.0),
		"the first wave spawns at its authored distance")
	game.call("_reset_run")
	game.set("stage", 95)
	for i in range(70):
		game.set("spawn_timer", 0.0)
		game.call("_update_spawn", 0.0)
	var enemies: Array = game.get("enemies")
	_check(enemies.size() == 1900 and enemies.all(func(enemy): return map.call("walkable", enemy.pos, 24.0)),
		"the late wave reaches the 1900-enemy target with all enemies on the map")
	for hero in range(Data.CHARACTERS.size()):
		game.call("_choose_character", hero)
		game.call("_choose_difficulty", 1)
		var intro: Control = game.get("flow_prologue")
		intro.call("_process", 4.0)
		intro.call("_process", 4.0)
		_check(game.get("screen") == "landing", "each operator reaches the real-map landing")
		game.call("_update_landing", 3.5)
		var landing: RefCounted = game.get("landing")
		_check(landing.call("player_visible") and landing.call("heli_visible"), "each operator disembarks before departure")
		game.call("_update_landing", 3.5)
		var structures: Array = game.get("structures")
		_check(game.get("screen") == "play" and game.get("player_index") == hero and structures.size() == 1,
			"natural landing hands control to each selected operator with HQ only")
		game.call("_choose_character", hero)
		game.call("_choose_difficulty", 1)
		intro.call("skip")
		_check(game.get("screen") == "play" and landing.call("heli_visible") == false and game.get("hq_build_ratio") == 1.0,
			"skipping leaves every operator in the same playable state")


func _test_enemy_wall_cover(game: Control) -> void:
	game.call("_reset_run")
	game.set("player_pos", Vector2(-50, 144))
	var hp: float = game.get("player_hp")
	var structures: Array = game.get("structures")
	var near_wall := {"kind": "wall", "cell": Vector2i(5, 6), "hp": 10.0, "max_hp": 180.0}
	var far_wall := {"kind": "wall", "cell": Vector2i(4, 6), "hp": 80.0, "max_hp": 180.0}
	structures.append(far_wall)
	structures.append(near_wall)
	var shots: Array = game.get("enemy_shots")
	var projectile := {"pos": Vector2(250, 144), "velocity": Vector2(-300, 0), "life": 2.2, "damage": 20.0}
	shots.append(projectile.duplicate())
	game.call("_update_projectiles", 1.0)
	_check(shots.is_empty() and near_wall.hp == 0.0 and far_wall.hp == 80.0 and game.get("player_hp") == hp,
		"a fast shot hits the first wall and cannot spill damage behind a destroyed wall")
	shots.append(projectile.duplicate())
	game.call("_update_projectiles", 1.0)
	_check(far_wall.hp == 60.0 and game.get("player_hp") == hp, "a second shot hits the next living wall")
	game.set("player_pos", Vector2(10, 144))
	shots.append(projectile.duplicate())
	game.call("_update_projectiles", 1.0)
	_check(far_wall.hp == 40.0 and game.get("player_hp") == hp, "a wall protects a player standing directly behind it")
	far_wall.hp = 0.0
	shots.append(projectile.duplicate())
	game.call("_update_projectiles", 1.0)
	_check(game.get("player_hp") < hp, "a new shot reaches the player after the walls are gone")
	hp = game.get("player_hp")
	near_wall.hp = 80.0
	game.set("player_pos", Vector2(112, 171))
	var enemy := {"pos": Vector2(123, 158), "attack": 12.0,
		"strike_remaining": 0.05, "strike_target": null, "attack_direction": Vector2(-11, 13).normalized()}
	game.call("_resolve_normal_strike", enemy, 0.1)
	_check(near_wall.hp == 68.0 and game.get("player_hp") == hp, "a melee strike cannot clip through a wall corner")
	near_wall.hp = 4.0
	game.set("player_pos", Vector2(60, 144))
	game.call("_explode_bomber", {"pos": Vector2(130, 144), "attack": 20.0, "target": "player"})
	_check(near_wall.hp == 0.0 and game.get("player_hp") == hp, "a bomber blast does not penetrate the wall it destroys")


func _test_character_augments(game: Control) -> void:
	const Catalog = preload("res://scripts/reclaim/augment_catalog.gd")
	var catalog := Catalog.cards()
	var owners := {}
	for card in catalog:
		owners[card.hero] = int(owners.get(card.hero, 0)) + 1
	_check(catalog.size() == 500 and owners == {"": 300, "tae": 50, "si": 50, "harin": 50, "yujin": 50},
		"all 500 records and character distributions load")
	game.set("player_index", 3)
	game.call("_reset_run")
	var options: Array = game.call("_eligible_augments")
	_check(options.any(func(card): return card.hero == "yujin") and not options.any(func(card): return card.hero == "harin" or card.key == "magazine"),
		"Yujin sees her exclusive cards and excludes magazine upgrades")
	game.set("player_index", 2)
	game.call("_reset_run")
	options = game.call("_eligible_augments")
	_check(not options.any(func(card): return card.id == "A022"), "a specialization needs its prerequisite")
	var magazine: Dictionary = catalog[20]
	for stack in range(1, 11):
		game.call("_choose_augment", magazine)
		_check(game.call("_magazine_capacity") == 30 + stack * 5, "each magazine stack applies the CSV's five rounds")
	game.call("_choose_augment", magazine)
	options = game.call("_eligible_augments")
	_check(game.call("_magazine_capacity") == 80 and not options.has(magazine) and options.has(catalog[21]),
		"the cap excludes the original card and the prerequisite unlocks specialization")
	game.set("manual_attack", true)
	game.set("manual_trigger", false)
	game.set("player_magazine", 0)
	game.set("player_reload_timer", 0.1)
	game.call("_update_player_attack", 0.2)
	_check(game.get("player_magazine") == 80, "reloading fills the upgraded magazine")
	game.call("_save_all")
	game.call("_load_saved_run")
	_check(game.call("_magazine_capacity") == 80 and game.get("player_magazine") == 80, "CSV magazine survives continue")


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
	_check(active.size() == 50, "early wave batches respect the active enemy target")


func _test_harin_muzzle(game: Control) -> void:
	game.set("player_index", 2)
	game.call("_reset_run")
	game.call("_show_screen", "play")
	game.set("camera_zoom", 2.0)
	game.set("player_facing", Vector2.DOWN)
	game.call("_attack_player")
	var visual: RefCounted = game.get("_harin_visual")
	var shots: Array = game.get("player_projectiles").shots
	var player: Vector2 = game.get("player_pos")
	_check(shots.size() == 1 and Vector2(shots[0].pos).is_equal_approx(player + Vector2(0, 9.0)),
		"Harin's downward projectile starts at the on-screen barrel at 2x zoom")
	_check(visual.call("_front_shot_frame") == 1, "Harin starts on the compressed recoil frame at discharge")
	visual.call("update", 0.07, Vector2.ZERO, 100.0, true)
	_check(visual.call("_front_shot_frame") == 2, "Harin advances to the return pose")
	for shot_origin in [
		[Vector2.UP, Vector2(6, -42)],
		[Vector2.LEFT, Vector2(-38, 2)],
		[Vector2.RIGHT, Vector2(38, -1)],
	]:
		shots.clear()
		game.set("player_facing", shot_origin[0])
		game.call("_attack_player")
		_check(shots.size() == 1 and Vector2(shots[0].pos).is_equal_approx(player + Vector2(shot_origin[1]) / 2.0),
			"Harin's projectile starts at the displayed barrel for %s" % shot_origin[0])
	game.set("camera_zoom", 1.0)


func _test_infantry_visuals(game: Control) -> void:
	for hero in [0, 1]:
		game.set("player_index", hero)
		game.call("_reset_run")
		game.set("player_facing", Vector2.UP)
		game.call("_attack_player")
		var visual: RefCounted = game.get("_infantry_visual")
		var shots: Array = game.get("player_projectiles").shots
		_check(visual.get("_shot_facing") == Vector2.UP and float(visual.get("_shot_time")) > 0.0,
			"infantry firing selects its authored north pose")
		_check(shots.size() == (5 if hero == 0 else 1) and Vector2(shots[0].tracer_offset).y < 0.0,
			"infantry keeps its shotgun or rifle behavior with an upright muzzle effect")


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
	var hits: Array = game.get("effects")
	_check(game.get("player_projectiles").shots.is_empty()
		and hits.any(func(effect): return effect.has("hit_angle"))
		and hits.all(func(effect): return effect.a == effect.b),
		"Yujin's cut produces local hit sparks without bullets or tracer lines")
	_check(float(visual.get("_attack_left")) > 0.0, "the real melee attack starts Yujin's cutting animation")
	game.set("player_facing", Vector2.UP)
	game.call("_attack_player")
	_check(visual.get("_attack_facing") == Vector2.UP, "Yujin's attack pose follows the northward cut")
	visual.call("update", 1.0)
	_check(is_zero_approx(float(visual.get("_attack_left"))), "Yujin returns to idle after cutting ends")
	var run = preload("res://scripts/reclaim/operator_run.gd")
	for hero in ["harin", "yujin", "tae", "si"]:
		var start: Vector2i = run.frame_cell(hero, Vector2.DOWN, 0.0)
		_check(run.frame_cell(hero, Vector2.UP, 0.0).y == start.y + 1
			and run.frame_cell(hero, Vector2.RIGHT, 0.0).y == start.y + 2,
			"%s selects separate front, back and side run art" % hero)
		var phases := PackedInt32Array()
		for step in range(5):
			phases.append(run.frame_cell(hero, Vector2.DOWN, step * run.STEP_DISTANCE).x)
		_check(phases == PackedInt32Array([0, 1, 2, 3, 0]),
			"%s advances through both contacts and both passing poses" % hero)


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
	_check(not attacker.attack_is_bite, "a normal zombie claws a structure")
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
	_check(is_equal_approx(game.get("camera_zoom"), 0.65), "mouse wheel reaches the wider view at 0.65x")
	camera_point = game.size * 0.5 + Vector2(48.0 * 0.65, 0.0)
	world_point = game.call("_screen_to_world", camera_point)
	_check(world_point.is_equal_approx(game.get("player_pos") + Vector2(48.0, 0.0)), "wide-view clicks retain one-tile world accuracy")
	game.set("camera_zoom", 1.0)
	game.call("_offer_augments")
	var row := (game.get("augment_screen") as Control).find_child("AugmentCards", true, false) as HBoxContainer
	_check(row.get_child_count() == 3 and row.get_combined_minimum_size().x <= 600.0 and row.get_combined_minimum_size().x >= 560.0, "the three augment cards are enlarged but fit within a compact row")
	var reroll: Button = game.get("augment_reroll_button")
	_check(reroll.flat and reroll.size_flags_horizontal == Control.SIZE_SHRINK_CENTER, "reroll is compact instead of stretching")
	game.call("_reroll_augments")
	_check(not reroll.disabled, "a second free reroll remains")
	game.call("_reroll_augments")
	_check(reroll.disabled and row.get_child_count() == 3, "two rerolls leave three cards")
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
	for i in range(700):
		var zombie: Dictionary = game.call("_make_enemy", "normal", Vector2(800.0, 0.0), false)
		variants[zombie.appearance] = [zombie.hp, zombie.speed, zombie.attack, zombie.reward]
	_check(variants.size() == 50 and variants.values().all(func(stats): return stats == variants.values()[0]), "all 50 random appearances share exactly the same normal zombie stats")
	_check(not bodies.is_empty() and bodies.back().variant == death_variant, "pool reuse cannot change a corpse visual")
	game.call("_update_zombie_corpses", now + ZombieVisual.DEATH_TIME * 0.5)
	_check(bodies.size() == deaths_before + 1, "corpse remains during its visible death frames")
	game.call("_update_zombie_corpses", now + ZombieVisual.DEATH_TIME + 0.01)
	_check(bodies.is_empty(), "corpse is removed at the end of the death animation")


func _test_operator_skills(game: Control) -> void:
	for cue in ["player.shotgun", "player.m4", "player.chainsaw", "player.chainsaw_rev", "enemy.low",
			"enemy.high", "enemy.elderly", "enemy.boss_arrival", "player.shield_impact"]:
		_check(game.get_node("/root/AudioDirector").play_cue(cue), "imported combat cue is loaded: %s" % cue)
	game.set("player_index", 0)
	game.call("_reset_run")
	game.call("_show_screen", "play")
	game.set("player_facing", Vector2.RIGHT)
	var starting_point: Vector2 = game.get("player_pos")
	var zombie := _spawn_test_zombie(game, starting_point + Vector2(38, 0), 600.0)
	game.call("_use_operator_skill")
	for step in range(5):
		game.call("_update_player", 0.03)
	_check(zombie.hp == 555.0 and game.get("shield_targets").size() == 1,
		"shield charge follows actual movement and strikes once per zombie")
	_check(game.get("skill_ready_at") == 12.0, "shield charge starts its own cooldown")
	var hit_position: Vector2 = zombie.pos
	_check(zombie.down_until > 0.0 and zombie.knock_left > 0.0, "shield contact knocks the zombie down")
	game.call("_update_enemies", 0.1)
	_check(Vector2(zombie.pos).x > hit_position.x and not zombie.moving, "knockdown pushes the zombie and prevents it attacking")
	_test_element_statuses(game)

	game.set("player_index", 1)
	game.call("_reset_run")
	game.call("_show_screen", "play")
	var base_rate: float = game.call("_weapon_interval", Data.CHARACTERS[1], 1.0)
	game.call("_use_operator_skill")
	_check(float(game.call("_weapon_interval", Data.CHARACTERS[1], 1.0)) < base_rate, "focus accelerates the rifle")
	game.set("run_seconds", 5.1)
	_check(is_equal_approx(float(game.call("_weapon_interval", Data.CHARACTERS[1], 1.0)), base_rate),
		"focus ends on the simulation clock")

	game.set("player_index", 2)
	game.call("_reset_run")
	game.call("_show_screen", "play")
	var harin_pos: Vector2 = game.get("player_pos")
	var drone_target := _spawn_test_zombie(game, harin_pos + Vector2(80, 0), 600.0)
	game.call("_use_operator_skill")
	game.call("_update_combat_drone", 0.1)
	_check(drone_target.hp < 600.0 and game.get("combat_drone_fire_at") == 0.0
		and float(game.get("drone_timer")) < 2.0, "the tactical drone attacks and overclock halves its attack delay")

	game.set("player_index", 3)
	game.call("_reset_run")
	game.call("_show_screen", "play")
	game.set("saw_heat", 98.0)
	game.call("_attack_player")
	_check(game.get("saw_overheated"), "the chainsaw overheats under sustained use")
	game.call("_use_operator_skill")
	_check(game.get("saw_heat") == 0.0 and not game.get("saw_overheated"), "forced cooling clears heat")
	var structures: Array = game.get("structures")
	structures.append({"kind": "wall", "cell": Vector2i(5, 5), "hp": 60.0, "max_hp": 100.0})
	var position: Vector2 = game.get("player_pos")
	game.set("saw_repair_kills", 4)
	game.set("sound_on", true)
	game.set("player_facing", Vector2.RIGHT)
	var target := _spawn_test_zombie(game, position + Vector2(40, 0), 1.0)
	var target_position: Vector2 = target.pos
	game.call("_attack_player")
	_check(game.get("saw_cut_audio_at") > 0.0 and target.pos == target_position,
		"the saw triggers its cutting cue on contact without moving the zombie")
	_check(structures.back().hp == 66.0, "the fifth saw kill repairs the nearest damaged non-HQ structure")


func _test_element_statuses(game: Control) -> void:
	var enemies: Array = game.get("enemies")
	enemies.clear()
	game.set("run_seconds", 0.0)
	var point: Vector2 = game.get("player_pos") + Vector2(88, 0)
	var enemy := _spawn_test_zombie(game, point, 50.0)
	game.call("_apply_status", enemy, "burn", 2.0, 3.0)
	game.call("_apply_status", enemy, "poison", 2.0, 4.0)
	game.call("_apply_cold", enemy, true)
	game.set("run_seconds", 0.46)
	game.call("_update_enemies", 0.1)
	_check(enemy.hp == 43.0 and enemy.pos == point, "burn and poison tick while cold stops movement with no extra tick damage")
	var effects: Array = game.get("effects")
	_check(effects.any(func(effect): return effect.get("dot_text", "") == "3" and effect.color.r > effect.color.g)
		and effects.any(func(effect): return effect.get("dot_text", "") == "4" and effect.color.g > effect.color.r),
		"burn and poison report actual damage in distinct colors")
	game.call("_damage_enemy", 0, 60.0, "player")
	_check(effects.any(func(effect): return effect.get("ice_shatter", false)), "a killed frozen zombie shatters")


func _test_dash_echoes(game: Control) -> void:
	game.call("_reset_run")
	game.call("_show_screen", "play")
	game.set("player_facing", Vector2.RIGHT)
	var origin: Vector2 = game.get("player_pos")
	game.call("_try_dash")
	for tick in range(7):
		game.call("_update_player", 1.0 / 60.0)
		game.set("run_seconds", float(tick + 1) / 60.0)
	var echoes: Array = game.get("dash_echoes")
	_check(echoes.size() >= 2 and echoes[0].pos == origin and echoes[1].pos.x > origin.x,
		"dash records a fading trail at the actual movement positions")
	game.set("run_seconds", 1.0)
	game.call("_process", 0.01)
	_check(echoes.is_empty(), "dash silhouettes expire")
	game.call("_reset_run")
	game.call("_show_screen", "play")
	game.set("player_facing", Vector2.RIGHT)
	game.set("player_pos", Vector2(1426, 0))
	game.call("_try_dash")
	game.call("_update_player", 1.0 / 60.0)
	_check(echoes.is_empty(), "a blocked dash does not leave an echo at the edge")


func _test_zombie_weapon_reactions(game: Control) -> void:
	for item in [["basic", "rifle"], ["heavy", "shotgun"], ["rocket", "explosive"],
			["electric", "electric"], ["flame", "fire"], ["freeze", "cold"], ["aa", "rifle"]]:
		game.call("_reset_run")
		var structures: Array = game.get("structures")
		structures.append({"kind": item[0], "cell": Vector2i(5, 5), "level": 1,
			"hp": 200.0, "max_hp": 200.0, "cool": 0.0})
		var mob: Dictionary = _spawn_test_zombie(game, Vector2(156, 96), 1000.0)
		mob.air = item[0] == "aa"
		game.call("_update_turrets", 0.01)
		_check(mob.hp < 1000.0 and mob.get("hit_style") == item[1] and mob.hit_until > 0.0,
			"the %s turret selects the %s zombie impact" % item)
	game.set("player_index", 0)
	game.call("_reset_run")
	var target: Dictionary = _spawn_test_zombie(game, Vector2(200, 50), 1000.0)
	game.call("_damage_enemy", 0, 10.0, "player", Vector2(240, 50))
	_check(target.hit_style == "shotgun" and Vector2(target.hit_direction).is_equal_approx(Vector2.LEFT),
		"shotgun reaction faces away from the projectile impact origin")


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
