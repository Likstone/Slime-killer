extends Area2D

@onready var my_timer : Timer = $Timer
@export var fire_rate = 1.0
@export var chain_radius = 150
@export var chain = 0
@export var attack_radius = 300.0
@onready var collison_radius = $CollisionShape2D
var player
var initial_global_position: Vector2
var distance_traveled: float = 0.0

func _ready() -> void:
	%Marker2D.position.y -= 100
	%CollisionShape2D.position.y -= 100
	my_timer.wait_time = fire_rate
	add_to_group("tesla_gun")
	collison_radius.shape.radius = attack_radius
	initial_global_position = global_position
	player = get_node("/root/Game/Player")
	collison_radius.shape.radius = attack_radius
	
func update_chain(chain_count):
	chain = chain_count

func update_chain_radius(chain_radius_c):
	chain_radius = chain_radius_c
	
func update_attack_radius(attack_radius_c):
	attack_radius = attack_radius_c
	collison_radius.shape.radius = attack_radius_c

func update_distance_traveled():
	distance_traveled = initial_global_position.distance_to(global_position)
	if distance_traveled > 800:
		initial_global_position = global_position
		overdrive_shoot()
	return distance_traveled

func overdrive_shoot():
	var enemies_in_range = get_overlapping_bodies()
	var BULLET = preload("res://data/player/lighting_shot.tscn")
	if enemies_in_range.size() > 2:
		for i in range(enemies_in_range.size()):
			var new_bullet = BULLET.instantiate()
			new_bullet.max_bounces = chain
			new_bullet.bounce_range = chain_radius
			new_bullet.target_number = i
			new_bullet.initial_target_range = attack_radius + 400
			%Marker2D.add_child(new_bullet)

func shoot():
	var enemies_in_range = get_overlapping_bodies()
	var BULLET = preload("res://data/player/lighting_shot.tscn")
	if enemies_in_range.size() > 0:
		var new_bullet = BULLET.instantiate()
		new_bullet.max_bounces = chain
		new_bullet.bounce_range = chain_radius
		new_bullet.target_number = 0
		new_bullet.initial_target_range = attack_radius + 100
		%Marker2D.add_child(new_bullet)
		
		
func _on_timer_timeout() -> void:
	if player.speed_up < 240:
		shoot()
	else:
		shoot()
		update_distance_traveled()
