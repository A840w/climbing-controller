extends  Node
enum Direction{
	NORTH,
	NORTH_EAST,
	EAST,
	SOUTH_EAST,
	SOUTH,
	SOUTH_WEST,
	WEST,
	NORTH_WEST
}

static  func get_cardinal_direction(forward: Vector3) -> Direction:
	var angle = atan2(forward.x, -forward.z,)
	return get_cardinal_from_angle(angle)

static  func get_cardinal_from_angle(angle: float) -> Direction:

	angle = fmod(angle, TAU)
	if angle < 0:
		angle += TAU

	var sector = int(round(angle / (TAU/8))) % 8

	match sector:
		0: return Direction.NORTH
		1: return Direction.NORTH_EAST
		2: return Direction.EAST
		3: return Direction.SOUTH_EAST
		4: return Direction.SOUTH
		5: return Direction.SOUTH_WEST
		6: return Direction.WEST
		7: return Direction.NORTH_WEST
	return Direction.NORTH

static  func get_direction_string(dir: Direction) -> String:
	match  dir:
		Direction.NORTH: return "NORTH"
		Direction.NORTH_EAST: return "NORTHEAST"
		Direction.EAST: return "EAST"
		Direction.SOUTH_EAST: return "SOUTHEAST"
		Direction.SOUTH: return "SOUTH"
		Direction.SOUTH_WEST: return "SOUTHWEST"
		Direction.WEST: return "WEST"
		Direction.NORTH_WEST: return "NORTHWEST"
	return "UNKNOWN"

static  func get_short_direction(dir: Direction) -> String:
	match  dir:
		Direction.NORTH: return "N"
		Direction.NORTH_EAST: return "NE"
		Direction.EAST: return "E"
		Direction.SOUTH_EAST: return "SE"
		Direction.SOUTH: return "S"
		Direction.SOUTH_WEST: return "SW"
		Direction.WEST: return "W"
		Direction.NORTH_WEST: return "NW"
	return "?"

static func get_degrees(dir: Direction) -> float:
	match dir:
		Direction.NORTH: return 0
		Direction.NORTH_EAST: return 45
		Direction.EAST: return 90
		Direction.SOUTH_EAST: return 135
		Direction.SOUTH: return 180
		Direction.SOUTH_WEST: return 225
		Direction.WEST: return 270
		Direction.NORTH_WEST: return 315
	return 0

func get_continuous_heading(forward: Vector3) -> String:
	var angle = atan2(forward.x, -forward.z)
	var degrees = rad_to_deg(angle)
	if degrees < 0:
		degrees += 360
	
	# Get cardinal direction
	var dir = get_cardinal_direction(forward)
	var dir_str = get_short_direction(dir)
	
	return "%s' %.1f°" % [dir_str, degrees]

static func get_heading_string(forward: Vector3, include_deg : bool= true) -> String:
	var dir = get_cardinal_direction(forward)
	var dir_str = get_direction_string(dir)

	if include_deg:
		var degrees = get_degrees(dir)
		return "%s %d " % [dir_str, degrees ]
	else:
		return dir_str
