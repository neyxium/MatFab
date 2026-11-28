class_name Hud extends Control

signal pause_pressed
signal info_pressed
signal speed_changed(speed: float)

const GOAL_FONT_SIZE := 24
const GOAL_ROW_WIDTH := 170
const DONE_COLOR := Color("8fe388")
const OVER_TIME_COLOR := Color("f08a6c")
const SYMBOL_FONT_SIZE := 22

# Mindustry-inspired build panel colors and layout.
const PANEL_BG := Color(0, 0, 0, 0.92)
const PANEL_BORDER := Color(0.28, 0.28, 0.28, 1)
const ACTIVE_BORDER := Color("ffd37f")
const SLOT_HOVER := Color(1, 1, 1, 0.12)
const SPEED_LABELS: Array[String] = ["1x", "2x", "4x"]
const SPEED_VALUES: Array[float] = [1.0, 2.0, 4.0]
const BLOCK_BUTTON_SIZE := Vector2(44, 44)
const CATEGORY_BUTTON_SIZE := Vector2(44, 44)
const TOOL_BUTTON_SIZE := Vector2(44, 44)
const TOOL_ICON_ERASER := preload("res://assets/real/trash.png")
const TOOL_ICON_SELECT := preload("res://assets/placeholder/icon_select.png")
const TOOL_ICON_UNDO := preload("res://assets/real/undo.png")
const TOOL_ICON_REDO := preload("res://assets/real/redo.png")
const CATEGORY_ORDER: Array[StringName] = [&"production", &"conveyor", &"miner"]
const CATEGORY_LABELS: Dictionary[StringName, String] = {
	&"production": "Proizvodnja",
	&"conveyor": "Transport",
	&"miner": "Rudarji",
}
# Category icons; swap these textures anytime to change the 3 category tabs on the right.
const CATEGORY_ICONS: Dictionary[StringName, Texture2D] = {
	&"production": preload("res://assets/real/crafting.png"),
	&"conveyor": preload("res://assets/real/distribution.png"),
	&"miner": preload("res://assets/real/production.png"),
}

var tracker: GoalTracker
var goal_rows: Dictionary[int, PanelContainer] = {}
var build_tool: BuildTool
var active_category: StringName = &"production"
var category_defs: Dictionary[StringName, Array] = {}
var category_buttons: Dictionary[StringName, Button] = {}
var slot_buttons: Dictionary[BuildingDef, Button] = {}
var eraser_button: Button
var select_button: Button
var _target_time := 0.0
var _par_cost := 0
var goals_expanded := false
var speed_index := 0

@onready var timer_panel: PanelContainer = $TopLeft/TimerPanel
@onready var time_label: Label = $TopLeft/TimerPanel/TimerRows/TimeLabel
@onready var best_time_label: Label = $TopLeft/TimerPanel/TimerRows/BestTimeLabel
@onready var cost_label: Label = $TopLeft/TimerPanel/TimerRows/CostLabel
@onready var goal_panel: PanelContainer = $TopLeft/GoalPanel
@onready var goal_list: VBoxContainer = $TopLeft/GoalPanel/GoalLayout/GoalList
@onready var goal_toggle: Button = $TopLeft/GoalPanel/GoalLayout/GoalToggle
@onready var build_panel: PanelContainer = $BuildPanel
@onready var selected_icon: TextureRect = $BuildPanel/Content/HeaderMargin/HeaderRow/SelectedIcon
@onready var selected_name: Label = $BuildPanel/Content/HeaderMargin/HeaderRow/SelectedName
@onready var help_button: Button = $BuildPanel/Content/HeaderMargin/HeaderRow/HelpButton
@onready var block_grid: GridContainer = $BuildPanel/Content/Body/LeftColumn/BlocksMargin/BlockGrid
@onready var tool_row: HBoxContainer = $BuildPanel/Content/Body/LeftColumn/ToolsMargin/ToolRow
@onready var category_column: VBoxContainer = $BuildPanel/Content/Body/CategoriesMargin/CategoryColumn
@onready var pause_button: Button = $PauseButton
@onready var speed_button: Button = $SpeedButton


func _ready() -> void:
	pause_button.pressed.connect(pause_pressed.emit)
	help_button.pressed.connect(info_pressed.emit)
	goal_toggle.pressed.connect(_toggle_goals)
	speed_button.pressed.connect(_cycle_speed)
	_style_speed_button()
	speed_button.text = SPEED_LABELS[speed_index]


func _cycle_speed() -> void:
	speed_index = (speed_index + 1) % SPEED_LABELS.size()
	speed_button.text = SPEED_LABELS[speed_index]
	speed_changed.emit(SPEED_VALUES[speed_index])


func set_speed(speed: float) -> void:
	speed_index = 0
	for i in SPEED_VALUES.size():
		if is_equal_approx(SPEED_VALUES[i], speed):
			speed_index = i
			break
	speed_button.text = SPEED_LABELS[speed_index]


func _style_speed_button() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = PANEL_BG
	normal.set_border_width_all(0)
	normal.set_corner_radius_all(12)
	normal.corner_detail = 1
	normal.set_content_margin_all(6)

	var hover := normal.duplicate()
	hover.bg_color = Color(0.08, 0.08, 0.1, 0.94)

	var pressed := hover.duplicate()

	speed_button.add_theme_stylebox_override("normal", normal)
	speed_button.add_theme_stylebox_override("hover", hover)
	speed_button.add_theme_stylebox_override("pressed", pressed)
	speed_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	speed_button.add_theme_color_override("font_color", Color.WHITE)
	speed_button.add_theme_color_override("font_hover_color", Color.WHITE)
	speed_button.add_theme_color_override("font_pressed_color", Color.WHITE)


func show_timer(target_time: float, best_time: float) -> void:
	_target_time = target_time
	BarStyle.style_panel(timer_panel)
	timer_panel.visible = true
	best_time_label.visible = best_time >= 0.0
	if best_time_label.visible:
		best_time_label.text = "Najboljši: %s" % Game.format_time(best_time)


func update_timer(elapsed_time: float) -> void:
	if not timer_panel.visible:
		return
	if _target_time > 0.0:
		time_label.text = "%s / %s" % [Game.format_time(elapsed_time), Game.format_time(_target_time)]
		if elapsed_time > _target_time:
			time_label.add_theme_color_override("font_color", OVER_TIME_COLOR)
		else:
			time_label.remove_theme_color_override("font_color")
	else:
		time_label.text = Game.format_time(elapsed_time)
		time_label.remove_theme_color_override("font_color")


func show_cost(par_cost: int) -> void:
	_par_cost = par_cost
	cost_label.visible = true


func update_cost(cost: int) -> void:
	if _par_cost > 0:
		cost_label.text = "Bloki: %d / %d" % [cost, _par_cost]
	else:
		cost_label.text = "Bloki: %d" % cost
	if _par_cost > 0 and cost > _par_cost:
		cost_label.add_theme_color_override("font_color", OVER_TIME_COLOR)
	else:
		cost_label.remove_theme_color_override("font_color")


func show_goals(goal_tracker: GoalTracker) -> void:
	tracker = goal_tracker
	goals_expanded = false
	BarStyle.style_panel(goal_panel)
	BarStyle.style_slot(goal_toggle)
	goal_toggle.visible = tracker.goals.size() > 1
	for child in goal_list.get_children():
		child.queue_free()
	goal_rows.clear()
	for number in tracker.goals:
		var row := make_goal_row(number)
		goal_list.add_child(row)
		goal_rows[number] = row
		update_goal(number, tracker.received.get(number, 0))
	_refresh_goal_visibility()
	if not tracker.counted.is_connected(update_goal):
		tracker.counted.connect(update_goal)


# A row shows the wanted number on the left and how many arrived on the right.
func make_goal_row(number: int) -> PanelContainer:
	var row := PanelContainer.new()
	row.custom_minimum_size.x = GOAL_ROW_WIDTH
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(line)
	var number_label := goal_label(str(number))
	number_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(number_label)
	line.add_child(goal_label(""))
	return row


func goal_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", GOAL_FONT_SIZE)
	return label


func update_goal(number: int, count: int) -> void:
	if not goal_rows.has(number):
		return
	var row := goal_rows[number]
	var line := row.get_child(0)
	var count_label: Label = line.get_child(1)
	var goal := tracker.goals[number]
	count_label.text = "%d / %d" % [count, goal]
	var done := count >= goal
	row.add_theme_stylebox_override("panel", BarStyle.slot_box(BarStyle.SLOT_COLOR, 8, DONE_COLOR if done else Color.TRANSPARENT))
	if done:
		for label: Label in line.get_children():
			label.add_theme_color_override("font_color", DONE_COLOR)
	_refresh_goal_visibility()


func _toggle_goals() -> void:
	goals_expanded = not goals_expanded
	_refresh_goal_visibility()


func _closest_goal() -> int:
	var best_number := -1
	var best_ratio := -1.0
	var best_remaining := 0
	var last_number := -1
	for number in tracker.goals:
		last_number = number
		var target := tracker.goals[number]
		var progress := tracker.progress(number)
		if progress >= target:
			continue
		var ratio := float(progress) / float(maxi(1, target))
		var remaining := target - progress
		if best_number == -1 or ratio > best_ratio or (is_equal_approx(ratio, best_ratio) and remaining < best_remaining):
			best_number = number
			best_ratio = ratio
			best_remaining = remaining
	return best_number if best_number != -1 else last_number


func _refresh_goal_visibility() -> void:
	goal_toggle.text = "▲" if goals_expanded else "▼"
	if goals_expanded:
		for number in goal_rows:
			goal_rows[number].visible = true
		return
	var primary := _closest_goal()
	for number in goal_rows:
		goal_rows[number].visible = (number == primary)


static func category_for(def: BuildingDef) -> StringName:
	if def.operation == &"mine" or def.id == &"miner":
		return &"miner"
	if def.behavior in [
		BuildingDef.Behavior.CONVEYOR,
		BuildingDef.Behavior.SPLITTER,
		BuildingDef.Behavior.MERGER,
		BuildingDef.Behavior.TUNNEL_IN,
		BuildingDef.Behavior.TUNNEL_OUT,
	]:
		return &"conveyor"
	return &"production"


func _style_build_panel() -> void:
	var panel_box := StyleBoxFlat.new()
	panel_box.bg_color = PANEL_BG
	panel_box.border_color = PANEL_BORDER
	panel_box.set_border_width_all(4)
	panel_box.corner_radius_top_left = 18
	panel_box.corner_detail = 1
	panel_box.set_content_margin_all(0)
	build_panel.add_theme_stylebox_override("panel", panel_box)

	var help_normal := StyleBoxFlat.new()
	help_normal.bg_color = Color.BLACK
	help_normal.border_color = PANEL_BORDER
	help_normal.set_border_width_all(2)
	help_normal.set_content_margin_all(4)
	var help_hover := help_normal.duplicate()
	help_hover.bg_color = SLOT_HOVER
	var help_pressed := help_hover.duplicate()
	help_pressed.border_color = ACTIVE_BORDER
	help_button.add_theme_stylebox_override("normal", help_normal)
	help_button.add_theme_stylebox_override("hover", help_hover)
	help_button.add_theme_stylebox_override("pressed", help_pressed)
	help_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


static func style_mindustry_button(button: Button) -> void:
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color.TRANSPARENT
	normal.set_border_width_all(0)
	normal.set_content_margin_all(5)

	var hover := normal.duplicate()
	hover.bg_color = SLOT_HOVER

	var pressed := hover.duplicate()
	pressed.set_border_width_all(3)
	pressed.border_color = ACTIVE_BORDER

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("hover_pressed", pressed)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func show_toolbar(tool: BuildTool) -> void:
	build_tool = tool
	_style_build_panel()

	category_defs.clear()
	for cat in CATEGORY_ORDER:
		category_defs[cat] = []
	for def in build_tool.buildable:
		category_defs[category_for(def)].append(def)

	for child in category_column.get_children():
		child.queue_free()
	category_buttons.clear()

	for cat in CATEGORY_ORDER:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = CATEGORY_BUTTON_SIZE
		button.toggle_mode = true
		button.icon = CATEGORY_ICONS.get(cat)
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.tooltip_text = CATEGORY_LABELS.get(cat, String(cat))
		style_mindustry_button(button)
		if category_defs[cat].is_empty():
			button.disabled = true
			button.modulate.a = 0.35
		button.pressed.connect(_select_category.bind(cat))
		category_column.add_child(button)
		category_buttons[cat] = button

	active_category = &"production"
	for cat in CATEGORY_ORDER:
		if not category_defs[cat].is_empty():
			active_category = cat
			break

	_rebuild_block_grid()
	_build_tool_row()
	if not build_tool.state_changed.is_connected(refresh_toolbar):
		build_tool.state_changed.connect(refresh_toolbar)
	refresh_toolbar()


func _build_tool_row() -> void:
	for child in tool_row.get_children():
		child.queue_free()
	eraser_button = _make_tool_button(TOOL_ICON_ERASER, "Radirka", true, func() -> void:
		if build_tool.mode == BuildTool.Mode.ERASE:
			build_tool.drop_tool()
		else:
			build_tool.use_eraser()
	)
	select_button = _make_tool_button(TOOL_ICON_SELECT, "Označi", true, func() -> void:
		if build_tool.mode == BuildTool.Mode.SELECT or build_tool.has_selection():
			build_tool.selection = Rect2i()
			build_tool.clipboard = null
			build_tool.drop_tool()
		else:
			build_tool.use_selector()
	)
	_make_tool_button(TOOL_ICON_UNDO, "Razveljavi", false, build_tool.undo)
	_make_tool_button(TOOL_ICON_REDO, "Uveljavi", false, build_tool.redo)


func _make_tool_button(icon_tex: Texture2D, tip: String, toggle: bool, action: Callable) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = TOOL_BUTTON_SIZE
	button.toggle_mode = toggle
	button.icon = icon_tex
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("icon_max_width", 26)
	button.tooltip_text = tip
	style_mindustry_button(button)
	button.pressed.connect(action)
	tool_row.add_child(button)
	return button


func _select_category(cat: StringName) -> void:
	active_category = cat
	_rebuild_block_grid()
	refresh_toolbar()


func _rebuild_block_grid() -> void:
	for child in block_grid.get_children():
		child.queue_free()
	slot_buttons.clear()
	var defs: Array = category_defs.get(active_category, [])
	for def: BuildingDef in defs:
		var button := make_block_button(def)
		block_grid.add_child(button)
		slot_buttons[def] = button


func make_block_button(def: BuildingDef) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = BLOCK_BUTTON_SIZE
	button.toggle_mode = true
	button.tooltip_text = def.display_name
	style_mindustry_button(button)
	if def.sprite != null:
		button.icon = def.sprite
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		button.add_child(symbol_tile(def))
	button.pressed.connect(_on_block_pressed.bind(def))
	return button


func _on_block_pressed(def: BuildingDef) -> void:
	if build_tool.tool_def == def:
		build_tool.drop_tool()
	else:
		build_tool.select_def(def)


func current_info_def() -> BuildingDef:
	if build_tool == null:
		return null
	if build_tool.tool_def != null:
		return build_tool.tool_def
	var defs: Array = category_defs.get(active_category, [])
	if not defs.is_empty():
		return defs[0]
	return build_tool.buildable[0] if not build_tool.buildable.is_empty() else null


# Blocks without art yet show the same symbol tile they are drawn with on the grid.
func symbol_tile(def: BuildingDef) -> Label:
	var tile := Label.new()
	tile.text = def.symbol
	tile.add_theme_font_size_override("font_size", SYMBOL_FONT_SIZE)
	var box := StyleBoxFlat.new()
	box.bg_color = BuildingView.FILL_COLOR
	box.border_color = BuildingView.BORDER_COLOR
	box.set_border_width_all(2)
	box.set_corner_radius_all(4)
	tile.add_theme_stylebox_override("normal", box)
	tile.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tile.offset_left = 6
	tile.offset_top = 6
	tile.offset_right = -6
	tile.offset_bottom = -6
	return tile


func refresh_toolbar() -> void:
	if build_tool.tool_def != null:
		var target_cat := category_for(build_tool.tool_def)
		if target_cat != active_category:
			active_category = target_cat
			_rebuild_block_grid()
	for cat in category_buttons:
		category_buttons[cat].set_pressed_no_signal(cat == active_category)
	for def in slot_buttons:
		slot_buttons[def].set_pressed_no_signal(build_tool.tool_def == def)
	if eraser_button != null:
		eraser_button.set_pressed_no_signal(build_tool.mode == BuildTool.Mode.ERASE)
	if select_button != null:
		select_button.set_pressed_no_signal(build_tool.mode == BuildTool.Mode.SELECT or build_tool.has_selection())
	help_button.visible = build_tool.tool_def != null
	if build_tool.tool_def != null:
		selected_name.text = build_tool.tool_def.display_name
		selected_icon.texture = build_tool.tool_def.sprite
		selected_icon.visible = build_tool.tool_def.sprite != null
	else:
		selected_name.text = CATEGORY_LABELS.get(active_category, "")
		selected_icon.visible = false
