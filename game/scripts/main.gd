extends Control

const PlayerProjectiles = preload("res://scripts/reclaim/player_projectiles.gd")
const ZombieVisual = preload("res://scripts/reclaim/zombie_visual.gd")
const Data = preload("res://scripts/reclaim/data.gd")
const HarinVisual = preload("res://scripts/reclaim/character_visual.gd")
const JejuMapArt = preload("res://scripts/reclaim/jeju_map_art.gd")
const BootScreen = preload("res://scripts/reclaim/flow/boot_screen.gd")
const MainMenuScreen = preload("res://scripts/reclaim/flow/main_menu_screen.gd")
const CharacterSelectScreen = preload("res://scripts/reclaim/flow/character_select_screen.gd")
const DifficultyScreen = preload("res://scripts/reclaim/flow/difficulty_screen.gd")
const PrologueScreen = preload("res://scripts/reclaim/flow/prologue_screen.gd")
const LandingSequence = preload("res://scripts/reclaim/flow/landing_sequence.gd")
const FlowSfx = preload("res://scripts/reclaim/flow/flow_sfx.gd")
## Landing zone and first player position for the opening landing cut.
const LANDING_ZONE := Vector2(300.0, -10.0)
const PLAYER_START := Vector2(180.0, 112.0)
const SAVE_PATH := "user://reclaim_save.json"
const CELL := 48.0
const PLAYER_RADIUS := 13.0
const GRID_SIZE := 7
const MAX_ENEMIES := 320
const WAVE_SECONDS := 22.0
const MAP_LIMIT := Vector2(2200.0, 1600.0)
const BASE_CELL := Vector2i(3, 3)
const PALETTE := {
	"bg": Color("#121719"), "ground": Color("#202826"), "road": Color("#303733"), "line": Color("#72796a"),
	"panel": Color("#202927"), "edge": Color("#566359"), "text": Color("#ece9dc"), "muted": Color("#a8b0a7"),
	"gold": Color("#d0a873"), "green": Color("#8db296"), "red": Color("#df7664"), "blue": Color("#78b7c2"), "white": Color("#ffffff")
}

var screen := "boot"
var player_index := 0
var difficulty_index := 1
var intro_index := 0
var player_pos := Vector2(190.0, 125.0)
var player_hp := 100.0
var player_max_hp := 100.0
var player_facing := Vector2.RIGHT
var aim_screen := Vector2.ZERO
var camera_zoom := 1.0
var manual_attack := false
var manual_trigger := false
var dash_direction := Vector2.RIGHT
var player_projectiles := PlayerProjectiles.new()
var enemy_spawn_id := 0
var dash_timer := 0.0
var dash_cooldown := 0.0
var player_attack_timer := 0.0
var player_reload_timer := 0.0
var player_magazine := 0
var player_xp := 0.0
var player_level := 1
var kills := 0
var run_seconds := 0.0
var stage := 1
var stage_elapsed := 0.0
var money := 150
var medals := 0
var boss_kills := 0
var difficulty: Dictionary = {}
var structures: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var enemy_pool: Array[Dictionary] = []
var zombie_corpses: Array[Dictionary] = []
var enemy_shots: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var selected_build := ""
var build_mode := false
var build_open := false
var build_tab := "turret"
var selected_entity := -1
var toast := ""
var toast_timer := 0.0
var spawn_timer := 1.0
var save_timer := 0.0
var income_timer := 0.0
var drone_timer := 0.0
var augments_taken := 0
var augment_reroll_used := false
var augment_options: Array[Dictionary] = []
var picked_augment_ids: Array[String] = []
var boss_40_spawned := false
var boss_80_spawned := false
var boss_100_spawned := false
var pending_final_boss := false
var win_state := false
var dead_count := 0
var player_mod_damage := 1.0
var player_mod_rate := 1.0
var player_mod_speed := 1.0
var player_mod_range := 1.0
var player_mod_armor := 1.0
var player_mod_xp := 1.0
var player_mod_salvage := 1.0
var player_mod_build := 1.0
var player_mod_building_hp := 1.0
var player_mod_turret_damage := 1.0
var player_mod_turret_rate := 1.0
var player_extra_pellets := 0
var player_pierce := 0
var player_drone_level := 0
var supply_income := 0
var research_bonus := 0
var sound_on := true
var bgm_volume := 100
var effects_volume := 100
var audio_save_timer: Timer
var zombie_sound_at := 0.0
var impact_sound_at := 0.0
var shake_on := true
var dash_key := KEY_SHIFT
var pause_key := KEY_ESCAPE
var awaiting_binding := ""
var permanent_upgrades: Dictionary = {}
var saved_run: Dictionary = {}
var _random := RandomNumberGenerator.new()
var _harin_visual = HarinVisual.new()
var player_motion := Vector2.ZERO
var boot_screen: Control
var flow_menu: Control
var flow_character: Control
var flow_difficulty: Control
var flow_prologue: Control
var flow_sfx: Node
var landing = LandingSequence.new()
## 0..1 while the HQ tent is being assembled in the landing cut; 1 = finished.
var hq_build_ratio := 1.0
var menu_screen: Control
var character_screen: Control
var difficulty_screen: Control
var intro_screen: Control
var settings_screen: Control
var perk_screen: Control
var game_ui: Control
var pause_screen: Control
var result_screen: Control
var augment_screen: Control
var build_panel: PanelContainer
var build_content: VBoxContainer
var build_status_label: Label
var hp_bar: ProgressBar
var base_bar: ProgressBar
var combat_label: Label
var status_label: Label
var stage_label: Label
var currency_label: Label
var boss_label: Label
var inspector_label: Label
var pause_label: Label
var result_title_label: Label
var result_stats_label: Label
var augment_title_label: Label
var augment_reroll_button: Button
var continue_button: Button
var dash_binding_button: Button
var pause_binding_button: Button
var perk_label: Label
var run_hud: Control


func _ready() -> void:
	_random.randomize()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_PASS
	aim_screen = get_local_mouse_position()
	set_process(true)
	set_process_unhandled_input(true)
	_load_data()
	AudioDirector.set_game_audio_mix(bgm_volume / 100.0, effects_volume / 100.0, sound_on)
	audio_save_timer = Timer.new()
	audio_save_timer.one_shot = true
	audio_save_timer.wait_time = 0.25
	audio_save_timer.timeout.connect(_save_all)
	add_child(audio_save_timer)
	flow_sfx = FlowSfx.new()
	add_child(flow_sfx)
	flow_sfx.enabled = sound_on
	_build_ui()
	_show_screen("boot")
	print("[reclaim-boot] 수도 탈환작전 · 한국어 메뉴 준비")


func _process(delta: float) -> void:
	queue_redraw()
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0:
			toast = ""
	if screen != "play" and screen != "augment":
		if screen == "landing":
			_update_landing(delta)
		_refresh_hud()
		return
	_update_player(delta)
	player_projectiles.update(delta, enemies, _damage_enemy)
	_harin_visual.update(delta, player_motion, player_hp, Data.CHARACTERS[player_index].id == "harin")
	_update_spawn(delta)
	_update_enemies(delta)
	_update_turrets(delta)
	_update_projectiles(delta)
	_update_effects(delta)
	_update_zombie_corpses(run_seconds + delta)
	_update_facilities(delta)
	_update_progress(delta)
	run_seconds += delta
	save_timer += delta
	if save_timer >= 12.0:
		save_timer = 0.0
		_save_all()
	_refresh_hud()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		aim_screen = get_global_transform_with_canvas().affine_inverse() * event.position
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		manual_trigger = false
	if screen == "play" and event is InputEventKey and (event.physical_keycode == KEY_TAB or event.keycode == KEY_TAB):
		get_viewport().set_input_as_handled()
		if event.pressed and not event.echo:
			manual_attack = not manual_attack


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		manual_trigger = false


func _unhandled_input(event: InputEvent) -> void:
	if awaiting_binding != "" and event is InputEventKey and event.pressed and not event.echo:
		var binding: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if binding == KEY_TAB:
			get_viewport().set_input_as_handled()
			return
		if awaiting_binding == "dash":
			dash_key = binding
		else:
			pause_key = binding
		awaiting_binding = ""
		_update_binding_labels()
		_save_all()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if screen == "landing" and (code == KEY_ESCAPE or code == KEY_SPACE or code == KEY_ENTER):
			skip_landing()
			get_viewport().set_input_as_handled()
			return
		if code == pause_key:
			if screen == "play":
				_toggle_pause()
			elif screen == "pause":
				_close_pause()
			elif screen == "augment":
				_show_toast("증강을 선택해야 작전이 계속됩니다.")
			get_viewport().set_input_as_handled()
			return
		if screen == "play":
			if code == KEY_B:
				_toggle_build_panel()
				get_viewport().set_input_as_handled()
			elif code == dash_key:
				_try_dash()
				get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.pressed and screen == "play":
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var step := 0.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -0.15
			camera_zoom = clampf(camera_zoom + step, 1.0, 1.6)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_cancel_build()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			manual_trigger = false
			if build_mode:
				_try_place_at(_screen_to_world(aim_screen))
			elif manual_attack and not build_open:
				manual_trigger = true
			else:
				_select_entity_at(_screen_to_world(aim_screen))
				manual_trigger = selected_entity < 0
			get_viewport().set_input_as_handled()


func _draw() -> void:
	if screen == "play" or screen == "pause" or screen == "augment" or screen == "result" or screen == "landing":
		_draw_world()
	else:
		_draw_menu_backdrop()


func _build_ui() -> void:
	boot_screen = BootScreen.new()
	boot_screen.visible = false
	add_child(boot_screen)
	boot_screen.finished.connect(_finish_boot)
	menu_screen = _new_screen()
	_build_menu()
	character_screen = _new_screen()
	_build_character_screen()
	difficulty_screen = _new_screen()
	_build_difficulty_screen()
	intro_screen = _new_screen()
	_build_intro_screen()
	settings_screen = _new_screen()
	_build_settings_screen()
	perk_screen = _new_screen()
	_build_perk_screen()
	game_ui = _new_screen()
	_build_game_hud()
	pause_screen = _new_screen()
	_build_pause_screen()
	result_screen = _new_screen()
	_build_result_screen()
	augment_screen = _new_screen()
	_build_augment_screen()


func _new_screen() -> Control:
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	c.visible = false
	add_child(c)
	return c


func _panel_style(accent: Color = PALETTE.gold) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(PALETTE.panel, 0.96)
	style.border_color = Color(accent, 0.62)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 20.0
	style.content_margin_bottom = 20.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 18
	return style


func _button_style(accent: Color = PALETTE.gold, hovered := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent, 0.18 if hovered else 0.08)
	style.border_color = Color(accent, 0.9 if hovered else 0.44)
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 9.0
	style.content_margin_bottom = 9.0
	return style


func _make_button(text: String, callback: Callable, accent: Color = PALETTE.gold, width := 330.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(width, 46)
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", PALETTE.text)
	b.add_theme_color_override("font_hover_color", PALETTE.white)
	b.add_theme_color_override("font_pressed_color", PALETTE.gold)
	b.add_theme_stylebox_override("normal", _button_style(accent))
	b.add_theme_stylebox_override("hover", _button_style(accent, true))
	b.add_theme_stylebox_override("pressed", _button_style(accent, true))
	b.add_theme_stylebox_override("focus", _button_style(PALETTE.blue, true))
	b.pressed.connect(callback)
	return b


func _make_label(text: String, font_size := 18, color: Color = PALETTE.text, centered := false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_y", 2)
	if centered:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _center_box(parent: Control) -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)
	return box


func _add_heading(box: VBoxContainer, title: String, subtitle: String = "") -> void:
	var h := _make_label(title, 38, PALETTE.gold, true)
	h.custom_minimum_size.x = 480
	box.add_child(h)
	if subtitle != "":
		var sub := _make_label(subtitle, 15, PALETTE.muted, true)
		box.add_child(sub)


func _build_menu() -> void:
	flow_menu = MainMenuScreen.new()
	menu_screen.add_child(flow_menu)
	flow_menu.start_pressed.connect(_on_menu_start)
	flow_menu.continue_pressed.connect(_on_menu_continue)
	flow_menu.settings_pressed.connect(func(): _ui_sound(); _show_settings())
	flow_menu.perks_pressed.connect(func(): _ui_sound(); _show_perks())
	flow_menu.quit_pressed.connect(_quit_game)
	flow_menu.set_continue_available(not saved_run.is_empty())
func _build_character_screen() -> void:
	flow_character = CharacterSelectScreen.new()
	character_screen.add_child(flow_character)
	flow_character.chosen.connect(_choose_character)
	flow_character.back_pressed.connect(func(): _ui_sound(); _show_screen("menu"))
func _build_difficulty_screen() -> void:
	flow_difficulty = DifficultyScreen.new()
	difficulty_screen.add_child(flow_difficulty)
	flow_difficulty.chosen.connect(_choose_difficulty)
	flow_difficulty.back_pressed.connect(func(): _ui_sound(); _show_screen("character"))
func _build_intro_screen() -> void:
	flow_prologue = PrologueScreen.new()
	flow_prologue.sfx = flow_sfx
	intro_screen.add_child(flow_prologue)
	flow_prologue.finished.connect(_launch_run)
func _build_settings_screen() -> void:
	var box := _center_box(settings_screen)
	_add_heading(box, "설정 · 조작", "WASD 이동은 고정 · 회피와 일시정지 키는 재지정 가능")
	dash_binding_button = _make_button("", _begin_dash_binding, PALETTE.blue, 380)
	box.add_child(dash_binding_button)
	pause_binding_button = _make_button("", _begin_pause_binding, PALETTE.blue, 380)
	box.add_child(pause_binding_button)
	box.add_child(_make_button("화면 효과: 켬", _toggle_effects, PALETTE.blue, 380))
	box.add_child(_make_button("배경음/효과음: %s" % ("켬" if sound_on else "끔"), _toggle_sound, PALETTE.blue, 380))
	_add_volume_slider(box, "배경음악", bgm_volume, true)
	_add_volume_slider(box, "효과음", effects_volume, false)
	box.add_child(_make_button("메뉴로", _show_screen.bind("menu"), PALETTE.gold, 260))
	_update_binding_labels()


func _add_volume_slider(box: VBoxContainer, title: String, value: int, is_bgm: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var title_label := _make_label(title, 15, PALETTE.text)
	title_label.custom_minimum_size.x = 80.0
	row.add_child(title_label)
	var slider := HSlider.new()
	slider.name = "BgmVolume" if is_bgm else "EffectsVolume"
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = value
	slider.custom_minimum_size = Vector2(190, 26)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	var percent := _make_label("%d%%" % value, 15, PALETTE.gold)
	percent.custom_minimum_size.x = 45.0
	percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(percent)
	slider.value_changed.connect(_set_audio_volume.bind(is_bgm, percent))
	box.add_child(row)


func _set_audio_volume(value: float, is_bgm: bool, percent: Label) -> void:
	if is_bgm:
		bgm_volume = roundi(value)
	else:
		effects_volume = roundi(value)
	percent.text = "%d%%" % roundi(value)
	AudioDirector.set_game_audio_mix(bgm_volume / 100.0, effects_volume / 100.0, sound_on)
	audio_save_timer.start()


func _build_perk_screen() -> void:
	var box := _center_box(perk_screen)
	box.add_child(_make_label("작전 훈장 강화", 34, PALETTE.gold, true))
	perk_label = _make_label("", 14, PALETTE.muted, true)
	box.add_child(perk_label)
	for perk in Data.PERMANENT_PERKS:
		box.add_child(_make_button("", _buy_perk.bind(String(perk.id)), PALETTE.green, 390))
		box.get_child(box.get_child_count() - 1).set_meta("perk_id", perk.id)
	box.add_child(_make_button("메뉴로", _show_screen.bind("menu"), PALETTE.blue, 260))


func _build_game_hud() -> void:
	run_hud = Control.new()
	run_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	run_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_ui.add_child(run_hud)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 16)
	panel.custom_minimum_size = Vector2(316, 174)
	panel.add_theme_stylebox_override("panel", _panel_style(PALETTE.green))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	run_hud.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	panel.add_child(column)
	stage_label = _make_label("1일차  /  준비", 16, PALETTE.gold)
	column.add_child(stage_label)
	var p_lab := _make_label("대원 체력", 12, PALETTE.muted)
	column.add_child(p_lab)
	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(276, 16)
	hp_bar.show_percentage = false
	column.add_child(hp_bar)
	var b_lab := _make_label("지휘본부", 12, PALETTE.muted)
	column.add_child(b_lab)
	base_bar = ProgressBar.new()
	base_bar.custom_minimum_size = Vector2(276, 16)
	base_bar.show_percentage = false
	column.add_child(base_bar)
	currency_label = _make_label("보급품 150  ·  처치 0  ·  훈장 0", 13, PALETTE.text)
	column.add_child(currency_label)
	combat_label = _make_label("", 14, PALETTE.gold)
	column.add_child(combat_label)
	status_label = _make_label("", 13, PALETTE.gold)
	status_label.position = Vector2(350, 28)
	status_label.custom_minimum_size = Vector2(500, 26)
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	run_hud.add_child(status_label)
	boss_label = _make_label("", 16, PALETTE.red, true)
	boss_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	boss_label.offset_top = 18
	boss_label.offset_bottom = 52
	boss_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	run_hud.add_child(boss_label)
	var buttons := HBoxContainer.new()
	buttons.anchor_left = 1.0
	buttons.anchor_right = 1.0
	buttons.offset_left = -316
	buttons.offset_right = -16
	buttons.offset_top = 16
	buttons.offset_bottom = 62
	buttons.add_theme_constant_override("separation", 8)
	run_hud.add_child(buttons)
	buttons.add_child(_make_button("건설 [B]", _toggle_build_panel, PALETTE.gold, 154))
	buttons.add_child(_make_button("일시정지", _toggle_pause, PALETTE.blue, 132))
	build_panel = PanelContainer.new()
	build_panel.anchor_left = 1.0
	build_panel.anchor_right = 1.0
	build_panel.anchor_top = 0.18
	build_panel.anchor_bottom = 0.90
	build_panel.offset_left = -354
	build_panel.offset_right = -16
	build_panel.add_theme_stylebox_override("panel", _panel_style(PALETTE.gold))
	build_panel.visible = false
	build_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	run_hud.add_child(build_panel)
	build_content = VBoxContainer.new()
	build_content.add_theme_constant_override("separation", 8)
	build_panel.add_child(build_content)
	build_status_label = _make_label("시설을 고르고 전장 칸을 클릭하세요. 전투는 계속됩니다.", 12, PALETTE.muted)
	build_status_label.custom_minimum_size.y = 30
	build_content.add_child(build_status_label)
	var hint := _make_label("건설 [B]: 시설 선택/배치   우클릭: 취소", 12, PALETTE.muted, true)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -31
	hint.offset_bottom = -8
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	run_hud.add_child(hint)
	var toast_label := _make_label("", 18, PALETTE.gold, true)
	toast_label.name = "Toast"
	toast_label.anchor_left = 0.2
	toast_label.anchor_right = 0.8
	toast_label.anchor_top = 0.82
	toast_label.anchor_bottom = 0.90
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	run_hud.add_child(toast_label)
	var inspector := PanelContainer.new()
	inspector.name = "Inspector"
	inspector.anchor_left = 1.0
	inspector.anchor_right = 1.0
	inspector.anchor_top = 0.18
	inspector.anchor_bottom = 0.90
	inspector.offset_left = -354
	inspector.offset_right = -16
	inspector.add_theme_stylebox_override("panel", _panel_style(PALETTE.blue))
	inspector.visible = false
	run_hud.add_child(inspector)
	var ivbox := VBoxContainer.new()
	ivbox.name = "InspectorContent"
	ivbox.add_theme_constant_override("separation", 9)
	inspector.add_child(ivbox)
	inspector_label = _make_label("", 16, PALETTE.text)
	ivbox.add_child(inspector_label)
	ivbox.add_child(_make_button("강화", _upgrade_selected, PALETTE.green, 270))
	ivbox.add_child(_make_button("철거", _remove_selected, PALETTE.red, 270))
	ivbox.add_child(_make_button("닫기", _close_inspector, PALETTE.blue, 270))
	game_ui.visible = false


func _build_pause_screen() -> void:
	var box := _center_box(pause_screen)
	box.add_theme_constant_override("separation", 14)
	pause_label = _make_label("작전 일시정지", 34, PALETTE.gold, true)
	box.add_child(pause_label)
	box.add_child(_make_button("계속", _close_pause, PALETTE.green, 320))
	box.add_child(_make_button("현재 작전 저장 후 메뉴", _leave_to_menu, PALETTE.blue, 320))
	box.add_child(_make_button("새 작전 시작", _return_to_start, PALETTE.red, 320))


func _build_result_screen() -> void:
	var box := _center_box(result_screen)
	box.add_theme_constant_override("separation", 14)
	result_title_label = _make_label("작전 결과", 38, PALETTE.gold, true)
	box.add_child(result_title_label)
	result_stats_label = _make_label("", 17, PALETTE.text, true)
	result_stats_label.custom_minimum_size = Vector2(470, 128)
	box.add_child(result_stats_label)
	box.add_child(_make_label("실제 밸런스와 장기 성능은 추가 테스트가 필요합니다.", 13, PALETTE.muted, true))
	box.add_child(_make_button("같은 조건으로 재도전", _retry_run, PALETTE.green, 340))
	box.add_child(_make_button("메인 메뉴", _leave_to_menu, PALETTE.blue, 340))


func _build_augment_screen() -> void:
	var box := _center_box(augment_screen)
	box.add_theme_constant_override("separation", 6)
	augment_title_label = _make_label("현장 증강 선택", 18, PALETTE.gold, true)
	box.add_child(augment_title_label)
	box.add_child(_make_label("3개 중 1개를 선택합니다. 선택 중에도 전투는 멈추지 않습니다.", 11, PALETTE.muted, true))
	var row := HBoxContainer.new()
	row.name = "AugmentCards"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)
	augment_reroll_button = Button.new()
	augment_reroll_button.text = "무료 리롤 1회"
	augment_reroll_button.flat = true
	augment_reroll_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	augment_reroll_button.add_theme_font_size_override("font_size", 12)
	augment_reroll_button.add_theme_color_override("font_color", PALETTE.blue)
	augment_reroll_button.pressed.connect(_reroll_augments)
	box.add_child(augment_reroll_button)


func _show_screen(which: String) -> void:
	if screen == "settings" and which != "settings" and not audio_save_timer.is_stopped():
		audio_save_timer.stop()
		_save_all()
	var was_in_combat := screen in ["play", "augment", "pause"]
	if which != "play":
		manual_trigger = false
	screen = which
	boot_screen.visible = which == "boot"
	for c in [menu_screen, character_screen, difficulty_screen, intro_screen, settings_screen, perk_screen, game_ui, pause_screen, result_screen, augment_screen]:
		c.visible = false
	match which:
		"menu": menu_screen.visible = true
		"character": character_screen.visible = true
		"difficulty": difficulty_screen.visible = true
		"intro": intro_screen.visible = true
		"landing": pass
		"settings": settings_screen.visible = true
		"perks": perk_screen.visible = true
		"play": game_ui.visible = true
		"pause":
			game_ui.visible = true
			pause_screen.visible = true
		"result": result_screen.visible = true
		"augment":
			game_ui.visible = true
			augment_screen.visible = true
			_rebuild_augment_cards()
	if which == "menu":
		flow_menu.set_continue_available(not saved_run.is_empty())
		flow_menu.on_shown()
	if which == "character": flow_character.on_shown()
	if which == "settings": _update_binding_labels()
	if which == "perks": _update_perk_screen()
	AudioDirector.set_game_paused(which == "pause")
	if sound_on and which in ["play", "augment"]:
		AudioDirector.play_music("music.gameplay")
	elif was_in_combat and which != "pause":
		AudioDirector.stop_music()
	_refresh_hud()
	queue_redraw()


func _show_character_select() -> void:
	_show_screen("character")


func _choose_character(index: int) -> void:
	_ui_sound(true)
	player_index = clampi(index, 0, Data.CHARACTERS.size() - 1)
	flow_difficulty.setup(player_index, difficulty_index)
	_show_screen("difficulty")
func _choose_difficulty(index: int) -> void:
	_ui_sound(true)
	difficulty_index = clampi(index, 0, Data.DIFFICULTIES.size() - 1)
	intro_index = 0
	_show_screen("intro")
	flow_prologue.start(player_index, LANDING_ZONE)
func _finish_boot() -> void:
	_show_screen("menu")
func _on_menu_start() -> void:
	AudioDirector.unlock_audio()
	_ui_sound(true)
	_show_character_select()
func _on_menu_continue() -> void:
	AudioDirector.unlock_audio()
	_ui_sound(true)
	_resume_run()
func _quit_game() -> void:
	if OS.has_feature("web"):
		_ui_sound()
		flow_menu.show_notice("웹 버전은 브라우저 탭을 닫으면 종료됩니다.")
		return
	_save_all()
	flow_sfx.stop_all()
	# Let the audio mixer release stopped playbacks before exiting.
	await get_tree().create_timer(0.12).timeout
	get_tree().quit()
func _ui_sound(confirm := false) -> void:
	if flow_sfx != null:
		flow_sfx.play("confirm" if confirm else "click", -8.0)
func _launch_run() -> void:
	_start_new_run()


func _start_new_run() -> void:
	_reset_run()
	# Landing cut on the real map: helicopter descends, operator disembarks,
	# the HQ tent is assembled, the helicopter leaves; then control begins.
	var hq: Dictionary = structures[0]
	hq_build_ratio = 0.0
	landing.setup(LANDING_ZONE, PLAYER_START, _entry_world_center(hq), flow_sfx)
	player_pos = landing.player_world()
	_show_screen("landing")
func _update_landing(delta: float) -> void:
	landing.update(delta)
	var before := player_pos
	player_pos = landing.player_world()
	player_motion = (player_pos - before) / maxf(delta, 0.001)
	if player_motion.length() > 1.0:
		player_facing = player_motion.normalized()
	_harin_visual.update(delta, player_motion, player_hp, Data.CHARACTERS[player_index].id == "harin")
	hq_build_ratio = maxf(0.0, landing.hq_ratio())
	if landing.done:
		_finish_landing()
func skip_landing() -> void:
	landing.skip()
	_finish_landing()
func _finish_landing() -> void:
	hq_build_ratio = 1.0
	player_pos = PLAYER_START
	player_motion = Vector2.ZERO
	if flow_sfx != null: flow_sfx.set_rotor(0.0)
	_show_screen("play")
	_show_toast("작전 개시 · WASD 이동 · 군용 텐트 HQ를 지켜라")
	_save_all()


func _reset_run() -> void:
	difficulty = Data.DIFFICULTIES[difficulty_index].duplicate(true)
	stage = 1
	stage_elapsed = 0.0
	run_seconds = 0.0
	zombie_sound_at = 0.0
	impact_sound_at = 0.0
	money = 150
	kills = 0
	boss_kills = 0
	dead_count = 0
	player_xp = 0.0
	player_level = 1
	augments_taken = 0
	augment_reroll_used = false
	picked_augment_ids.clear()
	structures.clear()
	enemies.clear()
	zombie_corpses.clear()
	enemy_pool.clear()
	enemy_shots.clear()
	player_projectiles.shots.clear()
	effects.clear()
	boss_40_spawned = false
	boss_80_spawned = false
	boss_100_spawned = false
	pending_final_boss = false
	win_state = false
	player_mod_damage = 1.0
	player_mod_rate = 1.0
	player_mod_speed = 1.0
	player_mod_range = 1.0
	player_mod_armor = 1.0
	player_mod_xp = 1.0
	player_mod_salvage = 1.0
	player_mod_build = 1.0
	player_mod_building_hp = 1.0
	player_mod_turret_damage = 1.0
	player_mod_turret_rate = 1.0
	player_extra_pellets = 0
	player_pierce = 0
	player_drone_level = 0
	supply_income = 0
	research_bonus = 0
	var hero: Dictionary = Data.CHARACTERS[player_index]
	player_max_hp = float(hero.hp) + float(permanent_upgrades.get("health", 0)) * 15.0
	player_hp = player_max_hp
	player_pos = PLAYER_START
	player_facing = Vector2.RIGHT
	player_attack_timer = 0.0
	player_reload_timer = 0.0
	player_magazine = int(hero.magazine)
	manual_attack = false
	manual_trigger = false
	dash_timer = 0.0
	dash_cooldown = 0.0
	player_mod_damage += float(permanent_upgrades.get("damage", 0)) * 0.06
	player_mod_speed += float(permanent_upgrades.get("speed", 0)) * 0.04
	player_mod_range += float(permanent_upgrades.get("range", 0)) * 0.05
	player_mod_build = maxf(0.55, player_mod_build - float(permanent_upgrades.get("build", 0)) * 0.04)
	player_mod_building_hp += float(permanent_upgrades.get("building_hp", 0)) * 0.08
	player_mod_rate += float(permanent_upgrades.get("reload", 0)) * 0.04
	player_mod_salvage += float(permanent_upgrades.get("salvage", 0)) * 0.05
	var hp := 1600.0 * player_mod_building_hp
	structures.append({"kind": "hq", "cell": BASE_CELL, "hp": hp, "max_hp": hp, "level": 1, "cool": 0.0, "built": true})
	spawn_timer = 2.0
	income_timer = 0.0
	save_timer = 0.0
	build_mode = false
	build_open = false
	selected_build = ""
	selected_entity = -1
	build_panel.visible = false


func _resume_run() -> void:
	if saved_run.is_empty():
		_show_character_select()
		return
	_load_saved_run()
	_show_screen("play")
	_show_toast("저장된 작전을 이어갑니다.")


func _load_saved_run() -> void:
	var state: Dictionary = saved_run.duplicate(true)
	player_index = clampi(int(state.get("hero", 0)), 0, Data.CHARACTERS.size() - 1)
	difficulty_index = clampi(int(state.get("difficulty", 1)), 0, Data.DIFFICULTIES.size() - 1)
	difficulty = Data.DIFFICULTIES[difficulty_index].duplicate(true)
	stage = clampi(int(state.get("stage", 1)), 1, 100)
	stage_elapsed = float(state.get("stage_elapsed", 0.0))
	run_seconds = float(state.get("run_seconds", 0.0))
	money = int(state.get("money", 0))
	kills = int(state.get("kills", 0))
	player_level = int(state.get("level", 1))
	player_xp = float(state.get("xp", 0.0))
	boss_kills = int(state.get("boss_kills", 0))
	var hero: Dictionary = Data.CHARACTERS[player_index]
	player_max_hp = float(state.get("player_max_hp", hero.hp))
	player_hp = clampf(float(state.get("player_hp", player_max_hp)), 1.0, player_max_hp)
	player_projectiles.shots.clear()
	enemy_shots.clear()
	var capacity := int(hero.magazine)
	player_magazine = clampi(int(state.get("magazine", capacity)), 0, capacity)
	player_attack_timer = 0.0
	player_reload_timer = 0.0
	if capacity > 0 and player_magazine == 0:
		player_reload_timer = clampf(float(state.get("reload_remaining", hero.reload)), 0.0, float(hero.reload))
		if player_reload_timer == 0.0:
			player_magazine = capacity
	manual_attack = bool(state.get("manual_attack", false))
	manual_trigger = false
	var pp: Array = state.get("player_pos", [180.0, 112.0])
	player_pos = Vector2(float(pp[0]), float(pp[1]))
	structures.clear()
	for entry in state.get("structures", []):
		structures.append({"kind": String(entry.get("kind", "wall")), "cell": Vector2i(int(entry.get("x", 0)), int(entry.get("y", 0))), "hp": float(entry.get("hp", 100.0)), "max_hp": float(entry.get("max_hp", 100.0)), "level": int(entry.get("level", 1)), "cool": 0.0, "built": true})
	if structures.is_empty():
		structures.append({"kind": "hq", "cell": BASE_CELL, "hp": 1200.0, "max_hp": 1200.0, "level": 1, "cool": 0.0, "built": true})
	enemies.clear()
	zombie_corpses.clear()
	for entry in state.get("enemies", []):
		var enemy: Dictionary = _make_enemy(String(entry.get("kind", "normal")), Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0))), bool(entry.get("boss", false)))
		enemy.hp = float(entry.get("hp", enemy.max_hp))
		enemy.cool = float(entry.get("cool", 0.5))
		var saved_variant := int(entry.get("variant", -1))
		if enemy.has("variant") and saved_variant >= 0 and saved_variant < ZombieVisual.SHEETS.size():
			enemy.variant = saved_variant
		enemies.append(enemy)
	boss_40_spawned = stage >= 40
	boss_80_spawned = stage >= 80
	boss_100_spawned = stage >= 100
	pending_final_boss = stage >= 100
	_restore_run_modifiers()
	win_state = false
	spawn_timer = 1.5
	augment_reroll_used = false
	build_mode = false
	selected_build = ""
	build_open = false
	build_panel.visible = false


func _toggle_pause() -> void:
	if screen != "play": return
	_save_all()
	_show_screen("pause")


func _close_pause() -> void:
	if screen == "pause": _show_screen("play")


func _leave_to_menu() -> void:
	if screen == "pause":
		_save_all()
	_show_screen("menu")


func _return_to_start() -> void:
	_reset_run()
	_show_character_select()


func _retry_run() -> void:
	_start_new_run()


func _show_settings() -> void:
	_show_screen("settings")


func _show_perks() -> void:
	_show_screen("perks")


func _begin_dash_binding() -> void:
	awaiting_binding = "dash"
	_update_binding_labels()


func _begin_pause_binding() -> void:
	awaiting_binding = "pause"
	_update_binding_labels()


func _update_binding_labels() -> void:
	if dash_binding_button != null:
		dash_binding_button.text = "회피 키: %s" % ("아무 키나 누르세요…" if awaiting_binding == "dash" else OS.get_keycode_string(dash_key))
	if pause_binding_button != null:
		pause_binding_button.text = "일시정지 키: %s" % ("아무 키나 누르세요…" if awaiting_binding == "pause" else OS.get_keycode_string(pause_key))


func _toggle_effects() -> void:
	shake_on = not shake_on
	var button := _button_by_text(settings_screen, "화면 효과")
	if button: button.text = "화면 효과: %s" % ("켬" if shake_on else "끔")
	_save_all()


func _toggle_sound() -> void:
	sound_on = not sound_on
	AudioDirector.set_game_audio_mix(bgm_volume / 100.0, effects_volume / 100.0, sound_on)
	if flow_sfx != null: flow_sfx.enabled = sound_on
	if not sound_on:
		AudioDirector.stop_music(0.0)
	var button := _button_by_text(settings_screen, "배경음/효과음")
	if button: button.text = "배경음/효과음: %s" % ("켬" if sound_on else "끔")
	_save_all()


func _button_by_text(parent: Node, prefix: String) -> Button:
	for child in parent.find_children("*", "Button", true, false):
		var b := child as Button
		if b.text.begins_with(prefix): return b
	return null


func _update_perk_screen() -> void:
	if perk_label == null: return
	perk_label.text = "보유 작전 훈장: %d  ·  작전 중 특수 적과 단계 보스로 획득" % medals
	for child in perk_screen.find_children("*", "Button", true, false):
		var b := child as Button
		if not b.has_meta("perk_id"): continue
		var id := String(b.get_meta("perk_id"))
		var perk: Dictionary = {}
		for item in Data.PERMANENT_PERKS:
			if item.id == id: perk = item; break
		var level := int(permanent_upgrades.get(id, 0))
		var cost := (level + 1) * 5
		b.text = "%s  ·  %d/5  ·  다음 강화 %d 훈장" % [String(perk.get("name", id)), level, cost] if level < 5 else "%s  ·  최대 강화" % String(perk.get("name", id))
		b.disabled = level >= 5 or medals < cost


func _buy_perk(id: String) -> void:
	var level := int(permanent_upgrades.get(id, 0))
	if level >= 5: return
	var cost := (level + 1) * 5
	if medals < cost:
		_show_toast("훈장이 부족합니다.")
		return
	medals -= cost
	permanent_upgrades[id] = level + 1
	_save_all()
	_update_perk_screen()


func _toggle_build_panel() -> void:
	if screen != "play": return
	build_open = not build_open
	build_panel.visible = build_open
	selected_entity = -1
	var inspector := run_hud.find_child("Inspector", true, false) as Control
	if inspector: inspector.visible = false
	if build_open: _refresh_build_panel()
	else: _cancel_build()


func _cancel_build() -> void:
	build_mode = false
	selected_build = ""
	if build_status_label != null and build_open:
		build_status_label.text = "시설을 고르고 전장 칸을 클릭하세요. 전투는 계속됩니다."
	queue_redraw()


func _refresh_build_panel() -> void:
	if build_content == null: return
	for child in build_content.get_children():
		if child != build_status_label:
			child.queue_free()
	var title := _make_label("실시간 건설", 21, PALETTE.gold)
	build_content.add_child(title)
	var tabrow := HBoxContainer.new()
	tabrow.add_theme_constant_override("separation", 5)
	build_content.add_child(tabrow)
	for tab in ["turret", "building", "wall"]:
		var tab_title: String = String({"turret": "포탑", "building": "시설", "wall": "방벽"}.get(tab, "건설"))
		tabrow.add_child(_make_button(tab_title, _select_build_tab.bind(tab), PALETTE.blue if build_tab == tab else PALETTE.gold, 90))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 250
	build_content.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 5)
	scroll.add_child(list)
	if build_tab == "turret":
		for item in Data.TURRETS:
			list.add_child(_make_button("%s  ·  %d 보급품\n%s" % [item.name, _effective_cost(int(item.cost)), item.role], _select_build.bind(String(item.id)), item.color, 285))
	elif build_tab == "building":
		for item in Data.BUILDINGS:
			list.add_child(_make_button("%s  ·  %d 보급품\n%s" % [item.name, _effective_cost(int(item.cost)), item.role], _select_build.bind(String(item.id)), PALETTE.green, 285))
	else:
		list.add_child(_make_button("모래주머니 방벽  ·  12 보급품\n1×1칸 · 사방 출입구를 막을 수 없습니다", _select_build.bind("wall"), PALETTE.gold, 285))
	build_content.add_child(_make_button("선택 취소", _cancel_build, PALETTE.red, 285))
	build_content.move_child(build_status_label, 0)


func _select_build_tab(tab: String) -> void:
	build_tab = tab
	_cancel_build()
	_refresh_build_panel()


func _select_build(kind: String) -> void:
	selected_build = kind
	build_mode = true
	selected_entity = -1
	var item := _build_definition(kind)
	build_status_label.text = "%s 선택됨 · 설치 칸을 클릭하세요 (B 취소)" % String(item.get("name", "방벽"))
	var inspector := run_hud.find_child("Inspector", true, false) as Control
	if inspector: inspector.visible = false


func _effective_cost(base: int) -> int:
	var hero: Dictionary = Data.CHARACTERS[player_index]
	var reduction := player_mod_build - (0.10 if hero.id == "yujin" else 0.0)
	return maxi(1, int(round(float(base) * maxf(0.5, reduction))))


func _build_definition(kind: String) -> Dictionary:
	for item in Data.TURRETS:
		if String(item.id) == kind: return item
	for item in Data.BUILDINGS:
		if String(item.id) == kind: return item
	if kind == "wall": return {"id": "wall", "name": "모래주머니 방벽", "cost": 12, "hp": 180.0, "color": PALETTE.gold, "role": "1×1칸"}
	return {"id": kind, "name": kind, "cost": 0, "hp": 0.0, "color": PALETTE.green}


func _is_turret(kind: String) -> bool:
	for item in Data.TURRETS:
		if String(item.id) == kind: return true
	return false


func _is_building(kind: String) -> bool:
	for item in Data.BUILDINGS:
		if String(item.id) == kind: return true
	return false


func _grid_cell(point: Vector2) -> Vector2i:
	return Vector2i(roundi(point.x / CELL) + 3, roundi(point.y / CELL) + 3)


func _cell_world(cell: Vector2i) -> Vector2:
	return Vector2(float(cell.x - 3) * CELL, float(cell.y - 3) * CELL)


func _occupied_cells(entry: Dictionary) -> Array[Vector2i]:
	var kind := String(entry.get("kind", "wall"))
	var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
	var width := 2 if kind == "hq" or _is_building(kind) else 1
	var cells: Array[Vector2i] = []
	for x in range(width): cells.append(Vector2i(cell.x + x, cell.y))
	return cells


func _cell_is_entrance(cell: Vector2i) -> bool:
	return cell == Vector2i(3, 0) or cell == Vector2i(3, 6) or cell == Vector2i(0, 3) or cell == Vector2i(6, 3)


func _validate_placement(kind: String, cell: Vector2i) -> String:
	var definition := _build_definition(kind)
	var width := 2 if _is_building(kind) else 1
	if cell.x < 0 or cell.y < 0 or cell.x + width > GRID_SIZE or cell.y >= GRID_SIZE:
		return "건설 구역 밖입니다."
	if kind == "wall" and _cell_is_entrance(cell):
		return "동서남북 영구 출입구는 막을 수 없습니다."
	var occupied_count := 0
	for entry in structures:
		if float(entry.get("hp", 0.0)) <= 0.0: continue
		for used in _occupied_cells(entry):
			for dx in range(width):
				if used == Vector2i(cell.x + dx, cell.y): occupied_count += 1
	if occupied_count > 0: return "이미 다른 시설이 점유한 칸입니다."
	var center := _cell_world(cell) + Vector2(CELL * 0.5 * float(width - 1), 0.0)
	var overlap_depth := _structure_overlap_depth(player_pos, center, width, PLAYER_RADIUS)
	if overlap_depth >= 0.0: return "대원이 서 있는 곳에는 배치할 수 없습니다."
	if kind != "wall" and kind != "hq":
		for entry in structures:
			if String(entry.kind) == kind and float(entry.hp) > 0.0:
				return "같은 종류의 시설은 한 개만 지을 수 있습니다."
	if _is_turret(kind):
		var cap := 8 if Data.CHARACTERS[player_index].id == "yujin" else 6
		var count := 0
		for entry in structures:
			if _is_turret(String(entry.kind)) and float(entry.hp) > 0.0: count += 1
		if count >= cap: return "포탑 한도 %d기에 도달했습니다." % cap
	var cost := _effective_cost(int(definition.get("cost", 0)))
	if money < cost: return "보급품이 부족합니다. 필요: %d" % cost
	if kind == "wall" and not _path_stays_open(cell): return "방벽이 기지 탈출 경로를 막습니다."
	return ""


func _path_stays_open(new_cell: Vector2i) -> bool:
	var blocked: Dictionary = {}
	for entry in structures:
		if float(entry.get("hp", 0.0)) <= 0.0: continue
		for cell in _occupied_cells(entry): blocked[cell] = true
	blocked[new_cell] = true
	var goals: Array[Vector2i] = [Vector2i(2, 3), Vector2i(5, 3), Vector2i(3, 2), Vector2i(3, 4)]
	var starts: Array[Vector2i] = [Vector2i(3, 0), Vector2i(3, 6), Vector2i(0, 3), Vector2i(6, 3)]
	for index in range(4):
		if not _grid_path_exists(starts[index], goals[index], blocked): return false
	return true


func _grid_path_exists(start: Vector2i, goal: Vector2i, blocked: Dictionary) -> bool:
	var queue: Array[Vector2i] = [start]
	var seen: Dictionary = {start: true}
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if cur == goal: return true
		for step in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next: Vector2i = cur + step
			if next.x < 0 or next.y < 0 or next.x >= GRID_SIZE or next.y >= GRID_SIZE: continue
			if blocked.has(next) or seen.has(next): continue
			seen[next] = true
			queue.append(next)
	return false


func _try_place_at(world_point: Vector2) -> void:
	if selected_build == "": return
	var cell := _grid_cell(world_point)
	var problem := _validate_placement(selected_build, cell)
	if problem != "":
		_show_toast(problem)
		build_status_label.text = problem
		return
	var def := _build_definition(selected_build)
	var cost := _effective_cost(int(def.get("cost", 0)))
	var maxhp := float(def.get("hp", 180.0)) * player_mod_building_hp
	money -= cost
	structures.append({"kind": selected_build, "cell": cell, "hp": maxhp, "max_hp": maxhp, "level": 1, "cool": 0.35, "built": true})
	_show_toast("%s 설치 완료 · 전투는 계속됩니다." % String(def.name))
	build_status_label.text = "%s 설치됨 · 다시 시설을 고르거나 계속 건설하세요." % String(def.name)
	selected_build = ""
	build_mode = false
	_save_all()
	queue_redraw()


func _select_entity_at(world_point: Vector2) -> void:
	var best := -1
	var best_distance := 44.0
	for i in range(structures.size()):
		var s := structures[i]
		if float(s.hp) <= 0.0: continue
		var center := _entry_world_center(s)
		var d := center.distance_to(world_point)
		if d < best_distance:
			best_distance = d
			best = i
	if best >= 0:
		selected_entity = best
		_open_inspector()
	else:
		selected_entity = -1
		var inspector := run_hud.find_child("Inspector", true, false) as Control
		if inspector: inspector.visible = false


func _entry_world_center(entry: Dictionary) -> Vector2:
	var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
	var kind := String(entry.get("kind", ""))
	return _cell_world(cell) + (Vector2(CELL * 0.5, 0) if kind == "hq" or _is_building(kind) else Vector2.ZERO)


func _open_inspector() -> void:
	if selected_entity < 0 or selected_entity >= structures.size(): return
	build_panel.visible = false
	build_open = false
	var inspector := run_hud.find_child("Inspector", true, false) as Control
	inspector.visible = true
	var s: Dictionary = structures[selected_entity]
	var def := _build_definition(String(s.kind))
	inspector_label.text = "%s\n레벨 %d  ·  내구도 %d/%d\n%s" % [String(def.get("name", "군용 텐트 HQ")), int(s.level), int(s.hp), int(s.max_hp), String(def.get("role", "지휘본부 · 파괴 시 패배"))]


func _close_inspector() -> void:
	var inspector := run_hud.find_child("Inspector", true, false) as Control
	if inspector: inspector.visible = false
	selected_entity = -1


func _upgrade_selected() -> void:
	if selected_entity < 0 or selected_entity >= structures.size(): return
	var s: Dictionary = structures[selected_entity]
	var kind := String(s.kind)
	if int(s.level) >= 5:
		_show_toast("최대 레벨입니다.")
		return
	var cost := 30 + int(s.level) * 24
	if money < cost:
		_show_toast("강화에 보급품 %d개가 필요합니다." % cost)
		return
	money -= cost
	s.level = int(s.level) + 1
	s.max_hp *= 1.22
	s.hp = minf(float(s.max_hp), float(s.hp) + float(s.max_hp) * 0.28)
	if _is_turret(kind):
		for item in Data.TURRETS:
			if item.id == kind:
				s.damage = float(item.damage) * (1.0 + (int(s.level) - 1) * 0.35)
	_show_toast("%s 레벨 %d 강화" % [String(_build_definition(kind).get("name", kind)), int(s.level)])
	_open_inspector()
	_save_all()


func _remove_selected() -> void:
	if selected_entity < 0 or selected_entity >= structures.size(): return
	var s: Dictionary = structures[selected_entity]
	if String(s.kind) == "hq":
		_show_toast("지휘본부는 철거할 수 없습니다.")
		return
	money += int(round(float(_build_definition(String(s.kind)).get("cost", 0)) * 0.35))
	structures.remove_at(selected_entity)
	selected_entity = -1
	_close_inspector()
	_save_all()


func _try_dash() -> void:
	if dash_cooldown > 0.0 or screen != "play": return
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): direction.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): direction.x += 1.0
	if direction.length() < 0.1: direction = player_facing
	dash_direction = direction.normalized()
	dash_timer = 0.2
	dash_cooldown = 1.25



func _move_player(motion: Vector2) -> void:
	var candidate_x := player_pos + Vector2(motion.x, 0)
	if _blocking_structure(candidate_x, PLAYER_RADIUS, true) < 0: player_pos.x = candidate_x.x
	var candidate_y := player_pos + Vector2(0, motion.y)
	if _blocking_structure(candidate_y, PLAYER_RADIUS, true) < 0: player_pos.y = candidate_y.y


func _structure_overlap_depth(point: Vector2, center: Vector2, width: int, radius: float) -> float:
	var difference := (point - center).abs()
	return minf(CELL * 0.5 * width + radius - difference.x, CELL * 0.5 + radius - difference.y)


func _blocking_structure(point: Vector2, radius: float, allow_player_escape := false) -> int:
	for i in range(structures.size()):
		var s: Dictionary = structures[i]
		if float(s.get("hp", 0.0)) <= 0.0: continue
		var kind := String(s.get("kind", ""))
		var width := 2 if kind == "hq" or _is_building(kind) else 1
		var center := _entry_world_center(s)
		var depth := _structure_overlap_depth(point, center, width, radius)
		if depth < 0.0: continue
		if allow_player_escape and depth < _structure_overlap_depth(player_pos, center, width, radius):
			continue
		return i
	return -1


func _update_player(delta: float) -> void:
	var previous_position := player_pos
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): direction.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): direction.x += 1.0
	if direction.length() > 0.0:
		direction = direction.normalized()
		player_facing = direction
	var speed := float(Data.CHARACTERS[player_index].speed) * player_mod_speed
	if dash_timer > 0.0:
		dash_timer = maxf(0.0, dash_timer - delta)
		_move_player(dash_direction * speed * 2.8 * delta)
	else:
		_move_player(direction * speed * delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	player_pos.x = clampf(player_pos.x, -MAP_LIMIT.x, MAP_LIMIT.x)
	player_pos.y = clampf(player_pos.y, -MAP_LIMIT.y, MAP_LIMIT.y)
	player_motion = (player_pos - previous_position) / maxf(delta, 0.001)
	_update_player_attack(delta)
	if player_drone_level > 0:
		drone_timer -= delta
		if drone_timer <= 0.0:
			drone_timer = maxf(0.9, 3.2 - player_drone_level * 0.45)
			var drone_target := _nearest_enemy(player_pos, 460.0)
			if drone_target >= 0:
				var target_pos: Vector2 = enemies[drone_target].pos
				_damage_enemy(drone_target, 24.0 * player_drone_level * player_mod_damage, "drone")
				effects.append({"a": player_pos + Vector2(20, -30), "b": target_pos, "time": 0.15, "color": PALETTE.blue})
	

func _update_player_attack(delta: float) -> void:
	var hero: Dictionary = Data.CHARACTERS[player_index]
	var wants_attack := false
	if manual_attack:
		var aim := aim_screen - size * 0.5
		if not aim.is_zero_approx():
			player_facing = aim.normalized()
		wants_attack = screen == "play" and manual_trigger and not build_mode
	else:
		var target := _nearest_enemy(player_pos, float(hero.range) * player_mod_range)
		if target >= 0:
			var aim: Vector2 = enemies[target].pos - player_pos
			if not aim.is_zero_approx():
				player_facing = aim.normalized()
			wants_attack = true

	player_attack_timer = maxf(0.0, player_attack_timer - delta)
	if player_reload_timer > 0.0:
		player_reload_timer = maxf(0.0, player_reload_timer - delta)
		if player_reload_timer == 0.0:
			player_magazine = int(hero.magazine)
	if wants_attack and player_attack_timer <= 0.0 and player_reload_timer <= 0.0:
		_attack_player()


func _attack_player() -> void:
	var hero: Dictionary = Data.CHARACTERS[player_index]
	var kind := String(hero.id)
	var reload := float(hero.rate) / player_mod_rate
	if kind == "yujin":
		player_attack_timer = maxf(0.08, reload)
		var direction := player_facing.normalized()
		for i in range(enemies.size() - 1, -1, -1):
			var target_pos: Vector2 = enemies[i].pos
			var toward := target_pos - player_pos
			if toward.length() <= float(hero.range) * player_mod_range and (toward.is_zero_approx() or direction.dot(toward.normalized()) > 0.70):
				_damage_enemy(i, float(hero.damage) * player_mod_damage * 0.45, "chainsaw")
				if effects.size() < 40: effects.append({"a": player_pos + direction * 26, "b": target_pos, "time": 0.09, "color": Color("#f1a34f")})
		return
	if player_magazine <= 0:
		return
	player_magazine -= 1
	if player_magazine == 0:
		player_reload_timer = float(hero.reload)
	if kind == "harin":
		_harin_visual.trigger_attack()
	if sound_on:
		AudioDirector.play_cue("player.action", 0.78 if kind == "tae" else 1.12 if kind == "si" else 1.0)
	player_attack_timer = maxf(0.05, reload)
	var direction := player_facing.normalized()
	var max_range := float(hero.range) * player_mod_range
	var pellets := int(hero.pellets) + player_extra_pellets if kind == "tae" else 1
	var damage := float(hero.damage) * player_mod_damage / float(pellets)
	var color: Color = PALETTE.gold if kind == "tae" else PALETTE.blue
	for pellet in range(pellets):
		var spread := (float(pellet) - float(pellets - 1) * 0.5) * (0.105 if kind == "tae" else 0.0)
		player_projectiles.fire(player_pos, direction.rotated(spread), max_range, damage, maxi(1, player_pierce + 1), color)


func _update_spawn(delta: float) -> void:
	stage_elapsed += delta
	spawn_timer -= delta
	if stage_elapsed >= WAVE_SECONDS and stage < 100:
		stage += 1
		stage_elapsed -= WAVE_SECONDS
		_show_toast("경계 단계 %d / 100" % stage)
		if stage == 40 and not boss_40_spawned:
			boss_40_spawned = true
			_spawn_boss(40)
		elif stage == 80 and not boss_80_spawned:
			boss_80_spawned = true
			_spawn_boss(80)
		elif stage == 100 and not boss_100_spawned:
			boss_100_spawned = true
			pending_final_boss = true
			_spawn_boss(100)
	if stage == 100 and pending_final_boss and _count_live_bosses() == 0 and boss_100_spawned:
		return
	if spawn_timer <= 0.0 and enemies.size() < MAX_ENEMIES:
		var base_interval := 1.25 / float(difficulty.get("spawn", 1.0))
		spawn_timer = maxf(0.18, base_interval * (1.0 - minf(0.55, float(stage) * 0.004)))
		var count := 1 + (1 if stage >= 16 and _random.randf() < 0.25 else 0)
		for n in range(count):
			if enemies.size() >= MAX_ENEMIES: break
			var kind := _choose_enemy_kind()
			var angle := _random.randf_range(0.0, TAU)
			var distance := _random.randf_range(470.0, 740.0)
			var pos := player_pos + Vector2(cos(angle), sin(angle)) * distance
			pos.x = clampf(pos.x, -MAP_LIMIT.x + 90, MAP_LIMIT.x - 90)
			pos.y = clampf(pos.y, -MAP_LIMIT.y + 90, MAP_LIMIT.y - 90)
			enemies.append(_make_enemy(kind, pos, false))


func _choose_enemy_kind() -> String:
	var choices: Array[String] = ["normal"]
	if stage >= 10: choices.append("runner")
	if stage >= 20: choices.append("bomber")
	if stage >= 25: choices.append("spitter")
	if stage >= 35: choices.append("brute")
	var weights: Array[float] = []
	for id in choices:
		weights.append(0.46 if id == "normal" else 0.16 if id == "runner" else 0.12 if id == "bomber" else 0.14 if id == "spitter" else 0.12)
	var total_weight: float = 0.0
	for weight in weights: total_weight += weight
	var roll: float = _random.randf() * total_weight
	for i in range(choices.size()):
		roll -= weights[i]
		if roll <= 0.0: return choices[i]
	return choices.back()


func _make_enemy(kind: String, pos: Vector2, is_boss: bool) -> Dictionary:
	var data: Dictionary = Data.BOSSES[100] if is_boss and stage >= 100 else Data.BOSSES[80] if is_boss and stage >= 80 else Data.BOSSES[40] if is_boss else Data.ENEMIES.get(kind, Data.ENEMIES.normal)
	var hp := float(data.hp) * float(difficulty.get("hp", 1.0))
	if is_boss: hp *= 1.0 + float(maxi(stage - 40, 0)) * 0.012
	var enemy: Dictionary = enemy_pool.pop_back() if not enemy_pool.is_empty() else {}
	enemy.clear()
	enemy.merge({"kind": kind, "name": String(data.name), "pos": pos, "hp": hp, "max_hp": hp, "speed": float(data.speed) * (1.0 + float(stage) * 0.0012), "attack": float(data.attack) * float(difficulty.get("attack", 1.0)), "color": data.color, "ranged": bool(data.get("ranged", is_boss)), "boss": is_boss, "cool": 1.0, "charge": 0.0, "target": "player", "slow": 0.0, "pattern_timer": 3.0, "reward": 8 if is_boss else 2 if kind == "normal" or kind == "runner" else 4}, true)
	enemy_spawn_id += 1
	enemy.spawn_id = enemy_spawn_id
	if kind == "normal" and not is_boss:
		enemy.variant = _random.randi_range(0, ZombieVisual.SHEETS.size() - 1)
		enemy.row = 0
		enemy.moving = false
		enemy.hit_until = 0.0
		enemy.attack_until = 0.0
	return enemy


func _spawn_boss(at_stage: int) -> void:
	var old_stage := stage
	stage = at_stage
	var angle := _random.randf_range(0, TAU)
	var spawn_at := player_pos + Vector2(cos(angle), sin(angle)) * 650.0
	var kind := "boss40" if at_stage == 40 else "boss80" if at_stage == 80 else "boss100"
	enemies.append(_make_enemy(kind, spawn_at, true))
	stage = old_stage
	_show_toast("보스 출현 · %s" % String(Data.BOSSES[at_stage].name))


func _count_live_bosses() -> int:
	var count := 0
	for e in enemies:
		if bool(e.get("boss", false)): count += 1
	return count


func _update_enemies(delta: float) -> void:
	var hq_pos := _hq_position()
	for i in range(enemies.size() - 1, -1, -1):
		var e: Dictionary = enemies[i]
		var previous_pos: Vector2 = e.pos
		var animated := e.has("variant")
		var body_radius := ZombieVisual.RADIUS if animated else 11.0
		e.cool = maxf(0.0, float(e.cool) - delta)
		e.slow = maxf(0.0, float(e.slow) - delta)
		if bool(e.boss): _update_boss_pattern(e, delta)
		if String(e.kind) == "bomber":
			var d_player: float = e.pos.distance_to(player_pos)
			var d_hq: float = e.pos.distance_to(hq_pos)
			if float(e.charge) > 0.0:
				e.charge -= delta
				if e.charge <= 0.0:
					_explode_bomber(e)
					_remove_enemy(i)
					continue
			elif minf(d_player, d_hq) < 48.0:
				e.charge = 0.72
				e.target = "player" if d_player < d_hq else "hq"
			continue
		var d_to_player: float = e.pos.distance_to(player_pos)
		var d_to_hq: float = e.pos.distance_to(hq_pos)
		var target_player: bool = d_to_player < d_to_hq and d_to_player < 440.0
		e.target = "player" if target_player else "hq"
		var target_pos: Vector2 = player_pos if target_player else hq_pos
		var dist: float = e.pos.distance_to(target_pos)
		if animated and dist > 0.01:
			e.row = ZombieVisual.facing_row(target_pos - e.pos)
		if bool(e.ranged) and dist < 390.0:
			if float(e.charge) > 0.0:
				e.charge -= delta
				if e.charge <= 0.0:
					_launch_enemy_shot(e, e.get("warn_pos", target_pos))
					e.cool = 2.0 if not bool(e.boss) else 1.35
			elif float(e.cool) <= 0.0:
				e.charge = 0.72 if String(e.kind) == "spitter" else 0.92
				e.warn_pos = target_pos
				e.cool = 2.6
		else:
			if dist > 30.0:
				var move_speed := float(e.speed) * (0.48 if float(e.slow) > 0.0 else 1.0)
				var move_dir: Vector2 = (target_pos - e.pos).normalized()
				var proposed: Vector2 = e.pos + move_dir * move_speed * delta
				var blocker := _blocking_structure(proposed, body_radius if not bool(e.boss) else 24.0)
				if blocker < 0:
					e.pos = proposed
				elif String(structures[blocker].kind) != "hq" and float(e.cool) <= 0.0:
					_damage_structure(blocker, float(e.attack))
					if animated: _animate_zombie_attack(e, _entry_world_center(structures[blocker]) - previous_pos)
					e.cool = 1.15
				else:
					var flank_a: Vector2 = e.pos + move_dir.rotated(0.92) * move_speed * delta
					var flank_b: Vector2 = e.pos + move_dir.rotated(-0.92) * move_speed * delta
					if _blocking_structure(flank_a, body_radius) < 0: e.pos = flank_a
					elif _blocking_structure(flank_b, body_radius) < 0: e.pos = flank_b
			elif float(e.cool) <= 0.0:
				if target_player:
					_player_take_damage(float(e.attack), "적의 근접 공격")
				else:
					_damage_hq(float(e.attack))
				if animated: _animate_zombie_attack(e, target_pos - previous_pos)
				e.cool = 1.0 if not bool(e.boss) else 0.65
		if e.pos.distance_to(player_pos) < 22.0 and float(e.charge) <= 0.0 and not bool(e.ranged):
			e.pos += (e.pos - player_pos).normalized() * 6.0
		if animated:
			e.moving = not previous_pos.is_equal_approx(e.pos)


func _animate_zombie_attack(enemy: Dictionary, toward: Vector2) -> void:
	ZombieVisual.start_attack(enemy, toward, run_seconds)
	if sound_on and run_seconds >= zombie_sound_at and player_pos.distance_squared_to(enemy.pos) < 400.0 * 400.0:
		zombie_sound_at = run_seconds + 0.24
		AudioDirector.play_cue("enemy.attack", 0.88 + float(int(enemy.spawn_id) % 7) * 0.035)


func _update_boss_pattern(e: Dictionary, delta: float) -> void:
	e.pattern_timer -= delta
	if e.pattern_timer > 0.0: return
	var current_stage := 40 if String(e.kind) == "boss40" else 80 if String(e.kind) == "boss80" else 100
	e.pattern_timer = 4.0 if current_stage == 40 else 5.0
	if current_stage == 40:
		e.guard = 1.0
		_show_toast("철갑 방어 태세 · 잠시 피해를 줄입니다.")
	elif current_stage == 80:
		var target := _nearest_structure(e.pos, 560.0, false)
		if target >= 0:
			_damage_structure(target, float(e.attack) * 2.0)
			_show_toast("파쇄자 · 구조물에 강한 충격")
	elif current_stage == 100:
		for n in range(3):
			var a := _random.randf_range(0, TAU)
			enemies.append(_make_enemy("normal", e.pos + Vector2(cos(a), sin(a)) * 90.0, false))
		_show_toast("군체 지배자 · 추가 개체 소환")


func _launch_enemy_shot(enemy: Dictionary, target: Vector2) -> void:
	var ptype := "acid" if String(enemy.kind) == "spitter" else "rock"
	var direction: Vector2 = (target - enemy.pos).normalized()
	enemy_shots.append({"pos": enemy.pos, "velocity": direction * (270.0 if ptype == "rock" else 235.0), "life": 2.2, "damage": float(enemy.attack), "type": ptype, "target": target, "color": PALETTE.red})


func _explode_bomber(enemy: Dictionary) -> void:
	var target_player := String(enemy.get("target", "player")) == "player"
	var center: Vector2 = player_pos if target_player else _hq_position()
	var dist: float = enemy.pos.distance_to(center)
	if dist < 120.0:
		if target_player: _player_take_damage(float(enemy.attack) * 1.8, "자폭 폭발")
		else: _damage_hq(float(enemy.attack) * 2.4)
	for i in range(structures.size() - 1, -1, -1):
		if _entry_world_center(structures[i]).distance_to(enemy.pos) <= 105.0:
			_damage_structure(i, float(enemy.attack) * 0.8)
	effects.append({"a": enemy.pos, "b": enemy.pos + Vector2(95, 0), "time": 0.28, "color": PALETTE.red, "blast": true})
	_show_toast("자폭체 폭발 · 경고 원에서 벗어나세요.")


func _damage_enemy(index: int, amount: float, source: String) -> void:
	if index < 0 or index >= enemies.size(): return
	var enemy: Dictionary = enemies[index]
	if bool(enemy.get("boss", false)) and float(enemy.get("guard", 0.0)) > 0.0:
		amount *= 0.4
		enemy.guard = maxf(0.0, float(enemy.guard) - 0.28)
	enemy.hp = float(enemy.hp) - amount
	if amount > 0.0 and sound_on and run_seconds >= impact_sound_at and player_pos.distance_squared_to(enemy.pos) < 440.0 * 440.0:
		impact_sound_at = run_seconds + 0.10
		AudioDirector.play_cue("enemy.impact", 1.18)
	if float(enemy.hp) <= 0.0:
		var reward := int(round(float(enemy.reward) * player_mod_salvage))
		money += reward
		kills += 1
		player_xp += (16.0 if bool(enemy.boss) else 4.0 if enemy.kind != "normal" else 2.6) * player_mod_xp * (1.0 + float(research_bonus) * 0.05)
		if bool(enemy.boss):
			boss_kills += 1
			medals += 12
			if String(enemy.kind) == "boss100":
				pending_final_boss = false
				_finish_run(true)
				return
		elif String(enemy.kind) != "normal":
			medals += 1
		_remove_enemy(index)
		_check_level_up()
	elif enemy.has("variant"):
		enemy.hit_until = run_seconds + ZombieVisual.HIT_TIME


func _remove_enemy(index: int) -> void:
	if index < 0 or index >= enemies.size(): return
	var dead: Dictionary = enemies[index]
	enemies.remove_at(index)
	if dead.has("variant") and _zombie_on_screen(_world_to_screen(dead.pos)) and zombie_corpses.size() < MAX_ENEMIES:
		zombie_corpses.append({"pos": dead.pos, "variant": dead.variant, "row": dead.row, "start": run_seconds})
	if enemy_pool.size() < MAX_ENEMIES: enemy_pool.append(dead)


func _update_zombie_corpses(now: float) -> void:
	# Corpses are inserted chronologically and carry no gameplay state.
	while not zombie_corpses.is_empty() and now - float(zombie_corpses.front().start) >= ZombieVisual.DEATH_TIME:
		zombie_corpses.pop_front()


func _zombie_on_screen(point: Vector2) -> bool:
	var visible_size := size / _view_zoom()
	return Rect2((size - visible_size) * 0.5, visible_size).grow(48.0).has_point(point)


func _explode_damage_center(center: Vector2, radius: float, damage: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i].pos.distance_to(center) <= radius:
			_damage_enemy(i, damage, "blast")


func _update_turrets(delta: float) -> void:
	for index in range(structures.size()):
		var s: Dictionary = structures[index]
		if float(s.hp) <= 0.0: continue
		var kind := String(s.kind)
		if not _is_turret(kind) and kind != "outpost" and kind != "hq": continue
		s.cool = maxf(0.0, float(s.get("cool", 0.0)) - delta)
		var pos := _entry_world_center(s)
		if kind == "repair":
			if float(s.cool) <= 0.0:
				var repair_target := _nearest_structure(pos, 310.0, true)
				if repair_target >= 0:
					structures[repair_target].hp = minf(float(structures[repair_target].max_hp), float(structures[repair_target].hp) + 24.0 * float(s.level))
					s.cool = 1.0
					effects.append({"a": pos, "b": _entry_world_center(structures[repair_target]), "time": 0.22, "color": PALETTE.green})
			continue
		if kind == "hq": continue
		var def := _build_definition(kind)
		var turret_range := float(def.get("range", 330.0)) * player_mod_range
		if kind == "outpost": turret_range = 390.0
		if float(s.cool) > 0.0: continue
		var target_index := _nearest_enemy(pos, turret_range)
		if target_index < 0: continue
		var target_pos: Vector2 = enemies[target_index].pos
		var fire_rate := float(def.get("rate", 1.0)) / player_mod_turret_rate
		s.cool = maxf(0.12, fire_rate / (1.0 + float(s.level - 1) * 0.12))
		var damage := float(def.get("damage", 20.0)) * (1.0 + float(s.level - 1) * 0.34) * player_mod_turret_damage
		if kind == "outpost": damage = 18.0 * player_mod_turret_damage
		if kind == "rocket":
			_explode_damage_center(target_pos, 82.0, damage * 0.72)
			effects.append({"a": pos, "b": target_pos, "time": 0.22, "color": PALETTE.red, "blast": true})
		elif kind == "electric":
			_damage_enemy(target_index, damage, "turret")
			var skip_index := target_index if target_index < enemies.size() and enemies[target_index].pos.distance_to(target_pos) < 0.5 else -1
			var secondary := _nearest_enemy(target_pos, 94.0, skip_index)
			if secondary >= 0: _damage_enemy(secondary, damage * 0.55, "chain")
			if effects.size() < 80: effects.append({"a": pos, "b": target_pos, "time": 0.16, "color": PALETTE.blue})
		else:
			_damage_enemy(target_index, damage, "turret")
			if kind == "freeze" and target_index < enemies.size() and enemies[target_index].pos.distance_to(target_pos) < 0.5:
				enemies[target_index].slow = 2.2
			if effects.size() < 80: effects.append({"a": pos, "b": target_pos, "time": 0.11, "color": def.get("color", PALETTE.gold)})


func _nearest_enemy(pos: Vector2, range: float, skip := -1) -> int:
	var nearest := -1
	var nearest_dist := range
	for i in range(enemies.size()):
		if i == skip or enemies[i].hp <= 0.0: continue
		var dist: float = pos.distance_to(enemies[i].pos)
		if dist <= range and (nearest < 0 or dist < nearest_dist):
			nearest_dist = dist
			nearest = i
	return nearest


func _nearest_structure(pos: Vector2, range: float, damaged_only: bool) -> int:
	var nearest := -1
	var nearest_dist := range
	for i in range(structures.size()):
		var s: Dictionary = structures[i]
		if float(s.hp) <= 0.0 or (damaged_only and float(s.hp) >= float(s.max_hp)): continue
		var dist := pos.distance_to(_entry_world_center(s))
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = i
	return nearest


func _update_projectiles(delta: float) -> void:
	for i in range(enemy_shots.size() - 1, -1, -1):
		var shot: Dictionary = enemy_shots[i]
		shot.pos += shot.velocity * delta
		shot.life -= delta
		var target_player: bool = shot.pos.distance_to(player_pos) < 24.0
		var target_hq: bool = shot.pos.distance_to(_hq_position()) < 28.0
		if target_player or target_hq or float(shot.life) <= 0.0:
			if target_player and dash_timer <= 0.0: _player_take_damage(float(shot.damage), "원거리 투사체")
			elif target_hq: _damage_hq(float(shot.damage))
			effects.append({"a": shot.pos, "b": shot.pos + Vector2(26, 0), "time": 0.14, "color": PALETTE.red})
			enemy_shots.remove_at(i)


func _update_effects(delta: float) -> void:
	for i in range(effects.size() - 1, -1, -1):
		effects[i].time = float(effects[i].time) - delta
		if float(effects[i].time) <= 0.0: effects.remove_at(i)


func _update_facilities(delta: float) -> void:
	for s in structures:
		if float(s.hp) <= 0.0: continue
		var kind := String(s.kind)
		if kind == "clinic" and player_pos.distance_to(_entry_world_center(s)) <= 245.0:
			player_hp = minf(player_max_hp, player_hp + delta * 2.8)
		elif kind == "supply":
			income_timer += delta
			if income_timer >= 24.0:
				income_timer = 0.0
				money += 18
		elif kind == "research": research_bonus = 1
		elif kind == "workshop": player_mod_turret_damage = maxf(player_mod_turret_damage, 1.12)


func _update_progress(delta: float) -> void:
	if player_hp <= 0.0:
		_finish_run(false)
		return
	var hq := _hq_index()
	if hq < 0 or float(structures[hq].hp) <= 0.0:
		_finish_run(false)
		return
	if player_xp >= float(player_level) * 42.0 and augments_taken < 15 and screen == "play":
		player_xp -= float(player_level) * 42.0
		player_level += 1
		augments_taken += 1
		augment_reroll_used = false
		_offer_augments()


func _check_level_up() -> void:
	if player_xp >= float(player_level) * 42.0 and augments_taken < 15 and screen == "play":
		player_xp -= float(player_level) * 42.0
		player_level += 1
		augments_taken += 1
		augment_reroll_used = false
		_offer_augments()


func _offer_augments() -> void:
	var available := Data.augment_catalog()
	var hero_id := String(Data.CHARACTERS[player_index].id)
	for i in range(available.size() - 1, -1, -1):
		var id := String(available[i].id)
		var belongs_to_hero := false
		for hero in ["tae", "si", "harin", "yujin"]:
			if id.begins_with(hero + "_"): belongs_to_hero = true
		if picked_augment_ids.has(id) or (belongs_to_hero and not id.begins_with(hero_id + "_")):
			available.remove_at(i)
	while available.size() < 3:
		available.append({"id": "field_%02d" % available.size(), "name": "현장 적응", "effect": "damage", "description": "공격 피해가 증가합니다."})
	augment_options.clear()
	for i in range(3):
		var pick_index := _random.randi_range(0, available.size() - 1)
		var card: Dictionary = available.pop_at(pick_index)
		card["rarity"] = _pick_rarity()
		card["stars"] = _random.randi_range(1, 5)
		augment_options.append(card)
	_show_screen("augment")


func _pick_rarity() -> String:
	var roll := _random.randf() * 100.0
	if roll < 45: return "일반"
	if roll < 75: return "고급"
	if roll < 90: return "희귀"
	if roll < 98: return "영웅"
	return "전설"


func _rebuild_augment_cards() -> void:
	if augment_screen == null: return
	var row := augment_screen.find_child("AugmentCards", true, false) as HBoxContainer
	if row == null: return
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	for card in augment_options:
		var rarity_color := PALETTE.muted if card.rarity == "일반" else PALETTE.green if card.rarity == "고급" else PALETTE.blue if card.rarity == "희귀" else Color("#bd8de0") if card.rarity == "영웅" else PALETTE.gold
		var b := _make_button("%s  ·  %s\n%s\n%s" % [String(card.rarity), "★".repeat(int(card.stars)), String(card.name), String(card.description)], _choose_augment.bind(card), rarity_color, 126)
		b.add_theme_font_size_override("font_size", 12)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size.y = 80
		for state in ["normal", "hover", "pressed", "focus"]:
			var style := b.get_theme_stylebox(state) as StyleBoxFlat
			style.content_margin_left = 6.0
			style.content_margin_right = 6.0
			style.content_margin_top = 5.0
			style.content_margin_bottom = 5.0
			if state != "focus":
				style.bg_color = Color(PALETTE.panel.lerp(rarity_color, 0.11 if state == "normal" else 0.22), 0.96)
		row.add_child(b)
	augment_reroll_button.disabled = augment_reroll_used
	augment_reroll_button.text = "무료 리롤 사용됨" if augment_reroll_used else "무료 리롤 1회"


func _reroll_augments() -> void:
	if augment_reroll_used: return
	augment_reroll_used = true
	augment_options.clear()
	# One reroll keeps every offer distinct and keeps the specified rarity odds.
	var available := Data.augment_catalog()
	var hero_id := String(Data.CHARACTERS[player_index].id)
	for i in range(available.size() - 1, -1, -1):
		var id := String(available[i].id)
		var belongs_to_hero := id.begins_with("tae_") or id.begins_with("si_") or id.begins_with("harin_") or id.begins_with("yujin_")
		if picked_augment_ids.has(id) or (belongs_to_hero and not id.begins_with(hero_id + "_")): available.remove_at(i)
	for i in range(3):
		var card: Dictionary = available.pop_at(_random.randi_range(0, available.size() - 1))
		card["rarity"] = _pick_rarity()
		card["stars"] = _random.randi_range(1, 5)
		augment_options.append(card)
	_rebuild_augment_cards()


func _choose_augment(card: Dictionary) -> void:
	picked_augment_ids.append(String(card.id))
	var mult := 1.0 + 0.025 * float(card.stars)
	match String(card.effect):
		"damage": player_mod_damage *= 1.0 + 0.07 * mult
		"rate", "reload": player_mod_rate *= 1.0 + 0.06 * mult
		"range": player_mod_range *= 1.0 + 0.06 * mult
		"health":
			player_max_hp += 14.0 * mult
			player_hp = minf(player_max_hp, player_hp + 35.0)
		"armor": player_mod_armor *= 0.94
		"speed": player_mod_speed *= 1.0 + 0.045 * mult
		"xp": player_mod_xp *= 1.0 + 0.08 * mult
		"building_hp": player_mod_building_hp *= 1.0 + 0.08 * mult
		"salvage": player_mod_salvage *= 1.0 + 0.10 * mult
		"turret_damage": player_mod_turret_damage *= 1.0 + 0.08 * mult
		"turret_rate": player_mod_turret_rate *= 1.0 + 0.08 * mult
		"build": player_mod_build = maxf(0.45, player_mod_build - 0.05)
		"projectile": player_extra_pellets += 1
		"pierce": player_pierce += 1
		"drone": player_drone_level += 1
		_: player_mod_damage *= 1.06
	_show_screen("play")
	_show_toast("현장 증강 · %s" % String(card.name))


func _player_take_damage(amount: float, cause: String) -> void:
	if dash_timer > 0.0: return
	var reduction := 0.12 if Data.CHARACTERS[player_index].id == "tae" else 0.0
	player_hp -= amount * maxf(0.25, player_mod_armor - reduction)
	if sound_on and run_seconds >= impact_sound_at:
		impact_sound_at = run_seconds + 0.10
		AudioDirector.play_cue("enemy.impact", 0.80)
	_show_toast("%s · -%d" % [cause, int(amount)])


func _hq_index() -> int:
	for i in range(structures.size()):
		if String(structures[i].kind) == "hq": return i
	return -1


func _hq_position() -> Vector2:
	var i := _hq_index()
	return _entry_world_center(structures[i]) if i >= 0 else Vector2.ZERO


func _damage_hq(amount: float) -> void:
	var i := _hq_index()
	if i < 0: return
	structures[i].hp = maxf(0.0, float(structures[i].hp) - amount)
	if float(structures[i].hp) <= 0.0:
		_show_toast("지휘본부가 파괴되었습니다!")


func _damage_structure(index: int, amount: float) -> void:
	if index < 0 or index >= structures.size(): return
	structures[index].hp = maxf(0.0, float(structures[index].hp) - amount)
	if float(structures[index].hp) <= 0.0:
		_show_toast("%s 파괴 · 슬롯 반환" % String(_build_definition(String(structures[index].kind)).get("name", structures[index].kind)))
		if String(structures[index].kind) == "hq": _finish_run(false)


func _finish_run(won: bool) -> void:
	if screen == "result": return
	win_state = won
	if won:
		medals += 100
	else:
		medals += maxi(1, stage / 12)
	result_title_label.text = "제주 방어 성공" if won else "작전 종료 · 철수"
	result_stats_label.text = "대원: %s\n난이도: %s\n도달 단계: %d / 100\n처치: %d  ·  보스 격파: %d\n전투 시간: %02d:%02d\n작전 훈장 보유: %d" % [String(Data.CHARACTERS[player_index].name), String(difficulty.get("label", "보통")), stage, kills, boss_kills, int(run_seconds / 60), int(run_seconds) % 60, medals]
	_show_screen("result")
	saved_run.clear()
	_save_all()


func _show_toast(message: String) -> void:
	toast = message
	toast_timer = 2.8
	if build_status_label != null and build_open: build_status_label.text = message


func _refresh_hud() -> void:
	if hp_bar == null or game_ui == null: return
	if screen == "play" or screen == "pause" or screen == "augment":
		hp_bar.max_value = player_max_hp
		hp_bar.value = player_hp
		var hq := _hq_index()
		if hq >= 0:
			base_bar.max_value = float(structures[hq].max_hp)
			base_bar.value = float(structures[hq].hp)
		var remaining := maxi(0, int(WAVE_SECONDS - stage_elapsed))
		stage_label.text = "단계 %d / 100  ·  %s  ·  다음 단계 %02d초" % [stage, String(difficulty.get("label", "")), remaining]
		currency_label.text = "보급품 %d  ·  처치 %d  ·  훈장 %d  ·  Lv.%d" % [money, kills, medals, player_level]
		var boss_text := ""
		for e in enemies:
			if bool(e.get("boss", false)):
				boss_text = "BOSS  %s  ·  %d / %d" % [String(e.name), int(e.hp), int(e.max_hp)]
				break
		boss_label.text = boss_text
		var toast_node := run_hud.find_child("Toast", true, false) as Label
		if toast_node: toast_node.text = toast if toast_timer > 0.0 else ""
		var capacity := int(Data.CHARACTERS[player_index].magazine)
		var ammo := "전기톱 · 탄약 미사용" if capacity == 0 else "탄약 %d / %d" % [player_magazine, capacity]
		if player_reload_timer > 0.0:
			ammo += " · 재장전 중"
		combat_label.text = "%s [Tab]  ·  %s" % ["수동" if manual_attack else "자동", ammo]
		status_label.text = "건설 중에도 적과 시간은 계속 움직입니다." if build_open else ("좌클릭 유지: 사격" if manual_attack else "")


func _save_all() -> void:
	var output: Dictionary = {"schema": 1, "medals": medals, "upgrades": permanent_upgrades, "dash_key": dash_key, "pause_key": pause_key, "sound_on": sound_on, "shake_on": shake_on, "saved_run": saved_run}
	if screen == "play" or screen == "pause" or screen == "augment":
		var structure_rows: Array[Dictionary] = []
		for s in structures:
			var cell: Vector2i = s.get("cell", Vector2i.ZERO)
			structure_rows.append({"kind": String(s.kind), "x": cell.x, "y": cell.y, "hp": float(s.hp), "max_hp": float(s.max_hp), "level": int(s.level)})
		var enemy_rows: Array[Dictionary] = []
		for e in enemies:
			enemy_rows.append({"kind": String(e.kind), "x": float(e.pos.x), "y": float(e.pos.y), "hp": float(e.hp), "cool": float(e.cool), "boss": bool(e.boss), "variant": int(e.get("variant", -1))})
		saved_run = {"hero": player_index, "difficulty": difficulty_index, "stage": stage, "stage_elapsed": stage_elapsed, "run_seconds": run_seconds, "money": money, "kills": kills, "level": player_level, "xp": player_xp, "boss_kills": boss_kills, "player_hp": player_hp, "player_max_hp": player_max_hp, "player_pos": [player_pos.x, player_pos.y], "structures": structure_rows, "enemies": enemy_rows, "mods": {"damage": player_mod_damage, "rate": player_mod_rate, "speed": player_mod_speed, "range": player_mod_range, "armor": player_mod_armor, "xp": player_mod_xp, "salvage": player_mod_salvage, "build": player_mod_build, "building_hp": player_mod_building_hp, "turret_damage": player_mod_turret_damage, "turret_rate": player_mod_turret_rate, "pellets": player_extra_pellets, "pierce": player_pierce, "drone": player_drone_level, "augments": augments_taken, "picked": picked_augment_ids}}
		var boss_flags: Array[int] = []
		if boss_40_spawned: boss_flags.append(40)
		if boss_80_spawned: boss_flags.append(80)
		if boss_100_spawned: boss_flags.append(100)
		saved_run["boss_flags"] = boss_flags
		saved_run["magazine"] = player_magazine
		saved_run["reload_remaining"] = player_reload_timer
		saved_run["manual_attack"] = manual_attack
		output["saved_run"] = saved_run
	output["bgm_volume"] = bgm_volume
	output["effects_volume"] = effects_volume
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(output))


func _load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH): return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null: return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary): return
	var data: Dictionary = parsed
	medals = maxi(0, int(data.get("medals", 0)))
	permanent_upgrades = data.get("upgrades", {})
	for perk in Data.PERMANENT_PERKS:
		permanent_upgrades[perk.id] = clampi(int(permanent_upgrades.get(perk.id, 0)), 0, 5)
	dash_key = int(data.get("dash_key", KEY_SHIFT))
	pause_key = int(data.get("pause_key", KEY_ESCAPE))
	if dash_key == KEY_TAB: dash_key = KEY_SHIFT
	if pause_key == KEY_TAB: pause_key = KEY_ESCAPE
	sound_on = bool(data.get("sound_on", true))
	bgm_volume = clampi(int(data.get("bgm_volume", 100)), 0, 100)
	effects_volume = clampi(int(data.get("effects_volume", 100)), 0, 100)
	shake_on = bool(data.get("shake_on", true))
	saved_run = data.get("saved_run", {})
	if not (saved_run is Dictionary): saved_run = {}


func _restore_run_modifiers() -> void:
	var mods: Dictionary = saved_run.get("mods", {})
	player_mod_damage = float(mods.get("damage", 1.0))
	player_mod_rate = float(mods.get("rate", 1.0))
	player_mod_speed = float(mods.get("speed", 1.0))
	player_mod_range = float(mods.get("range", 1.0))
	player_mod_armor = float(mods.get("armor", 1.0))
	player_mod_xp = float(mods.get("xp", 1.0))
	player_mod_salvage = float(mods.get("salvage", 1.0))
	player_mod_build = float(mods.get("build", 1.0))
	player_mod_building_hp = float(mods.get("building_hp", 1.0))
	player_mod_turret_damage = float(mods.get("turret_damage", 1.0))
	player_mod_turret_rate = float(mods.get("turret_rate", 1.0))
	player_extra_pellets = int(mods.get("pellets", 0))
	player_pierce = int(mods.get("pierce", 0))
	player_drone_level = int(mods.get("drone", 0))
	augments_taken = int(mods.get("augments", 0))
	picked_augment_ids.clear()
	for value in mods.get("picked", []): picked_augment_ids.append(String(value))
	var flags: Array = saved_run.get("boss_flags", [])
	boss_40_spawned = flags.has(40)
	boss_80_spawned = flags.has(80)
	boss_100_spawned = flags.has(100)
	pending_final_boss = stage >= 100 and boss_100_spawned


func _world_to_screen(point: Vector2) -> Vector2:
	return point - player_pos + size * 0.5


func _view_zoom() -> float:
	return 1.0 if screen == "landing" else camera_zoom


func _screen_to_world(point: Vector2) -> Vector2:
	return player_pos + (point - size * 0.5) / _view_zoom()


func _draw_menu_backdrop() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PALETTE.bg)
	var horizon := size.y * 0.57
	draw_rect(Rect2(0, horizon, size.x, size.y - horizon), Color("#1d2421"))
	# Distant low-rise outlines frame the title without reusing the approved mockup as an asset.
	for i in range(12):
		var width := 58.0 + float((i * 37) % 68)
		var height := 74.0 + float((i * 59) % 142)
		var x := float(i) * size.x / 11.0 - 24.0
		draw_rect(Rect2(x, horizon - height, width, height), Color("#242c28"))
		for row in range(2):
			for col in range(2):
				var window := Rect2(x + 10 + col * 22, horizon - height + 15 + row * 24, 8, 11)
				draw_rect(window, Color(0.79, 0.56, 0.32, 0.22))
	# Shoreline / road bands.
	draw_rect(Rect2(0, horizon + 30, size.x, 2), Color(PALETTE.gold, 0.28))
	draw_rect(Rect2(0, horizon + 76, size.x, 70), Color("#303733"))
	for x in range(0, int(size.x), 100):
		draw_rect(Rect2(float(x), horizon + 109, 44, 2), Color("#a8a286", 0.35))
	draw_circle(Vector2(size.x * 0.82, size.y * 0.19), 68.0, Color(PALETTE.gold, 0.07))
	draw_arc(Vector2(size.x * 0.82, size.y * 0.19), 92.0, 0, TAU, 72, Color(PALETTE.gold, 0.10), 1.0)


func _draw_world() -> void:
	var view := Rect2(Vector2.ZERO, size)
	draw_rect(view, Color("#1c2421"))
	var zoom := _view_zoom()
	var camera := Transform2D(0.0, Vector2.ONE * zoom, 0.0, size * 0.5 * (1.0 - zoom))
	draw_set_transform_matrix(camera)
	_draw_city_tiles()
	_draw_base_zone()
	if build_open:
		_draw_build_grid()
	for entry in structures:
		if float(entry.hp) > 0.0: _draw_structure(entry)
	for corpse in zombie_corpses:
		var center := _world_to_screen(corpse.pos)
		if _zombie_on_screen(center):
			ZombieVisual.draw_dead(self, corpse, center, run_seconds)
	for enemy in enemies: _draw_enemy(enemy, camera)
	for projectile in enemy_shots: _draw_enemy_projectile(projectile)
	for shot in player_projectiles.shots:
		var tip := _world_to_screen(shot.pos)
		draw_line(tip - shot.direction * 12.0, tip, shot.color, 2.0)
	for effect in effects: _draw_effect(effect)
	if screen != "landing" or landing.player_visible():
		_draw_player()
	if screen == "landing":
		landing.draw(self, _world_to_screen)
		landing.draw_overlay(self, size)
	if build_mode: _draw_placement_preview()
	draw_set_transform(Vector2.ZERO)
	if screen == "play" and manual_attack and not build_mode:
		_draw_cross(aim_screen, 7, Color(PALETTE.gold, 0.55))
	if screen == "pause" or screen == "augment" or screen == "result":
		draw_rect(view, Color(0.025, 0.035, 0.035, 0.16 if screen == "augment" else 0.42))


func _draw_city_tiles() -> void:
	JejuMapArt.draw(self, player_pos, size)


func _draw_base_zone() -> void:
	var center := _world_to_screen(Vector2.ZERO)
	draw_circle(center, 255, Color(0.08, 0.12, 0.10, 0.16))
	draw_arc(center, 170.0, 0.0, TAU, 64, Color(PALETTE.gold, 0.15), 1.2)
	# A subtle field-light square marks the construction zone even when its grid is hidden.
	draw_rect(Rect2(center - Vector2(CELL * 3.5, CELL * 3.5), Vector2(CELL * 7.0, CELL * 7.0)), Color(0.5, 0.6, 0.45, 0.025), false, 1.0)


func _draw_build_grid() -> void:
	for y in range(7):
		for x in range(7):
			var cell := Vector2i(x, y)
			var p := _world_to_screen(_cell_world(cell))
			var rect := Rect2(p - Vector2(CELL * 0.5, CELL * 0.5), Vector2(CELL, CELL))
			var accent := Color(PALETTE.gold, 0.27)
			if _cell_is_entrance(cell): accent = Color(PALETTE.green, 0.45)
			draw_rect(rect, Color(accent, 0.08), true)
			draw_rect(rect, accent, false, 1.0)
			if _cell_is_entrance(cell):
				draw_string(ThemeDB.fallback_font, p + Vector2(-9, 4), "↕" if cell.x == 3 else "↔", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(PALETTE.green, 0.9))


func _draw_placement_preview() -> void:
	if selected_build == "": return
	var world := _screen_to_world(get_local_mouse_position())
	var cell := _grid_cell(world)
	var valid := _validate_placement(selected_build, cell) == ""
	var width := 2 if _is_building(selected_build) else 1
	var color := PALETTE.green if valid else PALETTE.red
	for dx in range(width):
		var p := _world_to_screen(_cell_world(Vector2i(cell.x + dx, cell.y)))
		draw_rect(Rect2(p - Vector2(CELL * 0.5, CELL * 0.5), Vector2(CELL, CELL)), Color(color, 0.25), true)
		draw_rect(Rect2(p - Vector2(CELL * 0.5, CELL * 0.5), Vector2(CELL, CELL)), color, false, 2.0)


func _draw_structure(entry: Dictionary) -> void:
	var kind := String(entry.kind)
	var center := _world_to_screen(_entry_world_center(entry))
	var width := 2 if kind == "hq" or _is_building(kind) else 1
	var bounds := Rect2(center - Vector2(CELL * float(width) * 0.5, CELL * 0.5), Vector2(CELL * float(width), CELL))
	if kind == "hq" and hq_build_ratio < 1.0:
		LandingSequence.draw_tent_build(self, bounds, center, hq_build_ratio if landing.hq_ratio() >= 0.0 else -1.0)
		return
	if kind == "hq":
		# Only the initial military tent and HQ are drawn; no default allies or defenses.
		draw_rect(bounds.grow(-5), Color("#6b7058"))
		draw_colored_polygon(PackedVector2Array([Vector2(bounds.position.x - 2, bounds.position.y + 4), Vector2(center.x, bounds.position.y - 12), Vector2(bounds.end.x + 2, bounds.position.y + 4)]), Color("#8f7456"))
		draw_line(Vector2(center.x, bounds.position.y - 11), Vector2(center.x, bounds.position.y + 20), Color("#d0bd8e"), 2.0)
		draw_rect(Rect2(center.x - 7, bounds.position.y + 9, 14, 16), Color("#353a31"))
		draw_string(ThemeDB.fallback_font, center + Vector2(-34, 40), "지휘본부", HORIZONTAL_ALIGNMENT_LEFT, 90, 11, PALETTE.text)
	elif kind == "wall":
		draw_rect(bounds.grow(-7), Color("#9a8667"))
		for n in range(3): draw_circle(center + Vector2(-12 + n * 12, 0), 8, Color("#c0aa83"))
	elif _is_turret(kind):
		var def := _build_definition(kind)
		var c: Color = def.get("color", PALETTE.green)
		# Tripod base, turntable, and a deliberately long gun silhouette.
		draw_line(center + Vector2(-13, 13), center + Vector2(0, -2), Color("#4b554b"), 4.0)
		draw_line(center + Vector2(13, 13), center + Vector2(0, -2), Color("#4b554b"), 4.0)
		draw_line(center + Vector2(-12, 13), center + Vector2(12, 13), Color("#4b554b"), 3.0)
		draw_circle(center, 11, Color("#444e46"))
		draw_circle(center, 7, c)
		var target := _nearest_enemy(_entry_world_center(entry), 370.0)
		var direction := player_facing
		if target >= 0: direction = (enemies[target].pos - _entry_world_center(entry)).normalized()
		draw_line(center, center + direction * 25.0, Color("#343a35"), 5.0)
		draw_line(center, center + direction * 24.0, c.lightened(0.22), 2.0)
		for level in range(mini(5, int(entry.level))): draw_rect(Rect2(center.x - 12 + level * 5, center.y + 16, 3, 3), PALETTE.gold)
	elif _is_building(kind):
		var def := _build_definition(kind)
		var c: Color = Color("#657d69") if kind == "clinic" else Color("#7c704f") if kind == "supply" else Color("#62717a") if kind == "workshop" else Color("#75657b") if kind == "research" else Color("#788165")
		draw_rect(bounds.grow(-5), c)
		draw_rect(Rect2(bounds.position.x + 7, bounds.position.y + 8, bounds.size.x - 14, 5), Color(c.lightened(0.23)))
		draw_rect(Rect2(center.x - 6, center.y - 3, 13, 19), Color("#303832"))
		draw_string(ThemeDB.fallback_font, center + Vector2(-21, 23), String(def.get("short", "시설")), HORIZONTAL_ALIGNMENT_LEFT, 60, 10, PALETTE.text)
	if kind != "wall":
		var ratio := clampf(float(entry.hp) / maxf(1.0, float(entry.max_hp)), 0.0, 1.0)
		draw_rect(Rect2(center.x - 20.0 * float(width), bounds.position.y - 6, 40.0 * float(width), 3), Color(0, 0, 0, 0.7))
		draw_rect(Rect2(center.x - 20.0 * float(width), bounds.position.y - 6, 40.0 * float(width) * ratio, 3), PALETTE.green if ratio > 0.35 else PALETTE.red)
	if selected_entity >= 0 and selected_entity < structures.size() and structures[selected_entity] == entry:
		draw_rect(bounds.grow(3), PALETTE.blue, false, 2.0)


func _draw_enemy(enemy: Dictionary, camera: Transform2D) -> void:
	var p := _world_to_screen(enemy.pos)
	var boss := bool(enemy.get("boss", false))
	var radius := PlayerProjectiles.enemy_radius(enemy)
	if enemy.has("variant"):
		if not _zombie_on_screen(p): return
		ZombieVisual.draw_alive(self, enemy, p, run_seconds, camera)
		if float(enemy.hp) < float(enemy.max_hp):
			var ratio := clampf(float(enemy.hp) / float(enemy.max_hp), 0.0, 1.0)
			draw_rect(Rect2(p.x - 12, p.y - 33, 24, 3), Color(0, 0, 0, 0.65))
			draw_rect(Rect2(p.x - 12, p.y - 33, 24 * ratio, 3), PALETTE.green)
		return
	if String(enemy.kind) == "bomber" and float(enemy.get("charge", 0)) > 0.0:
		var pulse := 56.0 - 28.0 * maxf(0.0, float(enemy.charge)) / 0.72
		draw_arc(p, pulse, 0, TAU, 44, Color(PALETTE.red, 0.92), 3.0)
		_draw_cross(p, 8, PALETTE.red)
	var c: Color = enemy.get("color", PALETTE.red)
	draw_circle(p + Vector2(0, 5), radius + 2.0, Color(0, 0, 0, 0.28))
	draw_circle(p, radius, c)
	draw_circle(p + Vector2(0, -radius * 0.58), radius * 0.46, c.lightened(0.16))
	draw_circle(p + Vector2(-radius * 0.22, -2), 2.0 if not boss else 3.0, Color("#342928"))
	draw_circle(p + Vector2(radius * 0.22, -2), 2.0 if not boss else 3.0, Color("#342928"))
	if enemy.kind == "runner":
		draw_line(p + Vector2(-7, -2), p + Vector2(8, 4), Color("#f0d77d"), 2.0)
	elif enemy.kind == "spitter":
		draw_circle(p + Vector2(0, radius * 0.6), 5.0, Color("#9bc777"))
	elif enemy.kind == "brute":
		draw_rect(Rect2(p.x - radius, p.y - 8, 7, 18), c.darkened(0.12))
		draw_rect(Rect2(p.x + radius - 7, p.y - 8, 7, 18), c.darkened(0.12))
	if boss:
		draw_arc(p, radius + 6.0, 0.0, TAU, 42, Color(PALETTE.gold, 0.8), 2.0)
		var ratio := clampf(float(enemy.hp) / maxf(1.0, float(enemy.max_hp)), 0.0, 1.0)
		draw_rect(Rect2(p.x - 39, p.y - radius - 14, 78, 5), Color(0, 0, 0, 0.8))
		draw_rect(Rect2(p.x - 39, p.y - radius - 14, 78 * ratio, 5), PALETTE.red)
	elif float(enemy.hp) < float(enemy.max_hp):
		var ratio := clampf(float(enemy.hp) / float(enemy.max_hp), 0.0, 1.0)
		draw_rect(Rect2(p.x - 12, p.y - radius - 6, 24, 3), Color(0, 0, 0, 0.65))
		draw_rect(Rect2(p.x - 12, p.y - radius - 6, 24 * ratio, 3), PALETTE.green)
	if float(enemy.charge) > 0.0 and bool(enemy.ranged):
		var warn: Vector2 = enemy.get("warn_pos", player_pos)
		draw_arc(_world_to_screen(warn), 22.0, 0, TAU, 30, Color(PALETTE.red, 0.8), 2.0)
		draw_circle(_world_to_screen(warn), 4, Color(PALETTE.red, 0.55))


func _draw_enemy_projectile(shot: Dictionary) -> void:
	var p := _world_to_screen(shot.pos)
	var c: Color = shot.get("color", PALETTE.red)
	draw_circle(p, 7.0, c)
	draw_line(p, p - Vector2(10, 8), Color(c, 0.42), 3.0)


func _draw_effect(effect: Dictionary) -> void:
	var a := _world_to_screen(effect.a)
	var b := _world_to_screen(effect.b)
	var alpha := clampf(float(effect.time) / 0.25, 0.0, 1.0)
	var c: Color = effect.get("color", PALETTE.gold)
	if bool(effect.get("blast", false)):
		draw_arc(a, 24.0 + 110.0 * (1.0 - alpha), 0, TAU, 42, Color(c, alpha), 3.0)
	else:
		draw_line(a, b, Color(c, alpha), 2.0)


func _draw_player() -> void:
	var p := _world_to_screen(player_pos)
	var dir := player_facing.normalized()
	if Data.CHARACTERS[player_index].id == "harin":
		var reload_progress := -1.0
		if player_reload_timer > 0.0:
			reload_progress = 1.0 - player_reload_timer / float(Data.CHARACTERS[player_index].reload)
		_harin_visual.draw(self, p, dir, player_motion.length() > 6.0, dash_timer > 0.0, player_drone_level, reload_progress)
	else:
		var color: Color = Data.CHARACTERS[player_index].color
		if dash_timer > 0.0:
			draw_circle(p, 24.0, Color(PALETTE.blue, 0.23))
		draw_circle(p + Vector2(0, 8), 17, Color(0, 0, 0, 0.32))
		draw_circle(p, 15, color)
		draw_circle(p + Vector2(0, -8), 8, Color("#d7c3a8"))
		draw_arc(p + Vector2(0, -10), 9.0, PI, TAU, 16, Color("#465348"), 4.0)
		draw_line(p + dir * 8.0, p + dir * 28.0, Color("#303530"), 5.0)
		draw_line(p + dir * 11.0, p + dir * 28.0, Color(PALETTE.gold), 2.0)
		if Data.CHARACTERS[player_index].id == "tae":
			draw_arc(p - dir * 8.0, 18, -1.2, 1.2, 18, Color("#ccd4be"), 4.0)
		elif Data.CHARACTERS[player_index].id == "yujin":
			draw_arc(p, 51, dir.angle() - 0.8, dir.angle() + 0.8, 24, Color("#eea354", 0.26), 2.0)
	if screen == "play" and manual_attack and not build_mode:
		var color := Color(PALETTE.gold, 0.55)
		var aim_length := p.distance_to(_world_to_screen(_screen_to_world(aim_screen)))
		if aim_length > 24.0:
			draw_line(p + dir * 20.0, p + dir * minf(aim_length - 5.0, 92.0), color, 1.0)


func _draw_cross(center: Vector2, radius: float, color: Color) -> void:
	draw_line(center + Vector2(-radius, 0), center + Vector2(-3, 0), color, 1.5)
	draw_line(center + Vector2(3, 0), center + Vector2(radius, 0), color, 1.5)
	draw_line(center + Vector2(0, -radius), center + Vector2(0, -3), color, 1.5)
	draw_line(center + Vector2(0, 3), center + Vector2(0, radius), color, 1.5)
