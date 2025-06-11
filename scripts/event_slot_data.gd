class_name EventSlotData
extends Resource

# 卡槽数据类
# 定义事件卡槽的所有属性和行为

@export var event_id: int = 0
@export var slot_id: int = 0
@export var slot_description: String = ""
@export var allowed_card_types_json: String = "[]"
@export var specific_card_json: String = "{}"
@export var branch_id: int = 0
@export var controls_branch: bool = false
@export var contributes_to_check: bool = false
@export var effect_modifier_json: String = "{}"
@export var required_for_completion: bool = false
@export var mutually_exclusive_group: int = 0

# 缓存解析后的数据
var _allowed_card_types: Array = []
var _specific_card: Dictionary = {}
var _effect_modifier: Dictionary = {}

# 当前放置的卡牌信息
var placed_card_type: String = ""
var placed_card_id: String = ""
var placed_card_data = null

func _init():
	pass

# 解析允许的卡牌类型
func get_allowed_card_types() -> Array:
	if _allowed_card_types.is_empty() and not allowed_card_types_json.is_empty():
		var json = JSON.new()
		var error = json.parse(allowed_card_types_json)
		if error == OK:
			_allowed_card_types = json.data
		else:
			printerr("EventSlotData: 解析allowed_card_types失败: ", error)
			_allowed_card_types = []
	return _allowed_card_types

# 解析特定卡牌要求
func get_specific_card_requirements() -> Dictionary:
	if _specific_card.is_empty() and not specific_card_json.is_empty():
		var json = JSON.new()
		var error = json.parse(specific_card_json)
		if error == OK:
			_specific_card = json.data
		else:
			printerr("EventSlotData: 解析specific_card失败: ", error)
			_specific_card = {}
	return _specific_card

# 解析效果修正器
func get_effect_modifier() -> Dictionary:
	if _effect_modifier.is_empty() and not effect_modifier_json.is_empty():
		var json = JSON.new()
		var error = json.parse(effect_modifier_json)
		if error == OK:
			_effect_modifier = json.data
		else:
			printerr("EventSlotData: 解析effect_modifier失败: ", error)
			_effect_modifier = {}
	return _effect_modifier

# 检查卡牌类型是否允许
func is_card_type_allowed(card_type: String) -> bool:
	var allowed_types = get_allowed_card_types()
	return card_type in allowed_types

# 检查特定卡牌是否符合要求
func is_specific_card_valid(card_type: String, card_id: String, card_data = null) -> bool:
	var requirements = get_specific_card_requirements()
	if requirements.is_empty():
		print("EventSlotData: 无特定卡牌要求，验证通过")
		return true
	
	if requirements.has(card_type):
		var required_cards = requirements[card_type]
		print("EventSlotData: 验证卡牌要求 - 类型:", card_type, " 要求:", required_cards)
		
		# 对于特权卡，使用card_type进行验证
		if card_type == "特权卡" and card_data != null:
			var card_type_to_check = ""
			if card_data.has_method("get_card_type"):
				card_type_to_check = card_data.get_card_type()
			elif card_data.has("card_type"):
				card_type_to_check = card_data.card_type
			else:
				print("EventSlotData: 特权卡数据缺少card_type字段")
				return false
			
			print("EventSlotData: 特权卡验证 - 卡牌类型:", card_type_to_check, " 是否在要求中:", card_type_to_check in required_cards)
			
			if required_cards is Array:
				return card_type_to_check in required_cards
			else:
				return card_type_to_check == required_cards
		
		# 对于其他卡牌类型，使用card_id进行验证
		print("EventSlotData: 普通卡牌验证 - 卡牌ID:", card_id, " 是否在要求中:", card_id in required_cards)
		if required_cards is Array:
			return card_id in required_cards
		else:
			return card_id == required_cards
	
	print("EventSlotData: 卡牌类型不在要求列表中，验证通过")
	return true

# 放置卡牌
func place_card(card_type: String, card_id: String, card_data = null) -> bool:
	print("EventSlotData: 尝试放置卡牌 - 类型:", card_type, " ID:", card_id)
	
	if not is_card_type_allowed(card_type):
		print("EventSlotData: 卡牌类型不被允许: ", card_type)
		return false
	
	if not is_specific_card_valid(card_type, card_id, card_data):
		print("EventSlotData: 卡牌不符合特定要求 - 类型:", card_type, " ID:", card_id)
		return false
	
	placed_card_type = card_type
	placed_card_id = card_id
	placed_card_data = card_data
	print("EventSlotData: 卡牌放置成功 - 类型:", card_type, " ID:", card_id)
	return true

# 移除卡牌
func remove_card():
	placed_card_type = ""
	placed_card_id = ""
	placed_card_data = null

# 检查是否已放置卡牌
func has_card_placed() -> bool:
	return not placed_card_type.is_empty()

# 获取状态描述
func get_status_text() -> String:
	if has_card_placed():
		return "已放置: " + placed_card_type
	else:
		return slot_description

# 获取属性贡献
func get_attribute_contribution() -> Dictionary:
	if not has_card_placed() or not contributes_to_check:
		return {}
	
	var contribution = {}
	
	# 获取卡牌本身的属性
	if placed_card_data:
		if placed_card_data.has_method("get_attributes"):
			var card_attributes = placed_card_data.get_attributes()
			for attr_name in card_attributes:
				contribution[attr_name] = contribution.get(attr_name, 0) + card_attributes[attr_name]
	
	# 应用效果修正器
	var modifier = get_effect_modifier()
	if modifier.has("attribute_bonus"):
		var bonus = modifier["attribute_bonus"]
		for attr_name in bonus:
			contribution[attr_name] = contribution.get(attr_name, 0) + bonus[attr_name]
	
	return contribution

# 验证数据完整性
func validate() -> bool:
	if event_id <= 0:
		printerr("EventSlotData: event_id无效")
		return false
	
	if slot_id <= 0:
		printerr("EventSlotData: slot_id无效")
		return false
	
	if slot_description.is_empty():
		printerr("EventSlotData: slot_description为空")
		return false
	
	# 验证JSON格式
	var allowed_types = get_allowed_card_types()
	if allowed_types.is_empty():
		printerr("EventSlotData: allowed_card_types解析失败或为空")
		return false
	
	return true

# 获取调试信息
func get_debug_info() -> String:
	var info = "EventSlotData[%d-%d]: %s\n" % [event_id, slot_id, slot_description]
	info += "  允许类型: %s\n" % str(get_allowed_card_types())
	info += "  控制分支: %s\n" % str(controls_branch)
	info += "  参与检定: %s\n" % str(contributes_to_check)
	info += "  必须完成: %s\n" % str(required_for_completion)
	info += "  互斥组: %s\n" % str(mutually_exclusive_group)
	if has_card_placed():
		info += "  已放置卡牌: %s [%s]\n" % [placed_card_type, placed_card_id]
	return info

# 从TSV行数据解析
func parse_from_tsv_row(columns: Array) -> bool:
	if columns.size() < 11:
		printerr("EventSlotData: TSV行数据列数不足，需要至少11列")
		return false
	
	# 解析基本字段
	event_id = columns[0].to_int()
	slot_id = columns[1].to_int()
	slot_description = columns[2]
	allowed_card_types_json = columns[3]
	specific_card_json = columns[4]
	branch_id = columns[5].to_int()
	
	# 解析布尔字段
	var controls_value = columns[6].to_upper()
	controls_branch = (controls_value == "TRUE" or controls_value == "1")
	
	var contributes_value = columns[7].to_upper()
	contributes_to_check = (contributes_value == "TRUE" or contributes_value == "1")
	
	effect_modifier_json = columns[8]
	
	var required_value = columns[9].to_upper()
	required_for_completion = (required_value == "TRUE" or required_value == "1")
	
	# 解析互斥组字段
	if columns.size() > 10:
		mutually_exclusive_group = columns[10].to_int()
	else:
		mutually_exclusive_group = 0
	
	# 验证数据
	if not validate():
		return false
	
	print("EventSlotData: 解析成功 - 事件", event_id, "槽位", slot_id, ":", slot_description)
	return true 