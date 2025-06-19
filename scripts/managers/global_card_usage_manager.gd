extends Node

# GlobalCardUsageManager - 全局卡牌占用管理器单例
# 管理当前回合中所有事件的卡牌使用状态，确保卡牌不会在多个事件中重复使用

signal card_usage_changed(card_type: String, card_id: String, is_used: bool)
signal round_usage_reset()

# 当前回合的卡牌使用状态
# 结构: {card_type: {card_id: CardUsageData}}
var current_round_usage: Dictionary = {}

# 延迟忙碌的卡牌状态
# 结构: {card_type: {card_id: CardUsageData}}
var duration_busy_cards: Dictionary = {}

# 当前回合编号
var current_round: int = 1

func _ready():
	print("GlobalCardUsageManager: 初始化完成")

# 检查卡牌是否已被使用（包括延迟忙碌）
func is_card_used(card_type: String, card_id: String) -> bool:
	# 检查当前回合使用
	if current_round_usage.has(card_type) and current_round_usage[card_type].has(card_id):
		return true
	
	# 检查延迟忙碌状态
	if duration_busy_cards.has(card_type) and duration_busy_cards[card_type].has(card_id):
		return true
	
	return false

# 注册卡牌使用
func register_card_usage(card_type: String, card_id: String, event_id: int, slot_id: int) -> bool:
	# 检查卡牌是否已被使用
	if is_card_used(card_type, card_id):
		var existing_usage = get_card_usage(card_type, card_id)
		print("GlobalCardUsageManager: 卡牌已被使用 - ", card_type, "[", card_id, "] 在事件", existing_usage.event_id, "槽位", existing_usage.slot_id)
		return false
	
	# 确保类型字典存在
	if not current_round_usage.has(card_type):
		current_round_usage[card_type] = {}
	
	# 创建使用记录
	var usage_data = CardUsageData.new()
	usage_data.card_type = card_type
	usage_data.card_id = card_id
	usage_data.event_id = event_id
	usage_data.slot_id = slot_id
	usage_data.usage_timestamp = Time.get_unix_time_from_system()
	
	# 注册使用
	current_round_usage[card_type][card_id] = usage_data
	
	print("GlobalCardUsageManager: 注册卡牌使用 - ", card_type, "[", card_id, "] 在事件", event_id, "槽位", slot_id)
	card_usage_changed.emit(card_type, card_id, true)
	
	return true

# 释放卡牌使用
func release_card_usage(card_type: String, card_id: String) -> bool:
	if not current_round_usage.has(card_type):
		return false
	
	if not current_round_usage[card_type].has(card_id):
		print("GlobalCardUsageManager: 卡牌未被使用，无需释放 - ", card_type, "[", card_id, "]")
		return false
	
	# 获取使用记录用于日志
	var usage_data = current_round_usage[card_type][card_id]
	print("GlobalCardUsageManager: 释放卡牌使用 - ", card_type, "[", card_id, "] 从事件", usage_data.event_id, "槽位", usage_data.slot_id)
	
	# 移除使用记录
	current_round_usage[card_type].erase(card_id)
	
	# 如果类型下没有使用的卡牌了，移除类型字典
	if current_round_usage[card_type].is_empty():
		current_round_usage.erase(card_type)
	
	card_usage_changed.emit(card_type, card_id, false)
	return true

# 注册延迟忙碌状态
func register_duration_busy(card_type: String, card_id: String, settlement_round: int, settlement_scene_type: String) -> bool:
	print("GlobalCardUsageManager: 注册延迟忙碌 - ", card_type, "[", card_id, "] 至回合", settlement_round, "(", settlement_scene_type, ")")
	
	# 确保类型字典存在
	if not duration_busy_cards.has(card_type):
		duration_busy_cards[card_type] = {}
	
	# 创建延迟忙碌记录
	var usage_data = CardUsageData.new()
	usage_data.card_type = card_type
	usage_data.card_id = card_id
	usage_data.set_duration_busy(settlement_round, settlement_scene_type)
	usage_data.usage_timestamp = Time.get_unix_time_from_system()
	
	# 注册延迟忙碌
	duration_busy_cards[card_type][card_id] = usage_data
	
	print("GlobalCardUsageManager: 延迟忙碌注册成功 - ", card_type, "[", card_id, "]")
	card_usage_changed.emit(card_type, card_id, true)
	
	return true

# 释放延迟忙碌卡牌
func release_duration_busy_cards(current_round_num: int, scene_type: String) -> int:
	var released_count = 0
	var cards_to_release = []
	
	print("GlobalCardUsageManager: 检查延迟忙碌卡牌释放 - 回合:", current_round_num, " 场景:", scene_type)
	
	# 收集需要释放的卡牌
	for card_type in duration_busy_cards.keys():
		for card_id in duration_busy_cards[card_type].keys():
			var usage_data = duration_busy_cards[card_type][card_id]
			if usage_data.should_be_released(current_round_num, scene_type):
				cards_to_release.append({
					"type": card_type,
					"id": card_id,
					"usage_data": usage_data
				})
	
	# 释放卡牌
	for card_info in cards_to_release:
		var card_type = card_info.type
		var card_id = card_info.id
		var usage_data = card_info.usage_data
		
		print("GlobalCardUsageManager: 释放延迟忙碌卡牌 - ", card_type, "[", card_id, "] 事件", usage_data.event_id)
		
		# 移除延迟忙碌记录
		duration_busy_cards[card_type].erase(card_id)
		
		# 如果类型下没有延迟忙碌的卡牌了，移除类型字典
		if duration_busy_cards[card_type].is_empty():
			duration_busy_cards.erase(card_type)
		
		card_usage_changed.emit(card_type, card_id, false)
		released_count += 1
	
	if released_count > 0:
		print("GlobalCardUsageManager: 释放了", released_count, "张延迟忙碌卡牌")
	
	return released_count

# 获取卡牌使用信息（包括延迟忙碌）
func get_card_usage(card_type: String, card_id: String) -> CardUsageData:
	# 优先返回当前回合使用记录
	if current_round_usage.has(card_type) and current_round_usage[card_type].has(card_id):
		return current_round_usage[card_type][card_id]
	
	# 返回延迟忙碌记录
	if duration_busy_cards.has(card_type) and duration_busy_cards[card_type].has(card_id):
		return duration_busy_cards[card_type][card_id]
	
	return null

# 获取事件使用的所有卡牌
func get_event_used_cards(event_id: int) -> Array:
	var used_cards = []
	
	for card_type in current_round_usage.keys():
		for card_id in current_round_usage[card_type].keys():
			var usage_data = current_round_usage[card_type][card_id]
			if usage_data.event_id == event_id:
				used_cards.append(usage_data)
	
	return used_cards

# 释放事件的所有卡牌使用
func release_event_card_usage(event_id: int) -> int:
	var released_count = 0
	var cards_to_release = []
	
	# 收集需要释放的卡牌
	for card_type in current_round_usage.keys():
		for card_id in current_round_usage[card_type].keys():
			var usage_data = current_round_usage[card_type][card_id]
			if usage_data.event_id == event_id:
				cards_to_release.append({
					"type": card_type,
					"id": card_id
				})
	
	# 释放卡牌
	for card_info in cards_to_release:
		if release_card_usage(card_info.type, card_info.id):
			released_count += 1
	
	if released_count > 0:
		print("GlobalCardUsageManager: 释放事件", event_id, "的", released_count, "张卡牌")
	
	return released_count

# 获取所有已使用的卡牌列表
func get_all_used_cards() -> Array:
	var all_used_cards = []
	
	for card_type in current_round_usage.keys():
		for card_id in current_round_usage[card_type].keys():
			all_used_cards.append(current_round_usage[card_type][card_id])
	
	return all_used_cards

# 重置回合使用状态
func reset_round_usage(new_round: int = -1):
	var old_usage_count = get_total_used_cards_count()
	
	current_round_usage.clear()
	
	if new_round > 0:
		current_round = new_round
	else:
		current_round += 1
	
	print("GlobalCardUsageManager: 重置回合使用状态 - 新回合:", current_round, " 清除了", old_usage_count, "张卡牌的使用记录")
	round_usage_reset.emit()

# 获取当前使用的卡牌总数
func get_total_used_cards_count() -> int:
	var total_count = 0
	
	for card_type in current_round_usage.keys():
		total_count += current_round_usage[card_type].size()
	
	return total_count

# 获取指定类型的已使用卡牌列表
func get_used_cards_by_type(card_type: String) -> Array:
	var used_cards = []
	
	if current_round_usage.has(card_type):
		for card_id in current_round_usage[card_type].keys():
			used_cards.append(current_round_usage[card_type][card_id])
	
	return used_cards

# 检查特定事件是否有使用的卡牌
func has_event_used_cards(event_id: int) -> bool:
	for card_type in current_round_usage.keys():
		for card_id in current_round_usage[card_type].keys():
			var usage_data = current_round_usage[card_type][card_id]
			if usage_data.event_id == event_id:
				return true
	
	return false

# 获取调试信息
func get_debug_info() -> Dictionary:
	var debug_info = {
		"current_round": current_round,
		"total_used_cards": get_total_used_cards_count(),
		"usage_by_type": {},
		"usage_by_event": {}
	}
	
	# 按类型统计
	for card_type in current_round_usage.keys():
		debug_info.usage_by_type[card_type] = current_round_usage[card_type].size()
	
	# 按事件统计
	for card_type in current_round_usage.keys():
		for card_id in current_round_usage[card_type].keys():
			var usage_data = current_round_usage[card_type][card_id]
			var event_id = usage_data.event_id
			if not debug_info.usage_by_event.has(event_id):
				debug_info.usage_by_event[event_id] = 0
			debug_info.usage_by_event[event_id] += 1
	
	return debug_info

# 打印调试信息
func print_debug_info():
	var debug_info = get_debug_info()
	print("=== GlobalCardUsageManager 调试信息 ===")
	print("当前回合: ", debug_info.current_round)
	print("已使用卡牌总数: ", debug_info.total_used_cards)
	print("按类型统计: ", debug_info.usage_by_type)
	print("按事件统计: ", debug_info.usage_by_event)
	print("========================================")

# 回合推进处理（由TimeManager调用）
func on_round_changed(new_round: int, scene_type: String):
	print("GlobalCardUsageManager: 回合推进处理 - 回合:", new_round, " 场景:", scene_type)
	
	# 更新当前回合
	current_round = new_round
	
	# 释放到期的延迟忙碌卡牌
	var released_count = release_duration_busy_cards(new_round, scene_type)
	
	# 重置当前回合使用状态
	reset_round_usage(new_round)
	
	print("GlobalCardUsageManager: 回合推进完成 - 释放延迟忙碌卡牌:", released_count, "张")

# 获取延迟忙碌卡牌统计信息
func get_duration_busy_stats() -> Dictionary:
	var stats = {
		"total_count": 0,
		"by_type": {},
		"by_settlement_round": {}
	}
	
	for card_type in duration_busy_cards.keys():
		var type_count = duration_busy_cards[card_type].size()
		stats.total_count += type_count
		stats.by_type[card_type] = type_count
		
		for card_id in duration_busy_cards[card_type].keys():
			var usage_data = duration_busy_cards[card_type][card_id]
			var settlement_round = usage_data.settlement_round
			if not stats.by_settlement_round.has(settlement_round):
				stats.by_settlement_round[settlement_round] = 0
			stats.by_settlement_round[settlement_round] += 1
	
	return stats

# 检查指定卡牌的延迟忙碌状态
func get_card_duration_busy_info(card_type: String, card_id: String) -> Dictionary:
	if duration_busy_cards.has(card_type) and duration_busy_cards[card_type].has(card_id):
		var usage_data = duration_busy_cards[card_type][card_id]
		return {
			"is_duration_busy": true,
			"settlement_round": usage_data.settlement_round,
			"settlement_scene_type": usage_data.settlement_scene_type,
			"event_id": usage_data.event_id,
			"remaining_rounds": max(0, usage_data.settlement_round - current_round)
		}
	
	return {
		"is_duration_busy": false
	}

# ========== 存档序列化功能 ==========

# 序列化卡牌使用状态数据
func serialize_usage_data() -> Dictionary:
	var serialized_data = {
		"current_round": current_round,
		"current_round_usage": {},
		"duration_busy_cards": {}
	}
	
	# 序列化当前回合使用状态
	for card_type in current_round_usage.keys():
		serialized_data.current_round_usage[card_type] = {}
		for card_id in current_round_usage[card_type].keys():
			var usage_data = current_round_usage[card_type][card_id]
			serialized_data.current_round_usage[card_type][card_id] = {
				"card_type": usage_data.card_type,
				"card_id": usage_data.card_id,
				"event_id": usage_data.event_id,
				"slot_id": usage_data.slot_id,
				"usage_timestamp": usage_data.usage_timestamp,
				"is_duration_busy": usage_data.is_duration_busy,
				"settlement_round": usage_data.settlement_round,
				"settlement_scene_type": usage_data.settlement_scene_type
			}
	
	# 序列化延迟忙碌状态
	for card_type in duration_busy_cards.keys():
		serialized_data.duration_busy_cards[card_type] = {}
		for card_id in duration_busy_cards[card_type].keys():
			var usage_data = duration_busy_cards[card_type][card_id]
			serialized_data.duration_busy_cards[card_type][card_id] = {
				"card_type": usage_data.card_type,
				"card_id": usage_data.card_id,
				"event_id": usage_data.event_id,
				"slot_id": usage_data.slot_id,
				"usage_timestamp": usage_data.usage_timestamp,
				"is_duration_busy": usage_data.is_duration_busy,
				"settlement_round": usage_data.settlement_round,
				"settlement_scene_type": usage_data.settlement_scene_type
			}
	
	print("GlobalCardUsageManager: 序列化完成 - 当前使用:", get_total_used_cards_count(), " 延迟忙碌:", get_duration_busy_stats().total_count)
	return serialized_data

# 反序列化卡牌使用状态数据
func deserialize_usage_data(data: Dictionary) -> void:
	print("GlobalCardUsageManager: 开始反序列化卡牌使用状态")
	
	# 清空现有数据
	current_round_usage.clear()
	duration_busy_cards.clear()
	
	# 恢复回合信息
	if data.has("current_round"):
		current_round = data.current_round
		print("GlobalCardUsageManager: 恢复回合信息 - 回合:", current_round)
	
	# 恢复当前回合使用状态
	if data.has("current_round_usage"):
		var usage_data = data.current_round_usage
		for card_type in usage_data.keys():
			current_round_usage[card_type] = {}
			for card_id in usage_data[card_type].keys():
				var usage_info = usage_data[card_type][card_id]
				var card_usage = CardUsageData.new()
				card_usage.card_type = usage_info.get("card_type", card_type)
				card_usage.card_id = usage_info.get("card_id", card_id)
				card_usage.event_id = usage_info.get("event_id", 0)
				card_usage.slot_id = usage_info.get("slot_id", 0)
				card_usage.usage_timestamp = usage_info.get("usage_timestamp", 0)
				card_usage.is_duration_busy = usage_info.get("is_duration_busy", false)
				card_usage.settlement_round = usage_info.get("settlement_round", 0)
				card_usage.settlement_scene_type = usage_info.get("settlement_scene_type", "")
				
				current_round_usage[card_type][card_id] = card_usage
		
		print("GlobalCardUsageManager: 恢复当前回合使用状态 - 数量:", get_total_used_cards_count())
	
	# 恢复延迟忙碌状态
	if data.has("duration_busy_cards"):
		var busy_data = data.duration_busy_cards
		for card_type in busy_data.keys():
			duration_busy_cards[card_type] = {}
			for card_id in busy_data[card_type].keys():
				var usage_info = busy_data[card_type][card_id]
				var card_usage = CardUsageData.new()
				card_usage.card_type = usage_info.get("card_type", card_type)
				card_usage.card_id = usage_info.get("card_id", card_id)
				card_usage.event_id = usage_info.get("event_id", 0)
				card_usage.slot_id = usage_info.get("slot_id", 0)
				card_usage.usage_timestamp = usage_info.get("usage_timestamp", 0)
				card_usage.is_duration_busy = usage_info.get("is_duration_busy", true)
				card_usage.settlement_round = usage_info.get("settlement_round", 0)
				card_usage.settlement_scene_type = usage_info.get("settlement_scene_type", "")
				
				duration_busy_cards[card_type][card_id] = card_usage
		
		print("GlobalCardUsageManager: 恢复延迟忙碌状态 - 数量:", get_duration_busy_stats().total_count)
	
	print("GlobalCardUsageManager: 反序列化完成") 
