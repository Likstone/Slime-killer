extends CharacterBody2D

signal health_depleted
var gems_collected = 0
var player_level = 1
@export var health = 100.0
var base_speed = 400

var add_health_level = 1
var add_new_gun_level = 1

var gun_changes
var speed_up = 0
var orbital_gun = preload("res://data/player/orbital_gun.tscn")
var gun_count = 0

var tesla_gun = preload("res://data/player/tesla_gun.tscn")
var tesla_gun_level = 1


var health_bar
var gems_to_lvlup = 1.0

var autoregen = 1

var knockback_timer = 60.0
var last_knockback_time = -knockback_timer # Инициализируем так, чтобы способность сработала сразу
var knockback_cooldown = knockback_timer
var knockback_is_active = false

func _ready():
	add_to_group("player")
	gun_changes = get_node("/root/Game/Player/Gun")
	health_bar = get_node("/root/Game/Player/Health_bar")
	update_level_ui()

func check_level_up():
	var required_gems =  gems_to_lvlup * player_level
	if gems_collected >= required_gems:
		player_level += 1
		gems_collected = 0
		
		%AbilityMenu.open_menu()
		if not %AbilityMenu.ability_selected.is_connected(_on_ability_selected):
			%AbilityMenu.ability_selected.connect(_on_ability_selected)
		
	update_level_ui()

func _on_ability_selected(ability_id: int):
	match ability_id:
		1: change_firerate_gun()
		2: speed_up_one()
		3: add_new_gun()
		4: health_bar_attack()
		5: survivibility_ability()
		6: add_tesla_gun() # Сюда chain lighting / На голове у игрока появляется маленькая установка теслы
		# (1) раз в какое то время выстреливает молния которая мгновенно примагничивается к случайному противнику
		# (2) Молния отскакивает в ближейшего противника 1 раз
		# (3) Молния отскакивает в ближайшего противника 2 раза
		# (4) Молния отскакивает в ближайшего противника 3 раза
		# (5) Молния отскакивает в ближайшего противника 4 раза
		# (6) Молния отскакивает в ближайшего противника 5 раза
		# (7) Молния отскакивает в ближайшего противника 6 раза
		# (8) Монлия начинает стрелять каждые 100 (например) пикселей пройденных игроком
		7: pass # Щелчок пальцами, в толпе мобов (приоритет на толпу) происходит щелчок / хлопок со взрвыом 
		# (1) Радиус взрвыва больше
		# (2) Чаще взрыв
		# (3) Два радиуса, один маленький с двойным уроном
		# (4) Радиус больше
		# (5) Хлопок станин задетых врагов
		# (6) Критическяй хлопок, с 20% шансом весь радиус наносит 2x урона
		# (7) Радиус взрвыва больше
		# (8) После пхлопка остается фантомная рука которая с задержкой еще раз хлопает
		8: pass # 333, артилерийский залп, в случайное место на экране с задержкой падает снаряд
		# (1) Снарядо падает чаще
		# (2) Снаряд падает чаще и быстрее
		# (3) Снарядов становится 2
		# (4) Снаряд падает чаще и быстрее
		# (5) Снарядов становится 3
		# (6) Радиус взрыва увеличивается двое
		# (7) Снарядов становится 4
		# (8) Снаряды оставляют огненную воронку который раз в секунду наносит урон всем в радиусе
		9: pass # Магнит, увеличивает радиус подбора предметов
		# (1) Увеличивает еще сильнее радиус подбора предметов
		# (2) Увелчивает скорость втягивание предметов
		# (3) Увеличивает еще сильнее радиус подбора предметов
		# (4) Увелчивает скорость втягивание предметов
		10: pass # Отскакивающий снаряд который врезается и летит в обратную сторону
		# (1) Выпускает 2-а снаряда
		# (2) Скорость движение снаряда увеличивается
		# (3) Снаряды выпускаются чаще
		# (4) Выпускает 3-и снаряда
		# (5) Снаряд отскакивает 3-и раза
		# (6) Скорость движение снаряда увеличивается и снаряды выпускаются чаще
		# (7) Выпускает 4-и снаряда
		# (8) При первом столкновении разбивается на 2-а снаряда

	%AbilityMenu.close_menu()
		
func update_level_ui():
	%LevelProgressBar.value = gems_collected
	%LevelProgressBar.max_value =  gems_to_lvlup * player_level

	%LevelLabel.text = "LVL: %d" % player_level

func _physics_process(delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * (base_speed + speed_up)
	move_and_slide()
	
	if velocity.length() > 0.0:
		%HappyBoo.play_walk_animation()
	else:
		%HappyBoo.play_idle_animation()
	
	const DAMAGE_RATE = 50.0
	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	if overlapping_mobs.size() > 0:
		health -= DAMAGE_RATE * overlapping_mobs.size() * delta
		health_bar.health_update(health)
		if health <= 50 and knockback_is_active:
			if Time.get_ticks_msec() / 1000.0 - last_knockback_time >= knockback_cooldown:
				knockback_mobs()
				last_knockback_time = Time.get_ticks_msec() / 1000.0
		if health <= 0.0:
			health_depleted.emit()
	
func add_gem():
	gems_collected += 1
	check_level_up()
	update_level_ui()

func add_health(health_add_value):
	health += health_add_value
	health_bar.health_update(health)

func update_all_orbital_guns_firerate(new_firerate: float):
	for gun in get_tree().get_nodes_in_group("orbital_guns"):
		gun.update_firerate(new_firerate)
		gun.fire_rate = new_firerate

func update_all_orbital_guns_rotation_speed(rotation_speeds: float):
	for gun in get_tree().get_nodes_in_group("orbital_guns"):
		gun.change_rotation_speed(rotation_speeds)
		gun.rotation_speed = rotation_speeds

func update_all_orbital_guns_bullet_speed(bullet_speed: float):
	for gun in get_tree().get_nodes_in_group("orbital_guns"):
		gun.change_bullet_speed(bullet_speed)
		gun.bullet_speed = bullet_speed

func add_new_gun():	
	var orbital_guns = orbital_gun.instantiate()
	match add_new_gun_level:
		1:			
			gun_count += 1
			orbital_guns.angle = 0
			orbital_guns.gun_count = gun_count
			add_child(orbital_guns)
		2: 
			update_all_orbital_guns_firerate(0.9)
		3: 
			update_all_orbital_guns_rotation_speed(12.0)
		4: 
			update_all_orbital_guns_firerate(0.8)
		5:
			update_all_orbital_guns_firerate(0.7)
			update_all_orbital_guns_bullet_speed(2500)
		6:
			gun_count += 1
			orbital_guns.angle += deg_to_rad(90)
			orbital_guns.gun_count = gun_count
			add_child(orbital_guns)
			update_all_orbital_guns_firerate(0.7)
			update_all_orbital_guns_bullet_speed(2500)
		7:
			gun_count += 1
			orbital_guns.angle += deg_to_rad(90)
			orbital_guns.gun_count = gun_count
			add_child(orbital_guns)
			update_all_orbital_guns_firerate(0.7)
			update_all_orbital_guns_bullet_speed(2500)
		8:
			gun_count += 1
			orbital_guns.angle += deg_to_rad(90)
			orbital_guns.gun_count = gun_count
			add_child(orbital_guns)
			update_all_orbital_guns_firerate(0.7)
			update_all_orbital_guns_bullet_speed(2500)
			
	add_new_gun_level += 1
	
func change_firerate_gun():
	var gun = %Gun
	if gun.my_timer.wait_time >= 0.1:
		gun.my_timer.wait_time -= 0.05
	else:
		print("firerate is max")
	
func speed_up_one():
	if speed_up <= 300:
		speed_up += 30
	else:
		print("speed is max")
		
func health_bar_attack():
	health_bar.start_attack()

func knockback_mobs():
	var knockback_radius = 500.0
	var knockback_force = 5000.0  # Увеличьте силу если не работает
	
	var mobs = get_tree().get_nodes_in_group("mobs")
	for mob in mobs:
		var distance = global_position.distance_to(mob.global_position)
		if distance <= knockback_radius:
			var direction = (mob.global_position - global_position).normalized()
			# Добавляем вертикальную составляющую
			var force_vector = (direction + Vector2(0, -0.2)) * knockback_force
			if mob.has_method("apply_knockback"):
				mob.apply_knockback(force_vector)

func survivibility_ability():
	match add_health_level:
		1: 
			health += 30
		2:
			health += 30
		3: 
			$Autoregen.autostart = true
			$Autoregen.start()
		4: 
			autoregen = 3
		5:
			health += 30
		6:
			autoregen = 6
		7:
			knockback_is_active = true
		8:
			knockback_timer = 20.0
			knockback_cooldown = knockback_timer
			health += 30
	add_health_level += 1

func update_tesla_gun_chain(new_chain: float):
	for gun in get_tree().get_nodes_in_group("tesla_gun"):
		gun.update_chain(new_chain)
		gun.chain = new_chain

func add_tesla_gun():	
	var tesla_guns = tesla_gun.instantiate()
	match tesla_gun_level:
		1: add_child(tesla_guns)
		2: update_tesla_gun_chain(2)
		3: update_tesla_gun_chain(3)
		4: update_tesla_gun_chain(5)
		5: update_tesla_gun_chain(5)
		6: update_tesla_gun_chain(5)
		7: update_tesla_gun_chain(6)
		8: pass
	tesla_gun_level+=1
	
func _on_timer_timeout() -> void:
	add_health(autoregen)


func _on_button_pressed() -> void:
	add_gem()
