extends Node2D


func play_walk():
	%AnimationPlayer.play("walk")

func play_idle():
	%AnimationPlayer.play("idle")

func play_hurt():
	%AnimationPlayer.play("hurt")
	%AnimationPlayer.queue("walk")
func play_scary():
	%AnimationPlayer.play("scary")

	
func play_boss_walk():
	%AnimationPlayer.play("boss_walk")
