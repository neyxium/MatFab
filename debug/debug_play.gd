extends Node

const LEVEL_ID := &"r1_01"

var sim: Simulation
var clock := SimClock.new()

@onready var world_view: WorldView = $WorldView
@onready var hud: Hud = $UiLayer/Hud
@onready var action_bar: ActionBar = $UiLayer/ActionBar
@onready var preview_buttons: PreviewButtons = $UiLayer/PreviewButtons


func _ready() -> void:
	var level: LevelDef = Registry.levels[LEVEL_ID]
	sim = Simulation.from_level(level, Registry.buildings)
	world_view.show_sim(sim, clock, level.buildable)
	hud.show_goals(sim.tracker)
	hud.show_toolbar(world_view.build_tool)
	action_bar.show_tool(world_view.build_tool, Registry.controls_sorted)
	preview_buttons.show_tool(world_view.build_tool, world_view.camera_rig)


func _process(delta: float) -> void:
	for step in clock.advance(delta):
		sim.step()


# Editor-only debug shortcuts: Alt+1 (+1 current goal), Alt+2 (completa ceu goal), Alt+3 (completa level).
func _input(event: InputEvent) -> void:
	if not OS.has_feature("editor") or sim == null or sim.tracker == null:
		return
	if not (event is InputEventKey and event.pressed and not event.echo and event.alt_pressed):
		return
	var tracker := sim.tracker
	match event.physical_keycode:
		KEY_1, KEY_KP_1:
			var goal := tracker.current_goal()
			if goal != -1:
				tracker.receive(goal)
			get_viewport().set_input_as_handled()
		KEY_2, KEY_KP_2:
			var goal := tracker.current_goal()
			if goal != -1:
				for _i in tracker.goals[goal] - tracker.progress(goal):
					tracker.receive(goal)
			get_viewport().set_input_as_handled()
		KEY_3, KEY_KP_3:
			while not tracker.is_complete():
				tracker.receive(tracker.current_goal())
			get_viewport().set_input_as_handled()
