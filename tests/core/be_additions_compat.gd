extends Node
func _ready() -> void:
	call_deferred("_run")
func _run() -> void:
	assert(not Global.persistence_enabled)
	PoseInput.set_process(false)
	for map_id in range(1,6):
		Global.selected_action = map_id
		var viewport := SubViewport.new()
		viewport.size = Vector2i(1152,648)
		add_child(viewport)
		var level = load("res://maps/map_%d/main_level.tscn" % map_id).instantiate()
		viewport.add_child(level)
		await get_tree().create_timer(0.1).timeout
		var presenter = level.get_node("GamePresentation")
		presenter.set_process(false)
		level.instruction_panel.show()
		presenter._sync_camera_visibility()
		assert(not presenter.camera_header.visible and not presenter.camera_bg.visible)
		level.instruction_panel.hide()
		level.result_panel.hide()
		presenter._clear_camera("test")
		presenter._sync_camera_visibility()
		assert(presenter.camera_header.visible and presenter.camera_placeholder.visible)
		level.result_panel.show()
		presenter._sync_camera_visibility()
		assert(not presenter.camera_header.visible and not presenter.camera_placeholder.visible)
		viewport.queue_free()
		await get_tree().process_frame
	print("BE_ADDITIONS_COMPAT_PASS: camera visibility across five maps")
	get_tree().quit()
