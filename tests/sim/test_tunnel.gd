extends GutTest

const UP := 0
const RIGHT := 1
const DOWN := 2
const LEFT := 3

var sim: Simulation


func before_each() -> void:
	sim = Simulation.from_level(Registry.levels[&"r1_01"], Registry.buildings)
	sim.tracker = GoalTracker.new({5: 100} as Dictionary[int, int])


func test_tunnel_carries_number_under_crossing_conveyor() -> void:
	sim.ore[Vector2i(-6, 0)] = 5
	assert_true(sim.place(&"miner", Vector2i(-6, 0), RIGHT))
	assert_true(sim.place(&"tunnel_in", Vector2i(-5, 0), RIGHT))
	# Crossing belt sits directly in between the entrance and exit.
	assert_true(sim.place(&"conveyor", Vector2i(-3, 0), DOWN))
	assert_true(sim.place(&"tunnel_out", Vector2i(-1, 0), RIGHT))
	for _i in 60:
		sim.step()
	assert_gt(sim.tracker.received.get(5, 0), 0)
	assert_null(sim.building_at(Vector2i(-3, 0)).inputs[0], "crossing belt stays untouched")


func test_tunnel_respects_max_distance() -> void:
	sim.ore[Vector2i(-8, 0)] = 5
	assert_true(sim.place(&"miner", Vector2i(-8, 0), RIGHT))
	assert_true(sim.place(&"tunnel_in", Vector2i(-7, 0), RIGHT))
	# Distance 6 exceeds TunnelBehavior.MAX_DISTANCE (5).
	assert_true(sim.place(&"tunnel_out", Vector2i(-1, 0), RIGHT))
	for _i in 60:
		sim.step()
	assert_eq(sim.tracker.received.get(5, 0), 0)


func test_tunnel_ignores_mismatched_direction() -> void:
	sim.ore[Vector2i(-4, 0)] = 5
	assert_true(sim.place(&"miner", Vector2i(-4, 0), RIGHT))
	assert_true(sim.place(&"tunnel_in", Vector2i(-3, 0), RIGHT))
	assert_true(sim.place(&"tunnel_out", Vector2i(-1, 0), UP))
	for _i in 60:
		sim.step()
	assert_eq(sim.tracker.received.get(5, 0), 0)


func test_second_entrance_blocks_first_from_skipping_past_it() -> void:
	assert_true(sim.place(&"tunnel_in", Vector2i(-5, 0), RIGHT))
	assert_true(sim.place(&"tunnel_in", Vector2i(-3, 0), RIGHT))
	assert_true(sim.place(&"tunnel_out", Vector2i(-1, 0), RIGHT))
	var first := sim.building_at(Vector2i(-5, 0))
	var second := sim.building_at(Vector2i(-3, 0))
	var exit := sim.building_at(Vector2i(-1, 0))
	assert_null(TunnelBehavior.find_pair(sim, first.origin, first.front_side(), true))
	assert_eq(TunnelBehavior.find_pair(sim, second.origin, second.front_side(), true), exit)
	assert_eq(TunnelBehavior.find_pair(sim, exit.origin, exit.front_side(), false), second)
