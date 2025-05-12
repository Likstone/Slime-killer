extends Area2D

var orbit_speed: float = 3.0
var orbit_center_offset := Vector2(0, -30)
var rotation_speed: float = 8.0
@onready var my_timer : Timer = $Timer

@export var gun_count = 0
@export var start_angle: float = 100.0
@export var fire_rate = 0.6
var angle: float = 0
@export var bullet_count = 1
var spread_angle

func _ready() -> void:
	my_timer.wait_time = fire_rate
	add_to_group("main_guns")

func change_bullet_count(bullet_c):
	bullet_count = bullet_c

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
	else:
		var target_pos: Vector2
		match gun_count:
			0: 
				target_pos = orbit_center_offset + Vector2(0, 0)  # Правая позиция
				rotation = lerp_angle(rotation, 0, rotation_speed * delta)
			1: 
				target_pos = orbit_center_offset + Vector2(0, 0) # Левая позиция
				rotation = lerp_angle(rotation, PI, rotation_speed * delta)
		
		# Плавное перемещение к целевой позиции
		position = position.lerp(target_pos, rotation_speed * delta)
		angle = position.angle()  # Обновляем угол для плавности

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
	if bullet_count == 2:
		spread_angle = deg_to_rad(10)
	else:
		spread_angle = deg_to_rad(25)
	
	if bullet_count > 1:
		if enemies_in_range.size() > gun_count:
			for i in range(bullet_count):
				var new_bullet = BULLET.instantiate()
				new_bullet.global_position = %ShootingPoint.global_position
				
				# Вычисляем угол для текущей пули (равномерный разброс)
				var angle_offset = lerp(-spread_angle, spread_angle, float(i) / (bullet_count - 1))
				new_bullet.global_rotation = %ShootingPoint.global_rotation + angle_offset
				get_parent().add_child(new_bullet)
	else:
		var new_bullet = BULLET.instantiate()
		new_bullet.global_position = %ShootingPoint.global_position
		new_bullet.global_rotation = %ShootingPoint.global_rotation
		if enemies_in_range.size() > gun_count:
			%ShootingPoint.add_child(new_bullet)

func _on_timer_timeout() -> void:
	shoot()
