extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 9.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var direction = Vector3.FORWARD

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var mov = Input.get_axis("ui_up", "ui_down")
	var rot = Input.get_axis("ui_left", "ui_right")
#	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, -rot*0.1)
	
	$Node3D.rotation.y = rotate_toward($Node3D.rotation.y, -direction.signed_angle_to(Vector3.FORWARD, Vector3.UP), 0.1)
	if abs(mov):
		var vy = velocity.y
		velocity = direction.normalized() * SPEED * -mov
		velocity.y = vy
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
