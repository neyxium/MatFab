class_name LevelComplete extends OverlayMenu

signal main_menu_pressed
signal restart_pressed

const TIME_FONT_SIZE := 24

var time_label: Label


func _ready() -> void:
	add_title("Stopnja opravljena")
	time_label = Label.new()
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", TIME_FONT_SIZE)
	items.add_child(time_label)
	add_button("Začni znova", restart_pressed.emit)
	add_button("Glavni meni", main_menu_pressed.emit)


func show_time(elapsed: float, best: float, target: float) -> void:
	var lines: PackedStringArray = ["Čas: %s" % Game.format_time(elapsed)]
	if best >= 0.0:
		lines.append("Najboljši čas: %s" % Game.format_time(best))
	if target > 0.0:
		var status := "v ciljnem času!" if elapsed <= target else "čez ciljni čas"
		lines.append("Ciljni čas: %s (%s)" % [Game.format_time(target), status])
	time_label.text = "\n".join(lines)
