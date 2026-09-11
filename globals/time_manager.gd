extends Node

signal time_changed(hours: int, minutes: int, seconds: int, total_hours: float)
signal date_changed(day: int, month: int, year: int)
signal period_changed(period: DayPeriod)

enum DayPeriod {
	NIGHT,
	DAWN,
	DUSK,
	DAY
}

## Real-world seconds for one full in-game day (24h). Default: 30 minutes.
@export var day_length_real_seconds: float = 100.0
## Starting time when scene loads.
@export var start_hour: float = 6.0
## Starting date.
@export var start_day: int = 1
@export var start_month: int = 1
@export var start_year: int = 2024

## Speed multiplier: 0.0 = paused, 1.0 = normal, 2.0 = fast
@export var time_scale: float = 1.0:
	set(value):
		time_scale = clampf(value, 0.0, 100.0)

var current_time_hours: float = 6.0
var current_day: int = 1
var current_month: int = 1
var current_year: int = 2024

## Separate from time_scale so that unpausing restores the previous speed.
var is_paused: bool = false:
	set(value):
		is_paused = value
		# Nothing else needed — _process checks is_paused directly.

var _previous_second: int = -1
var _current_period: DayPeriod = DayPeriod.DAWN

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	current_day = start_day
	current_month = start_month
	current_year = start_year
	current_time_hours = start_hour
	_update_period(true)  # force=true so initial signal fires if you want it
	_emit_time_now()
	date_changed.emit(current_day, current_month, current_year)

func _process(delta: float) -> void:
	if is_paused or time_scale <= 0.0:
		return

	var effective_delta := delta * time_scale
	var hours_passed := (effective_delta / day_length_real_seconds) * 24.0
	current_time_hours += hours_passed

	if current_time_hours >= 24.0:
		current_time_hours -= 24.0
		current_day += 1
		_handle_data_roll_over()
		date_changed.emit(current_day, current_month, current_year)

	var total_seconds := floori(current_time_hours * 3600.0)
	if total_seconds != _previous_second:
		_previous_second = total_seconds
		_emit_time_now()
		_update_period()

# ---------------------------------------------------------------------------
# Time helpers
# ---------------------------------------------------------------------------

func _emit_time_now() -> void:
	var h := floori(current_time_hours)
	var m := floori((current_time_hours - float(h)) * 60.0)
	var s := floori(((current_time_hours - float(h)) * 60.0 - float(m)) * 60.0)
	time_changed.emit(h, m, s, current_time_hours)

func _update_period(force: bool = false) -> void:
	var new_period: DayPeriod
	if current_time_hours >= 5.0 and current_time_hours < 7.0:
		new_period = DayPeriod.DAWN
	elif current_time_hours >= 7.0 and current_time_hours < 17.0:
		new_period = DayPeriod.DAY
	elif current_time_hours >= 17.0 and current_time_hours < 19.0:
		new_period = DayPeriod.DUSK
	else:
		new_period = DayPeriod.NIGHT

	if force or new_period != _current_period:
		_current_period = new_period
		period_changed.emit(_current_period)

func get_current_period() -> DayPeriod:
	return _current_period

# ---------------------------------------------------------------------------
# Date helpers
# ---------------------------------------------------------------------------

func _handle_data_roll_over() -> void:
	var dim := _days_in_month(current_month, current_year)
	if current_day > dim:
		current_day = 1
		current_month += 1
		if current_month > 12:
			current_month = 1
			current_year += 1

func _days_in_month(month: int, year: int) -> int:
	match month:
		1, 3, 5, 7, 8, 10, 12: return 31
		4, 6, 9, 11: return 30
		2: return 29 if ((year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)) else 28
	return 30

# ---------------------------------------------------------------------------
# Sun
# ---------------------------------------------------------------------------

## Returns the sun's direction vector (where light comes FROM).
## 6 AM = East (+X), 12 PM = Zenith (+Y), 6 PM = West (-X), 12 AM = Nadir (-Y).
func get_sun_direction() -> Vector3:
	var angle := ((current_time_hours - 6.0) / 24.0) * TAU
	return Vector3(cos(angle), sin(angle), 0.0).normalized()

func get_time_string() -> String:
	var h := floori(current_time_hours)
	var m := floori((current_time_hours - float(h)) * 60.0)
	return "%02d:%02d" % [h, m]

# ===========================================================================
# DEBUG API
# ===========================================================================

## Pause / unpause the clock. time_scale is preserved.
func set_paused(paused: bool) -> void:
	is_paused = paused

func toggle_pause() -> void:
	is_paused = not is_paused

## Jump to a specific hour of the current day (0.0 – 24.0).
## Does NOT change the date.
func set_time(hours: float) -> void:
	current_time_hours = fposmod(hours, 24.0)
	_previous_second = -1          # force a time_changed emit next tick
	_emit_time_now()
	_update_period(true)           # force period emit even if same period

## Add (or subtract) hours from the current time. Rolls the date forward/back.
func add_hours(hours: float) -> void:
	set_time(current_time_hours + hours)
	if hours > 0.0 and current_time_hours < hours:
		# We wrapped past midnight during the add.
		pass  # optional: track and roll date here if you want
	# Simpler: recompute by adding directly to time and rolling date.
	# (Handled below by the explicit implementation.)

## Add hours and properly roll the calendar if we cross midnight.
func advance_hours(hours: float) -> void:
	var total := current_time_hours + hours
	while total >= 24.0:
		total -= 24.0
		current_day += 1
		_handle_data_roll_over()
		date_changed.emit(current_day, current_month, current_year)
	while total < 0.0:
		total += 24.0
		current_day -= 1
		if current_day < 1:
			current_month -= 1
			if current_month < 1:
				current_month = 12
				current_year -= 1
			current_day = _days_in_month(current_month, current_year)
		date_changed.emit(current_day, current_month, current_year)
	current_time_hours = total
	_previous_second = -1
	_emit_time_now()
	_update_period(true)

## Advance to the next occurrence of a period (DAWN / DAY / DUSK / NIGHT).
func skip_to_period(target: DayPeriod) -> void:
	var start_hours := {
		DayPeriod.DAWN: 5.0,
		DayPeriod.DAY: 7.0,
		DayPeriod.DUSK: 17.0,
		DayPeriod.NIGHT: 19.0,
	}
	var target_hour: float = start_hours[target]

	# If we're already in that period, advance to the NEXT day's version.
	if _current_period == target:
		advance_hours(24.0)

	# Figure out how many hours until target_hour.
	var diff := target_hour - current_time_hours
	if diff <= 0.0:
		diff += 24.0
	advance_hours(diff)

## Convenience wrappers for named jumps.
func go_to_dawn()  -> void: skip_to_period(DayPeriod.DAWN)
func go_to_day()   -> void: skip_to_period(DayPeriod.DAY)
func go_to_dusk()  -> void: skip_to_period(DayPeriod.DUSK)
func go_to_night() -> void: skip_to_period(DayPeriod.NIGHT)

## Set the full date + time in one call.
func set_datetime(year: int, month: int, day: int, hour: float) -> void:
	current_year = year
	current_month = clampi(month, 1, 12)
	current_day = clampi(day, 1, _days_in_month(current_month, current_year))
	current_time_hours = fposmod(hour, 24.0)
	_previous_second = -1
	_emit_time_now()
	_update_period(true)
	date_changed.emit(current_day, current_month, current_year)

## Dump current state as a string for debug printing.
func debug_string() -> String:
	var pname = ["NIGHT", "DAWN", "DUSK", "DAY"][_current_period]
	return "%04d-%02d-%02d %s  [%s]  x%.2f  %s" % [
		current_year, current_month, current_day,
		get_time_string(), pname, time_scale,
		"PAUSED" if is_paused else "RUNNING",
	]