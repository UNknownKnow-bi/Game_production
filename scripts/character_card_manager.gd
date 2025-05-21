class_name CardManager
extends Node

# 存储所有角色卡数据
var cards: Dictionary = {}  # 以card_id为键

# 数据文件路径
const CARDS_DATA_PATH = "res://data/character_cards.tsv"

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
	
	# 从第二行开始解析数据
	for i in range(1, lines.size()):
		var line = lines[i].strip_edges()
		if line.is_empty():
			continue
			
		var columns = line.split("\t")
		if columns.size() < header.size():
			continue
			
		# 创建角色卡数据对象
		var card_data = CharacterCardData.new()
		card_data.card_id = columns[0]
		card_data.card_name = columns[1]
		card_data.card_picture = columns[2]
		card_data.card_level = columns[3]
		
		# 如果有公司名称字段，则设置
		if columns.size() > 4:
			card_data.company_name = columns[4]
			
		# 如果有职位字段，则设置
		if columns.size() > 5:
			card_data.job_title = columns[5]
		
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
