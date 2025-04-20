extends Area2D

@onready var fire_rate : Timer = $Fire_rate_time
@export var shoot_point: Marker2D

func _ready() -> void:
	%Marker2D.position.y -= 100
	fire_rate.wait_time = 1
	fire_rate.one_shot = false
	fire_rate.start()
	
func shoot():
	var enemies_in_range = get_overlapping_bodies()
	if enemies_in_range.is_empty():
		return
	else:		
		const BULLET = preload("res://data/player/lighting_shot.tscn")
		var new_bullet = BULLET.instantiate()
		get_parent().add_child(new_bullet)
		new_bullet.global_position = %Marker2D.global_position

func _on_fire_rate_time_timeout() -> void:
	shoot()
