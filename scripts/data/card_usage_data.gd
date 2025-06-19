class_name CardUsageData
extends Resource

# 卡牌使用数据类
# 记录卡牌在当前回合中的使用状态和详细信息

@export var card_type: String = ""
@export var card_id: String = ""
@export var event_id: int = 0
@export var slot_id: int = 0
@export var usage_timestamp: float = 0.0

# 延迟结算相关字段
@export var settlement_round: int = -1        # 预期释放回合
@export var settlement_scene_type: String = "" # 释放场景类型
@export var is_duration_busy: bool = false    # 是否为延迟结算忙碌

func _init():
	pass

# 从字典数据初始化
func from_dict(data: Dictionary):
	card_type = data.get("card_type", "")
	card_id = data.get("card_id", "")
	event_id = data.get("event_id", 0)
	slot_id = data.get("slot_id", 0)
	usage_timestamp = data.get("usage_timestamp", 0.0)
	settlement_round = data.get("settlement_round", -1)
	settlement_scene_type = data.get("settlement_scene_type", "")
	is_duration_busy = data.get("is_duration_busy", false)

# 转换为字典
func to_dict() -> Dictionary:
	return {
		"card_type": card_type,
		"card_id": card_id,
		"event_id": event_id,
		"slot_id": slot_id,
		"usage_timestamp": usage_timestamp,
		"settlement_round": settlement_round,
		"settlement_scene_type": settlement_scene_type,
		"is_duration_busy": is_duration_busy
	}

# 获取使用时间的可读格式
func get_formatted_usage_time() -> String:
	var datetime = Time.get_datetime_dict_from_unix_time(usage_timestamp)
	return "%02d:%02d:%02d" % [datetime.hour, datetime.minute, datetime.second]

# 检查数据有效性
func is_valid() -> bool:
	return not card_type.is_empty() and not card_id.is_empty() and event_id > 0 and slot_id > 0

# 获取唯一标识符
func get_unique_key() -> String:
	return card_type + "|" + card_id

# 获取描述性文本
func get_description() -> String:
	var base_desc = "%s[%s] 在事件%d的槽位%d中使用 (时间: %s)" % [
		card_type, card_id, event_id, slot_id, get_formatted_usage_time()
	]
	
	if is_duration_busy:
		base_desc += " [延迟结算至回合%d(%s)]" % [settlement_round, settlement_scene_type]
	
	return base_desc

# 比较两个使用记录是否相同
func equals(other: CardUsageData) -> bool:
	if not other:
		return false
	
	return (
		card_type == other.card_type and
		card_id == other.card_id and
		event_id == other.event_id and
		slot_id == other.slot_id
	)

# 复制使用记录
func duplicate_usage() -> CardUsageData:
	var new_usage = CardUsageData.new()
	new_usage.card_type = card_type
	new_usage.card_id = card_id
	new_usage.event_id = event_id
	new_usage.slot_id = slot_id
	new_usage.usage_timestamp = usage_timestamp
	new_usage.settlement_round = settlement_round
	new_usage.settlement_scene_type = settlement_scene_type
	new_usage.is_duration_busy = is_duration_busy
	return new_usage

# 设置延迟结算信息
func set_duration_busy(settlement_round_value: int, settlement_scene_type_value: String):
	settlement_round = settlement_round_value
	settlement_scene_type = settlement_scene_type_value
	is_duration_busy = true

# 检查是否到达释放时间
func should_be_released(current_round: int, current_scene_type: String) -> bool:
	if not is_duration_busy:
		return false
	
	# 只有在相同场景类型且到达指定回合时才释放
	return current_scene_type == settlement_scene_type and current_round >= settlement_round 