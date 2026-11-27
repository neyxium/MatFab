class_name BlockInfoMenu extends Control

signal close_pressed

const NUMBER_COLOR := Color("3f86c7")
const ORE_COLOR := Color("7a5a38")

@onready var block_icon: TextureRect = $Root/Scroll/CenterMargin/ContentCenter/Content/BlockHeader/BlockIcon
@onready var block_symbol: Label = $Root/Scroll/CenterMargin/ContentCenter/Content/BlockHeader/BlockSymbol
@onready var block_name: Label = $Root/Scroll/CenterMargin/ContentCenter/Content/BlockHeader/BlockName
@onready var purpose_section: VBoxContainer = $Root/Scroll/CenterMargin/ContentCenter/Content/PurposeSection
@onready var description_label: Label = $Root/Scroll/CenterMargin/ContentCenter/Content/PurposeSection/DescriptionLabel
@onready var size_label: Label = $Root/Scroll/CenterMargin/ContentCenter/Content/GeneralSection/SizeLabel
@onready var io_section: VBoxContainer = $Root/Scroll/CenterMargin/ContentCenter/Content/IoSection
@onready var input_row: HBoxContainer = $Root/Scroll/CenterMargin/ContentCenter/Content/IoSection/InputRow
@onready var input_icon: PanelContainer = $Root/Scroll/CenterMargin/ContentCenter/Content/IoSection/InputRow/InputIcon
@onready var input_glyph: Label = $Root/Scroll/CenterMargin/ContentCenter/Content/IoSection/InputRow/InputIcon/Glyph
@onready var input_name: Label = $Root/Scroll/CenterMargin/ContentCenter/Content/IoSection/InputRow/InputInfo/InputName
@onready var input_rate: Label = $Root/Scroll/CenterMargin/ContentCenter/Content/IoSection/InputRow/InputInfo/InputRate
@onready var output_row: HBoxContainer = $Root/Scroll/CenterMargin/ContentCenter/Content/IoSection/OutputRow
@onready var output_icon: PanelContainer = $Root/Scroll/CenterMargin/ContentCenter/Content/IoSection/OutputRow/OutputIcon
@onready var output_glyph: Label = $Root/Scroll/CenterMargin/ContentCenter/Content/IoSection/OutputRow/OutputIcon/Glyph
@onready var output_name: Label = $Root/Scroll/CenterMargin/ContentCenter/Content/IoSection/OutputRow/OutputInfo/OutputName
@onready var output_rate: Label = $Root/Scroll/CenterMargin/ContentCenter/Content/IoSection/OutputRow/OutputInfo/OutputRate
@onready var craft_time_label: Label = $Root/Scroll/CenterMargin/ContentCenter/Content/CraftTimeLabel
@onready var close_button: Button = $Root/FooterMargin/CloseButton


func _ready() -> void:
	close_button.pressed.connect(close_pressed.emit)
	var symbol_box := _badge_style(BuildingView.FILL_COLOR, false)
	symbol_box.border_color = BuildingView.BORDER_COLOR
	symbol_box.set_border_width_all(2)
	block_symbol.add_theme_stylebox_override("normal", symbol_box)


# Shows universal details for any BuildingDef: icon/name, purpose, grid size, I/O and craft time.
func show_block(def: BuildingDef) -> void:
	block_icon.visible = def.sprite != null
	block_symbol.visible = def.sprite == null
	block_icon.texture = def.sprite
	block_symbol.text = def.symbol
	block_name.text = def.display_name

	purpose_section.visible = not def.description.is_empty()
	description_label.text = def.description
	size_label.text = "Velikost: %dx%d" % [def.size.x, def.size.y]

	var io := _io_summary(def)
	_apply_io_row(input_row, input_icon, input_glyph, input_name, input_rate, io["input"])
	_apply_io_row(output_row, output_icon, output_glyph, output_name, output_rate, io["output"])
	io_section.visible = input_row.visible or output_row.visible

	craft_time_label.visible = def.behavior != BuildingDef.Behavior.MOTHERSHIP and def.duration > 0.0
	craft_time_label.text = "Čas obdelave: %s %s" % [_fmt(def.duration), _seconds_unit(def.duration)]
	show()


func _io_summary(def: BuildingDef) -> Dictionary:
	var rate := (1.0 / def.duration) if def.duration > 0.0 else 0.0
	match def.behavior:
		BuildingDef.Behavior.CONVEYOR:
			return {
				"input": _item_spec("Število", "#", false, rate),
				"output": _item_spec("Število", "#", false, rate),
			}
		BuildingDef.Behavior.MOTHERSHIP:
			return {
				"input": _item_spec("Število", "#", false, -1.0),
				"output": {},
			}
		BuildingDef.Behavior.SPLITTER:
			return {
				"input": _item_spec("Število", "#", false, rate),
				"output": _item_spec("Število (×2)", "#", false, rate),
			}
		BuildingDef.Behavior.MERGER:
			return {
				"input": _item_spec("Število (×2)", "#", false, rate),
				"output": _item_spec("Število", "#", false, rate),
			}
		_:
			var in_count := def.inputs.size()
			var out_count := def.outputs.size()
			var has_ore := def.inputs.any(func(p: PortDef) -> bool: return p.source == PortDef.Source.ORE)
			var in_spec := {}
			if in_count > 0:
				if has_ore:
					in_spec = _item_spec("Ruda", "R", true, rate * in_count)
				else:
					var label := "Število" if in_count == 1 else "Število (×%d)" % in_count
					in_spec = _item_spec(label, "#", false, rate * in_count)
			var out_spec := {}
			if out_count > 0:
				var label := "Število" if out_count == 1 else "Število (×%d)" % out_count
				out_spec = _item_spec(label, "#", false, rate * out_count)
			return {"input": in_spec, "output": out_spec}


func _item_spec(title: String, glyph: String, is_ore: bool, rate: float) -> Dictionary:
	return {"title": title, "glyph": glyph, "is_ore": is_ore, "rate": rate}


func _apply_io_row(
	row: HBoxContainer,
	icon_box: PanelContainer,
	glyph_label: Label,
	name_label: Label,
	rate_label: Label,
	spec: Dictionary
) -> void:
	row.visible = not spec.is_empty()
	if not row.visible:
		return
	var is_ore: bool = spec["is_ore"]
	icon_box.add_theme_stylebox_override("panel", _badge_style(ORE_COLOR if is_ore else NUMBER_COLOR, not is_ore))
	glyph_label.text = spec["glyph"]
	name_label.text = spec["title"]
	var rate: float = spec["rate"]
	rate_label.text = ("%s/sek" % _fmt(rate)) if rate >= 0.0 else "—"


func _badge_style(color: Color, rounded: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(24 if rounded else 6)
	return box


func _fmt(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return str(snappedf(value, 0.01))


func _seconds_unit(value: float) -> String:
	if not is_equal_approx(value, roundf(value)):
		return "sekunde"
	match absi(int(roundf(value))) % 100:
		1:
			return "sekunda"
		2:
			return "sekundi"
		3, 4:
			return "sekunde"
		_:
			return "sekund"
