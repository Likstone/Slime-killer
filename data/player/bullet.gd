extends Area2D

var travelled_distance = 0

@export var SPEED: float = 1000
@export var RANGE = 1200
@export var penetration_flag = false
@export var damage = 1
func _physics_process(delta: float) -> void:
	var direction = Vector2.RIGHT.rotated(rotation)
	position += direction * SPEED * delta
	
	travelled_distance += SPEED * delta
	
	if travelled_distance > RANGE:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if !penetration_flag:
		if body.has_method("take_damage"):
			body.take_damage(damage)
			queue_free()
	else:
		if body.has_method("take_damage"):
			body.take_damage(damage)
