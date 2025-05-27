class_name CharacterMapping
extends Node

# 角色卡管理器引用
static var card_manager: CardManager

# 初始化保护标志
static var _is_initializing = false
static var _initialization_completed = false

# 初始化角色映射系统
static func initialize():
	# 如果已经初始化完成，直接返回
	if _initialization_completed and card_manager:
		return
	
	# 防止重复初始化
	if _is_initializing:
		print("CharacterMapping: 初始化正在进行中，跳过重复调用")
		return
	
	_is_initializing = true
	
	if not card_manager:
		# 使用自动加载的CharacterCardManager而不是创建新实例
		var autoload_manager = Engine.get_singleton("CharacterCardManager")
		if autoload_manager:
			card_manager = autoload_manager
			print("CharacterMapping: 使用自动加载的CharacterCardManager")
		else:
			# 回退方案：尝试通过场景树获取
			var scene_tree = Engine.get_main_loop() as SceneTree
			if scene_tree and scene_tree.root:
				card_manager = scene_tree.root.get_node_or_null("CharacterCardManager")
				if card_manager:
					print("CharacterMapping: 通过场景树获取CharacterCardManager")
				else:
					# 最后的回退方案：创建新实例
					card_manager = CardManager.new()
					print("警告: CharacterMapping创建新的CardManager实例（自动加载不可用）")
			else:
				card_manager = CardManager.new()
				print("警告: CharacterMapping创建新的CardManager实例（场景树不可用）")
	
	_initialization_completed = true
	_is_initializing = false

# 根据角色名称获取角色图片路径
static func get_character_image_path(character_name: String) -> String:
	if character_name.is_empty():
		print("警告: 角色名称为空")
		return ""
	
	# 安全的初始化检查
	if not _initialization_completed or not card_manager:
		initialize()
		if not card_manager:
			print("错误: CharacterMapping未能正确初始化")
			return ""
	
	var character_data = card_manager.get_character_data(character_name)
	if character_data:
		var image_path = character_data.get_character_image_path()
		print("CharacterMapping: 获取角色图片路径 - ", character_name, " -> ", image_path)
		return image_path
	else:
		print("CharacterMapping: 未找到角色图片路径 - ", character_name)
		return ""

# 根据角色名称获取角色数据
static func get_character_data(character_name: String) -> CharacterCardData:
	if character_name.is_empty():
		print("警告: 角色名称为空")
		return null
	
	# 安全的初始化检查
	if not _initialization_completed or not card_manager:
		initialize()
		if not card_manager:
			print("错误: CharacterMapping未能正确初始化")
			return null
	
	var character_data = card_manager.get_character_data(character_name)
	if character_data:
		print("CharacterMapping: 获取角色数据 - ", character_name)
		return character_data
	else:
		print("CharacterMapping: 未找到角色数据 - ", character_name)
		return null

# 验证角色是否存在
static func validate_character_exists(character_name: String) -> bool:
	if character_name.is_empty():
		print("警告: 角色名称为空")
		return false
	
	# 安全的初始化检查
	if not _initialization_completed or not card_manager:
		initialize()
		if not card_manager:
			print("错误: CharacterMapping未能正确初始化")
			return false
	
	var exists = card_manager.has_character(character_name)
	print("CharacterMapping: 验证角色存在性 - ", character_name, " -> ", exists)
	return exists

# 获取所有角色名称
static func get_all_character_names() -> Array:
	# 安全的初始化检查
	if not _initialization_completed or not card_manager:
		initialize()
		if not card_manager:
			print("错误: CharacterMapping未能正确初始化")
			return []
	
	var names = card_manager.get_all_character_names()
	print("CharacterMapping: 获取所有角色名称，数量: ", names.size())
	return names

# 根据角色名称获取角色属性
static func get_character_attributes(character_name: String) -> Dictionary:
	var character_data = get_character_data(character_name)
	if character_data:
		return character_data.get_attributes()
	return {}

# 调试方法：打印所有角色信息
static func debug_print_all_characters():
	initialize()
	
	if not card_manager:
		print("错误: CharacterMapping - card_manager未初始化，无法打印角色信息")
		return
	
	print("=== CharacterMapping角色信息 ===")
	var all_cards = card_manager.get_all_cards()
	for card in all_cards:
		print("角色: ", card.card_name, " | ID: ", card.card_id, " | 图片: ", card.card_picture)
	print("=== 总计: ", all_cards.size(), " 个角色 ===")

# 获取管理器状态信息
static func get_manager_info() -> Dictionary:
	initialize()
	
	var info = {
		"manager_initialized": card_manager != null,
		"manager_type": "",
		"total_cards": 0
	}
	
	if card_manager:
		info.manager_type = card_manager.get_script().resource_path if card_manager.get_script() else "Unknown"
		info.total_cards = card_manager.get_all_cards().size()
	
	return info 
