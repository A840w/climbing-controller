extends Node

signal time_changed(hours: int,minutes: int, seconds: int, total_hours: float)
signal date_changed(day:int, month:int, year:int)
signal period_changed(period: DayPeriod)

enum DayPeriod{
	NIGHT,
	DAWN,
	DUSK,
	DAY
}

## Real-world seconds for one full in-game day (24h). Default: 10 minutes.
@export var day_length_real_seconds: float = 600.0
## Starting time when scene loads.
@export var start_hour: float = 6.0
## Starting date.
@export var start_day: int = 1
@export var start_month: int = 1
@export var start_year: int = 2024

## speed multipler 0.0 = paused , 1.0 = normal, 2.0 = fast 
@export var time_scale: float = 1.0:
	set(value):
		time_scale = clampf(value, 0.0, 100.0)

var current_time_hours: float = 6.0
var current_day: int = 1
var current_month: int = 1
var current_year: int = 2024
var is_paused: bool = false


var _previous_second: int = -1
var _current_period: DayPeriod = DayPeriod.DAWN


func _ready() -> void:
	current_day = start_day
	current_month = start_month
	current_year = start_year
	current_time_hours = start_hour
	_update_period()

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
		date_changed.emit(current_day,current_month,current_year)

	var total_seconds := floori(current_time_hours * 3600.0)
	if total_seconds != _previous_second:
		_previous_second = total_seconds
		var h := floori(current_time_hours)
		var m := floori((current_time_hours - h) * 60.0)
		var s := floori(((current_time_hours - h) *60.0 - m ) * 60.0)
		time_changed.emit(h, m, s, current_time_hours)
		_update_period()




func _update_period() -> void:
	var new_period : DayPeriod
	if current_time_hours >= 5.0 and current_time_hours <= 7.0:
		new_period = DayPeriod.DAWN
	elif  current_time_hours >= 7.0 and current_time_hours <= 17.0:
		new_period = DayPeriod.DAY
	elif current_time_hours >= 17.0 and current_time_hours <= 19.0:
		new_period = DayPeriod.DUSK
	else:
		new_period = DayPeriod.NIGHT

func _handle_data_roll_over() -> void:
	var dim :=_days_in_month(current_month, current_year) 
	if current_day > dim :
		current_day = 1
		current_month += 1
		if current_month > 12:
			current_month = 1
			current_year +=1

func _days_in_month(month: int, year: int) -> int :
	match month:
		1, 3, 5, 7, 8, 10, 12: return 31
		4, 6, 9, 11: return 30
		2: return 29 if ((year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)) else 28
	return 30


## Returns the sun's direction vector (where light comes FROM).
## 6 AM = East (+X), 12 PM = Zenith (+Y), 6 PM = West (-X), 12 AM = Nadir (-Y).
func get_sun_direction() -> Vector3:
	var angle := ((current_time_hours - 6.0) / 24.0) * TAU
	return Vector3(cos(angle), sin(angle), 0.0).normalized()

func get_time_string() -> String:
	var h := floori(current_time_hours)
	var m := floori((current_time_hours - float(h)) * 60.0)
	return "%02d:%02d" % [h, m]
