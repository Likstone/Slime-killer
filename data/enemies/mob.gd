extends RigidBody2D

@export var Health = 0
@export var min_stop_distance: float = 30.0
@onready var player = get_node("/root/Game/Player")
@export var drop_chance: float = 0.7
@export var drop_chance_health: float = 0.001
@export var mob_speed: float = 300
@export var distance_dash: float = 1300

@export var distance_circle: float
@export var speed_circle: float
@export var circle_active : bool
@onready var dash_cooldown: Timer = $Dash_cooldown
@export var circle_dash_cooldown_time : float

@export var mass_body: float = 1.0
@export var boom_slime = false
var player_in_area = null
# Переменные для отталкивания
var knockback_power: Vector2 = Vector2.ZERO
var is_knocked_back: bool = false	
const KNOCKBACK_DECAY: float = 0.9

var scary_flag = false
@onready var attack_rate : Timer = $attack_rate
var attack_ready_flag = true
@export var mob_damage_rate = 10
signal mob_died

func _ready() -> void:
	%Slime.play_walk()
	add_to_group("mobs")  # Важно для обнаружения игроком
	contact_monitor = true
	max_contacts_reported = 100
	mass = mass_body
	if circle_active:
		dash_cooldown.autostart = true
		dash_cooldown.wait_time = circle_dash_cooldown_time
		dash_cooldown.start()
	
func _physics_process(_delta):
	if is_knocked_back:
		# Применяем отталкивание
		linear_velocity = knockback_power
		knockback_power *= KNOCKBACK_DECAY  # Постепенно уменьшаем силу
		
		# Когда отталкивание почти закончилось
		if knockback_power.length() < 10:
			is_knocked_back = false
			knockback_power = Vector2.ZERO
	else:
		# Обычное движение к игроку
		var direction = global_position.direction_to(player.global_position)
		var distance = global_position.distance_to(player.global_position)
		
		if distance > min_stop_distance:
			linear_velocity = direction * mob_speed
		else:
			linear_velocity = Vector2.ZERO
	
		if distance > distance_dash:
			linear_velocity = direction * (mob_speed + 1000)
			
		if distance > distance_circle and circle_active:
			linear_velocity = direction * (mob_speed + speed_circle)
			if linear_velocity.length() < 1040.0:
				circle_active = false
		else:
			circle_active = false
	if scary_flag:
		var direction = global_position.direction_to(player.global_position)
		var distance = global_position.distance_to(player.global_position)
		linear_velocity = -direction * (mob_speed + 300)
		if distance > 1300:
			take_damage(9999)
	
func scary_activated():
	drop_chance = 0.0
	drop_chance_health = 0.0
	scary_flag = true
	%Slime.play_scary()
	
# Функция отталкивания (должна вызываться из игрока)
func apply_knockback(force: Vector2):
	knockback_power = force
	is_knocked_back = true

# Остальные функции остаются без изменений
func drop_gem():
	const GEM_1 = preload("res://data/object/gem1.tscn")
	if randf() < drop_chance:
		var gem = GEM_1.instantiate()
		gem.global_position = global_position
		get_parent().call_deferred("add_child", gem)
		
func drop_health_pack():
	const healths = preload("res://data/object/health_pack.tscn")
	if randf() < drop_chance_health:
		var health_pack = healths.instantiate()
		health_pack.global_position = global_position
		get_parent().call_deferred("add_child", health_pack)

func take_damage(damage):
	Health -= damage
	%Slime.play_hurt()
	
	if Health <= 0:
		await get_tree().create_timer(0.15).timeout
		call_deferred("queue_free")
		const SMOKE_SCENE = preload("res://assets/smoke_explosion/smoke_explosion.tscn")
		var smoke = SMOKE_SCENE.instantiate()
		get_parent().add_child(smoke)
		smoke.global_position = global_position    
		emit_signal("mob_died")
		drop_health_pack()
		drop_gem()


func _on_dash_timeout() -> void:
	circle_active = true


#func _on_body_entered(body: Node) -> void:
	#if boom_slime and body.has_method("player_take_damage"):
		#body.player_take_damage(mob_damage_rate)
		#take_damage(9999)
	#else:
		#if attack_ready_flag and body.has_method("player_take_damage"):
			#body.player_take_damage(mob_damage_rate)
			#attack_ready_flag = false
			#print("attack player")
			#attack_rate.start()


func _on_attack_rate_timeout() -> void:
	if player_in_area and player_in_area.has_method("player_take_damage"):
		player_in_area.player_take_damage(mob_damage_rate)


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		if boom_slime:
			player_in_area = area.get_parent()
			if player_in_area and player_in_area.has_method("player_take_damage"):
				player_in_area.player_take_damage(mob_damage_rate)
				take_damage(99999)
		else:
			player_in_area = area.get_parent()
			$attack_rate.start()


func _on_area_2d_area_exited(area: Area2D) -> void:
	if player_in_area == area.get_parent():
		player_in_area = null
		$attack_rate.stop()
		
		
