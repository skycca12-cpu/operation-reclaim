extends RefCounted

# Initial playtest values for the confirmed operator concepts.
const SHIELD_COOLDOWN := 12.0
const SHIELD_DAMAGE := 45.0
const FOCUS_COOLDOWN := 18.0
const FOCUS_DURATION := 5.0
const FOCUS_RATE := 1.45
const DRONE_COOLDOWN := 18.0
const DRONE_DURATION := 6.0
const DRONE_RATE := 2.0
const VENT_COOLDOWN := 15.0
const SAW_HEAT_PER_SECOND := 23.0
const SAW_COOL_PER_SECOND := 27.0
const SAW_OVERHEAT_OUTPUT := 0.55
const YUJIN_TURRET_DAMAGE := 1.15
const SAW_REPAIR_KILLS := 5

const PROFILES := {
	"tae": ["방패 돌진", "방패로 적을 밀쳐 넘어뜨리고 피해 45 · 기본 피해 12% 감소"],
	"si": ["집중 사격", "5초 동안 공격 속도 +45% · 기본 고속 연사 소총"],
	"harin": ["전술 드론 과부하", "전술 드론 상시 동행 · 6초 동안 드론 연사 2배"],
	"yujin": ["강제 냉각", "전기톱 열기 제거 · 연속 절단 가속 · 포탑 피해 +15% · 5회 처치마다 인근 시설 수리"],
}
