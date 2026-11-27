# operation-reclaim
## 개발 프로젝트

`game/`이 개발 기준입니다. Godot 4.7.2에서 `game/project.godot`을 열고 실행합니다. 루트의 ZIP 두 개와 인수인계 문서는 원본 백업입니다.

Godot이 설치된 환경에서는 저장소 루트에서 다음 명령으로 가져오기와 스모크 테스트를 실행할 수 있습니다.

```sh
godot --headless --path game --editor --import
godot --headless --path game -s test/reclaim_smoke.gd
```

`npm run check`는 Manus 검증 런타임(`GAME_RUNTIME`)을 사용합니다.
