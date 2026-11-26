class_name LevelRating extends RefCounted

# Rates a finished level on two axes: build cost against LevelDef.par_cost (space) and elapsed time against
# LevelDef.target_time (time). A par of 0 means the level has none, and a missing par counts as met.

const MAX_STARS := 3
# Each axis scores par / actual, capped so that beating one par by a lot cannot make up for missing the other.
const RATIO_CAP := 1.25
const S_SCORE := 1.15
const B_SCORE := 0.8


static func stars(level: LevelDef, cost: int, elapsed: float) -> int:
	var count := 1
	if meets_cost(level, cost):
		count += 1
	if meets_time(level, elapsed):
		count += 1
	return count


static func meets_cost(level: LevelDef, cost: int) -> bool:
	return level.par_cost <= 0 or cost <= level.par_cost


static func meets_time(level: LevelDef, elapsed: float) -> bool:
	return level.target_time <= 0.0 or elapsed <= level.target_time


# Average of both axis ratios; 1.0 means exactly on par, and an axis without a par scores 1.0.
static func score(level: LevelDef, cost: int, elapsed: float) -> float:
	return (ratio(level.par_cost, cost) + ratio(level.target_time, elapsed)) / 2.0


static func ratio(par: float, actual: float) -> float:
	if par <= 0.0:
		return 1.0
	if actual <= 0.0:
		return RATIO_CAP
	return minf(par / actual, RATIO_CAP)


static func grade(level: LevelDef, cost: int, elapsed: float) -> String:
	var points := score(level, cost, elapsed)
	if stars(level, cost, elapsed) == MAX_STARS:
		return "S" if points >= S_SCORE else "A"
	return "B" if points >= B_SCORE else "C"


# {"stars": int, "grade": String, "cost": int, "elapsed": float}
static func rate(level: LevelDef, cost: int, elapsed: float) -> Dictionary:
	return {
		"stars": stars(level, cost, elapsed),
		"grade": grade(level, cost, elapsed),
		"cost": cost,
		"elapsed": elapsed,
	}


static func star_text(count: int) -> String:
	var filled := clampi(count, 0, MAX_STARS)
	return "★".repeat(filled) + "☆".repeat(MAX_STARS - filled)
