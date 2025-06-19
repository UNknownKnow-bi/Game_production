class_name DailyEventHotzoneManager
extends Node

# 热区配置
@export var hotzone_count: int = 3
@export var cards_per_hotzone: int = 1
@export var card_spacing: int = 15

# 随机位置配置
@export var enable_random_positioning: bool = false
@export var min_card_distance: float = 15.0
@export var max_position_attempts: int = 100
@export var hotzone_padding: Vector2 = Vector2(10, 10)

# 热区容器引用
var hotzone_containers: Array[Control] = []

# 卡片场景资源
var weekend_daily_card_scene: PackedScene

# 当前热区中的卡片
var hotzone_cards: Array[Array] = []

# 随机位置记录
var hotzone_positions: Array[Array] = []

# 信号
signal card_clicked(game_event: GameEvent)

func _ready():
	print("=== DailyEventHotzoneManager._ready 开始 ===")
	
	# 加载weekend日常事件卡片场景
	weekend_daily_card_scene = load("res://scenes/weekend/components/weekend_daily_event_card.tscn")
	if not weekend_daily_card_scene:
		print("✗ 错误: 无法加载weekend日常事件卡片场景")
		return
	
	print("✓ Weekend日常事件卡片场景加载成功")
	
	# 初始化热区卡片数组和位置数组
	for i in range(hotzone_count):
		hotzone_cards.append([])
		hotzone_positions.append([])
	
	# 连接EventManager信号
	_connect_event_manager_signals()
	
	print("=== DailyEventHotzoneManager._ready 完成 ===")

# 设置热区容器
func set_hotzone_containers(containers: Array[Control]):
	print("=== DailyEventHotzoneManager.set_hotzone_containers 开始 ===")
	print("传入容器数量: ", containers.size())
	
	hotzone_containers = containers
	
	for i in range(containers.size()):
		var container = containers[i]
		if container:
			print("✓ 热区", i+1, "容器设置成功: ", container.name)
			# 设置容器布局
			_setup_hotzone_container(container, i)
		else:
			print("✗ 热区", i+1, "容器为null")
	
	# 初始更新显示
	update_all_hotzones()
	
	print("=== DailyEventHotzoneManager.set_hotzone_containers 完成 ===")

# 设置热区容器布局
func _setup_hotzone_container(container: Control, hotzone_index: int):
	# 为随机定位准备容器
	if enable_random_positioning:
		# 确保容器没有自动布局，这样我们可以手动设置位置
		container.set_clip_contents(true)  # 防止卡片超出边界
		print("热区", hotzone_index+1, "容器配置为随机定位模式")
	else:
		# 传统布局设置
		if container is VBoxContainer:
			container.add_theme_constant_override("separation", card_spacing)
		elif container is HBoxContainer:
			container.add_theme_constant_override("separation", card_spacing)
		print("热区", hotzone_index+1, "容器配置为传统布局模式")

# 连接EventManager信号
func _connect_event_manager_signals():
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		print("⚠ DailyEventHotzoneManager: EventManager未找到，无法连接信号")
		return
	
	if not event_manager.events_updated.is_connected(_on_events_updated):
		event_manager.events_updated.connect(_on_events_updated)
		print("DailyEventHotzoneManager: 已连接EventManager的events_updated信号")

# 处理事件更新信号
func _on_events_updated():
	print("DailyEventHotzoneManager: 收到事件更新信号，开始更新热区")
	update_all_hotzones()

# 更新所有热区
func update_all_hotzones():
	print("=== DailyEventHotzoneManager.update_all_hotzones 开始 ===")
	
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		print("✗ EventManager未找到")
		return
	
	# 获取可用的日常事件
	var daily_events = event_manager.get_active_events_by_category("daily")
	print("获取到日常事件数量: ", daily_events.size())
	
	if daily_events.is_empty():
		print("没有可用的日常事件，清空所有热区")
		_clear_all_hotzones()
		return
	
	# 将事件分配到各个热区
	_distribute_events_to_hotzones(daily_events)
	
	print("=== DailyEventHotzoneManager.update_all_hotzones 完成 ===")

# 将事件分配到热区
func _distribute_events_to_hotzones(events: Array):
	print("=== DailyEventHotzoneManager._distribute_events_to_hotzones 开始 ===")
	print("待分配事件数量: ", events.size())
	print("热区数量: ", hotzone_containers.size())
	print("随机定位模式: ", enable_random_positioning)
	
	# 清空现有卡片
	_clear_all_hotzones()
	
	# 计算每个热区的事件分配
	var event_index = 0
	var total_capacity = hotzone_count * cards_per_hotzone
	var events_to_show = min(events.size(), total_capacity)
	
	print("总容量: ", total_capacity, ", 将显示事件数量: ", events_to_show)
	
	for hotzone_index in range(hotzone_count):
		if hotzone_index >= hotzone_containers.size():
			break
		
		var container = hotzone_containers[hotzone_index]
		if not container:
			continue
		
		print("处理热区", hotzone_index+1, "...")
		
		# 为当前热区分配事件
		var cards_in_this_hotzone = 0
		var hotzone_events = []
		
		# 收集这个热区的所有事件
		while cards_in_this_hotzone < cards_per_hotzone and event_index < events_to_show:
			hotzone_events.append(events[event_index])
			cards_in_this_hotzone += 1
			event_index += 1
		
		# 根据定位模式创建卡片
		if enable_random_positioning:
			_create_cards_with_random_positioning(hotzone_events, hotzone_index, container)
		else:
			for event in hotzone_events:
				_create_card_in_hotzone(event, hotzone_index, container)
		
		print("热区", hotzone_index+1, "完成，分配了", cards_in_this_hotzone, "张卡片")
	
	print("=== DailyEventHotzoneManager._distribute_events_to_hotzones 完成 ===")

# 在指定热区创建卡片
func _create_card_in_hotzone(game_event: GameEvent, hotzone_index: int, container: Control):
	print("=== DailyEventHotzoneManager._create_card_in_hotzone 开始 ===")
	print("热区索引: ", hotzone_index)
	print("事件: ", game_event.event_name)
	
	if not weekend_daily_card_scene:
		print("✗ 卡片场景未加载")
		return
	
	# 实例化卡片
	var card_instance = weekend_daily_card_scene.instantiate()
	if not card_instance:
		print("✗ 卡片实例化失败")
		return
	
	print("✓ 卡片实例化成功")
	
	# 先添加到容器（添加到场景树）
	container.add_child(card_instance)
	
	# 然后初始化卡片（此时卡片已在场景树中，可以访问EventManager）
	card_instance.set_game_event(game_event)
	card_instance.set_event_title(game_event.event_name)
	
	# 连接卡片点击信号
	if card_instance.card_clicked.connect(_on_card_clicked.bind(game_event)) == OK:
		print("✓ 卡片点击信号连接成功")
	else:
		print("✗ 卡片点击信号连接失败")
	
	# 记录到热区卡片数组
	if hotzone_index < hotzone_cards.size():
		hotzone_cards[hotzone_index].append(card_instance)
	
	print("✓ 卡片添加到热区", hotzone_index+1, "完成")
	print("=== DailyEventHotzoneManager._create_card_in_hotzone 完成 ===")

# 处理卡片点击
func _on_card_clicked(game_event: GameEvent):
	print("DailyEventHotzoneManager: 热区卡片被点击 - ", game_event.event_name)
	card_clicked.emit(game_event)

# 清空所有热区
func _clear_all_hotzones():
	print("DailyEventHotzoneManager: 清空所有热区")
	
	for hotzone_index in range(hotzone_containers.size()):
		_clear_hotzone(hotzone_index)

# 清空指定热区
func _clear_hotzone(hotzone_index: int):
	if hotzone_index >= hotzone_containers.size() or hotzone_index >= hotzone_cards.size():
		return
	
	var container = hotzone_containers[hotzone_index]
	if not container:
		return
	
	# 删除热区中的所有卡片
	for card in hotzone_cards[hotzone_index]:
		if is_instance_valid(card):
			card.queue_free()
	
	# 清空记录数组
	hotzone_cards[hotzone_index].clear()
	
	# 清空位置记录
	if hotzone_index < hotzone_positions.size():
		hotzone_positions[hotzone_index].clear()
	
	print("热区", hotzone_index+1, "已清空")

# 使用随机定位创建卡片
func _create_cards_with_random_positioning(events: Array, hotzone_index: int, container: Control):
	print("=== DailyEventHotzoneManager._create_cards_with_random_positioning 开始 ===")
	print("热区索引: ", hotzone_index, ", 事件数量: ", events.size())
	
	# 生成随机位置
	var positions = _generate_random_positions(events.size(), container)
	print("生成了", positions.size(), "个随机位置")
	
	# 为每个事件创建卡片并设置位置
	for i in range(events.size()):
		var event = events[i]
		var position = positions[i] if i < positions.size() else Vector2.ZERO
		
		# 创建卡片实例
		var card_instance = weekend_daily_card_scene.instantiate()
		if not card_instance:
			print("✗ 卡片实例化失败: ", event.event_name)
			continue
		
		# 添加到容器
		container.add_child(card_instance)
		
		# 设置随机位置
		card_instance.position = position
		print("卡片", event.event_name, "设置位置: ", position)
		
		# 初始化卡片
		card_instance.set_game_event(event)
		card_instance.set_event_title(event.event_name)
		
		# 连接信号
		if card_instance.card_clicked.connect(_on_card_clicked.bind(event)) == OK:
			print("✓ 卡片点击信号连接成功: ", event.event_name)
		
		# 记录卡片和位置
		if hotzone_index < hotzone_cards.size():
			hotzone_cards[hotzone_index].append(card_instance)
		if hotzone_index < hotzone_positions.size():
			hotzone_positions[hotzone_index].append(position)
	
	print("=== DailyEventHotzoneManager._create_cards_with_random_positioning 完成 ===")

# 生成随机位置算法
func _generate_random_positions(card_count: int, container: Control) -> Array[Vector2]:
	print("=== DailyEventHotzoneManager._generate_random_positions 开始 ===")
	print("需要生成", card_count, "个位置")
	
	var positions: Array[Vector2] = []
	var container_size = container.size
	var usable_area = container_size - hotzone_padding * 2
	
	# 更新卡片大小为新的尺寸
	var card_size = Vector2(240, 140)
	
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
	
	print("=== DailyEventHotzoneManager._generate_random_positions 完成 ===")
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
	var grid_x = (existing_positions.size() % 3) * (card_size.x + min_card_distance)
	var grid_y = (existing_positions.size() / 3) * (card_size.y + min_card_distance)
	return Vector2(hotzone_padding.x + grid_x, hotzone_padding.y + grid_y)

# 启用/禁用随机定位
func set_random_positioning(enabled: bool):
	enable_random_positioning = enabled
	print("随机定位模式设置为: ", enabled)
	
	# 重新配置热区容器
	for i in range(hotzone_containers.size()):
		_setup_hotzone_container(hotzone_containers[i], i)
	
	# 更新显示
	update_all_hotzones()

# 获取热区状态信息
func get_hotzone_status() -> Dictionary:
	var status = {
		"hotzone_count": hotzone_count,
		"cards_per_hotzone": cards_per_hotzone,
		"total_cards": 0,
		"random_positioning_enabled": enable_random_positioning
	}
	
	for hotzone_index in range(hotzone_cards.size()):
		var cards_in_hotzone = hotzone_cards[hotzone_index].size()
		status["hotzone_" + str(hotzone_index + 1)] = cards_in_hotzone
		status.total_cards += cards_in_hotzone
		
		# 如果启用随机定位，包含位置信息
		if enable_random_positioning and hotzone_index < hotzone_positions.size():
			status["hotzone_" + str(hotzone_index + 1) + "_positions"] = hotzone_positions[hotzone_index]
	
	return status 

# 支持周末新卡片类型的方法
func support_weekend_event_cards(random_card_scene: PackedScene, character_card_scene: PackedScene):
	print("DailyEventHotzoneManager: 扩展支持周末事件卡片")
	# 这里可以存储不同类型卡片的场景引用，为后续扩展做准备
	# 暂时保留现有的weekend_daily_card_scene作为主要卡片类型

# 刷新所有卡片状态
func refresh_cards_status():
	print("=== DailyEventHotzoneManager.refresh_cards_status 开始 ===")
	
	var total_cards = 0
	for hotzone_index in range(hotzone_cards.size()):
		total_cards += hotzone_cards[hotzone_index].size()
	
	if total_cards == 0:
		print("没有卡片需要刷新状态")
		return
	
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		print("⚠ EventManager未找到，无法刷新状态")
		return
	
	var refreshed_count = 0
	for hotzone_index in range(hotzone_cards.size()):
		for card in hotzone_cards[hotzone_index]:
			if is_instance_valid(card) and card.has_method("get_game_event"):
				var game_event = card.get_game_event()
				if game_event:
					var is_completed = event_manager.is_event_completed(game_event.event_id)
					
					# 强制更新卡片状态
					if card.has_method("set_completion_status"):
						card.set_completion_status(is_completed)
						print("✓ 刷新卡片状态: ", game_event.event_name, " -> ", "完成" if is_completed else "未完成")
						refreshed_count += 1
					elif card.has_method("set_completed"):
						card.set_completed(is_completed)
						print("✓ 刷新卡片状态: ", game_event.event_name, " -> ", "完成" if is_completed else "未完成")
						refreshed_count += 1
	
	print("✓ 成功刷新", refreshed_count, "张卡片状态")
	print("=== DailyEventHotzoneManager.refresh_cards_status 完成 ===")

# 更新特定事件的卡片状态
func update_card_status_for_event(event_id: int):
	print("=== DailyEventHotzoneManager.update_card_status_for_event 开始 ===")
	print("目标事件ID: ", event_id)
	
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		print("⚠ EventManager未找到，无法更新事件状态")
		return
	
	var is_completed = event_manager.is_event_completed(event_id)
	var found_card = false
	
	for hotzone_index in range(hotzone_cards.size()):
		for card in hotzone_cards[hotzone_index]:
			if is_instance_valid(card) and card.has_method("get_game_event"):
				var game_event = card.get_game_event()
				if game_event and game_event.event_id == event_id:
					found_card = true
					print("找到匹配卡片: ", game_event.event_name, " (热区", hotzone_index+1, ")")
					
					# 强制更新卡片状态
					if card.has_method("set_completion_status"):
						card.set_completion_status(is_completed)
						print("✓ 更新卡片状态: ", game_event.event_name, " -> ", "完成" if is_completed else "未完成")
					elif card.has_method("set_completed"):
						card.set_completed(is_completed)
						print("✓ 更新卡片状态: ", game_event.event_name, " -> ", "完成" if is_completed else "未完成")
					
					break
		if found_card:
			break
	
	if not found_card:
		print("⚠ 未找到事件ID为", event_id, "的卡片")
	
	print("=== DailyEventHotzoneManager.update_card_status_for_event 完成 ===")

# 强制同步所有卡片与EventManager的状态
func sync_all_cards_with_event_manager():
	print("=== DailyEventHotzoneManager.sync_all_cards_with_event_manager 开始 ===")
	
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		print("⚠ EventManager未找到，无法同步状态")
		return
	
	var synced_count = 0
	for hotzone_index in range(hotzone_cards.size()):
		for card in hotzone_cards[hotzone_index]:
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
	print("=== DailyEventHotzoneManager.sync_all_cards_with_event_manager 完成 ===") 
