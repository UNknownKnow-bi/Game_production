class_name EventCardFactory
extends Node

# 根据事件类型创建卡片
static func create_card(event_type: String):
	var card_scene_path = ""
	
	match event_type:
		"character":
			card_scene_path = "res://scenes/workday_new/components/character_event_card_fixed.tscn"
		"random":
			card_scene_path = "res://scenes/workday_new/components/random_event_card.tscn"
		_:
			# 使用基础事件卡片
			card_scene_path = "res://scenes/workday_new/components/base_event_card.tscn"
	
	var card_scene = load(card_scene_path)
	if card_scene:
		return card_scene.instantiate()
	else:
		printerr("无法加载事件卡片场景: ", card_scene_path)
		return null

# 初始化卡片内容 - 支持Dictionary和GameEvent两种数据源
static func initialize_card(card, event_data):
	if card == null:
		return
	
	# 处理GameEvent对象
	if event_data is GameEvent:
		initialize_card_from_game_event(card, event_data)
		return
	
	# 处理Dictionary数据（保持向后兼容）
	if not event_data is Dictionary:
		return
	
	initialize_card_from_dictionary(card, event_data)

# 从GameEvent对象初始化卡片
static func initialize_card_from_game_event(card, game_event: GameEvent):
	if card == null or game_event == null:
		print("EventCardFactory: 错误 - card或game_event为null")
		return
	
	print("EventCardFactory: 开始初始化卡片 - 事件: ", game_event.event_name, " | 类型: ", game_event.get_event_category())
	
	# 设置游戏事件引用
	card.set_game_event(game_event)
	
	# 验证设置是否成功
	var set_event = card.get_game_event()
	if set_event == game_event:
		print("EventCardFactory: ✓ game_event设置成功 - ", game_event.event_name)
	else:
		print("EventCardFactory: ✗ 错误 - game_event设置失败")
		return
	
	# 根据卡片类型进行不同的初始化
	if card is CharacterEventCardFixed:
		_initialize_character_card(card, game_event)
	elif card is RandomEventCard:
		_initialize_random_card(card, game_event)
	else:
		# 通用卡片初始化
		card.event_title = game_event.event_name
		if card.has_method("set_event_status"):
			card.event_status = "new"  # 默认状态

# 初始化人物事件卡片
static func _initialize_character_card(card: CharacterEventCardFixed, game_event: GameEvent):
	card.event_title = game_event.event_name
	card.character_name = game_event.character_name
	card.event_status = "new"  # 默认状态
	
	# 自动获取角色图片
	if not game_event.character_name.is_empty():
		var character_image_path = CharacterMapping.get_character_image_path(game_event.character_name)
		if not character_image_path.is_empty():
			print("EventCardFactory: 找到角色图片路径: ", character_image_path)
			var char_texture = load(character_image_path)
			if char_texture:
				card.character_texture = char_texture
				card.region_enabled = true
				card.region_y_position = 0.0
				card.region_height = 0.45
				print("EventCardFactory: ✓ 角色图片加载成功")
			else:
				print("EventCardFactory: ✗ 警告 - 无法加载角色图像: ", character_image_path)
		else:
			print("EventCardFactory: ✗ 警告 - 未找到角色 '", game_event.character_name, "' 的图片路径")
	else:
		print("EventCardFactory: 事件无关联角色")
	
	# 设置统一字体大小
	card.title_font_size = 50
	card.name_font_size = 50
	
	print("EventCardFactory: ✓ 人物卡片初始化完成 - 标题: ", card.event_title, " | 角色: ", card.character_name)

# 初始化随机事件卡片
static func _initialize_random_card(card: RandomEventCard, game_event: GameEvent):
	card.event_title = game_event.event_name
	
	# 根据事件状态设置完成状态（这里可以根据实际需求调整）
	card.is_completed = false  # 默认为未完成
	
	# 设置字体大小
	card.title_font_size = 24
	
	print("EventCardFactory: ✓ 随机卡片初始化完成 - 标题: ", card.event_title)

# 从Dictionary初始化卡片（保持向后兼容）
static func initialize_card_from_dictionary(card, event_data: Dictionary):
	print("⚠️ EventCardFactory: 警告 - initialize_card_from_dictionary方法已废弃，建议使用initialize_card_from_game_event")
	
	# 设置基本属性
	if "title" in event_data:
		card.event_title = event_data.title
	
	if "status" in event_data:
		card.event_status = event_data.status
	
	# 人物事件特有属性
	if card is CharacterEventCardFixed:
		if "character" in event_data:
			card.character_name = event_data.character
		
		# 尝试加载角色纹理
		var texture_path = null
		if "character_texture_path" in event_data:
			texture_path = event_data.character_texture_path
		elif "texture_path" in event_data:
			texture_path = event_data.texture_path
			
		if texture_path:
			var char_texture = load(texture_path)
			if char_texture:
				# 设置纹理（必须先设置纹理再设置区域参数）
				card.character_texture = char_texture
				
				# 处理区域裁剪设置
				if "region_enabled" in event_data:
					card.region_enabled = event_data.region_enabled
					
				if "region_y_position" in event_data:
					card.region_y_position = event_data.region_y_position
					
				if "region_height" in event_data:
					card.region_height = event_data.region_height
			else:
				print("警告: 无法加载角色图像: ", texture_path)
		
		# 始终设置字体大小为50px，确保所有卡片使用统一字体大小
		card.title_font_size = 50
		card.name_font_size = 50
			
		# 设置背景类型（如果指定）
		if "bg_type" in event_data:
			card.background_type = event_data.bg_type
			
		# 调试信息：打印初始化后的字体大小
		print("初始化卡片: ", card.event_title, " - 标题字体大小: ", card.title_font_size, ", 人物名称字体大小: ", card.name_font_size) 
