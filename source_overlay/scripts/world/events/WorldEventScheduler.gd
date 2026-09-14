extends Node
class_name WorldEventScheduler

signal event_started(id: String, label_ar: String)
signal event_ended(id: String)

const CONFIG_PATH := "res://data/events/world_events.json"

var clock: WorldClock
var configs: Dictionary = {}
var next_trigger: Dictionary = {}
var active_until: Dictionary = {}
var rng := RandomNumberGenerator.new()

func _ready() -> void:
    rng.randomize()
    _load_config()

func configure(c: WorldClock) -> void:
    clock = c
    _schedule_all()

func _process(_delta: float) -> void:
    if clock == null:
        return
    var now := int(floor(clock.total_minutes))

    for id in active_until.keys().duplicate():
        if now >= int(active_until[id]):
            active_until.erase(id)
            event_ended.emit(str(id))
            _schedule_one(str(id), now)

    for id in next_trigger.keys().duplicate():
        if active_until.has(id):
            continue
        if now >= int(next_trigger[id]):
            var cfg: Dictionary = configs.get(id, {})
            active_until[id] = now + int(cfg.get("duration_minutes", 60))
            next_trigger.erase(id)
            event_started.emit(str(id), str(cfg.get("label_ar", id)))

func is_active(id: String) -> bool:
    return active_until.has(id)

func remaining_minutes(id: String) -> int:
    if clock == null or not active_until.has(id):
        return 0
    return maxi(0, int(active_until[id]) - int(floor(clock.total_minutes)))

func serialize() -> Dictionary:
    return {"next_trigger": next_trigger.duplicate(true), "active_until": active_until.duplicate(true)}

func restore(data: Dictionary) -> void:
    var nt = data.get("next_trigger", {})
    var au = data.get("active_until", {})
    next_trigger = _sanitize_schedule(nt)
    active_until = _sanitize_schedule(au)

func _sanitize_schedule(value) -> Dictionary:
    var sanitized := {}
    if typeof(value) != TYPE_DICTIONARY:
        return sanitized
    for raw_id in value.keys():
        var id := str(raw_id)
        if not configs.has(id):
            continue
        var minute_value := float(value[raw_id])
        if is_nan(minute_value) or is_inf(minute_value) or minute_value < 0.0:
            continue
        sanitized[id] = int(minute_value)
    return sanitized

func _load_config() -> void:
    if not FileAccess.file_exists(CONFIG_PATH):
        return
    var f := FileAccess.open(CONFIG_PATH, FileAccess.READ)
    if f == null:
        return
    var parsed = JSON.parse_string(f.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        return
    for entry in parsed.get("events", []):
        if typeof(entry) == TYPE_DICTIONARY:
            configs[str(entry.get("id",""))] = entry

func _schedule_all() -> void:
    if clock == null:
        return
    var now := int(floor(clock.total_minutes))
    for id in configs.keys():
        if not next_trigger.has(id) and not active_until.has(id):
            _schedule_one(str(id), now)

func _schedule_one(id: String, now: int) -> void:
    var cfg: Dictionary = configs.get(id, {})
    var lo := int(cfg.get("min_interval_minutes", 180))
    var hi := maxi(lo, int(cfg.get("max_interval_minutes", lo + 60)))
    next_trigger[id] = now + rng.randi_range(lo, hi)
