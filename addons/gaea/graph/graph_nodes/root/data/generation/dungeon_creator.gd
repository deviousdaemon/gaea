@tool
extends GaeaNodeResource
class_name DungeonCreator

const _BIT_PATH: float = 1.0
const _BIT_WALL: float = 0.0

const _ROOM_ATTEMPT_MULT: int = 64
const _EXTRA_ROOM_CONNECTION_MAX: float = 6.75

var room_size_min: Vector2i
var room_size_max: Vector2i
var min_room_spacing: Vector2i
var room_density: float
var room_extra_connection_chance: float

var _grid: Dictionary[Vector3i, float]

func _get_title() -> String:
	return "DungeonCreator"

func _get_icon() -> Texture2D: return load("uid://bx462hx16fqcb")

func _get_description() -> String:
	return "Generates Rooms and Hallways.\nReturns a [code]Dictionary[Vector3i, room_index + 1 or 0][/code] of [data],\nan [code]Array[GaeaRoom][/code],\nthe starting room index,\nand the ending room index"

func _get_arguments_list() -> Array[StringName]: return [
		&"room_size_min",
		&"room_size_max",
		&"min_room_spacing",
		&"room_density",
		&"room_extra_connection_chance"
	]

func _get_argument_type(arg_name: StringName) -> GaeaValue.Type:
	match arg_name:
		&"room_size_min", &"room_size_max", &"min_room_spacing": return GaeaValue.Type.VECTOR2I
		&"room_density", &"room_extra_connection_chance": return GaeaValue.Type.FLOAT
	return GaeaValue.Type.NULL

func _get_argument_default_value(arg_name: StringName) -> Variant:
	match arg_name:
		&"room_size_min": return Vector2i(5, 5)
		&"room_size_max": return Vector2i(9, 9)
		&"min_room_spacing": return Vector2i(4, 4)
		&"room_density": return 1.0
		&"room_extra_connection_chance": return 0.0
	return super(arg_name)

func _get_argument_hint(arg_name: StringName) -> Dictionary[String, Variant]:
	match arg_name:
		&"room_size_min": return {"min":Vector2i(3, 3)}
		&"min_room_spacing": return {"min":Vector2i(4, 4)}
		&"room_density": return {"min":0.01,"max":1.0}
		&"room_extra_connection_chance": return {"min":0.0,"max":_EXTRA_ROOM_CONNECTION_MAX, "suffix":"%"}
	return super(arg_name)

func _get_output_ports_list() -> Array[StringName]: return [
	&"start_room_index",
	&"end_room_index",
	&"rooms",
	&"grid_data",
	]

func _get_output_port_type(output_name: StringName) -> GaeaValue.Type:
	match output_name:
		&"grid_data": return GaeaValue.Type.DATA
		&"rooms": return GaeaValue.Type.ROOM_ARRAY
		&"start_room_index", &"end_room_index": return GaeaValue.Type.INT
		_: return GaeaValue.Type.NULL

func _get_data(output_port: StringName, area: AABB, graph: GaeaGraph) -> Variant:
	var rng: GaeaRNG = define_rng(graph)
	
	var grid_size: Vector2i = Vector2i(area.size.x, area.size.y)
	var pos_z: int = area.position.z
	
	_grid.clear()
	
	room_size_min = _get_arg(&"room_size_min", area, graph) as Vector2i
	room_size_max = _get_arg(&"room_size_max", area, graph) as Vector2i
	min_room_spacing = _get_arg(&"min_room_spacing", area, graph) as Vector2i
	var max_room_attempts: int = pow(floori(sqrt(grid_size.x * grid_size.y)) * _ROOM_ATTEMPT_MULT, 1.25)
	room_density = _get_arg(&"room_density", area, graph) as float
	room_extra_connection_chance = (_get_arg(&"room_extra_connection_chance", area, graph) as float) / 100.0
	
	var rooms: Array[GaeaRoom] = _generate_rooms(rng, grid_size, max_room_attempts)
	
	if not is_equal_approx(room_density, 1.0):
		var max_rooms: int = maxi(floori(float(rooms.size()) * room_density), 2)
		
		while rooms.size() > max_rooms:
			rooms.remove_at(rng.randi() % rooms.size())
			pass
	
	rooms.sort_custom(__sort_clockwise.bind(grid_size / 2))
	
	for i in rooms.size():
		rooms[i].index = i
	
	
	
	var astar := DungeonAStar.new(rng)
	astar.diagonal_mode = DungeonAStar.DIAGONAL_MODE_NEVER
	#astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	#astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.region = Rect2i(Vector2i(), grid_size)
	astar.update()
	astar.fill_weight_scale_region(astar.region, 8.0)
	
	
	
	## Array[ Dictionary[ room_index: distance / weight ] ]
	var grid_data: Array[Dictionary]
	
	for i in rooms.size():
		var a: GaeaRoom = rooms[i]
		
		var outer_start: Vector2i = a.start - Vector2i.ONE
		var outer_end: Vector2i = a.end + Vector2i(2, 2)
		
		for y in range(outer_start.y, outer_end.y): for x in range(outer_start.x, outer_end.x):
			if y == outer_start.y or x == outer_start.x or y == outer_end.y - 1 or x == outer_end.x - 1:
				astar.set_point_weight_scale(Vector2i(x, y), 64.0)
				pass
			else:
				astar.set_point_solid(Vector2i(x, y), true)
		
		var g_dict: Dictionary[int, float]
		for j in rooms.size():
			if j == i: continue
			var b: GaeaRoom = rooms[j]
			if _line_intersects_room(a, b, rooms): continue
			g_dict[j] = a.center.distance_to(b.center)
		
		grid_data.append(g_dict)
		pass
	
	
	
	var mst_result: Array[PackedInt32Array] = _get_mst(grid_data)
	
	if room_extra_connection_chance > 0.0:
		for i in grid_data.size():
			for n in grid_data[i]:
				if mst_result.has(PackedInt32Array([i, n])) or mst_result.has(PackedInt32Array([n, i])): continue
				if rng.randf_range(0.0, 1.000) >= 1.000 - room_extra_connection_chance:
					mst_result.append(PackedInt32Array([i, n]))
					break
		pass
	
	
	
	_assign_room_connections(rooms, grid_data, mst_result)
	
	
	for pair in mst_result:
		
		var a_idx: int = pair[0]
		var b_idx: int = pair[1]
		
		var path: Array[Vector2i] = _get_connection_path(rooms[a_idx], rooms[b_idx], astar)
		
		var room_a: GaeaRoom = rooms[a_idx]
		var room_b: GaeaRoom = rooms[b_idx]
		
		var dist_thru_room_a: Vector2i = (room_a.get_connection_doorway(room_b) - room_a.center).abs()
		var dist_thru_room_b: Vector2i = (room_b.get_connection_doorway(room_a) - room_b.center).abs()
		
		room_a.connections[room_b] = path.size() + dist_thru_room_a[dist_thru_room_a.max_axis_index()]
		room_b.connections[room_a] = path.size() + dist_thru_room_b[dist_thru_room_b.max_axis_index()]
		
		for p in path:
			_grid[Vector3i(p.x, p.y, pos_z)] = _BIT_PATH
			pass
	
	
	var longest_path_indexes: PackedInt32Array = _get_longest_path(rooms, grid_data)
	
	var start_room: int = longest_path_indexes[0]
	var end_room: int = longest_path_indexes[1]
	
	#var room_rects: Array[Rect2i]
	#
	# Set Rects to Grid
	for i in rooms.size():
		var room: GaeaRoom = rooms[i]
		#room_rects.append(room.rect)
		var bit_value: int = room.index + 1
		for y in range(room.rect.position.y, room.rect.end.y): for x in range(room.rect.position.x, room.rect.end.x):
			_grid[Vector3i(x, y, pos_z)] = bit_value
			pass
	
	
	_set_cached_data(&"grid_data", graph, _grid)
	_set_cached_data(&"rooms", graph, rooms)
	_set_cached_data(&"start_room_index", graph, start_room)
	_set_cached_data(&"end_room_index", graph, end_room)
	
	return _get_cached_data(output_port, graph)

func _generate_rooms(rng: GaeaRNG, grid_size: Vector2i, max_room_attempts: int) -> Array[GaeaRoom]:
	const MAX_CANDIDATES: int = 8
	
	var rooms: Array[GaeaRoom]
	
	var attempt: int = 0
	
	while attempt < max_room_attempts:
		
		var candidates: Array[Rect2i]
		
		while candidates.size() < MAX_CANDIDATES and attempt < max_room_attempts:
		
			var r_size: Vector2i = rng.rand_vector2i(room_size_min, room_size_max)
			var r_pos: Vector2i = rng.rand_vector2i_odd(Vector2i(2, 2), grid_size - r_size - Vector2i(3, 3))
			var r_rect: Rect2i = Rect2i(r_pos, r_size)
			
			var intersected: bool = false
			
			for i in rooms:
				if i.rect.intersects(r_rect.grow_individual(min_room_spacing.x, min_room_spacing.y, min_room_spacing.x, min_room_spacing.y)):
					intersected = true
					break
			
			if not intersected:
				candidates.append(r_rect)
			
			attempt += 1
		
		if attempt >= max_room_attempts: break
		
		var largest_area: int = -1
		var largest_rect: Rect2i
		
		for rect in candidates:
			if rect.get_area() > largest_area:
				largest_area = rect.get_area()
				largest_rect = rect
		
		rooms.append(GaeaRoom.new(largest_rect))
		
		pass
	
	return rooms


func __sort_clockwise(a: GaeaRoom, b: GaeaRoom, center: Vector2i) -> bool:
	return Vector2(a.get_center() - center).angle() < Vector2(b.get_center() - center).angle()

func _line_intersects_room(from: GaeaRoom, to: GaeaRoom, rooms: Array[GaeaRoom]) -> bool:
	
	#var to_dir: Vector2 = Vector2(from.center).direction_to(Vector2(to.center)) * (from.center.distance_to(to.center))
	
	for room in rooms:
		if room == from or room == to: continue
		for line in room.get_edge_lines():
			if Geometry2D.segment_intersects_segment(from.center, to.center, line[0], line[1]):
				return true
		
	return false

func _get_mst(grid_data: Array[Dictionary]) -> Array[PackedInt32Array]:
	
	var unconnected_indexes: Array[int]
	for i in grid_data.size(): unconnected_indexes.append(i)
	
	# Connection Pairs
	
	var connected_indexes: PackedInt32Array = [randi() % grid_data.size()]
	unconnected_indexes.erase(connected_indexes[0])
	var pairs: Array[PackedInt32Array]
	
	while pairs.size() < grid_data.size() - 2:
		
		var connection_info: PackedInt32Array = __get_closest_index(connected_indexes, grid_data)
		pairs.append(connection_info)
		connected_indexes.append(connection_info[1])
		unconnected_indexes.erase(connection_info[1])
		
		pass
	
	var last_index: int = unconnected_indexes[0]
	
	var closest_dist: float = INF
	var closest_neighbor: int = -1
	
	for index in connected_indexes:
		for neighbor_index in grid_data[index].keys():
			if neighbor_index == last_index:
				if grid_data[index][neighbor_index] < closest_dist:
					closest_dist = grid_data[index][neighbor_index]
					closest_neighbor = index
					
			pass
		pass
	
	pairs.append(PackedInt32Array([closest_neighbor, last_index]))
	
	return pairs

func __get_closest_index(connected_indexes: PackedInt32Array, grid_data: Array[Dictionary]) -> PackedInt32Array:
	
	var closest_dist: float = INF
	var starting_index: int = -1
	var ending_index: int = -1
	
	for index in connected_indexes:
		for neighbor_index in grid_data[index].keys():
			if connected_indexes.has(neighbor_index): continue
			if grid_data[index][neighbor_index] < closest_dist:
				closest_dist = grid_data[index][neighbor_index]
				starting_index = index
				ending_index = neighbor_index
	
	return [starting_index, ending_index]

func _assign_room_connections(rooms: Array[GaeaRoom], grid_data: Array[Dictionary], mst_result: Array[PackedInt32Array]) -> void:
	for pair in mst_result:
		var a: int = pair[0]
		var b: int = pair[1]
		rooms[a].connections[rooms[b]] = grid_data[a][b]
		rooms[b].connections[rooms[a]] = grid_data[a][b]
		pass
	pass

func _get_connection_path(a: GaeaRoom, b: GaeaRoom, astar: AStarGrid2D) -> Array[Vector2i]:
	var closest_sides: Array[Side] = a.get_closest_sides_to(b)
	var side_start: Side = closest_sides[0]
	var side_end: Side = closest_sides[1]
	
	a.doorways[side_start].append(b)
	b.doorways[side_end].append(a)
	
	var start: Vector2i = a.get_edge_center(side_start)
	var end: Vector2i = b.get_edge_center(side_end)
	
	var start_points: Array[Vector2i]
	var end_points: Array[Vector2i]
	
	match side_start:
		SIDE_LEFT:
			for i in 2:
				start_points.append(start)
				start.x -= 1
		SIDE_TOP:
			for i in 2:
				start_points.append(start)
				start.y -= 1
			pass
		SIDE_RIGHT:
			for i in 2:
				start_points.append(start)
				start.x += 1
		SIDE_BOTTOM:
			for i in 2:
				start_points.append(start)
				start.y += 1
	
	match side_end:
		SIDE_LEFT:
			for i in 2:
				end_points.append(end)
				end.x -= 1
		SIDE_TOP:
			for i in 2:
				end_points.append(end)
				end.y -= 1
			pass
		SIDE_RIGHT:
			for i in 2:
				end_points.append(end)
				end.x += 1
		SIDE_BOTTOM:
			for i in 2:
				end_points.append(end)
				end.y += 1
	
	
	
	var points: Array[Vector2i] = astar.get_id_path(start, end)
	
	for point in points:
		astar.set_point_weight_scale(point, 6.0)
	
	return start_points + points + end_points

func _get_longest_path(rooms: Array[GaeaRoom], grid_data: Array[Dictionary]) -> PackedInt32Array:
	
	var astar := GraphAStar.new(rooms)
	for i in rooms.size():
		astar.add_point(i, rooms[i].center)
	
	for a in rooms:
		for b in a.connections:
			astar.add_connection(a.index, b.index, grid_data[a.index][b.index])
			pass
	
	var longest_path_distance: float = 0.0
	var start_i: int
	var end_i: int
	
	for a in rooms.size():
		for b in rooms.size():
			if b == a: continue
			var dist: float = astar.get_path_distance(a, b)
			if dist > longest_path_distance:
				longest_path_distance = dist
				start_i = a
				end_i = b
	
	return [start_i, end_i]

class DungeonAStar extends AStarGrid2D:
	var rng: GaeaRNG

	func _init(_rng: GaeaRNG) -> void:
		rng = _rng
		pass

	func _compute_cost(from_id: Vector2i, end_id: Vector2i) -> float:
		
		if rng.randf_range(0.0, 1.0) > 0.6:
			return _cost_octile(from_id, end_id)
		else:
			return _cost_manhattan(from_id, end_id)
		#
		#var dist: float = from_id.distance_to(end_id)
		#
		#if dist > 4.0:
			#return _cost_octile(from_id, end_id)
		#else:
			#return _cost_manhattan(from_id, end_id)

	func _cost_manhattan(from: Vector2i, end: Vector2i) -> float:
		var dx: int = absi(end.x - from.x)
		var dy: int = absi(end.y - from.y)
		return dx + dy

	func _cost_octile(from: Vector2i, end: Vector2i) -> float:
		var dx: int = absi(end.x - from.x)
		var dy: int = absi(end.y - from.y)
		var f: float = sqrt(2.0) - 1.0
		if dx < dy:
			return f * float(dx) + float(dy)
		else:
			return f * float(dy) + float(dx)
		# result = (dx < dy) ? f * dx + dy : f * dy + dx;

	func _cost_euclidean(from: Vector2i, end: Vector2i) -> float:
		var dx: int = absi(end.x - from.x)
		var dy: int = absi(end.y - from.y)
		return sqrt(dx * dx + dy * dy)

	func _cost_chebyshev(from: Vector2i, end: Vector2i) -> float:
		var dx: int = absi(end.x - from.x)
		var dy: int = absi(end.y - from.y)
		return maxf(dx, dy)

class GraphAStar extends AStar2D:

	var rooms: Array[GaeaRoom]

	## Array[ Dictionary[ to: int, weight ] ]
	var connection_distances: Array[Dictionary]

	func _init(_rooms: Array[GaeaRoom]) -> void:
		rooms = _rooms
		connection_distances.resize(rooms.size())
		pass

	func _compute_cost(from_id: int, to_id: int) -> float:
		if from_id >= connection_distances.size(): return get_point_position(from_id).distance_to(get_point_position(to_id))
		if not connection_distances[from_id].has(to_id): return get_point_position(from_id).distance_to(get_point_position(to_id))
		
		if rooms[to_id].get_sides_with_connections().size() == 1:
			return connection_distances[from_id][to_id] * 0.75
		
		return connection_distances[from_id][to_id]

	func add_connection(id: int, to_id: int, weight: float) -> void:
		if are_points_connected(id, to_id, true): return
		connect_points(id, to_id, true)
		connection_distances[id][to_id] = weight
		connection_distances[to_id][id] = weight
		pass

	func get_path_distance(from_id: int, to_id: int) -> float:
		
		var id_path: PackedInt64Array = get_id_path(from_id, to_id, false)
		
		if not id_path: return -1.0
		
		var weight: float = 0.0
		
		for i in id_path.size() - 1:
			weight += connection_distances[id_path[i]][id_path[i + 1]]
		
		return weight
