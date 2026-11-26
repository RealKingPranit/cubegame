extends CharacterBody2D

@export var speed: float = 300.0
@export_group("Jump Tuning")
@export var max_jump_height: float = 130.0
@export var time_to_peak: float = 0.35
@export var jump_buffer_window: float = 0.12
@export var gravity_blend_speed: float = 6.0
@export var squash_recovery_speed: float = 14.0

var jump_velocity: float = 0.0
var calculated_gravity: float = 0.0
var target_gravity_multiplier: float = 1.0
var current_gravity_multiplier: float = 1.0
var jump_buffer_counter: float = 0.0
var was_grounded: bool = false
var squash_scale: Vector2 = Vector2.ONE
var trail_timer: float = 0.0
var rect: ColorRect
var is_dead: bool = false

func _ready() -> void:
	update_jump_physics()
	rect = get_node_or_null("ColorRect") as ColorRect
	if rect:
		rect.pivot_offset = rect.size * 0.5

func _unhandled_input(event: InputEvent) -> void:
	if not is_dead and event.is_action_pressed("jump"):
		jump_buffer_counter = jump_buffer_window

func update_jump_physics() -> void:
	if time_to_peak <= 0.0:
		time_to_peak = 0.35
	calculated_gravity = (2.0 * max_jump_height) / pow(time_to_peak, 2.0)
	jump_velocity = -sqrt(2.0 * calculated_gravity * max_jump_height)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	jump_buffer_counter = maxf(0.0, jump_buffer_counter - delta)
	current_gravity_multiplier = move_toward(current_gravity_multiplier, target_gravity_multiplier, delta * gravity_blend_speed)
	var gravity = calculated_gravity * absf(current_gravity_multiplier)
	var grounded = is_on_floor() if current_gravity_multiplier >= 0.0 else is_on_ceiling()

	if grounded and not was_grounded:
		squash_scale = Vector2(1.35, 0.68)
		spawn_burst_particles(6)
		var camera = get_node_or_null("Camera2D")
		if camera and camera.has_method("apply_shake"):
			camera.apply_shake(3.0, 0.12)
	was_grounded = grounded

	if not grounded:
		var moving_away_from_surface = (current_gravity_multiplier >= 0.0 and velocity.y > 0.0) or (current_gravity_multiplier < 0.0 and velocity.y < 0.0)
		var fall_multiplier = 1.8 if moving_away_from_surface else 1.0
		velocity.y += (gravity if current_gravity_multiplier >= 0.0 else -gravity) * fall_multiplier * delta
	else:
		velocity.y = 0.0
		trail_timer -= delta
		if trail_timer <= 0.0:
			trail_timer = 0.075
			spawn_trail_particle()

	if jump_buffer_counter > 0.0 and grounded:
		velocity.y = jump_velocity if current_gravity_multiplier >= 0.0 else -jump_velocity
		jump_buffer_counter = 0.0
		squash_scale = Vector2(0.72, 1.28)
		spawn_burst_particles(8)

	if Input.is_action_just_released("jump"):
		if (current_gravity_multiplier >= 0.0 and velocity.y < 0.0) or (current_gravity_multiplier < 0.0 and velocity.y > 0.0):
			velocity.y *= 0.42

	velocity.x = speed
	move_and_slide()
	squash_scale = squash_scale.lerp(Vector2.ONE, minf(1.0, delta * squash_recovery_speed))
	if rect:
		var gravity_sign = -1.0 if current_gravity_multiplier < 0.0 else 1.0
		rect.scale.x = squash_scale.x
		rect.scale.y = move_toward(rect.scale.y, squash_scale.y * gravity_sign, delta * 15.0)

func spawn_trail_particle() -> void:
	if not rect or not is_inside_tree():
		return
	var particle = ColorRect.new()
	particle.size = Vector2(5.0, 5.0)
	particle.color = Color(0.65, 0.9, 1.0, 0.45)
	particle.global_position = global_position + Vector2(-12.0, rect.size.y * 0.35 * signf(current_gravity_multiplier))
	get_parent().add_child(particle)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(particle, "scale", Vector2.ZERO, 0.28)
	tween.tween_property(particle, "modulate:a", 0.0, 0.28)
	tween.chain().tween_callback(particle.queue_free)

func spawn_burst_particles(count: int) -> void:
	if not rect or not is_inside_tree():
		return
	for i in count:
		var particle = ColorRect.new()
		particle.size = Vector2(4.0, 4.0)
		particle.color = Color(0.65, 0.92, 1.0, 0.9)
		particle.global_position = global_position + Vector2(0.0, rect.size.y * 0.35 * signf(current_gravity_multiplier))
		get_parent().add_child(particle)
		var direction = Vector2(randf_range(-75.0, 40.0), randf_range(-55.0, 55.0))
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "global_position", particle.global_position + direction, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "scale", Vector2.ZERO, 0.28)
		tween.tween_property(particle, "modulate:a", 0.0, 0.28)
		tween.chain().tween_callback(particle.queue_free)
