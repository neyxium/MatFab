class_name LevelComplete extends OverlayMenu

signal main_menu_pressed
signal restart_pressed

const TIME_FONT_SIZE := 24
const STAR_FONT_SIZE := 72
const GRADE_FONT_SIZE := 36
const STAR_COLOR := Color("ffd34d")
const RECORD_COLOR := Color("8fe388")
const HINT_COLOR := Color(1, 1, 1, 0.7)
# Seconds between stars as they fill in.
const STAR_DELAY := 0.25

var star_label: Label
var grade_label: Label
var time_label: Label
var record_label: Label
var hint_label: Label
var _star_tween: Tween


func _ready() -> void:
	add_title("Stopnja opravljena")
	star_label = add_line(STAR_FONT_SIZE, STAR_COLOR)
	grade_label = add_line(GRADE_FONT_SIZE, STAR_COLOR)
	time_label = add_line(TIME_FONT_SIZE)
	record_label = add_line(TIME_FONT_SIZE, RECORD_COLOR)
	hint_label = add_line(TIME_FONT_SIZE, HINT_COLOR)
	add_button("Začni znova", restart_pressed.emit)
	add_button("Glavni meni", main_menu_pressed.emit)


func add_line(font_size: int, color := Color.TRANSPARENT) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	if color != Color.TRANSPARENT:
		label.add_theme_color_override("font_color", color)
	items.add_child(label)
	return label


# `result` comes from Game: LevelRating.rate plus "new_record" and "first_clear".
func show_result(result: Dictionary, level: LevelDef, best_time: float, best_cost: int) -> void:
	var stars: int = result["stars"]
	var cost: int = result["cost"]
	var elapsed: float = result["elapsed"]
	grade_label.text = "Ocena: %s" % result["grade"]
	var lines: PackedStringArray = []
	var cost_line := "Bloki: %d" % cost
	if level.par_cost > 0:
		cost_line += " (cilj: %d)" % level.par_cost
	lines.append(cost_line)
	var time_line := "Čas: %s" % Game.format_time(elapsed)
	if level.target_time > 0.0:
		time_line += " (cilj: %s)" % Game.format_time(level.target_time)
	lines.append(time_line)
	if best_time >= 0.0 and best_cost >= 0:
		lines.append("Najboljše: %s, %d blokov" % [Game.format_time(best_time), best_cost])
	time_label.text = "\n".join(lines)
	record_label.visible = result.get("new_record", false) and not result.get("first_clear", false)
	record_label.text = "Nov rekord!"
	hint_label.text = hint(level, cost, elapsed)
	hint_label.visible = hint_label.text != ""
	fill_stars(stars)


# What would earn the missing stars; empty with all three.
static func hint(level: LevelDef, cost: int, elapsed: float) -> String:
	var tips: PackedStringArray = []
	if not LevelRating.meets_cost(level, cost):
		tips.append("z manj bloki")
	if not LevelRating.meets_time(level, elapsed):
		tips.append("hitreje")
	if tips.is_empty():
		return ""
	return "Za več zvezdic poskusi %s." % " in ".join(tips)


# Stars fill in one at a time.
func fill_stars(stars: int) -> void:
	if _star_tween != null:
		_star_tween.kill()
	star_label.text = LevelRating.star_text(0)
	_star_tween = create_tween()
	for count in range(1, stars + 1):
		_star_tween.tween_interval(STAR_DELAY)
		_star_tween.tween_callback(func() -> void: star_label.text = LevelRating.star_text(count))
