extends CharacterBody2D
class_name Bullet

const BULLET_SPEED := 200.0

@export var boom_scene: PackedScene
@export var colors: PackedColorArray

func choose_color() -> Color:
	return colors[randi_range(0, colors.size() - 1)]

func stop_bullet() -> void:
	var boom: Node2D = boom_scene.instantiate()
	get_parent().add_child(boom)
	
	boom.global_position = global_position
	boom.modulate = choose_color()
	
	queue_free()

func _ready() -> void:
	modulate = choose_color()

func _physics_process(delta: float) -> void:
	if test_move(transform, Vector2.ZERO):
		stop_bullet()
		return
	
	move_and_slide()
	
	if get_slide_collision_count() > 0:
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			
			if not collision.get_collider() is StaticBody2D:
				continue
			
			collision.get_collider().queue_free()
		
		stop_bullet()
		return

func _on_color_timer_timeout() -> void:
	modulate = choose_color()
