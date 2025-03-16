extends CharacterBody2D
class_name Player

const STAND_SPEED := 100.0
const CROUCH_SPEED := 60.0
const BULLET_OFFSET := 4.0
const THROW_FORCE := Vector2(150.0, 50.0)
const THROW_FOLLOW := 0.75

const GROUND_ACCEL := 800.0
const AIR_ACCEL := 400.0

const JUMP_VELOCITY := 200.0
const JUMP_STOP := 0.5
const GRAVITY := 400.0

@export var sprites: Node2D
@export var top_sprite: Sprite2D
@export var bottom_sprite: Sprite2D

@export var top_animator: AnimationPlayer
@export var bottom_animator: AnimationPlayer
@export var aim_animator: AnimationPlayer

@export var stand_collider: CollisionShape2D
@export var crouch_collider: CollisionShape2D

@export var crouch_area: Area2D
@export var pickup_area: Area2D
@export var punch_area: Area2D

@export var bullet_forward: RayCast2D
@export var bullet_up: RayCast2D
@export var bullet_down: RayCast2D

@export var throw_point: Node2D

@export var item_origin: Node2D

@export var top_forward_texture: Texture2D
@export var top_up_texture: Texture2D
@export var top_down_texture: Texture2D

@export var jump_timer: Timer
@export var coyote_timer: Timer
@export var punch_timer: Timer
@export var pickup_timer: Timer

@export var jump_sound: AudioStreamPlayer2D
@export var fire_sound: AudioStreamPlayer2D
@export var pickup_sound: AudioStreamPlayer2D
@export var throw_sound: AudioStreamPlayer2D

@export var punch_effect_scene: PackedScene

var input_direction := Vector2.ZERO
var aim_direction := Vector2.RIGHT

var crouching := false
var jump_stopped := false
var can_stand := false

var held_item: Item

func aim() -> void:
	if Input.is_action_pressed("lock_aim"):
		return
	
	if input_direction.x != 0.0:
		aim_direction.x = input_direction.x
	
	aim_direction.y = input_direction.y
	
	sprites.scale.x = aim_direction.x

func crouch() -> void:
	if not can_stand:
		return
	
	crouching = is_on_floor() and Input.is_action_pressed("crouch")
	stand_collider.disabled = crouching
	crouch_collider.disabled = not crouching

func try_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		jump_timer.start()
	
	if is_on_floor():
		coyote_timer.start()
	
	if jump_timer.is_stopped() or coyote_timer.is_stopped():
		return
	
	if not can_stand:
		return
	
	jump_timer.stop()
	coyote_timer.stop()
	
	velocity.y = -JUMP_VELOCITY
	jump_stopped = false
	
	jump_sound.play()

func try_stop_jump() -> void:
	if jump_stopped:
		return
	
	if velocity.y >= 0.0:
		return
	
	if Input.is_action_pressed("jump"):
		return
	
	jump_stopped = true
	velocity.y *= JUMP_STOP

func walk(delta: float) -> void:
	var accel: float
	
	if is_on_floor():
		accel = GROUND_ACCEL
	else:
		if input_direction.x == 0.0:
			return
		
		accel = AIR_ACCEL
	
	var max_speed: float
	
	if crouching:
		max_speed = CROUCH_SPEED
	else:
		max_speed = STAND_SPEED
	
	velocity.x = move_toward(velocity.x, input_direction.x * max_speed, accel * delta)

func move(delta: float) -> void:
	velocity.y += GRAVITY * delta
	
	if is_on_floor():
		jump_stopped = true
	else:
		try_stop_jump()
	
	try_jump()
	walk(delta)
	
	move_and_slide()

func try_punch() -> void:
	if Input.is_action_just_pressed("fire"):
		punch_timer.start()
		pickup_sound.play()
	
	if punch_timer.is_stopped():
		return
	
	var punch_hit := false
	
	for body in punch_area.get_overlapping_bodies():
		if not body is Item:
			continue
		
		punch_hit = true
		
		body.velocity = get_throw_velocity(true)
		
		var effect: PunchEffect = punch_effect_scene.instantiate()
		get_parent().add_child(effect)
		effect.global_position = body.global_position
	
	if punch_hit:
		punch_timer.stop()
		fire_sound.play()
	
	top_animator.play("punch")

func get_shoot_direction() -> Vector2:
	if aim_direction.y == 0.0:
		return Vector2(aim_direction.x, 0.0)
	else:
		return Vector2(0.0, aim_direction.y)

func fire_bullet(bullet_scene: PackedScene):
	var bullet: Bullet = bullet_scene.instantiate()
	get_parent().add_child(bullet)
	
	var bullet_cast: RayCast2D
	
	match aim_direction.y:
		0.0:
			bullet_cast = bullet_forward
		-1.0:
			bullet_cast = bullet_up
		1.0:
			bullet_cast = bullet_down
	
	var shoot_direction := get_shoot_direction()
	
	bullet.velocity = shoot_direction * Bullet.BULLET_SPEED
	bullet.rotation = shoot_direction.angle()
	
	if bullet_cast.is_colliding():
		bullet.global_position = bullet_cast.get_collision_point()
	else:
		bullet.global_position = bullet_cast.to_global(
			bullet_cast.target_position - bullet_cast.target_position.normalized() * BULLET_OFFSET)
	
	bullet.query.exclude = [self]
	
	fire_sound.play()
	top_animator.play("fire")

func try_use_item() -> void:
	if not Input.is_action_just_pressed("fire"):
		return
	
	held_item.use_item(self)

func pickup_item(item: Item) -> void:
	pickup_timer.stop()
	punch_timer.stop()
	
	held_item = item
	item.get_parent().remove_child(item)
	
	item_origin.add_child(item)
	item.sprite.rotation = 0.0
	
	if item.visible_when_held:
		item.position = Vector2.ZERO
	else:
		item.visible = false
	
	item.process_mode = Node.PROCESS_MODE_DISABLED
	
	pickup_sound.play()

func get_throw_velocity(up_on_side: bool) -> Vector2:
	if aim_direction.y == 1.0 and is_on_floor():
		return Vector2.ZERO
	else:
		var throw_velocity := velocity * THROW_FOLLOW + get_shoot_direction() * THROW_FORCE.x
		
		if aim_direction.y == 1.0:
			return throw_velocity
		
		if not crouching or (up_on_side and aim_direction.y == 0.0):
			throw_velocity.y -= THROW_FORCE.y
		
		return throw_velocity

func throw_item() -> void:
	item_origin.remove_child(held_item)
	get_parent().add_child(held_item)
	
	held_item.process_mode = Node.PROCESS_MODE_INHERIT
	held_item.visible = true
	
	held_item.global_position = throw_point.global_position
	held_item.velocity = get_throw_velocity(false)
	
	held_item = null
	
	throw_sound.play()
	top_animator.play("throw")

func try_pickup_item() -> void:
	if Input.is_action_just_pressed("pickup"):
		pickup_timer.start()
	
	if pickup_timer.is_stopped():
		return
	
	for body in pickup_area.get_overlapping_bodies():
		if not body is Item:
			continue
		
		pickup_item(body)
		break

func try_throw_item() -> void:
	if not Input.is_action_just_pressed("pickup"):
		return
	
	throw_item()

func animate_top() -> void:
	match aim_direction.y:
		0.0:
			aim_animator.play("forward")
		-1.0:
			aim_animator.play("up")
		1.0:
			aim_animator.play("down")
	
	if top_animator.current_animation in ["fire", "throw", "punch"]:
		return
	
	if held_item == null:
		top_animator.play("idle")
	else:
		if held_item.visible_when_held:
			top_animator.play("hold")
		else:
			top_animator.play("gun_idle")

func animate_bottom() -> void:
	if is_on_floor():
		if input_direction.x == 0.0:
			if crouching:
				bottom_animator.play("crouch")
			else:
				bottom_animator.play("stand")
		else:
			if crouching:
				bottom_animator.play("crawl")
			else:
				bottom_animator.play("walk")
	else:
		if velocity.y < 0.0:
			bottom_animator.play("jump")
		else:
			bottom_animator.play("fall")

func animate() -> void:
	animate_top()
	animate_bottom()

func get_can_stand() -> bool:
	var bodies := crouch_area.get_overlapping_bodies()
	
	for body in bodies:
		if body == self:
			continue
		
		return false
	
	return true

func _physics_process(delta: float) -> void:
	input_direction = Input.get_vector(
		"move_left",
		"move_right",
		"aim_up",
		"aim_down").round()
	
	can_stand = get_can_stand()
	
	aim()
	crouch()
	
	if held_item == null:
		try_punch()
		try_pickup_item()
	else:
		try_use_item()
		try_throw_item()
	
	move(delta)
	animate()
	
	if Input.is_action_just_pressed("pause"):
		get_tree().reload_current_scene()
