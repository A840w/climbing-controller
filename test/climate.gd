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

## Max tilt of the sun's arc away from the celestial equator, in degrees.
## 0 = sun always rises due East. 23.5 mimics Earth's axial tilt.
@export_range(0.0, 45.0, 0.1) var max_axial_tilt_deg: float = 23.5
## How many in-game days for the tilt to complete a full cycle (a "year").
## Leave as -1 to sync with TimeManager's calendar (365.25 days).
@export var tilt_cycle_days: float = -1.0
## Random per-session offset so two runs don't look identical.
@export var randomize_tilt_seed: bool = true

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

## Cached values computed per tick
var _sun_dir: Vector3 = Vector3.RIGHT
var _moon_dir: Vector3 = Vector3.LEFT
var _sun_elevation: float = 0.0

## Tilt state
var _tilt_phase_offset: float = 0.0


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

	if randomize_tilt_seed:
		_tilt_phase_offset = randf() * TAU

	TimeManager.time_changed.connect(_on_time_changed)
	TimeManager.date_changed.connect(_on_date_changed)
	TimeManager.period_changed.connect(_on_period_changed)

	# Initialize immediately
	update_now()


## Public: force a full refresh. Useful after debug teleports.
func update_now() -> void:
	_recompute_directions()
	_update_celestial_positions()
	_update_light_properties()
	_update_sky_and_fog()


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_time_changed(_h: int, _m: int, _s: int, _total_hours: float) -> void:
	update_now()


func _on_date_changed(_day: int, _month: int, _year: int) -> void:
	# Recompute tilt when the date changes so the arc shifts subtly.
	_recompute_directions()
	_update_celestial_positions()


func _on_period_changed(_period: TimeManager.DayPeriod) -> void:
	# Snap shadow handoff instantly on debug jumps.
	_update_light_properties()


# ---------------------------------------------------------------------------
# Direction math (sun, moon, tilt)
# ---------------------------------------------------------------------------

## Returns the tilt (in radians) for the current date.
## 0 at equinoxes, ±max at solstices. One full cycle per tilt_cycle_days.
func _get_tilt_angle() -> float:
	var cycle := tilt_cycle_days
	if cycle <= 0.0:
		cycle = 365.25  # default: synced to a real year

	# Days since Jan 1 of current year (approx — good enough for visuals).
	var day_of_year := _day_of_year()
	# Phase: day 0 = winter solstice-ish for northern hemisphere.
	# Shift by 80 to roughly align with March equinox.
	var phase := ((day_of_year + 80.0) / cycle) * TAU + _tilt_phase_offset

	return deg_to_rad(max_axial_tilt_deg) * sin(phase)


func _day_of_year() -> int:
	# Simple accumulation — cheap enough and only runs on ticks.
	var days := 0
	for m in range(1, TimeManager.current_month):
		days += _days_in_month(m, TimeManager.current_year)
	days += TimeManager.current_day - 1
	return days


func _days_in_month(month: int, year: int) -> int:
	match month:
		1, 3, 5, 7, 8, 10, 12: return 31
		4, 6, 9, 11: return 30
		2: return 29 if ((year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)) else 28
	return 30


## Recomputes cached sun/moon directions with axial tilt applied.
func _recompute_directions() -> void:
	var hour := TimeManager.current_time_hours
	var tilt := _get_tilt_angle()

	# Base arc: 6 AM = +X (East), 12 PM = +Y (up), 6 PM = -X (West), 12 AM = -Y.
	var base_angle := ((hour - 6.0) / 24.0) * TAU
	var base := Vector3(cos(base_angle), sin(base_angle), 0.0)

	# Apply tilt as a rotation around the X axis (East-West axis).
	# Positive tilt tilts the arc's apex toward +Z (north-ish).
	var tilted := base.rotated(Vector3.RIGHT, tilt)

	# Add a small per-day jitter so consecutive days aren't identical.
	# Deterministic per date so save/load looks the same.
	var jitter := _daily_jitter()
	tilted = tilted.rotated(Vector3.RIGHT, jitter)

	_sun_dir = tilted.normalized()
	_moon_dir = -_sun_dir
	_sun_elevation = _sun_dir.y


## Small deterministic per-day jitter in radians (±0.5°).
func _daily_jitter() -> float:
	var d := _day_of_year()
	var y := TimeManager.current_year
	# Cheap hash → [-1, 1]
	var h := fmod(sin(float(d) * 12.9898 + float(y) * 78.233) * 43758.5453, 1.0)
	return (h - 0.5) * deg_to_rad(1.0)


# ---------------------------------------------------------------------------
# Apply to scene
# ---------------------------------------------------------------------------

func _update_celestial_positions() -> void:
	if sun:
		# Basis.looking_at aligns -Z to the target vector.
		# Light shines TOWARD -sun_dir (since sun_dir is where it comes FROM).
		sun.global_transform.basis = Basis.looking_at(-_sun_dir, Vector3.UP)

	if moon:
		moon.global_transform.basis = Basis.looking_at(-_moon_dir, Vector3.UP)


func _update_light_properties() -> void:
	if not sun or not moon:
		return

	var hour := TimeManager.current_time_hours
	var elevation := _sun_elevation

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


func _update_sky_and_fog() -> void:
	if not _sky_mat or not _env:
		return

	var hour := TimeManager.current_time_hours
	var elevation := _sun_elevation

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
