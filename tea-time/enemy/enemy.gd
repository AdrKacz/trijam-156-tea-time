extends KinematicBody2D

signal bounce(collided_with_name)
signal exploded

export (Color) var on_color : Color = Color(1, 1, 1, 1)
export (Color) var off_color : Color = Color(0, 0, 0, 1)

export (float, 1, 5000) var speed : float = 50

export (float, 0.1, 1) var swap_time : float  = 0.2
export (float, 0.1, 2) var delta_factor : float = 0.3

export (bool) var activated : bool = false
export (bool) var is_tea : bool = false
export (bool) var is_on : bool = false

onready var time_until_swap : float = swap_time

onready var mesh : Node2D = $Mesh
onready var marker : Node2D = $Marker
onready var remote_transform : RemoteTransform2D = $RemoteTransform2D
onready var animation_player : AnimationPlayer = $AnimationPlayer

var velocity : Vector2 = Vector2()

var is_stopped : bool = true
var is_exploded : bool = false

func _ready() -> void:
	set_process(false)
	
func reset(reset_position : Vector2, reset_rotation : float, reset_is_on : bool) -> void:
	collision_layer = 1
	collision_mask = 1
	is_on = not reset_is_on
	swap()
	global_position = reset_position
	velocity = Vector2(speed, 0).rotated(deg2rad(reset_rotation))
	
	desactivate()
	desactivate_host()
	mesh.show()
	
	is_stopped = false
	is_exploded = false
	
func _physics_process(delta : float) -> void:
	if is_stopped:
		delta = 0
	if is_tea:
		delta *= delta_factor
	
	var collision : KinematicCollision2D = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.normal)
		if activated and collision.collider.is_in_group("enemy"):
			emit_signal("bounce", collision.collider.name)
			
	time_until_swap -= delta
	if time_until_swap < 0:
		swap()
		time_until_swap = swap_time
	
	
func swap() -> void:
	is_on = not is_on
	if is_on:
		mesh.modulate = on_color
	else:
		mesh.modulate = off_color
		
func explode() -> void:
	desactivate_host()
	collision_layer = 0
	collision_mask = 0
	mesh.hide()
	animation_player.play("explosion")
	is_stopped = true
	is_exploded = true
	
	
func activate_host() -> void:
	marker.show()
	
func desactivate_host() -> void:
	marker.hide()


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "explosion":
		emit_signal("exploded")
		
func activate(relative_node_path : NodePath) -> void:
	activated = true 
	remote_transform.remote_path = relative_node_path

func desactivate() -> void:
	activated = false
	remote_transform.remote_path = remote_transform.get_path_to(self)

func capture() -> void:
	is_stopped = true
