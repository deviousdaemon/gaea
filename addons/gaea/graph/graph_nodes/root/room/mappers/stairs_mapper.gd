@tool
class_name StairsMapper
extends GaeaNodeResource

const CARDINALS: Array[Vector2i] = [
	Vector2i.LEFT,
	Vector2i.UP,
	Vector2i.RIGHT,
	Vector2i.DOWN,
]

func _get_title() -> String:
	return "StairsMapper"

func _get_arguments_list() -> Array[StringName]:
	return [
		&"data",
		&"room_index",
		&"room_array",
		&"stairs_material"
	]

func _get_argument_type(arg_name: StringName) -> GaeaValue.Type:
	match arg_name:
		&"data": return GaeaValue.Type.DATA
		&"room_index": return GaeaValue.Type.INT
		&"room_array": return GaeaValue.Type.ROOM_ARRAY
		&"stairs_material": return GaeaValue.Type.MATERIAL
		_: return GaeaValue.Type.NULL

func _get_required_arguments() -> Array[StringName]:
	return _get_arguments_list()

func _get_output_ports_list() -> Array[StringName]:
	return [ &"data", &"map" ]

func _get_output_port_type(output_name: StringName) -> GaeaValue.Type:
	match output_name:
		&"data": return GaeaValue.Type.DATA
		&"map": return GaeaValue.Type.MAP
		_: return GaeaValue.Type.NULL

func _get_data(output_port: StringName, area: AABB, graph: GaeaGraph) -> Dictionary[Vector3i, GaeaMaterial]:
	
	var map: Dictionary[Vector3i, GaeaMaterial]
	
	_set_cached_data(&"map", graph, map)
	
	var data: Dictionary[Vector3i, float] = _get_arg(&"data", area, graph) as Dictionary[Vector3i, float]
	_set_cached_data(&"data", graph, data)
	
	var room_index: int = _get_arg(&"room_index", area, graph) as int
	var room_array: Array[GaeaRoom] = _get_arg(&"room_array", area, graph) as Array[GaeaRoom]
	
	var stairs_material: GaeaMaterial = _get_arg(&"stairs_up_material", area, graph) as GaeaMaterial
	
	var rng := define_rng(graph)
	
	if not is_instance_valid(stairs_material):
		_log_error("Invalid material provided", graph, graph.resources.find(self))
		return _get_cached_data(output_port, graph)
	var p_mat: GaeaMaterial = stairs_material.prepare_sample(rng)
	if not is_instance_valid(p_mat):
		_log_error(
			"Recursive limit reached (%d): Invalid material provided at %s" % [GaeaMaterial.RECURSIVE_LIMIT, stairs_material.resource_path],
			graph,
			graph.resources.find(self)
		)
		return _get_cached_data(output_port, graph)
	else:
		stairs_material = p_mat
	
	var room: GaeaRoom = room_array[room_index]
	
	var room_center: Vector2i = room.get_center()
	
	var pos: Vector3i = Vector3i(room_center.x, room_center.y, area.position.z)
	
	var found_free_space: bool = false
	
	if data.has(pos): if int(data[pos]) == room_index + 1:
		var sample: GaeaMaterial = stairs_material.execute_sample(rng, data[pos])
		data[pos] = sample.get_instance_id()
		map[pos] = sample
		found_free_space = true
	
	if not found_free_space:
		# Find closest free space from center of room
		var points: Array[Vector2i] = room.get_point_array()
		points.erase(room_center)
		points.sort_custom(__sort_centerwise.bind(room_center))
		
		for point in points:
			var p_3d: Vector3i = Vector3i(point.x, point.y, area.position.z)
			if data.has(p_3d): if int(data[p_3d]) == room_index + 1:
				var sample: GaeaMaterial = stairs_material.execute_sample(rng, data[p_3d])
				data[p_3d] = sample.get_instance_id()
				map[p_3d] = sample
				found_free_space = true
				break
	
	if not found_free_space:
		_log_error("Cannot place stairs; No free space found in room.", graph, graph.resources.find(self))
		return _get_cached_data(output_port, graph)
	
	_set_cached_data(&"data", graph, data)
	_set_cached_data(&"map", graph, map)
	
	return _get_cached_data(output_port, graph)

func __sort_centerwise(a: Vector2i, b: Vector2i, center: Vector2i) -> bool:
	return a.distance_to(center) < b.distance_to(center)

#func _find_free_surrounding_space(rng: GaeaRNG, pos: Vector3i, room_index: int, rect: Rect2i, data: Dictionary[Vector3i, float], checked: Array[Vector3i]) -> Variant:
	#for dir in _get_cardinals(rng):
		#var n_pos: Vector3i = pos + Vector3i(dir.x, dir.y, 0)
		#if checked.has(n_pos): continue
		#if data.has(n_pos): if data[n_pos] == room_index:
			#return n_pos
	#return null
#
#func _get_cardinals(rng: GaeaRNG) -> Array[Vector2i]:
	#var cardinals: Array[Vector2i] = CARDINALS.duplicate()
	#rng.shuffle(cardinals)
	#return cardinals
