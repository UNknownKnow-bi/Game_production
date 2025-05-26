class_name CardManager
extends Node

# 存储所有角色卡数据
var cards: Dictionary = {}  # 以card_id为键

# 数据文件路径
const CARDS_DATA_PATH = "res://data/character/character_cards.tsv"

func _ready():
	load_cards_from_tsv(CARDS_DATA_PATH)

# 从TSV文件加载卡片数据
func load_cards_from_tsv(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		printerr("无法打开角色卡数据文件: ", file_path)
		return
		
	var content = file.get_as_text()
	file.close()
	
	var lines = content.split("\n")
	var header = lines[0].split("\t")
	
	# 查找各字段在表头中的索引位置
	var indices = {
		"card_id": header.find("card_id"),
		"card_name": header.find("card_name"),
		"card_pictures": header.find("card_pictures"),
		"card_level": header.find("card_level"),
		"company_name": header.find("company_name"),
		"job_title": header.find("job_title"),
		"card_type": header.find("card_type"),
		"attributes_orgin": header.find("attributes_orgin"),
		"character_description": header.find("character_description"),
		"is_unlocked_by_default": header.find("is_unlocked_by_default"),
		"tags": header.find("tags")
	}
	
	# 从第二行开始解析数据
	for i in range(1, lines.size()):
		var line = lines[i].strip_edges()
		if line.is_empty():
			continue
			
		var columns = line.split("\t")
		if columns.size() < 4:  # 至少需要id、名称、图片和等级
			continue
			
		# 创建角色卡数据对象
		var card_data = CharacterCardData.new()
		
		# 设置基本字段
		if indices.card_id >= 0 and indices.card_id < columns.size():
			card_data.card_id = columns[indices.card_id]
		else:
			continue  # 没有ID则跳过
			
		if indices.card_name >= 0 and indices.card_name < columns.size():
			card_data.card_name = columns[indices.card_name]
			
		if indices.card_pictures >= 0 and indices.card_pictures < columns.size():
			card_data.card_picture = columns[indices.card_pictures]
			
		if indices.card_level >= 0 and indices.card_level < columns.size():
			card_data.card_level = columns[indices.card_level]
			
		# 设置可选字段
		if indices.company_name >= 0 and indices.company_name < columns.size():
			card_data.company_name = columns[indices.company_name]
			
		if indices.job_title >= 0 and indices.job_title < columns.size():
			card_data.job_title = columns[indices.job_title]
			
		if indices.card_type >= 0 and indices.card_type < columns.size():
			card_data.card_type = columns[indices.card_type]
			
		# 设置属性数据（JSON格式）
		if indices.attributes_orgin >= 0 and indices.attributes_orgin < columns.size():
			card_data.attributes_orgin = columns[indices.attributes_orgin]
			
		# 设置角色描述
		if indices.character_description >= 0 and indices.character_description < columns.size():
			card_data.character_description = columns[indices.character_description]
			
		# 设置解锁状态
		if indices.is_unlocked_by_default >= 0 and indices.is_unlocked_by_default < columns.size():
			var unlock_value = columns[indices.is_unlocked_by_default]
			card_data.is_unlocked_by_default = unlock_value == "1" or unlock_value.to_lower() == "true"
			
		# 设置标签（JSON数组格式）
		if indices.tags >= 0 and indices.tags < columns.size():
			var tags_json = columns[indices.tags]
			card_data.set_tags_from_data(tags_json)
		
		# 将数据添加到字典
		cards[card_data.card_id] = card_data
	
	print("已加载 %d 个角色卡" % cards.size())

# 根据ID获取卡片数据
func get_card_by_id(card_id: String) -> CharacterCardData:
	if cards.has(card_id):
		return cards[card_id]
	return null

# 获取所有卡片
func get_all_cards() -> Array:
	return cards.values()

# 根据等级获取卡片
func get_cards_by_level(level: String) -> Array:
	var result = []
	for card_id in cards:
		var card = cards[card_id]
		if card.card_level == level:
			result.append(card)
	return result

# 获取所有已解锁的卡片
func get_unlocked_cards() -> Array:
	var result = []
	for card_id in cards:
		var card = cards[card_id]
		if card.is_unlocked_by_default:
			result.append(card)
	return result

# 根据卡片类型筛选
func get_cards_by_type(card_type: String) -> Array:
	var result = []
	for card_id in cards:
		var card = cards[card_id]
		if card.card_type == card_type:
			result.append(card)
	return result

# 根据角色名称获取角色卡数据
func get_character_data(character_name: String) -> CharacterCardData:
	if character_name.is_empty():
		return null
	
	for card_id in cards:
		var card_data = cards[card_id]
		if card_data.card_name == character_name:
			return card_data
	return null

# 检查角色是否存在
func has_character(character_name: String) -> bool:
	return get_character_data(character_name) != null

# 获取所有角色名称
func get_all_character_names() -> Array:
	var names = []
	for card_id in cards:
		names.append(cards[card_id].card_name)
	return names 
