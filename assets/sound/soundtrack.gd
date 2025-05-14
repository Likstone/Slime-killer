extends Node2D

func _ready():
	process_mode = PROCESS_MODE_ALWAYS

func mob_died():
	if %sound_cd_timer.is_stopped():
		%sound_cd_timer.start()
		%mob_died.play()
		
func laser_shoot():
	if %sound_cd_timer_2.is_stopped():
		%sound_cd_timer_2.start()
		%laser_shoot.play()
		
func electro_shoot():
	if %sound_cd_timer_3.is_stopped():
		%sound_cd_timer_3.start()
		%electro_shoot.play()
		
func gem_take():
	if %sound_cd_timer_4.is_stopped():
		%sound_cd_timer_4.start()
		%gem_take.play()

func level_up():
	if %sound_cd_timer_5.is_stopped():
		%sound_cd_timer_5.start()
		%level_up.play()
		
func player_take_damage():
	if %sound_cd_timer_6.is_stopped():
		%sound_cd_timer_6.start()
		%player_take_damage.play()

func lose():
	soundtrack_stop(4.00)
	%lose.play()
		
func victory():
	soundtrack_stop(2.50)
	%victory.play()

func soundtrack_stop(time):
	%soundtrack.stream_paused = true
	%soundtrack_stop.start(time)
	
func _on_soundtrack_stop_timeout() -> void:
	%soundtrack.stream_paused = false
