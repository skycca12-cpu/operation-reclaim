extends RefCounted

const CELL := 48
const SIDE := 35
const HALF := 17
const LIMIT := Vector2.ONE * CELL * SIDE * 0.5
const TERRAIN: Texture2D = preload("res://assets/reclaim/jeju/terrain.png")
const HQ: Texture2D = preload("res://assets/reclaim/jeju/props/hq.png")
const PROP_DIR := "res://assets/reclaim/jeju/props/"
const LANDMARKS := [
	# Feet positions reference the approved composition, with an open central plaza.
	["jeju_shop", -565, -476, 195, 132, 55], ["convenience_store", -250, -635, 237, 175, 58],
	["shop_ruin", -660, -686, 173, 128, 50], ["ruin", 240, -679, 235, 165, 55],
	["gas_station", 512, -510, 195, 135, 54], ["lighthouse", 741, -663, 155, 89, 44],
	["traditional_house", -662, -103, 211, 150, 49], ["red_roof_house", -681, 184, 160, 102, 48],
	["greenhouse", -607, 443, 163, 118, 56], ["jeju_rock", -683, 731, 136, 82, 44],
	["bus", 668, 103, 202, 140, 58], ["car", 643, -433, 121, 91, 48],
	["ruin", 752, -233, 171, 111, 47], ["ruin", 769, 448, 152, 92, 42],
	["statue", 494, 528, 59, 39, 29], ["road_sign", 288, 721, 116, 93, 23],
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

var props: Array[Dictionary] = []
var decorations: Array[Dictionary] = []
var colliders: Array[Rect2] = []
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
	if footprint.x > 0:
		colliders.append(Rect2(feet - Vector2(footprint.x * 0.5, footprint.y), footprint))
	if key.begins_with("farm_") or key in ["tire_marks", "parking_lines", "wave", "rubble"]:
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
	return [7, 7, 1, 3, 12, 7, 4, 7, 0, 13, 5, 7, 1][posmod(cell.x * cell.x * 5 + cell.y * cell.y * 7 + cell.x * cell.y, 13)]


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
