extends Node2D

signal attached

export (float, 100, 1000) var epsilon = 100

export (Vector2) var target_global_position : Vector2 = Vector2()
export (String) var target_name : String = ""
export (float, 100, 50000) var speed = 2000

onready var camera : Camera2D = $Camera2D
onready var game_ui : Control = $CanvasLayer/GameUI

onready var animation_player : AnimationPlayer = $AnimationPlayer

func swap_to(is_tea : bool):
	if is_tea:
		animation_player.play("zoom-in")
	else:
		animation_player.play("zoom-out")

