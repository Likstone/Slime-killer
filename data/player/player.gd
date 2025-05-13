extends CharacterBody2D

signal health_depleted
var gems_collected = 0
var player_level = 1
var health_add = 0
var base_speed = 400

var add_health_level = 1
var add_new_gun_level = 1
var health_bar_level = 1
var gun_changes
@export var speed_up = 0
var speed_up_level = 1
var orbital_gun = preload("res://data/player/orbital_gun.tscn")
var gun_count = 0
var ability_menu = preload("res://data/ui/ability_menu.tscn")

var magnit_level = 1
var main_gun_level = 1
var tesla_gun = preload("res://data/player/tesla_gun.tscn")
var tesla_gun_level = 1

@onready var magnet_area = %Gem_magnit_area
signal gem_entered_magnet_zone(gem)  #Сигнал входа
signal gem_exited_magnet_zone(gem)   # Сигнал выхода
signal gem_speed_changed(magnit_strength_value)

var health_bar
var gems_to_lvlup = 5

var autoregen = 1

var knockback_timer = 60.0
var last_knockback_time = -knockback_timer # Инициализируем так, чтобы способность сработала сразу
var knockback_cooldown = knockback_timer
var knockback_is_active = false

var sprite
var original_modulate: Color
var damage_modulate: Color = Color(1.0, 0.231, 0.0)  # Красный оттенок
var damage_tween: Tween

@export var world_size := Vector2(11520, 6480)

func _ready():
	add_to_group("player")
	sprite = %HappyBoo
	original_modulate = sprite.modulate
	%HurtBox.add_to_group("player_hurtbox")
	gun_changes = get_node("/root/Game/Player/Gun")
	health_bar = get_node("/root/Game/Player/Health_bar")
	update_level_ui()
	magnet_area.area_entered.connect(_on_magnet_body_entered)
	magnet_area.area_exited.connect(_on_magnet_body_exited)

func _flash_red():
	if damage_tween: damage_tween.kill()
	
	damage_tween = create_tween()
	damage_tween.set_trans(Tween.TRANS_SINE)
	damage_tween.set_ease(Tween.EASE_OUT)
	
	# Быстро меняем на красный
	damage_tween.tween_property(sprite, "modulate", damage_modulate, 0.075)
	# Затем плавно возвращаем обратно
	damage_tween.tween_property(sprite, "modulate", original_modulate, 0.15)

func _on_magnet_body_entered(body: Node2D):
	if body.is_in_group("gems"):
		gem_entered_magnet_zone.emit(body)

func _on_magnet_body_exited(body: Node2D):
	if body.is_in_group("gems"):
		gem_exited_magnet_zone.emit(body)

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
		1: main_gun()
		2: speed_up_one()
		3: add_new_gun()
		4: health_bar_attack()
		5: survivibility_ability()
		6: add_tesla_gun()
		7: magnit_ability() 

	%AbilityMenu.close_menu()
		
func update_level_ui():
	%LevelProgressBar.value = gems_collected
	%LevelProgressBar.max_value =  gems_to_lvlup * player_level
	%LevelLabel.text = "LVL: %d" % player_level

func _physics_process(_delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * (base_speed + speed_up)
	move_and_slide()
	
	if velocity.length() > 0.0:
		%HappyBoo.play_walk_animation()
	else:
		%HappyBoo.play_idle_animation()

	if health_bar.health_value <= health_bar.health_max_value/2 and knockback_is_active:
		if Time.get_ticks_msec() / 1000.0 - last_knockback_time >= knockback_cooldown:
			knockback_mobs()
			last_knockback_time = Time.get_ticks_msec() / 1000.0
	if health_bar.health_value <= 0.0:
		health_depleted.emit()

func player_take_damage(dmg):
	health_bar.health_dmg(dmg)
	if $Hurt.is_stopped():
		_flash_red()
		$Hurt.start()

func add_gem():
	gems_collected += 1
	check_level_up()
	update_level_ui()

func add_health(health_add_value):
	health_bar.health_add(health_add_value)

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

func update_all_orbital_guns_damage(damage: float):
	for gun in get_tree().get_nodes_in_group("orbital_guns"):
		gun.change_damage(damage)
		gun.damage = damage

func add_new_gun():	
	var orbital_guns = orbital_gun.instantiate()
	match add_new_gun_level:
		1:			
			orbital_guns.angle = 0
			orbital_guns.gun_count = gun_count
			add_child(orbital_guns)
			update_all_orbital_guns_damage(1)
			%AbilityMenu.change_description(3, "20% increase drone fire rate")
		2: 
			update_all_orbital_guns_firerate(1.2)
			%AbilityMenu.change_description(3, "increase drone rotation speed")
		3: 
			update_all_orbital_guns_rotation_speed(12.0)
			%AbilityMenu.change_description(3, "20% increase fire rate, drone deals x2 damage")
		4: 
			update_all_orbital_guns_firerate(1.0)
			update_all_orbital_guns_damage(2)
			%AbilityMenu.change_description(3, "20% increase fire rate, increase laser speed")
		5:
			update_all_orbital_guns_firerate(0.8)
			update_all_orbital_guns_bullet_speed(2500)
			%AbilityMenu.change_description(3, "20% increase fire rate, +1 drone")
		6:
			gun_count += 1
			orbital_guns.angle += deg_to_rad(90)
			orbital_guns.gun_count = gun_count
			add_child(orbital_guns)
			update_all_orbital_guns_firerate(0.7)
			update_all_orbital_guns_bullet_speed(2500)
			update_all_orbital_guns_damage(2)
			%AbilityMenu.change_description(3, "x3 damage, +1 drone")
		7:
			gun_count += 1
			orbital_guns.angle += deg_to_rad(90)
			orbital_guns.gun_count = gun_count
			add_child(orbital_guns)
			update_all_orbital_guns_firerate(0.7)
			update_all_orbital_guns_bullet_speed(2500)
			update_all_orbital_guns_damage(3)
			%AbilityMenu.change_description(3, "+1 drone")
		8:
			gun_count += 1
			orbital_guns.angle += deg_to_rad(90)
			orbital_guns.gun_count = gun_count
			add_child(orbital_guns)
			update_all_orbital_guns_firerate(0.7)
			update_all_orbital_guns_bullet_speed(2500)
			update_all_orbital_guns_damage(3)
			
	add_new_gun_level += 1
	
func change_firerate_gun(fire_rate_main):
	var gun1 = %Gun
	var gun2 = %Gun2
	gun1.my_timer.wait_time = fire_rate_main
	gun2.my_timer.wait_time = fire_rate_main

func update_all_main_gun_bullet_count(bullet_count: float):
	for gun in get_tree().get_nodes_in_group("main_guns"):
		gun.change_bullet_count(bullet_count)
		gun.bullet_count = bullet_count

func main_gun():
	match main_gun_level:
		1: 
			change_firerate_gun(0.6)
			%AbilityMenu.change_description(1, "2 bullets")
		2:
			update_all_main_gun_bullet_count(2)
			%AbilityMenu.change_description(1, "20% increase fire rate")
		3: 
			change_firerate_gun(0.5)
			%AbilityMenu.change_description(1, "3 bullets")
		4: 
			update_all_main_gun_bullet_count(3)
			%AbilityMenu.change_description(1, "20% increase fire rate")
		5:
			change_firerate_gun(0.3)
			%AbilityMenu.change_description(1, "4 bullets")
		6:
			update_all_main_gun_bullet_count(4)
			%AbilityMenu.change_description(1, "20% increase fire rate")
		7:
			change_firerate_gun(0.2)
			%AbilityMenu.change_description(1, "5 bullets")
		8:
			update_all_main_gun_bullet_count(5)
	main_gun_level += 1

func speed_up_one():

	match speed_up_level:
		1: speed_up += 30
		2: speed_up += 30
		3: speed_up += 30
		4: speed_up += 30
		5: speed_up += 30
		6: speed_up += 30
		7: speed_up += 30
		8: speed_up += 30

	speed_up_level+=1

func health_bar_attack():
	health_bar.start_attack()
	match health_bar_level:
		1: 
			%AbilityMenu.change_description(4, "increase length")
		2:
			%AbilityMenu.change_description(4, "increase length")
		3: 
			%AbilityMenu.change_description(4, "increase length")
		4: 
			%AbilityMenu.change_description(4, "increase speed")
		5:
			%AbilityMenu.change_description(4, "increase speed")
		6:
			%AbilityMenu.change_description(4, "chaotic rotation")
		7:
			%AbilityMenu.change_description(4, "x2 damage, increase speed")
	health_bar_level += 1

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
			health_bar.health_max_add(30)
			health_bar.health_add(30)
			%AbilityMenu.change_description(5, "20% increase max health")
		2:
			health_bar.health_max_add(30)
			health_bar.health_add(30)
			%AbilityMenu.change_description(5, "1 hp per second")
		3: 
			$Autoregen.autostart = true
			$Autoregen.start()
			%AbilityMenu.change_description(5, "2 hp per second")
		4: 
			autoregen = 2
			%AbilityMenu.change_description(5, "20% increase max health")
		5:
			health_bar.health_max_add(30)
			health_bar.health_add(30)
			%AbilityMenu.change_description(5, "3 hp per second")
		6:
			autoregen = 3
			%AbilityMenu.change_description(5, "50% health activate sacrife power")
		7:
			knockback_is_active = true
			%AbilityMenu.change_description(5, "20% increase max health, sacrife power increase cooldown recovery")
		8:
			knockback_timer = 20.0
			knockback_cooldown = knockback_timer
			health_bar.health_max_add(30)
			health_bar.health_add(30)
	add_health_level += 1

func update_tesla_gun_chain(new_chain: float):
	for gun in get_tree().get_nodes_in_group("tesla_gun"):
		gun.update_chain(new_chain)
		gun.chain = new_chain

func update_tesla_gun_attack_radius(attack_radius: float):
	for gun in get_tree().get_nodes_in_group("tesla_gun"):
		gun.update_attack_radius(attack_radius)
		gun.attack_radius = attack_radius

func update_tesla_gun_chain_radius(chain_radius: float):
	for gun in get_tree().get_nodes_in_group("tesla_gun"):
		gun.update_chain_radius(chain_radius)
		gun.chain_radius = chain_radius
		
func update_tesla_gun_damage(tesla_damage: float):
	for gun in get_tree().get_nodes_in_group("tesla_gun"):
		gun.update_tesla_damage(tesla_damage)
		gun.tesla_damage = tesla_damage

func add_tesla_gun():	
	var tesla_guns = tesla_gun.instantiate()
	match tesla_gun_level:
		1: 
			add_child(tesla_guns)
			update_tesla_gun_chain(4)
			%AbilityMenu.change_description(6, "+2 chain")
		2: 
			update_tesla_gun_chain(6)
			%AbilityMenu.change_description(6, "x2 damage, increase chain radius")
		3: 
			update_tesla_gun_chain_radius(300)
			update_tesla_gun_damage(2)
			%AbilityMenu.change_description(6, "+4 chain")
		4: 
			update_tesla_gun_chain(8)
			%AbilityMenu.change_description(6, "+8 chain, increase attack radius")
		5: 
			update_tesla_gun_attack_radius(600)
			update_tesla_gun_chain(16)
			%AbilityMenu.change_description(6, "+4 chain")
		6: 
			update_tesla_gun_chain(20)
			%AbilityMenu.change_description(6, "increase attack, radius")
		7: 
			update_tesla_gun_attack_radius(800)
			%AbilityMenu.change_description(6, "+10 chain")
		8: 
			update_tesla_gun_chain(30)
	tesla_gun_level+=1

func magnit_strengh(magnit_strength_value):
	GlobalSignal.current_magnet_speed = magnit_strength_value
	emit_signal("gem_speed_changed", magnit_strength_value)

func mega_magnit():
	for gem in get_tree().get_nodes_in_group("gems"):
		if gem.has_method("activate_attraction"):
			gem.activate_attraction()

func magnit_ability():
	match magnit_level:
		1: 
			%Gem_magnit_col.shape.radius = 200
			magnit_strengh(200)
			%AbilityMenu.change_description(7, "increase magnin strength")
		2: 
			magnit_strengh(400)
			%AbilityMenu.change_description(7, "increase magnin radius")
		3: 
			%Gem_magnit_col.shape.radius = 300
			%AbilityMenu.change_description(7, "increase magnin strength")
		4: 
			magnit_strengh(600)
			%AbilityMenu.change_description(7, "increase magnin radius")
		5: 
			%Gem_magnit_col.shape.radius = 400
			%AbilityMenu.change_description(7, "increase magnin strength")
		6: 
			magnit_strengh(800)
			%AbilityMenu.change_description(7, "increase magnin radius")
		7: 
			%Gem_magnit_col.shape.radius = 500
			%AbilityMenu.change_description(7, "mega magnnit activate")
		8: 
			mega_magnit()
			%Mega_magnit_activ.start()
	magnit_level+=1

func _on_timer_timeout() -> void:
	add_health(autoregen)

func _on_mega_magnit_activ_timeout() -> void:
	mega_magnit()
