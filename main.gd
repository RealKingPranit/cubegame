extends Node2D

@export var floor_chunk_scene: PackedScene
@export var ceiling_chunk_scene: PackedScene
@export var spike_scene: PackedScene
@export var player: CharacterBody2D
@export_group("World Generation")
@export var chunk_width: float = 2000.0
@export var chunks_ahead: int = 3
@export var floor_y: float = 0.0
@export var base_ceiling_y: float = -280.0
@export var spike_spawn_chance: float = 0.65

var spawn_x: float = 0.0
var active_chunks: Array[Node2D] = []

func _ready() -> void:
	for i in range(chunks_ahead):
		spawn_chunk()

func _process(_delta: float) -> void:
	if not is_instance_valid(player) or player.is_dead:
		return
	if player.global_position.x + chunks_ahead * chunk_width > spawn_x:
		spawn_chunk()
	cleanup_old_chunks()

func spawn_chunk() -> void:
	var rule_manager = get_node_or_null("RuleManager")
	var score = int(rule_manager.distance_score) if rule_manager and "distance_score" in rule_manager else 0
	var tier = int(score / 1000.0)
	var ceiling_y = base_ceiling_y - tier * 40.0
	_spawn_scene(floor_chunk_scene, Vector2(spawn_x, floor_y))
	if spike_scene and randf() < spike_spawn_chance:
		_spawn_spike(Vector2(spawn_x + randf_range(400.0, 1600.0), floor_y + 4.0), false)
	_spawn_scene(ceiling_chunk_scene, Vector2(spawn_x, ceiling_y))
	if spike_scene and randf() < spike_spawn_chance * 0.85:
		_spawn_spike(Vector2(spawn_x + randf_range(400.0, 1600.0), ceiling_y - 4.0), true)
	spawn_x += chunk_width

func _spawn_scene(scene: PackedScene, position: Vector2) -> void:
	if not scene:
		return
	var node = scene.instantiate()
	add_child(node)
	node.global_position = position
	if node is Node2D:
		active_chunks.append(node)

func _spawn_spike(position: Vector2, upside_down: bool) -> void:
	var spike = spike_scene.instantiate()
	add_child(spike)
	spike.global_position = position
	spike.rotation = PI if upside_down else 0.0
	spike.scale = Vector2(randf_range(0.8, 1.65), randf_range(0.85, 2.0))
	if spike is Node2D:
		active_chunks.append(spike)

func cleanup_old_chunks() -> void:	
	if not is_instance_valid(player):
		return
	var cleanup_x = player.global_position.x - chunk_width * 1.5
	for node in active_chunks:
		if not is_instance_valid(node):
			continue
		if node.global_position.x < cleanup_x:
			node.queue_free()
	active_chunks = active_chunks.filter(func(node): return is_instance_valid(node) and node.global_position.x >= cleanup_x)
