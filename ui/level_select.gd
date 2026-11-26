extends Control

const DONE_COLOR := Color("8fe388")
const LEVEL_BUTTON_SIZE := Vector2(520, 110)

@onready var back_button: Button = %BackButton
@onready var sections: VBoxContainer = %Sections


func _ready() -> void:
	back_button.pressed.connect(Game.open.bind(&"main_menu"))
	var groups := LevelGroups.by_grade(Registry.levels_sorted)
	for grade in groups:
		var heading := Label.new()
		heading.text = LevelGroups.grade_title(grade)
		sections.add_child(heading)
		var buttons := HFlowContainer.new()
		buttons.add_theme_constant_override("h_separation", 20)
		buttons.add_theme_constant_override("v_separation", 20)
		sections.add_child(buttons)
		for level: LevelDef in groups[grade]:
			buttons.add_child(_level_button(level))


func _level_button(level: LevelDef) -> Button:
	var button := Button.new()
	var lines: PackedStringArray = [level.title]
	var details: PackedStringArray = []
	if Game.best_stars.has(level.id):
		details.append(LevelRating.star_text(Game.best_stars[level.id]))
	if Game.best_times.has(level.id):
		details.append("Najboljši: %s" % Game.format_time(Game.best_times[level.id]))
	if level.target_time > 0.0:
		details.append("Cilj: %s" % Game.format_time(level.target_time))
	if not details.is_empty():
		lines.append("  |  ".join(details))
	button.text = "\n".join(lines)
	button.custom_minimum_size = LEVEL_BUTTON_SIZE
	if Game.completed_levels.has(level.id):
		button.add_theme_color_override("font_color", DONE_COLOR)
		button.add_theme_color_override("font_hover_color", DONE_COLOR)
	button.pressed.connect(Game.open_level.bind(level))
	return button
