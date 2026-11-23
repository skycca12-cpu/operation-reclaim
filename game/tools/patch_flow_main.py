import sys
p = 'scripts/main.gd'
s = open(p).read()
T = '\t'


def rep(a, b):
    global s
    a = a.replace('    ', T); b = b.replace('    ', T)
    import re
    pat = r'\n(?:[ \t]*\n)*'.join(re.escape(x) for x in a.split('\n'))
    m = re.search(pat, s)
    if not m:
        sys.exit('MISSING: ' + a[:120])
    s = s[:m.start()] + b + s[m.end():]


rep('const JejuMapArt = preload("res://scripts/reclaim/jeju_map_art.gd")\n',
'''const JejuMapArt = preload("res://scripts/reclaim/jeju_map_art.gd")
const BootScreen = preload("res://scripts/reclaim/flow/boot_screen.gd")
const MainMenuScreen = preload("res://scripts/reclaim/flow/main_menu_screen.gd")
const CharacterSelectScreen = preload("res://scripts/reclaim/flow/character_select_screen.gd")
const DifficultyScreen = preload("res://scripts/reclaim/flow/difficulty_screen.gd")
const PrologueScreen = preload("res://scripts/reclaim/flow/prologue_screen.gd")
const LandingSequence = preload("res://scripts/reclaim/flow/landing_sequence.gd")
const FlowSfx = preload("res://scripts/reclaim/flow/flow_sfx.gd")
## Landing zone and first player position for the opening landing cut.
const LANDING_ZONE := Vector2(205.0, -36.0)
const PLAYER_START := Vector2(180.0, 112.0)
''')
rep('var screen := "menu"\n', 'var screen := "boot"\n')
rep('var player_motion := Vector2.ZERO\n', '''var player_motion := Vector2.ZERO
var boot_screen: Control
var flow_menu: Control
var flow_character: Control
var flow_difficulty: Control
var flow_prologue: Control
var flow_sfx: Node
var landing = LandingSequence.new()
## 0..1 while the HQ tent is being assembled in the landing cut; 1 = finished.
var hq_build_ratio := 1.0
''')
rep('''    _build_ui()
    _show_screen("menu")''', '''    flow_sfx = FlowSfx.new()
    add_child(flow_sfx)
    flow_sfx.enabled = sound_on
    _build_ui()
    _show_screen("boot")''')
# WASD / spawn bug: these calls were unreachable after `return`.
rep('''        _refresh_hud()
        return
        _update_player(delta)
        _harin_visual.update(delta, player_motion, player_hp, Data.CHARACTERS[player_index].id == "harin")
        _update_spawn(delta)
''', '''        if screen == "landing":
            _update_landing(delta)
        _refresh_hud()
        return
    _update_player(delta)
    _harin_visual.update(delta, player_motion, player_hp, Data.CHARACTERS[player_index].id == "harin")
    _update_spawn(delta)
''')
rep('''    if event is InputEventKey and event.pressed and not event.echo:
        var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
        if code == pause_key:''', '''    if event is InputEventKey and event.pressed and not event.echo:
        var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
        if screen == "landing" and (code == KEY_ESCAPE or code == KEY_SPACE or code == KEY_ENTER):
            skip_landing()
            get_viewport().set_input_as_handled()
            return
        if code == pause_key:''')
rep('''    if screen == "play" or screen == "pause" or screen == "augment" or screen == "result":
        _draw_world()''', '''    if screen == "play" or screen == "pause" or screen == "augment" or screen == "result" or screen == "landing":
        _draw_world()''')
rep('''func _build_ui() -> void:
    menu_screen = _new_screen()''', '''func _build_ui() -> void:
    boot_screen = BootScreen.new()
    boot_screen.visible = false
    add_child(boot_screen)
    boot_screen.finished.connect(_finish_boot)
    menu_screen = _new_screen()''')
start = s.index('func _build_menu() -> void:')
end = s.index('func _build_settings_screen() -> void:')
s = s[:start] + '''func _build_menu() -> void:
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
'''.replace('    ', T) + s[end:]
rep('''    for c in [menu_screen, character_screen,''', '''    boot_screen.visible = which == "boot"
    for c in [menu_screen, character_screen,''')
rep('''        if continue_button != null:
            continue_button.visible = not saved_run.is_empty()''', '''        flow_menu.set_continue_available(not saved_run.is_empty())
        flow_menu.on_shown()
    if which == "character": flow_character.on_shown()''')
rep('''func _choose_character(index: int) -> void:
    player_index = clampi(index, 0, Data.CHARACTERS.size() - 1)
    _show_screen("difficulty")
func _choose_difficulty(index: int) -> void:
    difficulty_index = clampi(index, 0, Data.DIFFICULTIES.size() - 1)
    intro_index = 0
    _update_intro_text()
    _show_screen("intro")
''', '''func _choose_character(index: int) -> void:
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
    _ui_sound(true)
    _show_character_select()
func _on_menu_continue() -> void:
    _ui_sound(true)
    _resume_run()
func _quit_game() -> void:
    _ui_sound()
    if OS.has_feature("web"):
        flow_menu.show_notice("웹 버전은 브라우저 탭을 닫으면 종료됩니다.")
        return
    _save_all()
    get_tree().quit()
func _ui_sound(confirm := false) -> void:
    if flow_sfx != null:
        flow_sfx.play("confirm" if confirm else "click", -8.0)
''')
# Old 3-page text intro is replaced by PrologueScreen; remove its helpers.
start = s.index('func _update_intro_text() -> void:')
end = s.index('func _launch_run() -> void:')
s = s[:start] + s[end:]
rep('''func _start_new_run() -> void:
    _reset_run()
    _show_screen("play")
    _show_toast("출격 완료 · 군용 텐트 HQ 하나로 시작합니다.")
    _save_all()''', '''func _start_new_run() -> void:
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
    _save_all()''')
rep('''    player_pos = Vector2(180.0, 112.0)
    player_facing''', '''    player_pos = PLAYER_START
    player_facing''')
rep('''        "intro": intro_screen.visible = true''', '''        "intro": intro_screen.visible = true
        "landing": pass''')
rep('''    for effect in effects: _draw_effect(effect)
    _draw_player()''', '''    for effect in effects: _draw_effect(effect)
    if screen != "landing" or landing.player_visible():
        _draw_player()
    if screen == "landing":
        landing.draw(self, _world_to_screen)
        landing.draw_overlay(self, size)''')
rep('''    if kind == "hq":
        # Only''', '''    if kind == "hq" and hq_build_ratio < 1.0:
        LandingSequence.draw_tent_build(self, bounds, center, hq_build_ratio if landing.hq_ratio() >= 0.0 else -1.0)
        return
    if kind == "hq":
        # Only''')
for k in ['W', 'S', 'A', 'D']:
    s = s.replace('Input.is_key_pressed(KEY_%s) or' % k, 'Input.is_key_pressed(KEY_%s) or Input.is_physical_key_pressed(KEY_%s) or' % (k, k))
rep('''    sound_on = not sound_on
''', '''    sound_on = not sound_on
    if flow_sfx != null: flow_sfx.enabled = sound_on
''')
open(p, 'w').write(s)
print('patched')
