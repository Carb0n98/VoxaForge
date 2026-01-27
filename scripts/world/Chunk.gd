extends Node3D

# =========================
# CONFIG

const CHUNK_SIZE := 16
var noise := FastNoiseLite.new()

# =========================
# BLOCK IDS

const BLOCK_AIR := 0
const BLOCK_DIRT := 1
const BLOCK_STONE := 2

# =========================
# FACES

enum Face {
	FRONT,
	BACK,
	LEFT,
	RIGHT,
	TOP,
	BOTTOM
}

# =========================
# TEXTURES

const TEX_DIRT := preload("res://assets/textures/blocks/dirt.png")
const TEX_GRASS_TOP := preload("res://assets/textures/blocks/grass_top.png")
const TEX_GRASS_SIDE := preload("res://assets/textures/blocks/glass_side.png")
const TEX_STONE := preload("res://assets/textures/blocks/stone.png")

# =========================

var blocks := []

@onready var mesh_instance := $MeshInstance3D
@onready var collider := $StaticBody3D/CollisionShape3D

# =========================
# READY

func _ready():
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.02

	generate_blocks()
	build_mesh()

# =========================
# WORLD GEN

func generate_blocks():
	blocks.resize(CHUNK_SIZE)
	for x in range(CHUNK_SIZE):
		blocks[x] = []
		for y in range(CHUNK_SIZE):
			blocks[x].append([])
			for z in range(CHUNK_SIZE):
				var h := int((noise.get_noise_2d(x, z) + 1.0) * 8.0)
				if y <= h:
					blocks[x][y].append(BLOCK_STONE if y < 4 else BLOCK_DIRT)
				else:
					blocks[x][y].append(BLOCK_AIR)

# =========================
# BUILD MESH

func build_mesh():
	var surfaces := {}

	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			for z in range(CHUNK_SIZE):
				var block_id: int = blocks[x][y][z]
				if block_id == BLOCK_AIR:
					continue

				var pos := Vector3(x, y, z)

				if is_air(x, y, z - 1):
					add_face(surfaces, pos, block_id, Face.FRONT, x, y, z)
				if is_air(x, y, z + 1):
					add_face(surfaces, pos, block_id, Face.BACK, x, y, z)
				if is_air(x - 1, y, z):
					add_face(surfaces, pos, block_id, Face.LEFT, x, y, z)
				if is_air(x + 1, y, z):
					add_face(surfaces, pos, block_id, Face.RIGHT, x, y, z)
				if is_air(x, y + 1, z):
					add_face(surfaces, pos, block_id, Face.TOP, x, y, z)
				if is_air(x, y - 1, z):
					add_face(surfaces, pos, block_id, Face.BOTTOM, x, y, z)

	var mesh := ArrayMesh.new()
	for tex in surfaces.keys():
		surfaces[tex].commit(mesh)

	mesh_instance.mesh = mesh
	collider.shape = mesh.create_trimesh_shape()

# =========================
# AIR CHECK

func is_air(x:int, y:int, z:int) -> bool:
	if x < 0 or x >= CHUNK_SIZE: return true
	if y < 0 or y >= CHUNK_SIZE: return true
	if z < 0 or z >= CHUNK_SIZE: return true
	return blocks[x][y][z] == BLOCK_AIR

# =========================
# TEXTURE LOGIC (THE FIX)

func get_face_texture(block_id:int, face:int, x:int, y:int, z:int) -> Texture2D:
	if block_id == BLOCK_STONE:
		return TEX_STONE

	if block_id == BLOCK_DIRT:
		var covered := not is_air(x, y + 1, z)

		if covered:
			return TEX_DIRT

		if face == Face.TOP:
			return TEX_GRASS_TOP
		if face == Face.BOTTOM:
			return TEX_DIRT
		return TEX_GRASS_SIDE

	return TEX_DIRT

# =========================
# FACE BUILDER

func add_face(
	surfaces: Dictionary,
	pos: Vector3,
	block_id: int,
	face: int,
	x:int, y:int, z:int
):
	var tex := get_face_texture(block_id, face, x, y, z)

	if not surfaces.has(tex):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

		var mat := StandardMaterial3D.new()
		mat.albedo_texture = tex
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

		st.set_material(mat)
		surfaces[tex] = st

	var st: SurfaceTool = surfaces[tex]

	var verts := []
	var normal := Vector3.ZERO

	match face:
		Face.FRONT:
			normal = Vector3(0,0,-1)
			verts = [
				Vector3(0,0,0), Vector3(1,0,0), Vector3(1,1,0),
				Vector3(0,0,0), Vector3(1,1,0), Vector3(0,1,0)
			]
		Face.BACK:
			normal = Vector3(0,0,1)
			verts = [
				Vector3(1,0,1), Vector3(0,0,1), Vector3(0,1,1),
				Vector3(1,0,1), Vector3(0,1,1), Vector3(1,1,1)
			]
		Face.LEFT:
			normal = Vector3(-1,0,0)
			verts = [
				Vector3(0,0,1), Vector3(0,0,0), Vector3(0,1,0),
				Vector3(0,0,1), Vector3(0,1,0), Vector3(0,1,1)
			]
		Face.RIGHT:
			normal = Vector3(1,0,0)
			verts = [
				Vector3(1,0,0), Vector3(1,0,1), Vector3(1,1,1),
				Vector3(1,0,0), Vector3(1,1,1), Vector3(1,1,0)
			]
		Face.TOP:
			normal = Vector3(0,1,0)
			verts = [
				Vector3(0,1,0), Vector3(1,1,0), Vector3(1,1,1),
				Vector3(0,1,0), Vector3(1,1,1), Vector3(0,1,1)
			]
		Face.BOTTOM:
			normal = Vector3(0,-1,0)
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
