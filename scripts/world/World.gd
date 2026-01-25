extends Node3D

@export var chunk_scene: PackedScene
@export var view_distance := 2

const CHUNK_SIZE = 16

var chunks = {}
@onready var player = get_parent().get_node("Player")

func get_chunk_coord(pos: Vector3) -> Vector2i:
	return Vector2i(
		floor(pos.x / CHUNK_SIZE),
		floor(pos.z / CHUNK_SIZE)
	)
	
func _process(_delta):
	var player_chunk = get_chunk_coord(player.global_position)
	
	for x in range(-view_distance, view_distance + 1):
		for z in range(-view_distance, view_distance + 1):
			var coord = player_chunk + Vector2i(x, z)
			
			if not chunks.has(coord):
				create_chunk(coord)
			
func create_chunk(coord: Vector2i):
	var chunk = chunk_scene.instantiate()
	add_child(chunk)
	
	chunk.position = Vector3(
		coord.x * CHUNK_SIZE,
		0,
		coord.y * CHUNK_SIZE
	)
	
	chunks[coord] = chunk
