extends Node2D

# Настройки молнии
@export var damage: int = 1
@export var segment_duration: float = 0.1
@export var segments: int = 100
@export var width: float = 2.0
@export var color: Color = Color(0.7, 0.8, 1.0)
@export var max_bounces: int = 3
@export var bounce_range: float = 300.0
@export var initial_target_range: float = 400.0

var current_target: Node2D = null
var time_alive: float = 0.0
var bounce_count: int = 0
var hit_mobs: Array[Node2D] = []
var current_origin: Vector2
var is_tracking: bool = false
var was_paused: bool = false # Флаг паузы

func _ready():
	current_origin = global_position
	find_initial_target()
	if not current_target:
		queue_free()
		return
	start_tracking()
	
	# Подписываемся на уведомления о паузе
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta):
	# Пропускаем обновление, если игра на паузе
	if get_tree().paused:
		was_paused = true
		return
	
	# Если была пауза - сбрасываем таймер
	if was_paused:
		time_alive = 0.0
		was_paused = false
	
	time_alive += delta
	
	if is_tracking:
		queue_redraw()
		
		if time_alive >= segment_duration:
			complete_strike()
	else:
		if time_alive >= segment_duration:
			try_bounce_or_free()

func _draw():
	if not current_target or not is_tracking:
		return
	
	var start = to_local(current_origin)
	var end = to_local(current_target.global_position)
	draw_lightning_segment(start, end)

func draw_lightning_segment(start: Vector2, end: Vector2):
	var dir = (end - start).normalized()
	var length = start.distance_to(end)
	end.y -= 20
	
	var points = [start]
	for i in range(1, segments):
		var point = start + dir * (length * i/segments)
		point += Vector2(randf_range(-10, 10), randf_range(-10, 10)).rotated(dir.angle())
		points.append(point)
	points.append(end)
	
	for i in range(points.size()-1):
		draw_line(points[i], points[i+1], color, width)

func find_initial_target():
	var mobs = get_tree().get_nodes_in_group("mobs")
	var closest_dist = INF
	current_target = null
	
	for mob in mobs:
		var dist = global_position.distance_to(mob.global_position)
		if dist <= initial_target_range and dist < closest_dist:
			closest_dist = dist
			current_target = mob

func find_next_target():
	var mobs = get_tree().get_nodes_in_group("mobs")
	var valid_mobs: Array[Node2D] = []
	
	# Добавляем проверку на валидность целей
	for mob in mobs:
		if not is_instance_valid(mob):
			continue
		if mob in hit_mobs:
			continue
		var dist = current_origin.distance_to(mob.global_position)
		if dist <= bounce_range:
			valid_mobs.append(mob)
	
	if not valid_mobs.is_empty():
		current_target = valid_mobs.pick_random()
	else:
		current_target = null

func start_tracking():
	is_tracking = true
	time_alive = 0.0

func complete_strike():
	if not is_instance_valid(current_target):
		queue_free()
		return
	
	var hit_pos = current_target.global_position
	is_tracking = false
	
	if current_target.has_method("take_damage"):
		current_target.take_damage(damage)
	
	# Добавляем только если еще нет в списке
	if not current_target in hit_mobs:
		hit_mobs.append(current_target)
		
	time_alive = 0.0
	current_origin = hit_pos
	try_bounce_or_free()

func try_bounce_or_free():
	if bounce_count >= max_bounces:
		queue_free()
		return
	
	bounce_count += 1
	find_next_target()
	
	if current_target:
		start_tracking()
	else:
		queue_free()
