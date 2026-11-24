extends RefCounted

const CELL := 48
const SIDE := 45
const HALF := (SIDE - 1) / 2
const LIMIT := Vector2.ONE * CELL * SIDE * 0.5
const TERRAIN: Texture2D = preload("res://assets/reclaim/jeju/terrain.png")
const HQ: Texture2D = preload("res://assets/reclaim/jeju/props/hq.png")
const PROP_DIR := "res://assets/reclaim/jeju/props/"
const LANDMARKS := [
	# Feet positions reference the approved composition, with an open central plaza.
	["jeju_shop", -565, -476, 228, 132, 55], ["convenience_store", -250, -635, 268, 175, 58],
	["shop_ruin", -660, -686, 173, 128, 50], ["ruin", 240, -679, 235, 165, 55],
	["gas_station", 512, -510, 220, 135, 54], ["lighthouse", 741, -663, 155, 89, 44],
	["traditional_house", -662, -103, 243, 150, 49], ["red_roof_house", -681, 184, 186, 102, 48],
	["greenhouse", -607, 443, 187, 118, 56], ["jeju_rock", -683, 731, 136, 82, 44],
	["bus", 668, 103, 223, 140, 58], ["car", 643, -433, 121, 91, 48],
	["ruin", 752, -233, 171, 111, 47], ["ruin", 769, 448, 152, 92, 42],
	["statue", 494, 528, 69, 39, 29], ["road_sign", 288, 721, 116, 93, 23],
	["orange_tree", -566, -692, 101, 23, 24], ["orange_tree_small", -524, -125, 92, 24, 25],
	["orange_tree", 412, -624, 108, 24, 24], ["orange_tree_small", 719, -87, 98, 27, 25],
	["tree", -784, 492, 104, 28, 24], ["palms", 648, -620, 82, 20, 22], ["palm_small", 606, 449, 70, 19, 20],
	["lamp", -563, -341, 43, 13, 15], ["lamp", -462, 146, 43, 13, 15],
	["lamp", 602, -23, 43, 13, 15], ["lamp", 453, 421, 43, 13, 15],
	["utility_pole", -279, 679, 40, 14, 15], ["utility_pole", 195, 700, 40, 14, 15],
	["stone_wall", -632, -55, 163, 153, 22], ["wall", -688, 313, 150, 142, 23],
	["wall", 531, -657, 145, 134, 22], ["stone_wall", -503, 647, 130, 120, 20],
	["barrels", 707, -355, 56, 41, 20], ["crates", -447, -406, 67, 50, 24],
	["crates", 312, 393, 67, 50, 24], ["barricade", -136, 710, 66, 55, 18],
	["barricade", 129, 710, 66, 55, 18], ["flowers", -747, -345, 117, 0, 0],
	["flowers", -578, 721, 95, 0, 0], ["rubble", 442, 211, 73, 0, 0],
	["rubble", -328, 340, 66, 0, 0], ["tire_marks", -283, -244, 105, 0, 0],
	["tire_marks", -333, 399, 101, 0, 0], ["parking_lines", 673, 215, 168, 0, 0],
	["farm_0", -758, 539, 119, 0, 0], ["farm_1", -630, 576, 119, 0, 0],
	["farm_2", -519, 546, 119, 0, 0], ["farm_3", -758, 596, 119, 0, 0],
	["farm_4", -631, 634, 119, 0, 0], ["farm_5", -505, 607, 119, 0, 0],
	["shop_blue", -787, -495, 142, 111, 47], ["shop_red", -123, -780, 150, 112, 48],
	["shop_yellow", 407, -779, 148, 111, 44], ["car_wreck", 717, 317, 100, 74, 34],
	["truck_wreck", 757, -481, 124, 88, 36], ["van_wreck", -769, 64, 91, 65, 32],
	["bus_wreck", 802, 121, 133, 96, 45], ["statue_profile", 422, 572, 50, 26, 22],
	["stone_wall", -767, 267, 128, 118, 20], ["stone_wall", -657, 486, 133, 120, 18],
	["wall", -476, 699, 143, 126, 21], ["wall", 408, 621, 133, 121, 20],
	["tree", 712, -719, 104, 24, 24], ["orange_tree", -758, -153, 120, 24, 23],
	["orange_tree_small", -785, 269, 101, 22, 22], ["flowers", 746, 498, 116, 0, 0],
	["flowers", -796, 705, 149, 0, 0], ["flowers", 460, -704, 115, 0, 0],
	["rubble", 365, -403, 70, 0, 0], ["rubble", -459, 247, 66, 0, 0],
	["seawall_long", 614, 704, 115, 0, 0], ["seawall_corner", 765, 611, 121, 0, 0],
	["driftwood", 754, 693, 59, 0, 0], ["boat", 735, 771, 78, 0, 0],
]

# Dressing follows each landmark's frontage, shoreline or garden. The low
# vegetation and weathering have no gameplay footprint.
const COURTYARD_DRESSING := {
	"pink_flowers": [
		[-715,-480,86], [-627,-465,74], [-812,-400,91], [-727,-616,71], [590,-627,64], [736,-548,84],
	],
	"flowers": [
		[-812,-688,136], [-736,-725,117], [-488,-704,88], [-338,-610,109],
		[318,-669,114], [534,-719,98], [652,-719,119], [788,-620,116],
		[-792,-308,129], [-707,-271,91], [-794,-111,121], [-556,-73,73],
		[-792,142,115], [-747,206,92], [-608,215,102], [-781,357,108],
		[-703,389,118], [-544,449,85], [-793,613,112], [-674,670,129],
		[-757,799,144], [-458,757,126], [-369,818,116], [269,811,106],
		[439,727,108], [548,661,102], [664,538,93], [796,449,128],
		[794,238,120], [803,-148,107], [709,-175,91], [710,-358,78],
	],
	"yellow_hedge": [
		[-783,-575,90], [-465,-547,70], [324,-596,103], [464,-557,74], [745,-600,93],
		[-586,-34,106], [-666,241,110], [-742,453,97], [-533,683,98],
		[488,655,102], [590,581,99], [705,501,96], [808,230,99],
	],
	"orange_tree_small": [
		[-806,-247,114], [-762,166,98], [-535,586,89], [367,-685,100],
		[659,-584,98], [796,47,105], [808,356,92],
	],
	"stone_wall": [
		[-803,-524,120], [-691,-446,102], [-485,-621,111], [350,-630,123],
		[617,-646,124], [-765,-189,103], [-789,-49,92], [-568,-55,115],
		[-782,295,118], [-562,263,124], [-559,470,111], [-594,712,122],
		[-408,796,121], [293,806,117], [429,648,120], [754,389,105],
	],
	"wood_fence": [
		[446,684,93], [513,648,93], [582,604,93], [650,564,93], [715,519,93],
		[778,501,88], [-786,451,98], [-700,448,84], [-566,494,91],
	],
	"coast_boulder": [
		[620,762,98], [675,821,109], [806,713,95], [832,830,130], [810,-788,122],
		[682,-788,97], [-768,807,118], [-604,816,95],
	],
	"crates": [
		[-688,-514,53], [-456,-518,44], [-352,-605,67], [-160,-613,54],
		[275,-590,58], [571,-483,45], [-560,-105,45], [-491,152,43],
		[-475,531,57], [-389,681,54], [389,455,55], [802,294,59],
	],
	"barrels": [
		[-449,-482,44], [-166,-582,47], [623,-469,41], [788,-352,52],
		[643,113,43], [-493,568,42], [471,576,44],
	],
	"barricade": [
		[-309,-381,53], [-251,-388,51], [281,-501,61], [348,-488,54],
		[515,115,65], [574,106,57],
	],
	"weeds": [
		[-466,-352,63], [-399,-309,38], [-342,-464,35], [-166,-454,48], [54,-543,56],
		[196,-415,56], [331,-324,71], [468,-291,51], [512,-183,59], [-445,-176,42],
		[-383,93,53], [-340,246,54], [-421,335,43], [373,250,44], [486,344,62],
		[82,343,41], [-151,442,52], [-242,553,61], [48,626,37], [260,637,62],
		[-341,782,87], [189,782,56], [356,785,63],
	],
	"ground_broken": [
		[-446,-310,80], [-331,-420,55], [-170,-378,63], [114,-374,65], [254,-332,59],
		[413,-234,66], [530,-118,76], [550,231,71], [352,312,73], [153,419,68],
		[-149,407,77], [-178,478,49], [-390,215,67], [-505,22,83], [33,571,52],
	],
	"loose_rocks": [
		[-610,-316,61], [-445,-323,44], [-278,-375,35], [248,-320,47],
		[508,-225,52], [491,224,62], [308,379,43], [-159,421,56], [-375,310,46],
	],
	"ground_stain": [[-271,-140,43], [209,-167,37], [341,49,53], [-280,335,58], [71,449,46], [379,-368,31]],
}
const FLAT_PROPS := ["tire_marks", "parking_lines", "wave", "rubble", "weeds", "ground_broken", "loose_rocks", "ground_stain"]

var props: Array[Dictionary] = []
var decorations: Array[Dictionary] = []
var colliders: Array[Rect2] = []
var lamps: Array[Vector2] = []
var tiles: TileMapLayer
var border: ColorRect
var _textures: Dictionary = {}


func setup(parent: CanvasItem) -> void:
	border = ColorRect.new()
	border.color = Color("#231f24")
	border.show_behind_parent = true
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.hide()
	parent.add_child(border)
	tiles = TileMapLayer.new()
	tiles.name = "JejuTerrain"
	tiles.show_behind_parent = true
	tiles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tiles.hide()
	var atlas := TileSetAtlasSource.new()
	atlas.texture = TERRAIN
	atlas.texture_region_size = Vector2i(CELL, CELL)
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(CELL, CELL)
	var source := tileset.add_source(atlas)
	for tile in range(15):
		atlas.create_tile(Vector2i(tile, 0))
	tiles.tile_set = tileset
	parent.add_child(tiles)
	for y in range(-HALF, HALF + 1):
		for x in range(-HALF, HALF + 1):
			var cell := Vector2i(x, y)
			tiles.set_cell(cell, source, Vector2i(_terrain_tile(cell), 0))
			if _water(cell) and not _water(Vector2i(x - 1, y)):
				var shore := Vector2(cell * CELL)
				_add_prop(["cliff_turn" if y % 3 == 0 else "cliff", shore.x - 14, shore.y + 20, 67, 0, 0])
				_add_prop(["wave", shore.x + 25, shore.y + 30, 49, 0, 0])
	for entry in LANDMARKS:
		_add_prop(entry)
	for key in COURTYARD_DRESSING:
		for placement in COURTYARD_DRESSING[key]:
			_add_prop([key, placement[0], placement[1], placement[2], 0, 0])
	_add_prop(["coast_wall", 698, 600, 139, 0, 0])
	_add_prop(["coast_rocks", 774, 784, 57, 0, 0])


func _add_prop(entry: Array) -> void:
	var key: String = entry[0]
	if not _textures.has(key):
		_textures[key] = load(PROP_DIR + key + ".png")
	var texture: Texture2D = _textures[key]
	var feet := Vector2(entry[1], entry[2])
	var extent := texture.get_size() * (float(entry[3]) / texture.get_width())
	var footprint := Vector2(entry[4], entry[5])
	var record := {"texture": texture, "feet": feet, "size": extent}
	if key == "lamp":
		lamps.append(feet)
	if footprint.x > 0:
		colliders.append(Rect2(feet - Vector2(footprint.x * 0.5, footprint.y), footprint))
	if key.begins_with("farm_") or key in FLAT_PROPS:
		decorations.append(record)
	else:
		props.append(record)


func _terrain_tile(cell: Vector2i) -> int:
	if _water(cell): return 14
	if (cell.y >= 10 or cell.y <= -12) and absi(cell.x) <= 1:
		return 9 if cell.x == 0 else 8
	if (absi(cell.x) == 6 and absi(cell.y) <= 1) or (absi(cell.y) == 10 and absi(cell.x) <= 1):
		return 11
	if abs(cell.x) >= 10 or abs(cell.y) >= 13:
		return [0, 1, 2, 3, 4, 5, 6, 12, 13][posmod(cell.x * 7 + cell.y * 11, 9)]
	return [7, 7, 1, 7, 12, 7, 4, 7, 0, 7, 5, 7, 1][posmod(cell.x * cell.x * 5 + cell.y * cell.y * 7 + cell.x * cell.y, 13)]


func _water(cell: Vector2i) -> bool:
	return (cell.y >= 10 and cell.x >= 17 - (cell.y - 10)) or (cell.y <= -15 and cell.x >= 14 + (cell.y + 15))


func align(camera: Vector2, viewport: Vector2, zoom: float, shown: bool) -> void:
	if tiles == null: return
	tiles.visible = shown
	border.visible = shown
	if shown:
		border.size = viewport
		tiles.scale = Vector2.ONE * zoom
		tiles.position = viewport * 0.5 - (camera + Vector2.ONE * CELL * 0.5) * zoom


func walkable(point: Vector2, margin: float = 0.0) -> bool:
	if absf(point.x) + margin >= LIMIT.x or absf(point.y) + margin >= LIMIT.y:
		return false
	for offset in [Vector2(-margin, -margin), Vector2(margin, -margin), Vector2(-margin, margin), Vector2(margin, margin)]:
		if _water(Vector2i(((point + offset) / CELL).round())):
			return false
	for footprint in colliders:
		if footprint.grow(margin).has_point(point):
			return false
	return true


func nearest_land(point: Vector2, margin: float) -> Vector2:
	var candidate := point.clamp(-LIMIT + Vector2.ONE * (margin + 2.0), LIMIT - Vector2.ONE * (margin + 2.0))
	if walkable(candidate, margin):
		return candidate
	var cell := Vector2i((candidate / CELL).round())
	var distance := INF
	var best := Vector2.ZERO
	# Starts and legacy saves can lie outside the new map.
	for y in range(-HALF, HALF + 1):
		for x in range(-HALF, HALF + 1):
			var next := Vector2(Vector2i(x, y) * CELL)
			var cost := Vector2(cell * CELL).distance_squared_to(next)
			if cost < distance and walkable(next, margin):
				best = next
				distance = cost
	return best


static func draw_prop(canvas: CanvasItem, prop: Dictionary, camera_offset: Vector2) -> void:
	var extent: Vector2 = prop.size
	var feet: Vector2 = prop.feet
	canvas.draw_texture_rect(prop.texture, Rect2(feet + camera_offset - Vector2(extent.x * 0.5, extent.y), extent), false)
