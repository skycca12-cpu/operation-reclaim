p = 'test/reclaim_smoke.gd'
s = open(p).read()
T = '\t'
old = T + '_check(game.get("screen") == "menu", "boot reaches localized title menu")\n'
new = (T + '_check(game.get("screen") == "boot", "game opens on the loading screen")\n'
       + T + 'game.call("_finish_boot")\n'
       + T + '_check(game.get("screen") == "menu", "loading screen hands over to the main menu")\n'
       + T + 'game.call("_choose_character", 2)\n'
       + T + '_check(game.get("screen") == "difficulty", "character choice opens difficulty selection")\n'
       + T + 'game.call("_choose_difficulty", 4)\n'
       + T + '_check(game.get("screen") == "intro" and game.get("difficulty_index") == 4, "difficulty choice opens the prologue")\n')
assert old in s
s = s.replace(old, new, 1)
old2 = (T + 'game.call("_start_new_run")\n' + T + 'await process_frame\n')
new2 = (T + 'game.call("_start_new_run")\n' + T + 'await process_frame\n'
        + T + '_check(game.get("screen") == "landing", "new run starts with the landing cut")\n'
        + T + 'game.call("skip_landing")\n' + T + 'await process_frame\n')
assert old2 in s
s = s.replace(old2, new2, 1)
# WASD regression: holding D for some frames must move the player in play mode.
old3 = T + '_check(game.get("stage") == 1, "new run starts at stage one")\n'
new3 = (old3
        + T + 'var before_x: float = (game.get("player_pos") as Vector2).x\n'
        + T + 'var ev := InputEventKey.new()\n' + T + 'ev.physical_keycode = KEY_D\n' + T + 'ev.keycode = KEY_D\n' + T + 'ev.pressed = true\n'
        + T + 'Input.parse_input_event(ev)\n'
        + T + 'for _i in range(10): await process_frame\n'
        + T + 'var ev_up := ev.duplicate()\n' + T + 'ev_up.pressed = false\n' + T + 'Input.parse_input_event(ev_up)\n'
        + T + 'await process_frame\n'
        + T + '_check((game.get("player_pos") as Vector2).x > before_x + 1.0, "holding D moves the player (WASD regression)")\n')
assert old3 in s
s = s.replace(old3, new3, 1)
open(p, 'w').write(s)
print('test patched')
