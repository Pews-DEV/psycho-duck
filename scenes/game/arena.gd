class_name Arena
extends Node2D
## Cenário montado com o Tileset.png original: grama, pedras e pilhas de caixas.
## Na partida, cresce a cada 10 ondas (expand()): mais chão para os lados e plataformas
## finas de pedra para subir. No menu, fica no estágio 0 com as caixas de `crates`.

signal expanded(stage: int)

const TILESET_TEXTURE := preload("res://assets/sprites/environment/Tileset.png")
const HOUSE_TEXTURE := preload("res://assets/sprites/environment/home-market.png")
const TILE := 16
## A arena cresce igualmente para os dois lados a partir daqui (centro da casinha).
const CENTER_X := 160.0
## Largura em tiles de cada estágio; o último é o teto.
const STAGE_COLUMNS: Array[int] = [24, 30, 38, 46]
## Plataformas que cada estágio acrescenta: [x inicial, x final, altura acima do chão] em px.
## Cada degrau fica a 24 px do anterior, dentro do alcance de um pulo (~29 px).
const STAGE_LEDGES := [
	[],
	[[-8, 40, 24], [280, 328, 24], [40, 88, 48], [232, 280, 48]],
	[[-88, -40, 24], [360, 408, 24], [-56, -8, 48], [328, 376, 48]],
	[[-168, -120, 24], [440, 488, 24], [96, 224, 72]],
]
## Chão decorativo além das caixas: a tela (480 px) é mais larga que a arena no começo.
const GROUND_COLUMNS := Vector2i(-24, 44)
const LEDGE_THICKNESS := 4.0
## Camada física 7 ("platforms"): só o pato colide; tiros atravessam.
const PLATFORM_LAYER := 64

const GRASS_TILES: Array[Vector2i] = [Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3)]
const STONE_TILES: Array[Vector2i] = [Vector2i(2, 4), Vector2i(3, 4), Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4)]
const CRATE_TILE := Vector2i(6, 2)

## Altura (em px) da superfície da grama.
@export var ground_y := 156.0
@export var with_house := true
## Pilhas de caixas automáticas nas bordas, que acompanham a expansão (partida).
@export var edge_crates := true
## Caixas fixas quando edge_crates é falso: (coluna, altura a partir de 1).
@export var crates: Array[Vector2i] = []

var stage := 0
var tiles: TileMapLayer

var _ground_row := 0
var _crate_cells: Array[Vector2i] = []
var _left_wall: StaticBody2D
var _right_wall: StaticBody2D


func _ready() -> void:
	add_to_group(&"arena")
	tiles = TileMapLayer.new()
	tiles.tile_set = _make_tileset()
	# A grade é de 16 px; desloca a camada para a grama começar exatamente em ground_y.
	_ground_row = int(ground_y / TILE) + 1
	tiles.position.y = ground_y - _ground_row * TILE
	add_child(tiles)

	for col in range(GROUND_COLUMNS.x, GROUND_COLUMNS.y):
		_fill_ground_column(col)
	_place_crates()
	for s in range(1, stage + 1):
		for spec in STAGE_LEDGES[s]:
			_add_ledge(spec, false)

	if with_house:
		var house := Sprite2D.new()
		house.texture = HOUSE_TEXTURE
		house.centered = false
		house.position = Vector2(CENTER_X - HOUSE_TEXTURE.get_width() / 2.0, ground_y - HOUSE_TEXTURE.get_height())
		house.z_index = -1
		add_child(house)
		# Luminoso da casinha iluminando o chão.
		var sign_light := Fx.make_light(Color("ffb35c"), 90.0, 1.1)
		sign_light.position = Vector2(CENTER_X, ground_y - 36)
		add_child(sign_light)

	_left_wall = _make_wall()
	_right_wall = _make_wall()
	_update_walls()


# --- Limites -----------------------------------------------------------------

func columns() -> int:
	return STAGE_COLUMNS[stage]


func left() -> float:
	return CENTER_X - columns() * TILE / 2.0


func right() -> float:
	return CENTER_X + columns() * TILE / 2.0


## (esquerda, direita) em px.
func bounds() -> Vector2:
	return Vector2(left(), right())


func can_expand() -> bool:
	return stage < STAGE_COLUMNS.size() - 1


## Limites da arena ativa; os do estágio 0 se não houver uma na cena.
static func bounds_in(tree: SceneTree) -> Vector2:
	var arena := tree.get_first_node_in_group(&"arena") as Arena if tree else null
	return arena.bounds() if arena else Vector2(CENTER_X - STAGE_COLUMNS[0] * TILE / 2.0, CENTER_X + STAGE_COLUMNS[0] * TILE / 2.0)


# --- Expansão ----------------------------------------------------------------

## Cresce um estágio: o chão surge coluna a coluna para os dois lados, as caixas vão
## para as novas bordas e as plataformas do estágio aparecem. Use com await.
func expand() -> void:
	if not can_expand():
		return
	var old_first := _first_column()
	var old_last := _last_column()
	stage += 1
	_clear_crates()
	_update_walls()
	for i in old_first - _first_column():
		for col in [old_first - 1 - i, old_last + 1 + i]:
			_fill_ground_column(col)
			Fx.burst(self, Vector2(col * TILE + TILE / 2.0, ground_y), Color("8a6a4f"), 6, 40.0)
		await get_tree().create_timer(0.07, false).timeout
	_place_crates()
	for spec in STAGE_LEDGES[stage]:
		_add_ledge(spec, true)
		await get_tree().create_timer(0.12, false).timeout
	expanded.emit(stage)


## Vai direto a um estágio, sem animação (ao continuar uma run salva).
func restore_stage(target: int) -> void:
	target = clampi(target, 0, STAGE_COLUMNS.size() - 1)
	while stage < target:
		var old_first := _first_column()
		var old_last := _last_column()
		stage += 1
		_clear_crates()
		for i in old_first - _first_column():
			_fill_ground_column(old_first - 1 - i)
			_fill_ground_column(old_last + 1 + i)
		_place_crates()
		for spec in STAGE_LEDGES[stage]:
			_add_ledge(spec, false)
	_update_walls()
	expanded.emit(stage)


func _first_column() -> int:
	return floori(left() / TILE)


func _last_column() -> int:
	return floori(right() / TILE) - 1


func _fill_ground_column(col: int) -> void:
	tiles.set_cell(Vector2i(col, _ground_row), 0, GRASS_TILES[posmod(col, GRASS_TILES.size())])
	tiles.set_cell(Vector2i(col, _ground_row + 1), 0, STONE_TILES[posmod(col, STONE_TILES.size())])


func _place_crates() -> void:
	var cells: Array[Vector2i] = []
	if edge_crates:
		var l := _first_column()
		var r := _last_column()
		cells = [Vector2i(l, 1), Vector2i(l + 1, 1), Vector2i(l, 2),
			Vector2i(r - 3, 1), Vector2i(r - 2, 1), Vector2i(r - 1, 1), Vector2i(r, 1), Vector2i(r - 1, 2), Vector2i(r, 2)]
	else:
		cells = crates
	for crate in cells:
		var cell := Vector2i(crate.x, _ground_row - crate.y)
		tiles.set_cell(cell, 0, CRATE_TILE)
		_crate_cells.append(cell)


func _clear_crates() -> void:
	for cell in _crate_cells:
		tiles.erase_cell(cell)
		Fx.burst(self, tiles.map_to_local(cell) + tiles.position, Color("c86a3d"), 4, 30.0)
	_crate_cells.clear()


func _make_wall() -> StaticBody2D:
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 600)
	shape.shape = rect
	wall.add_child(shape)
	add_child(wall)
	return wall


func _update_walls() -> void:
	_left_wall.position = Vector2(left() - 8.0, ground_y - 200.0)
	_right_wall.position = Vector2(right() + 8.0, ground_y - 200.0)


## Plataforma de pedra: dá para subir por baixo (one-way) e descer segurando para baixo.
func _add_ledge(spec: Array, animate: bool) -> void:
	var x0 := float(spec[0])
	var width := float(spec[1]) - x0
	var ledge := StaticBody2D.new()
	ledge.collision_layer = PLATFORM_LAYER
	ledge.collision_mask = 0
	ledge.position = Vector2(x0, ground_y - float(spec[2]))
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, LEDGE_THICKNESS)
	shape.shape = rect
	shape.position = Vector2(width / 2.0, LEDGE_THICKNESS / 2.0)
	shape.one_way_collision = true
	ledge.add_child(shape)
	# Visual: a fileira de pedras do Tileset (7 px de altura no topo do tile).
	for i in int(width / TILE):
		var piece := Sprite2D.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = TILESET_TEXTURE
		atlas.region = Rect2(32 + TILE * (i % 5), 65, TILE, 7)
		piece.texture = atlas
		piece.centered = false
		piece.position = Vector2(i * TILE, 0)
		ledge.add_child(piece)
	add_child(ledge)
	if animate:
		ledge.modulate.a = 0.0
		var tween := ledge.create_tween().set_parallel()
		tween.tween_property(ledge, "modulate:a", 1.0, 0.25)
		Fx.burst(self, ledge.position + Vector2(width / 2.0, 0), Color("c7dcd0"), 10, 40.0)


static func _make_tileset() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 0)

	var source := TileSetAtlasSource.new()
	source.texture = TILESET_TEXTURE
	source.texture_region_size = Vector2i(TILE, TILE)
	tile_set.add_source(source, 0)

	var half := TILE / 2.0
	var full := PackedVector2Array([Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)])
	for coords in GRASS_TILES + [CRATE_TILE]:
		source.create_tile(coords)
		var data := source.get_tile_data(coords, 0)
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, 0, full)
	for coords in STONE_TILES:
		source.create_tile(coords)
	return tile_set
