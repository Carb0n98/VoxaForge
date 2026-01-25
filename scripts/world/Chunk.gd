extends Node3D

var noise := FastNoiseLite.new()

const  CHUNK_SIZE = 16

var blocks = []

@onready var mesh_instance = $MeshInstance3D
@onready var collider = $StaticBody3D/CollisionShape3D

func _ready():
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.02
	
	generate_blocks()
	build_mesh()

func generate_blocks():
	blocks.resize(CHUNK_SIZE)
	for x in range(CHUNK_SIZE):
		blocks[x] = []
		blocks[x].resize(CHUNK_SIZE)
		for y in range(CHUNK_SIZE):
			blocks[x][y] = []
			blocks[x][y].resize(CHUNK_SIZE)
			for z in range(CHUNK_SIZE):
				var height = int((noise.get_noise_2d(x, z) + 1) * 8)
				
				if y <= height:
					blocks[x][y][z] = 1 # terra
				else:
					blocks[x][y][z] = 0 # ar

func build_mesh():
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			for z in range(CHUNK_SIZE):
				if blocks[x][y][z] != 0:
					var pos = Vector3(x, y, z)
					
					if is_air(x, y, z - 1):
						add_face_front(st, pos)
					if is_air(x, y, z + 1):
						add_face_back(st, pos)
					if is_air(x - 1, y, z):
						add_face_left(st, pos)
					if is_air(x + 1, y, z):
						add_face_right(st, pos)
					if is_air(x, y + 1, z):
						add_face_top(st, pos)
					if is_air(x, y - 1, z):
						add_face_bottom(st, pos)

	var mesh = st.commit()
	mesh_instance.mesh = mesh
	
	var shape = mesh.create_trimesh_shape()
	collider.shape = shape


func is_air(x, y, z):
	if x < 0 or x >= CHUNK_SIZE:
		return true
	if y < 0 or z >= CHUNK_SIZE:
		return true
	if z < 0 or z >= CHUNK_SIZE:
		return true
	
	return blocks[x][y][z] == 0

func add_face_front(st: SurfaceTool, pos: Vector3):
	var v = [
		Vector3(0,0,0), Vector3(1,0,0), Vector3(1,1,0),
		Vector3(0,0,0), Vector3(1,1,0), Vector3(0,1,0)
	]
	for vent in v:
		st.add_vertex(vent + pos)

func add_face_back(st: SurfaceTool, pos: Vector3):
	var v = [
		Vector3(0,0,1), Vector3(1,1,1), Vector3(1,0,1),
		Vector3(0,0,1), Vector3(0,1,1), Vector3(1,1,1)
	]
	for vent in v:
		st.add_vertex(vent + pos)

func add_face_left(st: SurfaceTool, pos: Vector3):
	var v = [
		Vector3(0,0,0), Vector3(0,1,1), Vector3(0,0,1),
		Vector3(0,0,0), Vector3(0,1,0), Vector3(0,1,1)
	]
	for vent in v:
		st.add_vertex(vent + pos)

func add_face_right(st: SurfaceTool, pos: Vector3):
	var v = [
		Vector3(1,0,0), Vector3(1,0,1), Vector3(1,1,1),
		Vector3(1,0,0), Vector3(1,1,1), Vector3(1,1,0)
	]
	for vent in v:
		st.add_vertex(vent + pos)

func add_face_top(st: SurfaceTool, pos: Vector3):
	var v = [
		Vector3(0,1,0), Vector3(1,1,0), Vector3(1,1,1),
		Vector3(0,1,0), Vector3(1,1,1), Vector3(0,1,1)
	]
	for vent in v:
		st.add_vertex(vent + pos)

func add_face_bottom(st: SurfaceTool, pos: Vector3):
	var v = [
		Vector3(0,0,0), Vector3(1,0,1), Vector3(1,0,0),
		Vector3(0,0,0), Vector3(0,0,1), Vector3(1,0,1)
	]
	for vent in v:
		st.add_vertex(vent + pos)
