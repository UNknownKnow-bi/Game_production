class_name WeekendEventCardFactory
extends Node

# 卡片场景资源
static var weekend_random_card_scene: PackedScene
static var weekend_character_card_scene: PackedScene

# 初始化场景资源
static func _static_init():
	weekend_random_card_scene = load("res://scenes/weekend/components/weekend_random_event_card.tscn")
	weekend_character_card_scene = load("res://scenes/weekend/components/weekend_character_event_card.tscn")

# 根据GameEvent创建适合的周末卡片
static func create_weekend_card(game_event: GameEvent) -> Control:
	print("=== WeekendEventCardFactory.create_weekend_card 开始 ===")
	print("事件ID: ", game_event.event_id)
	print("事件类型: ", game_event.event_type)
	print("事件名称: ", game_event.event_name)
	print("角色名称原始: '", game_event.character_name, "' (长度:", game_event.character_name.length(), ")")
	
	# 清理character_name字段，处理占位符
	var cleaned_character_name = game_event.character_name.strip_edges()
	# 将各种占位符识别为空字符串
	if cleaned_character_name == "{}" or cleaned_character_name == "null" or cleaned_character_name == "NULL":
		cleaned_character_name = ""
	
	print("角色名称清理后: '", cleaned_character_name, "' (长度:", cleaned_character_name.length(), ")")
	
	# 确保场景资源已加载
	if not weekend_random_card_scene:
		weekend_random_card_scene = load("res://scenes/weekend/components/weekend_random_event_card.tscn")
	if not weekend_character_card_scene:
		weekend_character_card_scene = load("res://scenes/weekend/components/weekend_character_event_card.tscn")
	
	var card_instance = null
	
	# 根据事件类型选择卡片类型
	if game_event.event_type == "人物事件" and not cleaned_character_name.is_empty():
		print("创建周末人物事件卡片")
		print("  判断依据: event_type=='人物事件': ", game_event.event_type == "人物事件")
		print("  判断依据: 有有效角色名称: ", not cleaned_character_name.is_empty())
		card_instance = _create_weekend_character_card(game_event)
	elif game_event.event_type == "daily":
		print("创建周末日常事件卡片")
		print("  判断依据: event_type=='daily': ", game_event.event_type == "daily")
		# 对于日常事件，检查是否有weekend_daily卡片场景
		card_instance = _create_weekend_daily_card(game_event)
		if not card_instance:
			print("  fallback: 使用随机事件卡片代替")
			card_instance = _create_weekend_random_card(game_event)
	else:
		print("创建周末随机事件卡片")
		print("  判断依据: 随机事件或无有效角色名称")
		print("  事件类型: ", game_event.event_type)
		print("  角色名称为空: ", cleaned_character_name.is_empty())
		card_instance = _create_weekend_random_card(game_event)
	
	if card_instance:
		print("✓ 周末卡片创建成功 - 类型: ", card_instance.get_class())
	else:
		print("✗ 周末卡片创建失败")
	
	print("=== WeekendEventCardFactory.create_weekend_card 完成 ===")
	return card_instance

# 创建周末随机事件卡片
static func _create_weekend_random_card(game_event: GameEvent) -> WeekendRandomEventCard:
	print("=== WeekendEventCardFactory._create_weekend_random_card 开始 ===")
	
	if not weekend_random_card_scene:
		print("✗ 周末随机卡片场景未加载")
		return null
	
	var card_instance = weekend_random_card_scene.instantiate()
	if not card_instance:
		print("✗ 周末随机卡片实例化失败")
		return null
	
	print("✓ 周末随机卡片实例化成功")
	
	# 使用WeekendRandomEventCard的initialize_from_game_event方法
	if card_instance.has_method("initialize_from_game_event"):
		card_instance.initialize_from_game_event(game_event)
		print("✓ 使用专用初始化方法完成")
	else:
		# 手动初始化
		card_instance.set_game_event(game_event)
		card_instance.set_event_title(game_event.event_name)
		print("✓ 使用手动初始化完成")
	
	print("=== WeekendEventCardFactory._create_weekend_random_card 完成 ===")
	return card_instance

# 创建周末人物事件卡片
static func _create_weekend_character_card(game_event: GameEvent) -> WeekendCharacterEventCard:
	print("=== WeekendEventCardFactory._create_weekend_character_card 开始 ===")
	
	if not weekend_character_card_scene:
		print("✗ 周末人物卡片场景未加载")
		return null
	
	var card_instance = weekend_character_card_scene.instantiate()
	if not card_instance:
		print("✗ 周末人物卡片实例化失败")
		return null
	
	print("✓ 周末人物卡片实例化成功")
	
	# 使用WeekendCharacterEventCard的initialize_from_game_event方法
	if card_instance.has_method("initialize_from_game_event"):
		card_instance.initialize_from_game_event(game_event)
		print("✓ 使用专用初始化方法完成，包含角色图片加载")
	else:
		# 手动初始化
		card_instance.set_game_event(game_event)
		card_instance.set_event_title(game_event.event_name)
		card_instance.set_character_name(game_event.character_name)
		
		# 加载角色图片
		if not game_event.character_name.is_empty():
			_load_character_image(card_instance, game_event.character_name)
		
		print("✓ 使用手动初始化完成")
	
	print("=== WeekendEventCardFactory._create_weekend_character_card 完成 ===")
	return card_instance

# 创建周末日常事件卡片
static func _create_weekend_daily_card(game_event: GameEvent):
	print("=== WeekendEventCardFactory._create_weekend_daily_card 开始 ===")
	
	# 尝试加载weekend_daily_event_card场景
	var weekend_daily_card_scene = load("res://scenes/weekend/components/weekend_daily_event_card.tscn")
	
	if not weekend_daily_card_scene:
		print("✗ 周末日常卡片场景未找到，返回null")
		return null
	
	var card_instance = weekend_daily_card_scene.instantiate()
	if not card_instance:
		print("✗ 周末日常卡片实例化失败")
		return null
	
	print("✓ 周末日常卡片实例化成功")
	
	# 使用日常卡片的初始化方法
	if card_instance.has_method("initialize_from_game_event"):
		card_instance.initialize_from_game_event(game_event)
		print("✓ 使用专用初始化方法完成")
	elif card_instance.has_method("set_game_event"):
		card_instance.set_game_event(game_event)
		if card_instance.has_method("set_event_title"):
			card_instance.set_event_title(game_event.event_name)
		print("✓ 使用手动初始化完成")
	else:
		print("⚠ 卡片没有标准初始化方法，仅完成基本设置")
	
	print("=== WeekendEventCardFactory._create_weekend_daily_card 完成 ===")
	return card_instance

# 加载角色图片的辅助方法
static func _load_character_image(card: WeekendCharacterEventCard, character_name: String):
	print("=== WeekendEventCardFactory._load_character_image 开始 ===")
	print("角色名称: ", character_name)
	
	var image_path = CharacterMapping.get_character_image_path(character_name)
	if image_path and image_path != "":
		print("找到角色图片路径: ", image_path)
		var texture = load(image_path)
		if texture:
			card.set_character_texture(texture)
			# 启用图像裁剪
			card.set_region_enabled(true)
			card.set_region_y_position(0.0)
			card.set_region_height(0.45)
			print("✓ 角色图片加载并设置成功")
		else:
			print("✗ 无法加载角色图片: ", image_path)
	else:
		print("✗ 未找到角色图片路径")
	
	print("=== WeekendEventCardFactory._load_character_image 完成 ===")

# 批量创建周末卡片
static func create_weekend_cards(game_events: Array[GameEvent]) -> Array:
	print("=== WeekendEventCardFactory.create_weekend_cards 开始 ===")
	print("待创建卡片数量: ", game_events.size())
	
	var cards = []
	
	for i in range(game_events.size()):
		var event = game_events[i]
		var card = create_weekend_card(event)
		if card:
			cards.append(card)
			print("✓ 卡片", i+1, "创建成功: ", event.event_name)
		else:
			print("✗ 卡片", i+1, "创建失败: ", event.event_name)
	
	print("成功创建", cards.size(), "张卡片，共", game_events.size(), "个事件")
	print("=== WeekendEventCardFactory.create_weekend_cards 完成 ===")
	return cards

# 为热区创建卡片并设置随机位置
static func create_cards_for_hotzone(game_events: Array[GameEvent], hotzone_container: Control, enable_random_pos: bool = true) -> Array:
	print("=== WeekendEventCardFactory.create_cards_for_hotzone 开始 ===")
	print("事件数量: ", game_events.size())
	print("随机定位: ", enable_random_pos)
	
	var cards = []
	var positions = []
	
	# 创建所有卡片
	for event in game_events:
		var card = create_weekend_card(event)
		if card:
			cards.append(card)
		
	# 生成位置（如果启用随机定位）
	if enable_random_pos and cards.size() > 0:
		positions = _generate_random_positions_for_cards(cards, hotzone_container)
	
	# 将卡片添加到容器并设置位置
	for i in range(cards.size()):
		var card = cards[i]
		hotzone_container.add_child(card)
		
		if enable_random_pos and i < positions.size():
			card.position = positions[i]
			print("卡片", i+1, "设置随机位置: ", positions[i])
		else:
			print("卡片", i+1, "使用默认位置")
	
	print("✓ 为热区创建并放置了", cards.size(), "张卡片")
	print("=== WeekendEventCardFactory.create_cards_for_hotzone 完成 ===")
	return cards

# 为卡片生成随机位置
static func _generate_random_positions_for_cards(cards: Array, container: Control) -> Array[Vector2]:
	print("=== WeekendEventCardFactory._generate_random_positions_for_cards 开始 ===")
	
	var positions: Array[Vector2] = []
	var container_size = container.size
	var padding = Vector2(10, 10)
	var min_distance = 20.0
	var max_attempts = 100
	
	# 获取卡片大小（假设所有卡片大小相同）
	var card_size = Vector2(240, 140)  # 更新的卡片大小
	if cards.size() > 0 and cards[0].has_method("get_size"):
		card_size = cards[0].get_size()
	
	print("容器大小: ", container_size)
	print("卡片大小: ", card_size)
	print("内边距: ", padding)
	
	var usable_area = container_size - padding * 2
	var max_x = usable_area.x - card_size.x
	var max_y = usable_area.y - card_size.y
	
	# 为每张卡片生成位置
	for i in range(cards.size()):
		var position = _find_valid_position(positions, Vector2(max_x, max_y), card_size, padding, min_distance, max_attempts)
		positions.append(position)
		print("卡片", i+1, "位置: ", position)
	
	print("=== WeekendEventCardFactory._generate_random_positions_for_cards 完成 ===")
	return positions

# 寻找有效的随机位置
static func _find_valid_position(existing_positions: Array[Vector2], max_pos: Vector2, card_size: Vector2, padding: Vector2, min_distance: float, max_attempts: int) -> Vector2:
	var attempts = 0
	
	while attempts < max_attempts:
		var x = padding.x + randf() * max_pos.x
		var y = padding.y + randf() * max_pos.y
		var candidate_pos = Vector2(x, y)
		
		# 检查与现有位置的距离
		var is_valid = true
		for existing_pos in existing_positions:
			var distance = candidate_pos.distance_to(existing_pos)
			var required_distance = min_distance + (card_size.length() / 2)
			
			if distance < required_distance:
				is_valid = false
				break
		
		if is_valid:
			return candidate_pos
		
		attempts += 1
	
	# 后备位置：网格布局
	var grid_cols = 3
	var grid_x = (existing_positions.size() % grid_cols) * (card_size.x + min_distance)
	var grid_y = (existing_positions.size() / grid_cols) * (card_size.y + min_distance)
	return Vector2(padding.x + grid_x, padding.y + grid_y)

# 验证valid_rounds逻辑的辅助方法
static func validate_card_valid_rounds(card, expected_rounds: Array[int]) -> bool:
	if not card or not card.has_method("get_game_event"):
		return false
	
	var game_event = card.get_game_event()
	if not game_event:
		return false
	
	var actual_rounds = game_event.valid_rounds
	print("验证valid_rounds - 期望: ", expected_rounds, " 实际: ", actual_rounds)
	
	return actual_rounds == expected_rounds

# 获取卡片状态信息的调试方法
static func get_card_debug_info(card) -> Dictionary:
	var info = {
		"valid": is_instance_valid(card),
		"class": card.get_class() if is_instance_valid(card) else "null",
		"title": "",
		"type": "",
		"valid_rounds": [],
		"completed": false
	}
	
	if is_instance_valid(card):
		if card.has_method("get_game_event"):
			var event = card.get_game_event()
			if event:
				info.title = event.event_name
				info.type = event.event_type
				info.valid_rounds = event.valid_rounds
		
		if card.has_method("get_completion_status"):
			info.completed = card.get_completion_status()
		elif card.has_method("get") and "is_completed" in card:
			info.completed = card.is_completed
	
	return info 
 
