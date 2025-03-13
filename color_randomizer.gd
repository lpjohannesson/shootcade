extends Node

@export var colors: PackedColorArray

func choose_color() -> Color:
	return colors[randi() % colors.size()]
