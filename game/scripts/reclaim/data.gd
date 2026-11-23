extends RefCounted

const CHARACTERS: Array[Dictionary] = [
	{"id": "tae", "name": "강태준", "weapon": "산탄총 · 방패", "hp": 140.0, "speed": 225.0, "damage": 16.0, "rate": 1.05, "range": 390.0, "pellets": 5, "magazine": 6, "reload": 1.55, "color": Color("#85a78e"), "special": "산탄 5발 · 받는 피해 감소"},
	{"id": "si", "name": "윤시혁", "weapon": "돌격소총", "hp": 105.0, "speed": 250.0, "damage": 20.0, "rate": 0.17, "range": 510.0, "pellets": 1, "magazine": 30, "reload": 1.8, "color": Color("#64a4a0"), "special": "빠른 연사 · 긴 사거리"},
	{"id": "harin", "name": "서하린", "weapon": "M4 계열 소총 · 드론", "hp": 100.0, "speed": 260.0, "damage": 18.0, "rate": 0.19, "range": 520.0, "pellets": 1, "magazine": 30, "reload": 1.7, "color": Color("#be7995"), "special": "30발 탄창 · 지원 드론"},
	{"id": "yujin", "name": "한유진", "weapon": "전기톱 · 공병", "hp": 115.0, "speed": 245.0, "damage": 22.0, "rate": 0.20, "range": 115.0, "pellets": 1, "magazine": 0, "reload": 0.0, "color": Color("#d39a55"), "special": "전방 90° 지속 절단 · 포탑 강화"}
]

const DIFFICULTIES: Array[Dictionary] = [
	{"id": "easy", "label": "쉬움", "hp": 0.7, "attack": 0.7, "spawn": 0.8},
	{"id": "normal", "label": "보통", "hp": 1.0, "attack": 1.0, "spawn": 1.0},
	{"id": "hard", "label": "어려움", "hp": 1.2, "attack": 1.15, "spawn": 1.2},
	{"id": "very_hard", "label": "매우 어려움", "hp": 1.5, "attack": 1.3, "spawn": 1.4},
	{"id": "hell", "label": "지옥", "hp": 1.8, "attack": 1.5, "spawn": 1.6}
]

const ENEMIES: Dictionary = {
	"normal": {"name": "일반", "intro": 1, "hp": 100.0, "speed": 54.0, "attack": 7.0, "color": Color("#b4aaa0"), "ranged": false},
	"runner": {"name": "질주", "intro": 10, "hp": 70.0, "speed": 96.0, "attack": 6.0, "color": Color("#d4bd65"), "ranged": false},
	"bomber": {"name": "자폭", "intro": 20, "hp": 42.0, "speed": 64.0, "attack": 36.0, "color": Color("#de715c"), "ranged": false},
	"spitter": {"name": "독액 투사", "intro": 25, "hp": 80.0, "speed": 43.0, "attack": 8.0, "color": Color("#83bc72"), "ranged": true},
	"brute": {"name": "괴력", "intro": 35, "hp": 250.0, "speed": 36.0, "attack": 16.0, "color": Color("#897a77"), "ranged": true}
}

const BOSSES: Dictionary = {
	40: {"name": "철갑 포식자", "hp": 9500.0, "speed": 37.0, "attack": 24.0, "color": Color("#9d6575"), "pattern": "방어"},
	80: {"name": "파쇄자", "hp": 18000.0, "speed": 32.0, "attack": 34.0, "color": Color("#c27854"), "pattern": "철거"},
	100: {"name": "군체 지배자", "hp": 30000.0, "speed": 30.0, "attack": 45.0, "color": Color("#b24962"), "pattern": "군체"}
}

const TURRETS: Array[Dictionary] = [
	{"id": "basic", "name": "기본 자동포탑", "short": "기본", "cost": 34, "damage": 24.0, "rate": 0.70, "range": 350.0, "color": Color("#a7c08b"), "role": "균형"},
	{"id": "heavy", "name": "중기관총", "short": "중기관총", "cost": 42, "damage": 12.0, "rate": 0.23, "range": 320.0, "color": Color("#e0b85e"), "role": "연사"},
	{"id": "rocket", "name": "로켓 포탑", "short": "로켓", "cost": 58, "damage": 118.0, "rate": 2.30, "range": 440.0, "color": Color("#d87c60"), "role": "범위 폭발"},
	{"id": "electric", "name": "전기 포탑", "short": "전기", "cost": 50, "damage": 42.0, "rate": 1.15, "range": 335.0, "color": Color("#71c8d1"), "role": "연쇄"},
	{"id": "flame", "name": "화염 포탑", "short": "화염", "cost": 46, "damage": 11.0, "rate": 0.16, "range": 215.0, "color": Color("#ef9154"), "role": "지속 광역"},
	{"id": "freeze", "name": "냉각 포탑", "short": "냉각", "cost": 44, "damage": 9.0, "rate": 0.82, "range": 305.0, "color": Color("#9cdbe1"), "role": "감속"},
	{"id": "repair", "name": "수리 포탑", "short": "수리", "cost": 55, "damage": 0.0, "rate": 1.25, "range": 300.0, "color": Color("#7ed99a"), "role": "건물·방벽 회복"}
]

const BUILDINGS: Array[Dictionary] = [
	{"id": "clinic", "name": "의료소", "short": "의료", "cost": 76, "hp": 520.0, "role": "근처 생존자 회복"},
	{"id": "supply", "name": "보급소", "short": "보급", "cost": 74, "hp": 580.0, "role": "주기적 전투 재화"},
	{"id": "workshop", "name": "정비제작소", "short": "정비", "cost": 84, "hp": 650.0, "role": "포탑 성능 보조"},
	{"id": "research", "name": "연구소", "short": "연구", "cost": 96, "hp": 520.0, "role": "증강 경험 보조"},
	{"id": "outpost", "name": "초소", "short": "초소", "cost": 82, "hp": 610.0, "role": "가까운 적 자동 견제"}
]

const PERMANENT_PERKS: Array[Dictionary] = [
	{"id": "damage", "name": "공격력", "step": 0.06},
	{"id": "health", "name": "최대 체력", "step": 15.0},
	{"id": "range", "name": "공격 범위", "step": 0.05},
	{"id": "speed", "name": "이동 속도", "step": 0.04},
	{"id": "build", "name": "건설 비용 절감", "step": 0.04},
	{"id": "building_hp", "name": "건물 내구도", "step": 0.08},
	{"id": "reload", "name": "연사 속도", "step": 0.04},
	{"id": "salvage", "name": "재화 획득량", "step": 0.05}
]

static func augment_catalog() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var common_names: Array[String] = [
		"정밀 조준", "탄약 절약", "전술 탄두", "반동 제어", "확장 탄창", "관통 탄환", "급속 장전", "사거리 조정", "야전 의무", "방탄판 보강",
		"기동 훈련", "전투 식량", "현장 수리", "금속 회수", "보급 계약", "폭발물 숙련", "전력 증폭", "냉각 효율", "화염 노즐", "포탑 베어링",
		"경계 태세", "방어 각도", "야전 제작", "지형 감각", "엄호 사격", "신속 배치", "고밀도 장갑", "전술 분석", "강화 조준기", "긴급 후송"
	]
	var effects: Array[String] = ["damage", "rate", "projectile", "damage", "rate", "pierce", "rate", "range", "health", "armor", "speed", "xp", "building_hp", "salvage", "salvage", "damage", "turret_damage", "range", "damage", "turret_rate", "armor", "building_hp", "build", "speed", "damage", "build", "building_hp", "xp", "range", "health"]
	for i in range(common_names.size()):
		out.append({"id": "common_%02d" % i, "name": common_names[i], "effect": effects[i], "description": _effect_description(effects[i])})
	var hero_names: Dictionary = {
		"tae": ["방패 밀어내기", "산탄 확산", "강철 진형", "충격 완화", "최후 방어"],
		"si": ["속사 교리", "전술 재장전", "점사 제어", "철갑탄", "선봉 돌파"],
		"harin": ["드론 호출", "M4 정비", "정밀 호버", "탄약 링크", "엄호 비행"],
		"yujin": ["전기톱 톱날", "현장 개조", "긴급 정비", "포탑 조율", "공병 지휘"]
	}
	var hero_effects: Dictionary = {
		"tae": ["armor", "projectile", "health", "armor", "damage"],
		"si": ["rate", "reload", "damage", "pierce", "speed"],
		"harin": ["drone", "damage", "range", "rate", "turret_damage"],
		"yujin": ["damage", "build", "building_hp", "turret_damage", "turret_rate"]
	}
	for hero_id: String in hero_names.keys():
		for i in range(5):
			var effect_id: String = hero_effects[hero_id][i]
			out.append({"id": "%s_%02d" % [hero_id, i], "name": hero_names[hero_id][i], "effect": effect_id, "description": _effect_description(effect_id)})
	return out

static func _effect_description(effect_id: String) -> String:
	match effect_id:
		"damage": return "플레이어 공격 피해 증가"
		"rate": return "플레이어 공격 속도 증가"
		"reload": return "재장전 시간 단축"
		"projectile": return "산탄 수 또는 연쇄 대상 증가"
		"pierce": return "탄환 관통 성능 증가"
		"range": return "플레이어·포탑 사거리 증가"
		"health": return "최대 체력 증가 및 일부 회복"
		"armor": return "받는 피해 감소"
		"speed": return "이동 속도 증가"
		"xp": return "경험치 획득량 증가"
		"building_hp": return "건물·방벽 내구도 증가"
		"salvage": return "전투 재화 획득량 증가"
		"turret_damage": return "포탑 피해 증가"
		"turret_rate": return "포탑 공격 속도 증가"
		"build": return "건설 비용 감소"
		"drone": return "추가 지원 사격"
	return "작전 능력 강화"
