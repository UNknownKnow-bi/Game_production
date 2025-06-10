class_name WeekendEventHotzoneManager
extends Node

# 热区配置
@export var hotzone_count: int = 1
@export var cards_per_hotzone: int = 5
@export var card_spacing: int = 15

# 随机位置配置
@export var enable_random_positioning: bool = false
@export var min_card_distance: float = 15.0
@export var max_position_attempts: int = 150
@export var hotzone_padding: Vector2 = Vector2(10, 10)

# 排除区域配置
@export var excluded_regions: Array[Rect2] = []
@export var region_padding: float = 25.0

# 卡片尺寸和分布配置
@export var card_size: Vector2 = Vector2(240, 140)
@export var enable_diagonal_distribution: bool = true
@export var corner_region_ratio: float = 0.25
@export var max_cards_display: int = 6

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
		# 初始化排除区域
		_initialize_excluded_regions()
	else:
		print("✗ Weekend事件热区容器为null")
	
	print("=== WeekendEventHotzoneManager.set_hotzone_container 完成 ===")

# 设置热区容器布局
func _setup_hotzone_container(container: Control):
	print("=== WeekendEventHotzoneManager._setup_hotzone_container 开始 ===")
	print("容器类型: ", container.get_class())
	print("随机定位模式: ", enable_random_positioning)
	
	# 为随机定位准备容器
	if enable_random_positioning:
		# 确保容器没有自动布局，这样我们可以手动设置位置
		container.set_clip_contents(true)  # 防止卡片超出边界
		
		# 如果是布局容器，需要特殊处理
		if container is VBoxContainer or container is HBoxContainer:
			print("⚠ 警告: 检测到布局容器，随机定位可能受到干扰")
			print("建议将容器类型改为Control以获得最佳随机定位效果")
		
		print("✓ Weekend事件热区容器配置为随机定位模式")
	else:
		# 传统布局设置
		if container is VBoxContainer:
			container.add_theme_constant_override("separation", card_spacing)
			print("✓ VBoxContainer间距设置为:", card_spacing)
		elif container is HBoxContainer:
			container.add_theme_constant_override("separation", card_spacing)
			print("✓ HBoxContainer间距设置为:", card_spacing)
		print("✓ Weekend事件热区容器配置为传统布局模式")
	
	print("=== WeekendEventHotzoneManager._setup_hotzone_container 完成 ===")

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
	print("最大显示卡片数: ", max_cards_display)
	print("随机定位启用: ", enable_random_positioning)
	print("对角分布启用: ", enable_diagonal_distribution)
	
	# 限制显示的卡片数量
	var events_to_show = min(events.size(), max_cards_display)
	var limited_events = events.slice(0, events_to_show)
	
	print("实际将显示的事件数量: ", limited_events.size())
	
	# 生成位置 - 根据是否启用对角分布选择算法
	var positions: Array[Vector2] = []
	if enable_diagonal_distribution:
		positions = _generate_diagonal_scattered_positions(limited_events.size())
		print("✓ 使用对角散乱分布算法")
	else:
		positions = _generate_random_positions(limited_events.size())
		print("✓ 使用常规随机分布算法")
	
	print("生成了", positions.size(), "个位置")
	
	# 为每个事件创建卡片并设置位置
	for i in range(limited_events.size()):
		var event = limited_events[i]
		var position = positions[i] if i < positions.size() else Vector2.ZERO
		
		print("处理事件", i+1, ": ", event.event_name, " (", event.event_type, ")")
		print("  分配位置: ", position)
		
		# 清理character_name字段，处理占位符
		var cleaned_character_name = event.character_name.strip_edges()
		# 将各种占位符识别为空字符串
		if cleaned_character_name == "{}" or cleaned_character_name == "null" or cleaned_character_name == "NULL":
			cleaned_character_name = ""
		
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
		
		print("✓ 卡片实例化成功，类型: ", card_instance.get_class())
		
		# 添加到容器
		hotzone_container.add_child(card_instance)
		print("✓ 卡片已添加到容器")
		
		# 设置随机位置 - 延迟一帧确保容器布局完成
		call_deferred("_set_card_position_deferred", card_instance, position, event.event_name)
		
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

# 延迟设置卡片位置
func _set_card_position_deferred(card_instance: Node, position: Vector2, event_name: String):
	if is_instance_valid(card_instance):
		card_instance.position = position
		print("✓ 延迟设置卡片位置: ", event_name, " -> ", position)
		
		# 验证位置是否生效
		call_deferred("_verify_card_position", card_instance, position, event_name)
	else:
		print("✗ 卡片实例无效，无法设置位置: ", event_name)

# 验证卡片位置
func _verify_card_position(card_instance: Node, expected_position: Vector2, event_name: String):
	if is_instance_valid(card_instance):
		var actual_position = card_instance.position
		if actual_position.distance_to(expected_position) < 1.0:
			print("✓ 卡片位置验证成功: ", event_name, " 位置: ", actual_position)
		else:
			print("⚠ 卡片位置异常: ", event_name, " 期望: ", expected_position, " 实际: ", actual_position)
	else:
		print("✗ 卡片实例无效，无法验证位置: ", event_name)

# 生成随机位置算法
func _generate_random_positions(card_count: int) -> Array[Vector2]:
	print("=== WeekendEventHotzoneManager._generate_random_positions 开始 ===")
	print("需要生成", card_count, "个位置")
	
	var positions: Array[Vector2] = []
	
	if not hotzone_container:
		return positions
	
	var container_size = hotzone_container.size
	var usable_area = container_size - hotzone_padding * 2
	
	# 使用类属性卡片大小
	var effective_card_size = card_size
	
	print("容器大小: ", container_size)
	print("可用区域: ", usable_area)
	print("卡片大小: ", effective_card_size)
	
	# 确保可用区域足够放置卡片
	if usable_area.x < effective_card_size.x or usable_area.y < effective_card_size.y:
		print("⚠ 容器太小，使用默认位置")
		for i in range(card_count):
			positions.append(Vector2(hotzone_padding.x, hotzone_padding.y + i * (effective_card_size.y + min_card_distance)))
		return positions
	
	# 选择分布算法
	if enable_diagonal_distribution:
		return _generate_diagonal_scattered_positions(card_count)
	
	# 计算可放置的最大范围
	var max_x = usable_area.x - effective_card_size.x
	var max_y = usable_area.y - effective_card_size.y
	
	for i in range(card_count):
		var position = _find_non_overlapping_position(positions, Vector2(max_x, max_y), effective_card_size)
		positions.append(position)
		print("位置", i+1, ": ", position)
	
	print("=== WeekendEventHotzoneManager._generate_random_positions 完成 ===")
	return positions

# 生成对角散乱分布位置
func _generate_diagonal_scattered_positions(card_count: int) -> Array[Vector2]:
	print("=== WeekendEventHotzoneManager._generate_diagonal_scattered_positions 开始 ===")
	print("需要生成", card_count, "个对角散乱位置")
	
	var positions: Array[Vector2] = []
	var container_size = hotzone_container.size
	var usable_area = container_size - hotzone_padding * 2
	var effective_card_size = card_size
	
	print("容器尺寸: ", container_size)
	print("可用区域: ", usable_area) 
	print("卡片尺寸: ", effective_card_size)
	print("内边距: ", hotzone_padding)
	
	# 确保可用区域足够
	if usable_area.x < effective_card_size.x or usable_area.y < effective_card_size.y:
		print("⚠ 可用区域太小，使用后备布局")
		for i in range(card_count):
			var pos = Vector2(hotzone_padding.x + i * 50, hotzone_padding.y + i * 30)
			positions.append(pos)
		return positions
	
	# 计算角落区域大小
	var corner_width = usable_area.x * corner_region_ratio
	var corner_height = usable_area.y * corner_region_ratio
	
	print("角落区域尺寸: ", corner_width, "x", corner_height)
	print("角落区域比例: ", corner_region_ratio)
	
	for i in range(card_count):
		var position: Vector2
		var found_valid_position = false
		var corner_attempts = 0
		var max_corner_attempts = 50
		
		if i == 0:
			# 第一张卡片：左上角区域
			while not found_valid_position and corner_attempts < max_corner_attempts:
				var max_x = max(0, corner_width - effective_card_size.x)
				var max_y = max(0, corner_height - effective_card_size.y)
				var x = hotzone_padding.x + randf() * max_x
				var y = hotzone_padding.y + randf() * max_y
				position = Vector2(x, y)
				
				if not _is_position_in_excluded_region(position, effective_card_size):
					found_valid_position = true
					print("卡片", i+1, "放置在左上角: ", position)
				else:
					corner_attempts += 1
			
		elif i == 1:
			# 第二张卡片：右下角区域
			while not found_valid_position and corner_attempts < max_corner_attempts:
				var start_x = hotzone_padding.x + (usable_area.x - corner_width)
				var start_y = hotzone_padding.y + (usable_area.y - corner_height)
				var max_x = max(0, corner_width - effective_card_size.x)
				var max_y = max(0, corner_height - effective_card_size.y)
				var x = start_x + randf() * max_x
				var y = start_y + randf() * max_y
				position = Vector2(x, y)
				
				if not _is_position_in_excluded_region(position, effective_card_size):
					found_valid_position = true
					print("卡片", i+1, "放置在右下角: ", position)
				else:
					corner_attempts += 1
			
		elif i == 2:
			# 第三张卡片：右上角或左下角随机选择
			var try_top_right = randf() > 0.5
			
			# 先尝试首选角落
			if try_top_right:
				while not found_valid_position and corner_attempts < max_corner_attempts / 2:
					var start_x = hotzone_padding.x + (usable_area.x - corner_width)
					var max_x = max(0, corner_width - effective_card_size.x)
					var max_y = max(0, corner_height - effective_card_size.y)
					var x = start_x + randf() * max_x
					var y = hotzone_padding.y + randf() * max_y
					position = Vector2(x, y)
					
					if not _is_position_in_excluded_region(position, effective_card_size):
						found_valid_position = true
						print("卡片", i+1, "放置在右上角: ", position)
					else:
						corner_attempts += 1
			
			# 如果首选角落失败，尝试左下角
			if not found_valid_position:
				corner_attempts = 0
				while not found_valid_position and corner_attempts < max_corner_attempts / 2:
					var start_y = hotzone_padding.y + (usable_area.y - corner_height)
					var max_x = max(0, corner_width - effective_card_size.x)
					var max_y = max(0, corner_height - effective_card_size.y)
					var x = hotzone_padding.x + randf() * max_x
					var y = start_y + randf() * max_y
					position = Vector2(x, y)
					
					if not _is_position_in_excluded_region(position, effective_card_size):
						found_valid_position = true
						print("卡片", i+1, "放置在左下角: ", position)
					else:
						corner_attempts += 1
		else:
			# 后续卡片：在剩余空间中散乱分布，避开排除区域
			var max_x = max(0, usable_area.x - effective_card_size.x)
			var max_y = max(0, usable_area.y - effective_card_size.y)
			position = _find_non_overlapping_position(positions, Vector2(max_x, max_y), effective_card_size)
			found_valid_position = true
			print("卡片", i+1, "散乱分布: ", position)
		
		# 如果特定角落策略失败，使用通用位置查找算法
		if not found_valid_position:
			print("⚠ 角落策略失败，使用通用位置查找算法")
			var max_x = max(0, usable_area.x - effective_card_size.x)
			var max_y = max(0, usable_area.y - effective_card_size.y)
			position = _find_non_overlapping_position(positions, Vector2(max_x, max_y), effective_card_size)
		
		# 确保位置在边界内
		position.x = clamp(position.x, hotzone_padding.x, container_size.x - effective_card_size.x - hotzone_padding.x)
		position.y = clamp(position.y, hotzone_padding.y, container_size.y - effective_card_size.y - hotzone_padding.y)
		
		positions.append(position)
		print("  最终位置: ", position)
	
	print("=== WeekendEventHotzoneManager._generate_diagonal_scattered_positions 完成 ===")
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
		
		# 检查是否在排除区域内
		if is_valid and _is_position_in_excluded_region(candidate_pos, card_size):
			is_valid = false
		
		if is_valid:
			return candidate_pos
		
		attempts += 1
	
	# 如果找不到合适位置，使用智能网格布局作为后备
	print("⚠ 无法找到不重叠位置，使用智能网格后备策略")
	return _generate_fallback_grid_position(existing_positions, card_size)

# 生成智能网格后备位置
func _generate_fallback_grid_position(existing_positions: Array[Vector2], card_size: Vector2) -> Vector2:
	var container_size = hotzone_container.size if hotzone_container else Vector2(1000, 600)
	var grid_spacing = Vector2(card_size.x + min_card_distance, card_size.y + min_card_distance)
	
	# 计算网格参数
	var cols = max(1, int((container_size.x - hotzone_padding.x * 2) / grid_spacing.x))
	var rows = max(1, int((container_size.y - hotzone_padding.y * 2) / grid_spacing.y))
	
	print("网格后备策略: ", cols, "列 x ", rows, "行")
	
	# 尝试网格位置，避开排除区域
	for row in range(rows):
		for col in range(cols):
			var grid_pos = Vector2(
				hotzone_padding.x + col * grid_spacing.x,
				hotzone_padding.y + row * grid_spacing.y
			)
			
			# 检查网格位置是否在排除区域内
			if not _is_position_in_excluded_region(grid_pos, card_size):
				# 检查是否与现有位置过近
				var is_too_close = false
				for existing_pos in existing_positions:
					var distance = grid_pos.distance_to(existing_pos)
					if distance < min_card_distance:
						is_too_close = true
						break
				
				if not is_too_close:
					print("✓ 找到有效网格位置: ", grid_pos)
					return grid_pos
	
	# 如果所有网格位置都被占用或在排除区域内，返回安全默认位置
	print("⚠ 所有网格位置都不可用，使用安全默认位置")
	var safe_default = Vector2(hotzone_padding.x, hotzone_padding.y)
	
	# 尝试在容器右下角找到安全位置
	if hotzone_container:
		var bottom_right = Vector2(
			hotzone_container.size.x - card_size.x - hotzone_padding.x,
			hotzone_container.size.y - card_size.y - hotzone_padding.y
		)
		
		if not _is_position_in_excluded_region(bottom_right, card_size):
			safe_default = bottom_right
			print("✓ 使用右下角安全位置: ", safe_default)
	
	return safe_default

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

# 初始化排除区域
func _initialize_excluded_regions():
	print("=== WeekendEventHotzoneManager._initialize_excluded_regions 开始 ===")
	
	if not hotzone_container:
		print("✗ 热区容器未设置，无法初始化排除区域")
		return
	
	# 清空现有排除区域
	excluded_regions.clear()
	
	# 定义其他三个热区在UILayer坐标系中的位置（更新为实际场景位置）
	var other_hotzones_uilayer = [
		Rect2(567, 196, 278, 77),   # DailyEventHotzone1 - 更新后的实际位置
		Rect2(595, 600, 300, 62),   # DailyEventHotzone2 - 更新后的实际位置
		Rect2(1279, 552, 224, 75)   # DailyEventHotzone3 - 更新后的实际位置
	]
	
	print("UILayer坐标系中的其他热区:")
	for i in range(other_hotzones_uilayer.size()):
		print("  热区", i+1, ": ", other_hotzones_uilayer[i])
	
	# 转换为WeekendEventHotzone4的本地坐标系
	for uilayer_rect in other_hotzones_uilayer:
		var local_rect = _convert_uilayer_to_local_coords(uilayer_rect)
		excluded_regions.append(local_rect)
		print("  转换为本地坐标: ", local_rect)
	
	print("✓ 初始化了", excluded_regions.size(), "个排除区域")
	_debug_excluded_regions()
	print("=== WeekendEventHotzoneManager._initialize_excluded_regions 完成 ===")

# 坐标转换：UILayer坐标 -> WeekendEventHotzone4本地坐标
func _convert_uilayer_to_local_coords(uilayer_rect: Rect2) -> Rect2:
	if not hotzone_container:
		return Rect2()
	
	# WeekendEventHotzone4在UILayer中的位置
	var weekend_hotzone_offset = Vector2(473, 112)
	
	# 转换位置
	var local_position = uilayer_rect.position - weekend_hotzone_offset
	
	# 扩展区域以包含缓冲区
	var expanded_rect = Rect2(
		local_position.x - region_padding,
		local_position.y - region_padding,
		uilayer_rect.size.x + region_padding * 2,
		uilayer_rect.size.y + region_padding * 2
	)
	
	return expanded_rect

# 检查位置是否在排除区域内
func _is_position_in_excluded_region(position: Vector2, card_size: Vector2) -> bool:
	# 创建卡片的矩形区域
	var card_rect = Rect2(position, card_size)
	
	# 检查是否与任一排除区域重叠
	for excluded_region in excluded_regions:
		if card_rect.intersects(excluded_region):
			return true
	
	return false

# 调试排除区域信息
func _debug_excluded_regions():
	print("=== WeekendEventHotzoneManager._debug_excluded_regions ===")
	print("排除区域数量: ", excluded_regions.size())
	print("区域缓冲距离: ", region_padding)
	
	if hotzone_container:
		print("容器尺寸: ", hotzone_container.size)
	
	for i in range(excluded_regions.size()):
		var region = excluded_regions[i]
		print("排除区域", i+1, ": 位置(", region.position.x, ",", region.position.y, ") 尺寸(", region.size.x, ",", region.size.y, ")")
	
	print("=== _debug_excluded_regions 完成 ===") 