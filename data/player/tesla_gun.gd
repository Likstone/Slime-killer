extends Area2D

@onready var my_timer : Timer = $Timer
@onready var overdrive_timer : Timer = $overdrive_timer
@export var fire_rate = 1.0
@export var chain_radius = 150
@export var chain = 0
@export var attack_radius = 300.0
@onready var collison_radius = $CollisionShape2D
@export var tesla_damage = 1
var overdrive_flag = false
var player
var initial_global_position: Vector2
var distance_traveled: float = 0.0

func _ready() -> void:
	%Marker2D.position.y -= 115
	%CollisionShape2D.position.y -= 115
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

func update_tesla_damage(tesla_damage_c):
	tesla_damage = tesla_damage_c

func overdrive_shoot():
	var enemies_in_range = get_overlapping_bodies()
	var BULLET = preload("res://data/player/lighting_shot.tscn")
	if enemies_in_range.size() > 6:
		for i in range(10):
			var new_bullet = BULLET.instantiate()
			new_bullet.max_bounces = chain
			new_bullet.bounce_range = chain_radius
			new_bullet.target_number = i
			new_bullet.damage = tesla_damage
			new_bullet.initial_target_range = attack_radius + 400
			%Marker2D.add_child(new_bullet)
			SoundManager.electro_shoot()

func shoot():
	var enemies_in_range = get_overlapping_bodies()
	var BULLET = preload("res://data/player/lighting_shot.tscn")
	if enemies_in_range.size() > 0:
		var new_bullet = BULLET.instantiate()
		new_bullet.max_bounces = chain
		new_bullet.bounce_range = chain_radius
		new_bullet.target_number = 0
		new_bullet.damage = tesla_damage
		new_bullet.initial_target_range = attack_radius + 100
		%Marker2D.add_child(new_bullet)
		SoundManager.electro_shoot()
		
		
func _on_timer_timeout() -> void:
	shoot()
	if player.speed_up >= 240:
		overdrive_timer.autostart = true
		overdrive_timer.start()
		
func _on_overdrive_timer_timeout() -> void:
		overdrive_shoot()
