extends Node

func _ready() -> void:
    var coordinator := TrafficCoordinator.new()
    coordinator.name = "IntersectionCoordinatorUnderTest"
    add_child(coordinator)
    coordinator.intersections = [Vector3.ZERO]
    coordinator.intersection_radius = 5.0
    coordinator.intersection_clearance_margin = 2.5
    coordinator.signal_phase_seconds = 14.0
    coordinator.signal_yellow_seconds = 2.5
    coordinator.signal_all_red_seconds = 1.5

    var east_vehicle := Node3D.new()
    east_vehicle.name = "EastboundVehicle"
    east_vehicle.position = Vector3(-6.0, 0.0, 0.0)
    add_child(east_vehicle)
    coordinator.register_vehicle(east_vehicle)

    var north_vehicle := Node3D.new()
    north_vehicle.name = "NorthboundVehicle"
    north_vehicle.position = Vector3(0.0, 0.0, -6.0)
    add_child(north_vehicle)
    coordinator.register_vehicle(north_vehicle)

    # Axis 0 green: east/west vehicle may reserve, conflicting north/south may not.
    coordinator.signal_elapsed = 0.0
    if not coordinator.signal_allows_approach(0, Vector3.RIGHT):
        _fail("BOURGUIBA_INTERSECTION_GREEN_AXIS_INVALID")
        return
    if coordinator.signal_allows_approach(0, Vector3.FORWARD):
        _fail("BOURGUIBA_INTERSECTION_RED_AXIS_INVALID")
        return
    if not coordinator.request_intersection(east_vehicle, 0, Vector3.RIGHT):
        _fail("BOURGUIBA_INTERSECTION_RESERVATION_INVALID")
        return
    if coordinator.request_intersection(north_vehicle, 0, Vector3.FORWARD):
        _fail("BOURGUIBA_INTERSECTION_CONFLICT_EXCLUSION_INVALID")
        return

    # Pedestrians only cross on their green axis and never against a conflicting reservation.
    if not coordinator.pedestrian_allows_crossing(0, Vector3.RIGHT):
        _fail("BOURGUIBA_INTERSECTION_PEDESTRIAN_GREEN_INVALID")
        return
    if coordinator.pedestrian_allows_crossing(0, Vector3.FORWARD):
        _fail("BOURGUIBA_INTERSECTION_PEDESTRIAN_RED_INVALID")
        return

    # A committed vehicle remains owner while inside, then explicitly releases after clearance.
    east_vehicle.position = Vector3.ZERO
    if not coordinator.vehicle_inside_intersection(east_vehicle, 0):
        _fail("BOURGUIBA_INTERSECTION_INSIDE_INVALID")
        return
    if coordinator.vehicle_has_cleared_intersection(east_vehicle, 0):
        _fail("BOURGUIBA_INTERSECTION_PREMATURE_CLEAR_INVALID")
        return
    east_vehicle.position = Vector3(8.0, 0.0, 0.0)
    if not coordinator.vehicle_has_cleared_intersection(east_vehicle, 0):
        _fail("BOURGUIBA_INTERSECTION_CLEARANCE_INVALID")
        return
    coordinator.release_intersection(east_vehicle, 0)
    if coordinator.reservations.has(0):
        _fail("BOURGUIBA_INTERSECTION_RELEASE_INVALID")
        return

    # Axis 1 green after one phase: north/south vehicle becomes eligible.
    coordinator.signal_elapsed = coordinator.signal_phase_seconds
    if not coordinator.request_intersection(north_vehicle, 0, Vector3.FORWARD):
        _fail("BOURGUIBA_INTERSECTION_PHASE_SWITCH_INVALID")
        return

    # Front-gap safety must reject a vehicle directly ahead inside configured minimum gap.
    coordinator.release_intersection(north_vehicle, 0)
    east_vehicle.position = Vector3.ZERO
    north_vehicle.position = Vector3(0.0, 0.0, -3.0)
    if coordinator.has_front_gap(east_vehicle, Vector3(0.0, 0.0, -1.0)):
        _fail("BOURGUIBA_INTERSECTION_FRONT_GAP_INVALID")
        return
    north_vehicle.position = Vector3(0.0, 0.0, -12.0)
    if not coordinator.has_front_gap(east_vehicle, Vector3(0.0, 0.0, -1.0)):
        _fail("BOURGUIBA_INTERSECTION_FRONT_GAP_CLEAR_INVALID")
        return

    # All-red must reject both vehicle approaches and pedestrian crossing.
    coordinator.signal_elapsed = coordinator.signal_phase_seconds - 0.5
    if coordinator.current_green_axis() != -1:
        _fail("BOURGUIBA_INTERSECTION_ALL_RED_STATE_INVALID")
        return
    if coordinator.signal_allows_approach(0, Vector3.RIGHT):
        _fail("BOURGUIBA_INTERSECTION_ALL_RED_VEHICLE_INVALID")
        return
    if coordinator.pedestrian_allows_crossing(0, Vector3.RIGHT):
        _fail("BOURGUIBA_INTERSECTION_ALL_RED_PEDESTRIAN_INVALID")
        return

    print("BOURGUIBA_INTERSECTION_SAFETY_GATE_PASS")
    get_tree().quit(0)

func _fail(message: String) -> void:
    push_error(message)
    print(message)
    get_tree().quit(1)
