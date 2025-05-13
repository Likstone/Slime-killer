extends Camera2D

@export var follow_speed: float = 10.0  # Скорость следования (5 - нормально, 10 - резче)
@export var max_offset: Vector2 = Vector2(25, 25)  # Максимальное смещение от центра
@export var look_ahead: float = 0.5  # Предугадывание движения (0-1)

var current_offset: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var smoothing_enabled
var smoothing_speed
func _ready():
	make_current()
	# Настройки сглаживания (включите в инспекторе если не работает)
	smoothing_enabled = true
	smoothing_speed = follow_speed * 0.8

func _physics_process(delta):
	# Получаем направление движения игрока
	var player_velocity = get_parent().velocity  # Предполагаем что у родителя есть velocity
	var target_offset = Vector2(
		sign(player_velocity.x) * max_offset.x * look_ahead,
		sign(player_velocity.y) * max_offset.y * look_ahead
	)
	
	# Плавное изменение смещения
	current_offset = current_offset.lerp(target_offset, follow_speed * delta)
	
	# Обновляем позицию камеры относительно игрока
	position = current_offset
