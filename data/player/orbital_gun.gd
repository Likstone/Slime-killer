extends Area2D

var orbit_speed: float = 6.0
var orbit_center_offset := Vector2(0, -50)
var rotation_speed: float = 8.0
@onready var my_timer : Timer = $Timer

@export var gun_count = 0
@export var start_angle: float = 100.0
@export var fire_rate = 1.5
@export var bullet_speed = 800
var angle: float = 0
var attack_ready
@export var damage = 1

func _ready() -> void:
	my_timer.wait_time = fire_rate
	add_to_group("orbital_guns")

func update_firerate(firerate):
	my_timer.wait_time = firerate
	
func change_rotation_speed(rotation_speeds):
	rotation_speed = rotation_speeds

func change_bullet_speed(bullet_speeds):
	bullet_speed = bullet_speeds

func change_damage(dmg):
	damage = dmg

func _physics_process(delta):
	var enemies_in_range = get_overlapping_bodies()
	var orbit_pos = Vector2(cos(angle), sin(angle))
	
	# Ищем цель по приоритету
	var target_enemy = null
	for i in range(gun_count, -1, -1):  # Проверяем индексы 3, 2, 1, 0
		if i < enemies_in_range.size():
			target_enemy = enemies_in_range[i]
			break
	
	if target_enemy:
		position = orbit_center_offset + orbit_pos
		var target_angle = (target_enemy.global_position - global_position).angle()
		rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)
		var angle_diff = abs(fposmod(rotation - target_angle + PI, PI * 2) - PI)
		var angle_threshold = 0.1  # Порог в радианах (примерно 5.7 градусов)
		attack_ready = angle_diff < angle_threshold
	else:
		angle += orbit_speed * delta
		position = orbit_center_offset + Vector2(cos(angle), sin(angle))
		rotation = lerp_angle(rotation, angle, rotation_speed * delta)
		attack_ready = false

func shoot():
	var enemies_in_range = get_overlapping_bodies()
	var BULLET = preload("res://data/player/bullet.tscn")
	
	# Ищем цель по тому же приоритету
	var target_index = -1
	for i in range(gun_count, -1, -1):
		if i < enemies_in_range.size():
			target_index = i
			break
	
	if target_index >= 0:
		var new_bullet = BULLET.instantiate()
		new_bullet.SPEED = bullet_speed
		new_bullet.modulate = Color(1, 0, 0)
		new_bullet.scale = Vector2(4.0, 1)
		new_bullet.penetration_flag = true
		new_bullet.damage = damage
		new_bullet.global_position = %ShootingPoint.global_position
		
		# Направляем пулю в выбранную цель
		var target_enemy = enemies_in_range[target_index]
		var direction = (target_enemy.global_position - %ShootingPoint.global_position).normalized()
		new_bullet.global_rotation = direction.angle()
		%ShootingPoint.add_child(new_bullet)
		
func _on_timer_timeout() -> void:
	if attack_ready:
		shoot()
