extends Node

func _ready() -> void: call_deferred("_run")
func _settle() -> void: await get_tree().create_timer(0.2).timeout
func _capture(viewport: SubViewport, filename: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	assert(viewport.get_texture().get_image().save_png("res://" + filename) == OK)
func _assert_section(screen, selected: String) -> void:
	assert(screen._active_section == selected)
	for section in screen._section_views:
		assert(screen._section_views[section].is_visible_in_tree() == (section == selected))
	assert(screen._section_nav.visible == (selected != "overview"))

func _run() -> void:
	assert(not Global.persistence_enabled)
	Global.cloud_db_enabled = false
	var profiles_before := Global.patient_profiles.duplicate(true)
	var queue_before := Global.cloud_outbox.duplicate(true)
	var original_sessions := Global.session_history.duplicate(true)
	var original_rom := Global.rom_history.duplicate(true)
	Global.session_history = []
	Global.rom_history = []
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1152,648)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var screen = load("res://ui/screens/history/history_screen.tscn").instantiate()
	viewport.add_child(screen)
	await _settle()
	_assert_section(screen, "overview")
	assert(not screen._rom_chart.is_visible_in_tree())
	assert(not screen._session_list.is_visible_in_tree())
	assert(screen._overview_choices.size() == 2)
	assert(not screen._toolbar_row2.is_visible_in_tree())
	await _capture(viewport, "report-pages-overview-patient.png")
	screen._mode_toggle_btn.pressed.emit()
	for dimensions in [Vector2i(1152,648), Vector2i(800,600), Vector2i(1600,900)]:
		viewport.size = dimensions
		await _settle()
		_assert_section(screen, "overview")
		for button in screen._overview_choices.values():
			assert(button.get_global_rect().end.x <= dimensions.x)
		await _capture(viewport, "report-pages-overview-%d.png" % dimensions.x)
		screen._overview_choices.report.pressed.emit()
		await _settle()
		_assert_section(screen, "report")
		assert(screen._rom_chart.is_visible_in_tree())
		assert(not screen._session_list.is_visible_in_tree())
		assert(screen._section_title.text == "BÁO CÁO TẬP LUYỆN")
		assert(screen._section_patient.text.contains(Global.current_patient_id))
		assert(screen._rom_chart.get_global_rect().end.x <= dimensions.x)
		await _capture(viewport, "report-pages-report-%d.png" % dimensions.x)
		screen._section_tabs.history.pressed.emit()
		await _settle()
		_assert_section(screen, "history")
		assert(screen._session_list.is_visible_in_tree())
		assert(not screen._rom_chart.is_visible_in_tree())
		assert(screen._filter_count.text.contains("0/0"))
		assert(screen._session_list.get_child_count() == 1)
		assert(screen._section_scrolls.history.get_global_rect().end.x <= dimensions.x)
		await _capture(viewport, "report-pages-history-empty-%d.png" % dimensions.x)
		screen._section_back.pressed.emit()
		await _settle()
		_assert_section(screen, "overview")
		assert(screen._patient_mode == false)
	# Populate a temporary in-memory history to exercise filters, details and scroll retention.
	viewport.size = Vector2i(1152,648)
	for i in range(12):
		Global.session_history.append({"session_id":"ui-test-%d" % i,"patient_id":Global.current_patient_id,"status":"completed","map_id":i%2+1,"difficulty":1,"valid_reps":2,"rejected_reps":0,"completed_reps":2,"target_reps":10,"completed_phases":1,"target_phases":2,"active_seconds":65,"completed_at_utc":"2026-11-05T08:%02d:00" % i})
	screen._refresh_all()
	screen._overview_choices.history.pressed.emit()
	await _settle()
	assert(screen._session_list.get_child_count() == 12)
	screen._map_filter.select(2)
	screen._map_filter.item_selected.emit(2)
	await _settle()
	assert(screen._session_list.get_child_count() == 6)
	assert(screen._filter_count.text.contains("6/12"))
	var first_card: Node = screen._session_list.get_child(0).get_child(0)
	var detail_button: Button
	for child in first_card.get_children():
		if child is Button and child.text == "XEM CHI TIẾT": detail_button = child
	assert(detail_button != null)
	detail_button.button_pressed = true
	assert(first_card.get_child(-1).visible)
	await _settle()
	await _capture(viewport, "report-pages-history-data.png")
	screen._section_scrolls.history.scroll_vertical = 140
	await _settle()
	var previous_scroll: int = screen._section_scrolls.history.scroll_vertical
	var filter_y: float = screen._filter_count.global_position.y
	screen._section_tabs.report.pressed.emit()
	await _settle()
	screen._section_tabs.history.pressed.emit()
	await _settle()
	assert(screen._map_filter.selected == 2)
	assert(screen._session_list.get_child(0).get_child(0) == first_card)
	assert(first_card.get_child(-1).visible)
	assert(screen._section_scrolls.history.scroll_vertical == previous_scroll)
	assert(is_equal_approx(screen._filter_count.global_position.y, filter_y))
	screen.find_child("ResetHistoryFilters", true, false).pressed.emit()
	await _settle()
	assert(screen._map_filter.selected == 0 and screen._session_list.get_child_count() == 12)
	# Profile updates refresh both views, even while their content is hidden.
	var old_id: String = Global.current_patient_id
	Global.current_patient_id = "UI_OTHER"
	Global.patient_profile_changed.emit("UI_OTHER")
	await _settle()
	assert(screen._section_patient.text.contains("UI_OTHER"))
	assert(screen._filter_count.text.contains("0/0"))
	assert(screen._section_scrolls.history.scroll_vertical == 0)
	assert(screen._weekly_stats_label.text.contains("0 buổi"))
	Global.current_patient_id = old_id
	Global.session_history = original_sessions
	Global.rom_history = original_rom
	assert(Global.patient_profiles == profiles_before)
	assert(Global.cloud_outbox == queue_before)
	viewport.queue_free()
	await get_tree().process_frame
	print("REPORT_SECTIONS_PASS: 3 exclusive views, entry/back/tabs, empty/data history, sticky filters, details and scroll retained, profile change, 3 viewport sizes, no persistence")
	get_tree().quit()
