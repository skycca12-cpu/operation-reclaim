extends RefCounted

const PATH := "res://config/augments_500.json"
const RARITIES := ["일반", "고급", "희귀", "영웅", "전설", "신화"]
# First Jeju playtest rotation. The archive and existing acquisitions keep their original IDs.
const PLAYTEST_IDS := ["A001", "A003", "A011", "A021", "A022", "A023", "A027", "A028",
	"A029", "A030", "A035", "A047", "A053", "A063", "A073", "A077", "A078",
	"A081", "A085", "A091", "A101"]
static var _cards: Array[Dictionary] = []


static func cards() -> Array[Dictionary]:
	if _cards.is_empty():
		var rows: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if not rows is Array:
			push_error("Could not load the integrated augment catalog.")
			return _cards
		for original in rows:
			var card: Dictionary = original
			card.rarity = RARITIES[int(card.stars) - 1]
			_cards.append(card)
	return _cards


static func description(card: Dictionary) -> String:
	var suffix: String = "개" if card.unit == "개" else card.unit
	if card.key == "magazine": suffix = "발"
	var text := "%s +%s%s · 최대 %d회" % [card.effect, str(card.amount), suffix, card.limit]
	if String(card.trigger) != "":
		text += "\n관련 행동 후 5초"
	return text
