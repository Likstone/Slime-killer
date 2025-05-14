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
	
	if enemies_in_range.size() > gun_count:
		# Получаем отсортированный список врагов по расстоянию
		var sorted_enemies = _get_sorted_enemies_by_distance(enemies_in_range)
		
		# Выбираем врага согласно gun_count (0 - ближайший, 1 - второй и т.д.)
		var target_enemy = sorted_enemies[gun_count % sorted_enemies.size()]
		
		angle += orbit_speed * delta
		position = orbit_center_offset + Vector2(cos(angle), sin(angle))
		
		var target_angle = (target_enemy.global_position - global_position).angle()
		rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)
		attack_ready = true
	else:
		angle += orbit_speed * delta
		position = orbit_center_offset + Vector2(cos(angle), sin(angle))
		rotation = lerp_angle(rotation, angle, rotation_speed * delta)
		attack_ready = false

func _get_sorted_enemies_by_distance(enemies):
	var enemy_distances = []
	
	# Создаем массив с врагами и их расстояниями
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		enemy_distances.append({"enemy": enemy, "distance": distance})
	
	# Сортируем по расстоянию (от ближнего к дальнему)
	enemy_distances.sort_custom(func(a, b): return a["distance"] < b["distance"])
	
	# Возвращаем только врагов (без расстояний) в отсортированном порядке
	return enemy_distances.map(func(item): return item["enemy"])

func shoot():
	var enemies_in_range = get_overlapping_bodies()
	var BULLET = preload("res://data/player/bullet.tscn")
	var new_bullet = BULLET.instantiate()
	
	# Настройки пули
	new_bullet.SPEED = bullet_speed
	new_bullet.modulate = Color(1, 0, 0)
	new_bullet.scale = Vector2(4.0, 1)
	new_bullet.penetration_flag = true
	new_bullet.damage = damage
	
	# Позиция и направление
	new_bullet.global_position = %ShootingPoint.global_position
	new_bullet.global_rotation = %ShootingPoint.global_rotation
	if enemies_in_range.size() > gun_count:
		%ShootingPoint.add_child(new_bullet)
		SoundManager.laser_shoot()
		
func _on_timer_timeout() -> void:
	if attack_ready:
		shoot()
