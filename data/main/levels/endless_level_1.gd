extends Node2D
var score = 0
var mob_count = 0
var max_mob = 300

@export var timer_label: Label  # Label для вывода времени
var start_time: int
var paused_time: int = 0  # Накопленное время паузы
var is_paused: bool = false

@onready var slime_spawn_1 : Timer = $slime_spawn_1
@onready var slime_spawn_2 : Timer = $slime_spawn_2
var enemy_data = {}

var spawn_choice = randi_range(1, 2)

var lose_flag = true
var win_flag = true

var wave_1 = false
var wave_2 = false
var wave_3 = false
var wave_4 = false
var wave_5 = false
var wave_6 = false
var wave_7 = false
var wave_8 = false
var wave_9 = false
var wave_10 = false

var wave_events_1 = false
var wave_events_2 = false
var wave_events_3 = false
var wave_events_4 = false

func _ready() -> void:
	%ScoreLabel.text = "Score: " + str(score)
	randomize()
	start_time = Time.get_ticks_msec()
	enemy_data = {
	"gray_slime": {
		"scene": preload("res://data/enemies/mob.tscn"), 
		"timer_node": slime_spawn_1,
		"max_in_wave": 0,
		},
	"armored_slime": {
		"scene": preload("res://data/enemies/armored_slime.tscn"), 
		"timer_node": slime_spawn_1,
		"max_in_wave": 0,
		},
	"fast_slime": {
		"scene": preload("res://data/enemies/fast_slime.tscn"), 
		"timer_node": slime_spawn_2,
		"max_in_wave": 0,
		},
	"mini_boss_slime": {
		"scene": preload("res://data/enemies/slime_mini_boss.tscn"), 
		"timer_node": null,
		"max_in_wave": 1,
		},
	"circle_slime": {
		"scene": preload("res://data/enemies/circle_slime.tscn"), 
		"timer_node": null,
		"max_in_wave": 0,
		},
	"slime_boss": {
		"scene": preload("res://data/enemies/slime_boss.tscn"), 
		"timer_node": null,
		"max_in_wave": 1,
		},
	}
	
func score_add():
	score+=1
	%ScoreLabel.text = "Score: " + str(score)

func mob_died_check():
	mob_count-=1
	SoundManager.mob_died()

func _on_player_health_depleted() -> void:
	pause_timer()
	%GameOver.visible = true
	get_tree().paused = true
	%GameOver.process_mode = Node.PROCESS_MODE_ALWAYS
	%GameOver.get_child(0).process_mode = Node.PROCESS_MODE_ALWAYS
	if lose_flag:
		SoundManager.lose()
		lose_flag = false

var gems_collected: int = 0
var player_level: int = 1

func add_gem():
	gems_collected += 1
	check_level_up()

func add_health():
	pass	

func check_level_up():
	var required_gems = player_level * 2
	if gems_collected >= required_gems:
		player_level += 1
	
func _on_button_pressed() -> void:
	get_tree().paused = false
	unpause_timer()
	get_tree().call_deferred("change_scene_to_file", "res://data/main/menu/start_menu.tscn")

func pause_timer():
	if !is_paused:
		paused_time += Time.get_ticks_msec() - start_time
		$slime_spawn_1.paused = true
		$slime_spawn_2.paused = true
		is_paused = true

func unpause_timer():
	if is_paused:
		start_time = Time.get_ticks_msec()
		$slime_spawn_1.paused = false
		$slime_spawn_2.paused = false
		is_paused = false

func get_elapsed_time() -> int:
	if is_paused:
		return paused_time
	else:
		return paused_time + (Time.get_ticks_msec() - start_time)

func _process(_delta):
	# Текущее время в секундах
	var current_time_msec = get_elapsed_time()
	var current_time_sec = current_time_msec / 1000.0
	
	# Обновляем Label (формат MM:SS)
	if timer_label:
		var minutes = int(current_time_sec) / 60
		var seconds = int(current_time_sec) % 60
		var milliseconds = current_time_msec % 1000
		timer_label.text = "%02d:%02d" % [minutes, seconds]
	
	######### WAVE 1 ############
	if current_time_sec >= 1.0 and !wave_1:
		spawn_mob(enemy_data["gray_slime"]["scene"], 10)
		mob_power_increase("gray_slime", 5.0, 10)
		slime_spawn_1.autostart = true
		slime_spawn_1.start()
		wave_1 = true
		
	########## ADDITIONAL WAVE 1 ############
	if current_time_sec >= 60.0 and !wave_events_1:
		spawn_mob(enemy_data["gray_slime"]["scene"], 10)
		spawn_mob_group(enemy_data["gray_slime"]["scene"], 20)
		spawn_mob_group(enemy_data["armored_slime"]["scene"], 5)
		wave_events_1 = true
		
	######### WAVE 2 ############	
	if current_time_sec >= 100.0 and !wave_2:
		mob_power_increase("gray_slime", 5.0, 25)
		spawn_mob_group(enemy_data["fast_slime"]["scene"], 1)
		mob_power_increase("armored_slime", 5.0, 2)
		wave_2 = true
		
	######### WAVE 3 ############	
	if current_time_sec >= 200.0 and !wave_3:
		mob_power_increase("gray_slime", 4.0, 20)
		slime_spawn_2.autostart = true
		slime_spawn_2.start()
		mob_power_increase("fast_slime", 20.0, 2)
		spawn_mob_group(enemy_data["fast_slime"]["scene"], 10)
		spawn_mob(enemy_data["circle_slime"]["scene"], 20)
		wave_3 = true
	
	######### ADDITION WAVE 2 ############
	if current_time_sec >= 260.0 and !wave_events_2:
		spawn_mob_group(enemy_data["gray_slime"]["scene"], 10)
		spawn_mob_group(enemy_data["gray_slime"]["scene"], 10)
		spawn_mob_group(enemy_data["gray_slime"]["scene"], 10)
		spawn_mob_group(enemy_data["armored_slime"]["scene"], 10)
		wave_events_2 = true
	
	######### WAVE 4 ############	
	if current_time_sec >= 320.0 and !wave_4:
		mob_power_increase("gray_slime", 5.0, 30)
		spawn_mob(enemy_data["circle_slime"]["scene"], 50)
		spawn_mob(enemy_data["mini_boss_slime"]["scene"], 1)
		wave_4 = true
		
	######### WAVE 5 ############	
	if current_time_sec >= 380.0 and !wave_5:
		spawn_mob(enemy_data["mini_boss_slime"]["scene"], 2)
		spawn_mob(enemy_data["circle_slime"]["scene"], 80)
		mob_power_increase("gray_slime", 5.0, 50)
		mob_power_increase("armored_slime", 6.0, 20)
		mob_power_increase("fast_slime", 15.0, 5)
		slime_spawn_2.autostart = true
		slime_spawn_2.start()
		wave_5 = true
		
	######### ADDITION WAVE 3 ############
	if current_time_sec >= 420.0 and !wave_events_3:
		spawn_mob_group(enemy_data["gray_slime"]["scene"], 20)
		spawn_mob_group(enemy_data["gray_slime"]["scene"], 10)
		spawn_mob_group(enemy_data["gray_slime"]["scene"], 20)
		spawn_mob_group(enemy_data["armored_slime"]["scene"], 10)
		spawn_mob_group(enemy_data["armored_slime"]["scene"], 5)
		wave_events_3 = true	
	
	########## WAVE 6 ############	
	if current_time_sec >= 480.0 and !wave_6:
		spawn_mob(enemy_data["circle_slime"]["scene"], 60)
		spawn_mob(enemy_data["mini_boss_slime"]["scene"], 2)
		mob_power_increase("gray_slime", 5.0, 60)
		mob_power_increase("armored_slime", 4.0, 30)
		spawn_mob_group(enemy_data["fast_slime"]["scene"], 10)
		wave_6 = true
		
	######### ADDITION WAVE 4 ############
	if current_time_sec >= 520.0 and !wave_events_4:
		spawn_mob_group(enemy_data["gray_slime"]["scene"], 20)
		spawn_mob_group(enemy_data["armored_slime"]["scene"], 10)
		spawn_mob_group(enemy_data["armored_slime"]["scene"], 5)
		wave_events_4 = true	
		
	######### WAVE 7 ############	
	if current_time_sec >= 560.0 and !wave_7:
		spawn_mob(enemy_data["circle_slime"]["scene"], 100)
		spawn_mob(enemy_data["mini_boss_slime"]["scene"], 3)
		mob_power_increase("gray_slime", 5.0, 80)
		mob_power_increase("armored_slime", 4.0, 30)
		spawn_mob_group(enemy_data["fast_slime"]["scene"], 10)
		wave_7 = true
		
	######### WAVE 8 ############	
	if current_time_sec >= 600.0 and !wave_8:
		spawn_mob(enemy_data["circle_slime"]["scene"], 50)
		spawn_mob(enemy_data["armored_slime"]["scene"], 50)
		spawn_mob(enemy_data["gray_slime"]["scene"], 50)
		spawn_mob(enemy_data["mini_boss_slime"]["scene"], 3)
		wave_8 = true
		
	######### WAVE 9 ############	
	if current_time_sec >= 606.0 and !wave_9:
		mob_run_away()
		mob_power_increase("gray_slime", 5.0, 0)
		mob_power_increase("armored_slime", 5.0, 0)
		mob_power_increase("fast_slime", 5.0, 0)
		max_mob = 301
		spawn_mob(enemy_data["slime_boss"]["scene"], 1)
		var bosses = get_tree().get_nodes_in_group("boss")
		bosses[0].connect("boss_died", _on_boss_died)
		wave_9 = true
	
func _on_boss_died():
	pause_timer()
	%Victory.visible = true
	get_tree().paused = true
	%Victory.process_mode = Node.PROCESS_MODE_ALWAYS
	%Victory.get_child(0).process_mode = Node.PROCESS_MODE_ALWAYS
	if win_flag:
		SoundManager.victory()
		win_flag = false
	
func spawn_mob(enemies_type, spawn_loop_i : int):
	for i in range(spawn_loop_i):
		if mob_count < max_mob:
			var new_mob = enemies_type.instantiate()
			%PathFollow2D.progress_ratio = randf()
			new_mob.global_position = %PathFollow2D.global_position
			add_child(new_mob)
			mob_count+=1
			new_mob.mob_died.connect(score_add)
			new_mob.mob_died.connect(mob_died_check)

func spawn_mob_group(enemies_type, spawn_loop_i: int):
	# 1. Выбираем случайную точку на PathFollow2D
	%PathFollow2D.progress_ratio = randf()
	var center_position = %PathFollow2D.global_position
	
	# 2. Настройки кучки
	var cluster_radius = 500.0  # Радиус области спавна
	var min_distance = 15.0    # Минимальное расстояние между мобами
	
	# 3. Спавним мобов кучкой
	for i in range(spawn_loop_i):
		if mob_count >= max_mob:
			break
			
		# Генерируем случайную позицию в круге
		var angle = randf() * 2 * PI
		var distance = randf() * cluster_radius
		var spawn_pos = center_position + Vector2(cos(angle), sin(angle)) * distance
		
		# Проверяем, не слишком ли близко к другим мобам
		var position_valid = true
		for child in get_children():
			if child is RigidBody2D && child.global_position.distance_to(spawn_pos) < min_distance:
				position_valid = false
				break
				
		if position_valid:
			var new_mob = enemies_type.instantiate()
			new_mob.global_position = spawn_pos
			add_child(new_mob)
			mob_count += 1
			new_mob.mob_died.connect(score_add)
			new_mob.mob_died.connect(mob_died_check)

func mob_run_away():
	var mobs = get_tree().get_nodes_in_group("mobs")
	for mob in mobs:
		mob.scary_activated()

func mob_power_increase(mob_name, spawn_rate, max_in_wave):
	enemy_data[mob_name]["timer_node"].wait_time = spawn_rate
	enemy_data[mob_name]["max_in_wave"] = max_in_wave
	
func _on_slime_spawn_1_timeout() -> void:
	spawn_choice = randi_range(1, 3)
	match spawn_choice:
		1: spawn_mob(enemy_data["gray_slime"]["scene"], enemy_data["gray_slime"]["max_in_wave"])
		2: spawn_mob_group(enemy_data["gray_slime"]["scene"], enemy_data["gray_slime"]["max_in_wave"])
		3: spawn_mob_group(enemy_data["gray_slime"]["scene"], enemy_data["gray_slime"]["max_in_wave"])
	if wave_2:
		spawn_choice = randi_range(1, 3)
		match spawn_choice:
			1: spawn_mob(enemy_data["armored_slime"]["scene"], enemy_data["armored_slime"]["max_in_wave"])
			2: spawn_mob_group(enemy_data["armored_slime"]["scene"], enemy_data["armored_slime"]["max_in_wave"])
			3: spawn_mob_group(enemy_data["armored_slime"]["scene"], enemy_data["armored_slime"]["max_in_wave"])

func _on_slime_spawn_2_timeout() -> void:
	spawn_choice = randi_range(1, 2)
	match spawn_choice:
		1: spawn_mob(enemy_data["fast_slime"]["scene"], enemy_data["fast_slime"]["max_in_wave"])
		2: spawn_mob_group(enemy_data["fast_slime"]["scene"], enemy_data["fast_slime"]["max_in_wave"])
