extends Area2D

@export var speed: float = 0.0
@export var pickup_distance: float = 50.0

var player: Node2D = null
var is_attracted: bool = false
var attracted_mega: bool = false

func _ready():
	add_to_group("gems")
	player = get_tree().get_first_node_in_group("player")
	speed = GlobalSignal.current_magnet_speed
	if player:	
		player.gem_entered_magnet_zone.connect(_on_detection_area_entered)
		player.gem_exited_magnet_zone.connect(_on_detection_area_exited)
		player.gem_speed_changed.connect(_on_gem_speed_changed)

func _on_detection_area_entered(body: Node2D):
	if body == self:
		is_attracted = true

func _on_detection_area_exited(body: Node2D):
	if body == self:
		is_attracted = false

func _on_gem_speed_changed(new_speed: float):
	speed = new_speed

func activate_attraction():
	attracted_mega = true

func _physics_process(delta):
	if is_attracted and player or attracted_mega:
		var direction = (player.global_position - global_position).normalized()
		position += direction * speed * delta
		
		if global_position.distance_to(player.global_position) < pickup_distance:
			collect()

func collect():
	var level_manager = get_node("/root/Game")
	if level_manager:
		level_manager.add_gem()
	
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.add_gem()
	queue_free()
	
	call_deferred("queue_free")
	
	
