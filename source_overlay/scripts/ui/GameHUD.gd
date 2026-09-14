extends CanvasLayer
class_name GameHUD

var world_clock: WorldClock
var dynamic_objective_text := ""
var player: PlayerController

@onready var stats: Label = $Margin/VBox/Stats
@onready var objective: Label = $Objective
@onready var prompt: Label = $Prompt
@onready var blackout: ColorRect = $Blackout

func _ready() -> void:
    GameState.stat_changed.connect(_refresh)
    GameState.money_changed.connect(_refresh_money)
    GameState.blackout_changed.connect(_on_blackout)
    _refresh("", 0.0)
    _on_blackout(GameState.blackout_active)

func bind_dynamic_objectives(manager: DynamicObjectiveManager) -> void:
    if manager == null:
        push_warning("HUD_BIND: DynamicObjectiveManager unavailable; dynamic objective text disabled")
        return
    if not manager.dynamic_objective_changed.is_connected(_on_dynamic_objective_changed):
        manager.dynamic_objective_changed.connect(_on_dynamic_objective_changed)

func _on_dynamic_objective_changed(text: String) -> void:
    dynamic_objective_text = text

func bind_clock(clock: WorldClock) -> void:
    world_clock = clock

func bind_player(value: PlayerController) -> void:
    player = value
    player.interaction_target_changed.connect(_on_target_changed)

func bind_missions(manager: MissionManager) -> void:
    manager.objective_text_changed.connect(_on_objective_changed)

func _process(_delta: float) -> void:
    _refresh_stats()

func _refresh_stats() -> void:
    var time_text := world_clock.formatted_time() if world_clock else ""
    var shortages := ""
    if GameState.water_shortage:
        shortages += "\nالماء المعدني: مقطوع"
    if GameState.fuel_shortage:
        shortages += "\nالإيصنص: ناقص"
    stats.text = "%s\nالفلوس: %.1f د.ت\nالماء: %d%%   الطاقة: %d%%\nالإيصنص: %d%%   المزاج: %d%%%s" % [
        time_text, GameState.money, int(GameState.water), int(GameState.energy), int(GameState.fuel), int(GameState.mood), shortages
    ]

func _refresh(_name: String, _value: float) -> void:
    _refresh_stats()

func _refresh_money(_value: float) -> void:
    _refresh_stats()

func _on_target_changed(target: Interactable) -> void:
    prompt.text = "" if target == null else "E — " + target.prompt_ar

func _on_objective_changed(text: String) -> void:
    objective.text = "المهمة: " + text + ("\n" + dynamic_objective_text if not dynamic_objective_text.is_empty() else "")

func _on_blackout(active: bool) -> void:
    blackout.color = Color(0,0,0,0.38 if active else 0.0)

func current_interaction_prompt() -> String:
    if player == null or player.interaction_target == null:
        return ""
    if not player.interaction_target.can_interact(player):
        return ""
    return str(player.interaction_target.prompt_ar)
