@tool
class_name GaeaNodeRect2Constant
extends GaeaNodeConstant
## [Rect2] constant.


func _get_output_port_type(_output_name: StringName) -> GaeaValue.Type:
	return GaeaValue.Type.RECT2


func _get_title() -> String:
	return "Rect2Constant"


func _get_description() -> String:
	return "[code]Rect2[/code] constant."
