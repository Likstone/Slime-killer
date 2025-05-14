extends RigidBody2D

@export var Health = 3
@export var min_stop_distance: float = 60.0
@onready var player = get_node("/root/Game/Player")
@export var mob_speed: float = 100
@export var mass_body: float = 1.0

@onready var stun_timer = $stun_timer
@onready var dash_timer = $dash_timer
@onready var prepare_timer = $prepare_timer
@onready var cooldown_timer = $cooldown_timer
var player_in_area
var direction
var distance
enum State {CHASING, DASHING, COOLDOWN, PREPARE}

var current_state = State.CHASING
@export var attack_distance = 1000
@export var dash_duration = 0.40
@export var dash_force = 200000
@export var stun_duration = 1.35

@export var spawn_point_distance = 190
var spawn_choice
var spawn_point_choice
var max_hp
var state_attack = ""
var cooldown_attack_flag = true
@onready var sprite = $Slime
var original_scale: Vector2 = Vector2(3, 3)
var squash_scale: Vector2 = Vector2(3.5, 2.4)  # Приплюснутое состояние
var stretch_scale: Vector2 = Vector2(2.4, 3.3)  # Вытянутое состояние
var tween: Tween

var original_modulate: Color
var damage_modulate: Color = Color(0.60, 0.25, 0.9)  # Красный оттенок
var damage_tween: Tween

@export var rage_dash_count = 4
var rage_dash_remaining = rage_dash_count
var rage_flag = false
@export var mob_damage_rate = 5
var enemy_data = {
	"gray_slime": {
		"scene": preload("res://data/enemies/mob.tscn"), 
		"max_in_wave": 0,
		},
	"armored_slime": {
		"scene": preload("res://data/enemies/armored_slime.tscn"), 
		"max_in_wave": 0,
		},
	"fast_slime": {
		"scene": preload("res://data/enemies/fast_slime.tscn"), 
		"max_in_wave": 0,
		},
	"mini_boss_slime": {
		"scene": preload("res://data/enemies/slime_mini_boss.tscn"), 
		"max_in_wave": 1,
		},
	"circle_slime": {
		"scene": preload("res://data/enemies/circle_slime.tscn"), 
		"max_in_wave": 0,
		},
	}
var slime_friendly_flag = false
signal mob_died
signal boss_died

func _ready() -> void:
	%Slime.play_boss_walk()
	original_modulate = sprite.modulate
	contact_monitor = true
	linear_damp = 0.5
	randomize()
	max_contacts_reported = 1
	add_to_group("mobs")
	add_to_group("boss")  # Важно для обнаружения игроком
	mass = mass_body
	max_hp = Health
	
func _physics_process(_delta):
	direction = global_position.direction_to(player.global_position)
	distance = global_position.distance_to(player.global_position)
	%boss_spawner.rotation = direction.angle()
	%boss_spawner.position = direction * spawn_point_distance
	
	if Health <= max_hp*0.8 and !rage_flag:
		rage_flag = true
		
	match current_state:
			State.CHASING:
				_chasing_player()
				
				if distance < attack_distance and cooldown_attack_flag:
					_start_prepare(1, "dash")
					cooldown_attack_flag = false
			State.DASHING:
				_squash_effect()
				
			State.PREPARE:
				_stretch_effect()
			_:
				_reset_shape()
				if rage_flag:
					dash_force = 275000
					dash_duration = 0.2
					linear_damp = 0.8

func _squash_effect():
	if tween: tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(sprite, "scale", squash_scale, 0.2)

func _stretch_effect():
	if tween: tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(sprite, "scale", stretch_scale, dash_duration * 0.5)
	tween.tween_property(sprite, "scale", original_scale, dash_duration * 0.5)

func _reset_shape():
	if tween: tween.kill()
	tween = create_tween()
	tween.tween_property(sprite, "scale", original_scale, 0.2)

func _chasing_player():
	if distance > min_stop_distance:
		linear_velocity = direction * mob_speed

func _flash_red():
	if damage_tween: damage_tween.kill()
	
	damage_tween = create_tween()
	damage_tween.set_trans(Tween.TRANS_SINE)
	damage_tween.set_ease(Tween.EASE_OUT)
	
	# Быстро меняем на красный
	damage_tween.tween_property(sprite, "modulate", damage_modulate, 0.1)
	# Затем плавно возвращаем обратно
	damage_tween.tween_property(sprite, "modulate", original_modulate, 0.2)

func _start_dash():
	current_state = State.DASHING
	
	apply_central_impulse(direction * dash_force)
	
	dash_timer.start(dash_duration)

func _start_prepare(prepare_duration, attack_type):
	if current_state != State.CHASING: return
	
	current_state = State.PREPARE
	linear_velocity = direction * 0
	state_attack = attack_type
	prepare_timer.start(prepare_duration)

func take_damage(damage):
	Health -= damage
	_flash_red()
	
	if Health <= 0:
		await get_tree().create_timer(0.15).timeout
		call_deferred("queue_free")
		const SMOKE_SCENE = preload("res://assets/smoke_explosion/smoke_explosion.tscn")
		var smoke = SMOKE_SCENE.instantiate()
		get_parent().add_child(smoke)
		smoke.global_position = global_position    
		emit_signal("mob_died")
		emit_signal("boss_died")
		SoundManager.mob_died_s()

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage") and !slime_friendly_flag:
		body.take_damage(9999)
	if body.has_method("player_take_damage") and current_state != State.CHASING and current_state != State.PREPARE:
		body.player_take_damage(60)

func spawn_mob_group(enemies_type, spawn_loop_i : int):
	if !slime_friendly_flag:
		slime_friendly_flag = true
	var spawn_position = %boss_spawner.global_position
	for i in range(spawn_loop_i):
		var new_mob = enemies_type.instantiate()
		new_mob.drop_chance = 0.0
		new_mob.drop_chance_health = 0.0
		new_mob.global_position = spawn_position + Vector2(i * 5, 0)
		get_parent().add_child(new_mob)

func _on_dash_timer_timeout() -> void:
	current_state = State.COOLDOWN
	stun_timer.start(stun_duration)
	
func _on_cooldown_timer_timeout() -> void:
	cooldown_attack_flag = true

func _on_prepare_timer_timeout() -> void:
	match state_attack:
		"dash": 
			_start_dash()

func _on_stun_timer_timeout() -> void:
	current_state = State.CHASING
	if rage_flag:
		if rage_dash_remaining > 0:
			rage_dash_remaining -= 1
			_start_prepare(0.3, "dash")
		else:
			rage_dash_remaining = rage_dash_count
			spawn_point_choice = randi_range(1, 2)
			match spawn_point_choice:
				1:
					spawn_point_distance = 190
					%boss_spawner.position = direction * spawn_point_distance
					spawn_choice = randi_range(1, 4)
					match spawn_choice:
						1: spawn_mob_group(enemy_data["fast_slime"]["scene"], 10)
						2: spawn_mob_group(enemy_data["mini_boss_slime"]["scene"], 3)
						3: spawn_mob_group(enemy_data["armored_slime"]["scene"], 50)
						4: spawn_mob_group(enemy_data["gray_slime"]["scene"], 100)
				2:
					spawn_point_distance = 6000
					%boss_spawner.position = direction * spawn_point_distance
					spawn_choice = randi_range(1, 2)
					match spawn_choice:
						1: spawn_mob_group(enemy_data["fast_slime"]["scene"], 20)
						2: spawn_mob_group(enemy_data["circle_slime"]["scene"], 30)
			cooldown_timer.start()
	else:
		cooldown_timer.start()


func _on_attack_rate_timeout() -> void:
	if player_in_area and player_in_area.has_method("player_take_damage"):
		player_in_area.player_take_damage(mob_damage_rate)


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		player_in_area = area.get_parent()
		$attack_rate.start()


func _on_area_2d_area_exited(area: Area2D) -> void:
	if player_in_area == area.get_parent():
		player_in_area = null
		$attack_rate.stop()
