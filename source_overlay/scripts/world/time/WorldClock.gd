extends Node
class_name WorldClock

signal minute_changed(day: int, hour: int, minute: int)
signal day_changed(day: int)
signal time_scale_changed(value: float)

@export var start_day := 1
@export_range(0, 23, 1) var start_hour := 8
@export_range(0, 59, 1) var start_minute := 0
@export var real_seconds_per_game_minute := 0.45

var total_minutes := 0.0
var time_scale := 1.0
var _last_emitted_minute := -1

func _ready() -> void:
    total_minutes = float((start_day - 1) * 1440 + start_hour * 60 + start_minute)
    _last_emitted_minute = int(floor(total_minutes))

func _process(delta: float) -> void:
    if real_seconds_per_game_minute <= 0.0:
        return
    var before_day := current_day()
    total_minutes += (delta / real_seconds_per_game_minute) * time_scale
    var whole := int(floor(total_minutes))
    if whole != _last_emitted_minute:
        _last_emitted_minute = whole
        minute_changed.emit(current_day(), current_hour(), current_minute())
        if current_day() != before_day:
            day_changed.emit(current_day())

func current_day() -> int:
    return int(floor(total_minutes / 1440.0)) + 1

func current_hour() -> int:
    return (int(floor(total_minutes)) / 60) % 24

func current_minute() -> int:
    return int(floor(total_minutes)) % 60

func formatted_time() -> String:
    return "اليوم %d — %02d:%02d" % [current_day(), current_hour(), current_minute()]

func skip_minutes(minutes: int) -> void:
    total_minutes += max(0, minutes)

func set_time_scale(value: float) -> void:
    time_scale = clampf(value, 0.0, 20.0)
    time_scale_changed.emit(time_scale)

func serialize() -> Dictionary:
    return {"total_minutes": total_minutes, "time_scale": time_scale}

func restore(data: Dictionary) -> void:
    var restored_minutes := float(data.get("total_minutes", total_minutes))
    if is_nan(restored_minutes) or is_inf(restored_minutes) or restored_minutes < 0.0:
        restored_minutes = float((start_day - 1) * 1440 + start_hour * 60 + start_minute)
    total_minutes = restored_minutes

    var restored_scale := float(data.get("time_scale", time_scale))
    if is_nan(restored_scale) or is_inf(restored_scale):
        restored_scale = 1.0
    time_scale = clampf(restored_scale, 0.0, 20.0)
    _last_emitted_minute = int(floor(total_minutes))
