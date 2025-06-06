class_name ItemCardData
extends Resource

@export var card_id: int
@export var card_name: String 
@export var card_level: String  # P1, P2, P3, P4
@export var card_type: String = "情报卡"
@export var attributes_json: String = "{}"  # JSON字符串格式的属性数据
@export var card_description: String = ""
@export var card_tags_json: String = "[]"  # JSON字符串格式的标签数组

# 缓存解析后的数据
var _attributes_dict: Dictionary = {}
var _tags_array: Array = []

# 获取道具卡底图路径
func get_card_base_path() -> String:
	return "res://assets/cards/道具卡_" + card_level + ".png"

# 获取情报卡图片路径
func get_item_image_path() -> String:
	return "res://assets/cards/情报卡/card_" + str(card_id) + ".png"

# 解析属性JSON
func get_attributes() -> Dictionary:
	if _attributes_dict.is_empty() and not attributes_json.is_empty():
		var json = JSON.new()
		var error = json.parse(attributes_json)
		if error == OK:
			_attributes_dict = json.data
		else:
			printerr("解析属性JSON失败: ", error)
			_attributes_dict = {}
	return _attributes_dict

# 获取格式化的属性显示文本
func get_formatted_attributes() -> String:
	var attributes = get_attributes()
	if attributes.is_empty():
		return "无属性加成"
	
	var attr_texts: Array[String] = []
	var attr_names = {
		"social": "社交",
		"execution": "执行", 
		"innovation": "创新",
		"resistance": "抗压",
		"physical": "体能"
	}
	
	for attr_key in attributes:
		var attr_value = attributes[attr_key]
		var attr_display_name = attr_names.get(attr_key, attr_key)
		attr_texts.append(attr_display_name + "+" + str(attr_value))
	
	return " ".join(attr_texts)

# 解析标签JSON
func get_tags() -> Array:
	if _tags_array.is_empty() and not card_tags_json.is_empty():
		var json = JSON.new()
		var error = json.parse(card_tags_json)
		if error == OK and json.data is Array:
			_tags_array = json.data
		else:
			printerr("解析标签JSON失败: ", error)
			_tags_array = []
	return _tags_array

# 获取格式化的标签显示文本
func get_formatted_tags() -> String:
	var tags = get_tags()
	if tags.is_empty():
		return ""
	
	var tag_strings: Array[String] = []
	for tag in tags:
		tag_strings.append("[" + str(tag) + "]")
	
	return " ".join(tag_strings)

# 从TSV行数据创建ItemCardData实例
static func from_tsv_row(columns: Array) -> ItemCardData:
	if columns.size() < 7:
		printerr("TSV行数据不完整，需要7列数据")
		return null
	
	var data = ItemCardData.new()
	data.card_id = columns[0].to_int()
	data.card_name = columns[1]
	data.card_level = columns[2]
	data.card_type = columns[3]
	data.attributes_json = columns[4]
	data.card_description = columns[5]
	data.card_tags_json = columns[6]
	
	return data

# 验证数据完整性
func validate() -> bool:
	if card_id <= 0:
		printerr("ItemCardData验证失败: card_id无效")
		return false
	
	if card_name.is_empty():
		printerr("ItemCardData验证失败: card_name为空")
		return false
	
	if not card_level in ["P1", "P2", "P3", "P4"]:
		printerr("ItemCardData验证失败: card_level无效: ", card_level)
		return false
	
	return true 