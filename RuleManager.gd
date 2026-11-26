extends Node

@export var player: CharacterBody2D
@export var shift_interval: float = 6.0
@export var warning_duration: float = 1.5
@export var base_speed: float = 300.0
@export var boost_speed: float = 500.0

var shift_timer: Timer
var warning_timer: Timer
var current_rule: int = 0
enum Rules { NORMAL, LOW_GRAVITY, SPEED_BOOST, REVERSE_GRAVITY }
var distance_score: float = 0.0
var high_score: int = 0
const SAVE_PATH: String = "user://highscore.save"
var hud: CanvasLayer
var shift_flash: ColorRect
var warning_active: bool = false
var previous_rule: int = -1

func _ready() -> void:
	high_score = load_high_score()
	hud = get_node_or_null("../HUD") as CanvasLayer
	_create_shift_flash()
	shift_timer = Timer.new()
	shift_timer.wait_time = maxf(shift_interval, 2.0)
	shift_timer.one_shot = false
	shift_timer.timeout.connect(_on_shift_timeout)
	add_child(shift_timer)
	shift_timer.start()
	warning_timer = Timer.new()
	warning_timer.one_shot = true
	warning_timer.wait_time = maxf(shift_interval - warning_duration, 0.5)
	warning_timer.timeout.connect(_on_warning_timeout)
	add_child(warning_timer)
	warning_timer.start()
	if hud and hud.has_method("update_high_score"):
		hud.update_high_score(high_score)
	show_rule("READY • RUN!")

func _process(delta: float) -> void:
	if player and not player.is_dead:
		distance_score += maxf(player.speed, 0.0) * delta * 0.05
		if hud and hud.has_method("update_score"):
			hud.update_score(distance_score)
		check_and_save_high_score()

func _create_shift_flash() -> void:
	var layer = CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	shift_flash = ColorRect.new()
	shift_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shift_flash.color = Color(0.4, 0.85, 1.0, 0.0)
	shift_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(shift_flash)

func check_and_save_high_score() -> void:
	var score = int(distance_score)
	if score > high_score:
		high_score = score
		save_high_score(high_score)
		if hud and hud.has_method("update_high_score"):
			hud.update_high_score(high_score)

func save_high_score(score: int) -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"high_score": score}))

func load_high_score() -> int:
	if not FileAccess.file_exists(SAVE_PATH):
		return 0
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return 0
	var parsed = JSON.parse_string(file.get_as_text())
	return int(parsed.get("high_score", 0)) if parsed is Dictionary else 0

func _on_shift_timeout() -> void:
	if not player or player.is_dead:
		return
	var next_rule = randi_range(0, Rules.size() - 1)
	if Rules.size() > 1 and next_rule == previous_rule:
		next_rule = (next_rule + randi_range(1, Rules.size() - 1)) % Rules.size()
	previous_rule = next_rule
	current_rule = next_rule
	apply_rule(current_rule)
	_flash_shift()
	var camera = player.get_node_or_null("Camera2D")
	if camera and camera.has_method("apply_shake"):
		camera.apply_shake(7.0, 0.22)

func apply_rule(rule: Rules) -> void:
	player.speed = base_speed
	player.target_gravity_multiplier = 1.0
	var display_text = "NORMAL RUN"
	var tint = Color(0.75, 0.95, 1.0)
	match rule:
		Rules.NORMAL:
			display_text = "NORMAL RUN"
			tint = Color(0.75, 0.95, 1.0)
		Rules.LOW_GRAVITY:
			display_text = "LOW GRAVITY"
			tint = Color(0.75, 0.65, 1.0)
			player.target_gravity_multiplier = 0.4
		Rules.SPEED_BOOST:
			display_text = "HYPER SPEED"
			tint = Color(1.0, 0.8, 0.3)
			player.speed = boost_speed
		Rules.REVERSE_GRAVITY:
			display_text = "GRAVITY FLIPPED"
			tint = Color(0.45, 0.9, 1.0)
			player.target_gravity_multiplier = -1.0
	show_rule("SHIFT • " + display_text, tint)

func show_rule(message: String, tint: Color = Color(1.0, 0.9, 0.3)) -> void:
	if hud and hud.has_method("show_shift_text"):
		hud.show_shift_text(message, tint)

func _flash_shift() -> void:
	if not shift_flash:
		return
	var tween = create_tween()
	shift_flash.color = Color(0.45, 0.85, 1.0, 0.0)
	tween.tween_property(shift_flash, "color:a", 0.18, 0.08)
	tween.tween_property(shift_flash, "color:a", 0.0, 0.32)

func _on_warning_timeout() -> void:
	warning_flash()
	warning_timer.wait_time = shift_interval
	warning_timer.start()

func warning_flash() -> void:
	if not shift_flash or warning_active:
		return
	warning_active = true
	var tween = create_tween()
	for i in range(2):
		tween.tween_property(shift_flash, "color", Color(1.0, 0.75, 0.25, 0.16), 0.12)
		tween.tween_property(shift_flash, "color:a", 0.0, 0.16)
	tween.tween_callback(func(): warning_active = false)
