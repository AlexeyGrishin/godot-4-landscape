@tool
extends StaticBody3D

@onready var mesh = $LandscapeMesh
@onready var collision_shape = $LandscapeCollisionShape

@export var width: int = 200: 
	set(value):
		width = value
		reset()
		
@export var height: int = 200:
	set(value):
		height = value
		reset()
@export var mesh_data: ArrayMesh
@export var height_map_shape: HeightMapShape3D

var camera: Camera3D
var mesh_data_tool: MeshDataTool

var radius: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	mesh_data_tool = MeshDataTool.new()
	if mesh_data:
		mesh_data_tool.create_from_surface(mesh_data, 0)
	
	if Engine.is_editor_hint() and get_tree().edited_scene_root == self:
		camera = EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
		print("Camera is ", camera)
		await get_tree().process_frame
		initialize()
	else:
		set_process(false)
		set_process_input(false)
		$Cursor.queue_free()

func reset():
	if not Engine.is_editor_hint():
		return
	mesh_data = null
	height_map_shape = null
	initialize()

func initialize():
	if not mesh:
		return
	if not Engine.is_editor_hint():
		return
	
	if not mesh_data:
		mesh_data = ArrayMesh.new()
		var plane = PlaneMesh.new()
		plane.size = Vector2(width, height)
		plane.subdivide_width = width
		plane.subdivide_depth = height
		mesh_data.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane.surface_get_arrays(0))
	mesh.mesh = mesh_data
	mesh_data_tool.clear()
	mesh_data_tool.create_from_surface(mesh_data, 0)
	
	if not height_map_shape:
		height_map_shape = HeightMapShape3D.new()
		height_map_shape.map_width = width
		height_map_shape.map_depth = height
	collision_shape.shape = height_map_shape
	
func _get_vertice_indexes(position: Vector3, radius: float)->Array[int]:
	var array: Array[int] = []
	var position_wo_y = position
	position_wo_y.y = 0
	var radius2 = radius*radius
	for i in mesh_data_tool.get_vertex_count():
		var pos = mesh_data_tool.get_vertex(i)
		# compare only xz
		var pos_wo_y = pos
		pos_wo_y.y = 0
		if pos_wo_y.distance_squared_to(position_wo_y) <= radius2:
			array.append(i)
	return array
	
func get_average_height(position: Vector3, radius: float)->float:
	var vertice_idxs = _get_vertice_indexes(position, radius)
	if len(vertice_idxs) == 0:
		return 0.0
	var sum = 0.0
	for vi in vertice_idxs:
		sum += mesh_data_tool.get_vertex(vi).y
	return sum / float(len(vertice_idxs))

var modifying = false

func modify_height(position: Vector3, radius: float, set_to = null, add = null, random_weight = 0.0, min = -10.0, max = 10.0):
	if modifying:
		return
	modifying = true
	mesh_data_tool.clear()
	mesh_data_tool.create_from_surface(mesh_data, 0)
	
	var vertice_idxs = _get_vertice_indexes(position, radius)
	var t1 = Time.get_ticks_msec()
	for vi in vertice_idxs:
		var pos = mesh_data_tool.get_vertex(vi)
		var rand_offset = random_weight * randf_range(-1, 1) if random_weight else 0.0
		if set_to != null:
			pos.y = set_to + rand_offset
		if add != null:
			pos.y += add + rand_offset
		pos.y = clampf(pos.y, min, max)
		mesh_data_tool.set_vertex(vi, pos)
		var hmy = int((pos.z - global_position.z + height/2.0)*0.99/height*height_map_shape.map_depth)
		var hmx = int((pos.x - global_position.x + width/2.0) * 0.99 / width * height_map_shape.map_width)
		#print(hmx, " ", hmy)
		height_map_shape.map_data[hmy*height_map_shape.map_width + hmx] = pos.y
		#height_map_shape.map_data[hmx*height_map_shape.map_depth + hmy] = pos.y
	mesh_data.clear_surfaces()
	mesh_data_tool.commit_to_surface(mesh_data)
	await get_tree().process_frame
	#TODO: normals
	var t2 = Time.get_ticks_msec()
	var st = SurfaceTool.new()
	st.create_from(mesh_data, 0)
	await get_tree().process_frame
	st.generate_normals()
	await get_tree().process_frame
	st.generate_tangents()
	await get_tree().process_frame
	mesh_data.clear_surfaces()
	st.commit(mesh_data)
	var t3 = Time.get_ticks_msec()
	print("mdt=", (t2-t1),"ms  st=", (t3-t2), "ms")
	modifying = false
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var position = get_viewport().get_mouse_position()
	var pos = camera.project_ray_origin(position)
	var norm = camera.project_ray_normal(position)
	var d = get_world_3d().direct_space_state.intersect_ray(
		PhysicsRayQueryParameters3D.create(pos, pos+norm*9999)
	)
	if "collider" in d and d["collider"] == self:
		$Cursor.global_position = d["position"]
		d = get_world_3d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters3D.create(d["position"]+Vector3.UP, d["position"] + Vector3.DOWN)
		)
		
		if abs(d["normal"].dot(Vector3.UP)) > 0.9:
			$Cursor.rotation_degrees = Vector3(-90,0,0)
			pass 
		else:
			$Cursor.look_at($Cursor.global_position - d["normal"], Vector3.UP)
	($Cursor/CursorMesh.mesh as TorusMesh).outer_radius = radius
	($Cursor/CursorMesh.mesh as TorusMesh).inner_radius = radius - 0.2
	if Input.is_physical_key_pressed(KEY_Q):
		modify_height($Cursor.global_position, radius, null, 0.2)
		
	if Input.is_physical_key_pressed(KEY_Z):
		modify_height($Cursor.global_position, radius, null, -0.2)
		
	if Input.is_physical_key_pressed(KEY_1):
		radius -= 0.1
		radius = max(0.5, radius)

	if Input.is_physical_key_pressed(KEY_2):
		radius += 0.1
		
	if Input.is_physical_key_pressed(KEY_A):
		var ah = get_average_height($Cursor.global_position, radius)
		modify_height($Cursor.global_position, radius, ah, null)
		
	if Input.is_physical_key_pressed(KEY_R):
		var ah = get_average_height($Cursor.global_position, radius)
		modify_height($Cursor.global_position, radius, ah, null, 1.0)

	if Input.is_physical_key_pressed(KEY_X):
		modify_height($Cursor.global_position, radius, 0)
