extends Node
func _ready() -> void: call_deferred("_run")
func _run() -> void:
	assert(not Global.persistence_enabled)
	Global.cloud_db_enabled = false
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1152,648)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var screen = load("res://ui/screens/history/history_screen.tscn").instantiate()
	viewport.add_child(screen)
	await get_tree().create_timer(0.2).timeout
	assert(screen._csv_button.is_visible_in_tree())
	assert(not screen.find_child("ResetPatientButton",true,false).is_visible_in_tree())
	assert(not screen._patient_id_edit.editable)
	screen._mode_toggle_btn.pressed.emit()
	assert(screen._toolbar_row2.visible and screen._doctor_section_container.visible)
	assert(screen._patient_id_edit.editable)
	var reset: Button = screen.find_child("ResetPatientButton",true,false)
	assert(reset != null and reset.text == "Xóa dữ liệu hồ sơ…")
	var before_profiles := Global.patient_profiles.duplicate(true)
	var before_queue := Global.cloud_outbox.duplicate(true)
	reset.pressed.emit()
	assert(screen._reset_dialog.visible)
	assert(screen._reset_dialog.dialog_text.contains(Global.current_patient_id))
	assert(screen._reset_dialog.dialog_text.contains("Xóa lịch sử, ROM và tiến độ"))
	screen._reset_dialog.hide()
	assert(Global.patient_profiles == before_profiles and Global.cloud_outbox == before_queue)
	Global.report_sync.busy = true
	reset.pressed.emit()
	assert(not screen._reset_dialog.visible)
	Global.report_sync.busy = false
	for dimensions in [Vector2i(1152,648),Vector2i(800,600),Vector2i(1600,900)]:
		viewport.size = dimensions
		await get_tree().create_timer(0.25).timeout
		var toolbar: Control = screen.find_child("PatientToolbar",true,false)
		assert(screen._toolbar_row2.get_child_count() == 3)
		assert(screen._csv_button.get_parent() == screen._mode_toggle_btn.get_parent())
		assert(absf(screen._csv_button.global_position.y - screen._mode_toggle_btn.global_position.y) < 1)
		assert(screen._csv_button.get_global_rect().end.x <= screen._mode_toggle_btn.global_position.x)
		assert(screen._toolbar_row2.get_child(2) == reset)
		assert(screen._toolbar_row2.columns == 3)
		var manager_size: Vector2 = screen._mode_toggle_btn.size
		screen._mode_toggle_btn.pressed.emit()
		await get_tree().create_timer(0.1).timeout
		assert(screen._mode_toggle_btn.size.is_equal_approx(manager_size))
		assert(screen._csv_button.is_visible_in_tree() and not reset.is_visible_in_tree())
		screen._mode_toggle_btn.pressed.emit()
		await get_tree().create_timer(0.1).timeout
		assert(toolbar.get_global_rect().end.x <= dimensions.x)
		for button in screen._toolbar_row2.get_children():
			assert(button.get_global_rect().end.x <= toolbar.get_global_rect().end.x)
			assert(button.get_global_rect().end.y <= toolbar.get_global_rect().end.y)
			assert(absf(button.size.x-reset.size.x) <= 1)
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			assert(viewport.get_texture().get_image().save_png("res://history-toolbar-%d.png" % dimensions.x) == OK)
	screen._mode_toggle_btn.pressed.emit()
	assert(screen._csv_button.is_visible_in_tree() and not screen._doctor_section_container.visible)
	assert(not reset.is_visible_in_tree())
	assert(not screen._patient_id_edit.editable)
	assert(Global.patient_profiles == before_profiles and Global.cloud_outbox == before_queue)
	viewport.queue_free()
	await get_tree().process_frame
	print("HISTORY_TOOLBAR_PASS: manager/patient modes, reset confirmation/cancel, busy guard, three sizes, no patient-data mutation")
	get_tree().quit()
