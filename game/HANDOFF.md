# 인수인계 문서 — OPERATION: RECLAIM (수도 탈환 작전)

Godot 4.7.2 / GDScript, 1280x720, GL Compatibility. 작업은 2차 흐름 구현 도중에 중단했습니다. 아래는 확인된 사실과 남은 일입니다.

## 1. 요청 범위 (사용자 지시)
실행 → 로딩 화면 → 메인 메뉴(승인 시안) → 4인 캐릭터 선택 → 5단계 난이도 → 제주 프롤로그 → 헬기 착륙·HQ 설치 → 실제 전투. WASD 이동 불가 버그 수정.
제출물: 전체 프로젝트 ZIP, 실행 빌드, 실제 실행 영상, 완료·미완료 목록.
지켜야 할 규칙:
- 승인 이미지와 캐릭터 디자인을 임의로 바꾸지 않습니다.
- 기존 전투·건설·저장 기능을 삭제하지 않습니다.
- main.gd에 계속 몰아넣지 말고 모듈로 분리합니다.
- 인게임 첫 프레임에는 헬기 없이 군용 텐트 HQ만 있어야 합니다.
- 미구현을 완료로 보고하지 않습니다.

## 2. 완료 (렌더링 캡처로 확인)
| 항목 | 파일 |
|---|---|
| WASD 수정 | `scripts/main.gd` `_process()`: `_update_player`, `_harin_visual.update`, `_update_spawn`이 `return` 뒤에 잘못 들여쓰기되어 실행되지 않던 것을 수정했습니다. 물리 키 검사도 추가했습니다. |
| 로딩 화면 | `scripts/reclaim/flow/boot_screen.gd`: 승인 로딩 아트 위에 단계별 실제 진행바를 그립니다. |
| 메인 메뉴 | `main_menu_screen.gd`: 승인 메인 화면 위에 실제 버튼 4개를 같은 좌표로 올렸습니다. 훈장 강화 버튼도 유지했습니다. |
| 캐릭터 선택 | `character_select_screen.gd`: 승인 시트에서 자른 전신 입상 4장을 씁니다. |
| 난이도 | `difficulty_screen.gd`: 쉬움·보통·어려움·매우 어려움·지옥. |
| 프롤로그 | `prologue_screen.gd`: 3컷(해상 접근, 도심 상공, 강하 준비), 자막, 건너뛰기. |
| 착륙 연출 | `landing_sequence.gd`, `heli_art.gd`, `flow_sfx.gd`: 하강, 먼지, 하차, HQ 텐트 설치, 이륙 순서입니다. |
| 연결 | `scripts/main.gd`: 화면 상태 `boot`, `landing`을 추가했습니다. 이어하기와 저장은 유지했습니다. |
| 에셋 도구 | `tools/make_flow_assets.py`(승인 원본 크롭·배경 제거·로딩 진행바 지우기), `tools/make_flow_sfx.py`(효과음 합성), `tools/make_web_loading.py`(웹 로딩 셸) |
| 테스트 | `test/reclaim_smoke.gd`는 부팅 → 메뉴 → 선택 → 착륙 → 'D 키로 이동' 회귀 검사를 포함하며 통과합니다. `test/flow_capture.gd`는 Xvfb 캡처용입니다. |

## 3. 미완료 / 알려진 문제 (정직하게)
1. **`npm run check` 실패.** 원인은 `flow_sfx.gd`의 `AudioStreamWAV` 리소스가 종료 시 정리되지 않는 것입니다("resources still in use"). 노드 종료 시 `_rotor.stream = null`, `p.stream = null` 처리와 `STREAMS` 정리를 추가하면 될 것으로 예상하지만 검증하지 않았습니다. 스모크 테스트 자체는 PASS입니다.
2. **실행 영상(mp4) 없음.** 캡처 PNG만 있습니다(`/tmp`에 있었고 ZIP에는 미포함). 권장 방법은 `xvfb-run`으로 `test/flow_capture.gd`와 비슷한 스크립트를 돌리면서 ffmpeg `x11grab`으로 녹화하는 것입니다.
3. **Web 빌드 ZIP 미생성.** `npm run build` 후 `dist/standalone`을 압축합니다. Windows 내보내기 템플릿이 없어서 Windows exe는 못 만듭니다.
4. **README / TODO / PHASE1_STATUS 미갱신, 저장·푸시 미실행.** 마지막 저장본은 1차 checkpoint `dd626159`입니다. 이번 변경은 모두 커밋되지 않았습니다.
5. **프롤로그·헬기 그래픽은 임시(코드로 그린 도형)입니다.** 이미지 생성이 크레딧 부족으로 실패해서 승인 화풍의 정지 이미지 3장과 헬기 스프라이트가 없습니다. 효과음도 합성한 임시 사운드입니다.
6. **인게임 스프라이트는 서하린만 있습니다.** 강태준·윤시혁·한유진은 전투 중 임시 도형입니다.
7. **웹 로딩 셸 미검증.** `web/loading.html`을 승인 아트(base64)로 바꿨지만 실제 브라우저에서 확인하지 않았습니다.
8. **캐릭터 카드 크롭 미세 보정 필요.** 태준 크롭은 한 번 수정했지만 최종 확인하지 않았습니다.
9. **기존 경고.** 미사용 `assets/template/ui/loading-background.png`, `assets/template/audio/missing.ogg` 참조(테스트용), visualCoverage 0/8.
10. **미착수.** 좀비 5종 스프라이트, 기지 건설 그래픽, 포탑 7종, 나머지 3명의 인게임 스프라이트(이전 지시의 3~5차)는 시작하지 않았습니다.

## 4. 그래픽 시안·기준 자료 (`references/approved-art/`)
- `메인화면_승인참고.png` (1670x941): 메인 메뉴 기준. 버튼 4개가 그림에 포함되어 있어 코드 버튼의 위치 기준으로만 씁니다.
- `로딩화면_참고.png` (1673x940): 로딩 기준. "작전 준비 중... 78%" 진행 UI가 포함되어 있습니다.
- `강태준_승인원본.png`, `윤시혁_승인원본.png`, `서하린_한유진_승인시안.png`(상단 서하린, 하단 한유진), `한유진_전기톱_전투시안_v01.png`
- `좀비_기지_통합_승인시안.png`, `포탑_7종_5레벨_시안.png`, `인게임_고정기준.png`(인게임 분위기 참고용이며, 통째로 배경에 쓰면 안 됩니다)
- 원본 개발 패키지: `수도탈환작전.zip`(`기존_개발자료_v03/` 안에 명세와 승인 디자인이 있습니다).
- 생성 산출물: `assets/reclaim/ui/*`(승인 아트 원본 복사·로딩 아트는 진행바를 지운 것), `assets/reclaim/portraits/*`(크롭·배경 제거), `assets/reclaim/audio/*`(임시 효과음), `assets/reclaim/characters/harin_sheet.png`(서하린 스프라이트 시트), `assets/reclaim/world/*`(도심 지면·장식).

## 5. 다음 작업 순서 (크레딧 절약 권장)
1. 위 1번 누수를 고치고 `npm run check`로 통과를 확인합니다.
2. 영상 1개를 녹화합니다. 로딩 → 메뉴 → 캐릭터 → 난이도 → 프롤로그 → 착륙 → WASD 이동 → 사격 순서로 한 번에 찍습니다.
3. `npm run build` 후 ZIP을 만들고 문서를 갱신하고 저장합니다.
4. 그 다음에야 그래픽 보강(프롤로그 이미지, 헬기, 나머지 3명 스프라이트)에 들어갑니다. 한 번에 여러 장을 일괄 생성하는 것이 낫습니다.

## 6. 실행·검증 명령
- 헤드리스 테스트: `godot --headless --path . -s test/reclaim_smoke.gd`
- 렌더링 캡처: `xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 -s test/flow_capture.gd`
- 게임 프로젝트 도구: `npm run check`, `npm run preview:build`, `npm run build`
- 에셋 재생성: `python3 tools/make_flow_assets.py`, `python3 tools/make_flow_sfx.py`(Pillow, numpy 필요)
- 저장은 Manus webdev 런타임의 `save-release.mjs` 흐름을 따릅니다.
