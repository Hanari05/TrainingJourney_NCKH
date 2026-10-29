extends Control
const Display = preload("res://ui/shared/session_display.gd")
const MAP_NAMES := ["Phá cản mở đường", "Nâng đá", "Đẩy lùi tường", "Leo vách đá cao", "Thiền định"]

func _ready() -> void:
	theme = preload("res://assets/shared/ui/game_theme.tres")
	$Background.hide()
	var forest := preload("res://ui/screens/map_selection/map_preview.gd").new()
	forest.scenery_only = true
	add_child(forest)
	move_child(forest, 0)
	forest.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	$Margin/Column/Title.add_theme_color_override("font_color", Color("f5e9c7"))
	$BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://ui/screens/start/start_screen.tscn"))
	var list: VBoxContainer = $Margin/Column/Scroll/List
	$Margin/Column/Scroll.follow_focus = true
	var heading := _label("%d buổi tập  •  Thời gian theo máy" % Global.session_history.size(), 18)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", Color("f5e9c7"))
	$Margin/Column.add_child(heading)
	$Margin/Column.move_child(heading, 1)
	if Global.session_history.is_empty():
		var box := _card(list)
		box.add_child(_label("CHƯA CÓ LỊCH SỬ BUỔI TẬP", 24))
		box.add_child(_label("Các buổi đã được lưu sẽ xuất hiện tại đây.", 20))
		var start := Button.new()
		start.text = "CHỌN MAP ĐỂ BẮT ĐẦU"
		start.custom_minimum_size.y = 48
		start.pressed.connect(func(): get_tree().change_scene_to_file("res://ui/screens/map_selection/level_selection.tscn"))
		box.add_child(start)
	for index in range(Global.session_history.size() - 1, -1, -1):
		var entry: Dictionary = Global.session_history[index]
		var box := _card(list)
		var map_id := int(entry.get("map_id", 1))
		var map_name: String = MAP_NAMES[map_id - 1] if map_id >= 1 and map_id <= 5 else "Buổi tập"
		box.add_child(_label("Map %d · %s  —  Mức %d" % [map_id, map_name, int(entry.get("difficulty", 1))], 22))
		box.add_child(_label(_local_time(str(entry.get("ended_at_utc", entry.get("completed_at_utc", "")))), 17))
		if entry.has("status"): box.add_child(_label(Display.status(entry), 18))
		var stats := "Hợp lệ: %d lần     •     Chưa hợp lệ: %d lần" % [int(entry.get("valid_reps", 0)), int(entry.get("rejected_reps", 0))]
		if entry.has("bonus_points"): stats += "     •     Điểm thưởng: %d" % int(entry.bonus_points)
		box.add_child(_label(stats, 20))
		if TrackingStability.ENABLED and bool(entry.get("stability_enabled", true)):
			box.add_child(_label("Ổn định: %d/3" % int(entry.get("stability", 0)), 18))
		var evaluation := str(entry.get("evaluation", ""))
		if not evaluation.is_empty(): box.add_child(_label("Đánh giá trong game: " + evaluation, 18))
		var detail := _label(Display.compact_details(entry), 18)
		detail.hide()
		var toggle := Button.new()
		toggle.text = "XEM CHI TIẾT"
		toggle.toggle_mode = true
		toggle.custom_minimum_size.y = 44
		toggle.toggled.connect(func(open: bool):
			detail.visible = open
			toggle.text = "THU GỌN" if open else "XEM CHI TIẾT")
		box.add_child(toggle)
		box.add_child(detail)

func _card(list: VBoxContainer) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	return box

func _label(value: String, font_size: int) -> Label:
	var item := Label.new()
	item.text = value
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_font_size_override("font_size", font_size)
	return item

func _local_time(utc: String) -> String:
	if utc.is_empty(): return "Chưa có thông tin thời gian"
	var timestamp := Time.get_unix_time_from_datetime_string(utc)
	var local := Time.get_datetime_dict_from_unix_time(timestamp + int(Time.get_time_zone_from_system().bias) * 60)
	return "%02d/%02d/%04d  ·  %02d:%02d" % [local.day, local.month, local.year, local.hour, local.minute]
