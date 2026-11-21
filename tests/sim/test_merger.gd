extends GutTest

const UP := 0

var sim: Simulation


func before_each() -> void:
	sim = Simulation.from_level(Registry.levels[&"r1_01"], Registry.buildings)


func test_two_input_belts_merge_alternating_into_one_output_belt() -> void:
	assert_true(sim.place(&"merger", Vector2i(-5, -5), UP))
	assert_true(sim.place(&"conveyor", Vector2i(-5, -6), UP))
	var out_belt := sim.building_at(Vector2i(-5, -6))
	var received: Array[int] = []
	for n in 2:
		assert_true(sim.offer(Vector2i(-5, -4), UP, 3))
		assert_true(sim.offer(Vector2i(-4, -4), UP, 5))
		for cycle in 2:
			for step in 5:
				sim.step()
			if out_belt.inputs[0] != null:
				received.append(out_belt.inputs[0])
				out_belt.inputs[0] = null
	assert_eq(received, [3, 5, 3, 5] as Array[int])
