extends Control

const PlayerProjectiles = preload("res://scripts/reclaim/player_projectiles.gd")
const Elements = preload("res://scripts/reclaim/element_visual.gd")
const FlowUI = preload("res://scripts/reclaim/flow/flow_ui.gd")
const OpsUI = preload("res://scripts/reclaim/operation_ui.gd")
const OperatorInfo = preload("res://scripts/reclaim/operator_info.gd")
const FieldWarning = preload("res://scripts/reclaim/field_warning.gd")
const BurrowVisual = preload("res://scripts/reclaim/burrow_visual.gd")
const ZombieVisual = preload("res://scripts/reclaim/zombie_visual.gd")
const Data = preload("res://scripts/reclaim/data.gd")
const YujinVisual = preload("res://scripts/reclaim/yujin_visual.gd")
const InfantryVisual = preload("res://scripts/reclaim/infantry_visual.gd")
const TACTICAL_DRONE = preload("res://assets/reclaim/characters/tactical_drone.png")
const TACTICAL_DRONE_SIDE = preload("res://assets/reclaim/characters/tactical_drone_side.png")
const Skills = preload("res://scripts/reclaim/operator_skills.gd")
const HarinVisual = preload("res://scripts/reclaim/character_visual.gd")
const REPAIR_DRONE_ART = preload("res://assets/reclaim/jeju/structures/repair_drone.png")
const FacilityEffects = preload("res://scripts/reclaim/flow/heli_art.gd")
const DAMAGE_MARK := 0.75
const DAMAGE_SMOKE := 0.45
const DAMAGE_FIRE := 0.25
const BASE_ART = preload("res://assets/reclaim/jeju/structures/base.png")
const TURRET_ART = preload("res://assets/reclaim/jeju/structures/turrets.png")
const STRUCTURE_FRAME := Vector2(112, 104)
const TURRET_ROWS := {"basic": 0, "heavy": 1, "rocket": 2, "electric": 3, "flame": 4, "freeze": 5, "aa": 6}
const FACILITY_COLUMNS := {"clinic": 0, "supply": 1, "workshop": 2, "research": 3, "outpost": 4}
const AugmentCatalog = preload("res://scripts/reclaim/augment_catalog.gd")
const SpecialEnemies = preload("res://scripts/reclaim/special_enemies.gd")
const FlatArena = preload("res://scripts/reclaim/flat_arena.gd")
const BootScreen = preload("res://scripts/reclaim/flow/boot_screen.gd")
const MainMenuScreen = preload("res://scripts/reclaim/flow/main_menu_screen.gd")
const CharacterSelectScreen = preload("res://scripts/reclaim/flow/character_select_screen.gd")
const DifficultyScreen = preload("res://scripts/reclaim/flow/difficulty_screen.gd")
const PrologueScreen = preload("res://scripts/reclaim/flow/prologue_screen.gd")
const LandingSequence = preload("res://scripts/reclaim/flow/landing_sequence.gd")
const FlowSfx = preload("res://scripts/reclaim/flow/flow_sfx.gd")
## Landing zone and first player position for the opening landing cut.
const LANDING_ZONE := Vector2(235.0, -10.0)
const PLAYER_START := Vector2(180.0, 112.0)
const SAVE_PATH := "user://reclaim_save.json"
const CELL := FlatArena.CELL
const PLAYER_RADIUS := 13.0
const PLAYER_DRAW_SCALE := 0.5
const ENEMY_SHOT_RADIUS := 7.0
const GRID_SIZE := 11
const GRID_MIN := -2
const GRID_MAX := GRID_MIN + GRID_SIZE - 1
const BUILD_ENTRANCES := [Vector2i(3, GRID_MIN), Vector2i(3, GRID_MAX), Vector2i(GRID_MIN, 3), Vector2i(GRID_MAX, 3)]
const MIN_CAMERA_ZOOM := 0.65
const MAX_CAMERA_ZOOM := 2.4
const HIT_SPARK_TIME := 0.18
const BUILD_SHORTCUTS := {
	KEY_1: "basic", KEY_2: "heavy", KEY_3: "rocket", KEY_4: "electric",
	KEY_5: "flame", KEY_6: "freeze", KEY_7: "repair", KEY_8: "wall", KEY_9: "aa",
	KEY_F1: "clinic", KEY_F2: "supply", KEY_F3: "workshop", KEY_F4: "research", KEY_F5: "outpost",
}
const RESERVED_KEYS := [KEY_Q, KEY_TAB, KEY_C, KEY_B, KEY_G, KEY_U, KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_F6]
const MAX_ENEMIES := 3000
const MAX_CORPSES := 160
const WAVE_TARGETS := [50, 100, 200, 350, 500, 750, 1000, 1300, 1600, 1900, 2000]
const MAX_XP_CHOICES := 100
const WAVE_SPAWN_MULTIPLIER := 5
const WAVE_SECONDS := 22.0
const BASE_CELL := Vector2i(3, 3)
const PALETTE := {
	"bg": Color("#121719"), "ground": Color("#202826"), "road": Color("#303733"), "line": Color("#72796a"),
	"panel": Color("#202927"), "edge": Color("#566359"), "text": Color("#ece9dc"), "muted": Color("#a8b0a7"),
	"gold": Color("#d0a873"), "green": Color("#8db296"), "red": Color("#df7664"), "blue": Color("#78b7c2"), "white": Color("#ffffff")
}

var jeju_map := FlatArena.new()
var jeju_background: Sprite2D
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
const DASH_ECHO_LIFE := 0.18
var dash_echoes: Array[Dictionary] = []
var dash_echo_time := 0.0
var skill_ready_at := 0.0
var skill_active_until := 0.0
var shield_dash := false
var shield_targets: Dictionary = {}
var saw_heat := 0.0
var saw_overheated := false
var saw_last_cut := -1.0
var saw_chain := 0
var saw_repair_kills := 0
var saw_cut_audio_at := 0.0
var combat_drone_position := Vector2.ZERO
var combat_drone_fire_at := -1.0
var combat_drone_facing := Vector2.RIGHT
var skill_button: Button
var dash_status: Label
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
var enemy_update_group := 0
const AMBUSH_WARNING := 0.85
const AMBUSH_RADIUS := 37.0
var pending_skill_blasts: Array[Dictionary] = []
var last_crit_at := -10.0
var last_kill_at := -10.0
var toxin_zones: Array[Dictionary] = []
var player_slime := 0.0
var treatment_remaining := 0.0
var expedition_remaining := 0.0
var mercenary_level := 0
var simulation_speed := 1.0
var boss_spawned: Dictionary = {}
var final_boss_defeated := false
var augment_queue := 0
var csv_passive: Dictionary = {}
var csv_conditional: Dictionary = {}
var csv_trigger_until: Dictionary = {}
var last_dash_at := -10.0
var last_reload_at := -10.0
var clinic_shield := 0.0
var repair_drone_level := 0
var repair_drone_pos := Vector2.ZERO
var repair_drone_cooldown := 0.0
var structures: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var warned_enemies: Dictionary = {}
var field_warning: PanelContainer
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
var augment_reroll_used := 0
var augment_options: Array[Dictionary] = []
var picked_augment_ids: Array[String] = []
var acquired_augments: Dictionary = {}
var run_base_stats: Dictionary = {}
var operator_info: OperatorInfo
var hud_portrait: TextureRect
var hud_hero := -1
var hud_name: Label
var hud_health: Label
var hud_level: Label
var hud_hq: Label
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
var zombie_ambient_at := 0.0
var impact_sound_at := 0.0
var shake_on := true
var dash_key := KEY_SHIFT
var pause_key := KEY_ESCAPE
var awaiting_binding := ""
var permanent_upgrades: Dictionary = {}
var saved_run: Dictionary = {}
var _random := RandomNumberGenerator.new()
var _yujin_visual = YujinVisual.new()
var _harin_visual = HarinVisual.new()
var _infantry_visual := InfantryVisual.new()
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
var settings_from_pause := false
var settings_back_button: Button
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
	jeju_background = jeju_map.create_background()
	add_child(jeju_background)
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
	delta *= simulation_speed
	while not dash_echoes.is_empty() and float(dash_echoes[0].until) <= run_seconds:
		dash_echoes.pop_front()
	if treatment_remaining <= 0.0:
		_update_player(delta)
	else:
		AudioDirector.set_chainsaw_motor(false)
	_update_operator_skill(delta)
	player_projectiles.update(delta, enemies, _damage_enemy)
	_yujin_visual.update(delta, player_motion)
	_infantry_visual.update(delta, player_motion)
	_harin_visual.update(delta, player_motion, player_hp, Data.CHARACTERS[player_index].id == "harin")
	_update_spawn(delta)
	_update_enemies(delta)
	_update_toxins(delta)
	_resolve_skill_blasts()
	_update_turrets(delta)
	_update_repair_drone(delta)
	_update_projectiles(delta)
	_update_effects(delta)
	_update_zombie_corpses(run_seconds + delta)
	_update_facilities(delta)
	_update_progress(delta)
	if screen == "play":
		field_warning.update(delta, player_index, Data.CHARACTERS[player_index].name)
	run_seconds += delta
	player_hp = minf(player_hp, _effective_player_max_hp())
	save_timer += delta
	if save_timer >= 12.0:
		save_timer = 0.0
		_save_all()
	_refresh_hud()


func _input(event: InputEvent) -> void:
	if screen == "play" and awaiting_binding.is_empty() and event is InputEventKey:
		var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if BUILD_SHORTCUTS.has(code) or code in [KEY_U, KEY_F6]:
			get_viewport().set_input_as_handled()
			if event.pressed and not event.echo:
				if code == KEY_F6:
					simulation_speed = 2.0 if simulation_speed == 1.0 else 1.0
					_show_toast("작전 속도 %.0f배" % simulation_speed)
				elif code == KEY_U:
					if not build_mode:
						_upgrade_selected()
				else:
					_select_build(BUILD_SHORTCUTS[code])
			return
	if screen in ["play", "info"] and event is InputEventKey and (event.physical_keycode == KEY_C or event.keycode == KEY_C):
		get_viewport().set_input_as_handled()
		if event.pressed and not event.echo:
			_toggle_operator_info()
		return
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
		var other_key := pause_key if awaiting_binding == "dash" else dash_key
		if RESERVED_KEYS.has(binding) or BUILD_SHORTCUTS.has(binding) or binding == other_key:
			_show_toast("이미 사용 중인 키입니다.")
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
			elif screen == "info":
				_toggle_operator_info()
			elif screen == "settings":
				_close_settings()
			elif screen == "augment":
				_show_toast("증강을 선택해야 작전이 계속됩니다.")
			get_viewport().set_input_as_handled()
			return
		if screen == "play":
			if code == KEY_B:
				_toggle_build_panel()
				get_viewport().set_input_as_handled()
			elif code == KEY_Q:
				_use_operator_skill()
				get_viewport().set_input_as_handled()
			elif code == dash_key:
				_try_dash()
				get_viewport().set_input_as_handled()
			elif code == KEY_G:
				_open_base_management()
				get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.pressed and screen == "play":
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var step := 0.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -0.15
			camera_zoom = clampf(camera_zoom + step, MIN_CAMERA_ZOOM, MAX_CAMERA_ZOOM)
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
	var world_visible := screen in ["play", "pause", "augment", "result", "landing", "info"] or (screen == "settings" and settings_from_pause)
	jeju_background.visible = world_visible
	if world_visible:
		jeju_map.align_background(jeju_background, player_pos, size, _view_zoom())
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
	flow_prologue.skipped.connect(func():
		_start_new_run()
		skip_landing())
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
	box.add_child(_make_button("조작키 기본값 복원", _reset_key_bindings, PALETTE.blue, 380))
	settings_back_button = _make_button("메뉴로", _close_settings, PALETTE.gold, 260)
	box.add_child(settings_back_button)
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
	field_warning = FieldWarning.new()
	run_hud.add_child(field_warning)
	field_warning.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	field_warning.offset_left = 20.0
	field_warning.offset_bottom = -43.0
	field_warning.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var pilot := _hud_plate(Vector2(14, 12))
	var pilot_row := HBoxContainer.new()
	pilot_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pilot.add_child(pilot_row)
	hud_portrait = TextureRect.new()
	hud_portrait.custom_minimum_size = Vector2(44, 52)
	hud_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hud_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hud_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pilot_row.add_child(hud_portrait)
	var pilot_details := VBoxContainer.new()
	pilot_details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pilot_row.add_child(pilot_details)
	hud_name = OpsUI.label("", 15)
	hud_level = OpsUI.label("", 12, OpsUI.GOLD)
	hud_health = OpsUI.label("", 12)
	pilot_details.add_child(hud_name)
	pilot_details.add_child(hud_level)
	hp_bar = _hud_bar(108.0, Color("#b74743"))
	pilot_details.add_child(hp_bar)
	hud_health.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_health.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hp_bar.add_child(hud_health)

	var base := _hud_plate(Vector2(195, 12))
	var base_column := VBoxContainer.new()
	base_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.add_child(base_column)
	stage_label = OpsUI.label("", 13, OpsUI.GOLD)
	base_column.add_child(stage_label)
	hud_hq = OpsUI.label("", 12)
	base_column.add_child(hud_hq)
	base_bar = _hud_bar(150.0, Color("#699a60"))
	base_column.add_child(base_bar)
	var resources := _hud_plate(Vector2(451, 12))
	currency_label = OpsUI.label("", 13)
	resources.add_child(currency_label)
	var ammo_panel := _hud_plate(Vector2(195, 75))
	combat_label = OpsUI.label("", 13, OpsUI.GOLD)
	ammo_panel.add_child(combat_label)
	status_label = OpsUI.label("", 12, OpsUI.GOLD)
	status_label.position = Vector2(14, 101)
	run_hud.add_child(status_label)
	boss_label = OpsUI.label("", 14, PALETTE.red)
	boss_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	boss_label.offset_top = 112
	boss_label.offset_bottom = 135
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	run_hud.add_child(boss_label)
	var buttons := HBoxContainer.new()
	buttons.anchor_left = 1.0
	buttons.anchor_right = 1.0
	buttons.offset_left = -188.0
	buttons.offset_right = -14.0
	buttons.offset_top = 12
	buttons.add_theme_constant_override("separation", 6)
	run_hud.add_child(buttons)
	buttons.add_child(OpsUI.tool_button("info", "캐릭터 정보 [C]", _toggle_operator_info))
	buttons.add_child(OpsUI.tool_button("build", "건설 [B]", _toggle_build_panel))
	buttons.add_child(OpsUI.tool_button("base", "지휘본부 관리 [G]", _open_base_management))
	buttons.add_child(OpsUI.tool_button("pause", "일시정지", _toggle_pause))
	build_panel = PanelContainer.new()
	build_panel.anchor_left = 1.0
	build_panel.anchor_right = 1.0
	build_panel.offset_top = 70
	build_panel.offset_bottom = 70
	build_panel.offset_left = -278
	build_panel.offset_right = -14
	build_panel.custom_minimum_size.x = 264
	build_panel.add_theme_stylebox_override("panel", OpsUI.plate(OpsUI.GOLD, Color("#1c2220f8"), 9.0))
	build_panel.visible = false
	build_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	run_hud.add_child(build_panel)
	build_content = VBoxContainer.new()
	build_content.add_theme_constant_override("separation", 5)
	build_panel.add_child(build_content)
	build_status_label = _make_label("전장 클릭 · 우클릭 취소", 12, PALETTE.muted)
	build_status_label.custom_minimum_size.y = 16
	build_status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	build_content.add_child(build_status_label)
	var abilities := HBoxContainer.new()
	abilities.name = "CombatAbilities"
	run_hud.add_child(abilities)
	abilities.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	abilities.offset_left = -160
	abilities.offset_right = 160
	abilities.offset_top = -91
	abilities.offset_bottom = -42
	abilities.alignment = BoxContainer.ALIGNMENT_CENTER
	abilities.add_theme_constant_override("separation", 7)
	skill_button = Button.new()
	skill_button.custom_minimum_size = Vector2(204, 44)
	skill_button.focus_mode = Control.FOCUS_NONE
	skill_button.add_theme_stylebox_override("normal", OpsUI.plate(Color("#a182db"), Color("#201a30")))
	skill_button.add_theme_stylebox_override("hover", OpsUI.plate(Color("#d4c0ff"), Color("#342442")))
	skill_button.add_theme_stylebox_override("disabled", OpsUI.plate(Color("#63596a"), Color("#18161e")))
	skill_button.pressed.connect(_use_operator_skill)
	abilities.add_child(skill_button)
	var dash_panel := PanelContainer.new()
	dash_panel.add_theme_stylebox_override("panel", OpsUI.plate(OpsUI.GOLD, Color("#241e16")))
	abilities.add_child(dash_panel)
	dash_status = OpsUI.label("", 13)
	dash_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dash_status.custom_minimum_size.x = 90.0
	dash_panel.add_child(dash_status)
	var hint := _make_label("건설 [B]   포탑 [1–6]   수리 드론 [7]   방벽 [8]   시설 [F1–F5]   강화 [U]   배속 [F6]   우클릭 취소", 12, PALETTE.muted, true)
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
	ivbox.add_child(_make_button("강화 [U]", _upgrade_selected, PALETTE.green, 270))
	var expedition := _make_button("용병 파견", _start_expedition, PALETTE.gold, 270)
	expedition.name = "Expedition"
	ivbox.add_child(expedition)
	var mercenary := _make_button("용병 강화", _upgrade_mercenary, PALETTE.green, 270)
	mercenary.name = "Mercenary"
	ivbox.add_child(mercenary)
	ivbox.add_child(_make_button("철거", _remove_selected, PALETTE.red, 270))
	ivbox.add_child(_make_button("닫기", _close_inspector, PALETTE.blue, 270))
	operator_info = OperatorInfo.new()
	operator_info.closed.connect(_toggle_operator_info)
	game_ui.add_child(operator_info)
	operator_info.hide()
	game_ui.visible = false


func _hud_plate(position: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", OpsUI.plate(Color("#7b6945")))
	run_hud.add_child(panel)
	return panel


func _hud_bar(width: float, fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(width, 16)
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", OpsUI.plate(Color("#635646"), Color("#242626"), 0.0))
	bar.add_theme_stylebox_override("fill", OpsUI.plate(fill, fill, 0.0))
	return bar


func _open_base_management() -> void:
	if screen != "play":
		return
	var hq := _hq_index()
	if hq >= 0:
		_cancel_build()
		selected_entity = hq
		_open_inspector()


func _toggle_operator_info() -> void:
	if screen == "info":
		_show_screen("play")
	elif screen == "play":
		operator_info.fill("캐릭터 정보  /  %s  ·  Lv.%d" % [Data.CHARACTERS[player_index].name, player_level],
			_operator_portrait(), _operator_stat_rows(), acquired_augments.values(),
			"고유 능력 · %s
%s" % Skills.PROFILES[Data.CHARACTERS[player_index].id])
		_show_screen("info")


func _operator_portrait() -> AtlasTexture:
	var texture: Texture2D = FlowUI.PORTRAITS[player_index]
	var portrait := AtlasTexture.new()
	portrait.atlas = texture
	portrait.region = Rect2(texture.get_width() * 0.17, 0.0, texture.get_width() * 0.66, texture.get_height() * 0.40)
	return portrait


func _build_pause_screen() -> void:
	var box := _center_box(pause_screen)
	box.add_theme_constant_override("separation", 14)
	pause_label = _make_label("작전 일시정지", 34, PALETTE.gold, true)
	box.add_child(pause_label)
	box.add_child(_make_button("계속", _close_pause, PALETTE.green, 320))
	box.add_child(_make_button("설정", _show_settings.bind(true), PALETTE.blue, 320))
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
	var was_in_combat := screen in ["play", "augment", "pause", "info"] or (screen == "settings" and settings_from_pause)
	if which != "play":
		AudioDirector.stop_shield_windup()
		manual_trigger = false
		AudioDirector.set_chainsaw_motor(false)
	screen = which
	operator_info.visible = which == "info"
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
		"play", "info": game_ui.visible = true
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
	var combat_paused := which in ["pause", "info"] or (which == "settings" and settings_from_pause)
	AudioDirector.set_game_paused(combat_paused)
	if sound_on and which in ["play", "augment"]:
		AudioDirector.play_music("music.gameplay")
	elif was_in_combat and not combat_paused:
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
	landing.operator_line = PrologueScreen.HERO_LINES[player_index]
	player_pos = landing.player_world()
	_show_screen("landing")
func _update_landing(delta: float) -> void:
	landing.update(delta)
	var before := player_pos
	player_pos = landing.player_world()
	player_motion = (player_pos - before) / maxf(delta, 0.001)
	if player_motion.length() > 1.0:
		player_facing = player_motion.normalized()
	_yujin_visual.update(delta, player_motion)
	_infantry_visual.update(delta, player_motion)
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
	toxin_zones.clear()
	pending_skill_blasts.clear()
	last_crit_at = -10.0
	last_kill_at = -10.0
	player_slime = 0.0
	treatment_remaining = 0.0
	expedition_remaining = 0.0
	mercenary_level = 0
	simulation_speed = 1.0
	boss_spawned.clear()
	final_boss_defeated = false
	augment_queue = 0
	csv_passive.clear()
	csv_conditional.clear()
	csv_trigger_until.clear()
	last_dash_at = -10.0
	last_reload_at = -10.0
	clinic_shield = 0.0
	_yujin_visual.reset()
	_harin_visual = HarinVisual.new()
	_infantry_visual = InfantryVisual.new()
	difficulty = Data.DIFFICULTIES[difficulty_index].duplicate(true)
	stage = 1
	stage_elapsed = 0.0
	run_seconds = 0.0
	zombie_sound_at = 0.0
	zombie_ambient_at = 0.0
	impact_sound_at = 0.0
	money = 150
	kills = 0
	boss_kills = 0
	dead_count = 0
	player_xp = 0.0
	player_level = 1
	augments_taken = 0
	augment_reroll_used = 0
	picked_augment_ids.clear()
	acquired_augments.clear()
	repair_drone_level = 0
	repair_drone_pos = Vector2.ZERO
	repair_drone_cooldown = 0.0
	structures.clear()
	enemies.clear()
	zombie_corpses.clear()
	field_warning.clear()
	warned_enemies.clear()
	enemy_pool.clear()
	enemy_shots.clear()
	player_projectiles.shots.clear()
	effects.clear()
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
	player_magazine = _magazine_capacity()
	manual_attack = false
	manual_trigger = false
	dash_timer = 0.0
	dash_echoes.clear()
	dash_echo_time = 0.0
	skill_ready_at = 0.0
	skill_active_until = 0.0
	shield_dash = false
	AudioDirector.stop_shield_windup()
	shield_targets.clear()
	saw_heat = 0.0
	saw_overheated = false
	saw_last_cut = -1.0
	saw_chain = 0
	saw_repair_kills = 0
	AudioDirector.set_chainsaw_motor(false)
	saw_cut_audio_at = 0.0
	drone_timer = 0.0
	combat_drone_position = PLAYER_START + Vector2(34, -28)
	combat_drone_fire_at = -1.0
	dash_cooldown = 0.0
	player_mod_damage += float(permanent_upgrades.get("damage", 0)) * 0.06
	player_mod_speed += float(permanent_upgrades.get("speed", 0)) * 0.04
	player_mod_range += float(permanent_upgrades.get("range", 0)) * 0.05
	player_mod_build = maxf(0.55, player_mod_build - float(permanent_upgrades.get("build", 0)) * 0.04)
	player_mod_building_hp += float(permanent_upgrades.get("building_hp", 0)) * 0.08
	player_mod_rate += float(permanent_upgrades.get("reload", 0)) * 0.04
	player_mod_salvage += float(permanent_upgrades.get("salvage", 0)) * 0.05
	run_base_stats = _combat_stats()
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
	var ability: Dictionary = state.get("operator_skill", {})
	skill_ready_at = float(ability.get("ready", 0.0))
	skill_active_until = float(ability.get("active", 0.0))
	saw_heat = float(ability.get("heat", 0.0))
	saw_overheated = bool(ability.get("overheated", false))
	saw_repair_kills = int(ability.get("repair_kills", 0))
	saw_chain = 0
	saw_last_cut = -1.0
	AudioDirector.set_chainsaw_motor(false)
	saw_cut_audio_at = 0.0
	shield_dash = false
	AudioDirector.stop_shield_windup()
	shield_targets.clear()
	dash_echoes.clear()
	dash_timer = 0.0
	money = int(state.get("money", 0))
	kills = int(state.get("kills", 0))
	player_level = int(state.get("level", 1))
	player_xp = float(state.get("xp", 0.0))
	boss_kills = int(state.get("boss_kills", 0))
	var hero: Dictionary = Data.CHARACTERS[player_index]
	player_max_hp = float(state.get("player_max_hp", hero.hp))
	treatment_remaining = maxf(0.0, float(state.get("treatment_remaining", 0.0)))
	expedition_remaining = maxf(0.0, float(state.get("expedition_remaining", 0.0)))
	mercenary_level = clampi(int(state.get("mercenary_level", 0)), 0, 10)
	simulation_speed = 1.0
	augment_queue = maxi(0, int(state.get("augment_queue", 0)))
	final_boss_defeated = bool(state.get("final_boss_defeated", false))
	player_hp = clampf(float(state.get("player_hp", player_max_hp)), 0.0 if treatment_remaining > 0.0 else 1.0, player_max_hp)
	player_projectiles.shots.clear()
	enemy_shots.clear()
	manual_attack = bool(state.get("manual_attack", false))
	manual_trigger = false
	var pp: Array = state.get("player_pos", [180.0, 112.0])
	player_pos = jeju_map.nearest_land(Vector2(float(pp[0]), float(pp[1])), PLAYER_RADIUS)
	combat_drone_position = player_pos + Vector2(34, -28)
	combat_drone_fire_at = -1.0
	repair_drone_level = clampi(int(state.get("repair_drone_level", 0)), 0, 11)
	repair_drone_cooldown = 0.0
	structures.clear()
	for entry in state.get("structures", []):
		if entry.get("kind") == "repair":
			if float(entry.get("hp", 0.0)) > 0.0:
				repair_drone_level = maxi(repair_drone_level, clampi(int(entry.get("level", 1)), 1, 5))
			continue
		structures.append({"kind": String(entry.get("kind", "wall")), "cell": Vector2i(int(entry.get("x", 0)), int(entry.get("y", 0))), "hp": float(entry.get("hp", 100.0)), "max_hp": float(entry.get("max_hp", 100.0)), "level": int(entry.get("level", 1)), "cool": 0.0, "built": true})
	if structures.is_empty():
		structures.append({"kind": "hq", "cell": BASE_CELL, "hp": 1200.0, "max_hp": 1200.0, "level": 1, "cool": 0.0, "built": true})
	repair_drone_pos = _hq_position()
	enemies.clear()
	zombie_corpses.clear()
	field_warning.clear()
	warned_enemies.clear()
	for kind in state.get("warned_enemies", []):
		if FieldWarning.WARNINGS.has(String(kind)):
			warned_enemies[String(kind)] = true
	for kind in state.get("pending_enemy_warnings", []):
		if warned_enemies.has(String(kind)):
			field_warning.enqueue(String(kind))
	for entry in state.get("enemies", []):
		var saved_pos := Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0)))
		var enemy: Dictionary = _make_enemy(String(entry.get("kind", "normal")), jeju_map.nearest_land(saved_pos, ZombieVisual.RADIUS), bool(entry.get("boss", false)))
		enemy.hp = float(entry.get("hp", enemy.max_hp))
		enemy.cool = float(entry.get("cool", 0.5))
		var saved_variant := int(entry.get("variant", -1))
		if enemy.has("variant") and saved_variant >= 0 and saved_variant < ZombieVisual.SHEETS.size():
			enemy.variant = saved_variant
			enemy.appearance = clampi(int(entry.get("appearance", saved_variant)), 0, 49)
		if enemy.kind == "S10":
			enemy.underground = bool(entry.get("underground", true))
			if enemy.underground and entry.has("burrow_warning"):
				enemy.burrow_warning = float(entry.burrow_warning)
		enemies.append(enemy)
		_warn_enemy_once(enemy.kind)
	_restore_run_modifiers()
	var capacity := _magazine_capacity()
	player_magazine = clampi(int(state.get("magazine", capacity)), 0, capacity)
	player_attack_timer = 0.0
	player_reload_timer = 0.0
	if capacity > 0 and player_magazine == 0:
		player_reload_timer = clampf(float(state.get("reload_remaining", hero.reload)), 0.0, float(hero.reload))
		if player_reload_timer == 0.0:
			player_magazine = capacity
	win_state = false
	spawn_timer = 1.5
	augment_reroll_used = 0
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


func _show_settings(from_pause := false) -> void:
	settings_from_pause = from_pause
	settings_back_button.text = "일시정지로" if from_pause else "메뉴로"
	_show_screen("settings")


func _close_settings() -> void:
	awaiting_binding = ""
	_show_screen("pause" if settings_from_pause else "menu")
	settings_from_pause = false


func _reset_key_bindings() -> void:
	awaiting_binding = ""
	dash_key = KEY_SHIFT
	pause_key = KEY_ESCAPE
	_update_binding_labels()
	_save_all()


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
	elif settings_from_pause:
		AudioDirector.play_music("music.gameplay")
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
		build_status_label.text = "전장 클릭 · 우클릭 취소"
	queue_redraw()


func _refresh_build_panel() -> void:
	if build_content == null: return
	for child in build_content.get_children():
		if child != build_status_label:
			build_content.remove_child(child)
			child.queue_free()
	var header := HBoxContainer.new()
	build_content.add_child(header)
	var title := _make_label("건설 · 11×11", 15, PALETTE.gold)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := _build_menu_button("닫기 ×", _toggle_build_panel, PALETTE.gold)
	close.name = "CloseBuild"
	close.tooltip_text = "건설 창 닫기 [B]"
	header.add_child(close)
	var tabrow := HBoxContainer.new()
	tabrow.add_theme_constant_override("separation", 4)
	build_content.add_child(tabrow)
	for tab in ["turret", "building", "wall"]:
		var tab_title: String = {"turret": "포탑", "building": "시설", "wall": "방벽"}[tab]
		var tab_button := _build_menu_button(tab_title, _select_build_tab.bind(tab), PALETTE.blue if build_tab == tab else PALETTE.gold)
		tab_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabrow.add_child(tab_button)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 3)
	if build_tab == "wall":
		build_content.add_child(list)
		_add_build_option(list, _build_definition("wall"), PALETTE.gold)
	else:
		var scroll := ScrollContainer.new()
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.custom_minimum_size.y = 153
		build_content.add_child(scroll)
		scroll.add_child(list)
		var items := Data.TURRETS if build_tab == "turret" else Data.BUILDINGS
		for item in items:
			_add_build_option(list, item, item.get("color", PALETTE.green))
		if build_tab == "building":
			if repair_drone_level == 0:
				_add_build_option(list, Data.REPAIR_DRONE, Data.REPAIR_DRONE.color)
				list.move_child(list.get_child(-1), 0)
			else:
				var label := "수리 드론 Lv.%d · 강화 %d" % [repair_drone_level, _repair_drone_upgrade_cost()] if repair_drone_level < 11 else "수리 드론 +10 · 최대 강화"
				var upgrade := _build_menu_button(label, _upgrade_repair_drone, Data.REPAIR_DRONE.color)
				upgrade.disabled = repair_drone_level >= 11
				list.add_child(upgrade)
				list.move_child(upgrade, 0)

	build_content.move_child(build_status_label, build_content.get_child_count() - 1)
	_fit_build_panel.call_deferred()


func _fit_build_panel() -> void:
	build_panel.size = Vector2(264, 0)


func _add_build_option(list: VBoxContainer, item: Dictionary, accent: Color) -> void:
	var key := OS.get_keycode_string(BUILD_SHORTCUTS.find_key(item.id))
	var price := _structure_cost(String(item.id), int(item.cost))
	var button := _build_menu_button("[%s] %s  ·  %d" % [key, item.name, price], _select_build.bind(String(item.id)), accent)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.tooltip_text = "%s · %d 보급품" % [item.role, price]
	list.add_child(button)


func _build_menu_button(label: String, action: Callable, accent: Color) -> Button:
	var button := _make_button(label, action, accent, 0.0)
	button.custom_minimum_size.y = 26
	button.add_theme_font_size_override("font_size", 13)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		style.content_margin_left = 6.0
		style.content_margin_right = 6.0
		style.content_margin_top = 3.0
		style.content_margin_bottom = 3.0
		button.add_theme_stylebox_override(state, style)
	return button


func _select_build_tab(tab: String) -> void:
	build_tab = tab
	_cancel_build()
	_refresh_build_panel()


func _select_build(kind: String) -> void:
	if kind == "repair":
		_install_repair_drone()
		return
	selected_build = kind
	build_mode = true
	selected_entity = -1
	var item := _build_definition(kind)
	build_status_label.text = "%s 선택 · 전장 클릭" % String(item.get("name", "방벽"))
	var inspector := run_hud.find_child("Inspector", true, false) as Control
	if inspector: inspector.visible = false


func _structure_cost(kind: String, price: int) -> int:
	var key := "wall_cost" if kind == "wall" else "turret_cost" if _is_turret(kind) else "facility_cost" if _is_building(kind) else ""
	return maxi(1, roundi(_effective_cost(price) * _csv_reduction(key)))


func _effective_cost(base: int) -> int:
	var hero: Dictionary = Data.CHARACTERS[player_index]
	return maxi(1, int(round(float(base) * _build_cost_factor(hero, player_mod_build))))


func _build_definition(kind: String) -> Dictionary:
	if kind == "repair": return Data.REPAIR_DRONE
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
	return BUILD_ENTRANCES.has(cell)


func _validate_placement(kind: String, cell: Vector2i) -> String:
	var definition := _build_definition(kind)
	var width := 2 if _is_building(kind) else 1
	if cell.x < GRID_MIN or cell.y < GRID_MIN or cell.x + width - 1 > GRID_MAX or cell.y > GRID_MAX:
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
	for enemy in enemies:
		if enemy.has("burrow_warning") and _structure_overlap_depth(enemy.pos, center, width, PlayerProjectiles.enemy_radius(enemy)) >= 0.0:
			return "지면이 갈라지는 곳에는 배치할 수 없습니다."
	var overlap_depth := _structure_overlap_depth(player_pos, center, width, PLAYER_RADIUS)
	if overlap_depth >= 0.0: return "대원이 서 있는 곳에는 배치할 수 없습니다."
	if _is_building(kind):
		for entry in structures:
			if String(entry.kind) == kind and float(entry.hp) > 0.0:
				return "같은 종류의 시설은 한 개만 지을 수 있습니다."
	if _is_turret(kind):
		var cap := (Data.YUJIN_TURRET_CAP if Data.CHARACTERS[player_index].id == "yujin" else Data.TURRET_CAP) + int(_csv_bonus("turret_cap")) + int(_csv_bonus("iron_fortress"))
		var count := 0
		for entry in structures:
			if _is_turret(String(entry.kind)) and float(entry.hp) > 0.0: count += 1
		if count >= cap: return "포탑 한도 %d기에 도달했습니다." % cap
	var cost := _structure_cost(kind, int(definition.get("cost", 0)))
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
	for index in range(4):
		if not _grid_path_exists(BUILD_ENTRANCES[index], goals[index], blocked): return false
	return true


func _grid_path_exists(start: Vector2i, goal: Vector2i, blocked: Dictionary) -> bool:
	var queue: Array[Vector2i] = [start]
	var seen: Dictionary = {start: true}
	while not queue.is_empty():
		var cur: Vector2i = queue.pop_front()
		if cur == goal: return true
		for step in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next: Vector2i = cur + step
			if next.x < GRID_MIN or next.y < GRID_MIN or next.x > GRID_MAX or next.y > GRID_MAX: continue
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
	var cost := _structure_cost(selected_build, int(def.get("cost", 0)))
	var hp_key := "wall_hp" if selected_build == "wall" else "turret_hp" if _is_turret(selected_build) else "facility_hp"
	var maxhp := float(def.get("hp", 180.0)) * player_mod_building_hp * (_csv_factor(hp_key) + (_csv_bonus("clinic_hp") / 100.0 if selected_build == "clinic" else 0.0))
	_mark_csv_trigger("build")
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
	inspector.find_child("Expedition", true, false).visible = s.kind == "supply"
	inspector.find_child("Mercenary", true, false).visible = s.kind == "supply"
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
	if int(s.level) >= (6 if kind == "wall" else 11):
		_show_toast("최대 레벨입니다.")
		return
	var key := "wall_upgrade" if kind == "wall" else "hq_upgrade" if kind == "hq" else "turret_upgrade" if _is_turret(kind) else "facility_upgrade"
	var cost := roundi((30 + int(s.level) * 24) * 1.30 * _csv_reduction(key))
	if money < cost:
		_show_toast("강화에 보급품 %d개가 필요합니다." % cost)
		return
	money -= cost
	s.level = int(s.level) + 1
	s.max_hp *= 1.264
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
	money += int(round(float(_build_definition(String(s.kind)).get("cost", 0)) * 0.35 * _csv_factor("refund")))
	structures.remove_at(selected_entity)
	selected_entity = -1
	_close_inspector()
	_save_all()


func _try_dash() -> void:
	if dash_cooldown > 0.0 or screen != "play" or treatment_remaining > 0.0: return
	var direction := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): direction.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): direction.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): direction.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): direction.x += 1.0
	if direction.length() < 0.1: direction = player_facing
	dash_direction = direction.normalized()
	dash_timer = 0.2
	dash_echo_time = 0.0
	dash_cooldown = 1.25 * _csv_reduction("dash_cooldown")
	last_dash_at = run_seconds



func _move_player(motion: Vector2) -> void:
	# Step across the footprint checks so a long dash cannot cross a cliff.
	var steps := maxi(1, ceili(maxf(absf(motion.x), absf(motion.y)) / 16.0))
	var step := motion / float(steps)
	for i in range(steps):
		var candidate_x := player_pos + Vector2(step.x, 0.0)
		if jeju_map.walkable(candidate_x, PLAYER_RADIUS) and _blocking_structure(candidate_x, PLAYER_RADIUS, true) < 0:
			player_pos.x = candidate_x.x
		var candidate_y := player_pos + Vector2(0.0, step.y)
		if jeju_map.walkable(candidate_y, PLAYER_RADIUS) and _blocking_structure(candidate_y, PLAYER_RADIUS, true) < 0:
			player_pos.y = candidate_y.y


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
	var speed := float(Data.CHARACTERS[player_index].speed) * player_mod_speed * (_csv_factor("move") + _recent_combat_bonus("crit_move", "kill_move") / 100.0) * (_csv_factor("after_dash_speed") if run_seconds - last_dash_at < 5.0 else 1.0) * (0.62 if player_slime > 0.0 else 1.0)
	if dash_timer > 0.0:
		dash_timer = maxf(0.0, dash_timer - delta)
		_move_player(dash_direction * speed * 2.8 * delta * _csv_factor("dash_distance"))
		if shield_dash:
			_resolve_shield_dash(previous_position)
		dash_echo_time -= delta
		if dash_echo_time <= 0.0 and previous_position.distance_squared_to(player_pos) > 4.0:
			dash_echo_time = 0.032
			dash_echoes.append({"pos": previous_position, "direction": dash_direction, "shield": shield_dash, "until": run_seconds + DASH_ECHO_LIFE})
	else:
		shield_dash = false
		_move_player(direction * speed * delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	player_motion = (player_pos - previous_position) / maxf(delta, 0.001)
	if not shield_dash:
		_update_player_attack(delta)
	_update_combat_drone(delta)


func _update_combat_drone(delta: float) -> void:
	var harin: bool = Data.CHARACTERS[player_index].id == "harin"
	var drone_level := player_drone_level + int(_csv_bonus("combat_drone"))
	if harin:
		drone_level = maxi(1, drone_level)
		var orbit := Vector2(cos(run_seconds * 2.4) * 42.0, sin(run_seconds * 2.4) * 13.0 - 29.0)
		combat_drone_position = combat_drone_position.move_toward(player_pos + orbit, delta * 860.0)
	if drone_level <= 0:
		return
	drone_timer -= delta
	if drone_timer > 0.0:
		return
	var origin := combat_drone_position if harin else player_pos + Vector2(20, -30)
	var drone_target := _nearest_enemy(player_pos, 460.0)
	drone_timer = 0.18 if drone_target < 0 else maxf(0.9, (3.2 - drone_level * 0.45) / _csv_factor("combat_drone_rate"))
	if harin and run_seconds < skill_active_until:
		drone_timer /= Skills.DRONE_RATE
	if drone_target < 0:
		return
	_mark_csv_trigger("drone")
	var target_pos: Vector2 = enemies[drone_target].pos
	combat_drone_facing = origin.direction_to(target_pos)
	combat_drone_fire_at = run_seconds
	var damage := 24.0 * drone_level * player_mod_damage * _csv_factor("combat_drone_damage")
	if run_seconds - last_dash_at < 5.0:
		damage *= _csv_factor("after_dash_drone")
	_damage_enemy(drone_target, damage, "drone", origin)
	var side := _tactical_drone_side()
	var muzzle := Vector2(0, 8) if side == 0.0 else Vector2(8.0 * side, 6.0)
	var emitter := origin + muzzle if harin else origin
	effects.append({"a": emitter, "b": target_pos, "time": 0.15, "color": Color("#b88dfb") if harin else PALETTE.blue})


func _use_operator_skill() -> void:
	if screen != "play" or treatment_remaining > 0.0 or run_seconds < skill_ready_at:
		return
	var hero: String = Data.CHARACTERS[player_index].id
	match hero:
		"tae":
			if dash_timer > 0.0:
				return
			dash_direction = player_facing.normalized()
			dash_timer = 0.29
			dash_echo_time = 0.0
			dash_cooldown = maxf(dash_cooldown, dash_timer)
			shield_dash = true
			shield_targets.clear()
			if sound_on:
				AudioDirector.play_shield_windup()
			skill_ready_at = run_seconds + Skills.SHIELD_COOLDOWN
		"si":
			skill_active_until = run_seconds + Skills.FOCUS_DURATION
			skill_ready_at = run_seconds + Skills.FOCUS_COOLDOWN
		"harin":
			skill_active_until = run_seconds + Skills.DRONE_DURATION
			skill_ready_at = run_seconds + Skills.DRONE_COOLDOWN
			drone_timer = 0.0
		"yujin":
			if saw_heat <= 0.0:
				return
			saw_heat = 0.0
			saw_overheated = false
			skill_ready_at = run_seconds + Skills.VENT_COOLDOWN
	_show_toast(Skills.PROFILES[hero][0])


func _resolve_shield_dash(previous: Vector2) -> void:
	if previous.is_equal_approx(player_pos):
		return
	for i in range(enemies.size() - 1, -1, -1):
		var target := enemies[i]
		if target.get("air", false) or target.get("underground", false) or shield_targets.has(target.spawn_id):
			continue
		var closest := Geometry2D.get_closest_point_to_segment(target.pos, previous, player_pos)
		if closest.distance_squared_to(target.pos) <= 31.0 * 31.0:
			if shield_targets.is_empty():
				AudioDirector.stop_shield_windup()
				if sound_on:
					AudioDirector.play_cue("player.shield_impact")
			shield_targets[target.spawn_id] = true
			var push: Vector2 = (dash_direction + (Vector2(target.pos) - closest).limit_length(24.0) / 36.0).normalized()
			target.knock_direction = push
			target.knock_left = 0.11 if target.boss else 0.22
			target.down_until = run_seconds + (0.18 if target.boss else 0.55)
			_interrupt_enemy_attack(target)
			_damage_enemy(i, Skills.SHIELD_DAMAGE, "shield", previous)


func _interrupt_enemy_attack(enemy: Dictionary) -> void:
	enemy.erase("strike_remaining")
	enemy.erase("strike_target")
	enemy.attack_until = 0.0


func _update_knocked_enemy(enemy: Dictionary, delta: float) -> void:
	var remaining := minf(delta, float(enemy.knock_left))
	enemy.knock_left = maxf(0.0, float(enemy.knock_left) - delta)
	var radius := PlayerProjectiles.enemy_radius(enemy)
	var speed := 150.0 if enemy.boss else 250.0
	while remaining > 0.0001:
		var step := minf(remaining, 0.025)
		var next: Vector2 = enemy.pos + enemy.knock_direction * speed * step
		if not jeju_map.walkable(next, radius) or _blocking_structure(next, radius) >= 0:
			enemy.knock_left = 0.0
			break
		enemy.pos = next
		remaining -= step


func _update_operator_skill(delta: float) -> void:
	if Data.CHARACTERS[player_index].id != "yujin":
		return
	if run_seconds - saw_last_cut > 0.38 or saw_overheated:
		saw_heat = maxf(0.0, saw_heat - delta * Skills.SAW_COOL_PER_SECOND)
	if saw_overheated and saw_heat <= 40.0:
		saw_overheated = false
	if run_seconds - saw_last_cut > 0.55:
		saw_chain = 0


func _update_player_attack(delta: float) -> void:
	var hero: Dictionary = Data.CHARACTERS[player_index]
	var wants_attack := false
	if manual_attack:
		var aim := _screen_to_world(aim_screen) - player_pos
		if not aim.is_zero_approx():
			player_facing = aim.normalized()
		wants_attack = screen == "play" and manual_trigger and not build_mode
	else:
		var target := _nearest_enemy(player_pos, _weapon_range(hero))
		if target >= 0:
			var aim: Vector2 = enemies[target].pos - player_pos
			if not aim.is_zero_approx():
				player_facing = aim.normalized()
			wants_attack = true

	player_attack_timer = maxf(0.0, player_attack_timer - delta)
	if player_reload_timer > 0.0:
		player_reload_timer = maxf(0.0, player_reload_timer - delta)
		if player_reload_timer == 0.0:
			player_magazine = _magazine_capacity()
			last_reload_at = run_seconds
	if wants_attack and player_attack_timer <= 0.0 and player_reload_timer <= 0.0:
		_attack_player()
	AudioDirector.set_chainsaw_motor(screen == "play" and hero.id == "yujin" and wants_attack, saw_overheated)


func _attack_player() -> void:
	var hero: Dictionary = Data.CHARACTERS[player_index]
	var kind := String(hero.id)
	if kind != "yujin" and player_magazine <= 0:
		return
	_mark_csv_trigger("attack")
	var interval := _weapon_interval(hero, player_mod_rate * (_csv_factor("rate") + _recent_combat_bonus("crit_rate", "kill_rate") / 100.0))
	if kind == "yujin":
		saw_last_cut = run_seconds
		if not saw_overheated:
			saw_heat = minf(100.0, saw_heat + interval * Skills.SAW_HEAT_PER_SECOND)
			saw_overheated = saw_heat >= 100.0
		_yujin_visual.attack(interval, player_facing)
		player_attack_timer = interval
		var direction := player_facing.normalized()
		var reach := _weapon_range(hero)
		var made_contact := false
		for i in range(enemies.size() - 1, -1, -1):
			var target_pos: Vector2 = enemies[i].pos
			var toward := target_pos - player_pos
			if toward.length() <= reach and (toward.is_zero_approx() or direction.dot(toward.normalized()) > cos(deg_to_rad(minf(85.0, 45.0 * _csv_factor("saw_angle"))))):
				_damage_enemy(i, _weapon_damage(hero, player_mod_damage), "chainsaw")
				saw_chain = mini(6, saw_chain + 1)
				made_contact = true
		if sound_on:
			_play_saw_attack(made_contact)
		return
	player_magazine -= 1
	if player_magazine == 0:
		player_reload_timer = float(hero.reload) / _csv_factor("reload")
	var muzzle := player_pos
	var tracer_offset := Vector2.ZERO
	if kind == "harin":
		_harin_visual.trigger_attack(player_facing)
		muzzle += _harin_visual.muzzle_offset(player_facing) * PLAYER_DRAW_SCALE / _view_zoom()
	else:
		_infantry_visual.attack(player_facing)
		tracer_offset = _infantry_visual.muzzle(kind, player_facing) * PLAYER_DRAW_SCALE / _view_zoom()
	if sound_on:
		AudioDirector.play_cue("player.shotgun" if kind == "tae" else "player.m4", 1.08 if kind == "si" else 1.0)
	player_attack_timer = interval
	var direction := player_facing.normalized()
	var max_range := _weapon_range(hero)
	var pellets := (int(hero.pellets) + player_extra_pellets if kind == "tae" else 1) + int(_csv_bonus("pellets"))
	var damage := _weapon_damage(hero, player_mod_damage) / float(pellets)
	var color: Color = PALETTE.gold if kind == "tae" else PALETTE.blue
	var element_mask := _weapon_elements()
	for pellet in range(pellets):
		var spread := (float(pellet) - float(pellets - 1) * 0.5) * (0.105 * _csv_reduction("pellet_focus") if kind == "tae" else 0.0)
		player_projectiles.fire(muzzle, direction.rotated(spread), max_range, damage, maxi(1, player_pierce + 1 + int(_csv_bonus("pierce"))), color, _csv_factor("projectile_speed"), int(_csv_bonus("ricochet")), tracer_offset, element_mask)


func _play_saw_attack(made_contact: bool) -> void:
	if made_contact and run_seconds >= saw_cut_audio_at:
		saw_cut_audio_at = run_seconds + 0.29
		AudioDirector.play_cue("player.chainsaw", 0.92 if saw_overheated else 1.0)

func _update_spawn(delta: float) -> void:
	stage_elapsed += delta
	spawn_timer -= delta
	if stage_elapsed >= WAVE_SECONDS and stage < 100:
		stage += 1
		stage_elapsed -= WAVE_SECONDS
		_show_toast("경계 단계 %d / 100" % stage)
		if Data.BOSSES.has(stage) and not boss_spawned.has(stage):
			boss_spawned[stage] = true
			_spawn_boss(stage)
		for special in SpecialEnemies.TYPES:
			if SpecialEnemies.TYPES[special][1] == stage:
				_spawn_enemy(special, _land_spawn(_random.randf_range(0, TAU), 620.0), false)
	if stage == 100 and stage_elapsed >= WAVE_SECONDS:
		if enemies.is_empty() and final_boss_defeated:
			_finish_run(true)
		return
	var target: int = WAVE_TARGETS[10 if stage == 100 else (stage - 1) / 10]
	if spawn_timer <= 0.0 and enemies.size() < target:
		var base_interval := 1.25 / float(difficulty.get("spawn", 1.0))
		spawn_timer = maxf(0.18, base_interval * (1.0 - minf(0.55, float(stage) * 0.004)))
		var base_count := 1 + (1 if stage >= 16 and _random.randf() < 0.25 else 0)
		var count := mini(maxi(base_count * WAVE_SPAWN_MULTIPLIER, ceili(target / 9.0)) if stage > 10 else base_count * WAVE_SPAWN_MULTIPLIER, target - enemies.size())
		for n in range(count):
			var kind := _choose_enemy_kind()
			var angle := _random.randf_range(0.0, TAU)
			var distance := _random.randf_range(700.0, 940.0) if stage == 1 else _random.randf_range(470.0, 740.0)
			var pos := _land_spawn(angle, distance)
			_spawn_enemy(kind, pos, false)


func _land_spawn(angle: float, distance: float) -> Vector2:
	return jeju_map.nearest_land(_hq_position() + Vector2.from_angle(angle) * distance, 48.0)


func _choose_enemy_kind() -> String:
	if stage < 5 or _random.randf() >= minf(0.092, stage * 0.001):
		return "normal"
	var choices: Array[String] = []
	for kind in SpecialEnemies.TYPES:
		if SpecialEnemies.TYPES[kind][1] <= stage:
			choices.append(kind)
	return choices[_random.randi_range(0, choices.size() - 1)]


func _spawn_enemy(kind: String, pos: Vector2, is_boss: bool) -> void:
	enemies.append(_make_enemy(kind, pos, is_boss))
	_warn_enemy_once(kind)


func _warn_enemy_once(kind: String) -> void:
	if not warned_enemies.has(kind) and FieldWarning.WARNINGS.has(kind):
		warned_enemies[kind] = true
		field_warning.enqueue(kind)


func _make_enemy(kind: String, pos: Vector2, is_boss: bool) -> Dictionary:
	var data: Dictionary = Data.BOSSES.get(int(kind.trim_prefix("boss")), Data.BOSSES[40]) if is_boss else Data.ENEMIES.get(kind, Data.ENEMIES.normal)
	var special := SpecialEnemies.definition(kind)
	if not special.is_empty():
		data = special
	var hp := float(data.hp) * float(difficulty.get("hp", 1.0))
	if is_boss: hp *= 1.0 + float(maxi(stage - 40, 0)) * 0.012
	var enemy: Dictionary = enemy_pool.pop_back() if not enemy_pool.is_empty() else {}
	enemy.clear()
	enemy.merge({"kind": kind, "name": String(data.name), "pos": pos, "hp": hp, "max_hp": hp, "speed": float(data.speed) * (1.0 + float(stage) * 0.0012), "attack": float(data.attack) * float(difficulty.get("attack", 1.0)), "color": data.color, "ranged": bool(data.get("ranged", is_boss)), "boss": is_boss, "cool": 1.0, "charge": 0.0, "target": "player", "slow": 0.0, "pattern_timer": 3.0, "reward": 8 if is_boss else 2 if kind == "normal" or kind == "runner" else 4}, true)
	enemy_spawn_id += 1
	enemy.spawn_id = enemy_spawn_id
	if kind == "normal" or kind == "small" or not special.is_empty() or is_boss:
		enemy.appearance = 0 if is_boss else _random.randi_range(0, 49) if special.is_empty() else _random.randi_range(0, 3)
		enemy.variant = int(enemy.appearance) % ZombieVisual.SHEETS.size()
		enemy.art_scale = float(data.get("scale", 1.0)) if is_boss else 0.55 if kind == "small" else minf(float(special.get("scale", 1.0)), 1.5)
		enemy.special = not special.is_empty()
		enemy.air = SpecialEnemies.airborne(kind)
		enemy.ability = float(special.get("period", 0.0))
		enemy.ability_cool = enemy.ability
		if kind == "small":
			enemy.hp *= 0.38
			enemy.max_hp = enemy.hp
		if kind == "S10":
			enemy.underground = true
		enemy.row = 0
		enemy.moving = false
		enemy.walk_distance = 0.0
		enemy.hit_until = 0.0
		enemy.attack_until = 0.0
	return enemy


func _spawn_boss(at_stage: int) -> void:
	var old_stage := stage
	stage = at_stage
	var angle := _random.randf_range(0, TAU)
	var spawn_at := _land_spawn(angle, 650.0)
	var kind := "boss%d" % at_stage
	_spawn_enemy(kind, spawn_at, true)
	stage = old_stage
	if sound_on:
		AudioDirector.play_cue("enemy.boss_arrival")
	_show_toast("보스 출현 · %s" % String(Data.BOSSES[at_stage].name))


func _count_live_bosses() -> int:
	var count := 0
	for e in enemies:
		if bool(e.get("boss", false)): count += 1
	return count


func _update_enemies(delta: float) -> void:
	var hq_index := _hq_index()
	var hq_pos := _entry_world_center(structures[hq_index]) if hq_index >= 0 else Vector2.ZERO
	var walls: Array[int] = []
	for index in range(structures.size()):
		if structures[index].kind == "wall" and float(structures[index].hp) > 0.0:
			walls.append(index)
	enemy_update_group = (enemy_update_group + 1) % 4
	var crowd := enemies.size() >= 500
	for i in range(enemies.size() - 1, -1, -1):
		var e: Dictionary = enemies[i]
		var previous_pos: Vector2 = e.pos
		var step := delta + float(e.get("pending_step", 0.0))
		if crowd and not e.get("special", false) and not e.boss and not e.has("strike_remaining") and previous_pos.distance_squared_to(player_pos) > 120.0 * 120.0 and previous_pos.distance_squared_to(hq_pos) > 115.0 * 115.0 and int(e.spawn_id) % 4 != enemy_update_group:
			e.pending_step = step
			continue
		if e.has("pending_step"):
			e.erase("pending_step")
		if (e.has("burn") or e.has("poison")) and _tick_enemy_status(e, i):
			continue
		if float(e.get("knock_left", 0.0)) > 0.0:
			_update_knocked_enemy(e, step)
		if maxf(float(e.get("down_until", 0.0)), float(e.get("frozen_until", 0.0))) > run_seconds:
			e.moving = false
			continue
		var animated := e.has("variant")
		var body_radius := PlayerProjectiles.enemy_radius(e)
		if e.get("special", false) and _update_special(e, i, step):
			continue
		e.cool = maxf(0.0, float(e.cool) - step)
		e.slow = maxf(0.0, float(e.slow) - step)
		if e.has("strike_remaining"):
			_resolve_normal_strike(e, step)
			continue
		if bool(e.boss) and _update_boss_pattern(e, step):
			continue
		if String(e.kind) == "bomber":
			var d_player: float = e.pos.distance_to(player_pos)
			var d_hq: float = e.pos.distance_to(hq_pos)
			if float(e.charge) > 0.0:
				e.charge -= step
				if e.charge <= 0.0:
					_explode_bomber(e)
					_remove_enemy(i)
					continue
			elif minf(d_player, d_hq) < 48.0:
				e.charge = 0.72
				e.target = "player" if d_player < d_hq else "hq"
			continue
		var d_to_player: float = e.pos.distance_squared_to(player_pos)
		var d_to_hq: float = e.pos.distance_squared_to(hq_pos)
		var target_player: bool = treatment_remaining <= 0.0 and d_to_player < d_to_hq and d_to_player < (92.0 * 92.0 if e.kind == "S11" else 440.0 * 440.0)
		e.target = "player" if target_player else "hq"
		var target_pos: Vector2 = player_pos if target_player else hq_pos
		var target_structure := -1 if target_player else hq_index
		if not bool(e.ranged) and not walls.is_empty() and not e.get("air", false) and previous_pos.distance_squared_to(hq_pos) <= 440.0 * 440.0:
			var wall := int(_first_wall_hit(e.pos, target_pos).index)
			if wall < 0:
				wall = _priority_wall(e.pos, walls)
			if wall >= 0:
				target_structure = wall
				e.target = "wall"
				target_pos = _entry_world_center(structures[wall])
		var dist_squared: float = e.pos.distance_squared_to(target_pos)
		if animated and dist_squared > 0.0001:
			e.row = ZombieVisual.facing_row(target_pos - e.pos)
		if bool(e.ranged) and dist_squared < 390.0 * 390.0:
			if float(e.charge) > 0.0:
				e.charge -= step
				if e.charge <= 0.0:
					_launch_enemy_shot(e, e.get("warn_pos", target_pos))
					e.cool = 2.0 if not bool(e.boss) else 1.35
			elif float(e.cool) <= 0.0:
				e.charge = 0.72 if String(e.kind) == "spitter" else 0.92
				e.warn_pos = target_pos
				e.cool = 2.6
		else:
			_update_melee_enemy(e, target_pos, target_structure, body_radius, step)
		if e.target == "player" and e.pos.distance_squared_to(player_pos) < 22.0 * 22.0 and float(e.charge) <= 0.0 and not bool(e.ranged):
			var separated: Vector2 = e.pos + (e.pos - player_pos).normalized() * 6.0
			if e.get("air", false) or jeju_map.walkable(separated, body_radius):
				e.pos = separated
		if animated:
			var traveled := previous_pos.distance_to(e.pos)
			e.moving = traveled > 0.001
			e.walk_distance += traveled
	_play_zombie_ambient()


func _update_special(enemy: Dictionary, index: int, delta: float) -> bool:
	var kind := String(enemy.kind)
	var point: Vector2 = enemy.pos
	var hq := _hq_position()
	var goal := player_pos if point.distance_squared_to(player_pos) < point.distance_squared_to(hq) and treatment_remaining <= 0.0 else hq
	var distance := point.distance_to(goal)
	enemy.ability_cool = maxf(0.0, float(enemy.ability_cool) - delta)
	if kind == "S09":
		enemy.hp = minf(float(enemy.max_hp), float(enemy.hp) + delta * float(enemy.max_hp) * 0.055)
	if kind == "S10" and enemy.get("underground", false):
		if enemy.has("burrow_warning"):
			enemy.burrow_warning = maxf(0.0, float(enemy.burrow_warning) - delta)
			if enemy.burrow_warning <= 0.0:
				enemy.erase("burrow_warning")
				_emerge_enemy(enemy, AMBUSH_RADIUS)
			return true
		if enemy.ability_cool <= 0.0 or distance <= 84.0:
			var radius := PlayerProjectiles.enemy_radius(enemy)
			for offset in [Vector2.ZERO, Vector2(65, 0), Vector2(-65, 0), Vector2(0, 65), Vector2(0, -65),
					Vector2(100, 100), Vector2(-100, 100), Vector2(100, -100), Vector2(-100, -100)]:
				var site: Vector2 = point + offset
				if jeju_map.walkable(site, radius) and _blocking_structure(site, radius) < 0:
					enemy.pos = site
					enemy.burrow_warning = AMBUSH_WARNING
					_play_burrow_sound(site, "enemy.burrow_rumble")
					return true
		enemy.pos = point.move_toward(hq, 112.0 * delta)
		return true
	if kind == "S05" and (distance <= 53.0 or float(enemy.charge) > 0.0):
		if float(enemy.charge) <= 0.0:
			enemy.target = "player" if goal == player_pos else "hq"
		enemy.moving = false
		enemy.charge = float(enemy.charge) + delta
		if enemy.charge >= float(enemy.ability):
			_explode_bomber(enemy)
			_remove_enemy(index)
		return true
	if float(enemy.ability) <= 0.0 or float(enemy.ability_cool) > 0.0:
		return false
	if kind in ["S06", "S15", "S19"] and distance < 280.0:
		if toxin_zones.size() < 24:
			toxin_zones.append({"pos": goal, "life": 3.5, "tick": 0.0, "damage": float(enemy.attack) * 0.32, "slime": kind == "S19"})
	elif kind == "S08":
		for nearby in enemies:
			if nearby.pos.distance_squared_to(point) < 170.0 * 170.0:
				nearby.rage_until = run_seconds + 4.0
	elif kind == "S12" and distance < 160.0:
		var landing := point.move_toward(goal, 112.0)
		if jeju_map.walkable(landing, 24.0) and _blocking_structure(landing, 21.0) < 0:
			enemy.pos = landing
	elif kind == "S16":
		for structure in structures:
			if _is_turret(structure.kind) and _entry_world_center(structure).distance_squared_to(point) < 175.0 * 175.0:
				structure.cool = maxf(float(structure.cool), 2.8)
	enemy.ability_cool = enemy.ability
	return false


func _emerge_enemy(enemy: Dictionary, radius: float) -> void:
	enemy.underground = false
	enemy.emerged_at = run_seconds
	enemy.moving = false
	var point: Vector2 = enemy.pos
	effects.append({"a": point, "b": point, "time": 0.82, "seconds": 0.82, "burrow_debris": radius})
	_play_burrow_sound(point, "enemy.burrow_break")


func _play_burrow_sound(point: Vector2, cue: String) -> void:
	if sound_on and point.distance_squared_to(player_pos) < 560.0 * 560.0:
		AudioDirector.play_cue(cue)


func _update_toxins(delta: float) -> void:
	player_slime = maxf(0.0, player_slime - delta)
	for i in range(toxin_zones.size() - 1, -1, -1):
		var zone := toxin_zones[i]
		zone.life -= delta
		if zone.life <= 0.0:
			toxin_zones.remove_at(i)
			continue
		zone.tick -= delta
		if zone.tick <= 0.0:
			zone.tick = 0.5
			if player_pos.distance_squared_to(zone.pos) <= 52.0 * 52.0:
				if zone.slime:
					player_slime = 0.8
				else:
					_player_take_damage(zone.damage, "독성 지대")


func _first_wall_hit(start: Vector2, end: Vector2, padding := 0.0) -> Dictionary:
	var first := {"index": -1, "fraction": INF}
	for i in range(structures.size()):
		var wall := structures[i]
		if wall.kind != "wall" or float(wall.hp) <= 0.0:
			continue
		var half_extent := Vector2.ONE * (CELL * 0.5 + padding)
		var bounds := Rect2(_entry_world_center(wall) - half_extent, half_extent * 2.0)
		var fraction := _segment_rect_entry(start, end, bounds)
		if fraction < float(first.fraction):
			first = {"index": i, "fraction": fraction}
	return first


func _segment_rect_entry(start: Vector2, end: Vector2, bounds: Rect2) -> float:
	var motion := end - start
	var entry := 0.0
	var exit := 1.0
	for axis in range(2):
		if is_zero_approx(motion[axis]):
			if start[axis] < bounds.position[axis] or start[axis] > bounds.end[axis]:
				return INF
			continue
		var near := (bounds.position[axis] - start[axis]) / motion[axis]
		var far := (bounds.end[axis] - start[axis]) / motion[axis]
		entry = maxf(entry, minf(near, far))
		exit = minf(exit, maxf(near, far))
		if entry > exit:
			return INF
	return entry


func _segment_circle_entry(start: Vector2, end: Vector2, center: Vector2, radius: float) -> float:
	if start.distance_squared_to(center) <= radius * radius:
		return 0.0
	var fraction := Geometry2D.segment_intersects_circle(start, end, center, radius)
	return fraction if fraction >= 0.0 else INF


func _priority_wall(point: Vector2, walls: Array[int]) -> int:
	var nearest := -1
	var best_distance := 150.0 * 150.0
	for index in walls:
		var wall := structures[index]
		if float(wall.hp) <= 0.0:
			continue
		var distance := point.distance_squared_to(_entry_world_center(wall))
		if distance < best_distance:
			best_distance = distance
			nearest = index
	return nearest


func _update_melee_enemy(enemy: Dictionary, target: Vector2, target_structure: int, body_radius: float, delta: float) -> void:
	var toward: Vector2 = target - enemy.pos
	var rage: bool = float(enemy.get("rage_until", -1.0)) > run_seconds or (enemy.get("kind", "") == "S20" and float(enemy.hp) < float(enemy.max_hp) * 0.35)
	if target_structure >= 0:
		var kind := String(structures[target_structure].kind)
		var width := 2 if kind == "hq" or _is_building(kind) else 1
		if _structure_overlap_depth(enemy.pos, target, width, body_radius + 5.0) >= 0.0:
			_strike_structure(enemy, target_structure)
			return
	elif toward.length_squared() <= pow(_enemy_melee_reach(enemy, enemy.get("next_attack_is_bite", false)), 2):
		if float(enemy.cool) <= 0.0:
			if enemy.has("variant"):
				_queue_normal_strike(enemy, toward)
			else:
				_apply_enemy_melee_to_player(enemy)
			enemy.cool = 0.65 if enemy.boss else 1.0
		return
	var speed := float(enemy.speed) * (float(enemy.get("slow_factor", 0.48)) if float(enemy.slow) > 0.0 else 1.0) * (1.55 if rage else 1.0)
	var movement := toward.normalized() * speed * delta
	var radius := 24.0 if enemy.boss else body_radius
	var proposed: Vector2 = enemy.pos + movement
	if enemy.get("air", false):
		enemy.pos = proposed
		return
	if not jeju_map.walkable(proposed, radius):
		var found := false
		var followed := float(enemy.get("terrain_side", 1.0 if int(enemy.spawn_id) % 2 == 0 else -1.0))
		for angle in [0.72 * followed, 1.42 * followed, -0.72 * followed, -1.42 * followed]:
			var alternate: Vector2 = enemy.pos + movement.rotated(angle)
			if jeju_map.walkable(alternate, radius):
				proposed = alternate
				enemy.terrain_side = signf(angle)
				found = true
				break
		if not found:
			return
	var blocker := _blocking_structure(proposed, radius) if proposed.length_squared() < 465.0 * 465.0 else -1
	if blocker < 0:
		enemy.pos = proposed
	else:
		_strike_structure(enemy, blocker)


func _enemy_melee_reach(enemy: Dictionary, bite := false) -> float:
	return (26.0 if bite else 30.0) + maxf(0.0, float(enemy.get("art_scale", 1.0)) - 1.0) * 8.0


func _enemy_attack_power(enemy: Dictionary) -> float:
	var rage: bool = float(enemy.get("rage_until", -1.0)) > run_seconds or (enemy.get("kind", "") == "S20" and float(enemy.hp) < float(enemy.max_hp) * 0.35)
	return float(enemy.attack) * (1.45 if rage else 1.0)


func _apply_enemy_melee_to_player(enemy: Dictionary) -> void:
	var wall := -1 if enemy.get("air", false) else int(_first_wall_hit(enemy.pos, player_pos).index)
	if wall >= 0:
		var multiplier := SpecialEnemies.structure_damage_multiplier("S11") if enemy.get("kind", "") == "S11" else 1.0
		_damage_structure(wall, float(enemy.attack) * multiplier)
	else:
		_player_take_damage(_enemy_attack_power(enemy), "적의 근접 공격")


func _strike_structure(enemy: Dictionary, index: int) -> void:
	if float(enemy.cool) > 0.0:
		return
	var toward: Vector2 = _entry_world_center(structures[index]) - enemy.pos
	if enemy.has("variant"):
		_queue_normal_strike(enemy, toward, structures[index])
	else:
		_damage_structure(index, _enemy_attack_power(enemy) * SpecialEnemies.structure_damage_multiplier(enemy.kind))
	enemy.cool = 1.15


func _queue_normal_strike(enemy: Dictionary, toward: Vector2, target: Variant = null) -> void:
	enemy.strike_remaining = ZombieVisual.IMPACT_TIME
	enemy.strike_target = target
	var bite := false
	if enemy.kind == "normal" and target == null:
		bite = bool(enemy.get("next_attack_is_bite", false))
		enemy.next_attack_is_bite = not bite
	enemy.attack_is_bite = bite
	_animate_zombie_attack(enemy, toward)


func _resolve_normal_strike(enemy: Dictionary, delta: float) -> void:
	enemy.strike_remaining = float(enemy.strike_remaining) - delta
	if float(enemy.strike_remaining) > 0.0001:
		return
	var target: Variant = enemy.strike_target
	enemy.erase("strike_remaining")
	enemy.erase("strike_target")
	if target == null:
		var offset: Vector2 = player_pos - enemy.pos
		if offset.length_squared() <= pow(_enemy_melee_reach(enemy, enemy.get("attack_is_bite", false)), 2) and offset.dot(enemy.attack_direction) >= 0.0:
			_apply_enemy_melee_to_player(enemy)
		return
	for index in range(structures.size()):
		if not is_same(structures[index], target) or float(target.hp) <= 0.0:
			continue
		var kind := String(target.kind)
		var width := 2 if kind == "hq" or _is_building(kind) else 1
		if _structure_overlap_depth(enemy.pos, _entry_world_center(target), width, (24.0 if enemy.boss else PlayerProjectiles.enemy_radius(enemy)) + 5.0) >= 0.0:
			var wall := -1 if enemy.get("air", false) else int(_first_wall_hit(enemy.pos, _entry_world_center(target)).index)
			_damage_structure(wall if wall >= 0 else index, _enemy_attack_power(enemy) * SpecialEnemies.structure_damage_multiplier(enemy.kind))
		return


func _zombie_voice(enemy: Dictionary) -> String:
	var body := int(enemy.get("variant", 0))
	if body == 7:
		return "enemy.elderly"
	return "enemy.high" if body in [1, 3, 5] else "enemy.low"


func _play_zombie_ambient() -> void:
	if not sound_on or run_seconds < zombie_ambient_at:
		return
	var nearby := _nearest_enemy(player_pos, 225.0)
	zombie_ambient_at = run_seconds + (0.35 if nearby < 0 else 1.8)
	if nearby >= 0:
		var pitch := 0.86 + float(int(enemies[nearby].spawn_id) % 7) * 0.045
		AudioDirector.play_cue(_zombie_voice(enemies[nearby]), pitch)


func _animate_zombie_attack(enemy: Dictionary, toward: Vector2) -> void:
	ZombieVisual.start_attack(enemy, toward, run_seconds)
	if sound_on and run_seconds >= zombie_sound_at and player_pos.distance_squared_to(enemy.pos) < 400.0 * 400.0:
		zombie_sound_at = run_seconds + 0.95
		AudioDirector.play_cue(_zombie_voice(enemy), 0.97 + float(int(enemy.spawn_id) % 7) * 0.035)


func _update_boss_pattern(e: Dictionary, delta: float) -> bool:
	var milestone := int(String(e.kind).trim_prefix("boss"))
	if e.has("pattern_pos"):
		e.pattern_windup -= delta
		if e.pattern_windup > 0.0:
			e.moving = false
			return true
		var point: Vector2 = e.pattern_pos
		e.erase("pattern_pos")
		_animate_zombie_attack(e, point - e.pos)
		match milestone:
			20:
				for ally in enemies:
					if not ally.boss and ally.pos.distance_squared_to(point) < 205.0 * 205.0:
						ally.rage_until = run_seconds + 4.0
			60, 80:
				_enemy_ground_impact(e, point, _boss_pattern_radius(milestone), milestone == 80)
			100:
				for n in range(3):
					if enemies.size() >= MAX_ENEMIES:
						break
					var spawn_at := jeju_map.nearest_land(point + Vector2.from_angle(n * TAU / 3.0) * 90.0, ZombieVisual.RADIUS)
					if jeju_map.walkable(spawn_at, ZombieVisual.RADIUS) and _blocking_structure(spawn_at, ZombieVisual.RADIUS) < 0:
						_spawn_enemy("normal", spawn_at, false)
		return false
	e.pattern_timer -= delta
	if e.pattern_timer > 0.0:
		return false
	e.pattern_timer = 5.0
	match milestone:
		40:
			e.guard_until = run_seconds + 1.5
			return false
		60:
			if treatment_remaining > 0.0 or e.pos.distance_squared_to(player_pos) > 360.0 * 360.0:
				return false
			e.pattern_pos = player_pos
		80:
			var target := _nearest_structure(e.pos, 560.0, false)
			if target < 0:
				return false
			var point := _entry_world_center(structures[target])
			var wall := int(_first_wall_hit(e.pos, point).index)
			e.pattern_pos = _entry_world_center(structures[wall]) if wall >= 0 else point
		_:
			e.pattern_pos = e.pos
	e.pattern_windup = 0.9
	e.moving = false
	return true


func _boss_pattern_radius(milestone: int) -> float:
	match milestone:
		20: return 205.0
		60: return 88.0
		80: return 74.0
		_: return 95.0


func _enemy_ground_impact(enemy: Dictionary, point: Vector2, radius: float, hits_structures: bool) -> void:
	var damage := float(enemy.attack)
	if treatment_remaining <= 0.0 and point.distance_squared_to(player_pos) <= radius * radius and int(_first_wall_hit(point, player_pos).index) < 0:
		_player_take_damage(damage, String(enemy.name))
	if hits_structures:
		var targets: Array[int] = []
		for index in range(structures.size() - 1, -1, -1):
			var center := _entry_world_center(structures[index])
			if float(structures[index].hp) > 0.0 and point.distance_squared_to(center) <= radius * radius:
				var wall := int(_first_wall_hit(point, center).index)
				if wall == -1 or wall == index:
					targets.append(index)
		for index in targets:
			_damage_structure(index, damage * (2.0 if enemy.boss else 1.0))
	effects.append({"a": point, "b": point + Vector2(radius, 0), "time": 0.28, "color": enemy.color, "blast": true})


func _launch_enemy_shot(enemy: Dictionary, target: Vector2) -> void:
	if enemy.has("variant"):
		_animate_zombie_attack(enemy, target - Vector2(enemy.pos))
	var ptype := "acid" if String(enemy.kind) == "spitter" else "rock"
	var direction: Vector2 = (target - enemy.pos).normalized()
	enemy_shots.append({"pos": enemy.pos, "velocity": direction * (270.0 if ptype == "rock" else 235.0), "life": 2.2, "damage": float(enemy.attack), "type": ptype, "target": target, "color": PALETTE.red})


func _explode_bomber(enemy: Dictionary) -> void:
	var target_player := String(enemy.get("target", "player")) == "player"
	var center: Vector2 = player_pos if target_player else _hq_position()
	var dist: float = enemy.pos.distance_to(center)
	var protected := int(_first_wall_hit(enemy.pos, center).index) >= 0
	# Evaluate cover against the pre-blast walls, so a wall destroyed by this
	# explosion still shields everything behind it from this same explosion.
	var blast_targets: Array[int] = []
	for i in range(structures.size() - 1, -1, -1):
		var structure_center := _entry_world_center(structures[i])
		if structure_center.distance_to(enemy.pos) <= 105.0:
			var wall := int(_first_wall_hit(enemy.pos, structure_center).index)
			if wall < 0 or wall == i:
				blast_targets.append(i)
	if dist < 120.0 and not protected:
		if target_player: _player_take_damage(float(enemy.attack) * 1.8, "자폭 폭발")
		else: _damage_hq(float(enemy.attack) * 2.4)
	for i in blast_targets:
		_damage_structure(i, float(enemy.attack) * 0.8)
	effects.append({"a": enemy.pos, "b": enemy.pos + Vector2(95, 0), "time": 0.28, "color": PALETTE.red, "blast": true})
	_show_toast("자폭체 폭발 · 경고 원에서 벗어나세요.")


func _apply_status(enemy: Dictionary, key: String, seconds: float, damage: float) -> void:
	var effect: Dictionary = enemy.get(key, {})
	var started := float(effect.get("start", run_seconds)) if float(effect.get("until", 0.0)) > run_seconds else run_seconds
	enemy[key] = {"start": started, "until": run_seconds + seconds,
		"tick": float(effect.get("tick", run_seconds + 0.45)), "damage": damage}
	_mark_csv_trigger(key)


func _tick_enemy_status(enemy: Dictionary, index: int) -> bool:
	for element in ["burn", "poison"]:
		if not enemy.has(element):
			continue
		var effect: Dictionary = enemy[element]
		if float(effect.until) <= run_seconds:
			enemy.erase(element)
		elif float(effect.tick) <= run_seconds:
			effect.tick = run_seconds + 0.45
			var spawn_id: int = enemy.spawn_id
			var before := float(enemy.hp)
			var point: Vector2 = enemy.pos
			_damage_enemy(index, float(effect.damage), "status")
			var lost := before - maxf(0.0, float(enemy.hp)) if int(enemy.spawn_id) == spawn_id else before
			if lost > 0.0 and effects.size() < 80 and _zombie_on_screen(_world_to_screen(point)):
				effects.append({"a": point, "b": point, "time": 0.46, "seconds": 0.46,
					"dot_text": str(maxi(1, roundi(lost))), "color": Color("#ff665c") if element == "burn" else Color("#9ee05b")})
			if float(enemy.hp) <= 0.0 or int(enemy.spawn_id) != spawn_id:
				return true
	return false


func _status_damage_bonus(enemy: Dictionary) -> float:
	var bonus := 0.0
	var count := 0
	for status in ["burn", "poison", "shock", "freeze"]:
		if enemy.has(status) and float(enemy[status].until) > run_seconds:
			bonus += _csv_bonus(status + "_target")
			count += 1
	if count > 0: bonus += _csv_bonus("status_target")
	if count > 1: bonus += _csv_bonus("multistatus_target")
	return bonus


func _apply_weapon_status(enemy: Dictionary, damage: float) -> void:
	for key in ["burn", "poison", "shock", "freeze", "explosion"]:
		var percent := _csv_bonus(key + "_chance")
		if percent <= 0.0 or _random.randf() >= minf(0.8, percent / 100.0):
			continue
		if key == "explosion":
			if pending_skill_blasts.size() < 20:
				pending_skill_blasts.append({"pos": enemy.pos, "damage": damage * 0.3 * _csv_factor("blast_damage")})
			_mark_csv_trigger(key)
		elif key == "freeze":
			_apply_cold(enemy, true)
		elif key == "shock":
			_apply_status(enemy, key, 2.0, 0.0)
			enemy.hp = float(enemy.hp) - damage * 0.25 * _csv_factor("shock_damage")
		else:
			_apply_status(enemy, key, 2.5 * _csv_factor(key + "_time"), damage * 0.13 * _csv_factor(key + "_damage"))


func _apply_cold(enemy: Dictionary, frozen: bool) -> void:
	var duration := 2.2 * _csv_factor("freeze_time")
	enemy.slow = maxf(duration, float(enemy.slow))
	enemy.slow_factor = maxf(0.1, 0.48 - _csv_bonus("freeze_strength") / 100.0)
	_apply_status(enemy, "freeze", duration, 0.0)
	if frozen:
		var hold := minf(duration, 0.48 if enemy.boss else 1.35)
		enemy.frozen_until = maxf(float(enemy.get("frozen_until", 0.0)), run_seconds + hold)
		_interrupt_enemy_attack(enemy)


func _weapon_elements() -> int:
	var mask := 0
	for element in Elements.WEAPON_KEYS:
		if _csv_bonus(element + "_chance") > 0.0:
			mask |= int(Elements.WEAPON_KEYS[element])
	return mask


func _resolve_skill_blasts() -> void:
	while not pending_skill_blasts.is_empty():
		var blast: Dictionary = pending_skill_blasts.pop_back()
		_explode_damage_center(blast.pos, 64.0 * _csv_factor("blast_radius"), blast.damage, "augment_blast")
		if effects.size() < 80:
			effects.append({"a": blast.pos, "b": blast.pos, "time": 0.18, "color": Color("#a1b86b"), "blast": true})


func _damage_enemy(index: int, amount: float, source: String, origin: Variant = null) -> void:
	if index < 0 or index >= enemies.size(): return
	var enemy: Dictionary = enemies[index]
	if enemy.get("underground", false):
		return
	if enemy.kind == "S02":
		amount *= 0.58
	if source in ["player", "chainsaw", "drone"]:
		var bonus := _status_damage_bonus(enemy)
		if enemy.get("special", false): bonus += _csv_bonus("combat_drone_special" if source == "drone" else "special_damage")
		if enemy.boss: bonus += _csv_bonus("combat_drone_boss" if source == "drone" else "boss_damage")
		if enemy.get("air", false): bonus += _csv_bonus("air_damage")
		if enemy.kind == "S02": bonus += _csv_bonus("armored_damage")
		if float(enemy.hp) < float(enemy.max_hp) * 0.35: bonus += _csv_bonus("low_damage")
		if source != "drone":
			bonus += _csv_bonus("base_damage" if player_pos.distance_squared_to(_hq_position()) <= 264.0 * 264.0 else "outside_damage")
			if run_seconds - last_dash_at < 5.0: bonus += _csv_bonus("after_dash_damage")
			if run_seconds - last_reload_at < 5.0: bonus += _csv_bonus("after_reload")
			if player_motion.length_squared() > 36.0: bonus += _csv_bonus("on_move_damage")
			if _csv_bonus("crit") > 0.0 and _random.randf() < minf(0.8, _csv_bonus("crit") / 100.0):
				amount *= 1.5 + _csv_bonus("crit_damage") / 100.0
				last_crit_at = run_seconds
		amount *= 1.0 + bonus / 100.0
		if source != "drone":
			_apply_weapon_status(enemy, amount)
	if bool(enemy.get("boss", false)) and float(enemy.get("guard_until", 0.0)) > run_seconds:
		amount *= 0.4
	enemy.hp = float(enemy.hp) - amount
	var impact_origin: Vector2 = origin if origin is Vector2 else player_pos
	var hit_style := _zombie_hit_style(source)
	if amount > 0.0 and source != "status" and enemy.has("variant"):
		enemy.hit_style = hit_style
		enemy.hit_direction = impact_origin.direction_to(enemy.pos)
	if amount > 0.0 and source != "status" and (shake_on or source == "chainsaw" or source == "shield") and effects.size() < 80 and _zombie_on_screen(_world_to_screen(enemy.pos)):
		var point: Vector2 = enemy.pos
		var angle := impact_origin.angle_to_point(point)
		effects.append({"a": point, "b": point, "time": HIT_SPARK_TIME, "hit_angle": angle,
			"color": ZombieVisual.NormalVisual.IMPACTS[hit_style]})
	if amount > 0.0 and source not in ["chainsaw", "status", "shield"] and sound_on and run_seconds >= impact_sound_at and player_pos.distance_squared_to(enemy.pos) < 440.0 * 440.0:
		impact_sound_at = run_seconds + 0.10
		AudioDirector.play_cue("enemy.impact", 1.18)
	if float(enemy.hp) <= 0.0:
		last_kill_at = run_seconds
		_mark_csv_trigger("kill")
		if source != "augment_blast" and _csv_bonus("kill_blast") > 0.0 and pending_skill_blasts.size() < 20:
			pending_skill_blasts.append({"pos": enemy.pos, "damage": amount * _csv_bonus("kill_blast") / 100.0})
		var reward_scale := _csv_factor("money") + _csv_bonus("boss_money" if enemy.boss else "special_money" if enemy.get("special", false) else "") / 100.0
		var reward := int(round(float(enemy.reward) * player_mod_salvage * reward_scale))
		if treatment_remaining <= 0.0:
			if _csv_bonus("kill_heal") > 0.0 and _random.randf() < minf(0.8, _csv_bonus("kill_heal") / 100.0):
				player_hp = minf(_effective_player_max_hp(), player_hp + _effective_player_max_hp() * 0.04 * _csv_factor("heal"))
			if source == "chainsaw":
				saw_repair_kills += 1
				if saw_repair_kills >= Skills.SAW_REPAIR_KILLS:
					saw_repair_kills = 0
					_emergency_repair()
				player_hp = minf(_effective_player_max_hp(), player_hp + _csv_bonus("saw_kill_heal") / 100.0 * amount)
		money += reward
		kills += 1
		player_xp += (16.0 if bool(enemy.boss) else 4.0 if enemy.kind != "normal" else 2.6) * player_mod_xp * (_csv_factor("xp") + _csv_bonus("boss_xp" if enemy.boss else "special_xp" if enemy.get("special", false) else "") / 100.0) * (1.0 + float(research_bonus) * 0.05)
		if bool(enemy.boss):
			boss_kills += 1
			medals += 12
			augment_queue += 2
			if String(enemy.kind) == "boss100":
				final_boss_defeated = true
		elif enemy.get("special", false):
			medals += 1
			augment_queue += 1
		var split: bool = enemy.kind == "S18"
		var split_at: Vector2 = enemy.pos
		_remove_enemy(index)
		if split:
			for piece in range(3):
				if enemies.size() >= MAX_ENEMIES: break
				_spawn_enemy("small", split_at + Vector2.from_angle(piece * TAU / 3.0) * 25.0, false)
		_check_level_up()
	elif amount > 0.0 and source != "status" and enemy.has("variant"):
		enemy.hit_until = run_seconds + ZombieVisual.HIT_TIME


func _emergency_repair() -> void:
	var closest := 330.0 * 330.0
	var damaged: Dictionary = {}
	for facility in structures:
		if facility.kind == "hq" or float(facility.hp) <= 0.0 or float(facility.hp) >= float(facility.max_hp):
			continue
		var distance := player_pos.distance_squared_to(_entry_world_center(facility))
		if distance < closest:
			closest = distance
			damaged = facility
	if not damaged.is_empty():
		damaged.hp = minf(float(damaged.max_hp), float(damaged.hp) + float(damaged.max_hp) * 0.06)


func _zombie_hit_style(source: String) -> String:
	match source:
		"player":
			return "shotgun" if Data.CHARACTERS[player_index].id == "tae" else "rifle"
		"chainsaw":
			return "saw"
		"shield":
			return "shotgun"
		"blast", "augment_blast", "rocket":
			return "explosive"
		"electric", "chain":
			return "electric"
		"flame":
			return "fire"
		"freeze":
			return "cold"
		"drone":
			return "drone"
		"heavy":
			return "shotgun"
	return "rifle"


func _remove_enemy(index: int) -> void:
	if index < 0 or index >= enemies.size(): return
	var dead: Dictionary = enemies[index]
	enemies.remove_at(index)
	if float(dead.get("frozen_until", 0.0)) > run_seconds:
		if effects.size() < 80 and _zombie_on_screen(_world_to_screen(dead.pos)):
			effects.append({"a": dead.pos, "b": dead.pos, "time": 0.42, "seconds": 0.42, "ice_shatter": true})
	elif dead.has("variant") and not dead.get("underground", false) and _zombie_on_screen(_world_to_screen(dead.pos)) and zombie_corpses.size() < MAX_CORPSES:
		var corpse := {"pos": dead.pos, "variant": dead.variant, "row": dead.row, "start": run_seconds, "kind": dead.kind, "scale": dead.art_scale}
		if dead.kind == "normal":
			corpse.appearance = dead.appearance
		zombie_corpses.append(corpse)
	if enemy_pool.size() < MAX_ENEMIES: enemy_pool.append(dead)


func _update_zombie_corpses(now: float) -> void:
	# Corpses are inserted chronologically and carry no gameplay state.
	while not zombie_corpses.is_empty() and now - float(zombie_corpses.front().start) >= ZombieVisual.DEATH_TIME:
		zombie_corpses.pop_front()


func _zombie_on_screen(point: Vector2, padding := 48.0) -> bool:
	var visible_size := size / _view_zoom()
	return Rect2((size - visible_size) * 0.5, visible_size).grow(padding).has_point(point)


func _explode_damage_center(center: Vector2, radius: float, damage: float, source := "blast") -> void:
	for i in range(enemies.size() - 1, -1, -1):
		if enemies[i].pos.distance_to(center) <= radius:
			_damage_enemy(i, damage, source, center)


func _install_repair_drone() -> void:
	if repair_drone_level > 0:
		_show_toast("수리 드론이 이미 배치되어 있습니다.")
		return
	var price := _effective_cost(int(Data.REPAIR_DRONE.cost))
	if money < price:
		_show_toast("수리 드론 배치에 보급품 %d개가 필요합니다." % price)
		return
	_cancel_build()
	money -= price
	repair_drone_level = 1
	repair_drone_pos = _hq_position()
	repair_drone_cooldown = 0.0
	_show_toast("수리 드론 배치 · 기지 자동 순찰")
	if build_open: _refresh_build_panel()
	_save_all()


func _repair_drone_upgrade_cost() -> int:
	return roundi((30 + repair_drone_level * 24) * 1.30)


func _upgrade_repair_drone() -> void:
	if repair_drone_level <= 0 or repair_drone_level >= 11:
		return
	var price := _repair_drone_upgrade_cost()
	if money < price:
		_show_toast("수리 드론 강화에 보급품 %d개가 필요합니다." % price)
		return
	money -= price
	repair_drone_level += 1
	_show_toast("수리 드론 레벨 %d 강화" % repair_drone_level)
	if build_open: _refresh_build_panel()
	_save_all()


func _update_repair_drone(delta: float) -> void:
	if repair_drone_level <= 0:
		return
	repair_drone_cooldown = maxf(0.0, repair_drone_cooldown - delta)
	var target := _hq_index()
	if target < 0 or float(structures[target].hp) <= 0.0 or float(structures[target].hp) >= float(structures[target].max_hp):
		target = _nearest_structure(repair_drone_pos, INF, true)
	var destination := _hq_position() + Vector2.from_angle(run_seconds * 0.6) * 105.0
	if target >= 0:
		destination = _entry_world_center(structures[target])
	repair_drone_pos = repair_drone_pos.move_toward(destination, 150.0 * delta * _csv_factor("drone_move"))
	if target >= 0 and repair_drone_cooldown <= 0.0 and repair_drone_pos.distance_to(destination) <= 29.0:
		var facility := structures[target]
		var key := "wall_repair" if facility.kind == "wall" else "hq_repair" if facility.kind == "hq" else "facility_repair"
		var bonus := _csv_bonus(key) + (_csv_bonus("clinic_repair") if facility.kind == "clinic" else 0.0)
		if float(facility.hp) < float(facility.max_hp) * 0.35: bonus += _csv_bonus("drone_low")
		facility.hp = minf(float(facility.max_hp), float(facility.hp) + 12.0 * repair_drone_level * (_csv_factor("drone_repair") + bonus / 100.0))
		_mark_csv_trigger("repair")
		_mark_csv_trigger(String(facility.kind))
		repair_drone_cooldown = 1.0 / _csv_factor("drone_repair_rate")
		if effects.size() < 80:
			effects.append({"a": repair_drone_pos + Vector2(0, -30), "b": destination, "time": 0.22, "color": PALETTE.green})


func _update_turrets(delta: float) -> void:
	for index in range(structures.size()):
		var s: Dictionary = structures[index]
		if float(s.hp) <= 0.0: continue
		var kind := String(s.kind)
		if not _is_turret(kind) and kind != "outpost" and kind != "hq": continue
		s.cool = maxf(0.0, float(s.get("cool", 0.0)) - delta)
		var pos := _entry_world_center(s)
		if kind == "hq": continue
		var def := _build_definition(kind)
		var turret_range := float(def.get("range", 330.0)) * player_mod_range * (_csv_factor("turret_range") + _csv_bonus(kind + "_range") / 100.0)
		if kind == "outpost": turret_range = 390.0
		if float(s.cool) > 0.0: continue
		var target_index := _nearest_enemy(pos, turret_range, -1, kind == "aa")
		if target_index < 0: continue
		var target_pos: Vector2 = enemies[target_index].pos
		var fire_rate := float(def.get("rate", 1.0)) / (player_mod_turret_rate * (_csv_factor("turret_rate") + _csv_bonus(kind + "_rate") / 100.0))
		s.cool = maxf(0.12, fire_rate / (1.0 + float(s.level - 1) * 0.12))
		var damage := float(def.get("damage", 20.0)) * 0.5 * (1.0 + float(s.level - 1) * 0.408) * player_mod_turret_damage * (_csv_factor("turret_damage") + _csv_bonus(kind + "_damage") / 100.0)
		if kind == "outpost": damage = 9.0 * player_mod_turret_damage
		elif Data.CHARACTERS[player_index].id == "yujin": damage *= Skills.YUJIN_TURRET_DAMAGE
		if pos.distance_squared_to(_hq_position()) <= 220.0 * 220.0:
			damage *= _csv_factor("hq_turret")
		if _csv_bonus("turret_crit") > 0.0 and _random.randf() < minf(0.8, _csv_bonus("turret_crit") / 100.0):
			damage *= 1.5 + _csv_bonus("turret_crit_damage") / 100.0
		_mark_csv_trigger("turret")
		_mark_csv_trigger(kind)
		if kind == "rocket":
			_explode_damage_center(target_pos, 82.0 * (_csv_factor("blast_radius") + _csv_bonus("rocket_radius") / 100.0), damage * 0.72 * _csv_factor("blast_damage"), "rocket")
			if effects.size() < 80: effects.append({"a": pos, "b": target_pos, "time": 0.22, "color": PALETTE.red, "blast": true})
		elif kind == "electric":
			var struck_ids: Dictionary = {}
			var arc_start := pos
			for jump in range(2 + mini(5, int(_csv_bonus("electric_targets")))):
				if target_index < 0:
					break
				var target := enemies[target_index]
				var struck: Vector2 = target.pos
				struck_ids[target.spawn_id] = true
				_apply_status(target, "shock", 2.0, 0.0)
				_damage_enemy(target_index, damage * pow(0.55, jump), kind if jump == 0 else "chain", arc_start)
				if effects.size() < 80:
					effects.append({"a": arc_start, "b": struck, "time": 0.16, "element_mask": Elements.SHOCK})
				arc_start = struck
				target_index = _nearest_enemy(struck, 94.0 * _csv_factor("electric_range"), -1, false, struck_ids)
		elif kind == "flame":
			var direction := pos.direction_to(target_pos)
			var threshold := cos(deg_to_rad(minf(78.0, 28.0 * _csv_factor("flame_angle"))))
			for i in range(enemies.size() - 1, -1, -1):
				var offset: Vector2 = enemies[i].pos - pos
				if offset.length_squared() <= turret_range * turret_range and offset.normalized().dot(direction) >= threshold:
					if enemies[i].get("underground", false):
						continue
					_apply_status(enemies[i], "burn", 2.0 * _csv_factor("burn_time"), damage * 0.15 * _csv_factor("burn_damage"))
					_damage_enemy(i, damage, kind, pos)
			if effects.size() < 80: effects.append({"a": pos, "b": target_pos, "time": 0.15, "element_mask": Elements.FIRE, "color": Color("#ef9154"), "fire_cone": true})
		else:
			if kind == "freeze":
				var freeze_chance := minf(0.8, 0.08 + _csv_bonus("freeze_chance") / 100.0)
				_apply_cold(enemies[target_index], _random.randf() < freeze_chance)
			_damage_enemy(target_index, damage, kind, pos)
			if effects.size() < 80:
				effects.append({"a": pos, "b": target_pos, "time": 0.13,
					"color": def.get("color", PALETTE.gold), "element_mask": Elements.ICE if kind == "freeze" else 0})


func _nearest_enemy(pos: Vector2, range: float, skip := -1, air_only := false, exclude: Dictionary = {}) -> int:
	var nearest := -1
	var nearest_dist := range
	for i in range(enemies.size()):
		if i == skip or exclude.has(enemies[i].spawn_id) or enemies[i].hp <= 0.0 or enemies[i].get("underground", false) or (air_only and not enemies[i].get("air", false)): continue
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
		var start: Vector2 = shot.pos
		var end: Vector2 = start + shot.velocity * clampf(float(shot.life), 0.0, delta)
		shot.life -= delta
		var wall := _first_wall_hit(start, end, ENEMY_SHOT_RADIUS)
		var player_hit := _segment_circle_entry(start, end, player_pos, PLAYER_RADIUS + ENEMY_SHOT_RADIUS)
		var hq_hit := _segment_circle_entry(start, end, _hq_position(), 28.0) if _hq_index() >= 0 else INF
		var impact := minf(float(wall.fraction), minf(player_hit, hq_hit))
		if impact != INF:
			shot.pos = start.lerp(end, impact)
			if float(wall.fraction) == impact:
				_damage_structure(int(wall.index), float(shot.damage))
			elif player_hit == impact:
				_player_take_damage(float(shot.damage), "원거리 투사체")
			else:
				_damage_hq(float(shot.damage))
		else:
			shot.pos = end
		if impact != INF or float(shot.life) <= 0.0:
			if effects.size() < 80:
				var direction: Vector2 = shot.velocity.normalized()
				effects.append({"a": shot.pos, "b": shot.pos - direction * 18.0, "time": 0.14, "color": PALETTE.red})
			enemy_shots.remove_at(i)


func _update_effects(delta: float) -> void:
	for i in range(effects.size() - 1, -1, -1):
		effects[i].time = float(effects[i].time) - delta
		if float(effects[i].time) <= 0.0: effects.remove_at(i)


func _living_facility(kind: String) -> int:
	for index in range(structures.size()):
		if structures[index].kind == kind and float(structures[index].hp) > 0.0:
			return index
	return -1


func _update_facilities(delta: float) -> void:
	clinic_shield = maxf(0.0, clinic_shield - delta)
	var clinic := _living_facility("clinic")
	if player_hp > 0.0 and treatment_remaining <= 0.0 and _csv_bonus("regen") > 0.0:
		player_hp = minf(_effective_player_max_hp(), player_hp + delta * _csv_bonus("regen") * _effective_player_max_hp() / 100.0)
	if treatment_remaining > 0.0:
		if clinic < 0:
			_finish_run(false)
			return
		treatment_remaining = maxf(0.0, treatment_remaining - delta)
		if treatment_remaining == 0.0:
			player_pos = _hq_position() + Vector2(0, CELL)
			player_hp = _effective_player_max_hp()
			clinic_shield = _csv_bonus("clinic_invulnerability")
			_mark_csv_trigger("clinic")
			_show_toast("치료 완료 · 지휘본부 복귀")
	elif clinic >= 0 and player_hp > 0.0 and player_pos.distance_to(_entry_world_center(structures[clinic])) <= 245.0:
		player_hp = minf(_effective_player_max_hp(), player_hp + delta * 2.8 * _csv_factor("heal") * (_csv_factor("low_heal") if player_hp < _effective_player_max_hp() * 0.35 else 1.0))
	if expedition_remaining > 0.0:
		var depot := _living_facility("supply")
		if depot < 0:
			expedition_remaining = 0.0
			_show_toast("파견 시설 파괴 · 파견 중단")
		else:
			expedition_remaining = maxf(0.0, expedition_remaining - delta)
			if expedition_remaining == 0.0:
				var chance := clampf(0.88 - difficulty_index * 0.09 + mercenary_level * 0.025 + _csv_bonus("expedition_chance") / 100.0, 0.10, 0.98)
				var reward := roundi(35.0 * (1.0 + difficulty_index * 0.33 + mercenary_level * 0.12) * (1.0 + float(structures[depot].level - 1) * 0.08) * _csv_factor("expedition_reward"))
				_mark_csv_trigger("expedition")
				if _random.randf() < chance:
					money += reward
					_show_toast("용병 파견 성공 · 보급품 +%d" % reward)
				else:
					_show_toast("용병 파견 실패")
	if _living_facility("research") >= 0: research_bonus = 1
	if _living_facility("workshop") >= 0: player_mod_turret_damage = maxf(player_mod_turret_damage, 1.12)


func _start_expedition() -> void:
	var depot := _living_facility("supply")
	if depot < 0 or expedition_remaining > 0.0:
		return
	var reduction := minf(0.8, (int(structures[depot].level) - 1) * 0.05 + mercenary_level * 0.035 + _csv_bonus("expedition_time") / 100.0)
	expedition_remaining = (32.0 + difficulty_index * 12.0) * (1.0 - reduction)
	_show_toast("용병 파견 시작 · %d초" % ceili(expedition_remaining))
	_save_all()


func _upgrade_mercenary() -> void:
	var cost := roundi((30 + mercenary_level * 15) * _csv_reduction("mercenary_cost"))
	if _living_facility("supply") < 0 or mercenary_level >= 10 or money < cost:
		return
	money -= cost
	mercenary_level += 1
	_open_inspector()
	_save_all()


func _update_progress(_delta: float) -> void:
	if screen == "result":
		return
	var hq := _hq_index()
	if hq < 0 or float(structures[hq].hp) <= 0.0:
		_finish_run(false)
		return
	if player_hp <= 0.0 and treatment_remaining <= 0.0:
		var clinic := _living_facility("clinic")
		if clinic < 0:
			_finish_run(false)
			return
		var reduction := minf(0.8, (int(structures[clinic].level) - 1) * 0.08 + _csv_bonus("clinic_time") / 100.0)
		treatment_remaining = 600.0 * (1.0 - reduction)
		player_hp = 0.0
		player_motion = Vector2.ZERO
		manual_trigger = false
		_show_toast("의료소에서 치료 중 · 기지 관리는 계속할 수 있습니다.")
	_check_level_up()


func _check_level_up() -> void:
	while augments_taken < MAX_XP_CHOICES:
		var required := 16.0 + player_level * 9.0 + pow(float(player_level), 1.35) * 2.2
		if player_xp < required:
			break
		player_xp -= required
		player_level += 1
		augments_taken += 1
		augment_queue += 1
	if augment_queue > 0 and screen == "play":
		augment_reroll_used = 0
		_offer_augments()


func _csv_bonus(key: String) -> float:
	var amount := float(csv_passive.get(key, 0.0))
	if not csv_conditional.has(key):
		return amount
	var timed: Dictionary = csv_conditional[key]
	for trigger in timed:
		if float(csv_trigger_until.get(trigger, -1.0)) > run_seconds:
			amount += float(timed[trigger])
	return amount


func _recent_combat_bonus(crit_key: String, kill_key: String) -> float:
	return (_csv_bonus(crit_key) if run_seconds - last_crit_at < 5.0 else 0.0) + (_csv_bonus(kill_key) if run_seconds - last_kill_at < 5.0 else 0.0)


func _effective_player_max_hp() -> float:
	var temporary := _csv_bonus("hp") - float(csv_passive.get("hp", 0.0))
	return player_max_hp + float(Data.CHARACTERS[player_index].hp) * temporary / 100.0


func _csv_factor(key: String) -> float:
	return 1.0 + _csv_bonus(key) / 100.0


func _csv_reduction(key: String) -> float:
	return 1.0 - clampf(_csv_bonus(key) / 100.0, 0.0, 0.80)


func _mark_csv_trigger(trigger: String) -> void:
	if not csv_conditional.is_empty():
		csv_trigger_until[trigger] = run_seconds + 5.0


func _rebuild_csv_stats() -> void:
	csv_passive.clear()
	csv_conditional.clear()
	for card in acquired_augments.values():
		var key := String(card.get("key", ""))
		if key.is_empty():
			continue
		var amount := float(card.amount) * int(card.count)
		var trigger := String(card.trigger)
		if trigger.is_empty():
			csv_passive[key] = float(csv_passive.get(key, 0.0)) + amount
		else:
			var timed: Dictionary = csv_conditional.get(key, {})
			timed[trigger] = float(timed.get(trigger, 0.0)) + amount
			csv_conditional[key] = timed


func _eligible_augments() -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	var hero: Dictionary = Data.CHARACTERS[player_index]
	var built: Dictionary = {}
	for structure in structures:
		if float(structure.hp) > 0.0:
			built[structure.kind] = true
	var equipment := {"기본 포탑": "basic", "중기관총": "heavy", "로켓": "rocket", "전기 포탑": "electric", "화염 포탑": "flame", "냉기": "freeze", "냉각 포탑": "freeze",
		"대공": "aa", "의료": "clinic", "파견": "supply"}
	for card in AugmentCatalog.cards():
		if card.key == "" or (card.hero != "" and card.hero != hero.id):
			continue
		if int(acquired_augments.get(card.id, {}).get("count", 0)) >= int(card.limit):
			continue
		if int(acquired_augments.get(card.requires, {}).get("count", 0)) < int(card.required_count):
			continue
		if int(hero.magazine) == 0 and card.family == "탄약":
			continue
		if equipment.has(card.family) and not built.has(equipment[card.family]):
			continue
		if card.family == "수리 드론" and repair_drone_level == 0:
			continue
		available.append(card)
	return available


func _draw_augment_offer() -> void:
	var available := _eligible_augments()
	augment_options.clear()
	for i in range(mini(3, available.size())):
		var ticket := _random.randf()
		var best := _random.randi_range(0, available.size() - 1)
		# Rarity is defined by the catalog. Sample several candidates for a rarity bias.
		for attempt in range(3):
			var challenger := _random.randi_range(0, available.size() - 1)
			if ticket < 0.93 and int(available[challenger].stars) < int(available[best].stars):
				best = challenger
		augment_options.append(available.pop_at(best))


func _offer_augments() -> void:
	_draw_augment_offer()
	if not augment_options.is_empty():
		_show_screen("augment")


func _rebuild_augment_cards() -> void:
	if augment_screen == null: return
	var row := augment_screen.find_child("AugmentCards", true, false) as HBoxContainer
	if row == null: return
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	for card in augment_options:
		var display := card.duplicate()
		display.description = _augment_effect_text(card)
		row.add_child(OpsUI.augment_card(display, _choose_augment.bind(card), 189.0, 164.0, true))
	augment_reroll_button.disabled = augment_reroll_used >= 2
	augment_reroll_button.text = "무료 리롤 %d회 남음" % (2 - augment_reroll_used)


func _reroll_augments() -> void:
	if augment_reroll_used >= 2: return
	augment_reroll_used += 1
	_draw_augment_offer()
	_rebuild_augment_cards()


func _choose_csv_augment(card: Dictionary) -> void:
	var previous: Dictionary = acquired_augments.get(card.id, {})
	if not _eligible_augments().has(card):
		return
	var entry := card.duplicate()
	entry.count = int(previous.get("count", 0)) + 1
	entry.description = AugmentCatalog.description(card)
	acquired_augments[card.id] = entry
	_rebuild_csv_stats()
	var hp_keys := {"hq": "hq_hp", "wall": "wall_hp", "clinic": "clinic_hp"}
	if card.key == "hp" and String(card.trigger).is_empty():
		var increase := float(Data.CHARACTERS[player_index].hp) * float(card.amount) / 100.0
		player_max_hp += increase
		if treatment_remaining <= 0.0: player_hp += increase
	elif card.key in ["hq_hp", "wall_hp", "turret_hp", "facility_hp", "clinic_hp"]:
		for item in structures:
			var kind: String = item.kind
			if float(item.hp) <= 0.0:
				continue
			var matches: bool = card.key == hp_keys.get(kind, "") or (card.key == "turret_hp" and _is_turret(kind)) or (card.key == "facility_hp" and _is_building(kind))
			if matches:
				var increase := float(item.max_hp) * float(card.amount) / maxf(100.0, 100.0 + _csv_bonus(card.key) - float(card.amount))
				item.max_hp += increase
				item.hp += increase
	augment_queue = maxi(0, augment_queue - 1)
	_show_screen("play")
	_show_toast("현장 증강 · %s" % String(card.name))
	_check_level_up()


func _choose_augment(card: Dictionary) -> void:
	if card.has("key"):
		_choose_csv_augment(card)
		return
	var id := String(card.id)
	if id == Data.HARIN_MAGAZINE_AUGMENT and (Data.CHARACTERS[player_index].id != "harin" or _magazine_augment_stacks() >= Data.MAGAZINE_AUGMENT_LIMIT):
		return
	if not picked_augment_ids.has(id):
		picked_augment_ids.append(id)
	var entry: Dictionary = acquired_augments.get(id, {})
	var count := int(entry.get("count", 0)) + 1
	var effects_applied: Array = entry.get("effects_applied", [])
	if effects_applied.is_empty() and entry.has("stars"):
		effects_applied.append(entry.description)
	effects_applied.append(_augment_effect_text(card))
	if int(card.stars) >= int(entry.get("stars", 0)):
		entry = card.duplicate()
		entry["description"] = _augment_effect_text(card)
	entry["count"] = count
	entry["effects_applied"] = effects_applied
	acquired_augments[id] = entry
	var mult := 1.0 + 0.025 * float(card.stars)
	match String(card.effect):
		"damage": player_mod_damage *= 1.0 + 0.07 * mult
		"rate", "reload": player_mod_rate *= 1.0 + 0.06 * mult
		"range": player_mod_range *= 1.0 + 0.06 * mult
		"health":
			player_max_hp += 14.0 * mult
			player_hp = minf(_effective_player_max_hp(), player_hp + 35.0)
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
		"magazine", "saw_reach": pass
		_: player_mod_damage *= 1.06
	augment_queue = maxi(0, augment_queue - 1)
	_show_screen("play")
	_show_toast("현장 증강 · %s" % String(card.name))


func _magazine_augment_stacks() -> int:
	var entry: Dictionary = acquired_augments.get(Data.HARIN_MAGAZINE_AUGMENT, {})
	return clampi(int(entry.get("count", 0)), 0, Data.MAGAZINE_AUGMENT_LIMIT)


func _magazine_capacity() -> int:
	var hero: Dictionary = Data.CHARACTERS[player_index]
	return int(hero.magazine) + (int(_csv_bonus("magazine")) if int(hero.magazine) > 0 else 0) + (_magazine_augment_stacks() * Data.MAGAZINE_AUGMENT_ROUNDS if hero.id == "harin" else 0)


func _weapon_range(hero: Dictionary) -> float:
	var reach := float(hero.range) * player_mod_range * _csv_factor("range")
	if hero.id == "yujin" and picked_augment_ids.has(Data.YUJIN_REACH_AUGMENT):
		reach += Data.SAW_REACH_BONUS
	return reach


func _weapon_interval(hero: Dictionary, rate: float) -> float:
	var focus := Skills.FOCUS_RATE if hero.id == "si" and run_seconds < skill_active_until else 1.0
	return maxf(0.08 if hero.id == "yujin" else 0.05, float(hero.rate) / (rate * focus))


func _weapon_damage(hero: Dictionary, multiplier: float) -> float:
	var output := 1.0
	if hero.id == "yujin":
		output = 0.45 * (1.0 + float(saw_chain) * 0.045)
		if saw_overheated:
			output *= Skills.SAW_OVERHEAT_OUTPUT
	return float(hero.damage) * multiplier * _csv_factor("damage") * output


func _incoming_damage_factor(hero: Dictionary, armor: float) -> float:
	return maxf(0.25, armor - (0.12 if hero.id == "tae" else 0.0))


func _build_cost_factor(hero: Dictionary, multiplier: float) -> float:
	return maxf(0.5, multiplier - (0.10 if hero.id == "yujin" else 0.0))


func _combat_stats() -> Dictionary:
	var hero: Dictionary = Data.CHARACTERS[player_index]
	return {
		"hp": _effective_player_max_hp(),
		"magazine": float(_magazine_capacity()),
		"damage": _weapon_damage(hero, player_mod_damage),
		"rate": 1.0 / _weapon_interval(hero, player_mod_rate * _csv_factor("rate")),
		"speed": float(hero.speed) * player_mod_speed * _csv_factor("move"),
		"range": _weapon_range(hero),
		"armor": (1.0 - _incoming_damage_factor(hero, player_mod_armor)) * 100.0,
		"build": _build_cost_factor(hero, player_mod_build) * 100.0,
	}


func _legacy_base_stats() -> Dictionary:
	var hero: Dictionary = Data.CHARACTERS[player_index]
	return {
		"magazine": float(hero.magazine),
		"hp": float(hero.hp) + float(permanent_upgrades.get("health", 0)) * 15.0,
		"damage": _weapon_damage(hero, 1.0 + float(permanent_upgrades.get("damage", 0)) * 0.06),
		"rate": 1.0 / _weapon_interval(hero, 1.0 + float(permanent_upgrades.get("reload", 0)) * 0.04),
		"speed": float(hero.speed) * (1.0 + float(permanent_upgrades.get("speed", 0)) * 0.04),
		"range": float(hero.range) * (1.0 + float(permanent_upgrades.get("range", 0)) * 0.05),
		"armor": (1.0 - _incoming_damage_factor(hero, 1.0)) * 100.0,
		"build": _build_cost_factor(hero, maxf(0.55, 1.0 - float(permanent_upgrades.get("build", 0)) * 0.04)) * 100.0,
	}


func _operator_stat_rows() -> Array:
	var current := _combat_stats()
	var base := run_base_stats if not run_base_stats.is_empty() else _legacy_base_stats()
	var rows := []
	for field in [
		["hp", "최대 체력", ""], ["damage", "공격 피해 (1회 합계)", ""],
		["rate", "공격 빈도", "/초"], ["speed", "이동 속도", " px/초"], ["range", "공격 범위", " px"],
		["armor", "받는 피해 감소", "%"], ["build", "건설 비용 배율", "%"],
		["magazine", "최대 탄창 용량", "발"],
	]:
		if field[0] == "magazine" and int(current.magazine) == 0:
			continue
		var final_value := float(current[field[0]])
		var base_value := float(base.get(field[0], Data.CHARACTERS[player_index].magazine if field[0] == "magazine" else final_value))
		var difference := final_value - base_value
		var unit := String(field[2])
		if field[0] == "magazine":
			rows.append([field[1], "%d발" % base_value, "+%d발" % difference if difference > 0 else "—", "%d발" % final_value])
			continue
		var delta_text := "—" if is_zero_approx(difference) else "%s%.2f%s" % ["+" if difference > 0.0 else "", difference, "%p" if unit == "%" else unit]
		rows.append([field[1], "%.2f%s" % [base_value, unit], delta_text, "%.2f%s" % [final_value, unit]])
	return rows


func _augment_effect_text(card: Dictionary) -> String:
	if card.has("key"):
		return AugmentCatalog.description(card)
	if not card.has("stars"):
		return String(card.get("description", "")) + " · 세부 획득 기록 없음"
	var scale := 1.0 + 0.025 * float(card.stars)
	match String(card.effect):
		"damage": return "공격 피해 +%.2f%%" % (7.0 * scale)
		"rate", "reload":
			var hero: Dictionary = Data.CHARACTERS[player_index]
			var before := 1.0 / _weapon_interval(hero, player_mod_rate)
			var after := 1.0 / _weapon_interval(hero, player_mod_rate * (1.0 + 0.06 * scale))
			return "공격 빈도 +%.2f%%\n%.2f → %.2f회/초" % [(after / before - 1.0) * 100.0, before, after]
		"range": return "무기·포탑 사거리 +%.2f%%" % (6.0 * scale)
		"health": return "최대 체력 +%.2f · 획득 시 체력 최대 35 회복" % (14.0 * scale)
		"armor": return "받는 피해 배율 ×0.94 (고유 보정·하한 별도)"
		"speed": return "이동 속도 배율 +%.2f%%" % (4.5 * scale)
		"xp": return "경험치 배율 +%.2f%%" % (8.0 * scale)
		"building_hp": return "건설 시 시설 내구도 배율 +%.2f%%" % (8.0 * scale)
		"salvage": return "보급품 배율 +%.2f%%" % (10.0 * scale)
		"turret_damage": return "포탑 피해 배율 +%.2f%%" % (8.0 * scale)
		"turret_rate": return "포탑 공격 빈도 배율 +%.2f%%" % (8.0 * scale)
		"build": return "건설 비용 배율 -5%p (최소 비용 배율 적용)"
		"projectile": return "산탄총 발사 탄환 +1" if Data.CHARACTERS[player_index].id == "tae" else "산탄 수 +1 (산탄총에만 적용)"
		"pierce": return "총기 관통 대상 +1"
		"drone": return "지원 드론 레벨 +1 · 자동 지원 사격"
		"saw_reach": return "전기톱 공격 거리 +%d px" % Data.SAW_REACH_BONUS
		"magazine":
			var capacity := _magazine_capacity()
			return "최대 탄창 +%d발 (%d → %d발)\n중첩 %d/%d · 재장전 시 반영" % [Data.MAGAZINE_AUGMENT_ROUNDS, capacity, capacity + Data.MAGAZINE_AUGMENT_ROUNDS, _magazine_augment_stacks() + 1, Data.MAGAZINE_AUGMENT_LIMIT]
	return "공격 피해 +6%"


func _player_take_damage(amount: float, cause: String) -> void:
	if dash_timer > 0.0 or treatment_remaining > 0.0: return
	if clinic_shield > 0.0 or (_csv_bonus("evade") > 0.0 and _random.randf() < minf(0.8, _csv_bonus("evade") / 100.0)):
		return
	var reduction := _csv_bonus("armor") + (_csv_bonus("low_armor") if player_hp < _effective_player_max_hp() * 0.35 else 0.0)
	player_hp -= amount * _incoming_damage_factor(Data.CHARACTERS[player_index], player_mod_armor) * (1.0 - clampf(reduction / 100.0, 0.0, 0.8))
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
	var previous_hp := float(structures[i].hp)
	structures[i].hp = maxf(0.0, previous_hp - amount * _csv_reduction("hq_armor"))
	if previous_hp > 0.0 and float(structures[i].hp) <= 0.0:
		_emit_structure_debris(structures[i])
		_show_toast("지휘본부가 파괴되었습니다!")


func _damage_structure(index: int, amount: float) -> void:
	if index < 0 or index >= structures.size(): return
	var previous_hp := float(structures[index].hp)
	var reduction := _csv_reduction("wall_armor" if structures[index].kind == "wall" else "hq_armor" if structures[index].kind == "hq" else "")
	structures[index].hp = maxf(0.0, previous_hp - amount * reduction)
	if previous_hp > 0.0 and float(structures[index].hp) <= 0.0:
		_emit_structure_debris(structures[index])
		_show_toast("%s 파괴 · 슬롯 반환" % String(_build_definition(String(structures[index].kind)).get("name", structures[index].kind)))
		if String(structures[index].kind) == "hq": _finish_run(false)


func _emit_structure_debris(structure: Dictionary) -> void:
	if effects.size() < 80:
		var broken := _entry_world_center(structure)
		effects.append({"a": broken, "b": broken, "time": 0.32, "debris": true})


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
	if screen in ["play", "pause", "augment", "info"]:
		if hud_hero != player_index:
			hud_hero = player_index
			hud_portrait.texture = _operator_portrait()
		hud_name.text = String(Data.CHARACTERS[player_index].name)
		hud_level.text = "Lv.%d  [C]" % player_level
		hud_health.text = "%d / %d" % [ceili(player_hp), ceili(_effective_player_max_hp())]
		hp_bar.max_value = _effective_player_max_hp()
		hp_bar.value = player_hp
		var hq := _hq_index()
		if hq >= 0:
			base_bar.max_value = float(structures[hq].max_hp)
			base_bar.value = float(structures[hq].hp)
			hud_hq.text = "HQ  %d / %d" % [ceili(base_bar.value), ceili(base_bar.max_value)]
		var remaining := maxi(0, int(WAVE_SECONDS - stage_elapsed))
		stage_label.text = "단계 %d / 100  ·  %s  ·  다음 단계 %02d초" % [stage, String(difficulty.get("label", "")), remaining]
		var elapsed := int(run_seconds)
		currency_label.text = "보급품 %d  ·  처치 %d  ·  훈장 %d   |   %02d:%02d" % [money, kills, medals, elapsed / 60, elapsed % 60]
		var boss_text := ""
		for e in enemies:
			if bool(e.get("boss", false)):
				boss_text = "BOSS  %s  ·  %d / %d" % [String(e.name), int(e.hp), int(e.max_hp)]
				break
		boss_label.text = boss_text
		var toast_node := run_hud.find_child("Toast", true, false) as Label
		if toast_node: toast_node.text = toast if toast_timer > 0.0 else ""
		var capacity := _magazine_capacity()
		var ammo := "전기톱 · 탄약 미사용" if capacity == 0 else "탄약 %d / %d" % [player_magazine, capacity]
		if player_reload_timer > 0.0:
			ammo += " · 재장전 중"
		var hero_id: String = Data.CHARACTERS[player_index].id
		if hero_id == "yujin":
			ammo = "전기톱 · 열 %d%%%s" % [int(saw_heat), " · 과열" if saw_overheated else ""]
		if skill_button != null:
			var profile: Array = Skills.PROFILES[hero_id]
			var cooldown := maxf(0.0, skill_ready_at - run_seconds)
			var active := maxf(0.0, skill_active_until - run_seconds)
			var state_text := "작동 %d초" % ceili(active) if active > 0.0 else "%d초" % ceili(cooldown) if cooldown > 0.0 else ("열기 없음" if hero_id == "yujin" and saw_heat <= 0.0 else "준비")
			skill_button.text = "%s [Q] · %s" % [profile[0], state_text]
			skill_button.tooltip_text = String(profile[1])
			skill_button.disabled = screen != "play" or treatment_remaining > 0.0 or cooldown > 0.0 or (hero_id == "yujin" and saw_heat <= 0.0)
			dash_status.text = "대시 [%s]  %s" % [OS.get_keycode_string(dash_key), "%d초" % ceili(dash_cooldown) if dash_cooldown > 0.0 else "준비"]
		combat_label.text = "%s [Tab]  ·  %s" % ["수동" if manual_attack else "자동", ammo]
		status_label.text = "치료 중 · %d초 남음" % ceili(treatment_remaining) if treatment_remaining > 0.0 else ("좌클릭 유지: 사격" if manual_attack and not build_open else "")
		var inspector := run_hud.find_child("Inspector", true, false) as Control
		if inspector.visible and selected_entity >= 0 and selected_entity < structures.size():
			var facility := structures[selected_entity]
			if facility.kind == "clinic":
				inspector_label.text = "의료소 · 레벨 %d\n%s" % [facility.level, "%s 치료 중 · %d초" % [Data.CHARACTERS[player_index].name, ceili(treatment_remaining)] if treatment_remaining > 0.0 else "빈 병상 · 대기 중"]
			elif facility.kind == "supply":
				inspector_label.text = "용병 파견소 · 레벨 %d\n%s" % [facility.level, "복귀까지 %d초" % ceili(expedition_remaining) if expedition_remaining > 0.0 else "파견 대기 · 용병 강화 %d/10" % mercenary_level]


func _save_all() -> void:
	var output: Dictionary = {"schema": 1, "medals": medals, "upgrades": permanent_upgrades, "dash_key": dash_key, "pause_key": pause_key, "sound_on": sound_on, "shake_on": shake_on, "saved_run": saved_run}
	if screen in ["play", "pause", "augment", "info"]:
		var structure_rows: Array[Dictionary] = []
		for s in structures:
			var cell: Vector2i = s.get("cell", Vector2i.ZERO)
			structure_rows.append({"kind": String(s.kind), "x": cell.x, "y": cell.y, "hp": float(s.hp), "max_hp": float(s.max_hp), "level": int(s.level)})
		var enemy_rows: Array[Dictionary] = []
		for e in enemies:
			var row := {"kind": String(e.kind), "x": float(e.pos.x), "y": float(e.pos.y), "hp": float(e.hp), "cool": float(e.cool), "boss": bool(e.boss), "variant": int(e.get("variant", -1)), "appearance": int(e.get("appearance", 0))}
			if e.kind == "S10":
				row.underground = e.underground
				if e.has("burrow_warning"):
					row.burrow_warning = e.burrow_warning
			enemy_rows.append(row)
		saved_run = {"hero": player_index, "difficulty": difficulty_index, "stage": stage, "stage_elapsed": stage_elapsed, "run_seconds": run_seconds, "money": money, "kills": kills, "level": player_level, "xp": player_xp, "boss_kills": boss_kills, "player_hp": player_hp, "player_max_hp": player_max_hp, "player_pos": [player_pos.x, player_pos.y], "structures": structure_rows, "enemies": enemy_rows, "mods": {"damage": player_mod_damage, "rate": player_mod_rate, "speed": player_mod_speed, "range": player_mod_range, "armor": player_mod_armor, "xp": player_mod_xp, "salvage": player_mod_salvage, "build": player_mod_build, "building_hp": player_mod_building_hp, "turret_damage": player_mod_turret_damage, "turret_rate": player_mod_turret_rate, "pellets": player_extra_pellets, "pierce": player_pierce, "drone": player_drone_level, "augments": augments_taken, "picked": picked_augment_ids}}
		saved_run["operator_skill"] = {"ready": skill_ready_at, "active": skill_active_until,
			"heat": saw_heat, "overheated": saw_overheated, "repair_kills": saw_repair_kills}
		saved_run["boss_flags"] = boss_spawned.keys()
		saved_run["final_boss_defeated"] = final_boss_defeated
		saved_run["augment_queue"] = augment_queue
		saved_run["treatment_remaining"] = treatment_remaining
		saved_run["expedition_remaining"] = expedition_remaining
		saved_run["mercenary_level"] = mercenary_level
		saved_run["base_stats"] = run_base_stats
		saved_run["acquired_augments"] = acquired_augments
		saved_run["warned_enemies"] = warned_enemies.keys()
		saved_run["pending_enemy_warnings"] = field_warning.pending_warnings()
		saved_run["repair_drone_level"] = repair_drone_level
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
	if RESERVED_KEYS.has(dash_key) or BUILD_SHORTCUTS.has(dash_key): dash_key = KEY_SHIFT
	if RESERVED_KEYS.has(pause_key) or BUILD_SHORTCUTS.has(pause_key): pause_key = KEY_ESCAPE
	if pause_key == dash_key:
		dash_key = KEY_SHIFT
		pause_key = KEY_ESCAPE
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
	run_base_stats = saved_run.get("base_stats", _legacy_base_stats())
	acquired_augments = saved_run.get("acquired_augments", {}).duplicate(true)
	csv_trigger_until.clear()
	_rebuild_csv_stats()
	for card in Data.augment_catalog():
		if picked_augment_ids.has(card.id) and not acquired_augments.has(card.id):
			var legacy := card.duplicate()
			legacy.description = _augment_effect_text(card)
			acquired_augments[card.id] = legacy
	var flags: Array = saved_run.get("boss_flags", [])
	boss_spawned.clear()
	for flag in flags:
		boss_spawned[int(flag)] = true
	for milestone in Data.BOSSES:
		if milestone < stage:
			boss_spawned[milestone] = true


func _world_to_screen(point: Vector2) -> Vector2:
	return point - jeju_map.camera_center(player_pos, size, _view_zoom()) + size * 0.5


func _world_to_viewport(point: Vector2) -> Vector2:
	var center := jeju_map.camera_center(player_pos, size, _view_zoom())
	return size * 0.5 + (point - center) * _view_zoom()


func _view_zoom() -> float:
	return 1.0 if screen == "landing" else camera_zoom


func _screen_to_world(point: Vector2) -> Vector2:
	return jeju_map.camera_center(player_pos, size, _view_zoom()) + (point - size * 0.5) / _view_zoom()


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
	var zoom := _view_zoom()
	var camera := Transform2D(0.0, Vector2.ONE * zoom, 0.0, size * 0.5 * (1.0 - zoom))
	draw_set_transform_matrix(camera)
	if build_open or build_mode:
		_draw_build_grid()
	for effect in effects:
		if effect.get("burrow_debris", 0.0) == AMBUSH_RADIUS:
			var remaining := clampf(float(effect.time) / float(effect.seconds), 0.0, 1.0)
			BurrowVisual.ground(self, _world_to_screen(effect.a), float(effect.burrow_debris), remaining, remaining, run_seconds)
	for zone in toxin_zones:
		draw_circle(_world_to_screen(zone.pos), 52.0, Color("#84ae5549"))
	_draw_world_depth(camera)
	if Data.CHARACTERS[player_index].id == "harin" and treatment_remaining <= 0.0 and screen != "landing":
		_draw_tactical_drone(camera)
	for projectile in enemy_shots: _draw_enemy_projectile(projectile)
	for shot in player_projectiles.shots:
		var traveled: float = shot.traveled
		var tail_length := minf(12.0, traveled)
		var offset: Vector2 = shot.tracer_offset
		var tip := _world_to_screen(shot.pos + offset * maxf(0.0, 1.0 - traveled / 82.0))
		var tail_offset := offset * maxf(0.0, 1.0 - (traveled - tail_length) / 82.0)
		var tail: Vector2 = _world_to_screen(shot.pos - shot.direction * tail_length + tail_offset)
		draw_line(tail, tip, shot.color, 2.0)
		var mask := int(shot.get("element_mask", 0))
		if mask != 0:
			Elements.trail(self, tail, tip, mask, run_seconds)
	if repair_drone_level > 0:
		_draw_repair_drone()
	for effect in effects: _draw_effect(effect)
	if screen == "landing":
		landing.draw(self, _world_to_screen)
		landing.draw_overlay(self, size)
	if build_mode: _draw_placement_preview()
	draw_set_transform(Vector2.ZERO)
	if screen == "play" and manual_attack and not build_mode:
		_draw_cross(aim_screen, 7, Color(PALETTE.gold, 0.55))
	if screen in ["pause", "augment", "result", "info"] or (screen == "settings" and settings_from_pause):
		draw_rect(view, Color(0.025, 0.035, 0.035, 0.16 if screen == "augment" else 0.42))


func _tactical_drone_side() -> float:
	if absf(player_motion.x) > maxf(6.0, absf(player_motion.y)):
		return signf(player_motion.x)
	return 0.0


func _draw_tactical_drone(camera: Transform2D) -> void:
	var elapsed := run_seconds - combat_drone_fire_at
	var firing := combat_drone_fire_at >= 0.0 and elapsed < 0.21
	var point := _world_to_viewport(combat_drone_position)
	var recoil := -combat_drone_facing * maxf(0.0, 3.0 - elapsed * 24.0) if firing else Vector2.ZERO
	var side := _tactical_drone_side()
	var frame_rect := Rect2(-16, -12, 32, 24)
	if side == 0.0:
		var frame := (2 if elapsed < 0.075 else 3) if firing else int(run_seconds * 12.0) % 2
		draw_set_transform_matrix(Transform2D(0.0, (point + recoil).round()))
		draw_texture_rect_region(TACTICAL_DRONE, frame_rect, Rect2(frame * 64, 0, 64, 48))
	else:
		var tint := Color(1.16, 1.04, 1.22) if firing and elapsed < 0.07 else Color.WHITE
		draw_set_transform_matrix(Transform2D(0.0, Vector2(side, 1.0), 0.0, (point + recoil).round()))
		draw_texture_rect(TACTICAL_DRONE_SIDE, frame_rect, false, tint)
	draw_set_transform_matrix(camera)


func _draw_world_depth(camera: Transform2D) -> void:
	var layers: Array[Array] = []
	for entry in structures:
		if float(entry.hp) > 0.0:
			layers.append([_entry_world_center(entry).y + CELL * 0.5, 1, entry])
	for corpse in zombie_corpses:
		if _zombie_on_screen(_world_to_screen(corpse.pos)):
			layers.append([corpse.pos.y + 40.0, 2, corpse])
	for enemy in enemies:
		if enemy.has("pattern_pos") or _zombie_on_screen(_world_to_screen(enemy.pos), 240.0 if enemy.boss else 100.0):
			layers.append([enemy.pos.y + 40.0, 3, enemy])
	if treatment_remaining <= 0.0 and (screen != "landing" or landing.player_visible()):
		layers.append([player_pos.y + 40.0 * PLAYER_DRAW_SCALE / _view_zoom(), 4, {}])
	layers.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	for item in layers:
		match item[1]:
			1: _draw_structure(item[2], camera)
			2: ZombieVisual.draw_dead(self, item[2], _world_to_screen(item[2].pos), run_seconds, camera)
			3: _draw_enemy(item[2], camera)
			4:
				# Draw at the camera focus point in screen pixels, then restore the world transform.
				draw_set_transform(Vector2.ZERO)
				_draw_player(_world_to_viewport(player_pos).round())
				draw_set_transform_matrix(camera)


func _draw_build_grid() -> void:
	for y in range(GRID_MIN, GRID_MAX + 1):
		for x in range(GRID_MIN, GRID_MAX + 1):
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


func _draw_repair_drone() -> void:
	var center := _world_to_screen(repair_drone_pos)
	var height := -29.0 + sin(run_seconds * 7.0) * 3.0
	var extent := REPAIR_DRONE_ART.get_size() * (35.0 / REPAIR_DRONE_ART.get_width())
	draw_circle(center, 11.0, Color("#14151850"))
	draw_texture_rect(REPAIR_DRONE_ART, Rect2(center + Vector2(0, height) - extent * 0.5, extent), false)
	draw_circle(center + Vector2(0, height + 7.0), 2.0, Data.REPAIR_DRONE.color)


func _draw_structure(entry: Dictionary, camera: Transform2D) -> void:
	var kind := String(entry.kind)
	var center := _world_to_screen(_entry_world_center(entry))
	var width := 2 if kind == "hq" or _is_building(kind) else 1
	var bounds := Rect2(center - Vector2(CELL * float(width) * 0.5, CELL * 0.5), Vector2(CELL * float(width), CELL))
	var ratio := clampf(float(entry.hp) / maxf(1.0, float(entry.max_hp)), 0.0, 1.0)
	# Keep painted detail while bringing highlights into the battlefield palette.
	var condition := Color("#d8c8c0") if ratio > DAMAGE_MARK else Color("#b4a094") if ratio > DAMAGE_FIRE else Color("#95756a")
	var level := clampi(int(entry.get("level", 1)), 1, 5)
	var bar_height := 31.0
	if kind == "hq" and hq_build_ratio <= 0.0:
		return
	_draw_structure_shadow(bounds, kind, hq_build_ratio if kind == "hq" else 1.0)
	if kind == "hq":
		_draw_structure_sprite(BASE_ART, level - 1, 0, center + Vector2(0, 24), 105.0,
			Color(condition, hq_build_ratio))
		bar_height = 77.0
		draw_string(ThemeDB.fallback_font, center + Vector2(-34, 40), "지휘본부", HORIZONTAL_ALIGNMENT_LEFT, 90, 11, PALETTE.text)
	elif kind == "wall":
		_draw_structure_sprite(BASE_ART, level - 1, 1, center + Vector2(0, 24), 51.0, condition)
	elif TURRET_ROWS.has(kind):
		var target := _nearest_enemy(_entry_world_center(entry), 370.0)
		var look_left: bool = enemies[target].pos.x < _entry_world_center(entry).x if target >= 0 else player_facing.x < 0.0
		var flip := Vector2(-1, 1) if look_left else Vector2.ONE
		draw_set_transform_matrix(camera * Transform2D(0.0, flip, 0.0, center))
		_draw_structure_sprite(TURRET_ART, level - 1, TURRET_ROWS[kind], Vector2(0, 24), 82.0, condition)
		draw_set_transform_matrix(camera)
		for pip in range(level):
			draw_rect(Rect2(center.x - 12 + pip * 5, center.y + 19, 3, 2), PALETTE.gold)
	elif FACILITY_COLUMNS.has(kind):
		var def := _build_definition(kind)
		bar_height = 60.0
		_draw_structure_sprite(BASE_ART, FACILITY_COLUMNS[kind], 2, center + Vector2(0, 24), 103.0, condition)
		draw_string(ThemeDB.fallback_font, center + Vector2(-21, 34), String(def.get("short", "시설")), HORIZONTAL_ALIGNMENT_LEFT, 60, 10, PALETTE.text)
	_draw_structure_damage(center, ratio, width, kind == "wall")
	var bar_width := 28.0 if kind == "wall" else 40.0 * float(width)
	var bar := Rect2(center.x - bar_width * 0.5, center.y - bar_height, bar_width, 3)
	draw_rect(bar, Color(0, 0, 0, 0.7))
	bar.size.x *= ratio
	draw_rect(bar, PALETTE.green if ratio > 0.35 else PALETTE.red)
	if selected_entity >= 0 and selected_entity < structures.size() and structures[selected_entity] == entry:
		draw_rect(bounds.grow(3), PALETTE.blue, false, 2.0)


func _draw_structure_shadow(bounds: Rect2, kind: String, opacity: float) -> void:
	var left := bounds.position.x + (9.0 if TURRET_ROWS.has(kind) else 2.0)
	var right := bounds.end.x - (9.0 if TURRET_ROWS.has(kind) else 2.0)
	var base := bounds.end.y
	var depth := 10.0 if kind == "wall" else 21.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(left + 2, base - depth), Vector2(right + 2, base - depth),
		Vector2(right + 13, base + 4), Vector2(left + 6, base + 4),
	]), Color(0.13, 0.10, 0.10, 0.28 * opacity))
	draw_colored_polygon(PackedVector2Array([
		Vector2(left + 3, base - 8), Vector2(right - 2, base - 8),
		Vector2(right + 2, base), Vector2(left, base),
	]), Color(0.11, 0.08, 0.08, 0.44 * opacity))


func _draw_structure_damage(center: Vector2, ratio: float, width: int, wall: bool) -> void:
	if ratio > DAMAGE_MARK:
		return
	var offset := Vector2(13.0 if width == 1 else 23.0, 4.0 if wall else -8.0)
	var scar := center + offset
	draw_polyline(PackedVector2Array([scar + Vector2(-8, -9), scar + Vector2(-4, -4),
		scar + Vector2(-7, 0), scar + Vector2(1, 7)]), Color("#251d20c8"), 1.5)
	if ratio <= DAMAGE_SMOKE:
		var phase := run_seconds + fposmod(center.x * 0.012 + center.y * 0.02, 0.8)
		var extent := Vector2.ONE * (56.0 if wall else 83.0)
		FacilityEffects.draw_clip(self, "smoke", phase, scar + Vector2(0, -3), extent, 0.6)
		if ratio <= DAMAGE_FIRE:
			FacilityEffects.draw_clip(self, "fire", phase + 0.1, scar + Vector2(0, 5), extent * 0.8, 0.88)


func _draw_structure_sprite(texture: Texture2D, column: int, row: int, feet: Vector2, width: float, tint := Color.WHITE) -> void:
	var source := Rect2(Vector2(column, row) * STRUCTURE_FRAME, STRUCTURE_FRAME)
	var size_px := STRUCTURE_FRAME * (width / STRUCTURE_FRAME.x)
	var anchor := Vector2(size_px.x * 0.5, size_px.y * (100.0 / STRUCTURE_FRAME.y))
	draw_texture_rect_region(texture, Rect2(feet - anchor, size_px), source, tint)


func _draw_enemy(enemy: Dictionary, camera: Transform2D) -> void:
	var p := _world_to_screen(enemy.pos)
	var boss := bool(enemy.get("boss", false))
	if enemy.has("pattern_pos"):
		var point := _world_to_screen(enemy.pattern_pos)
		var warning_radius := _boss_pattern_radius(int(String(enemy.kind).trim_prefix("boss")))
		draw_circle(point, warning_radius, Color(enemy.color, 0.15))
		draw_arc(point, warning_radius, 0.0, TAU, 36, Color(enemy.color, 0.9), 3.0)
	elif enemy.kind == "S05" and float(enemy.charge) > 0.0:
		var buildup := clampf(float(enemy.charge) / float(enemy.ability), 0.0, 1.0)
		draw_circle(p, 120.0, Color(1.0, 0.34, 0.13, 0.09))
		draw_arc(p, 120.0, 0.0, TAU, 40, Color("#dd7949"), 2.0)
		draw_arc(p, 120.0 * buildup, 0.0, TAU, 40, Color("#ffc88d"), 2.0)
	elif enemy.has("warn_pos") and enemy.ranged and float(enemy.charge) > 0.0:
		var target := _world_to_screen(enemy.warn_pos)
		draw_line(p, target, Color(enemy.color, 0.64), 2.0)
		draw_arc(target, 19.0, 0.0, TAU, 20, Color(enemy.color, 0.86), 2.0)
	if float(enemy.get("guard_until", 0.0)) > run_seconds:
		draw_arc(p, 57.0, 0.0, TAU, 36, Color("#b5bbc5"), 3.0)
	var radius := PlayerProjectiles.enemy_radius(enemy) * ZombieVisual.DRAW_SCALE
	if enemy.has("variant"):
		if not _zombie_on_screen(p, 240.0 if boss else 100.0): return
		if enemy.get("underground", false):
			if enemy.has("burrow_warning"):
				var progress := 1.0 - float(enemy.burrow_warning) / AMBUSH_WARNING
				BurrowVisual.ground(self, p, AMBUSH_RADIUS, progress, 0.0, run_seconds)
			return
		var art_scale := ZombieVisual.DRAW_SCALE * float(enemy.get("art_scale", 1.0))
		var lift := -30.0 if enemy.get("air", false) else 0.0
		var transform := Transform2D(0.0, Vector2.ONE * art_scale, 0.0, p * (1.0 - art_scale) + Vector2(0, lift))
		var visual_camera := camera * transform
		draw_set_transform_matrix(visual_camera)
		var tint := Color.WHITE
		if enemy.get("special", false):
			tint = [Color.WHITE, Color("#e2debb"), Color("#c0cbd8"), Color("#d9b9aa")][int(enemy.appearance) % 4]
		elif enemy.kind != "normal" and int(enemy.get("appearance", 0)) >= 8:
			tint = Color.WHITE.lerp(Color.from_hsv(float(int(enemy.appearance) / 8) / 7.0, 0.35, 0.91), 0.34)
		if enemy.kind == "S17": tint.a = 0.42
		if enemy.kind == "S05" and float(enemy.charge) > 0.0:
			tint = tint.lerp(Color("#ff9560"), 0.35 + sin(run_seconds * 35.0) * 0.22)
		var frozen := float(enemy.get("frozen_until", 0.0)) > run_seconds
		var frost: Dictionary = enemy.get("freeze", {})
		if float(frost.get("until", 0.0)) > run_seconds:
			var coverage := clampf((run_seconds - float(frost.get("start", run_seconds))) / 1.5, 0.0, 1.0)
			tint = tint.lerp(Color("#80d4ef"), 0.75 if frozen else 0.16 + coverage * 0.24)
		if float(enemy.get("down_until", 0.0)) > run_seconds:
			var axis: Vector2 = enemy.knock_direction
			var angle := (-1.0 if axis.x < 0.0 else 1.0) * lerpf(0.0, 1.28, clampf((float(enemy.down_until) - run_seconds) / 0.16, 0.0, 1.0))
			var tip := Transform2D(angle, Vector2.ZERO)
			var anchor := p + Vector2(0, 28)
			visual_camera = visual_camera * Transform2D(tip.x, tip.y, anchor - tip * anchor)
			draw_set_transform_matrix(visual_camera)
		ZombieVisual.draw_alive(self, enemy, p, run_seconds, visual_camera, tint, enemies.size() >= 500)
		draw_set_transform_matrix(camera)
		_draw_enemy_elements(enemy, p + Vector2(0, lift), frozen)
		if float(enemy.hp) < float(enemy.max_hp):
			var ratio := clampf(float(enemy.hp) / float(enemy.max_hp), 0.0, 1.0)
			draw_rect(Rect2(p.x - 12, p.y - 47.0 * art_scale + lift, 24, 3), Color(0, 0, 0, 0.65))
			draw_rect(Rect2(p.x - 12, p.y - 47.0 * art_scale + lift, 24 * ratio, 3), PALETTE.green)
		return
	if String(enemy.kind) == "bomber" and float(enemy.get("charge", 0)) > 0.0:
		var pulse := 56.0 - 28.0 * maxf(0.0, float(enemy.charge)) / 0.72
		draw_arc(p, pulse, 0, TAU, 44, Color(PALETTE.red, 0.92), 3.0)
		_draw_cross(p, 8, PALETTE.red)
	var c: Color = enemy.get("color", PALETTE.red)
	var frozen := float(enemy.get("frozen_until", 0.0)) > run_seconds
	if frozen:
		c = c.lerp(Elements.FROST, 0.65)
	_draw_enemy_elements(enemy, p, frozen)
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


func _draw_enemy_elements(enemy: Dictionary, p: Vector2, frozen: bool) -> void:
	var phase := run_seconds + float(enemy.get("spawn_id", 0)) * 0.17
	if float(enemy.get("burn", {}).get("until", 0.0)) > run_seconds:
		Elements.flame(self, p + Vector2(0, -9), Vector2.UP, phase, 0.8)
	if float(enemy.get("poison", {}).get("until", 0.0)) > run_seconds:
		Elements.trail(self, p + Vector2(-7, 5), p + Vector2(6, -9), Elements.POISON, phase)
	if frozen or float(enemy.get("freeze", {}).get("until", 0.0)) > run_seconds:
		Elements.crystals(self, p, 0.95 if frozen else 0.42)


func _draw_enemy_projectile(shot: Dictionary) -> void:
	var p := _world_to_screen(shot.pos)
	var c: Color = shot.get("color", PALETTE.red)
	draw_circle(p, ENEMY_SHOT_RADIUS, c)
	draw_line(p, p - Vector2(10, 8), Color(c, 0.42), 3.0)


func _draw_effect(effect: Dictionary) -> void:
	var a := _world_to_screen(effect.a)
	var b := _world_to_screen(effect.b)
	var alpha := clampf(float(effect.time) / 0.25, 0.0, 1.0)
	var c: Color = effect.get("color", PALETTE.gold)
	if effect.has("burrow_debris"):
		var age := 1.0 - clampf(float(effect.time) / float(effect.seconds), 0.0, 1.0)
		BurrowVisual.burst(self, a, float(effect.burrow_debris), age)
	elif effect.has("dot_text"):
		var weight := clampf(float(effect.time) / float(effect.seconds), 0.0, 1.0)
		var point := a + Vector2(-8, -53 - 18.0 * (1.0 - weight)) + Vector2(0 if c.g < 0.6 else 10, 0)
		draw_string_outline(ThemeDB.fallback_font, point, effect.dot_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 3, Color("#202220"))
		draw_string(ThemeDB.fallback_font, point, effect.dot_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(c, weight))
	elif effect.has("ice_shatter"):
		Elements.shatter(self, a, 1.0 - clampf(float(effect.time) / float(effect.seconds), 0.0, 1.0))
	elif effect.get("fire_cone", false):
		var forward := a.direction_to(b)
		for i in range(1, 6):
			var fuzz := forward.orthogonal() * sin(run_seconds * 37.0 + i * 2.0) * i * 1.7
			Elements.flame(self, a.lerp(b, float(i) / 6.0) + fuzz, forward, run_seconds + i, 1.0 + float(i) * 0.13)
	elif int(effect.get("element_mask", 0)) == Elements.SHOCK:
		Elements.spark(self, a, b, minf(1.0, alpha * 1.7))
	elif int(effect.get("element_mask", 0)) != 0:
		Elements.trail(self, a, b, int(effect.element_mask), run_seconds)
	elif effect.has("debris"):
		var progress := 1.0 - clampf(float(effect.time) / 0.32, 0.0, 1.0)
		for i in range(7):
			var rubble := a + Vector2.from_angle(float(i) * TAU / 7.0) * (7.0 + 29.0 * progress)
			rubble.y -= sin(progress * PI) * 13.0
			draw_rect(Rect2(rubble.round(), Vector2(5, 4)), Color(0.50, 0.41, 0.36, 1.0 - progress))
	elif effect.has("hit_angle"):
		var strength := clampf(float(effect.time) / HIT_SPARK_TIME, 0.0, 1.0)
		var age := 1.0 - strength
		for spread in [-0.9, -0.3, 0.22, 0.78]:
			var ray := Vector2.from_angle(float(effect.hit_angle) + float(spread))
			var start := a + ray * (4.0 + 18.0 * age)
			draw_line(start, start + ray * (4.0 + 7.0 * strength), Color(c, strength), 2.0)
		if age < 0.32:
			draw_circle(a, 3.5 * strength, Color("#fff0cb"))
	elif bool(effect.get("blast", false)):
		draw_arc(a, 24.0 + 110.0 * (1.0 - alpha), 0, TAU, 42, Color(c, alpha), 3.0)
	else:
		draw_line(a, b, Color(c, alpha), 2.0)


func _draw_player(p: Vector2) -> void:
	for sample in dash_echoes:
		var point := _world_to_viewport(sample.pos).round()
		var opacity := 0.46 * clampf((float(sample.until) - run_seconds) / DASH_ECHO_LIFE, 0.0, 1.0)
		if opacity > 0.0:
			var direction: Vector2 = sample.direction
			if sample.get("shield", false):
				_infantry_visual.draw_shield_charge(self, point, direction, Color(0.55, 0.86, 0.96, opacity), PLAYER_DRAW_SCALE)
			else:
				_draw_operator_sprite(point, direction, direction * 225.0, false, opacity)
	var dir := player_facing.normalized()
	if shield_dash and dash_timer > 0.0:
		_infantry_visual.draw_shield_charge(self, p, dash_direction, Color.WHITE, PLAYER_DRAW_SCALE)
	else:
		_draw_operator_sprite(p, dir, player_motion, dash_timer > 0.0)
	if screen == "play" and manual_attack and not build_mode:
		var color := Color(PALETTE.gold, 0.55)
		var aim_length := p.distance_to(aim_screen)
		if aim_length > 24.0:
			draw_line(p + dir * 20.0, p + dir * minf(aim_length - 5.0, 92.0), color, 1.0)


func _draw_operator_sprite(p: Vector2, dir: Vector2, motion: Vector2, dashing: bool, echo := 0.0) -> void:
	var kind: String = Data.CHARACTERS[player_index].id
	match kind:
		"harin":
			var reload_progress := -1.0
			if player_reload_timer > 0.0 and echo == 0.0:
				reload_progress = 1.0 - player_reload_timer / float(Data.CHARACTERS[player_index].reload)
			_harin_visual.draw(self, p, dir, motion, dashing, reload_progress, echo, PLAYER_DRAW_SCALE)
		"yujin":
			_yujin_visual.draw(self, p, dir, motion, dashing, echo, _weapon_elements() if echo == 0.0 else 0, run_seconds, PLAYER_DRAW_SCALE)
		_:
			_infantry_visual.draw(self, p, kind, dir, motion, dashing, echo, PLAYER_DRAW_SCALE)


func _draw_cross(center: Vector2, radius: float, color: Color) -> void:
	draw_line(center + Vector2(-radius, 0), center + Vector2(-3, 0), color, 1.5)
	draw_line(center + Vector2(3, 0), center + Vector2(radius, 0), color, 1.5)
	draw_line(center + Vector2(0, -radius), center + Vector2(0, -3), color, 1.5)
	draw_line(center + Vector2(0, 3), center + Vector2(0, radius), color, 1.5)
