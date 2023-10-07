extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
var was_pressed = false
var distance = 1.0

var cooldown = 0.0
var sh
func _process(delta):
	if cooldown > 0:
		cooldown -= delta
		return
		
	if Input.is_physical_key_pressed(KEY_X):
		if not was_pressed:
			was_pressed = true
			cooldown = 0.2
			$Hero.velocity.y = $Hero.JUMP_VELOCITY
			sh = $Hero.global_position.y-0.5
		else:
			distance += 0.5
		#var sh = $LandscapeEditDemo.get_average_height($Hero.global_position + $Hero.direction.normalized()*distance, 4.0)
		$LandscapeEditDemo.modify_height($Hero.global_position  + $Hero.direction.normalized()*distance, 4.0, sh)
	else:
		was_pressed = false
		distance = 1.0
