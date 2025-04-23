extends Area2D

@onready var my_timer : Timer = $Timer
@export var fire_rate = 1.0
@export var chain = 0

func _ready() -> void:
	%Marker2D.position.y -= 100
	my_timer.wait_time = fire_rate
	add_to_group("tesla_gun")

func update_chain(chain_count):
	chain = chain_count

func _physics_process(delta):
	pass

func shoot():
	var enemies_in_range = get_overlapping_bodies()
	var BULLET = preload("res://data/player/lighting_shot.tscn")
	if enemies_in_range.size() > 0:
		var new_bullet = BULLET.instantiate()
		new_bullet.max_bounces = chain
		%Marker2D.add_child(new_bullet)
		
func _on_timer_timeout() -> void:
	shoot()
