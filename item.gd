extends CharacterBody2D
class_name Item

const GRAVITY := 300.0
const ACCEL := 400.0
const SPIN_SPEED := 0.01
const BOUNCE := 0.5

@export var visible_when_held := true

@export var animation_player: AnimationPlayer
@export var sprite: Sprite2D
@export var bump_sound: AudioStreamPlayer2D
@export var bump_timer: Timer

func use_item(_player: Player):
	pass

func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, ACCEL * delta)
	
	var old_velocity := velocity
	move_and_slide()
	
	animation_player.speed_scale = velocity.length() * SPIN_SPEED
	
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		velocity = old_velocity.bounce(collision.get_normal()) * BOUNCE
		
		if bump_timer.is_stopped():
			bump_sound.play()
		
		bump_timer.start()
