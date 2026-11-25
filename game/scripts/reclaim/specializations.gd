extends RefCounted

const LEVELS := [1, 4, 8, 14]
const PATHS := {
	"tae": [
		{"id": "shield", "name": "방패 돌진", "summary": "적 무리 사이에 길을 냅니다.", "tiers": [
			["방패 돌진 피해 +30%", "shield_damage", 30.0],
			["방패 돌진 재사용 -2초", "skill_cooldown", 2.0],
			["Q 타격 폭 +20", "shield_width", 10.0],
			["쓰러진 적의 회복 +0.3초", "shield_down", 0.3]]},
		{"id": "scatter", "name": "산탄 제압", "summary": "가까운 적을 넓게 제압합니다.", "tiers": [
			["산탄 확산 폭 +20%", "shotgun_spread", 20.0],
			["한 발당 산탄 +1", "pellets", 1.0],
			["Q 돌진이 대상을 0.3초 더 넘어뜨림", "shield_down", 0.3],
			["산탄에 맞은 적이 1초간 느려짐", "shotgun_slow", 1.0]]},
		{"id": "defense", "name": "기지 수비", "summary": "시설을 지키며 기지 가까이에서 싸웁니다.", "tiers": [
			["지휘본부가 받는 피해 -12%", "hq_armor", 12.0],
			["방벽이 받는 피해 -15%", "wall_armor", 15.0],
			["기지 근처에서 Q 사용 시 본부 내구도 6% 회복", "shield_repair", 6.0],
			["기지 근처 공격 피해 +15%", "base_damage", 15.0]]}],
	"si": [
		{"id": "focus", "name": "집중 연사", "summary": "강한 적 하나에 화력을 집중합니다.", "tiers": [
			["공격 속도 +8%", "rate", 8.0],
			["공격력 +8%", "damage", 8.0],
			["Q 집중 사격 중 공격 속도 추가 증가", "focus_rate", 20.0],
			["집중 사격 지속 +2초", "skill_duration", 2.0]]},
		{"id": "penetration", "name": "관통 사격", "summary": "일렬로 몰리는 적을 정리합니다.", "tiers": [
			["탄환 관통 +1", "pierce", 1.0],
			["탄환 속도 +20%", "projectile_speed", 20.0],
			["Q 집중 사격 중 관통 +2", "active_pierce", 2.0],
			["탄환 관통 추가 +1", "pierce", 1.0]]},
		{"id": "reload", "name": "재장전 사격", "summary": "짧은 재장전 사이에 화력을 몰아칩니다.", "tiers": [
			["재장전 속도 +20%", "reload", 20.0],
			["재장전 후 5초간 피해 +12%", "after_reload", 12.0],
			["Q 사용 즉시 탄창을 채움", "focus_refill", 1.0],
			["재장전 후 피해 추가 +15%", "after_reload", 15.0]]}],
	"harin": [
		{"id": "ricochet", "name": "도탄 사격", "summary": "흩어진 적 사이로 총알을 튕깁니다.", "tiers": [
			["탄환 도탄 +1", "ricochet", 1.0],
			["공격력 +8%", "damage", 8.0],
			["Q 드론 과부하 중 소총 도탄 +1", "active_ricochet", 1.0],
			["탄환 도탄 추가 +1", "ricochet", 1.0]]},
		{"id": "drone", "name": "드론 화력", "summary": "드론의 지속 화력을 높입니다.", "tiers": [
			["드론 피해 +20%", "combat_drone_damage", 20.0],
			["드론 공격 속도 +15%", "combat_drone_rate", 15.0],
			["Q 드론 과부하 지속 +2초", "skill_duration", 2.0],
			["드론 피해 추가 +25%", "combat_drone_damage", 25.0]]},
		{"id": "cover", "name": "드론 엄호", "summary": "드론이 몸 가까이 붙는 적을 견제합니다.", "tiers": [
			["근접 표적에 드론이 0.8초 감속 부여", "drone_slow", 0.8],
			["감속 시간 +0.4초", "drone_slow", 0.4],
			["Q 드론 과부하 중 감속 시간 +0.8초", "drone_active_slow", 0.8],
			["드론 과부하 재사용 -3초", "skill_cooldown", 3.0]]}],
	"yujin": [
		{"id": "endurance", "name": "지속 절단", "summary": "과열을 늦춰 전기톱을 오래 돌립니다.", "tiers": [
			["전기톱 발열 -20%", "saw_heat", 20.0],
			["공격 속도 +10%", "rate", 10.0],
			["Q 강제 냉각 후 3초간 발열 없음", "cooling_window", 3.0],
			["전기톱 발열 추가 -15%", "saw_heat", 15.0]]},
		{"id": "sweep", "name": "광역 절단", "summary": "전기톱을 넓게 휘둘러 밀집한 적을 처리합니다.", "tiers": [
			["절단 각도 +25%", "saw_angle", 25.0],
			["절단 피해 +10%", "damage", 10.0],
			["Q 강제 냉각 후 4초간 절단 각도 추가 +35%", "sweep_window", 4.0],
			["전기톱 도달 거리 +12%", "range", 12.0]]},
		{"id": "repair", "name": "현장 정비", "summary": "절단 처치로 무너지는 기지를 수리합니다.", "tiers": [
			["5회 대신 4회 처치로 시설 수리", "repair_kills", 1.0],
			["수리 시 최대 내구도 추가 4% 회복", "repair_percent", 4.0],
			["Q 강제 냉각 시 인근 시설 즉시 수리", "vent_repair", 1.0],
			["현장 수리 대상에 지휘본부 포함", "repair_hq", 1.0]]}],
}


static func find_path(hero: String, id: String) -> Dictionary:
	for path: Dictionary in PATHS[hero]:
		if path.id == id:
			return path
	return {}


static func bonuses(path: Dictionary, level: int) -> Dictionary:
	var result := {}
	for i in range(LEVELS.size()):
		if level < LEVELS[i] or path.is_empty():
			break
		var tier: Array = path.tiers[i]
		result[tier[1]] = float(result.get(tier[1], 0.0)) + float(tier[2])
	return result
