@tool
extends Control
class_name EventPanel

# 导出变量，便于在编辑器中调整
@export var panel_texture: Texture2D : set = set_panel_texture
@export_enum("Fit:保持比例适应", "Fill:保持比例填满", "Center:居中原始大小") 
var texture_fit_mode: int = 0 : set = set_texture_fit_mode
@export var texture_padding: Vector2 = Vector2(40, 100) # 纹理周围的额外空间，用于标题和内容
@export var min_panel_size: Vector2 = Vector2(200, 300)
@export var max_panel_size: Vector2 = Vector2(500, 800)
@export var card_container_margin: int = 20 : set = set_card_container_margin

# 节点引用
@onready var event_frame: TextureRect = $EventFrame
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var card_container: VBoxContainer = $ScrollContainer/CardContainer

# 信号
signal panel_clicked
signal size_changed(new_size)

# 卡片管理
var event_cards = [] # 当前面板中的事件卡片

# 编辑器设置跟踪
var _editor_positions_initialized = false
var _editor_container_position: Vector2
var _editor_container_size: Vector2

# 用于保存编辑器设置的变量
var _editor_card_container_custom_minimum_size: Vector2
var _editor_card_container_size_flags_vertical: int
var _editor_card_container_size_flags_horizontal: int

func _init():
	# 连接尺寸变化信号
	resized.connect(_on_panel_resized)

func _ready():
	# 连接信号
	if event_frame and not event_frame.gui_input.is_connected(_on_event_frame_input):
		event_frame.gui_input.connect(_on_event_frame_input)
	
	# 应用初始属性
	_apply_properties()
	
	# 确保纹理显示正确
	_update_texture_display()
	
	# 检查纹理是否已设置
	if Engine.is_editor_hint():
		if not panel_texture:
			print("警告: 事件面板 ", name, " 未设置纹理")
	elif not Engine.is_editor_hint():
		# 游戏运行时
		if not panel_texture:
			printerr("错误: 运行时事件面板 ", name, " 未设置纹理!")
	
	# 保存卡片容器设置
	if card_container:
		# 保存编辑器中的设置
		_editor_card_container_custom_minimum_size = card_container.custom_minimum_size
		_editor_card_container_size_flags_vertical = card_container.size_flags_vertical
		_editor_card_container_size_flags_horizontal = card_container.size_flags_horizontal
		
		# 在_ready中保存编辑器设置的位置和大小
		if not _editor_positions_initialized:
			_editor_container_position = card_container.position
			_editor_container_size = card_container.size
			_editor_positions_initialized = true
			print("已保存编辑器设置的CardContainer - 位置:", _editor_container_position, 
				 "大小:", _editor_container_size,
				 "最小大小:", _editor_card_container_custom_minimum_size,
				 "水平大小标志:", _editor_card_container_size_flags_horizontal,
				 "垂直大小标志:", _editor_card_container_size_flags_vertical)
	
	# 设置卡片容器边距
	set_card_container_margin(card_container_margin)
	
	# 隐藏滚动条但保留滚动功能
	if scroll_container:
		scroll_container.vertical_scroll_mode = 3

# 处理尺寸变化事件
func _on_panel_resized():
	_update_texture_display()
	
	# 发送大小改变信号
	size_changed.emit(size)

# 更新纹理显示
func _update_texture_display():
	if not event_frame or not panel_texture:
		return
		
	match texture_fit_mode:
		0: # Fit - 保持比例完全适应
			event_frame.stretch_mode = 5 # STRETCH_KEEP_ASPECT_CENTERED
			event_frame.expand_mode = 2  # EXPAND_IGNORE_SIZE
		1: # Fill - 保持比例填满(可能裁剪)
			event_frame.stretch_mode = 6 # STRETCH_KEEP_ASPECT_COVERED
			event_frame.expand_mode = 2  # EXPAND_IGNORE_SIZE
		2: # Center - 居中原始大小
			event_frame.stretch_mode = 3 # STRETCH_KEEP_CENTERED
			event_frame.expand_mode = 0  # EXPAND_NONE

# 属性设置器
func set_panel_texture(texture: Texture2D):
	panel_texture = texture
	if event_frame:
		event_frame.texture = texture
		_update_texture_display()

func set_texture_fit_mode(mode: int):
	texture_fit_mode = mode
	_update_texture_display()

# 新增函数: 计算合适的卡片容器高度以显示3张卡片
func _calculate_container_height_for_three_cards():
	# 单个卡片高度 + 卡片间距 × 2 (两个间隔) + 上下边距
	var card_height = 110                # 与base_event_card.gd中的card_min_height一致
	var separation = 10                  # 卡片间距
	var total_separation = separation * 2  # 2个间隔
	var container_padding = card_container_margin * 2  # 上下边距
	
	return card_height * 3 + total_separation + container_padding

# 新增函数: 计算合适的卡片容器高度以显示4张卡片
func _calculate_container_height_for_four_cards():
	# 单个卡片高度 + 卡片间距 × 3 (三个间隔) + 上下边距
	var card_height = 110                # 与base_event_card.gd中的card_min_height一致
	var separation = 10                  # 卡片间距
	var total_separation = separation * 3  # 3个间隔（4个卡片间有3个间隔）
	var container_padding = card_container_margin * 2  # 上下边距
	
	return card_height * 4 + total_separation + container_padding

# 修改set_card_container_margin函数
func set_card_container_margin(value: int):
	card_container_margin = value
	
	if not card_container:
		return
		
	# 在编辑器中，优先使用保存的编辑器设置
	if Engine.is_editor_hint():
		# 如果这是第一次设置，保存编辑器中的初始位置和大小
		if not _editor_positions_initialized:
			_editor_container_position = card_container.position
			_editor_container_size = card_container.size
			_editor_card_container_custom_minimum_size = card_container.custom_minimum_size
			_editor_card_container_size_flags_vertical = card_container.size_flags_vertical
			_editor_card_container_size_flags_horizontal = card_container.size_flags_horizontal
			
			_editor_positions_initialized = true
			print("编辑器中保存CardContainer设置 - 位置:", _editor_container_position, 
				  "大小:", _editor_container_size,
				  "最小大小:", _editor_card_container_custom_minimum_size)
	else:
		# 运行时，使用card_container_margin属性设置边距
		# 但尊重编辑器中设置的其他属性
		var offset = value
		
		# 应用保存的编辑器设置
		if _editor_positions_initialized:
			# 保持编辑器中设置的大小标志
			card_container.size_flags_horizontal = _editor_card_container_size_flags_horizontal
			card_container.size_flags_vertical = _editor_card_container_size_flags_vertical
			
			# 使用保存的编辑器位置，但应用当前边距
			card_container.position = _editor_container_position
			
			# 计算容器高度以正好容纳4张卡片
			var container_height = _calculate_container_height_for_four_cards()
			card_container.size.y = container_height
			card_container.size.x = _editor_container_size.x
			
			# 设置卡片间距
			if card_container is VBoxContainer:
				card_container.add_theme_constant_override("separation", 10)
		else:
			# 如果没有保存过编辑器设置，使用默认边距
			card_container.position = Vector2(offset, offset)
			card_container.size = Vector2(size.x - offset * 2, _calculate_container_height_for_four_cards())
			
			# 设置卡片间距
			if card_container is VBoxContainer:
				card_container.add_theme_constant_override("separation", 10)
		
		print("运行时设置CardContainer - 位置:", card_container.position, "大小:", card_container.size)

# 应用所有属性
func _apply_properties():
	if event_frame:
		event_frame.texture = panel_texture

# 处理事件框架的输入事件
func _on_event_frame_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		panel_clicked.emit()

# === 事件卡片管理基础设施 ===

# 添加事件卡片
func add_event_card(event_data, card_type: String = "character"):
	if event_data == null:
		return null
		
	# 记录事件数据用于调试
	print("添加事件卡片: ", event_data, " 类型: ", card_type)
	
	var card = null
	
	# 检查是否已经是BaseEventCard实例
	if event_data is BaseEventCard:
		card = event_data
	else:
		# 使用工厂创建卡片
		card = EventCardFactory.create_card(card_type)
		if card == null:
			return null
			
		# 初始化卡片内容
		EventCardFactory.initialize_card(card, event_data)
	
	# 将卡片添加到容器
	if card_container:
		card_container.add_child(card)
	
	# 连接卡片点击信号
	if card.has_signal("card_clicked") and not card.card_clicked.is_connected(_on_card_clicked):
		card.card_clicked.connect(_on_card_clicked.bind(card))
	
	# 将卡片添加到事件卡片列表
	event_cards.append(card)
	
	return card

# 清除所有事件卡片
func clear_event_cards():
	# 清除事件卡片记录
	event_cards.clear()
	
	# 清除容器中的子节点
	if card_container:
		for child in card_container.get_children():
			child.queue_free()
	
	print("已清除所有事件卡片")

# 显示空状态（无事件时）
func show_empty_state(message: String = ""):
	# 清除所有卡片
	clear_event_cards()
	
	# 当前无需显示任何特定的空状态UI
	# 未来可能会添加一个空状态的视觉指示
	print("事件面板显示空状态: ", message if message else "无事件")
	
# 修改create_sample_event_cards函数
func create_sample_event_cards(count: int = 3, card_type: String = "character"):
	# 清除现有卡片
	clear_event_cards()
	
	print("开始创建 ", count, " 个样本", card_type, "卡片...")
	
	# 创建几个样本事件卡片
	var sample_events = [
		{
			"title": "一个人的会议室",
			"character": "天笑",
			"status": "dealing",  # 处理中
			"texture_path": "res://assets/character/bosstrans.png",
			"region_enabled": true,
			"region_y_position": 0.0,  # 顶部
			"region_height": 0.45
		},
		{
			"title": "客户投诉处理",
			"character": "员工",
			"status": "new",  # 新消息
			"texture_path": "res://assets/character/maincharacter_trans.png",
			"region_enabled": true,
			"region_y_position": 0.0,  # 顶部
			"region_height": 0.45
		},
		{
			"title": "部门预算审批",
			"character": "老板",
			"status": "dealing",  # 处理中
			"texture_path": "res://assets/character/bosstrans.png",
			"region_enabled": true,
			"region_y_position": 0.0,  # 顶部
			"region_height": 0.45
		}
	]
	
	# 确保有足够的样本数据
	while sample_events.size() < count:
		# 添加重复的样本事件
		var base_index = sample_events.size() % 3
		var new_sample = sample_events[base_index].duplicate()
		new_sample.title = new_sample.title + " " + str(sample_events.size() + 1)
		sample_events.append(new_sample)
	
	# 根据请求的数量创建卡片
	for i in range(count):
		var event_data = sample_events[i]
		
		print("创建卡片 #", i+1, ":", event_data.title)
		
		# 使用add_event_card添加卡片
		add_event_card(event_data, card_type)
	
	print("已创建 ", event_cards.size(), " 个样本事件卡片")

# 卡片点击处理
func _on_card_clicked(card):
	print("卡片被点击: ", card.event_title) 

# 静态方法：创建完整配置的测试事件面板实例
static func create_test_panel(panel_size: Vector2 = Vector2(320, 500)) -> EventPanel:
	# 实例化事件面板场景
	var panel_scene = load("res://scenes/workday_new/components/event_panel.tscn")
	var panel = panel_scene.instantiate()
	
	# 设置面板大小
	panel.size = panel_size
	panel.custom_minimum_size = panel_size
	
	# 加载面板纹理
	var panel_texture = load("res://assets/workday_new/ui/events/character.png")
	if panel_texture:
		panel.panel_texture = panel_texture
	
	# 配置面板选项
	panel.texture_fit_mode = 0  # Fit - 保持比例适应
	panel.card_container_margin = 20
	
	# 创建样本事件卡片来测试布局
	# 注意：需要在面板添加到场景树后调用
	# panel.create_sample_event_cards()
	
	return panel 
