extends PanelContainer
class_name WeekendRandomEventCard

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
@export var title_font_size: int = 32 : set = set_title_font_size

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
	
	# 连接EventManager信号
	_connect_event_manager_signals()
	
	# 应用样式和内容
	_apply_style()
	_apply_content()
	_update_textures()
	
	print("WeekendRandomEventCard就绪: ", event_title)

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

# 更新纹理和状态显示
func _update_textures():
	if not is_instance_valid(background_image):
		return
	
	# 更新背景图片（基于当前is_completed状态）
	if is_completed:
		background_image.texture = random_done_texture
		print("WeekendRandomEventCard: 设置背景为完成状态 - random_done_texture")
	else:
		background_image.texture = random_undo_texture
		print("WeekendRandomEventCard: 设置背景为未完成状态 - random_undo_texture")
	
	# 更新状态数字显示（仅显示逻辑）
	_update_status_number()

# 更新状态数字显示（仅显示逻辑，不修改状态）
func _update_status_number(force_event_manager_check: bool = false):
	if not game_event or not status_icon:
		return
	
	var display_completed = is_completed
	
	# 可选：检查EventManager状态用于显示
	if force_event_manager_check:
		var event_manager = get_node_or_null("/root/EventManager")
		if event_manager:
			display_completed = event_manager.is_event_completed(game_event.event_id)
			print("WeekendRandomEventCard: 使用EventManager状态进行显示 - ", display_completed)
	
	print("WeekendRandomEventCard: 状态显示检查 - 事件ID:", game_event.event_id, " 显示状态:", display_completed)
	print("WeekendRandomEventCard: 数据检查 - duration_rounds:", game_event.duration_rounds, " valid_rounds:", game_event.valid_rounds)
	
	# 仅更新显示内容，不修改卡片状态
	if display_completed:
		# 事件已完成，显示持续回合数
		var duration_text = str(game_event.duration_rounds)
		status_icon.text = duration_text
		print("WeekendRandomEventCard: 显示完成状态，duration_rounds:", duration_text)
	else:
		# 事件未处理，显示有效回合数
		var valid_text = ""
		if game_event.valid_rounds.size() > 0:
			# 显示第一个有效回合
			valid_text = str(game_event.valid_rounds[0])
		else:
			# 如果没有指定有效回合，显示"全部"
			valid_text = "全部"
		
		status_icon.text = valid_text
		print("WeekendRandomEventCard: 显示未完成状态，valid_rounds:", valid_text)

# 与EventManager同步状态（独立的同步逻辑）
func _sync_with_event_manager():
	if not game_event:
		print("WeekendRandomEventCard: 无game_event，跳过同步")
		return
	
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		print("⚠ WeekendRandomEventCard: EventManager未找到，无法同步状态")
		return
	
	var manager_completed = event_manager.is_event_completed(game_event.event_id)
	print("WeekendRandomEventCard: 状态同步检查 - 当前卡片状态:", is_completed, " EventManager状态:", manager_completed)
	
	if manager_completed != is_completed:
		print("WeekendRandomEventCard: 检测到状态不一致，进行同步: ", is_completed, " -> ", manager_completed)
		print("WeekendRandomEventCard: 事件", game_event.event_id, "(", game_event.event_name, ") 状态同步")
		
		# 先设置状态
		set_completed(manager_completed)
		
		# 验证背景图片是否正确设置
		if is_instance_valid(background_image):
			var expected_texture = random_done_texture if manager_completed else random_undo_texture
			var actual_texture = background_image.texture
			print("WeekendRandomEventCard: 背景纹理验证")
			print("  期望纹理: ", expected_texture)
			print("  实际纹理: ", actual_texture)
			print("  纹理匹配: ", actual_texture == expected_texture)
			
			# 如果纹理不匹配，强制更新
			if actual_texture != expected_texture:
				print("⚠ WeekendRandomEventCard: 背景纹理不匹配，强制更新")
				background_image.texture = expected_texture
				print("✓ WeekendRandomEventCard: 强制设置背景纹理为: ", expected_texture)
		
		print("✓ WeekendRandomEventCard: 状态同步完成")
	else:
		print("✓ WeekendRandomEventCard: 状态已一致，无需同步")

# 处理点击事件
func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("WeekendRandomEventCard点击: ", event_title)
			card_clicked.emit()
			
			# 如果有关联的游戏事件，发送更详细的信号
			if game_event:
				# 可以添加更具体的事件处理逻辑
				pass

# 游戏事件管理方法
func set_game_event(event: GameEvent) -> void:
	game_event = event
	print("WeekendRandomEventCard: 设置game_event - ", event.event_name if event else "null")
	
	# 连接EventManager信号（确保在设置事件时信号已连接）
	_connect_event_manager_signals()
	
	# 检查并同步初始完成状态
	if event:
		print("WeekendRandomEventCard: 开始初始状态同步...")
		# 使用新的状态同步方法
		call_deferred("_sync_with_event_manager")
	else:
		set_completed(false)
		print("WeekendRandomEventCard: 无事件，设置为默认未完成状态")

func get_game_event() -> GameEvent:
	return game_event

# 获取卡片类型
func get_card_type() -> String:
	return "weekend_random"

# 统一状态访问接口实现
func get_completion_status() -> bool:
	# WeekendRandomEventCard使用is_completed管理状态
	return is_completed

func set_completion_status(completed: bool):
	# 使用现有的set_completed方法
	set_completed(completed)

func get_status_description() -> String:
	# 返回详细状态描述，用于调试
	var event_id = game_event.event_id if game_event else -1
	var event_name = game_event.event_name if game_event else "null"
	return "WeekendRandomEventCard[" + str(event_id) + ":" + event_name + "] is_completed: " + str(is_completed) + " (completed: " + str(get_completion_status()) + ")"

# 从GameEvent初始化卡片
func initialize_from_game_event(event: GameEvent):
	if not event:
		return
	
	set_game_event(event)
	set_event_title(event.event_name)
	
	# set_game_event已经会检查并设置正确的初始完成状态，无需再次强制设置
	
	print("WeekendRandomEventCard: 从GameEvent初始化完成 - ", event.event_name)

# 连接EventManager信号
func _connect_event_manager_signals():
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		print("⚠ WeekendRandomEventCard: EventManager未找到，无法连接信号")
		return
	
	if not event_manager.event_completed.is_connected(_on_event_completed):
		event_manager.event_completed.connect(_on_event_completed)
		print("WeekendRandomEventCard: 已连接EventManager的event_completed信号")

# 处理事件完成信号
func _on_event_completed(event_id: int):
	print("WeekendRandomEventCard: 收到事件完成信号 - event_id:", event_id)
	
	if not game_event:
		print("WeekendRandomEventCard: 无game_event，忽略信号")
		return
		
	if game_event.event_id == event_id:
		print("WeekendRandomEventCard: 信号匹配当前事件，开始状态同步")
		print("WeekendRandomEventCard: 当前状态 - ", get_status_description())
		
		# 使用独立的状态同步方法
		_sync_with_event_manager()
		
		print("WeekendRandomEventCard: 更新后状态 - ", get_status_description())
		print("WeekendRandomEventCard: 事件完成处理完毕 - ", event_id)
	else:
		print("WeekendRandomEventCard: 信号不匹配当前事件 (当前:", game_event.event_id, " 信号:", event_id, ")") 