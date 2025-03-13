extends Node2D
class_name Bullet

const BULLET_SPEED := 200.0

@export var boom_scene: PackedScene

var velocity := Vector2.ZERO
var query := PhysicsRayQueryParameters2D.new()

func stop_bullet() -> void:
	var boom: Node2D = boom_scene.instantiate()
	get_parent().add_child(boom)
	
	boom.global_position = global_position
	boom.modulate = ColorRandomizer.choose_color()
	
	queue_free()

func _ready() -> void:
	modulate = ColorRandomizer.choose_color()
	
	query.hit_from_inside = true

func _physics_process(delta: float) -> void:
	var next_position := global_position + velocity * delta
	
	query.from = global_position
	query.to = next_position
	
	var space_state := get_world_2d().direct_space_state
	var result := space_state.intersect_ray(query)
	
	if not result.is_empty():
		global_position = result.position
		stop_bullet()
		return
	
	global_position = next_position

func _on_color_timer_timeout() -> void:
	modulate = ColorRandomizer.choose_color()
