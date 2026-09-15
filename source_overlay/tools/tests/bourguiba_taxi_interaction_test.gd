extends Node

var game_state: Node

func _ready() -> void:
    call_deferred("_run_gate")

func _fail(message: String, code: int) -> void:
    push_error(message)
    get_tree().quit(code)

func _run_gate() -> void:
    game_state = get_node_or_null("/root/GameState")
    if game_state == null:
        _fail("BOURGUIBA_TAXI_GAME_STATE_AUTOLOAD_INVALID", 79)
        return

    var world := Node3D.new()
    world.name = "BourguibaTaxiInteractionGateWorld"
    add_child(world)

    var taxi := ArcadeVehicle.new()
    taxi.name = "MissionTaxi"
    taxi.vehicle_id = "taxi_01"
    var seat := Marker3D.new()
    seat.name = "DriverSeat"
    taxi.add_child(seat)
    var exit_point := Marker3D.new()
    exit_point.name = "ExitPoint"
    taxi.add_child(exit_point)
    world.add_child(taxi)

    var player := PlayerController.new()
    player.name = "Player"
    world.add_child(player)

    taxi.enter_vehicle(player)
    if taxi.driver != player or game_state.current_vehicle_id != "taxi_01" or player.visible:
        _fail("BOURGUIBA_TAXI_ENTER_INTERACTION_INVALID", 80)
        return

    taxi.speed = 2.0
    taxi.exit_vehicle()
    if taxi.driver != player:
        _fail("BOURGUIBA_TAXI_MOVING_EXIT_SAFETY_INVALID", 81)
        return

    taxi.speed = 0.0
    taxi.exit_vehicle()
    if taxi.driver != null or not game_state.current_vehicle_id.is_empty() or not player.visible:
        _fail("BOURGUIBA_TAXI_STOPPED_EXIT_INVALID", 82)
        return

    var passenger := Node3D.new()
    passenger.name = "Passenger"
    world.add_child(passenger)
    var pickup := Node3D.new()
    pickup.name = "Pickup"
    pickup.position = Vector3(4.0, 0.0, 0.0)
    world.add_child(pickup)
    var dropoff := Node3D.new()
    dropoff.name = "Dropoff"
    dropoff.position = Vector3(24.0, 0.0, 0.0)
    world.add_child(dropoff)

    var fare := TaxiFareDirector.new()
    fare.name = "TaxiFareDirector"
    world.add_child(fare)
    fare.configure(taxi, passenger, pickup, dropoff, player)

    game_state.fuel = 50.0
    fare.activate()
    if fare.stage != "pickup":
        _fail("BOURGUIBA_TAXI_FARE_ACTIVATION_INVALID:%s" % fare.stage, 83)
        return

    taxi.enter_vehicle(player)
    taxi.global_position = pickup.global_position
    taxi.speed = 2.0
    fare._process(0.1)
    if fare.stage != "pickup":
        _fail("BOURGUIBA_TAXI_PICKUP_MOVING_SAFETY_INVALID:%s" % fare.stage, 84)
        return

    taxi.speed = 0.0
    fare._process(0.1)
    if fare.stage != "dropoff" or passenger.visible:
        _fail("BOURGUIBA_TAXI_PICKUP_INTERACTION_INVALID:%s" % fare.stage, 85)
        return

    taxi.global_position = dropoff.global_position
    taxi.speed = 2.0
    fare._process(0.1)
    if fare.stage != "dropoff":
        _fail("BOURGUIBA_TAXI_DROPOFF_MOVING_SAFETY_INVALID:%s" % fare.stage, 86)
        return

    var money_before: float = game_state.money
    taxi.speed = 0.0
    fare._process(0.1)
    if fare.stage != "complete" or game_state.money <= money_before or not passenger.visible:
        _fail("BOURGUIBA_TAXI_DROPOFF_INTERACTION_INVALID stage=%s money_before=%.2f money_after=%.2f" % [fare.stage, money_before, game_state.money], 87)
        return

    print("BOURGUIBA_TAXI_INTERACTION_GATE_PASS vehicle=%s stage=%s fare_delta=%.2f" % [taxi.vehicle_id, fare.stage, game_state.money - money_before])
    get_tree().quit(0)
