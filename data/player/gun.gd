extends Area2D

var orbit_speed: float = 3.0
var orbit_center_offset := Vector2(0, -50)
var rotation_speed: float = 8.0
@onready var my_timer : Timer = $Timer

@export var gun_count = 0
@export var start_angle: float = 100.0
@export var fire_rate = 1.6
var angle: float = 0

func _ready() -> void:
	my_timer.wait_time = fire_rate

func _physics_process(delta):
	var enemies_in_range = get_overlapping_bodies()
	var orbit_pos = Vector2(cos(angle), sin(angle))
	
	if enemies_in_range.size() > gun_count:
		var target_enemy = enemies_in_range[gun_count]
		position = orbit_center_offset + orbit_pos

		var target_angle = (target_enemy.global_position - global_position).angle()
		rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)
	else:
		angle += orbit_speed * delta
		position = orbit_center_offset + Vector2(cos(angle), sin(angle))
		rotation = lerp_angle(rotation, angle, rotation_speed * delta)

func shoot():
	var enemies_in_range = get_overlapping_bodies()
	const BULLET = preload("res://data/player/bullet.tscn")
	var new_bullet = BULLET.instantiate()
	new_bullet.global_position = %ShootingPoint.global_position
	new_bullet.global_rotation = %ShootingPoint.global_rotation
	if enemies_in_range.size() > gun_count:
		%ShootingPoint.add_child(new_bullet)

func change_firerate():
	if my_timer.wait_time >= 0.1:
		my_timer.wait_time -= 0.4
	else:
		print("firerate is max")

func _on_timer_timeout() -> void:
	shoot()
