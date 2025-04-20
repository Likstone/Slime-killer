extends Area2D

@export var speed: float = 150.0  
@export var pickup_distance: float = 10.0
@export var health_add = 25

var player: Node2D = null
var is_attracted: bool = false

func _ready():
	$DetectionArea.body_entered.connect(_on_detection_area_entered)
	$DetectionArea.body_exited.connect(_on_detection_area_exited)

func _on_detection_area_entered(body: Node2D):
	if body.is_in_group("player"):
		player = body
		is_attracted = true

func _on_detection_area_exited(body: Node2D):
	if body == player:  
		is_attracted = false

func _physics_process(delta):
	if is_attracted and player:
		var direction = (player.global_position - global_position).normalized()
		position += direction * speed * delta
		
		if global_position.distance_to(player.global_position) < pickup_distance:
			collect()

func collect():
	var level_manager = get_node("/root/Game")
	if level_manager:
		level_manager.add_health()
	
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.add_health(health_add)
	
	call_deferred("queue_free")
	
	
