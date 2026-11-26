extends Area2D

@export var hit_player_group: String = "player"
@export var death_particle_count: int = 22
@export var death_effect_duration: float = 0.42
var triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if triggered or not (body.name == "Player" or body.is_in_group(hit_player_group)):
		return
	triggered = true
	var rule_manager = get_node_or_null("../RuleManager")
	if rule_manager and rule_manager.has_method("check_and_save_high_score"):
		rule_manager.check_and_save_high_score()
	if body.has_method("set"):
		body.set("is_dead", true)
	body.visible = false
	body.set_physics_process(false)
	var camera = body.get_node_or_null("Camera2D")
	if camera and camera.has_method("apply_shake"):
		camera.apply_shake(16.0, 0.35)
	spawn_death_explosion(body.global_position)
	var hud = get_node_or_null("../HUD")
	if hud and hud.has_method("show_game_over"):
		hud.show_game_over()

func spawn_death_explosion(position: Vector2) -> void:	
	for i in range(death_particle_count):
		var shard = ColorRect.new()
		shard.size = Vector2(randf_range(4.0, 9.0), randf_range(4.0, 9.0))
		shard.color = Color(1.0, 0.35, 0.35) if i % 3 == 0 else Color(0.75, 0.95, 1.0)
		shard.global_position = position
		get_parent().add_child(shard)
		var direction = Vector2(randf_range(-190.0, 190.0), randf_range(-160.0, 160.0))
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(shard, "global_position", position + direction, death_effect_duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween.tween_property(shard, "rotation", randf_range(-PI, PI), death_effect_duration)
		tween.tween_property(shard, "scale", Vector2.ZERO, death_effect_duration)
		tween.tween_property(shard, "modulate:a", 0.0, death_effect_duration)
		tween.chain().tween_callback(shard.queue_free)
