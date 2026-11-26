extends GPUParticles2D

@export var player: CharacterBody2D
@export var normal_speed: float = 300.0
@export var base_particle_speed_min: float = 800.0
@export var base_particle_speed_max: float = 1400.0
@export var boost_intensity: float = 1.45

func _ready() -> void:
	z_index = -10
	var material = ParticleProcessMaterial.new()
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(600.0, 350.0, 1.0)
	material.direction = Vector3(-1.0, 0.0, 0.0)
	material.spread = 0.0
	material.initial_velocity_min = base_particle_speed_min
	material.initial_velocity_max = base_particle_speed_max
	material.gravity = Vector3.ZERO
	material.scale_min = 0.65
	material.scale_max = 1.8
	material.color = Color(0.65, 0.85, 1.0, 0.75)
	process_material = material
	amount = 48
	lifetime = 0.75
	one_shot = false
	preprocess = 0.4
	emitting = true

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		return
	global_position = Vector2(player.global_position.x + 240.0, player.global_position.y)
	var ratio = maxf(player.speed / maxf(normal_speed, 1.0), 0.0)
	speed_scale = clampf(ratio, 0.65, boost_intensity)
