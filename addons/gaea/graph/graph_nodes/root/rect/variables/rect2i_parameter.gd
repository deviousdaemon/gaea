@tool
class_name GaeaNodeRect2iParameter
extends GaeaNodeParameter
## [Rect2i] parameter editable in the inspector.


func _get_variant_type() -> int:
	return TYPE_RECT2I


func _get_title() -> String:
	return "Rect2iParameter"


func _get_description() -> String:
	return "[code]Rect2i[/code] parameter editable in the inspector."
