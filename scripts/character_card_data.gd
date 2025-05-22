class_name CharacterCardData
extends Resource

@export var card_id: String
@export var card_name: String 
@export var card_picture: String  # 存储相对路径
@export var card_level: String  # P1, P2, P3, P4
@export var company_name: String = "WonderTech"
@export var job_title: String = "生态员工"  # 职位信息，可选
@export var card_type: String = "角色"  # 卡片类型
@export var attributes_orgin: String = "{}"  # JSON字符串格式的属性数据
@export var character_description: String = ""  # 角色描述
@export var is_unlocked_by_default: bool = false  # 是否默认解锁
@export var tags: Array[String] = []  # 标签数组

# 缓存解析后的属性数据
var _attributes_dict: Dictionary = {}

# 获取资源路径
func get_character_image_path() -> String:
	return "res://assets/character/" + card_picture

func get_card_face_path() -> String:
	return "res://assets/cards/" + card_level + ".png"
	
func get_card_overlay_path() -> String:
	return "res://assets/cards/" + card_level + "_cloud.png"

# 解析属性JSON
func get_attributes() -> Dictionary:
	if _attributes_dict.is_empty() and not attributes_orgin.is_empty():
		var json = JSON.new()
		var error = json.parse(attributes_orgin)
		if error == OK:
			_attributes_dict = json.data
		else:
			printerr("解析属性JSON失败: ", error)
	return _attributes_dict

# 获取特定属性值
func get_attribute_value(attribute_name: String) -> int:
	var attributes = get_attributes()
	if attributes.has(attribute_name):
		return attributes[attribute_name]
	return 0

# 获取属性列表（用于显示）
func get_attributes_list() -> Array:
	var attributes = get_attributes()
	var result = []
	for key in attributes:
		result.append({"name": key, "value": attributes[key]})
	return result

# 获取格式化的标签字符串
func get_formatted_tags() -> String:
	if tags.is_empty():
		return ""
	return " ".join(tags)

# 设置属性值（从字典）
func set_attributes_from_dict(attributes_dict: Dictionary) -> void:
	_attributes_dict = attributes_dict
	attributes_orgin = JSON.stringify(attributes_dict)

# 设置标签（从数组或JSON字符串）
func set_tags_from_data(tags_data) -> void:
	# 清空现有标签
	tags.clear()
	
	var temp_array = []
	
	# 解析数据源
	if tags_data is String:
		var json = JSON.new()
		var error = json.parse(tags_data)
		if error == OK:
			temp_array = json.data
		else:
			printerr("解析标签JSON失败: ", error)
			return
	elif tags_data is Array:
		temp_array = tags_data
	else:
		return  # 不支持的数据类型
	
	# 将临时数组中的每个元素添加到强类型数组中
	for item in temp_array:
		if item is String:
			tags.append(item)
		else:
			# 尝试将非字符串转换为字符串
			tags.append(str(item)) 
