extends Node
var clicks := 0
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")
func _status(ok: bool) -> void:
	PoseInput.provider_connected = true
	PoseInput.last_tracking_received_ms = Time.get_ticks_msec()
	PoseInput.last_tracking_status = {"person_detected":ok,"required_body_visible":ok}
	PoseInput.tracking_status_changed.emit(PoseInput.last_tracking_status)
func _run() -> void:
	assert(not Global.persistence_enabled)
	PoseInput.set_process(false)
	HandCursor.set_process(false)
	PoseInput.provider_connected = true
	var button := CheckButton.new()
	button.position = Vector2(200,180)
	button.size = Vector2(240,60)
	button.text = "Hand native toggle"
	button.pressed.connect(func(): clicks += 1)
	add_child(button)
	await get_tree().process_frame
	var pos := button.get_global_rect().get_center()
	var dimensions := get_viewport().get_visible_rect().size
	HandCursor._screen_pos = pos
	HandCursor._on_hand_control_received({"active":true,"cursor_x":pos.x/dimensions.x,"cursor_y":pos.y/dimensions.y,"confidence":1.0})
	for i in range(18): HandCursor._process(0.1)
	Input.flush_buffered_events()
	await get_tree().process_frame
	assert(clicks == 1 and button.button_pressed, "Dwell must activate a native toggle once")
	HandCursor._last_hand_packet_ms -= 2000
	HandCursor._process(0.1)
	assert(not HandCursor.visual.visible and HandCursor._dwell_time == 0.0)
	button.queue_free()
	await get_tree().process_frame
	print("HAND_CURSOR_PASS: native dwell/toggle, stale input hides cursor")
	Global.selected_action = 1
	Global.max_rom_angle = 74.0
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1152,648)
	add_child(viewport)
	var level = load("res://maps/map_1/main_level.tscn").instantiate()
	viewport.add_child(level)
	await get_tree().create_timer(0.25).timeout
	var presentation = level.get_node("GamePresentation")
	presentation.set_process(false)
	var session = level.exercise_session
	session.set_process(false)
	level.instruction_panel.hide()
	_status(true)
	assert(session.start_session(level._session_config))
	level.get_node("Map1Controller").set_session_active(false)
	_status(false)
	presentation._process_auto_pause(0.5)
	assert(get_tree().paused and presentation.auto_pause_panel.visible and session._tracking_recovery_paused)
	session._process(2.0)
	assert(is_equal_approx(session._durations.tracking_lost_seconds,2.0))
	var before_reps: int = session.total_valid_reps
	session._on_exercise_event_received({"exercise_id":session.exercise_id,"event":"rep_completed","rep_candidate_id":"ignored"})
	assert(session.total_valid_reps == before_reps)
	_status(true)
	presentation._process_auto_pause(0.1)
	assert(get_tree().paused)
	session._process(1.0)
	assert(is_equal_approx(session._durations.paused_seconds,1.0))
	# Opening settings must not resume the game, even while tracking is restored.
	var settings = level.get_node("SettingsMenu")
	settings.overlay.show()
	session.set_menu_paused(true)
	presentation._process_auto_pause(5.0)
	assert(get_tree().paused and session._tracking_recovery_paused)
	settings.overlay.hide()
	session.set_menu_paused(false)
	presentation._process_auto_pause(3.1)
	assert(not get_tree().paused and not session._tracking_recovery_paused)
	# Loss during the recovery countdown restarts the countdown.
	_status(false)
	presentation._process_auto_pause(0.5)
	_status(true)
	presentation._process_auto_pause(0.1)
	presentation._process_auto_pause(1.0)
	_status(false)
	presentation._process_auto_pause(0.5)
	assert(presentation._auto_pause_resuming < 0.0 and get_tree().paused)
	_status(true)
	presentation._process_auto_pause(0.1)
	assert(is_equal_approx(presentation._auto_pause_resuming,3.0))
	presentation._process_auto_pause(3.1)
	assert(not get_tree().paused)
	# Snapshot remains from start and retains all history fields.
	Global.max_rom_angle = 10.0
	var summary: Dictionary = session._build_summary("stopped_early")
	assert(summary.calibration_rom_angle == 74.0 and not summary.has("rom_angle"))
	assert(summary.status == "stopped_early" and summary.target_reps == 20)
	assert(summary.tracking_lost_seconds >= 2.0 and summary.paused_seconds >= 1.0)
	# Real-backend mode must ignore simulator shortcuts.
	var request_before: Dictionary = PoseInput.last_exercise_request.duplicate(true)
	for keycode in [KEY_R,KEY_F,KEY_C,KEY_K,KEY_T]:
		var key := InputEventKey.new()
		key.physical_keycode = keycode
		key.pressed = true
		PoseInput._unhandled_key_input(key)
	assert(session.total_valid_reps == before_reps and PoseInput.last_exercise_request == request_before)
	session.stop_session("scene_changed")
	viewport.queue_free()
	await get_tree().process_frame
	assert(not get_tree().paused)
	print("SELECTIVE_BE_MERGE_PASS: tracking recovery, nested menu, countdown reset, duration/history schema and debug guards")
	get_tree().quit()
