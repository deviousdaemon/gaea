@tool
extends GaeaGraphNodeArgumentEditor
class_name Rect2ArgumentEditor

@onready var pos_x_label: Label = %PosXLabel
@onready var pos_y_label: Label = %PosYLabel
@onready var end_x_label: Label = %EndXLabel
@onready var end_y_label: Label = %EndYLabel
@onready var size_x_label: Label = %SizeXLabel
@onready var size_y_label: Label = %SizeYLabel

@onready var pos_x_spinbox: SpinBox = %PosXSpinbox
@onready var pos_y_spinbox: SpinBox = %PosYSpinbox
@onready var end_x_spinbox: SpinBox = %EndXSpinbox
@onready var end_y_spinbox: SpinBox = %EndYSpinbox
@onready var size_x_spinbox: SpinBox = %SizeXSpinbox
@onready var size_y_spinbox: SpinBox = %SizeYSpinbox

func _configure() -> void:
	if is_part_of_edited_scene():
		return
	await super ()
	
	pos_x_spinbox.value_changed.connect(argument_value_changed.emit)
	pos_y_spinbox.value_changed.connect(argument_value_changed.emit)
	end_x_spinbox.value_changed.connect(argument_value_changed.emit)
	end_y_spinbox.value_changed.connect(argument_value_changed.emit)
	size_x_spinbox.value_changed.connect(argument_value_changed.emit)
	size_y_spinbox.value_changed.connect(argument_value_changed.emit)
	
	var editor_interface = Engine.get_singleton("EditorInterface")
	pos_x_label.add_theme_color_override(&"font_color", editor_interface.get_base_control().get_theme_color("property_color_x", "Editor"))
	pos_y_label.add_theme_color_override(&"font_color", editor_interface.get_base_control().get_theme_color("property_color_x", "Editor"))
	end_x_label.add_theme_color_override(&"font_color", editor_interface.get_base_control().get_theme_color("property_color_x", "Editor"))
	end_y_label.add_theme_color_override(&"font_color", editor_interface.get_base_control().get_theme_color("property_color_x", "Editor"))
	size_x_label.add_theme_color_override(&"font_color", editor_interface.get_base_control().get_theme_color("property_color_x", "Editor"))
	size_y_label.add_theme_color_override(&"font_color", editor_interface.get_base_control().get_theme_color("property_color_x", "Editor"))

	if type == GaeaValue.Type.VECTOR2I or type == GaeaValue.Type.VECTOR3I:
		pos_x_spinbox.step = 1
		pos_y_spinbox.step = 1
		end_x_spinbox.step = 1
		end_y_spinbox.step = 1
		size_x_spinbox.step = 1
		size_y_spinbox.step = 1

	if hint.has("min"):
		var min_rect: Rect2 = hint.get("min")
		pos_x_spinbox.min_value = min_rect.position.x
		pos_y_spinbox.min_value = min_rect.position.y
		end_x_spinbox.min_value = min_rect.end.x
		end_y_spinbox.min_value = min_rect.end.y
		size_x_spinbox.min_value = min_rect.size.x
		size_y_spinbox.min_value = min_rect.size.y

	if hint.has("max"):
		var max_rect: Rect2 = hint.get("max")
		pos_x_spinbox.max_value = max_rect.position.x
		pos_y_spinbox.max_value = max_rect.position.y
		end_x_spinbox.max_value = max_rect.end.x
		end_y_spinbox.max_value = max_rect.end.y
		size_x_spinbox.max_value = max_rect.size.x
		size_y_spinbox.max_value = max_rect.size.y

	var has_min: bool = hint.has("min")
	pos_x_spinbox.allow_lesser = not has_min
	pos_y_spinbox.allow_lesser = not has_min
	end_x_spinbox.allow_lesser = not has_min
	end_y_spinbox.allow_lesser = not has_min
	size_x_spinbox.allow_lesser = not has_min
	size_y_spinbox.allow_lesser = not has_min
	
	var has_max: bool = hint.has("max")
	pos_x_spinbox.allow_greater = not has_max
	pos_y_spinbox.allow_greater = not has_max
	end_x_spinbox.allow_greater = not has_max
	end_y_spinbox.allow_greater = not has_max
	size_x_spinbox.allow_greater = not has_max
	size_y_spinbox.allow_greater = not has_max
	
	pass

func get_arg_value() -> Variant:
	if super () != null:
		return super ()
	match type:
		GaeaValue.Type.RECT2:
			return Rect2(Vector2(pos_x_spinbox.value, pos_y_spinbox.value), Vector2(size_x_spinbox.value, size_y_spinbox.value))
		GaeaValue.Type.RECT2I:
			return Rect2i(Vector2i(pos_x_spinbox.value, pos_y_spinbox.value), Vector2i(size_x_spinbox.value, size_y_spinbox.value))
	return null

func set_arg_value(new_value: Variant) -> void:
	var new_value_type = typeof(new_value)
	if not typeof(new_value) in [
		GaeaValue.Type.RECT2,
		GaeaValue.Type.RECT2I
	]:
		return
	pos_x_spinbox.value = float(new_value.position.x)
	pos_y_spinbox.value = float(new_value.position.y)
	end_x_spinbox.value = float(new_value.end.x)
	end_y_spinbox.value = float(new_value.end.y)
	size_x_spinbox.value = float(new_value.size.x)
	size_y_spinbox.value = float(new_value.size.y)
	pass




