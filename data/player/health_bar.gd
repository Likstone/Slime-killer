extends Area2D

enum MODE {ATTACK, STATIK}
var current_mode = 	MODE.STATIK

var orbit_speed: float = 10.0
var orbit_center_offset := Vector2(0, -130)
var rotation_speed: float = 180.0
var angle = 0.0
var orbit_radius = 130.0

var self_rotation_angle: float = 0.0
var self_rotation_speed: float = 30.0
var transition_started := false
var transition_angle := 0.0
var initial_offset := Vector2.ZERO
var transition_progress := 0.0

var new_orbit_center = Vector2(0, -50)  # Новый центр (пример)
var center_transition_progress = 0.0 # Прогресс смещения центра
var center_transition_speed = 1.0

@export var health_value = 0
@export var health_max_value = 0

var level = 1
var damage = 1
var ignore_delta_in_rotation := false
func _ready():
	# Запоминаем начальное смещение относительно центра орбиты
	initial_offset = position - (orbit_center_offset + Vector2(0, 130))
	health_value = %HealthBar.value
	health_max_value = %HealthBar.max_value

func _process(delta):
	match current_mode:
		MODE.ATTACK:
			# Плавное наращивание перехода в режим атаки
			transition_progress = min(transition_progress + delta, 1.0)
			
			# Плавное смещение центра (если нужно)
			center_transition_progress = min(center_transition_progress + delta * center_transition_speed, 1.0)
			
			# Текущий центр (сначала переход в (0, -50), затем в new_orbit_center)
			var initial_attack_center = orbit_center_offset.lerp(Vector2(0, -240), transition_progress)
			var current_center = initial_attack_center.lerp(new_orbit_center, center_transition_progress)
			
			# Плавное изменение радиуса
			var current_radius = lerp(initial_offset.length(), orbit_radius, transition_progress)
			
			# Обновляем угол
			angle += orbit_speed * delta * transition_progress
			
			# Вычисляем позицию
			position = current_center + Vector2(cos(angle) * current_radius, sin(angle) * current_radius)
			
			# Поворачиваем объект по направлению движения
			if ignore_delta_in_rotation and level >= 6:
				rotation += self_rotation_speed * delta
			else:
				rotation = lerp_angle(rotation, angle, rotation_speed * delta)
			
		_:
			# Возврат в исходное состояние
			transition_progress = 0.0
			center_transition_progress = 0.0
			angle = 0.0
			position = orbit_center_offset
	
func _on_body_entered(body: Node2D) -> void:
	match current_mode:
		MODE.ATTACK:
			if body.has_method("take_damage"):
				body.take_damage(damage)

func start_attack():
	current_mode = MODE.ATTACK
	match level:
		1: 
			orbit_speed = 6
			%HealthBar.modulate = Color(1.0, 0.87, 0.87)
		2: 
			%HealthBar.modulate = Color(1.0, 0.75, 0.75)
			%HealthBar.custom_minimum_size = Vector2(120, 20)
			%HealthBar.scale = Vector2(1.5, 1.5)
			if %CollisionShape2D.shape is CapsuleShape2D:
				%CollisionShape2D.shape.radius *= 1.5
				%CollisionShape2D.shape.height *= 1.5
				$CollisionShape2D.position = Vector2(35, 5)
		3: 
			%HealthBar.modulate = Color(1.0, 0.6, 0.6)
			%HealthBar.custom_minimum_size = Vector2(160, 20)
			%HealthBar.scale = Vector2(1.5, 1.5)
			if %CollisionShape2D.shape is CapsuleShape2D:
				%CollisionShape2D.shape.radius *= 1.2
				%CollisionShape2D.shape.height = 235
				$CollisionShape2D.position = Vector2(55, 5)
		4: 
			orbit_speed = 8
			%HealthBar.modulate = Color(1.0, 0.43, 0.43, 0.903)
		5: 
			orbit_speed = 10
			%HealthBar.modulate = Color(1.0, 0.34, 0.34, 0.803)
		6: 
			ignore_delta_in_rotation = true
			%HealthBar.modulate = Color(1.0, 0.27, 0.27, 0.703)
		7: 
			%HealthBar.modulate = Color(1.0, 0.17, 0.17, 0.603)
			orbit_speed = 12
			orbit_radius += 120
			self_rotation_speed = 45
		8: 
			%HealthBar.modulate = Color(1.0, 0.12, 0.12, 0.503)
			if %HealthBar.max_value >= 200:
				damage = 3
			else:
				damage = 2
	level+=1

func end_attack():
	current_mode = MODE.STATIK

func health_max_add(health):
	%HealthBar.max_value += health
	health_max_value = %HealthBar.max_value

func health_dmg(dmg):
	%HealthBar.value -= dmg
	health_value = %HealthBar.value

func health_add(health):
	%HealthBar.value += health
	health_value = %HealthBar.value
