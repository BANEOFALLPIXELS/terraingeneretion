extends Node3D

# Constants for terrain generation
@export var WIDTH = 100
@export var HEIGHT = 100
@export var DEPTH = 100
@export var HEIGHT_SCALE = 20
@export var CELL_SIZE = 1.0
@export var WATER_LEVEL = 0.5 # Adjust water level as needed
@export var terrain_material:StandardMaterial3D
@export var water_material:StandardMaterial3D 

var tempreture = {}
var moisture = {}
var altitude = {}
var water_pos
# Noise generators
@export var terrain_noise:FastNoiseLite
@export var biome_noise:FastNoiseLite

# Mesh data
var terrain_mesh_instance = MeshInstance3D.new()
var water_mesh_instance = MeshInstance3D.new()

func _ready():
	terrain_noise.seed = randi()
	# Configure the mesh
	tempreture = generate_biome_variables(122, 5)
	moisture = generate_biome_variables(492, 5)
	altitude = get_altitude()
	terrain_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	water_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	terrain_mesh_instance.material_override = terrain_material
	water_mesh_instance.material_override = water_material
	# Generate the terrain mesh
	var terrain_mesh = generate_terrain()
	terrain_mesh_instance.mesh = terrain_mesh
	add_child(terrain_mesh_instance)

	# Generate the water mesh
	var water_mesh = generate_water()
	water_mesh_instance.mesh = water_mesh
	add_child(water_mesh_instance)

	
func generate_terrain():
	var terrain_mesh = SurfaceTool.new()
	terrain_mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for x in range(WIDTH):
		for z in range(DEPTH):
			# Calculate the height using the terrain_noise
			var height = terrain_noise.get_noise_2d(x * CELL_SIZE, z * CELL_SIZE) * HEIGHT_SCALE
			
			# Define the vertices
			var v0 = Vector3(x * CELL_SIZE, height, z * CELL_SIZE)
			var v1 = Vector3((x + 1) * CELL_SIZE, terrain_noise.get_noise_2d((x + 1) * CELL_SIZE, z * CELL_SIZE) * HEIGHT_SCALE, z * CELL_SIZE)
			var v2 = Vector3(x * CELL_SIZE, terrain_noise.get_noise_2d(x * CELL_SIZE, (z + 1) * CELL_SIZE) * HEIGHT_SCALE, (z + 1) * CELL_SIZE)
			var v3 = Vector3((x + 1) * CELL_SIZE, terrain_noise.get_noise_2d((x + 1) * CELL_SIZE, (z + 1) * CELL_SIZE) * HEIGHT_SCALE, (z + 1) * CELL_SIZE)
		
			# Create the two triangles for the quad
			terrain_mesh.add_vertex(v0)
			terrain_mesh.add_vertex(v1)
			terrain_mesh.add_vertex(v2)

			terrain_mesh.add_vertex(v1)
			terrain_mesh.add_vertex(v3)
			terrain_mesh.add_vertex(v2)
			#biomes
	Biome_Generetor()
	terrain_mesh.index()
	return terrain_mesh.commit()

func generate_water():
	var water_mesh = SurfaceTool.new()
	water_mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
   
	var v0 = Vector3(0, WATER_LEVEL, 0)
	var v1 = Vector3(WIDTH * CELL_SIZE, WATER_LEVEL, 0)
	var v2 = Vector3(0, WATER_LEVEL, DEPTH * CELL_SIZE)
	var v3 = Vector3(WIDTH * CELL_SIZE, WATER_LEVEL, DEPTH * CELL_SIZE)

	# Define the triangles for the water surface
	water_mesh.add_vertex(v0)
	water_mesh.add_vertex(v1)
	water_mesh.add_vertex(v2)
	
	water_mesh.add_vertex(v1)
	water_mesh.add_vertex(v3)
	water_mesh.add_vertex(v2)
	
	water_mesh.index()
	return water_mesh.commit()

#generates noise for biomes
func generate_biome_variables(per, oct):
	#sets the seed random for spice
	biome_noise.seed = randi()
	biome_noise.fractal_gain = per
	biome_noise.fractal_octaves = oct
	var gridname = {}
	for x in range(WIDTH):
		for z in range(DEPTH):
			var rand = 2 * (abs(FastNoiseLite.new().get_noise_2d(x, z))) 
			gridname[Vector2(x, z)] = rand
	return gridname
	
#gets the altitude of current terrain noise
func get_altitude():
	var gridname = {}
	for x in range(WIDTH):
		for z in range(DEPTH):
			var rand = 2 * (abs(terrain_noise.get_noise_2d(x, z))) 
			gridname[Vector2(x, z)] = rand
	return gridname	

func Biome_Generetor():
	for x in range(WIDTH):
		for z in range(DEPTH):
			var pos = Vector2(x, z)
			var alt = altitude[pos]
			var temp = tempreture[pos]
			var moist = moisture[pos]
			
			# Assign biomes based on altitude, temperature, and moisture
			var biome = assign_biome(alt, temp, moist)
			
			# Do something with the assigned biome (e.g., color terrain)
			color_terrain(pos, biome)
			

func assign_biome(altitude, temperature, moisture):
	if altitude < WATER_LEVEL:
		return "Ocean"
	
	if altitude < WATER_LEVEL + 0.2:
		return "Beach"
	
	if temperature > 1:
		if moisture < 0.2:
			return "Desert"
		elif moisture < 0.6:
			return "Savanna"
		else:
			return "Tropical Rainforest"
	
	if temperature < 0.5:
		if moisture < 0.4:
			return "Tundra"
		else:
			return "Taiga"
	
	if moisture < 0.2:
		return "Grassland"
	
	if moisture < 0.6:
		return "Forest"
	
	return "Rainforest"

func color_terrain(position, biome):
	# Example: Color terrain based on biome
	var terrain_color
	
	if biome == "Ocean":
		terrain_color = Color(0.2, 0.4, 0.8)
	elif biome == "Beach":
		terrain_color = Color(0.9, 0.8, 0.6)
	elif biome == "Desert":
		terrain_color = Color(0.9, 0.8, 0.5)
	elif biome == "Savanna":
		terrain_color = Color(0.7, 0.8, 0.4)
	elif biome == "Tropical Rainforest":
		terrain_color = Color(0.1, 0.5, 0.1)
	elif biome == "Tundra":
		terrain_color = Color(0.8, 0.9, 0.9)
	elif biome == "Taiga":
		terrain_color = Color(0.6, 0.7, 0.7)
	elif biome == "Grassland":
		terrain_color = Color(0.4, 0.7, 0.2)
	elif biome == "Forest":
		terrain_color = Color(0.2, 0.5, 0.1)
	elif biome == "Rainforest":
		terrain_color = Color(0.1, 0.3, 0.1)
	else:
		terrain_color = Color(1, 1, 1)  # Default color if biome not recognized
	
	# Apply the terrain color to the terrain at the specified position
	apply_terrain_color(position, terrain_color)

	# Example: Color terrain based on biome
	match biome:
		"Ocean":
			return Color(0.2, 0.4, 0.8)
		"Beach":
			return Color(0.9, 0.8, 0.6)
		"Desert":
			return Color(0.9, 0.8, 0.5)
		"Savanna":
			return Color(0.7, 0.8, 0.4)
		"Tropical Rainforest":
			return Color(0.1, 0.5, 0.1)
		"Tundra":
			return Color(0.8, 0.9, 0.9)
		"Taiga":
			return Color(0.6, 0.7, 0.7)
		"Grassland":
			return Color(0.4, 0.7, 0.2)
		"Forest":
			return Color(0.2, 0.5, 0.1)
		"Rainforest":
			return Color(0.1, 0.3, 0.1)
	
	# Apply the terrain color to the terrain at the specified position
	apply_terrain_color(position, terrain_color)

func apply_terrain_color(position, color):
	# Example: Set the color of the terrain at the specified position
	# This is where you would apply the color to your terrain mesh
	# Replace this with your actual implementation
	print(position, color)
	
func between(val, start, end):
	if start <= val or val < end:
		return true
