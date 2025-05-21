@tool
extends Control

# 导出变量，允许在编辑器中调整
@export var left_panel_position: Vector2 = Vector2(350, 540) : set = set_left_panel_position
@export var middle_panel_position: Vector2 = Vector2(960, 540) : set = set_middle_panel_position
@export var right_panel_position: Vector2 = Vector2(1570, 540) : set = set_right_panel_position
@export var left_panel_size: Vector2 = Vector2(320, 500) : set = set_left_panel_size
@export var middle_panel_size: Vector2 = Vector2(320, 500) : set = set_middle_panel_size
@export var right_panel_size: Vector2 = Vector2(320, 500) : set = set_right_panel_size

# 面板节点引用
@onready var left_panel: EventPanel = $LeftPanel
@onready var middle_panel: EventPanel = $MiddlePanel
@onready var right_panel: EventPanel = $RightPanel

# 面板纹理
var character_event_texture: Texture2D
var random_event_texture: Texture2D
var daily_event_texture: Texture2D

# 初始化标志
var is_initialized: bool = false

# 预防循环更新的标志
var _updating_positions = false

func _ready():
	if Engine.is_editor_hint():
		# 编辑器内预览，但不重置位置
		_setup_editor_preview_content_only()
	else:
		# 游戏运行时初始化
		_setup_game_panels()
		
		# 连接事件管理器信号
		var event_manager = get_node_or_null("/root/EventManager")
		if event_manager:
			if not event_manager.events_updated.is_connected(_on_events_updated):
				event_manager.events_updated.connect(_on_events_updated)
			# 初始化显示事件
			_on_events_updated()
		
		# 设置输入处理
		set_process_input(true)
		
		# 初始化完成
		is_initialized = true

# 加载事件面板纹理
func _load_textures(store_in_variables: bool = false):
	var char_texture = load("res://assets/workday_new/ui/events/character.png")
	var random_texture = load("res://assets/workday_new/ui/events/random.png") 
	var daily_texture = load("res://assets/workday_new/ui/events/daily.png")
	
	if store_in_variables:
		character_event_texture = char_texture
		random_event_texture = random_texture
		daily_event_texture = daily_texture
	
	# 检查纹理是否成功加载
	if not char_texture:
		printerr("无法加载角色事件纹理!")
	if not random_texture:
		printerr("无法加载随机事件纹理!")
	if not daily_texture:
		printerr("无法加载日常事件纹理!")
	
	return [char_texture, random_texture, daily_texture]

# 连接面板的尺寸变化信号
func _connect_size_change_signals():
	if left_panel and not left_panel.size_changed.is_connected(_on_left_panel_size_changed):
		left_panel.size_changed.connect(_on_left_panel_size_changed)
	
	if middle_panel and not middle_panel.size_changed.is_connected(_on_middle_panel_size_changed):
		middle_panel.size_changed.connect(_on_middle_panel_size_changed)
	
	if right_panel and not right_panel.size_changed.is_connected(_on_right_panel_size_changed):
		right_panel.size_changed.connect(_on_right_panel_size_changed)

# 连接面板的点击信号
func _connect_click_signals():
	if left_panel and not left_panel.panel_clicked.is_connected(_on_left_panel_clicked):
		left_panel.panel_clicked.connect(_on_left_panel_clicked)
	
	if middle_panel and not middle_panel.panel_clicked.is_connected(_on_middle_panel_clicked):
		middle_panel.panel_clicked.connect(_on_middle_panel_clicked)
	
	if right_panel and not right_panel.panel_clicked.is_connected(_on_right_panel_clicked):
		right_panel.panel_clicked.connect(_on_right_panel_clicked)

# 仅设置内容而不重置位置的编辑器预览
func _setup_editor_preview_content_only():
	# 加载纹理
	var textures = _load_textures(false)
	var char_texture = textures[0]
	var random_texture = textures[1]
	var daily_texture = textures[2]
	
	# 连接信号
	_connect_size_change_signals()
	
	# 连接拖动位置变化信号
	_connect_position_change_signals()
	
	# 设置面板纹理
	if left_panel:
		if not left_panel.panel_texture:
			left_panel.panel_texture = char_texture
		left_panel.show_empty_state()
	
	if middle_panel:
		if not middle_panel.panel_texture:
			middle_panel.panel_texture = random_texture
		middle_panel.show_empty_state()
	
	if right_panel:
		if not right_panel.panel_texture:
			right_panel.panel_texture = daily_texture
		right_panel.show_empty_state()

# 游戏面板设置
func _setup_game_panels():
	# 加载纹理并存储到类变量
	_load_textures(true)
	
	# 连接信号
	_connect_size_change_signals()
	_connect_click_signals()
	
	# 设置面板纹理
	if left_panel:
		if character_event_texture:
			left_panel.panel_texture = character_event_texture
		# 清除面板内容，准备后续添加事件卡片
		left_panel.clear_event_cards()
	
	if middle_panel:
		if random_event_texture:
			middle_panel.panel_texture = random_event_texture
		# 清除面板内容，准备后续添加事件卡片
		middle_panel.clear_event_cards()
	
	if right_panel:
		if daily_event_texture:
			right_panel.panel_texture = daily_event_texture
		# 清除面板内容，准备后续添加事件卡片
		right_panel.clear_event_cards()
	
	# 设置面板布局
	_update_all_panel_positions()

# 更新所有面板的位置
func _update_all_panel_positions():
	_set_panel_transforms(left_panel, left_panel_position, left_panel_size)
	_set_panel_transforms(middle_panel, middle_panel_position, middle_panel_size)
	_set_panel_transforms(right_panel, right_panel_position, right_panel_size)

# 设置单个面板的变换
func _set_panel_transforms(panel: EventPanel, center_pos: Vector2, size: Vector2):
	if panel and not _updating_positions:
		_updating_positions = true
		# 计算左上角位置
		var pos = center_pos - size / 2
		panel.position = pos
		panel.size = size
		# 通知面板更新纹理显示
		if panel.has_method("_update_texture_display"):
			panel._update_texture_display()
		_updating_positions = false

# 事件更新回调
func _on_events_updated():
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		return
	
	print("事件已更新，正在刷新面板显示...")
	
	# 获取和显示各类事件数量以便调试
	var character_events = event_manager.get_active_events("character")
	var random_events = event_manager.get_active_events("random")
	var daily_events = event_manager.get_active_events("daily")
	
	print("角色事件数量: ", character_events.size())
	print("随机事件数量: ", random_events.size())
	print("日常事件数量: ", daily_events.size())
	
	# 更新人物事件显示
	update_event_panel("character", left_panel)
	
	# 更新随机事件显示
	update_event_panel("random", middle_panel)
	
	# 更新日常事件显示
	update_event_panel("daily", right_panel)
	
	# 为空的character面板添加样本事件卡片进行UI测试
	if character_events.is_empty() and left_panel:
		print("character面板无可用事件，添加样本事件卡片进行UI测试...")
		left_panel.create_sample_event_cards(3, "character")  # 创建3个人物事件卡片
	
	print("事件面板更新完成")

# 更新特定类别的事件面板
func update_event_panel(category: String, panel: EventPanel):
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager or not panel:
		return
	
	var active_events = event_manager.get_active_events(category)
	
	# 清除现有卡片
	panel.clear_event_cards()
	
	# 如果没有活跃事件，显示空状态
	if active_events.is_empty():
		panel.show_empty_state("当前没有可用的" + get_category_display_name(category))
		return
	
	# 为每个活跃事件创建卡片
	for event in active_events:
		# 将事件对象转换为字典
		var event_data = {
			"title": event.event_name,
			"character": event.event_group_name,
			"status": "new",  # 默认为新消息，可以根据实际状态调整
			"character_texture_path": event.icon_path,
			# 添加默认的区域裁剪设置
			"region_enabled": true,  # 默认启用区域裁剪
			"region_y_position": 0.0,  # 默认使用顶部区域
			"region_height": 0.45      # 默认使用45%高度
		}
		
		# 如果事件中有自定义区域设置，则使用事件中的设置
		if event.has("region_enabled"):
			event_data.region_enabled = event.region_enabled
			
		if event.has("region_y_position"):
			event_data.region_y_position = event.region_y_position
			
		if event.has("region_height"):
			event_data.region_height = event.region_height
		
		# 根据类别创建合适类型的卡片
		panel.add_event_card(event_data, category)
		
	print("已为", category, "面板添加", active_events.size(), "个事件卡片")

# 获取类别显示名称
func get_category_display_name(category: String) -> String:
	match category:
		"character": return "人物事件"
		"random": return "随机事件"
		"daily": return "日常事件"
		_: return "未知事件"

# 面板点击事件处理
func _on_left_panel_clicked():
	print("角色事件被点击")
	# 在这里添加点击处理逻辑

func _on_middle_panel_clicked():
	print("随机事件被点击")
	# 在这里添加点击处理逻辑

func _on_right_panel_clicked():
	print("日常事件被点击")
	# 在这里添加点击处理逻辑

# 保存当前面板布局
func save_panels_layout() -> Dictionary:
	return {
		"left_panel_position": left_panel_position,
		"middle_panel_position": middle_panel_position,
		"right_panel_position": right_panel_position,
		"left_panel_size": left_panel_size,
		"middle_panel_size": middle_panel_size,
		"right_panel_size": right_panel_size
	}

# 加载面板布局
func load_panels_layout(layout: Dictionary):
	if layout.has("left_panel_position") and layout.has("middle_panel_position") and layout.has("right_panel_position") and layout.has("left_panel_size") and layout.has("middle_panel_size") and layout.has("right_panel_size"):
		left_panel_position = layout.left_panel_position
		middle_panel_position = layout.middle_panel_position
		right_panel_position = layout.right_panel_position
		left_panel_size = layout.left_panel_size
		middle_panel_size = layout.middle_panel_size
		right_panel_size = layout.right_panel_size
		_update_all_panel_positions()

# 处理输入事件
func _input(event):
	# 按下F5键重新加载事件数据
	if event is InputEventKey and event.pressed and event.keycode == KEY_F5:
		reload_events()

# 重新加载事件数据
func reload_events():
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		printerr("EventManager not found in autoload nodes")
		return
	
	print("重新加载事件数据...")
	
	# 重新加载事件数据
	event_manager.load_events_from_tsv("res://data/events/sample_events.tsv")
	
	# 更新可用事件
	event_manager.update_available_events()
	
	print("事件数据重新加载完成")

# 属性设置器
func set_left_panel_position(pos: Vector2):
	left_panel_position = pos
	if left_panel and not _updating_positions:
		_set_panel_transforms(left_panel, pos, left_panel_size)

func set_middle_panel_position(pos: Vector2):
	middle_panel_position = pos
	if middle_panel and not _updating_positions:
		_set_panel_transforms(middle_panel, pos, middle_panel_size)

func set_right_panel_position(pos: Vector2):
	right_panel_position = pos
	if right_panel and not _updating_positions:
		_set_panel_transforms(right_panel, pos, right_panel_size)

func set_left_panel_size(size: Vector2):
	left_panel_size = size
	if not _updating_positions:
		_update_all_panel_positions()

func set_middle_panel_size(size: Vector2):
	middle_panel_size = size
	if not _updating_positions:
		_update_all_panel_positions()

func set_right_panel_size(size: Vector2):
	right_panel_size = size
	if not _updating_positions:
		_update_all_panel_positions()

# 面板大小变化处理函数
func _on_left_panel_size_changed(new_size: Vector2):
	left_panel_size = new_size

func _on_middle_panel_size_changed(new_size: Vector2):
	middle_panel_size = new_size

func _on_right_panel_size_changed(new_size: Vector2):
	right_panel_size = new_size 

# 连接面板位置变化监听
func _connect_position_change_signals():
	if Engine.is_editor_hint():
		# 使用process来监听面板位置变化
		set_process(true)

# 在编辑器中添加位置同步功能
func _process(delta):
	if Engine.is_editor_hint():
		# 定期检查面板位置是否变化
		_sync_positions_from_panels()
		
		# 检测F2键作为手动更新触发器
		if Input.is_physical_key_pressed(KEY_F2):
			print("手动同步面板位置")
			_sync_positions_bidirectional()

# 更新属性值，从面板位置计算
func _update_values_from_panel_positions():
	if left_panel:
		left_panel_position = left_panel.position + left_panel.size / 2
	if middle_panel:
		middle_panel_position = middle_panel.position + middle_panel.size / 2
	if right_panel:
		right_panel_position = right_panel.position + right_panel.size / 2

# 从面板位置更新属性值
func _sync_positions_from_panels():
	if _updating_positions or not Engine.is_editor_hint():
		return
		
	# 防止循环更新
	_updating_positions = true
	
	# 从面板实际位置更新属性，但仅当有变化时
	if left_panel:
		var new_center = left_panel.position + left_panel.size / 2
		if new_center.distance_to(left_panel_position) > 1.0:  # 添加容差
			left_panel_position = new_center
	
	if middle_panel:
		var new_center = middle_panel.position + middle_panel.size / 2
		if new_center.distance_to(middle_panel_position) > 1.0:
			middle_panel_position = new_center
	
	if right_panel:
		var new_center = right_panel.position + right_panel.size / 2
		if new_center.distance_to(right_panel_position) > 1.0:
			right_panel_position = new_center
	
	# 重置标志
	_updating_positions = false

# 双向同步位置
func _sync_positions_bidirectional():
	if _updating_positions:
		return
	
	_updating_positions = true
	
	# 从面板更新属性值
	_update_values_from_panel_positions()
	
	# 从属性更新面板位置
	_update_all_panel_positions()
	
	_updating_positions = false
	print("位置同步完成！") 
