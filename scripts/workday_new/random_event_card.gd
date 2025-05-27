extends PanelContainer
class_name RandomEventCard

# 内容属性
@export_group("内容")
@export var event_title: String = "随机事件标题" : set = set_event_title
@export var is_completed: bool = false : set = set_completed
@export var game_event: GameEvent

# 样式属性
@export_group("样式")
@export var border_color: Color = Color(0.7, 0.7, 0.7, 1.0) : set = set_border_color
@export var corner_radius: int = 8 : set = set_corner_radius
@export var border_width: int = 2 : set = set_border_width
@export var title_font_size: int = 24 : set = set_title_font_size

# 节点引用
@onready var background_image = $CardContent/BackgroundImage
@onready var status_icon = $CardContent/StatusIcon
@onready var title_label = $CardContent/EventTitle

# 资源引用
var random_undo_texture = preload("res://assets/workday_new/ui/events/random_undo.png")
var random_done_texture = preload("res://assets/workday_new/ui/events/random_done.png")
var random_undo_icon_texture = preload("res://assets/workday_new/ui/events/random_undo_icon.png")
var random_done_icon_texture = preload("res://assets/workday_new/ui/events/random_done_icon.png")

# 信号
signal card_clicked

func _ready():
	# 确保卡片能接收点击事件
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 设置CardContent容器忽略鼠标事件，让事件传播到父容器
	if has_node("CardContent"):
		get_node("CardContent").mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 设置所有子节点忽略鼠标事件，让事件传播到父容器
	if background_image:
		background_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if status_icon:
		status_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if title_label:
		title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 连接信号
	gui_input.connect(_on_gui_input)
	
	# 应用样式和内容
	_apply_style()
	_apply_content()
	_update_textures()
	
	print("RandomEventCard就绪: ", event_title)

# 内容属性更新方法
func set_event_title(text: String):
	event_title = text
	if is_instance_valid(title_label):
		title_label.text = text

func set_completed(completed: bool):
	is_completed = completed
	_update_textures()

# 样式属性更新方法
func set_border_color(color: Color):
	border_color = color
	_apply_style()

func set_corner_radius(radius: int):
	corner_radius = radius
	_apply_style()

func set_border_width(width: int):
	border_width = width
	_apply_style()

func set_title_font_size(size: int):
	title_font_size = size
	if is_instance_valid(title_label):
		title_label.add_theme_font_size_override("font_size", size)

# 应用样式
func _apply_style():
	var style_box = get_theme_stylebox("panel")
	if style_box is StyleBoxFlat:
		style_box.border_color = border_color
		style_box.corner_radius_top_left = corner_radius
		style_box.corner_radius_top_right = corner_radius
		style_box.corner_radius_bottom_left = corner_radius
		style_box.corner_radius_bottom_right = corner_radius
		style_box.border_width_left = border_width
		style_box.border_width_top = border_width
		style_box.border_width_right = border_width
		style_box.border_width_bottom = border_width

# 应用内容
func _apply_content():
	if is_instance_valid(title_label):
		title_label.text = event_title
		title_label.add_theme_font_size_override("font_size", title_font_size)

# 更新纹理
func _update_textures():
	if not is_instance_valid(background_image) or not is_instance_valid(status_icon):
		return
	
	if is_completed:
		background_image.texture = random_done_texture
		status_icon.texture = random_done_icon_texture
	else:
		background_image.texture = random_undo_texture
		status_icon.texture = random_undo_icon_texture

# 处理点击事件
func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("RandomEventCard点击: ", event_title)
			card_clicked.emit()
			
			# 如果有关联的游戏事件，发送更详细的信号
			if game_event:
				# 可以添加更具体的事件处理逻辑
				pass

# 游戏事件管理方法
func set_game_event(event: GameEvent) -> void:
	game_event = event
	print("RandomEventCard: 设置game_event - ", event.event_name if event else "null")

func get_game_event() -> GameEvent:
	return game_event

# 获取卡片类型
func get_card_type() -> String:
	return "random"

# 从GameEvent初始化卡片
func initialize_from_game_event(event: GameEvent):
	if not event:
		return
	
	set_game_event(event)
	set_event_title(event.event_name)
	
	# 根据事件状态设置完成状态（这里可以根据实际需求调整）
	set_completed(false)  # 默认为未完成
	
	print("RandomEventCard: 从GameEvent初始化完成 - ", event.event_name) 