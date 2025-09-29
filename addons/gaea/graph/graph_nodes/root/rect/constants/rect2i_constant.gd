@tool
class_name GaeaNodeRect2iConstant
extends GaeaNodeConstant
## [Rect2i] constant.


func _get_output_port_type(_output_name: StringName) -> GaeaValue.Type:
	return GaeaValue.Type.RECT2I


func _get_title() -> String:
	return "Rect2iConstant"


func _get_description() -> String:
	return "[code]Rect2i[/code] constant."
