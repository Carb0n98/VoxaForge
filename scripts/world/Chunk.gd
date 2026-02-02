extends Node3D

# =================================================
# CONFIGURAÇÕES GERAIS

const CHUNK_SIZE: int = 16
const MAX_HEIGHT: int = 32
const BASE_HEIGHT: int = 12

# =================================================
# COORDENADAS DO CHUNK (SETADAS PELO WORLD)

var chunk_x: int
var chunk_z: int

# =================================================
# NOISE

var noise_base: FastNoiseLite
var noise_detail: FastNoiseLite

# =================================================
# BLOCO IDS

const BLOCK_AIR: int = 0
const BLOCK_DIRT: int = 1
const BLOCK_STONE: int = 2

# =================================================
# FACES

enum Face {
	FRONT,
	BACK,
	LEFT,
	RIGHT,
	TOP,
	BOTTOM
}

# =================================================
# TEXTURAS (UM ARQUIVO POR FACE)

const BLOCK_TEXTURES := {
	BLOCK_DIRT: {
		Face.TOP: preload("res://assets/textures/blocks/grass_top.png"),
		Face.BOTTOM: preload("res://assets/textures/blocks/dirt.png"),
		Face.FRONT: preload("res://assets/textures/blocks/glass_side.png"),
		Face.BACK: preload("res://assets/textures/blocks/glass_side.png"),
		Face.LEFT: preload("res://assets/textures/blocks/glass_side.png"),
		Face.RIGHT: preload("res://assets/textures/blocks/glass_side.png"),
	},
	BLOCK_STONE: {
		Face.TOP: preload("res://assets/textures/blocks/stone.png"),
		Face.BOTTOM: preload("res://assets/textures/blocks/stone.png"),
		Face.FRONT: preload("res://assets/textures/blocks/stone.png"),
		Face.BACK: preload("res://assets/textures/blocks/stone.png"),
		Face.LEFT: preload("res://assets/textures/blocks/stone.png"),
		Face.RIGHT: preload("res://assets/textures/blocks/stone.png"),
	}
}

# =================================================
# DADOS

var blocks: Array = []

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collider: CollisionShape3D = $StaticBody3D/CollisionShape3D

# =================================================
# READY

func _ready() -> void:
	noise_base = FastNoiseLite.new()
	noise_base.seed = 12345
	noise_base.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_base.frequency = 0.005

	noise_detail = FastNoiseLite.new()
	noise_detail.seed = 67890
	noise_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise_detail.frequency = 0.02

	generate_blocks()
	build_mesh()

# =================================================
# GERAÇÃO DO TERRENO (CONTÍNUA)

func generate_blocks() -> void:
	blocks.resize(CHUNK_SIZE)

	for x in range(CHUNK_SIZE):
		blocks[x] = []
		for y in range(MAX_HEIGHT):
			blocks[x].append([])
			for z in range(CHUNK_SIZE):
				blocks[x][y].append(BLOCK_AIR)

	for x in range(CHUNK_SIZE):
		for z in range(CHUNK_SIZE):
			var world_x: float = float(chunk_x * CHUNK_SIZE + x)
			var world_z: float = float(chunk_z * CHUNK_SIZE + z)

			var base: float = noise_base.get_noise_2d(world_x, world_z)
			var detail: float = noise_detail.get_noise_2d(world_x * 2.0, world_z * 2.0)

			var height_f: float = BASE_HEIGHT + base * 10.0 + detail * 4.0
			var height: int = clampi(int(height_f), 1, MAX_HEIGHT - 1)

			for y in range(height + 1):
				if y < height - 3:
					blocks[x][y][z] = BLOCK_STONE
				else:
					blocks[x][y][z] = BLOCK_DIRT

# =================================================
# BUILD MESH (UM SURFACE POR TEXTURA)

func build_mesh() -> void:
	var surfaces: Dictionary = {}

	for x in range(CHUNK_SIZE):
		for y in range(MAX_HEIGHT):
			for z in range(CHUNK_SIZE):
				var id: int = blocks[x][y][z]
				if id == BLOCK_AIR:
					continue

				var pos := Vector3(x, y, z)

				if is_air(x, y, z - 1):
					add_face(surfaces, pos, id, Face.FRONT)
				if is_air(x, y, z + 1):
					add_face(surfaces, pos, id, Face.BACK)
				if is_air(x - 1, y, z):
					add_face(surfaces, pos, id, Face.LEFT)
				if is_air(x + 1, y, z):
					add_face(surfaces, pos, id, Face.RIGHT)
				if is_air(x, y + 1, z):
					add_face(surfaces, pos, id, Face.TOP)
				if is_air(x, y - 1, z):
					add_face(surfaces, pos, id, Face.BOTTOM)

	var mesh := ArrayMesh.new()

	for tex in surfaces.keys():
		var st: SurfaceTool = surfaces[tex]
		st.commit(mesh)

	mesh_instance.mesh = mesh
	collider.shape = mesh.create_trimesh_shape()

# =================================================
# VERIFICA AR

func is_air(x: int, y: int, z: int) -> bool:
	if x < 0 or x >= CHUNK_SIZE:
		return true
	if y < 0 or y >= MAX_HEIGHT:
		return true
	if z < 0 or z >= CHUNK_SIZE:
		return true
	return blocks[x][y][z] == BLOCK_AIR

# =================================================
# FACE BUILDER (TEXTURA POR FACE)

func add_face(surfaces: Dictionary, pos: Vector3, block_id: int, face: int) -> void:
	var tex: Texture2D = BLOCK_TEXTURES[block_id][face]

	if not surfaces.has(tex):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

		var mat := StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

		st.set_material(mat)
		surfaces[tex] = st

	var st: SurfaceTool = surfaces[tex]

	var verts: Array
	var normal: Vector3

	match face:
		Face.FRONT:
			normal = Vector3(0, 0, -1)
			verts = [
				Vector3(0,0,0), Vector3(1,0,0), Vector3(1,1,0),
				Vector3(0,0,0), Vector3(1,1,0), Vector3(0,1,0)
			]
		Face.BACK:
			normal = Vector3(0, 0, 1)
			verts = [
				Vector3(1,0,1), Vector3(0,0,1), Vector3(0,1,1),
				Vector3(1,0,1), Vector3(0,1,1), Vector3(1,1,1)
			]
		Face.LEFT:
			normal = Vector3(-1, 0, 0)
			verts = [
				Vector3(0,0,1), Vector3(0,0,0), Vector3(0,1,0),
				Vector3(0,0,1), Vector3(0,1,0), Vector3(0,1,1)
			]
		Face.RIGHT:
			normal = Vector3(1, 0, 0)
			verts = [
				Vector3(1,0,0), Vector3(1,0,1), Vector3(1,1,1),
				Vector3(1,0,0), Vector3(1,1,1), Vector3(1,1,0)
			]
		Face.TOP:
			normal = Vector3(0, 1, 0)
			verts = [
				Vector3(0,1,0), Vector3(1,1,0), Vector3(1,1,1),
				Vector3(0,1,0), Vector3(1,1,1), Vector3(0,1,1)
			]
		Face.BOTTOM:
			normal = Vector3(0, -1, 0)
			verts = [
				Vector3(0,0,1), Vector3(1,0,1), Vector3(1,0,0),
				Vector3(0,0,1), Vector3(1,0,0), Vector3(0,0,0)
			]

	var uvs := [
		Vector2(0,1), Vector2(1,1), Vector2(1,0),
		Vector2(0,1), Vector2(1,0), Vector2(0,0)
	]

	for i in range(6):
		st.set_normal(normal)
		st.set_uv(uvs[i])
		st.add_vertex(verts[i] + pos)
