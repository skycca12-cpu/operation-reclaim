extends SceneTree
## Renders the opening flow and saves screenshots (run under xvfb, not headless):
##   xvfb-run -s "-screen 0 1280x720x24" godot --path . -s test/flow_capture.gd
var game: Node
var out := "/tmp/flow_shots"


func _initialize() -> void:
	call_deferred("_run")


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _shot(name: String) -> void:
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	img.save_png("%s/%s.png" % [out, name])
	print("[capture] ", name, " screen=", game.get("screen"))


func _key(code: int, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	game = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await _wait(0.6)
	await _shot("01_boot_loading")
	await _wait(2.4)
	await _shot("02_boot_done")
	game.call("_finish_boot")
	await _wait(0.8)
	await _shot("03_main_menu")
	game.call("_on_menu_start")
	await _wait(0.5)
	await _shot("04_character_select")
	game.call("_choose_character", 2)
	await _wait(0.4)
	await _shot("05_difficulty")
	game.call("_choose_difficulty", 1)
	await _wait(3.0)
	await _shot("06_prologue_sea")
	await _wait(5.0)
	await _shot("07_prologue_city")
	await _wait(5.5)
	await _shot("08_prologue_brief")
	while game.get("screen") == "intro":
		await process_frame
	await _wait(1.4)
	await _shot("09_landing_descent")
	await _wait(2.3)
	await _shot("10_landing_disembark")
	await _wait(1.8)
	await _shot("11_landing_hq_build")
	await _wait(2.4)
	await _shot("12_landing_liftoff")
	while game.get("screen") == "landing":
		await process_frame
	await _shot("13_first_play_frame")
	var start: Vector2 = game.get("player_pos")
	_key(KEY_D, true)
	await _wait(0.8)
	_key(KEY_D, false)
	_key(KEY_S, true)
	await _wait(0.6)
	_key(KEY_S, false)
	print("[capture] moved from ", start, " to ", game.get("player_pos"))
	await _wait(6.0)
	await _shot("14_play_combat")
	print("[capture] enemies=", (game.get("enemies") as Array).size())
	quit(0)
