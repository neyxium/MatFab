extends Node

@onready var world_view: WorldView = $WorldView
@onready var hud: Hud = $UiLayer/Hud
@onready var action_bar: ActionBar = $UiLayer/ActionBar
@onready var preview_buttons: PreviewButtons = $UiLayer/PreviewButtons
@onready var pause_menu: PauseMenu = $UiLayer/PauseMenu
@onready var level_complete: LevelComplete = $UiLayer/LevelComplete
@onready var tutorial_panel: TutorialPanel = $UiLayer/TutorialPanel
@onready var block_info_menu: BlockInfoMenu = $UiLayer/BlockInfoMenu


func _ready() -> void:
	world_view.show_sim(Game.sim, Game.clock, Game.level.buildable)
	hud.show_goals(Game.sim.tracker)
	hud.show_timer(Game.level.target_time, Game.best_times.get(Game.level.id, -1.0))
	hud.update_timer(Game.elapsed_time)
	hud.show_cost(Game.level.par_cost)
	hud.update_cost(Game.sim.build_cost())
	hud.show_toolbar(world_view.build_tool)
	hud.set_speed(Game.sim_speed)
	hud.pause_pressed.connect(pause)
	hud.info_pressed.connect(open_info)
	hud.speed_changed.connect(_on_speed_changed)
	block_info_menu.close_pressed.connect(close_info)
	action_bar.show_tool(world_view.build_tool, Registry.controls_sorted)
	preview_buttons.show_tool(world_view.build_tool, world_view.camera_rig)
	pause_menu.resume_pressed.connect(resume)
	pause_menu.main_menu_pressed.connect(Game.open.bind(&"main_menu"))
	pause_menu.settings_pressed.connect(Game.open.bind(&"settings"))
	level_complete.main_menu_pressed.connect(Game.open.bind(&"main_menu"))
	level_complete.restart_pressed.connect(Game.restart_level)
	Game.level_completed.connect(_on_level_completed)
	# The tutorial starts over on every visit; Preskoči hides it.
	tutorial_panel.show_tutorial(Game.level.tutorial, Game.sim, world_view.build_tool)
	if Game.sim.tracker.is_complete():
		_on_level_completed()
	elif Game.paused:
		pause_menu.show()


func _process(_delta: float) -> void:
	hud.update_timer(Game.elapsed_time)
	# Leaving to the menu clears the sim a frame before this scene goes away.
	if Game.sim != null:
		hud.update_cost(Game.sim.build_cost())


func _on_speed_changed(speed: float) -> void:
	Game.sim_speed = speed


func _on_level_completed() -> void:
	var best: float = Game.best_times.get(Game.level.id, -1.0)
	hud.show_timer(Game.level.target_time, best)
	hud.update_timer(Game.elapsed_time)
	# Reopening a level finished earlier rates the saved world, since last_result may belong to another level.
	var result := Game.last_result if Game.last_result.get("id") == Game.level.id else Game.current_result()
	level_complete.show_result(result, Game.level, best, Game.best_cost.get(Game.level.id, -1))
	level_complete.show()
	tutorial_panel.hide()


# Back drops the tool or selection first; with neither, it opens the pause menu, and from there resumes.
func go_back() -> void:
	if level_complete.visible:
		Game.open(&"main_menu")
	elif block_info_menu.visible:
		close_info()
	elif pause_menu.visible:
		resume()
	elif not world_view.build_tool.cancel():
		pause()


func pause() -> void:
	world_view.build_tool.cancel_gesture()
	Game.paused = true
	pause_menu.show()


func resume() -> void:
	Game.paused = false
	pause_menu.hide()


# The Info window shows details for the currently selected block; the sim waits while it is open.
func open_info() -> void:
	var def := hud.current_info_def()
	if def == null:
		return
	world_view.build_tool.cancel_gesture()
	Game.paused = true
	block_info_menu.show_block(def)


func close_info() -> void:
	Game.paused = false
	block_info_menu.hide()


# Editor-only debug shortcuts: Alt+1 (+1 current goal), Alt+2 (complete current goal), Alt+3 (complete level).
func _input(event: InputEvent) -> void:
	if not OS.has_feature("editor") or Game.sim == null or Game.sim.tracker == null:
		return
	if not (event is InputEventKey and event.pressed and not event.echo and event.alt_pressed):
		return
	var tracker := Game.sim.tracker
	match event.physical_keycode:
		KEY_1, KEY_KP_1:
			if not tracker.is_complete():
				tracker.receive(tracker.current_goal())
			get_viewport().set_input_as_handled()
		KEY_2, KEY_KP_2:
			if not tracker.is_complete():
				var goal := tracker.current_goal()
				for _i in tracker.goals[goal] - tracker.progress(goal):
					tracker.receive(goal)
			get_viewport().set_input_as_handled()
		KEY_3, KEY_KP_3:
			while not tracker.is_complete():
				tracker.receive(tracker.current_goal())
			get_viewport().set_input_as_handled()
