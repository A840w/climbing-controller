extends Node3D

## Drives sun, moon, sky, and fog from TimeManager signals.
## Place this in your 3D world and assign the exported nodes.

@export_group("Celestial Bodies")
@export var sun: DirectionalLight3D
@export var moon: DirectionalLight3D
@export var world_environment: WorldEnvironment

@export_group("Sun")
@export var max_sun_energy: float = 1.3
@export var sun_color_day: Color = Color(1.0, 0.98, 0.95)
@export var sun_color_dawn: Color = Color(1.0, 0.62, 0.32)
@export var sun_color_dusk: Color = Color(1.0, 0.42, 0.28)

@export_group("Moon")
@export var max_moon_energy: float = 0.35
@export var moon_color: Color = Color(0.72, 0.78, 1.0)

@export_group("Sky & Fog")
@export var day_sky_energy: float = 1.0
@export var night_sky_energy: float = 0.04
@export var dawn_dusk_sky_energy: float = 0.3
@export var day_fog_color: Color = Color(0.76, 0.82, 0.92)
@export var night_fog_color: Color = Color(0.02, 0.02, 0.05)
@export var dawn_fog_color: Color = Color(0.92, 0.6, 0.38)

var _sky_mat: PhysicalSkyMaterial
var _env: Environment


func _ready() -> void:
	if world_environment and world_environment.environment:
		_env = world_environment.environment
		if _env.sky and _env.sky.sky_material:
			_sky_mat = _env.sky.sky_material
			if not _sky_mat is PhysicalSkyMaterial:
				push_warning("DayNightCycle: Sky material is not PhysicalSkyMaterial!")

	# Ensure only the sun drives the sky shader's sun disk
	if sun:
		sun.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_AND_SKY
	if moon:
		moon.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY

	TimeManager.time_changed.connect(_on_time_changed)
	# Initialize immediately
	_on_time_changed(0, 0, 0, TimeManager.current_time_hours)


func _on_time_changed(_h: int, _m: int, _s: int, total_hours: float) -> void:
	_update_celestial_positions(total_hours)
	_update_light_properties(total_hours)
	_update_sky_and_fog(total_hours)


func _update_celestial_positions(hour: float) -> void:
	var sun_dir := TimeManager.get_sun_direction()

	if sun:
		# Basis.looking_at aligns -Z to the target vector.
		# Light shines TOWARD -sun_dir (since sun_dir is where it comes FROM).
		sun.global_transform.basis = Basis.looking_at(-sun_dir, Vector3.UP)

	if moon:
		var moon_dir := -sun_dir
		moon.global_transform.basis = Basis.looking_at(-moon_dir, Vector3.UP)


func _update_light_properties(hour: float) -> void:
	if not sun or not moon:
		return

	var sun_dir := TimeManager.get_sun_direction()
	var elevation := sun_dir.y  # 1.0 = zenith, 0.0 = horizon, -1.0 = nadir

	# --- Sun ---
	var sun_factor := smoothstep(-0.15, 0.35, elevation)
	sun.light_energy = lerpf(0.0, max_sun_energy, sun_factor)

	var sun_col: Color
	if hour < 5.0 or hour >= 19.0:
		sun_col = sun_color_dusk
	elif hour < 7.0:
		sun_col = sun_color_dawn.lerp(sun_color_day, (hour - 5.0) / 2.0)
	elif hour < 17.0:
		sun_col = sun_color_day
	elif hour < 19.0:
		sun_col = sun_color_day.lerp(sun_color_dusk, (hour - 17.0) / 2.0)
	else:
		sun_col = sun_color_dusk
	sun.light_color = sun_col

	# --- Moon (opposite phase) ---
	var moon_elevation := -elevation
	var moon_factor := smoothstep(-0.15, 0.35, moon_elevation)
	moon.light_energy = lerpf(0.0, max_moon_energy, moon_factor)
	moon.light_color = moon_color

	# Shadow handoff: only dominant body casts shadows (prevents flickering)
	var sun_dominant := sun.light_energy > moon.light_energy
	sun.shadow_enabled = sun_dominant
	moon.shadow_enabled = not sun_dominant


func _update_sky_and_fog(hour: float) -> void:
	if not _sky_mat or not _env:
		return

	var elevation := TimeManager.get_sun_direction().y

	# Sky energy multiplier
	var sky_energy: float
	if elevation > 0.1:
		sky_energy = day_sky_energy
	elif elevation > -0.1:
		sky_energy = lerpf(dawn_dusk_sky_energy, day_sky_energy, (elevation + 0.1) / 0.2)
	else:
		sky_energy = night_sky_energy
	_sky_mat.energy_multiplier = sky_energy

	# Fog color & density
	var fog_col: Color
	if elevation > 0.1:
		fog_col = day_fog_color
	elif elevation > -0.1:
		if hour < 12.0:
			fog_col = dawn_fog_color.lerp(day_fog_color, (elevation + 0.1) / 0.2)
		else:
			fog_col = day_fog_color.lerp(dawn_fog_color, (0.1 - elevation) / 0.2)
	else:
		fog_col = night_fog_color
	_env.fog_light_color = fog_col
	_env.fog_light_energy = clampf(elevation * 0.5 + 0.5, 0.1, 1.0)

	# Ground color darkens at night
	var day_ground := Color(0.1, 0.07, 0.05)
	var night_ground := Color(0.01, 0.01, 0.02)
	_sky_mat.ground_color = night_ground.lerp(day_ground, clampf(elevation + 0.2, 0.0, 1.0))
