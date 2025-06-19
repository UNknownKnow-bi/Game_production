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
		print("错误: 未找到EventManager")
		return
	
	print("事件已更新，检查是否需要刷新面板显示...")
	
	# 获取和显示各类事件数量以便调试
	var character_events = event_manager.get_active_events_by_category("character")
	var random_events = event_manager.get_active_events_by_category("random")
	var daily_events = event_manager.get_active_events_by_category("daily")
	
	print("活跃事件数量统计:")
	print("  角色事件数量: ", character_events.size())
	print("  随机事件数量: ", random_events.size())
	print("  日常事件数量: ", daily_events.size())
	
	# 智能更新判断：检查是否真的需要重建面板
	var need_rebuild = _check_if_rebuild_needed(character_events, random_events, daily_events)
	
	if need_rebuild:
		print("EventSystem: 检测到需要重建面板，执行完整更新")
		# 更新人物事件显示
		update_event_panel("character", left_panel)
		
		# 更新随机事件显示
		update_event_panel("random", middle_panel)
		
		# 更新日常事件显示
		update_event_panel("daily", right_panel)
	else:
		print("EventSystem: 无需重建面板，执行轻量级状态同步")
		_sync_existing_cards_status()
	
	# 如果调试模式开启，显示所有事件数量
	if event_manager.debug_mode:
		var debug_info = event_manager.get_debug_info()
		print("EventManager调试信息: ", debug_info)
	
	print("事件面板更新完成")

# 检查是否需要重建面板的方法
func _check_if_rebuild_needed(character_events: Array, random_events: Array, daily_events: Array) -> bool:
	# 检查左侧面板（人物事件）
	if not left_panel or left_panel.event_cards.size() != character_events.size():
		print("EventSystem: 人物事件数量变化，需要重建")
		return true
	
	# 检查中间面板（随机事件）
	if not middle_panel or middle_panel.event_cards.size() != random_events.size():
		print("EventSystem: 随机事件数量变化，需要重建")
		return true
	
	# 检查右侧面板（日常事件）
	if not right_panel or right_panel.event_cards.size() != daily_events.size():
		print("EventSystem: 日常事件数量变化，需要重建")
		return true
	
	# 检查事件ID是否匹配
	if not _check_events_match(left_panel.event_cards, character_events):
		print("EventSystem: 人物事件ID不匹配，需要重建")
		return true
	
	if not _check_events_match(middle_panel.event_cards, random_events):
		print("EventSystem: 随机事件ID不匹配，需要重建")
		return true
	
	if not _check_events_match(right_panel.event_cards, daily_events):
		print("EventSystem: 日常事件ID不匹配，需要重建")
		return true
	
	print("EventSystem: 事件列表未变化，无需重建")
	return false

# 检查卡片和事件是否匹配
func _check_events_match(cards: Array, events: Array) -> bool:
	if cards.size() != events.size():
		return false
	
	for i in range(cards.size()):
		var card = cards[i]
		var event = events[i]
		
		if not card.has_method("get_game_event"):
			continue
		
		var card_event = card.get_game_event()
		if not card_event or card_event.event_id != event.event_id:
			return false
	
	return true

# 同步现有卡片状态的方法
func _sync_existing_cards_status():
	print("EventSystem: 同步现有卡片状态...")
	
	# 同步人物事件卡片状态
	if left_panel:
		_sync_panel_cards_status(left_panel, "character")
	
	# 同步随机事件卡片状态
	if middle_panel:
		_sync_panel_cards_status(middle_panel, "random")
	
	# 同步日常事件卡片状态
	if right_panel:
		_sync_panel_cards_status(right_panel, "daily")
	
	print("EventSystem: 卡片状态同步完成")

# 同步单个面板卡片状态
func _sync_panel_cards_status(panel: EventPanel, category: String):
	if not panel:
		return
	
	print("EventSystem: 同步", category, "面板卡片状态，卡片数量:", panel.event_cards.size())
	
	for card in panel.event_cards:
		if card.has_method("_verify_and_fix_initial_status"):
			card.call_deferred("_verify_and_fix_initial_status")
		elif card.has_method("_verify_status_consistency"):
			card.call_deferred("_verify_status_consistency")

# 更新特定类别的事件面板
func update_event_panel(category: String, panel: EventPanel):
	print("=== EventSystem.update_event_panel 开始 ===")
	print("更新类别: ", category)
	print("面板实例: ", panel)
	
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager or not panel:
		print("✗ EventManager或面板为null")
		print("  EventManager: ", event_manager)
		print("  Panel: ", panel)
		print("=== EventSystem.update_event_panel 失败 ===")
		return
	
	print("✓ EventManager和面板验证通过")
	
	var active_events = event_manager.get_active_events_by_category(category)
	print("获取到的活跃事件数量: ", active_events.size())
	
	# 日常事件特定调试
	if category == "daily":
		print("=== 日常事件特定调试 ===")
		print("右侧面板状态验证:")
		print("  面板类型: ", panel.get_class())
		print("  面板可见性: ", panel.visible)
		print("  面板大小: ", panel.size)
		print("  面板位置: ", panel.position)
		print("  面板mouse_filter: ", panel.mouse_filter)
		
		if panel.has_method("get_card_container"):
			var container = panel.get_card_container()
			print("  卡片容器: ", container)
			if container:
				print("    容器类型: ", container.get_class())
				print("    容器可见性: ", container.visible)
				print("    容器大小: ", container.size)
				print("    容器位置: ", container.position)
				print("    容器mouse_filter: ", container.mouse_filter)
		
		for i in range(active_events.size()):
			var event = active_events[i]
			print("  日常事件 #", i+1, ":")
			print("    ID: ", event.event_id)
			print("    名称: ", event.event_name)
			print("    类型: ", event.get_event_category())
		print("=== 日常事件调试完成 ===")
	
	# 清除现有卡片
	print("清除现有卡片...")
	panel.clear_event_cards()
	
	# 如果没有活跃事件，显示空状态
	if active_events.is_empty():
		var empty_message = "当前没有可用的" + get_category_display_name(category)
		print("显示空状态: ", empty_message)
		panel.show_empty_state(empty_message)
		print("=== EventSystem.update_event_panel 完成(空状态) ===")
		return
	
	print("开始为每个活跃事件创建卡片...")
	
	# 为每个活跃事件创建卡片
	for i in range(active_events.size()):
		var event = active_events[i]
		print("处理事件 #", i+1, ": ", event.event_name)
		# 直接传递GameEvent对象，让EventCardFactory处理所有逻辑
		var created_card = panel.add_event_card(event, category)
		if created_card:
			print("✓ 事件卡片创建成功")
		else:
			print("✗ 事件卡片创建失败")
		
	print("已为", category, "面板添加", active_events.size(), "个事件卡片")
	
	# 验证卡片创建结果
	print("=== EventSystem验证卡片状态 ===")
	var created_cards = panel.event_cards.size()
	print("预期卡片数量: ", active_events.size(), " | 实际创建数量: ", created_cards)
	
	if created_cards != active_events.size():
		print("⚠️ 警告: 卡片创建数量不匹配")
	
	# 验证每个卡片的game_event设置
	var valid_cards = 0
	for i in range(panel.event_cards.size()):
		var card = panel.event_cards[i]
		var game_event = card.get_game_event()
		if game_event:
			print("✓ 卡片 #", i+1, " - 事件: ", game_event.event_name, " | 状态: 正常")
			valid_cards += 1
		else:
			print("✗ 卡片 #", i+1, " - 标题: ", card.event_title, " | 状态: game_event为null")
	
	print("有效卡片数量: ", valid_cards, "/", created_cards)
	print("=== 验证完成 ===")
	print("=== EventSystem.update_event_panel 完成 ===")

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
	
	# 测试角色映射功能
	print("=== 测试角色映射功能 ===")
	CharacterMapping.debug_print_all_characters()
	
	# 测试几个已知角色
	var test_characters = ["主角", "高云峰", "天笑"]
	for char_name in test_characters:
		var image_path = CharacterMapping.get_character_image_path(char_name)
		print("测试角色映射: ", char_name, " -> ", image_path)

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
