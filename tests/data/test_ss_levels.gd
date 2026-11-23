extends GutTest

# High-school levels ss_01..ss_05: they load, sit in grade 10 and every goal can be built from the level's ores and blocks.

const LEVEL_IDS: Array[StringName] = [&"ss_01", &"ss_02", &"ss_03", &"ss_04", &"ss_05"]
# Blocks that only move or mine numbers; the reachability search skips them.
const NON_MATH_BLOCKS: Array[StringName] = [&"conveyor", &"miner", &"splitter", &"merger"]
const MAX_STEPS := 3
const MAX_BUILDABLE := 10

var operations := Operations.new()


func ore_values(level: LevelDef) -> Array[int]:
	var values: Array[int] = []
	for patch in level.ore_patches:
		values.append(patch.value)
	return values


func math_blocks(level: LevelDef) -> Array[BuildingDef]:
	var blocks: Array[BuildingDef] = []
	for def in level.buildable:
		if def.id not in NON_MATH_BLOCKS:
			blocks.append(def)
	return blocks


func add_result(result: Variant, found: Dictionary) -> void:
	if result != null and int(result) >= 1 and int(result) <= Operations.MAX_VALUE:
		found[int(result)] = true


# Starts from the ore values and applies every math block to every (ordered) combination of numbers found so far.
func reachable_values(level: LevelDef) -> Dictionary:
	var found := {}
	for value in ore_values(level):
		found[value] = true
	var blocks := math_blocks(level)
	for _step in MAX_STEPS:
		var current: Array = found.keys()
		for def in blocks:
			if def.inputs.size() == 1:
				for a in current:
					add_result(operations.call(def.operation, a), found)
			else:
				for a in current:
					for b in current:
						add_result(operations.call(def.operation, a, b), found)
	return found


func test_ss_levels_load_through_the_registry_in_grade_10() -> void:
	for id in LEVEL_IDS:
		assert_true(Registry.levels.has(id), "missing level %s" % id)
		assert_eq(Registry.levels[id].grade, 10, "level %s" % id)


func test_no_goal_equals_an_ore_value() -> void:
	for id in LEVEL_IDS:
		var level: LevelDef = Registry.levels[id]
		var ores := ore_values(level)
		for goal in level.goals:
			assert_false(goal in ores, "level %s: goal %d is an ore" % [id, goal])


func test_every_math_block_has_an_operation() -> void:
	for id in LEVEL_IDS:
		var blocks := math_blocks(Registry.levels[id])
		assert_gt(blocks.size(), 0, "level %s has no math blocks" % id)
		for def in blocks:
			assert_true(operations.has_method(def.operation), "level %s: block %s" % [id, def.id])


func test_every_goal_is_reachable_with_the_level_blocks() -> void:
	for id in LEVEL_IDS:
		var level: LevelDef = Registry.levels[id]
		var reachable := reachable_values(level)
		for goal in level.goals:
			assert_true(reachable.has(goal), "level %s: goal %d is not reachable in %d steps" % [id, goal, MAX_STEPS])


func test_buildable_has_at_most_10_blocks() -> void:
	for id in LEVEL_IDS:
		assert_lte(Registry.levels[id].buildable.size(), MAX_BUILDABLE, "level %s" % id)
