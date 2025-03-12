extends Item
class_name Pistol

@export var bullet_scene: PackedScene

func use_item(player: Player):
	player.fire_bullet(bullet_scene)
