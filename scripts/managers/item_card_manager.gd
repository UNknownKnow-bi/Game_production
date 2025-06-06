extends Node

# 单例模式
static var instance: ItemCardManager

# 数据存储
var all_item_cards: Array[ItemCardData] = []
var item_cards_by_id: Dictionary = {}

# 数据文件路径
const ITEM_CARDS_DATA_PATH = "res://data/item/item_cards"

# 初始化
func _ready():
	if instance == null:
		instance = self
		print("=== ItemCardManager 初始化开始 ===")
		load_item_cards_data()
	else:
		queue_free()

# 加载情报卡数据
func load_item_cards_data():
	print("ItemCardManager: 开始加载情报卡数据")
	
	if not FileAccess.file_exists(ITEM_CARDS_DATA_PATH):
		print("⚠ 情报卡数据文件不存在: ", ITEM_CARDS_DATA_PATH)
		return
	
	var file = FileAccess.open(ITEM_CARDS_DATA_PATH, FileAccess.READ)
	if not file:
		printerr("✗ 无法打开情报卡数据文件: ", ITEM_CARDS_DATA_PATH)
		return
	
	# 读取表头
	var header_line = file.get_line()
	if header_line.is_empty():
		print("⚠ 情报卡数据文件为空")
		file.close()
		return
	
	print("情报卡数据表头: ", header_line.split("\t"))
	
	# 逐行读取数据
	var line_count = 1
	while not file.eof_reached():
		var line = file.get_line()
		if line.is_empty():
			continue
		
		line_count += 1
		var fields = line.split("\t")
		
		# 验证字段数量
		if fields.size() != 7:
			print("⚠ 第", line_count, "行字段数量不正确，期望7个，实际", fields.size(), "个")
			continue
		
		# 创建ItemCardData
		var card_data = ItemCardData.new()
		card_data.card_id = int(fields[0].strip_edges())
		card_data.card_name = fields[1].strip_edges()
		card_data.card_level = fields[2].strip_edges()
		card_data.card_type = fields[3].strip_edges()
		card_data.attributes_json = fields[4].strip_edges()
		card_data.card_description = fields[5].strip_edges()
		card_data.card_tags_json = fields[6].strip_edges()
		
		# 存储数据
		all_item_cards.append(card_data)
		item_cards_by_id[card_data.card_id] = card_data
		
		print("✓ 加载情报卡: ID=", card_data.card_id, " 名称=", card_data.card_name)
	
	file.close()
	print("=== 情报卡数据加载完成，总计: ", all_item_cards.size(), " 张 ===")

# 获取所有情报卡
func get_all_cards() -> Array[ItemCardData]:
	return all_item_cards

# 根据ID获取情报卡
func get_card_by_id(card_id: int) -> ItemCardData:
	return item_cards_by_id.get(card_id, null)

# 静态访问方法
static func get_instance():
	return instance 
