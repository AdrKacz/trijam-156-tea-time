extends Node

signal done
signal gameover

export (Array, AudioStream) var audio_streams : Array

export (float) var tea_time : float = 3
export (float) var host_time : float = 0.5
export (int) var target_index : int = 0
export (int) var host_index : int = 0

onready var enemies : Node2D = $Enemies
onready var player : Node2D = $Player
onready var animation_player : AnimationPlayer = $AnimationPlayer
onready var audio_capture : AudioStreamPlayer = $AudioStreamPlayerCapture

onready var time_until_tea_time : float = tea_time
onready var time_until_host : float = host_time

var is_tea : bool = false
var run_time : float = 0
var captured_enemy : int = 0

var is_stopped : bool = true

func _ready() -> void:
	randomize()
	
	enemies.get_children()[0].activate_host()
	for enemy in enemies.get_children():
		enemy.connect("bounce", self, "_on_Enemy_Bounce", [enemy.name])
		enemy.connect("exploded", self, "_on_Enemy_Exploded", [enemy.name])

func reset() -> void:
	time_until_host = host_time
	time_until_tea_time = tea_time
	
	run_time = 0
	captured_enemy = 0
	
	var i : int = 0
	for enemy in enemies.get_children():
		var reset_position : Vector2 = Vector2(-400 + 200 * i, rand_range(-400, 400))
		var reset_rotation = rand_range(0, 360)
		var reset_is_on = true if randf() > .5 else false
		if i == 0:
			reset_is_on = true
		enemy.reset(reset_position, reset_rotation, reset_is_on)
		i += 1
	
	target_index = 0
	host_index = 0
	change_target(target_index)
	
	is_tea = true
	swap_tea()
	
	is_stopped = false

func _process(delta : float):
	if is_stopped:
		return
	run_time += delta
	time_until_tea_time -= delta

	if time_until_tea_time <= 0:
		time_until_tea_time = tea_time
		swap_tea()
		
	if is_tea:
		swap_nearest()
	else:
		time_until_host -= delta
		if time_until_host <= 0:
			time_until_host = host_time
			swap_random()
		
	
func swap_nearest() -> void:
	enemies.get_children()[host_index].desactivate_host()
	var target_enemy : KinematicBody2D = enemies.get_children()[target_index]
	var nearest_squared_distance : float = INF
	var i : int = 0
	for enemy in enemies.get_children():
		i += 1
		if enemy.is_stopped or enemy.name == target_enemy.name:
			continue
		var squared_distance : float = target_enemy.global_transform.origin.distance_squared_to(enemy.global_transform.origin)
		if squared_distance < nearest_squared_distance:
			nearest_squared_distance = squared_distance
			host_index = i - 1
	enemies.get_children()[host_index].activate_host()
	
func swap_random() -> void:
	enemies.get_children()[host_index].desactivate_host()
	host_index = randi() % enemies.get_child_count()
	while enemies.get_children()[host_index].is_stopped:
		host_index = (host_index + 1) % enemies.get_child_count()
	enemies.get_children()[host_index].activate_host()

func swap_host() -> void:
	if is_tea:
		swap_nearest()
	else:	
		swap_random()

func swap_tea() -> void:
	time_until_host = host_time
	is_tea = not is_tea
	for enemy in enemies.get_children():
		enemy.is_tea = is_tea
	player.swap_to(is_tea)
	
	if is_tea:
		animation_player.play("slow-down")
		if not enemies.get_children()[target_index].is_on:
			enemies.get_children()[target_index].swap()
		capture_target()
	else:
		animation_player.play("speed-up")


func _on_Enemy_Bounce(enemy_name : String, enemy_activated_name : String) -> void:
	pass
#	enemies.get_node(enemy_name).explode()
#	enemies.get_node(enemy_activated_name).explode()

func _on_Enemy_Exploded(enemy_exploded_name : String) -> void:
#	var enemy : KinematicBody2D = enemies.get_node(enemy_exploded_name)
#	enemies.remove_child(enemy)
#	enemy.queue_free()
	if not is_stopped:
		is_stopped = true
		emit_signal("gameover")

func _input(event):
	if event.is_action_pressed("action"):
		if is_stopped: # Menu Phase
			player.game_ui.hide()
			reset()
		else: # Game Phase
			change_target(host_index)
			var enemy : KinematicBody2D = enemies.get_children()[target_index]
			if is_tea:
				if enemy.is_on:
					capture_target()
				else:
					enemy.explode()
					
func capture_target() -> void:
	if not enemies.get_children()[target_index].is_stopped:
		enemies.get_children()[target_index].capture()
		captured_enemy += 1
		if captured_enemy == enemies.get_child_count():
			emit_signal("done")
			is_stopped = true
			
		# Play sound
		audio_capture.stream = audio_streams[randi() % audio_streams.size()]
		audio_capture.play()

func change_target(new_target_index : int):
	enemies.get_children()[target_index].desactivate()
	target_index = new_target_index
	var enemy : KinematicBody2D = enemies.get_children()[target_index]
	var relative_node_path : NodePath = enemy.remote_transform.get_path_to(player)
	enemy.activate(relative_node_path)

func _on_Game_done():
	player.game_ui.show()
	player.game_ui.status_label.text = "Well done"
	player.game_ui.info_label.text = "You took %05.2f seconds" % run_time


func _on_Game_gameover():
	player.game_ui.show()
	player.game_ui.status_label.text = "Game Over"
	player.game_ui.info_label.text = "You captured %d balls" % captured_enemy
