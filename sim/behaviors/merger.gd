class_name MergerBehavior extends Behavior


func tick(building: BuildingState) -> void:
	if building.inputs.count(null) == building.inputs.size():
		return
	building.timer += 1
	if building.timer < building.duration_ticks():
		return
	var def := building.def
	if def.outputs.is_empty():
		return
	var out_port := def.outputs[0]
	var count := def.inputs.size()
	for offset in count:
		var index := (building.next_output + offset) % count
		var number: Variant = building.inputs[index]
		if number != null:
			if sim().offer(Ports.world_cell(building, out_port), Ports.world_side(building, out_port), number):
				building.inputs[index] = null
				building.timer = 0
				building.next_output = (index + 1) % count
			return


func accept(building: BuildingState, cell: Vector2i, side: int, number: int) -> bool:
	var def := building.def
	var was_empty := building.inputs.count(null) == building.inputs.size()
	for i in def.inputs.size():
		var port := def.inputs[i]
		if port.source == PortDef.Source.NEIGHBOR and building.inputs[i] == null \
				and Ports.world_cell(building, port) == cell and Ports.world_side(building, port) == side:
			building.inputs[i] = number
			if was_empty:
				building.timer = sim().arrival_timer(building)
			return true
	return false
