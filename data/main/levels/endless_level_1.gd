extends Node2D
var score = 0
var mob_count = 0
var max_mob = 0

@onready var mob_timer : Timer = $Timer
func _ready() -> void:
	%ScoreLabel.text = "Score: " + str( score)
	
func score_add():
	score+=1
	%ScoreLabel.text = "Score: " + str(score)

func mob_died_check():
	mob_count-=1

func spawn_mob():
	if mob_count < max_mob:
		var new_mob = preload("res://data/enemies/mob.tscn").instantiate()
		%PathFollow2D.progress_ratio = randf()
		new_mob.global_position = %PathFollow2D.global_position
		add_child(new_mob)
		mob_count+=1
		new_mob.mob_died.connect(score_add)
		new_mob.mob_died.connect(mob_died_check)
	
	
func _on_timer_timeout() -> void:
	spawn_mob()

func _on_player_health_depleted() -> void:
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
		if mob_timer.wait_time > 0.06:
			mob_timer.wait_time -= 0.01
	
func _on_button_pressed() -> void:
	get_tree().paused = false
	get_tree().call_deferred("change_scene_to_file", "res://data/main/menu/start_menu.tscn")
