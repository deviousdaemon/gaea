@tool
@abstract
class_name GaeaNodeRectBase
extends GaeaNodeResource
## Base class for rect operation nodes.


enum RectType {
	RECT2 = GaeaValue.Type.RECT2,
	RECT2I = GaeaValue.Type.RECT2I,
}

enum InputType {
	VECTOR,
	FULL
}


func _get_rect_type_name() -> String:
	return RectType.find_key(get_enum_selection(0)).to_pascal_case()


func _get_enums_count() -> int:
	return 2


func _get_enum_options(enum_idx: int) -> Dictionary:
	match enum_idx:
		0: return RectType
		1: return InputType
	return {}


func _get_enum_option_display_name(enum_idx: int, option_value: int) -> String:
	return super(enum_idx, option_value).replace(" ", "")


func _get_enum_option_icon(_enum_idx: int, option_value: int) -> Texture:
	return GaeaValue.get_display_icon(option_value)


func _on_enum_value_changed(_enum_idx: int, _option_value: int) -> void:
	notify_argument_list_changed()


func _is_integer_rect() -> bool:
	return get_enum_selection(0) in [RectType.RECT2I]
