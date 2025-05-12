extends CharacterBody2D

var health = 3
@export var min_stop_distance: float = 70.0
@onready var player = get_node("/root/Game/Player")
@export var drop_chance: float = 0.7
@export var drop_chance_health: float = 0.001

# Переменные для отталкивания
var knockback_power: Vector2 = Vector2.ZERO
var is_knocked_back: bool = false
const KNOCKBACK_DECAY: float = 0.9

signal mob_died

func _ready() -> void:
	%Slime.play_walk()
	add_to_group("mobs")  # Важно для обнаружения игроком
	
func _physics_process(_delta):
	if is_knocked_back:
		# Применяем отталкивание
		velocity = knockback_power
		knockback_power *= KNOCKBACK_DECAY  # Постепенно уменьшаем силу
		
		# Когда отталкивание почти закончилось
		if knockback_power.length() < 10:
			is_knocked_back = false
			knockback_power = Vector2.ZERO
	
	move_and_slide()

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
	%Slime.play_hurt()
	
	#if health >= 0:
		#await get_tree().create_timer(0.15).timeout
		#call_deferred("queue_free")
		#const SMOKE_SCENE = preload("res://assets/smoke_explosion/smoke_explosion.tscn")
		#var smoke = SMOKE_SCENE.instantiate()
		#get_parent().add_child(smoke)
		#smoke.global_position = global_position    
		#emit_signal("mob_died")
		#drop_health_pack()
		#drop_gem()
