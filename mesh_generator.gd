@tool
extends MeshInstance3D

enum {BACK, LEFT, FRONT, RIGHT, TOP, BOTTOM}
const x_size = 8
const y_size = 8
const z_size = 8


var data:Array

#first top, then the sides!!
var block_uv_maps:Array = [
	[1, 1, 1, 1, 1, 1],
	[0, 0, 0, 0, 1, 0],#grass block!!
	[2, 2, 2, 2, 3, 2]
]


# Called when the node enters the scene tree for the first time.
func mesh_gen(_data:Array):
	data = _data
	#set_data(data, _data)
	var arrays:Array
	var index_size = 0
	
	var vertex:PackedVector3Array
	var index:PackedInt32Array
	var normal:PackedVector3Array
	var uv:PackedVector2Array
	
	arrays.resize(Mesh.ARRAY_MAX)
	
	#loopingg thru the data, and generating individual cube face for the chunk!!!. and appending to the main-chunk!!
	for i in range(0, 512):
		var position:Vector3 = num_to_vec(i)
		if not data[i]==0:
			var free_face:Array = find_neighbour_voxel(data, position.x, position.y, position.z)
			var temp_arr:Dictionary = cube_gen(position, free_face, data[i])
			vertex.append_array(temp_arr["vertex"])
			uv.append_array(temp_arr["uv"])
			normal.append_array(temp_arr["normal"])
		pass
	
	arrays[Mesh.ARRAY_VERTEX] = vertex
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_NORMAL] = normal
	
	#after generating the mesh, upload it to the MeshInstance, and make a collision body, and a material
	if vertex.size() > 0:
		mesh = ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	
		#adding a new material
		var mat:StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_texture = preload("res://tile_map.png")
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
		mat.specular_mode = BaseMaterial3D.SPECULAR_TOON
		mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
		mat.roughness = 0
		mat.albedo_color = Color(0.7, 0.7, 0.7)
		set_surface_override_material(0, mat)
		
		#making the collision shape and stuff!!
		create_trimesh_collision()

func find_neighbour_voxel(arr, x,y,z):
	var free_face:Array = [FRONT, BACK, LEFT, RIGHT, TOP, BOTTOM]
	if x>0:
		var index:int = vec_to_num(x-1, y, z)
		if not arr[index] == 0:
			free_face.erase(LEFT)
	if x<x_size - 1:
		var index:int = vec_to_num(x+1, y, z)
		if not arr[index] == 0:
			free_face.erase(RIGHT)
	if y>0:
		var index:int = vec_to_num(x, y-1, z)
		if not arr[index] == 0:
			free_face.erase(BOTTOM)
	if y<y_size-1:
		var index:int = vec_to_num(x, y+1, z)
		if not arr[index] == 0:
			free_face.erase(TOP)
	if z>0:
		var index:int = vec_to_num(x, y, z-1)
		if not arr[index] == 0:
			free_face.erase(BACK)
	if z<z_size-1:
		var index:int = vec_to_num(x, y, z+1)
		if not arr[index] == 0:
			free_face.erase(FRONT)
	return free_face


func num_to_vec(num:int):
	var ret:Vector3
	ret.x = num % x_size
	ret.y = floor(num / (x_size * z_size))
	ret.z = floor(( num - (x_size * z_size) * ret.y) / z_size)
	return ret

func vec_to_num(x:int, z:int, y:int):
	return (x + (y*x_size)) + (z*(x_size * y_size))

func id_to_uv(id:int) -> Vector2:
	var ret:Vector2 = Vector2(floor(id/10), id%10) * 0.1
	return ret

func cube_gen(position:Vector3, directions:Array, tile_type:int):
	var return_dict:Dictionary = {"vertex":[], "index":[], "normal":[], "uv":[] }
	var cube_vertices:PackedVector3Array = [
		Vector3(0,0,0),
		Vector3(0,1,0),
		Vector3(1,1,0),
		Vector3(1,0,0),
		Vector3(0,0,1),
		Vector3(0,1,1),
		Vector3(1,1,1),
		Vector3(1,0,1),
	]
	
	var cube_normals:PackedVector3Array = [
		Vector3(0, 0, -1),
		Vector3(-1, 0, 0),
		Vector3(0, 0, 1),
		Vector3(1, 0, 0),
		Vector3(0, 1, 0),
		Vector3(0, -1, 0)
	]

	var cube_indices:PackedInt32Array = [
		2, 1, 0,#front
		0, 3, 2,
		1, 5, 4,#right
		4, 0, 1,
		5, 6, 7,#back
		7, 4, 5,
		6, 2, 3,#left
		3, 7, 6,
		6, 5, 1,#top
		1, 2, 6,
		0, 4, 7,#bottom
		7, 3, 0
	]
	
	var cube_uv:PackedVector2Array = [
		Vector2(1,0),
		Vector2(0,0),
		Vector2(0,1),
		Vector2(0,1),#2nd triangle
		Vector2(1,1),
		Vector2(1,0)
	]

	#looping thru all the directions
	#all it does is appending the face's vertex position
	for dir in directions:
		#oh well, if a direction exists, you gotta ( dir*6 ) to get the face's position in cube_indices!!.
		#due to no slicing in gdscript, Im manually copying the next 6 element using a loop!!
		for i in range(6):
			var index:int = i + (dir * 6)
			var cube_index:int = cube_indices[index]
			return_dict["vertex"].append(cube_vertices[cube_index] + position)
			#adding the normal!!
			return_dict["normal"].append(cube_normals[dir])
			
			#adding the UV coords!!!
			var tile_id:int = block_uv_maps[tile_type][dir]
			var temp_cube_uv:Vector2 = (cube_uv[i] * 0.1) + id_to_uv(tile_id)
			return_dict["uv"].append(temp_cube_uv)
	return return_dict

