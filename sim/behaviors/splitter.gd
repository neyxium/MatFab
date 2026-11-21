class_name SplitterBehavior extends Behavior


func tick(building: BuildingState) -> void:
	if building.inputs.is_empty() or building.inputs[0] == null:
		return
	building.timer += 1
	if building.timer < building.duration_ticks():
		return
	var def := building.def
	var count := def.outputs.size()
	if count == 0:
		return
	for offset in count:
		var index := (building.next_output + offset) % count
		var port := def.outputs[index]
		if sim().offer(Ports.world_cell(building, port), Ports.world_side(building, port), building.inputs[0]):
			building.inputs[0] = null
			building.timer = 0
			building.next_output = (index + 1) % count
			return


func accept(building: BuildingState, cell: Vector2i, side: int, number: int) -> bool:
	var def := building.def
	for i in def.inputs.size():
		var port := def.inputs[i]
		if port.source == PortDef.Source.NEIGHBOR and building.inputs[i] == null \
				and Ports.world_cell(building, port) == cell and Ports.world_side(building, port) == side:
			building.inputs[i] = number
			building.timer = sim().arrival_timer(building)
			return true
	return false
