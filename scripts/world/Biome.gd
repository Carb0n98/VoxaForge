extends Resource
class_name Biome

enum Type {
	PLAINS,
	DESERT,
	MOUNTAINS
}

var biome_noise: FastNoiseLite

func _init(seed: int = 9999) -> void:
	biome_noise = FastNoiseLite.new()
	biome_noise.seed = seed
	biome_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	biome_noise.frequency = 0.001

func get_biome(world_x: float, world_z: float) -> int:
	var n: float = biome_noise.get_noise_2d(world_x, world_z)

	if n < -0.25:
		return Type.DESERT
	elif n < 0.25:
		return Type.PLAINS
	else:
		return Type.MOUNTAINS

func get_biome_weight(world_x: float, world_z: float) -> float:
	var n: float = biome_noise.get_noise_2d(world_x, world_z)
	return clampf((n + 1.0) * 0.5, 0.0, 1.0)

func get_height(
	biome: int,
	base_noise: float,
	detail_noise: float,
	base_height: int
) -> float:
	match biome:
		Type.PLAINS:
			return base_height + base_noise * 4.0

		Type.DESERT:
			return base_height - 2.0 + base_noise * 3.0

		Type.MOUNTAINS:
			return base_height + base_noise * 14.0 + detail_noise * 6.0

	return base_height
