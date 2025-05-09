extends Node2D
var score = 0
var mob_count = 0
var max_mob = 600

@export var timer_label: Label  # Label для вывода времени
var start_time: int
var paused_time: int = 0  # Накопленное время паузы
var is_paused: bool = false


@onready var slime_spawn_1 : Timer = $slime_spawn_1
@onready var slime_spawn_2 : Timer = $slime_spawn_2
var enemy_data = {}

var wave_1 = false
var wave_2 = false
var wave_3 = false
var wave_4 = false
var wave_5 = false
var wave_6 = false
var wave_7 = false
var wave_8 = false
var wave_9 = false


func _ready() -> void:
	%ScoreLabel.text = "Score: " + str(score)
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
	}
	
func score_add():
	score+=1
	%ScoreLabel.text = "Score: " + str(score)

func mob_died_check():
	mob_count-=1

func _on_player_health_depleted() -> void:
	pause_timer()
	%GameOver.visible = true
	get_tree().paused = true
	%GameOver.process_mode = Node.PROCESS_MODE_ALWAYS
	%GameOver.get_child(0).process_mode = Node.PROCESS_MODE_ALWAYS 

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
		is_paused = true

func unpause_timer():
	if is_paused:
		start_time = Time.get_ticks_msec()
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
	
	########## WAVE 1 ############
	if current_time_sec >= 1.0 and !wave_1:
		mob_power_increase("gray_slime", 5.0, 10)
		slime_spawn_1.autostart = true
		slime_spawn_1.start()
		wave_1 = true
		
	######### WAVE 2 ############	
	if current_time_sec >= 120.0 and !wave_2:
		mob_power_increase("gray_slime", 5.0, 15)
		mob_power_increase("fast_slime", 5.0, 2)
		slime_spawn_2.autostart = true
		slime_spawn_2.start()
		wave_2 = true
		
	######### WAVE 3 ############	
	if current_time_sec >= 240.0 and !wave_3:
		mob_power_increase("gray_slime", 5.0, 20)
		mob_power_increase("fast_slime", 5.0, 4)
		spawn_mob_group(enemy_data["fast_slime"]["scene"], 10)
		wave_3 = true
		
	######### WAVE 4 ############	
	if current_time_sec >= 360.0 and !wave_4:
		mob_power_increase("gray_slime", 5.0, 30)
		spawn_mob(enemy_data["circle_slime"]["scene"], 50)
		spawn_mob(enemy_data["mini_boss_slime"]["scene"], enemy_data["mini_boss_slime"]["max_in_wave"])
		wave_4 = true
		
	######### WAVE 5 ############	
	if current_time_sec >= 480.0 and !wave_5:
		mob_power_increase("gray_slime", 5.0, 30)
		spawn_mob_group(enemy_data["fast_slime"]["scene"], 20)
		mob_power_increase("armored_slime", 5.0, 15)
		wave_5 = true
		
	########## WAVE 6 ############	
	if current_time_sec >= 600.0 and !wave_6:
		mob_power_increase("gray_slime", 10.0, 100)
		mob_power_increase("armored_slime", 5.0, 30)
		mob_power_increase("fast_slime", 5.0, 5)
		slime_spawn_2.autostart = true
		slime_spawn_2.start()
		spawn_mob(enemy_data["circle_slime"]["scene"], 80)
		wave_6 = true
		
	######### WAVE 7 ############	
	if current_time_sec >= 720.0 and !wave_7:
		mob_power_increase("gray_slime", 10.0, 130)
		mob_power_increase("armored_slime", 5.0, 40)
		wave_7 = true
		
	######### WAVE 8 ############	
	if current_time_sec >= 840.0 and !wave_8:
		mob_power_increase("gray_slime", 10.0, 160)
		mob_power_increase("armored_slime", 5.0, 60)
		spawn_mob_group(enemy_data["fast_slime"]["scene"], 30)
		spawn_mob(enemy_data["circle_slime"]["scene"], 130)
		wave_8 = true
		
	######### WAVE 9 ############	
	if current_time_sec >= 960.0 and !wave_8:
		spawn_mob_group(enemy_data["fast_slime"]["scene"], 100)
		spawn_mob(enemy_data["circle_slime"]["scene"], 200)
		wave_8 = true


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

func spawn_mob_group(enemies_type, spawn_loop_i : int):
	%PathFollow2D.progress_ratio = randf()
	var spawn_position = %PathFollow2D.global_position
	for i in range(spawn_loop_i):
		if mob_count < max_mob:
			var new_mob = enemies_type.instantiate()
			new_mob.global_position = spawn_position + Vector2(i * 5, 0)
			add_child(new_mob)
			mob_count+=1
			new_mob.mob_died.connect(score_add)
			new_mob.mob_died.connect(mob_died_check)

func mob_power_increase(mob_name, spawn_rate, max_in_wave):
	enemy_data[mob_name]["timer_node"].wait_time = spawn_rate
	enemy_data[mob_name]["max_in_wave"] = max_in_wave
	
func _on_slime_spawn_1_timeout() -> void:
	spawn_mob(enemy_data["gray_slime"]["scene"], enemy_data["gray_slime"]["max_in_wave"])
	if wave_4:
		spawn_mob(enemy_data["armored_slime"]["scene"], enemy_data["armored_slime"]["max_in_wave"])

func _on_slime_spawn_2_timeout() -> void:
	spawn_mob(enemy_data["fast_slime"]["scene"], enemy_data["fast_slime"]["max_in_wave"])
