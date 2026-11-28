extends GutTest

var operations: Operations


func before_each() -> void:
	operations = Operations.new()


func test_basic_operations_with_negative_and_zero() -> void:
	assert_eq(operations.sum(-5, 3), -2)
	assert_eq(operations.sum(-5, 5), 0)
	assert_eq(operations.subtract(2, 7), -5)
	assert_eq(operations.subtract(-3, -3), 0)
	assert_eq(operations.multiply(-4, 3), -12)
	assert_eq(operations.multiply(-4, -3), 12)
	assert_eq(operations.multiply(-4, 0), 0)
	assert_eq(operations.divide(-12, 3), -4)
	assert_eq(operations.divide(-12, -3), 4)
	assert_eq(operations.divide(0, -5), 0)
	assert_null(operations.divide(-5, 0))
	assert_eq(operations.square(-5), 25)
	assert_eq(operations.cube(-3), -27)


func test_value_bounds_reject_overflow_in_both_directions() -> void:
	assert_eq(operations.subtract(0, 9999), -9999)
	assert_null(operations.subtract(-9999, 1))
	assert_null(operations.sum(9999, 1))
	assert_null(operations.multiply(-100, 100))
	assert_null(operations.square(-100))
	assert_null(operations.cube(-22))


func test_advanced_operations_with_negative_and_zero() -> void:
	assert_eq(operations.power(-2, 3), -8)
	assert_eq(operations.power(-2, 2), 4)
	assert_eq(operations.power(-3, 0), 1)
	assert_eq(operations.power(0, 3), 0)
	assert_null(operations.power(0, 0))
	assert_null(operations.power(2, -1))
	assert_null(operations.power(-10, 5))
	assert_eq(operations.square_root(0), 0)
	assert_null(operations.square_root(-4))
	assert_eq(operations.factorial(0), 1)
	assert_null(operations.factorial(-3))
	assert_eq(operations.gcd(-12, 18), 6)
	assert_eq(operations.gcd(-12, -18), 6)
	assert_eq(operations.gcd(0, -5), 5)
	assert_null(operations.gcd(0, 0))
	assert_eq(operations.lcm(-4, 6), 12)
	assert_null(operations.lcm(0, 5))


func test_goal_tracker_handles_negative_one_goal() -> void:
	var tracker := GoalTracker.new({-1: 2, -5: 1} as Dictionary[int, int])
	assert_false(tracker.is_complete())
	assert_eq(tracker.current_goal(), -1)
	tracker.receive(-1)
	assert_false(tracker.is_complete())
	assert_eq(tracker.progress(-1), 1)
	tracker.receive(-1)
	assert_false(tracker.is_complete())
	assert_eq(tracker.current_goal(), -5)
	tracker.receive(-5)
	assert_true(tracker.is_complete())
