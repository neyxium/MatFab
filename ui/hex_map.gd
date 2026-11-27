class_name HexMap extends Control

const HEX_TILE_SCENE := preload("res://ui/hex_tile.tscn")
const HEX_SIZE := Vector2(120, 120)
const COLUMNS := 4
const MIN_ZOOM := 0.5
const MAX_ZOOM := 2.5
const WHEEL_ZOOM_STEP := 1.12
const DRAG_SLOP := 12.0
const KEEP_VISIBLE := 120.0

@export var levels: Array[LevelDef] = []

var current_type: LevelDef.SchoolType = LevelDef.SchoolType.PRIMARY
var tiles: Array[HexTile] = []
var selected_tile: HexTile
var _grid_rect := Rect2()
var _touches: Dictionary[int, Vector2] = {}
var _pinch_start_dist := 0.0
var _pinch_start_zoom := 1.0
var _drag_distance := 0.0

@onready var background: TextureRect = %Background
@onready var back_button: Button = %BackButton
@onready var school_panel: PanelContainer = %SchoolPanel
@onready var primary_button: Button = %PrimaryButton
@onready var secondary_button: Button = %SecondaryButton
@onready var map_area: Control = %MapArea
@onready var map_content: Control = %MapContent
@onready var bottom_bar: PanelContainer = %BottomBar
@onready var selected_title: Label = %SelectedTitle
@onready var selected_desc: Label = %SelectedDesc
@onready var start_button: Button = %StartButton


func _ready() -> void:
	_style_school_panel()
	_style_action_buttons()
	back_button.pressed.connect(Game.open.bind(&"main_menu"))
	primary_button.pressed.connect(_select_type.bind(LevelDef.SchoolType.PRIMARY))
	secondary_button.pressed.connect(_select_type.bind(LevelDef.SchoolType.SECONDARY))
	start_button.pressed.connect(_on_start_pressed)
	map_area.resized.connect(_layout_tiles)
	_select_type(LevelDef.SchoolType.PRIMARY)


func _style_school_panel() -> void:
	var panel_box := StyleBoxFlat.new()
	panel_box.bg_color = Color(0, 0, 0, 0.92)
	panel_box.border_color = Color(0.32, 0.32, 0.32, 1)
	panel_box.set_border_width_all(2)
	panel_box.set_content_margin_all(6)
	school_panel.add_theme_stylebox_override("panel", panel_box)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color.TRANSPARENT
	normal.set_border_width_all(0)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6

	var hover := normal.duplicate()
	hover.bg_color = Color(1, 1, 1, 0.08)

	var active := hover.duplicate()
	active.border_color = Color("ffd37f")
	active.set_border_width_all(2)

	for button in [primary_button, secondary_button]:
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", active)
		button.add_theme_stylebox_override("hover_pressed", active)
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.add_theme_color_override("font_color", Color(0.85, 0.87, 0.9, 1))
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_pressed_color", Color("ffd37f"))
		button.add_theme_color_override("font_hover_pressed_color", Color("ffd37f"))


func _style_action_buttons() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0.72)
	normal.border_color = Color(0.45, 0.45, 0.45, 1)
	normal.set_border_width_all(2)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8

	var hover := normal.duplicate()
	hover.bg_color = Color(0.12, 0.13, 0.16, 0.85)
	hover.border_color = Color(0.65, 0.65, 0.65, 1)

	var pressed := hover.duplicate()
	pressed.border_color = Color("ffd37f")

	for button in [start_button, back_button]:
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.add_theme_color_override("font_pressed_color", Color("ffd37f"))


func _select_type(school_type: LevelDef.SchoolType) -> void:
	current_type = school_type
	primary_button.set_pressed_no_signal(current_type == LevelDef.SchoolType.PRIMARY)
	secondary_button.set_pressed_no_signal(current_type == LevelDef.SchoolType.SECONDARY)
	map_content.position = Vector2.ZERO
	map_content.scale = Vector2.ONE
	_build_hex_grid()
	_layout_tiles.call_deferred()


func _build_hex_grid() -> void:
	for tile in tiles:
		tile.queue_free()
	tiles.clear()
	selected_tile = null
	bottom_bar.hide()

	var source: Array[LevelDef] = levels if not levels.is_empty() else Registry.levels_sorted
	var num := 0
	for level in source:
		if level.type != current_type:
			continue
		num += 1
		var tile: HexTile = HEX_TILE_SCENE.instantiate()
		map_content.add_child(tile)
		tile.setup(level, num)
		tile.toggled.connect(_on_tile_toggled.bind(tile))
		tiles.append(tile)


func _layout_tiles() -> void:
	if tiles.is_empty():
		return
	var step_x := HEX_SIZE.x * 0.92
	var step_y := HEX_SIZE.y * 0.80
	var cols := mini(COLUMNS, tiles.size())
	var rows := ceili(float(tiles.size()) / COLUMNS)
	var total_w := (cols - 1) * step_x + HEX_SIZE.x + (step_x * 0.5 if rows > 1 else 0.0)
	var total_h := (rows - 1) * step_y + HEX_SIZE.y
	var origin := (map_area.size - Vector2(total_w, total_h)) * 0.5
	_grid_rect = Rect2(origin, Vector2(total_w, total_h))

	for i in tiles.size():
		var col := i % COLUMNS
		@warning_ignore("integer_division")
		var row := i / COLUMNS
		var x := origin.x + col * step_x + (step_x * 0.5 if row % 2 == 1 else 0.0)
		var y := origin.y + row * step_y
		tiles[i].position = Vector2(x, y)
	_clamp_map_position()


func _on_tile_toggled(on: bool, tile: HexTile) -> void:
	if not on:
		if selected_tile == tile:
			selected_tile = null
			bottom_bar.hide()
		return
	if selected_tile != null and selected_tile != tile:
		selected_tile.button_pressed = false
	selected_tile = tile
	selected_title.text = tile.level_def.title
	selected_desc.text = "%s  •  Zvezdice: %d/3" % [
		LevelGroups.grade_title(tile.level_def.grade),
		Game.best_stars.get(tile.level_def.id, 0),
	]
	bottom_bar.show()


func _on_start_pressed() -> void:
	if selected_tile != null:
		Game.open_level(selected_tile.level_def)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag and _touches.has(event.index):
		_handle_drag(event)
	elif event is InputEventMouseButton and event.pressed:
		if map_area.get_global_rect().has_point(event.position) and not _is_over_ui(event.position):
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_zoom_at(clampf(map_content.scale.x * WHEEL_ZOOM_STEP, MIN_ZOOM, MAX_ZOOM), _to_map_area(event.position))
				get_viewport().set_input_as_handled()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_zoom_at(clampf(map_content.scale.x / WHEEL_ZOOM_STEP, MIN_ZOOM, MAX_ZOOM), _to_map_area(event.position))
				get_viewport().set_input_as_handled()


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _touches.is_empty() and (not map_area.get_global_rect().has_point(event.position) or _is_over_ui(event.position)):
			return
		_touches[event.index] = event.position
		if _touches.size() == 1:
			_drag_distance = 0.0
		elif _touches.size() == 2:
			var pts := _touches.values()
			_pinch_start_dist = pts[0].distance_to(pts[1])
			_pinch_start_zoom = map_content.scale.x
			get_viewport().set_input_as_handled()
	else:
		if not _touches.has(event.index):
			return
		_touches.erase(event.index)
		if _touches.is_empty() and _drag_distance > DRAG_SLOP:
			get_viewport().set_input_as_handled()


func _handle_drag(event: InputEventScreenDrag) -> void:
	_touches[event.index] = event.position
	if _touches.size() == 2:
		var pts := _touches.values()
		var new_zoom := GestureMath.pinch_zoom(_pinch_start_zoom, _pinch_start_dist, pts[0].distance_to(pts[1]), MIN_ZOOM, MAX_ZOOM)
		_zoom_at(new_zoom, _to_map_area((pts[0] + pts[1]) * 0.5))
		map_content.position += event.relative * 0.5
		_clamp_map_position()
		get_viewport().set_input_as_handled()
	elif _touches.size() == 1:
		_drag_distance += event.relative.length()
		if _drag_distance > DRAG_SLOP:
			map_content.position += event.relative
			_clamp_map_position()
			get_viewport().set_input_as_handled()


func _is_over_ui(screen_pos: Vector2) -> bool:
	return school_panel.get_global_rect().has_point(screen_pos) or back_button.get_global_rect().has_point(screen_pos) or (bottom_bar.visible and bottom_bar.get_global_rect().has_point(screen_pos))


func _to_map_area(screen_pos: Vector2) -> Vector2:
	return map_area.get_global_transform().affine_inverse() * screen_pos


func _zoom_at(new_zoom: float, area_point: Vector2) -> void:
	var old_zoom := map_content.scale.x
	if is_equal_approx(old_zoom, new_zoom):
		return
	var local_before := (area_point - map_content.position) / old_zoom
	map_content.scale = Vector2.ONE * new_zoom
	map_content.position = area_point - local_before * new_zoom
	for tile in tiles:
		tile.set_zoom(new_zoom)
	_clamp_map_position()


func _clamp_map_position() -> void:
	if _grid_rect.size == Vector2.ZERO:
		return
	var zoom := map_content.scale.x
	var scaled_size := _grid_rect.size * zoom
	var margin := Vector2(minf(KEEP_VISIBLE, scaled_size.x * 0.5), minf(KEEP_VISIBLE, scaled_size.y * 0.5))
	var scaled_pos := map_content.position + _grid_rect.position * zoom
	scaled_pos.x = clampf(scaled_pos.x, margin.x - scaled_size.x, map_area.size.x - margin.x)
	scaled_pos.y = clampf(scaled_pos.y, margin.y - scaled_size.y, map_area.size.y - margin.y)
	map_content.position = scaled_pos - _grid_rect.position * zoom
	_update_background()


func _update_background() -> void:
	var max_shift := map_area.size * 0.22
	var shift := Vector2(
		clampf(map_content.position.x * 0.18, -max_shift.x, max_shift.x),
		clampf(map_content.position.y * 0.18, -max_shift.y, max_shift.y)
	)
	background.offset_left = shift.x
	background.offset_right = shift.x
	background.offset_top = shift.y
	background.offset_bottom = shift.y
	background.pivot_offset = background.size * 0.5
	background.scale = Vector2.ONE * (1.0 + (map_content.scale.x - 1.0) * 0.08)
