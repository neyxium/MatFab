class_name TunnelBehavior extends Behavior

# Maximum cell distance from a tunnel entrance to its matching exit (up to 4 cells of gap between them).
const MAX_DISTANCE := 5


func tick(building: BuildingState) -> void:
	if building.def.behavior == BuildingDef.Behavior.TUNNEL_IN:
		_tick_in(building)
	else:
		_tick_out(building)


func _tick_in(building: BuildingState) -> void:
	if building.inputs[0] == null:
		return
	building.timer += 1
	if building.timer < building.duration_ticks():
		return
	var exit := find_pair(sim(), building.origin, building.front_side(), true)
	if exit == null or exit.outputs[0] != null:
		return
	exit.outputs[0] = building.inputs[0]
	exit.timer = sim().arrival_timer(exit)
	building.inputs[0] = null
	building.timer = 0


func _tick_out(building: BuildingState) -> void:
	if building.outputs[0] == null:
		return
	building.timer += 1
	if building.timer >= building.duration_ticks() and sim().offer(building.origin, building.front_side(), building.outputs[0]):
		building.outputs[0] = null
		building.timer = 0


func accept(building: BuildingState, _cell: Vector2i, side: int, number: int) -> bool:
	if building.def.behavior != BuildingDef.Behavior.TUNNEL_IN:
		return false
	if building.inputs[0] != null or side != Ports.opposite_side(building.front_side()):
		return false
	building.inputs[0] = number
	building.timer = sim().arrival_timer(building)
	return true


# Finds the matching partner tunnel along `front_side` (forward for TUNNEL_IN, backward for TUNNEL_OUT).
static func find_pair(simulation: Simulation, origin: Vector2i, front_side: int, is_in: bool) -> BuildingState:
	var step := Ports.direction(front_side) * (1 if is_in else -1)
	var target_behavior := BuildingDef.Behavior.TUNNEL_OUT if is_in else BuildingDef.Behavior.TUNNEL_IN
	var blocker_behavior := BuildingDef.Behavior.TUNNEL_IN if is_in else BuildingDef.Behavior.TUNNEL_OUT
	for dist in range(1, MAX_DISTANCE + 1):
		var other := simulation.building_at(origin + step * dist)
		if other == null or other.front_side() != front_side:
			continue
		if other.def.behavior == target_behavior:
			return other
		if other.def.behavior == blocker_behavior:
			return null
	return null
