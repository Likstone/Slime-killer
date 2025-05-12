extends Control

func _ready() -> void:
	get_tree().paused = false

func load_level_1():
	GlobalSignal.current_magnet_speed = 100.0
	get_tree().change_scene_to_file("res://data/main/levels/endless_level_1.tscn")

func _on_button_pressed() -> void:
	load_level_1()


func _on_button_3_pressed() -> void:
	get_tree().quit()
