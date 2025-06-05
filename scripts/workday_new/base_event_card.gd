@tool
extends PanelContainer
class_name BaseEventCard

# 内容相关导出变量
@export_group("内容")
@export var event_title: String = "事件标题" : set = set_event_title
@export var event_status: String = "new" : set = set_event_status  # "new" 或 "dealing"

# 布局属性组
@export_group("布局")
@export var card_min_height: int = 110 : set = set_card_min_height
@export var card_min_width: int = 350 : set = set_card_min_width
@export var title_font_size: int = 18 : set = set_title_font_size
@export var status_icon_size: Vector2 = Vector2(60, 28) : set = set_status_icon_size

# 资源引用
var new_status_texture = preload("res://assets/workday_new/ui/events/new.png")
var dealing_status_texture = preload("res://assets/workday_new/ui/events/dealing.png")

# 游戏事件引用
var game_event: GameEvent = null

# 节点引用
@onready var _base_title_label = $HBoxContainer/RightSection/TopInfo/EventTitle
@onready var _base_status_icon = $HBoxContainer/RightSection/BottomInfo/StatusIcon

# 信号
signal card_clicked

func _ready():
	# 连接信号
	gui_input.connect(_on_gui_input)
	
	# 应用布局属性
	_apply_layout_properties()
	
	# 应用内容属性
	_apply_content_properties()

# 布局属性的setter函数
func set_card_min_height(value: int):
	card_min_height = value
	custom_minimum_size.y = value
	queue_redraw()

func set_card_min_width(value: int):
	card_min_width = value
	custom_minimum_size.x = value
	queue_redraw()

func set_title_font_size(value: int):
	title_font_size = value
	_update_title_font_size(value)
	queue_redraw()

func _update_title_font_size(value: int):
	if is_instance_valid(_base_title_label):
		_base_title_label.add_theme_font_size_override("font_size", value)

func set_status_icon_size(value: Vector2):
	status_icon_size = value
	_update_status_icon_size(value)
	queue_redraw()

func _update_status_icon_size(value: Vector2):
	if is_instance_valid(_base_status_icon):
		_base_status_icon.custom_minimum_size = value
		
		# 确保状态图标在右下角
		var parent = $HBoxContainer/RightSection/BottomInfo
		if parent:
			_base_status_icon.anchor_right = 1.0
			_base_status_icon.anchor_bottom = 1.0
			_base_status_icon.grow_horizontal = 0  # 向左增长
			_base_status_icon.grow_vertical = 0    # 向上增长
			_base_status_icon.offset_right = 0     # 右边缘对齐
			_base_status_icon.offset_bottom = 0    # 底边缘对齐

# 内容属性setter函数
func set_event_title(text: String):
	event_title = text
	_update_event_title(text)

func _update_event_title(text: String):
	if is_instance_valid(_base_title_label):
		_base_title_label.text = text

func set_event_status(status: String):
	event_status = status
	_update_event_status(status)

func _update_event_status(status: String):
	if is_instance_valid(_base_status_icon):
		if status == "new":
			_base_status_icon.texture = new_status_texture
		else:
			_base_status_icon.texture = dealing_status_texture

# 布局属性应用函数
func _apply_layout_properties():
	# 在编辑器和运行时都应用布局
	set_card_min_height(card_min_height)
	set_card_min_width(card_min_width)
	set_title_font_size(title_font_size)
	set_status_icon_size(status_icon_size)

# 内容属性应用函数
func _apply_content_properties():
	# 设置事件标题
	set_event_title(event_title)
	
	# 设置事件状态
	set_event_status(event_status)

# 点击事件处理
func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_clicked.emit()

# 获取卡片类型
func get_card_type() -> String:
	return "base" 

# 游戏事件相关方法
func set_game_event(event: GameEvent):
	game_event = event

func get_game_event() -> GameEvent:
	return game_event

# 统一状态访问接口
func get_completion_status() -> bool:
	# 基础实现：根据event_status判断完成状态
	return event_status == "dealing"

func set_completion_status(completed: bool):
	# 基础实现：设置event_status
	if completed:
		set_event_status("dealing")
	else:
		set_event_status("new")

func get_status_description() -> String:
	# 返回状态描述，用于调试
	return "event_status: " + event_status + " (completed: " + str(get_completion_status()) + ")" 
