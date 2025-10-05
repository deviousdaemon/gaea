@tool
extends GaeaNodeResource
class_name RoomMapper

func _get_title() -> String: return "RoomMapper"

func _get_arguments_list() -> Array[StringName]:
	return [
		&"data",
		&"room_array",
		&"wall_material",
		&"floor_material",
		&"door_horizontal_material",
		&"door_vertical_material",
	]

func _get_argument_type(arg_name: StringName) -> GaeaValue.Type:
	match arg_name:
		&"data": return GaeaValue.Type.DATA
		&"room_array": return GaeaValue.Type.ROOM_ARRAY
		&"wall_material", &"floor_material", &"door_horizontal_material", &"door_vertical_material": return GaeaValue.Type.MATERIAL
	return GaeaValue.Type.NULL


func _get_output_ports_list() -> Array[StringName]:
	return [ &"data", &"wall_map", &"floor_map" ]

func _get_output_port_type(output_name: StringName) -> GaeaValue.Type:
	match output_name:
		&"data": return GaeaValue.Type.DATA
		&"wall_map", &"floor_map": return GaeaValue.Type.MAP
		_: return GaeaValue.Type.NULL

func _get_data(output_port: StringName, area: AABB, graph: GaeaGraph) -> Variant:
	
	var wall_map: Dictionary[Vector3i, GaeaMaterial]
	var floor_map: Dictionary[Vector3i, GaeaMaterial]
	
	_set_cached_data(&"wall_map", graph, wall_map)
	_set_cached_data(&"floor_map", graph, floor_map)
	
	var data: Dictionary[Vector3i, float] = _get_arg(&"data", area, graph) as Dictionary[Vector3i, float]
	_set_cached_data(&"data", graph, data)
	
	var room_array: Array[GaeaRoom] = _get_arg(&"room_array", area, graph) as Array[GaeaRoom]
	
	var wall_material: GaeaMaterial = _get_arg(&"wall_material", area, graph) as GaeaMaterial
	var floor_material: GaeaMaterial = _get_arg(&"floor_material", area, graph) as GaeaMaterial
	var door_horizontal_material: GaeaMaterial = _get_arg(&"door_horizontal_material", area, graph) as GaeaMaterial
	var door_vertical_material: GaeaMaterial = _get_arg(&"door_vertical_material", area, graph) as GaeaMaterial
	
	var rng := define_rng(graph)
	
	var mats: Array[GaeaMaterial] = [wall_material, floor_material, door_horizontal_material, door_vertical_material]
	
	for mat in mats:
		if not is_instance_valid(mat):
			_log_error("Invalid material provided", graph, graph.resources.find(self))
			return _get_cached_data(output_port, graph)
		var p_mat: GaeaMaterial = mat.prepare_sample(rng)
		if not is_instance_valid(p_mat):
			_log_error(
				"Recursive limit reached (%d): Invalid material provided at %s" % [GaeaMaterial.RECURSIVE_LIMIT, mat.resource_path],
				graph,
				graph.resources.find(self)
			)
			return _get_cached_data(output_port, graph)
		else:
			mat = p_mat
	
	for room in room_array:
		var room_index: int = room.index
		
		# Walls
		
		for point in room.get_wall_points():
			var p_3d: Vector3i = Vector3i(point.x, point.y, area.position.z)
			if data.has(p_3d): continue
			var sample: GaeaMaterial = wall_material.execute_sample(rng, data[p_3d])
			data[p_3d] = sample.get_instance_id()
			wall_map[p_3d] = sample
			pass
		
		# Floor
		
		for y in range(room.start.y, room.end.y): for x in range(room.start.x, room.end.x):
			var p_3d: Vector3i = Vector3i(x, y, area.position.z)
			if not data.has(p_3d): continue
			if not int(data[p_3d]) == room_index + 1: continue
			var sample: GaeaMaterial = floor_material.execute_sample(rng, data[p_3d])
			floor_map[p_3d] = sample
			pass
		
		# Door(s)
		
		var door_data: Dictionary[Side, Vector2i] = room.get_door_data()
		
		for side in door_data:
			var p_3d: Vector3i = Vector3i(door_data[side].x, door_data[side].y, area.position.z)
			if not data.has(p_3d): continue
			if not int(data[p_3d]) == 1 and not int(data[p_3d] == room_index + 1): continue
			var sample: GaeaMaterial
			match side:
				SIDE_TOP, SIDE_BOTTOM:
					sample = door_vertical_material.execute_sample(rng, data[p_3d])
				_:
					sample = door_horizontal_material.execute_sample(rng, data[p_3d])
			data[p_3d] = sample.get_instance_id()
			wall_map[p_3d] = sample
			pass
	
	# All good, set data
	
	_set_cached_data(&"data", graph, data)
	_set_cached_data(&"wall_map", graph, wall_map)
	_set_cached_data(&"floor_map", graph, floor_map)
	
	return _get_cached_data(output_port, graph)
