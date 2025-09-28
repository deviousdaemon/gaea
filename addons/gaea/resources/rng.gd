extends RandomNumberGenerator
class_name GaeaRNG
#
#static func get_class_name() -> String: return "RNG"

func _init(rng_seed: int = -1) -> void:
	if rng_seed == -1:
		rng_seed = roundi(Time.get_unix_time_from_system() * 100.0)
		seed = rng_seed
	else:
		seed = rng_seed
	pass

func choice(array: Array) -> Variant:
	return array[self.randi() % array.size()]

func rand_bool() -> bool: return choice([true, false])

func rand_rect(min_size: Vector2i, max_size: Vector2i, start: Vector2i, end: Vector2i) -> Rect2i:
	var size: Vector2i = rand_vector2i(min_size, max_size)
	var pos: Vector2i = rand_vector2i(start, end - size)
	return Rect2i(pos, size)

func rand_vector2i(min_vec: Vector2i, max_vec: Vector2i) -> Vector2i:
	return Vector2i(self.randi_range(min_vec.x, max_vec.x), self.randi_range(min_vec.y, max_vec.y))

func rand_vector2i_odd(min_vec: Vector2i, max_vec: Vector2i) -> Vector2i:
	return Vector2i(self.randi_range_odd(min_vec.x, max_vec.x), self.randi_range_odd(min_vec.y, max_vec.y))

func randi_range_stepped(from: int, to: int, step: int) -> int:
	if from == to: return from
	return clampi(snappedi(self.randi_range(from, to - 1), step), from, to - 1)

func randi_range_odd(from: int, to: int) -> int:
	if from == to: return from
	var num: int = self.randi_range(from, to)
	if _is_even(num):
		if num + 1 > to:
			num -= 1
		else:
			num += 1
	return num

func randi_range_even(from: int, to: int) -> int:
	if from == to: return from
	var num: int = self.randi_range(from, to)
	if not _is_even(num):
		if num + 1 > to:
			num -= 1
		else:
			num += 1
	return num

func _is_even(num: int) -> bool: return num % 2 == 0

func shuffle(array: Array) -> void:
	var n: int = array.size()
	if n < 2: return
	for i in range(n - 1, -1, -1):
		var j: int = self.randi() % (i + 1)
		var temp: Variant = array[i]
		array[i] = array[j]
		array[j] = temp
