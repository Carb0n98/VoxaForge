extends Node3D

@export var chunk_scene: PackedScene
@export var view_distance := 2
@export var seed := 12345
var biome: Biome

const CHUNK_SIZE = 16

var chunks = {}
@onready var player = get_parent().get_node("Player") # Certifique-se que o caminho pro Player está certo

func _ready() -> void:
	biome = Biome.new(seed)

func _process(_delta):
	# Proteção caso o player não seja encontrado
	if not player:
		return

	var player_chunk = get_chunk_coord(player.global_position)
	
	for x in range(-view_distance, view_distance + 1):
		for z in range(-view_distance, view_distance + 1):
			var coord = player_chunk + Vector2i(x, z)
			
			if not chunks.has(coord):
				create_chunk(coord)

func get_chunk_coord(pos: Vector3) -> Vector2i:
	return Vector2i(
		floor(pos.x / CHUNK_SIZE),
		floor(pos.z / CHUNK_SIZE)
	)

func create_chunk(coord: Vector2i):
	var chunk = chunk_scene.instantiate()
	
	# Adicionamos à cena primeiro
	add_child(chunk)
	
	# --- A MUDANÇA IMPORTANTE ---
	# Chamamos a função 'init' do Chunk passando as coordenadas (X, Z).
	# Note que usamos coord.y para o Z, pois Vector2i usa (x, y).
	if chunk.has_method("init"):
		chunk.init(coord.x, coord.y, biome)
	
	# Armazenamos no dicionário para não criar de novo
	chunks[coord] = chunk
