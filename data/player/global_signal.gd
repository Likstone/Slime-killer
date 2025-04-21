extends Node

signal game_paused(paused: bool)

func set_paused(paused: bool):
	get_tree().paused = paused
	emit_signal("game_paused", paused)
