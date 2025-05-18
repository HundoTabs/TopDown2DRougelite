extends Node2D

@export var player_stats : EntityResource

@onready var floors: TileMapLayer = $MapLayers/Floors
@onready var second_floor_layer: TileMapLayer = $"MapLayers/Second Floor Layer"
@onready var depth_walls: TileMapLayer = $"MapLayers/Depth Walls"
@onready var left_wall_borders: TileMapLayer = $"MapLayers/Left Wall Borders"
@onready var left_corner_borders: TileMapLayer = $"MapLayers/Left Corner Borders"
@onready var top_borders: TileMapLayer = $"MapLayers/Top Borders"
@onready var right_wall_borders: TileMapLayer = $"MapLayers/Right Wall Borders"
@onready var right_corner_borders: TileMapLayer = $"MapLayers/Right Corner Borders"
@onready var under_depth_tiles: TileMapLayer = $"MapLayers/IndexedWalls/Under Depth Tiles"
@onready var index_walls: TileMapLayer = $"MapLayers/IndexedWalls/Index Walls"

@onready var character_scene = preload("res://Scenes/player_without_node.tscn")
@onready var EnemyController = $EnemyController
@onready var PlayerController = null

@export_group("Map Size")
@export var grid_size = Vector2(300, 300)
var grid = [] #2D Array to store walkable tiles
@export var walk_steps = 750
@export var walk_start = Vector2(grid_size.x / 2, grid_size.y / 2)
var player_instance = null
@export var direction_chance = 4
@export var enemies_in_area: Array = []
var occupied_tiles = {}

var rng = RandomNumberGenerator.new()

func _ready():
	generate_map()
	var new_stats : EntityResource = player_stats.create_instance()

func _process(_delta):
	if Input.is_action_just_pressed("reset map"):
		
		floors.clear()
		depth_walls.clear()
		left_wall_borders.clear()
		top_borders.clear()
		right_wall_borders.clear()
		under_depth_tiles.clear()
		second_floor_layer.clear()
		index_walls.clear()
		
		EnemyController.get_children()
		occupied_tiles.clear()
		for node in EnemyController.get_children():
			node.queue_free()
		generate_map()

func generate_map():
	randomize()
	
	grid = []
	for y in range(grid_size.y):
		var row = []
		for x in range(grid_size.x):
			row.append(0)
		grid.append(row)
		

	drunkards_walk(walk_start, walk_steps)
	
	update_tilemap()
	
	add_depth_tiles()
	
	generate_left_borders()
	generate_right_borders()
	generate_top_borders()
	
	spawn_character_on_floor_tile()
	
func drunkards_walk(start_position: Vector2, step: int):
	var current_position = start_position
	grid[int(current_position.y)][int(current_position.x)] = 1
	
	for i in range(step):
		var direction = randi() % direction_chance
		match direction:
			0:
				current_position.y -= 1 #move up
			1:
				current_position.y += 1 #move down
			2:
				current_position.x -= 1 #move left
			3:
				current_position.x += 1 #move right

		# Keep within the bounds of the grid
		current_position.x = clamp(current_position.x, 0, grid_size.x - 1)
		current_position.y = clamp(current_position.y, 0, grid_size.y - 1)
		
		# Mark Position on Floor
		grid[int(current_position.y)][int(current_position.x)] = 1
	
	
func update_tilemap():
	var modified_cells = []
	
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var cell_position = Vector2i(x, y)
			if grid[y][x] == 1:
				# Set tile as floor (use tile ID 1)
				floors.set_cell(cell_position, 0, Vector2i(round(rng.randi_range(0 , 5)), 0), 0)
				match randi() % 10:
					1:
						second_floor_layer.set_cell(cell_position, 3, Vector2i(2, 2), 0)
			else:
				# Set tile as wall
				floors.set_cell(cell_position, 1, Vector2i(1, 2), 0)
				
				
			modified_cells.append(cell_position)

func add_depth_tiles():
	var depth_cells = []
	var index_wall_cells = []
	var undertile_cells = []
	
	for y in range(grid_size.y - 1):
		for x in range(grid_size.x):
			if grid[y][x] == 0 and grid[y + 1][x] == 1:
				var cell_position = Vector2i(x, y)
				
				
				var undertile_bottom_left = Vector2(x * 2, y * 2)
				var undertile_bottom_right = Vector2(x * 2 + 1, y * 2)
				var undertile_top_left = Vector2(x * 2, y * 2 + 1)
				var undertile_top_right = Vector2(x * 2 + 1, y * 2 + 1)
				
				var index_position_left = Vector2i(x * 2, y * 2)
				var index_position_right = Vector2i(x * 2 + 1, y * 2)
				depth_walls.set_cell(cell_position, 1, Vector2i(round(rng.randi_range(4, 5)), 1))
				
				under_depth_tiles.set_cell(undertile_bottom_left, 1, Vector2i(8, 0))
				under_depth_tiles.set_cell(undertile_bottom_right, 1, Vector2i(8, 0))
				under_depth_tiles.set_cell(undertile_top_left, 1, Vector2i(8, 0))
				under_depth_tiles.set_cell(undertile_top_right, 1, Vector2i(8, 0))

				index_walls.set_cell(index_position_left, 0, Vector2i(8, 2))
				index_walls.set_cell(index_position_right, 0, Vector2i(8, 2))
				
				depth_cells.append(cell_position)
				
				undertile_cells.append(undertile_bottom_left)
				undertile_cells.append(undertile_bottom_right)
				undertile_cells.append(undertile_top_left)
				undertile_cells.append(undertile_top_right)
				
				index_wall_cells.append(index_position_left)
				index_wall_cells.append(index_position_right)
	
func spawn_character_on_floor_tile():
	if player_instance != null:
		player_instance.queue_free()
		
	var floor_tiles = []
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			if grid[y][x] == 1:
				floor_tiles.append(Vector2i(x, y))
					
	if floor_tiles.size() > 0:
		var random_tile = floor_tiles[randi() % floor_tiles.size()]
		var world_position = floors.map_to_local(random_tile)
		player_instance = character_scene.instantiate()
		PlayerController = player_instance
		player_instance.position = world_position
		
		add_child(player_instance)
		
		var timer = Timer.new()
		timer.one_shot = true
		timer.wait_time = 0.2
		timer.connect("timeout", Callable(self, "spawn_enemy_on_floor_tile").bind(floor_tiles))
		add_child(timer)
		timer.start()
		
func spawn_enemy_on_floor_tile(floor_tiles):
	#FIXME: Fix enemy spawning so they aren't on the same tile causing them to collide.
	var enemy_scene = preload("res://Scenes/enemy.tscn")
	
	for _i in range(25):
		var random_tile = floor_tiles[randi() % floor_tiles.size()]
		if is_tile_safe_for_enemy_spawn(random_tile):
			var world_position = floors.map_to_local(random_tile)
			var enemy_instance = enemy_scene.instantiate()
			enemy_instance.position = world_position
			occupied_tiles[random_tile] = enemy_instance
			
			EnemyController.add_child(enemy_instance)
		
func is_tile_safe_for_enemy_spawn(tile_pos: Vector2i) -> bool:
	if occupied_tiles.has(tile_pos):
		return false
	
	for offset in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
		var check_pos = tile_pos + offset
		if grid[check_pos.y][check_pos.x] == 0:
			return false
	
	return true
		
func generate_left_borders():
	var left_border_cells = []
	
	for y in range(grid_size.y):
		for x in range(grid_size.x - 1):
			if grid[y][x] == 1 and grid[y][x + 1] == 0:
				var cell_position = Vector2i(x, y)
				left_wall_borders.set_cell(cell_position, 2, Vector2i(0, 2))

func generate_right_borders():
	var right_border_cells = []
	
	for y in range(grid_size.y):
		for x in range(grid_size.x - 1):
			if grid[y][x] == 1 and grid[y][x - 1] == 0:
				var cell_position = Vector2i(x, y)
				right_wall_borders.set_cell(cell_position, 2, Vector2i(2, 2))
	
func generate_top_borders():
	var top_border_cells = []
	
	for y in range(grid_size.y):
		for x in range(grid_size.x - 1):
			if grid[y][x] == 1 and grid[y + 1][x] == 0:
				var cell_position = Vector2i(x, y)
				top_borders.set_cell(cell_position, 2, Vector2i(1, 1))
