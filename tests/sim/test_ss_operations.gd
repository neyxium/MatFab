extends GutTest

# High-school operations: power, square root, factorial, gcd and lcm.

const UP := 0
const RIGHT := 1
const DOWN := 2

var sim: Simulation
var operations: Operations


# One miner on (-8, -2) feeds a one-input block above it; a conveyor line runs from the block to the mothership's top edge.
func build_line(block_id: StringName) -> void:
	sim.place(&"miner", Vector2i(-8, -2), UP)
	assert_true(sim.place(block_id, Vector2i(-8, -3), UP))
	build_conveyors_and_run()


# Two miners on (-8, -2) and (-7, -2) feed a two-input block above them; the left miner is the first input.
func build_two_input_line(block_id: StringName) -> void:
	sim.place(&"miner", Vector2i(-8, -2), UP)
	sim.place(&"miner", Vector2i(-7, -2), UP)
	assert_true(sim.place(block_id, Vector2i(-8, -3), UP))
	build_conveyors_and_run()


func build_conveyors_and_run() -> void:
	for x in range(-8, 0):
		sim.place(&"conveyor", Vector2i(x, -4), RIGHT)
	for y in range(-4, 0):
		sim.place(&"conveyor", Vector2i(0, y), DOWN)
	for i in 150:
		sim.step()


# Goals large enough that the tracker never completes and keeps recording everything it receives.
func before_each() -> void:
	sim = Simulation.from_level(Registry.levels[&"r1_01"], Registry.buildings)
	sim.tracker = GoalTracker.new({3: 1000, 4: 1000, 8: 1000} as Dictionary[int, int])
	operations = Operations.new()


func test_upper_bound_is_four_digits() -> void:
	assert_eq(Operations.MAX_VALUE, 9999)


func test_power() -> void:
	assert_eq(operations.power(2, 3), 8)
	assert_eq(operations.power(5, 1), 5)
	assert_eq(operations.power(1, 50), 1)
	assert_eq(operations.power(3, 8), 6561)
	assert_eq(operations.power(9999, 1), 9999)
	assert_null(operations.power(10, 4))
	assert_null(operations.power(10, 5))
	assert_null(operations.power(2, 63))


func test_square_root() -> void:
	assert_eq(operations.square_root(16), 4)
	assert_eq(operations.square_root(1), 1)
	assert_eq(operations.square_root(9801), 99)
	assert_null(operations.square_root(15))
	assert_null(operations.square_root(2))
	assert_null(operations.square_root(9999))


func test_factorial() -> void:
	assert_eq(operations.factorial(5), 120)
	assert_eq(operations.factorial(1), 1)
	assert_eq(operations.factorial(7), 5040)
	assert_null(operations.factorial(8))
	assert_null(operations.factorial(100))


func test_gcd() -> void:
	assert_eq(operations.gcd(12, 18), 6)
	assert_eq(operations.gcd(18, 12), 6)
	assert_eq(operations.gcd(7, 13), 1)
	assert_eq(operations.gcd(9, 9), 9)
	assert_eq(operations.gcd(1, 9999), 1)


func test_lcm() -> void:
	assert_eq(operations.lcm(4, 6), 12)
	assert_eq(operations.lcm(1, 9999), 9999)
	assert_eq(operations.lcm(5, 5), 5)
	assert_eq(operations.lcm(3, 7), 21)
	assert_null(operations.lcm(100, 101))


func test_no_operation_returns_zero_or_negative() -> void:
	for a in range(1, 13):
		for b in range(1, 13):
			for result in [operations.power(a, b), operations.gcd(a, b), operations.lcm(a, b)]:
				assert_true(result == null or (result >= 1 and result <= Operations.MAX_VALUE))
		for result in [operations.square_root(a), operations.factorial(a)]:
			assert_true(result == null or (result >= 1 and result <= Operations.MAX_VALUE))


func test_new_blocks_are_registered_as_processors() -> void:
	var inputs := {&"power": 2, &"square_root": 1, &"factorial": 1, &"gcd": 2, &"lcm": 2}
	for id in inputs:
		assert_true(Registry.buildings.has(id), "missing block %s" % id)
		var def: BuildingDef = Registry.buildings[id]
		assert_eq(def.behavior, BuildingDef.Behavior.PROCESSOR)
		assert_eq(def.inputs.size(), inputs[id])
		assert_eq(def.operation, id)
		assert_not_null(def.sprite)


func test_square_root_of_ore_16_feeds_4() -> void:
	sim.ore[Vector2i(-8, -2)] = 16
	build_line(&"square_root")
	assert_gt(sim.tracker.received.get(4, 0), 0)
	assert_eq(sim.tracker.received.keys(), [4])


func test_square_root_of_ore_15_feeds_nothing() -> void:
	sim.ore[Vector2i(-8, -2)] = 15
	build_line(&"square_root")
	assert_eq(sim.tracker.received.size(), 0)


func test_ore_2_to_the_power_of_ore_3_feeds_8() -> void:
	sim.ore[Vector2i(-8, -2)] = 2
	sim.ore[Vector2i(-7, -2)] = 3
	build_two_input_line(&"power")
	assert_gt(sim.tracker.received.get(8, 0), 0)
	assert_eq(sim.tracker.received.keys(), [8])


func test_power_above_the_bound_feeds_nothing() -> void:
	sim.ore[Vector2i(-8, -2)] = 10
	sim.ore[Vector2i(-7, -2)] = 5
	build_two_input_line(&"power")
	assert_eq(sim.tracker.received.size(), 0)
