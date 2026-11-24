extends Node

signal level_completed

const SCREENS: Dictionary[StringName, String] = {
	&"main_menu": "res://ui/main_menu.tscn",
	&"level_select": "res://ui/level_select.tscn",
	&"settings": "res://ui/settings_menu.tscn",
	&"play": "res://game/play.tscn",
}

var level: LevelDef
var sim: Simulation
var clock := SimClock.new()
var elapsed_time := 0.0
var paused := false
# Filled from progress.sav by the save store; level select marks these levels.
var completed_levels: Array[StringName] = []
var best_times: Dictionary[StringName, float] = {}
var best_stars: Dictionary[StringName, int] = {}
var best_cost: Dictionary[StringName, int] = {}
var last_result: Dictionary = {}
var last_played := &""
var save_store := SaveStore.new()
var autosave := AutosaveTimer.new()
# Blocks whose description the HUD has already shown once; the Info window shows them again.
var seen_block_info: Array[StringName] = []


func _ready() -> void:
	# Keeps running while the tree is paused, so back still reaches go_back.
	process_mode = Node.PROCESS_MODE_ALWAYS
	var progress := save_store.load_progress()
	completed_levels.assign(progress["completed"])
	best_times.assign(progress["best_times"])
	best_stars.assign(progress["best_stars"])
	best_cost.assign(progress["best_cost"])
	last_played = progress["last_played"]


func _physics_process(delta: float) -> void:
	step_sim(delta)


func step_sim(delta: float) -> void:
	if sim == null or paused or (sim.tracker != null and sim.tracker.is_complete()):
		return
	elapsed_time += delta
	for step in clock.advance(delta):
		sim.step()
	if autosave.advance(delta):
		save_world()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		go_back()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		save_world()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		go_back()


# Leaving to the menus ends the level; the settings screen keeps it, so back returns to it paused.
func open(id: StringName) -> void:
	if id == &"main_menu" or id == &"level_select":
		close_level()
	get_tree().change_scene_to_file(SCREENS[id])


func open_level(level_def: LevelDef) -> void:
	load_level(level_def, true)
	open(&"play")


# Starts the open level again from its layout and overwrites its saved world, so a completed level can be replayed.
func restart_level() -> void:
	load_level(level, false)
	save_world()
	open(&"play")


func load_level(level_def: LevelDef, from_save: bool) -> void:
	level = level_def
	sim = Simulation.from_level(level, Registry.buildings)
	elapsed_time = 0.0
	if from_save and save_store.has_world(level.id):
		save_store.load_world(level.id, sim)
		elapsed_time = save_store.load_world_time(level.id)
	clock = SimClock.new()
	autosave.restart()
	paused = false
	sim.tracker.completed.connect(complete_level)
	last_played = level.id
	save_progress()


# The level played last, when it still exists; Nadaljuj opens it.
func continue_level() -> LevelDef:
	return Registry.levels.get(last_played)


func complete_level() -> void:
	if not completed_levels.has(level.id):
		completed_levels.append(level.id)
	last_result = current_result()
	last_result["new_record"] = keep_records(level.id, last_result)
	paused = true
	save_world()
	save_progress()
	level_completed.emit()


# The open level rated on its current build cost and time.
func current_result() -> Dictionary:
	return LevelRating.rate(level, sim.build_cost(), elapsed_time)


func keep_records(id: StringName, result: Dictionary) -> bool:
	var improved := false
	if not best_times.has(id) or result["elapsed"] < best_times[id]:
		best_times[id] = result["elapsed"]
		improved = true
	if not best_stars.has(id) or result["stars"] > best_stars[id]:
		best_stars[id] = result["stars"]
		improved = true
	if not best_cost.has(id) or result["cost"] < best_cost[id]:
		best_cost[id] = result["cost"]
		improved = true
	return improved


func save_world() -> void:
	if sim != null:
		save_store.save_world(level.id, sim, elapsed_time)


func save_progress() -> void:
	save_store.save_progress({
		"completed": completed_levels,
		"last_played": last_played,
		"best_times": best_times,
		"best_stars": best_stars,
		"best_cost": best_cost,
	})


func close_level() -> void:
	save_world()
	level = null
	sim = null
	elapsed_time = 0.0
	paused = false


func reset_progress() -> void:
	level = null
	sim = null
	elapsed_time = 0.0
	paused = false
	completed_levels.clear()
	best_times.clear()
	best_stars.clear()
	best_cost.clear()
	last_result = {}
	last_played = &""
	seen_block_info.clear()
	save_store.clear_all()


static func format_time(seconds: float) -> String:
	var total := maxi(0, int(seconds))
	@warning_ignore("integer_division")
	var hours := total / 3600
	@warning_ignore("integer_division")
	var minutes := (total % 3600) / 60
	var secs := total % 60
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, secs]
	return "%02d:%02d" % [minutes, secs]


# On the play screen back is the screen's own: it drops the tool or selection first, then opens the pause menu.
func go_back() -> void:
	match current_screen():
		&"main_menu":
			get_tree().quit()
		&"level_select":
			open(&"main_menu")
		&"play", &"settings":
			get_tree().current_scene.go_back()


func current_screen() -> StringName:
	var scene := get_tree().current_scene
	var id: Variant = SCREENS.find_key(scene.scene_file_path) if scene else null
	return id if id != null else &""
