class_name WeekendEventHotzoneManager
extends Node

# 热区配置
@export var hotzone_count: int = 1
@export var cards_per_hotzone: int = 3
@export var card_spacing: int = 15

# 随机位置配置
@export var enable_random_positioning: bool = false
@export var min_card_distance: float = 20.0
@export var max_position_attempts: int = 100
@export var hotzone_padding: Vector2 = Vector2(10, 10)

# 热区容器引用
var hotzone_container: Control = null

# 卡片场景资源
var weekend_character_card_scene: PackedScene
var weekend_random_card_scene: PackedScene

# 当前热区中的卡片
var hotzone_cards: Array = []

# 随机位置记录
var hotzone_positions: Array = []

# 信号
signal card_clicked(game_event: GameEvent)

func _ready():
	print("=== WeekendEventHotzoneManager._ready 开始 ===")
	
	# 加载weekend事件卡片场景
	weekend_character_card_scene = load("res://scenes/weekend/components/weekend_character_event_card.tscn")
	weekend_random_card_scene = load("res://scenes/weekend/components/weekend_random_event_card.tscn")
	
	if not weekend_character_card_scene:
		print("✗ 错误: 无法加载weekend角色事件卡片场景")
		return
	
	if not weekend_random_card_scene:
		print("✗ 错误: 无法加载weekend随机事件卡片场景")
		return
	
	print("✓ Weekend事件卡片场景加载成功")
	
	print("=== WeekendEventHotzoneManager._ready 完成 ===")

# 设置热区容器
func set_hotzone_container(container: Control):
	print("=== WeekendEventHotzoneManager.set_hotzone_container 开始 ===")
	
	hotzone_container = container
	
	if container:
		print("✓ Weekend事件热区容器设置成功: ", container.name)
		# 设置容器布局
		_setup_hotzone_container(container)
	else:
		print("✗ Weekend事件热区容器为null")
	
	print("=== WeekendEventHotzoneManager.set_hotzone_container 完成 ===")

# 设置热区容器布局
func _setup_hotzone_container(container: Control):
	# 为随机定位准备容器
	if enable_random_positioning:
		# 确保容器没有自动布局，这样我们可以手动设置位置
		container.set_clip_contents(true)  # 防止卡片超出边界
		print("Weekend事件热区容器配置为随机定位模式")
	else:
		# 传统布局设置
		if container is VBoxContainer:
			container.add_theme_constant_override("separation", card_spacing)
		elif container is HBoxContainer:
			container.add_theme_constant_override("separation", card_spacing)
		print("Weekend事件热区容器配置为传统布局模式")

# 显示weekend事件卡片
func display_weekend_events(events: Array[GameEvent]):
	print("=== WeekendEventHotzoneManager.display_weekend_events 开始 ===")
	print("待显示事件数量: ", events.size())
	
	if not hotzone_container:
		print("✗ 热区容器未设置")
		return
	
	# 清空现有卡片
	_clear_hotzone()
	
	# 筛选weekend character和random事件
	var weekend_events = []
	for event in events:
		if event.event_type == "人物事件" or event.event_type == "随机事件":
			weekend_events.append(event)
			print("添加weekend事件: ", event.event_name, " (", event.event_type, ")")
	
	print("筛选到weekend事件数量: ", weekend_events.size())
	
	if weekend_events.is_empty():
		print("没有weekend character/random事件需要显示")
		return
	
	# 显示事件（限制数量）
	var events_to_show = min(weekend_events.size(), cards_per_hotzone)
	
	# 根据定位模式创建卡片
	if enable_random_positioning:
		_create_cards_with_random_positioning(weekend_events.slice(0, events_to_show))
	else:
		for i in range(events_to_show):
			_create_card_in_hotzone(weekend_events[i])
	
	print("✓ 完成显示", events_to_show, "个weekend事件")
	print("=== WeekendEventHotzoneManager.display_weekend_events 完成 ===")

# 在热区创建卡片
func _create_card_in_hotzone(game_event: GameEvent):
	print("=== WeekendEventHotzoneManager._create_card_in_hotzone 开始 ===")
	print("事件: ", game_event.event_name, " (", game_event.event_type, ")")
	
	# 详细调试事件字段
	print("🔍 事件字段调试:")
	print("  event_id: ", game_event.event_id)
	print("  event_name: ", game_event.event_name)
	print("  event_type: ", game_event.event_type)
	print("  character_name原始: '", game_event.character_name, "'")
	print("  character_name原始长度: ", game_event.character_name.length())
	print("  character_name.is_empty(): ", game_event.character_name.is_empty())
	
	# 清理character_name字段，处理占位符
	var cleaned_character_name = game_event.character_name.strip_edges()
	# 将各种占位符识别为空字符串
	if cleaned_character_name == "{}" or cleaned_character_name == "null" or cleaned_character_name == "NULL":
		cleaned_character_name = ""
	
	print("  character_name清理后: '", cleaned_character_name, "'")
	print("  character_name清理后长度: ", cleaned_character_name.length())
	print("  cleaned_character_name.is_empty(): ", cleaned_character_name.is_empty())
	
	# 根据事件类型选择场景
	var card_scene: PackedScene = null
	if game_event.event_type == "人物事件" and not cleaned_character_name.is_empty():
		print("🎯 选择人物事件卡片场景")
		print("  原因: event_type=='人物事件': ", game_event.event_type == "人物事件")
		print("  原因: 有有效角色名称: ", not cleaned_character_name.is_empty())
		card_scene = weekend_character_card_scene
	elif game_event.event_type == "daily":
		print("🎯 尝试选择日常事件卡片场景")
		print("  原因: event_type=='daily': ", game_event.event_type == "daily")
		# 暂时使用随机事件卡片代替日常事件卡片
		card_scene = weekend_random_card_scene
		print("  使用随机卡片场景代替")
	else:
		print("🎯 选择随机事件卡片场景")
		print("  原因: 随机事件或无有效角色名称")
		print("  事件类型: ", game_event.event_type)
		print("  角色名称为空: ", cleaned_character_name.is_empty())
		card_scene = weekend_random_card_scene
	
	if not card_scene:
		print("✗ 卡片场景未加载")
		return
	
	# 实例化卡片
	var card_instance = card_scene.instantiate()
	if not card_instance:
		print("✗ 卡片实例化失败")
		return
	
	print("✓ 卡片实例化成功 - 类型: ", card_instance.get_class())
	
	# 先添加到容器（添加到场景树）
	hotzone_container.add_child(card_instance)
	
	# 然后初始化卡片 - 优先使用完整初始化方法
	if card_instance.has_method("initialize_from_game_event"):
		print("✓ 使用initialize_from_game_event方法进行完整初始化")
		card_instance.initialize_from_game_event(game_event)
	else:
		print("✓ 使用基础初始化方法")
		if card_instance.has_method("set_game_event"):
			card_instance.set_game_event(game_event)
		if card_instance.has_method("set_event_title"):
			card_instance.set_event_title(game_event.event_name)
	
	# 连接卡片点击信号
	if card_instance.has_signal("card_clicked"):
		if card_instance.card_clicked.connect(_on_card_clicked.bind(game_event)) == OK:
			print("✓ 卡片点击信号连接成功")
		else:
			print("✗ 卡片点击信号连接失败")
	
	# 延迟检查卡片状态和信号连接
	call_deferred("_verify_card_initialization", card_instance, game_event)
	
	# 记录到热区卡片数组
	hotzone_cards.append(card_instance)
	
	print("✓ 卡片添加到weekend热区完成")
	print("=== WeekendEventHotzoneManager._create_card_in_hotzone 完成 ===")

# 处理卡片点击
func _on_card_clicked(game_event: GameEvent):
	print("WeekendEventHotzoneManager: Weekend事件卡片被点击 - ", game_event.event_name)
	card_clicked.emit(game_event)

# 清空热区
func _clear_hotzone():
	print("WeekendEventHotzoneManager: 清空weekend事件热区")
	
	if not hotzone_container:
		return
	
	# 删除热区中的所有卡片
	for card in hotzone_cards:
		if is_instance_valid(card):
			card.queue_free()
	
	# 清空记录数组
	hotzone_cards.clear()
	hotzone_positions.clear()

# 使用随机定位创建卡片
func _create_cards_with_random_positioning(events: Array):
	print("=== WeekendEventHotzoneManager._create_cards_with_random_positioning 开始 ===")
	print("事件数量: ", events.size())
	
	# 生成随机位置
	var positions = _generate_random_positions(events.size())
	print("生成了", positions.size(), "个随机位置")
	
	# 为每个事件创建卡片并设置位置
	for i in range(events.size()):
		var event = events[i]
		var position = positions[i] if i < positions.size() else Vector2.ZERO
		
		print("处理事件: ", event.event_name, " (", event.event_type, ")")
		print("  character_name原始: '", event.character_name, "' (长度:", event.character_name.length(), ")")
		
		# 清理character_name字段，处理占位符
		var cleaned_character_name = event.character_name.strip_edges()
		# 将各种占位符识别为空字符串
		if cleaned_character_name == "{}" or cleaned_character_name == "null" or cleaned_character_name == "NULL":
			cleaned_character_name = ""
		
		print("  character_name清理后: '", cleaned_character_name, "' (长度:", cleaned_character_name.length(), ")")
		
		# 根据事件类型选择场景
		var card_scene: PackedScene = null
		if event.event_type == "人物事件" and not cleaned_character_name.is_empty():
			card_scene = weekend_character_card_scene
			print("  选择人物事件卡片场景")
		elif event.event_type == "daily":
			card_scene = weekend_random_card_scene
			print("  选择随机卡片场景（代替日常卡片）")
		else:
			card_scene = weekend_random_card_scene
			print("  选择随机事件卡片场景")
		
		# 创建卡片实例
		var card_instance = card_scene.instantiate()
		if not card_instance:
			print("✗ 卡片实例化失败: ", event.event_name)
			continue
		
		# 添加到容器
		hotzone_container.add_child(card_instance)
		
		# 设置随机位置
		card_instance.position = position
		print("卡片", event.event_name, "设置位置: ", position)
		
		# 初始化卡片 - 优先使用完整初始化方法
		if card_instance.has_method("initialize_from_game_event"):
			print("✓ 使用initialize_from_game_event方法进行完整初始化")
			card_instance.initialize_from_game_event(event)
		else:
			print("✓ 使用基础初始化方法")
			if card_instance.has_method("set_game_event"):
				card_instance.set_game_event(event)
			if card_instance.has_method("set_event_title"):
				card_instance.set_event_title(event.event_name)
		
		# 连接信号
		if card_instance.has_signal("card_clicked"):
			if card_instance.card_clicked.connect(_on_card_clicked.bind(event)) == OK:
				print("✓ 卡片点击信号连接成功: ", event.event_name)
		
		# 记录卡片和位置
		hotzone_cards.append(card_instance)
		hotzone_positions.append(position)
	
	print("=== WeekendEventHotzoneManager._create_cards_with_random_positioning 完成 ===")

# 生成随机位置算法
func _generate_random_positions(card_count: int) -> Array[Vector2]:
	print("=== WeekendEventHotzoneManager._generate_random_positions 开始 ===")
	print("需要生成", card_count, "个位置")
	
	var positions: Array[Vector2] = []
	
	if not hotzone_container:
		return positions
	
	var container_size = hotzone_container.size
	var usable_area = container_size - hotzone_padding * 2
	
	# 假设卡片大小
	var card_size = Vector2(350, 200)
	
	print("容器大小: ", container_size)
	print("可用区域: ", usable_area)
	print("卡片大小: ", card_size)
	
	# 确保可用区域足够放置卡片
	if usable_area.x < card_size.x or usable_area.y < card_size.y:
		print("⚠ 容器太小，使用默认位置")
		for i in range(card_count):
			positions.append(Vector2(hotzone_padding.x, hotzone_padding.y + i * (card_size.y + min_card_distance)))
		return positions
	
	# 计算可放置的最大范围
	var max_x = usable_area.x - card_size.x
	var max_y = usable_area.y - card_size.y
	
	for i in range(card_count):
		var position = _find_non_overlapping_position(positions, Vector2(max_x, max_y), card_size)
		positions.append(position)
		print("位置", i+1, ": ", position)
	
	print("=== WeekendEventHotzoneManager._generate_random_positions 完成 ===")
	return positions

# 寻找不重叠的位置
func _find_non_overlapping_position(existing_positions: Array[Vector2], max_pos: Vector2, card_size: Vector2) -> Vector2:
	var attempts = 0
	
	while attempts < max_position_attempts:
		# 生成随机位置
		var x = hotzone_padding.x + randf() * max_pos.x
		var y = hotzone_padding.y + randf() * max_pos.y
		var candidate_pos = Vector2(x, y)
		
		# 检查是否与现有位置重叠
		var is_valid = true
		for existing_pos in existing_positions:
			var distance = candidate_pos.distance_to(existing_pos)
			var min_required_distance = min_card_distance + (card_size.length() / 2)
			
			if distance < min_required_distance:
				is_valid = false
				break
		
		if is_valid:
			return candidate_pos
		
		attempts += 1
	
	# 如果找不到合适位置，使用网格布局作为后备
	print("⚠ 无法找到不重叠位置，使用后备位置")
	var grid_x = (existing_positions.size() % 2) * (card_size.x + min_card_distance)
	var grid_y = (existing_positions.size() / 2) * (card_size.y + min_card_distance)
	return Vector2(hotzone_padding.x + grid_x, hotzone_padding.y + grid_y)

# 启用/禁用随机定位
func set_random_positioning(enabled: bool):
	enable_random_positioning = enabled
	print("Weekend事件随机定位模式设置为: ", enabled)
	
	# 重新配置热区容器
	if hotzone_container:
		_setup_hotzone_container(hotzone_container)

# 获取热区状态信息
func get_hotzone_status() -> Dictionary:
	var status = {
		"cards_per_hotzone": cards_per_hotzone,
		"total_cards": hotzone_cards.size(),
		"random_positioning_enabled": enable_random_positioning
	}
	
	# 如果启用随机定位，包含位置信息
	if enable_random_positioning:
		status["card_positions"] = hotzone_positions
	
	return status

# 刷新所有卡片状态
func refresh_cards_status():
	print("=== WeekendEventHotzoneManager.refresh_cards_status 开始 ===")
	
	if hotzone_cards.is_empty():
		print("没有卡片需要刷新状态")
		return
	
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		print("⚠ EventManager未找到，无法刷新状态")
		return
	
	var refreshed_count = 0
	for card in hotzone_cards:
		if is_instance_valid(card) and card.has_method("get_game_event"):
			var game_event = card.get_game_event()
			if game_event:
				var manager_completed = event_manager.is_event_completed(game_event.event_id)
				
				# 获取当前卡片状态
				var card_completed = false
				if card.has_method("get_completion_status"):
					card_completed = card.get_completion_status()
				elif card.has_method("get") and "is_completed" in card:
					card_completed = card.is_completed
				
				# 只有状态不一致时才更新
				if manager_completed != card_completed:
					print("刷新卡片状态不一致: ", game_event.event_name, " 卡片:", card_completed, " 管理器:", manager_completed)
					
					# 使用卡片自身的同步方法而不是强制设置
					if card.has_method("_sync_with_event_manager"):
						card._sync_with_event_manager()
						print("✓ 使用同步方法刷新卡片: ", game_event.event_name)
						refreshed_count += 1
					elif card.has_method("set_completion_status"):
						card.set_completion_status(manager_completed)
						print("✓ 强制刷新卡片状态: ", game_event.event_name, " -> ", "完成" if manager_completed else "未完成")
						refreshed_count += 1
					elif card.has_method("set_completed"):
						card.set_completed(manager_completed)
						print("✓ 强制刷新卡片状态: ", game_event.event_name, " -> ", "完成" if manager_completed else "未完成")
						refreshed_count += 1
				else:
					print("✓ 卡片状态已一致: ", game_event.event_name, " (", "完成" if card_completed else "未完成", ")")
	
	print("✓ 成功刷新", refreshed_count, "张卡片状态")
	print("=== WeekendEventHotzoneManager.refresh_cards_status 完成 ===")

# 更新特定事件的卡片状态
func update_card_status_for_event(event_id: int):
	print("=== WeekendEventHotzoneManager.update_card_status_for_event 开始 ===")
	print("目标事件ID: ", event_id)
	
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		print("⚠ EventManager未找到，无法更新事件状态")
		return
	
	var is_completed = event_manager.is_event_completed(event_id)
	var found_card = false
	
	for card in hotzone_cards:
		if is_instance_valid(card) and card.has_method("get_game_event"):
			var game_event = card.get_game_event()
			if game_event and game_event.event_id == event_id:
				found_card = true
				print("找到匹配卡片: ", game_event.event_name)
				
				# 强制更新卡片状态
				if card.has_method("set_completion_status"):
					card.set_completion_status(is_completed)
					print("✓ 更新卡片状态: ", game_event.event_name, " -> ", "完成" if is_completed else "未完成")
				elif card.has_method("set_completed"):
					card.set_completed(is_completed)
					print("✓ 更新卡片状态: ", game_event.event_name, " -> ", "完成" if is_completed else "未完成")
				
				break
	
	if not found_card:
		print("⚠ 未找到事件ID为", event_id, "的卡片")
	
	print("=== WeekendEventHotzoneManager.update_card_status_for_event 完成 ===")

# 强制同步所有卡片与EventManager的状态
func sync_all_cards_with_event_manager():
	print("=== WeekendEventHotzoneManager.sync_all_cards_with_event_manager 开始 ===")
	
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		print("⚠ EventManager未找到，无法同步状态")
		return
	
	var synced_count = 0
	for card in hotzone_cards:
		if is_instance_valid(card) and card.has_method("get_game_event"):
			var game_event = card.get_game_event()
			if game_event:
				# 重新连接EventManager信号确保状态同步
				if card.has_method("_connect_event_manager_signals"):
					card._connect_event_manager_signals()
				
				# 强制状态检查和同步
				var current_completed = event_manager.is_event_completed(game_event.event_id)
				if card.has_method("set_completion_status"):
					card.set_completion_status(current_completed)
				elif card.has_method("set_completed"):
					card.set_completed(current_completed)
				
				print("✓ 同步卡片: ", game_event.event_name, " 状态: ", "完成" if current_completed else "未完成")
				synced_count += 1
	
	print("✓ 成功同步", synced_count, "张卡片与EventManager")
	print("=== WeekendEventHotzoneManager.sync_all_cards_with_event_manager 完成 ===")

# 验证卡片信号连接状态
func verify_cards_signal_connections():
	print("=== WeekendEventHotzoneManager.verify_cards_signal_connections 开始 ===")
	
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		print("⚠ EventManager未找到，无法验证信号连接")
		return
	
	var connected_count = 0
	for card in hotzone_cards:
		if is_instance_valid(card) and card.has_method("get_game_event"):
			var game_event = card.get_game_event()
			if game_event:
				# 检查信号连接状态
				var signal_connected = false
				if card.has_method("_on_event_completed"):
					signal_connected = event_manager.event_completed.is_connected(card._on_event_completed)
				
				print("卡片", game_event.event_name, "信号连接状态:", "已连接" if signal_connected else "未连接")
				
				if signal_connected:
					connected_count += 1
				else:
					# 尝试重新连接信号
					if card.has_method("_connect_event_manager_signals"):
						card._connect_event_manager_signals()
						print("✓ 重新连接信号: ", game_event.event_name)
	
	print("✓ 验证完成，", connected_count, "/", hotzone_cards.size(), "张卡片信号已连接")
	print("=== WeekendEventHotzoneManager.verify_cards_signal_connections 完成 ===")

# 延迟检查卡片状态和信号连接
func _verify_card_initialization(card: Node, game_event: GameEvent):
	print("=== WeekendEventHotzoneManager._verify_card_initialization 开始 ===")
	
	if not is_instance_valid(card):
		print("⚠ 卡片已销毁，无法验证状态")
		return
	
	if not is_instance_valid(game_event):
		print("⚠ 事件已销毁，无法验证状态")
		return
	
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		print("⚠ EventManager未找到，无法验证状态")
		return
	
	# 检查卡片状态 - 仅在初始化时同步，避免覆盖运行时状态变更
	if card.has_method("get_game_event"):
		var current_game_event = card.get_game_event()
		if current_game_event:
			# 获取当前卡片状态和EventManager状态
			var manager_completed = event_manager.is_event_completed(current_game_event.event_id)
			var card_completed = false
			
			if card.has_method("get_completion_status"):
				card_completed = card.get_completion_status()
			elif card.has_method("get") and "is_completed" in card:
				card_completed = card.is_completed
			
			print("卡片状态检查: ", current_game_event.event_name)
			print("  EventManager状态: ", manager_completed)
			print("  卡片当前状态: ", card_completed)
			
			# 只有在状态不一致且这是真正的初始化时才同步
			# 通过检查是否刚添加到场景树来判断是否为初始化
			var is_initialization = card.get_parent() != null and card.get_child_count() >= 0
			
			if manager_completed != card_completed and is_initialization:
				print("初始化时检测到状态不一致，进行同步: ", card_completed, " -> ", manager_completed)
				if card.has_method("set_completion_status"):
					card.set_completion_status(manager_completed)
					print("✓ 初始化同步卡片状态: ", current_game_event.event_name, " -> ", "完成" if manager_completed else "未完成")
				elif card.has_method("set_completed"):
					card.set_completed(manager_completed)
					print("✓ 初始化同步卡片状态: ", current_game_event.event_name, " -> ", "完成" if manager_completed else "未完成")
			else:
				print("✓ 状态一致或非初始化阶段，跳过状态覆盖")
	
	# 检查信号连接状态
	var signal_connected = false
	if card.has_method("_on_event_completed"):
		signal_connected = event_manager.event_completed.is_connected(card._on_event_completed)
		print("卡片", game_event.event_name, "信号连接状态:", "已连接" if signal_connected else "未连接")
	
	if not signal_connected:
		# 尝试重新连接信号
		if card.has_method("_connect_event_manager_signals"):
			card._connect_event_manager_signals()
			print("✓ 重新连接信号: ", game_event.event_name)
	
	print("=== WeekendEventHotzoneManager._verify_card_initialization 完成 ===") 