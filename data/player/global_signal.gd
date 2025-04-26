extends Node

signal game_paused(paused: bool)

var current_magnet_speed: float = 100.0

func set_paused(paused: bool):
	get_tree().paused = paused
	emit_signal("game_paused", paused)
