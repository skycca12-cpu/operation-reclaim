extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_verify")


func _verify() -> void:
	_check(ProjectSettings.get_setting("application/config/name") == "수도 탈환작전", "exported identity")
	for path: String in [
		"scripts/main.gd", "scripts/reclaim/data.gd", "scenes/main.tscn",
		"assets/share/favicon.png", "assets/template/fonts/ui_regular.tres",
	]:
		_check(ResourceLoader.exists("res://" + path), "pack resource: " + path)
	_check(not ResourceLoader.exists("res://test/reclaim_smoke.gd"), "source test excluded")
	_check(not ResourceLoader.exists("res://tools/verify_exported_pack.gd"), "pack verifier excluded")
	_check(not root.has_node("GlobalLeaderboard"), "no dormant network adapter")
	var packed := load("res://scenes/main.tscn") as PackedScene
	_check(packed != null, "exported main scene")
	if packed != null:
		var main := packed.instantiate()
		root.add_child(main)
		await process_frame
		await process_frame
		_check(main.get("screen") == "menu", "pack boots to localized game menu")
		main.call("_start_new_run")
		await process_frame
		_check(main.get("screen") == "play", "pack starts playable game")
		var structures: Array = main.get("structures")
		_check(structures.size() == 1 and structures[0].kind == "hq", "new run starts with HQ tent only")
		_check(main.has_method("_validate_placement"), "construction validation is present")
		_check(main.has_method("_update_spawn"), "timed combat progression is present")
		main.queue_free()
		await process_frame
	if _failures.is_empty():
		print("[exported-pack] PASS: identity, game resources, exclusions, boot, HQ-only start, construction and combat")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("[exported-pack] " + failure)
		quit(1)


func _check(condition: bool, context: String) -> void:
	if not condition and context not in _failures:
		_failures.append(context)
