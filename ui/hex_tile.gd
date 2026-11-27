class_name HexTile extends TextureButton

var level_def: LevelDef

@onready var number_label: Label = $Center/NumberLabel
@onready var title_overlay: Label = $TitleOverlay


func _ready() -> void:
	toggled.connect(_on_toggled)
	title_overlay.resized.connect(_center_title_pivot)


func setup(level: LevelDef, index_number: int) -> void:
	level_def = level
	number_label.text = str(index_number)
	title_overlay.text = level.title
	_center_title_pivot.call_deferred()


func set_zoom(zoom: float) -> void:
	_center_title_pivot()
	title_overlay.scale = Vector2.ONE / zoom


func _center_title_pivot() -> void:
	title_overlay.pivot_offset = title_overlay.size * 0.5


func _on_toggled(on: bool) -> void:
	z_index = 10 if on else 0
	title_overlay.visible = on
	number_label.visible = not on

func _has_point(point: Vector2) -> bool:
	return point.distance_to(size * 0.5) <= size.x * 0.43
