extends CanvasLayer

var score_label: Label
var high_score_label: Label
var shift_label: Label
var game_over_panel: Control
var score_value: int = 0
var high_score_value: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hud()

func _build_hud() -> void:
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 20)
	add_child(margin)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	margin.add_child(row)
	var left_stack = VBoxContainer.new()
	left_stack.add_theme_constant_override("separation", 3)
	row.add_child(left_stack)
	score_label = _make_label("DIST  0000m", 26, Color(0.9, 0.97, 1.0))
	left_stack.add_child(score_label)
	high_score_label = _make_label("BEST  0000m", 16, Color(0.55, 0.75, 0.85))
	left_stack.add_child(high_score_label)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	shift_label = _make_label("READY", 26, Color(1.0, 0.88, 0.35))
	shift_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	shift_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	row.add_child(shift_label)

func _make_label(text_value: String, size: int, color: Color) -> Label:
	var label = Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.65))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label

func update_score(score: float) -> void:
	score_value = int(score)
	if score_label:
		score_label.text = "DIST  %04dm" % score_value

func update_high_score(score: int) -> void:
	high_score_value = score
	if high_score_label:
		high_score_label.text = "BEST  %04dm" % high_score_value

func show_shift_text(text_value: String, tint: Color = Color(1.0, 0.88, 0.35)) -> void:
	if not shift_label:
		return
	shift_label.text = text_value
	shift_label.add_theme_color_override("font_color", tint)
	shift_label.scale = Vector2(1.18, 1.18)
	var tween = create_tween()
	tween.tween_property(shift_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func show_game_over() -> void:
	if game_over_panel:
		return
	game_over_panel = Control.new()
	game_over_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_panel.modulate.a = 0.0
	add_child(game_over_panel)
	var overlay = ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.015, 0.025, 0.045, 0.86)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	game_over_panel.add_child(overlay)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_panel.add_child(center)
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(360, 260)
	center.add_child(panel)
	var box = VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var title = _make_label("RUN ENDED", 42, Color(1.0, 0.35, 0.35))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var score = _make_label("DISTANCE  %dm" % score_value, 24, Color(0.92, 0.98, 1.0))
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(score)
	var best = _make_label("BEST  %dm" % high_score_value, 18, Color(0.65, 0.82, 0.92))
	best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(best)
	var button = Button.new()
	button.text = "RUN AGAIN"
	button.custom_minimum_size = Vector2(210, 52)
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	box.add_child(button)
	get_tree().paused = true
	var fade = create_tween()
	fade.tween_property(game_over_panel, "modulate:a", 1.0, 0.25)
