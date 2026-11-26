extends Camera2D

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var original_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	original_offset = offset

func apply_shake(intensity: float = 10.0, duration: float = 0.4) -> void:
	shake_intensity = intensity
	shake_duration = duration

func _process(delta: float) -> void:
	if shake_duration > 0:
		shake_duration -= delta
		offset = original_offset + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_intensity
		if shake_duration <= 0:
			offset = original_offset
