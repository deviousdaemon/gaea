@tool
class_name GaeaNodeRect2Parameter
extends GaeaNodeParameter
## [Rect2] parameter editable in the inspector.


func _get_variant_type() -> int:
	return TYPE_RECT2


func _get_title() -> String:
	return "Rect2Parameter"


func _get_description() -> String:
	return "[code]Rect2[/code] parameter editable in the inspector."
