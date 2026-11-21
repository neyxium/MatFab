extends GutTest

const UP := 0

var sim: Simulation


func before_each() -> void:
	sim = Simulation.from_level(Registry.levels[&"r1_01"], Registry.buildings)


func test_four_numbers_split_evenly_to_two_output_belts() -> void:
	assert_true(sim.place(&"splitter", Vector2i(-5, -5), UP))
	assert_true(sim.place(&"conveyor", Vector2i(-5, -6), UP))
	assert_true(sim.place(&"conveyor", Vector2i(-4, -6), UP))
	var left_belt := sim.building_at(Vector2i(-5, -6))
	var right_belt := sim.building_at(Vector2i(-4, -6))
	var left_count := 0
	var right_count := 0
	for n in 4:
		assert_true(sim.offer(Vector2i(-5, -4), UP, 7))
		for step in 5:
			sim.step()
		if left_belt.inputs[0] == 7:
			left_count += 1
			left_belt.inputs[0] = null
		if right_belt.inputs[0] == 7:
			right_count += 1
			right_belt.inputs[0] = null
	assert_eq(left_count, 2)
	assert_eq(right_count, 2)
