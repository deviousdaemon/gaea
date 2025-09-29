@tool
extends GaeaNodeRectBase
class_name GaeaNodeDecomposeRect
## Decomposes vector to floats.


func _get_title() -> String:
	return "RectDecompose"


func _get_description() -> String:
	return "Decomposes a [code]%s[/code] into %d [code]float[/code]s." % [_get_rect_type_name(), _get_output_ports_list().size()]


#region Arguments
func _get_arguments_list() -> Array[StringName]:
	return [&"rect"]

func _get_argument_display_name(_arg_name: StringName) -> String:
	return ""


func _get_argument_type(_arg_name: StringName) -> GaeaValue.Type:
	return get_enum_selection(0) as GaeaValue.Type
#endregion


#region Outputs
func _get_output_ports_list() -> Array[StringName]:
	match get_enum_selection(1):
		InputType.VECTOR:
			return [&"position", &"size"]
		InputType.FULL:
			return [&"x", &"y", &"width", &"height"]
	return []


func _get_output_port_display_name(output_name: StringName) -> String:
	return output_name


func _get_output_port_type(_output_name: StringName) -> GaeaValue.Type:
	match _output_name:
		&"position", &"size": return GaeaValue.Type.VECTOR2I if _is_integer_rect() else GaeaValue.Type.VECTOR2
		&"x", &"y", &"width", &"height": return GaeaValue.Type.INT if _is_integer_rect() else GaeaValue.Type.FLOAT
	return GaeaValue.Type.NULL
#endregion


func _get_tree_items() -> Array[GaeaNodeResource]:
	var array: Array[GaeaNodeResource] = []

	for i in RectType.values():
		var item: GaeaNodeResource = get_script().new()
		item.set_default_enum_value_override(0, i)
		item.set_tree_name_override(
			_get_enum_option_display_name(0, i) + "Decompose"
		)
		array.append(item)

	return array


func _get_data(output_port: StringName, area: AABB, graph: GaeaGraph) -> float:
	return _get_arg(&"vector", area, graph)[output_port]
