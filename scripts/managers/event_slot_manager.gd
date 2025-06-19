extends Node

# EventSlotManager - 事件卡槽管理器单例
# 管理所有事件的卡槽配置和状态

signal slot_card_placed(event_id: int, slot_id: int, card_type: String, card_id: String)
signal slot_card_removed(event_id: int, slot_id: int)
signal slots_updated(event_id: int)
signal slots_loaded

# 存储所有卡槽数据，按event_id分组
var event_slots: Dictionary = {}  # event_id -> Array[EventSlotData]

# 分支选择记录
var selected_branches: Dictionary = {}  # event_id -> branch_id

# 数据文件路径
const SLOTS_DATA_PATH = "res://data/events/event_slots.tsv"

func _ready():
	print("EventSlotManager: 开始初始化")
	load_slots_from_tsv(SLOTS_DATA_PATH)
	print("EventSlotManager: 初始化完成，加载状态: ", get_loading_status())
	
	# 同步调试模式设置
	if EventManager:
		detailed_debug_mode = EventManager.detailed_debug_mode
		print("EventSlotManager: 同步调试模式设置 - detailed_debug_mode:", detailed_debug_mode)

# 从TSV文件加载卡槽数据
func load_slots_from_tsv(file_path: String = SLOTS_DATA_PATH):
	print("EventSlotManager: 开始加载TSV文件: ", file_path)
	
	# 检查文件是否存在
	if not FileAccess.file_exists(file_path):
		printerr("EventSlotManager: TSV文件不存在: ", file_path)
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		printerr("EventSlotManager: 无法打开TSV文件: ", file_path)
		return
	
	var content = file.get_as_text()
	file.close()
	
	if content.is_empty():
		printerr("EventSlotManager: TSV文件内容为空")
		return
	
	var lines = content.split("\n")
	if lines.size() < 2:
		printerr("EventSlotManager: TSV文件格式错误，行数不足")
		return
	
	# 清空现有数据
	event_slots.clear()
	
	# 解析表头
	var header = lines[0].split("\t")
	print("EventSlotManager: TSV表头: ", header)
	
	var loaded_count = 0
	var error_count = 0
	
	# 解析数据行
	for i in range(1, lines.size()):
		var line = lines[i].strip_edges()
		if line.is_empty():
			continue
		
		var columns = line.split("\t")
		if columns.size() < header.size():
			print("EventSlotManager: 第", i+1, "行列数不足，跳过")
			error_count += 1
			continue
		
		var slot_data = EventSlotData.new()
		if slot_data.parse_from_tsv_row(columns):
			if not event_slots.has(slot_data.event_id):
				event_slots[slot_data.event_id] = []
			event_slots[slot_data.event_id].append(slot_data)
			loaded_count += 1
		else:
			print("EventSlotManager: 第", i+1, "行数据解析失败")
			error_count += 1
	
	print("EventSlotManager: TSV加载完成 - 成功: ", loaded_count, ", 错误: ", error_count)
	print("EventSlotManager: 加载的事件数: ", event_slots.size())
	
	# 发射加载完成信号
	slots_loaded.emit()

# 获取指定事件的所有卡槽
func get_event_slots(event_id: int) -> Array:
	return event_slots.get(event_id, [])

# 获取指定卡槽数据
func get_slot_data(event_id: int, slot_id: int) -> EventSlotData:
	var slots = get_event_slots(event_id)
	for slot in slots:
		if slot.slot_id == slot_id:
			return slot
	return null

# 放置卡牌到卡槽
func place_card_in_slot(event_id: int, slot_id: int, card_type: String, card_id: String, card_data = null) -> bool:
	var slot_data = get_slot_data(event_id, slot_id)
	if not slot_data:
		print("EventSlotManager: 找不到卡槽 ", event_id, "-", slot_id)
		return false
	
	# 检查全局卡牌占用状态
	var global_usage_manager = get_node_or_null("/root/GlobalCardUsageManager")
	if global_usage_manager and global_usage_manager.is_card_used(card_type, card_id):
		var existing_usage = global_usage_manager.get_card_usage(card_type, card_id)
		print("EventSlotManager: 卡牌已被其他事件使用 - ", card_type, "[", card_id, "] 在事件", existing_usage.event_id, "槽位", existing_usage.slot_id)
		return false
	
	# 处理当前卡槽的卡牌替换逻辑
	if slot_data.has_card_placed():
		var old_card_type = slot_data.placed_card_type
		var old_card_id = slot_data.placed_card_id
		print("EventSlotManager: 卡槽替换 - 移除旧卡牌 ", old_card_type, "[", old_card_id, "] 准备放置新卡牌 ", card_type, "[", card_id, "]")
		
		# 释放旧卡牌的全局占用
		if global_usage_manager:
			global_usage_manager.release_card_usage(old_card_type, old_card_id)
			print("EventSlotManager: 已释放旧卡牌的全局占用 - ", old_card_type, "[", old_card_id, "]")
		
		# 发射旧卡牌移除信号
		slot_card_removed.emit(event_id, slot_id)
	
	# 处理金币卡的特殊逻辑
	if card_type == "金币卡":
		return _handle_coin_card_placement(event_id, slot_id, card_id, slot_data)
	
	# 处理互斥冲突
	var removed_cards = remove_conflicting_cards(event_id, slot_id)
	if removed_cards.size() > 0:
		print("EventSlotManager: 处理互斥冲突，移除了 ", removed_cards.size(), " 张卡牌")
		for removed_card in removed_cards:
			# 释放被移除卡牌的全局占用
			if global_usage_manager:
				global_usage_manager.release_card_usage(removed_card.card_type, removed_card.card_id)
			slot_card_removed.emit(event_id, removed_card.slot_id)
	
	if slot_data.place_card(card_type, card_id, card_data):
		# 注册全局卡牌使用
		if global_usage_manager:
			if not global_usage_manager.register_card_usage(card_type, card_id, event_id, slot_id):
				# 如果注册失败，回滚卡槽放置
				slot_data.remove_card()
				print("EventSlotManager: 全局卡牌占用注册失败，回滚卡牌放置")
				return false
		
		print("EventSlotManager: 成功放置卡牌 ", card_type, "[", card_id, "] 到卡槽 ", event_id, "-", slot_id)
		slot_card_placed.emit(event_id, slot_id, card_type, card_id)
		slots_updated.emit(event_id)
		return true
	else:
		print("EventSlotManager: 放置卡牌失败")
		return false

# 从卡槽移除卡牌
func remove_card_from_slot(event_id: int, slot_id: int) -> bool:
	var slot_data = get_slot_data(event_id, slot_id)
	if not slot_data:
		print("EventSlotManager: 找不到卡槽 ", event_id, "-", slot_id)
		return false
	
	if slot_data.has_card_placed():
		var card_type = slot_data.placed_card_type
		var card_id = slot_data.placed_card_id
		
		slot_data.remove_card()
		
		# 释放全局卡牌占用
		var global_usage_manager = get_node_or_null("/root/GlobalCardUsageManager")
		if global_usage_manager:
			global_usage_manager.release_card_usage(card_type, card_id)
		
		print("EventSlotManager: 从卡槽 ", event_id, "-", slot_id, " 移除卡牌 ", card_type, "[", card_id, "]")
		slot_card_removed.emit(event_id, slot_id)
		slots_updated.emit(event_id)
		return true
	else:
		print("EventSlotManager: 卡槽 ", event_id, "-", slot_id, " 没有卡牌可移除")
		return false

# 检查事件完成准备状态
func check_event_completion_readiness(event_id: int) -> Dictionary:
	var result = {
		"can_complete": false,
		"missing_required_slots": [],
		"filled_required_slots": [],
		"total_required_slots": 0
	}
	
	var slots = get_event_slots(event_id)
	var groups_status = _get_mutually_exclusive_groups_status(event_id)
	
	# 处理互斥组
	for group_id in groups_status.keys():
		var group_info = groups_status[group_id]
		if group_info.has_required_slots:
			result.total_required_slots += 1
			if group_info.is_filled:
				# 找到填充的卡槽并添加到已填充列表
				for slot in group_info.slots:
					if slot.has_card_placed():
						result.filled_required_slots.append({
							"slot_id": slot.slot_id,
							"description": slot.slot_description,
							"card_type": slot.placed_card_type,
							"card_id": slot.placed_card_id
						})
						break
			else:
				# 添加整个互斥组的所有必需卡槽到缺失列表
				for slot in group_info.slots:
					if slot.required_for_completion:
						result.missing_required_slots.append({
							"slot_id": slot.slot_id,
							"description": slot.slot_description,
							"allowed_types": slot.get_allowed_card_types()
						})
	
	# 处理非互斥组的必需卡槽
	for slot in slots:
		if slot.mutually_exclusive_group == 0 and slot.required_for_completion:
			result.total_required_slots += 1
			if slot.has_card_placed():
				result.filled_required_slots.append({
					"slot_id": slot.slot_id,
					"description": slot.slot_description,
					"card_type": slot.placed_card_type,
					"card_id": slot.placed_card_id
				})
			else:
				result.missing_required_slots.append({
					"slot_id": slot.slot_id,
					"description": slot.slot_description,
					"allowed_types": slot.get_allowed_card_types()
				})
	
	result.can_complete = result.missing_required_slots.is_empty()
	return result

# 获取事件必需卡槽状态
func get_event_required_slots_status(event_id: int) -> Dictionary:
	var status = {
		"total_required": 0,
		"filled_required": 0,
		"missing_slots": []
	}
	
	var slots = get_event_slots(event_id)
	var groups_status = _get_mutually_exclusive_groups_status(event_id)
	
	# 处理互斥组
	for group_id in groups_status.keys():
		var group_info = groups_status[group_id]
		if group_info.has_required_slots:
			status.total_required += 1
			if group_info.is_filled:
				status.filled_required += 1
			else:
				# 添加整个互斥组的必需卡槽到缺失列表
				for slot in group_info.slots:
					if slot.required_for_completion:
						status.missing_slots.append({
							"slot_id": slot.slot_id,
							"description": slot.slot_description
						})
	
	# 处理非互斥组的必需卡槽
	for slot in slots:
		if slot.mutually_exclusive_group == 0 and slot.required_for_completion:
			status.total_required += 1
			if slot.has_card_placed():
				status.filled_required += 1
			else:
				status.missing_slots.append({
					"slot_id": slot.slot_id,
					"description": slot.slot_description
				})
	
	return status

# 检查事件的必须卡槽是否都已填充（支持互斥组逻辑）
func are_required_slots_filled(event_id: int) -> bool:
	var slots = get_event_slots(event_id)
	var groups_status = _get_mutually_exclusive_groups_status(event_id)
	
	# 检查互斥组的必需条件
	for group_id in groups_status.keys():
		var group_info = groups_status[group_id]
		if group_info.has_required_slots and not group_info.is_filled:
			print("EventSlotManager: 互斥组", group_id, "包含必需卡槽但未填充")
			return false
	
	# 检查非互斥组的必需卡槽
	for slot in slots:
		if slot.mutually_exclusive_group == 0 and slot.required_for_completion and not slot.has_card_placed():
			print("EventSlotManager: 必需卡槽", slot.slot_id, "未填充:", slot.slot_description)
			return false
	
	return true

# 获取互斥组状态分析（新增辅助方法）
func _get_mutually_exclusive_groups_status(event_id: int) -> Dictionary:
	var slots = get_event_slots(event_id)
	var groups = {}
	
	# 按互斥组分组
	for slot in slots:
		if slot.mutually_exclusive_group > 0:
			var group_id = slot.mutually_exclusive_group
			if not groups.has(group_id):
				groups[group_id] = {
					"slots": [],
					"has_required_slots": false,
					"is_filled": false
				}
			groups[group_id].slots.append(slot)
			
			# 检查是否有必需卡槽
			if slot.required_for_completion:
				groups[group_id].has_required_slots = true
			
			# 检查是否有卡槽已填充
			if slot.has_card_placed():
				groups[group_id].is_filled = true
	
	return groups

# 检查互斥冲突
func check_mutually_exclusive_conflict(event_id: int, slot_id: int) -> Array:
	var target_slot = get_slot_data(event_id, slot_id)
	if not target_slot or target_slot.mutually_exclusive_group == 0:
		return []  # 不参与互斥关系，无冲突
	
	var conflicting_slots = []
	var slots = get_event_slots(event_id)
	
	for slot in slots:
		if slot.slot_id != slot_id and slot.mutually_exclusive_group == target_slot.mutually_exclusive_group:
			if slot.has_card_placed():
				conflicting_slots.append(slot)
	
	return conflicting_slots

# 移除冲突的卡牌
func remove_conflicting_cards(event_id: int, slot_id: int) -> Array:
	var conflicting_slots = check_mutually_exclusive_conflict(event_id, slot_id)
	var removed_cards = []
	
	for slot in conflicting_slots:
		var removed_card_info = {
			"slot_id": slot.slot_id,
			"card_type": slot.placed_card_type,
			"card_id": slot.placed_card_id
		}
		slot.remove_card()
		removed_cards.append(removed_card_info)
		print("EventSlotManager: 移除冲突卡牌 - 卡槽", slot.slot_id, ":", removed_card_info.card_type, "[", removed_card_info.card_id, "]")
	
	return removed_cards

# 获取事件的总属性贡献
func get_event_attribute_contribution(event_id: int) -> Dictionary:
	var total_contribution = {}
	var slots = get_event_slots(event_id)
	
	for slot in slots:
		var slot_contribution = slot.get_attribute_contribution()
		for attr_name in slot_contribution:
			total_contribution[attr_name] = total_contribution.get(attr_name, 0) + slot_contribution[attr_name]
	
	return total_contribution

# 获取控制分支的卡槽选择
func get_branch_controlling_slots(event_id: int) -> Array:
	var controlling_slots = []
	var slots = get_event_slots(event_id)
	
	for slot in slots:
		if slot.controls_branch and slot.has_card_placed():
			controlling_slots.append(slot)
	
	return controlling_slots

# 根据卡槽选择确定分支ID
func determine_branch_id(event_id: int) -> int:
	var controlling_slots = get_branch_controlling_slots(event_id)
	
	if controlling_slots.is_empty():
		# 没有控制分支的卡槽，返回默认分支（通常是第一个分支）
		var slots = get_event_slots(event_id)
		if not slots.is_empty():
			return slots[0].branch_id
		return 0
	
	# 返回第一个控制分支的卡槽对应的分支ID
	return controlling_slots[0].branch_id

# 清空指定事件的所有卡槽
func clear_event_slots(event_id: int):
	var slots = get_event_slots(event_id)
	var global_usage_manager = get_node_or_null("/root/GlobalCardUsageManager")
	
	for slot in slots:
		if slot.has_card_placed():
			var card_type = slot.placed_card_type
			var card_id = slot.placed_card_id
			
			slot.remove_card()
			
			# 释放全局卡牌占用
			if global_usage_manager:
				global_usage_manager.release_card_usage(card_type, card_id)
	
	print("EventSlotManager: 清空事件 ", event_id, " 的所有卡槽")
	slots_updated.emit(event_id)

# 获取调试信息
func get_debug_info(event_id: int = -1) -> String:
	var info = "=== EventSlotManager 调试信息 ===\n"
	
	if event_id > 0:
		# 显示特定事件的信息
		var slots = get_event_slots(event_id)
		info += "事件 %d 的卡槽信息:\n" % event_id
		
		# 添加互斥组状态信息
		var groups_status = _get_mutually_exclusive_groups_status(event_id)
		if not groups_status.is_empty():
			info += "互斥组状态:\n"
			for group_id in groups_status.keys():
				var group_info = groups_status[group_id]
				info += "  组 %d: 包含必需=%s, 已填充=%s, 卡槽数=%d\n" % [
					group_id, 
					group_info.has_required_slots,
					group_info.is_filled,
					group_info.slots.size()
				]
		
		# 显示完成状态
		var completion_status = check_event_completion_readiness(event_id)
		info += "完成状态: 可完成=%s, 总必需=%d, 已填充=%d, 缺失=%d\n" % [
			completion_status.can_complete,
			completion_status.total_required_slots,
			completion_status.filled_required_slots.size(),
			completion_status.missing_required_slots.size()
		]
		
		# 显示各个卡槽详情
		for slot in slots:
			info += slot.get_debug_info()
	else:
		# 显示所有事件的概览
		info += "总计事件数: %d\n" % event_slots.size()
		for eid in event_slots.keys():
			var slots = event_slots[eid]
			info += "事件 %d: %d 个卡槽\n" % [eid, slots.size()]
	
	return info

# 检查是否有卡槽数据
func has_slots_for_event(event_id: int) -> bool:
	return event_slots.has(event_id) and not event_slots[event_id].is_empty()

# 获取加载状态报告
func get_loading_status() -> Dictionary:
	var status = {
		"tsv_file_exists": FileAccess.file_exists(SLOTS_DATA_PATH),
		"total_events": event_slots.size(),
		"total_slots": 0,
		"file_path": SLOTS_DATA_PATH
	}
	
	for event_id in event_slots:
		status.total_slots += event_slots[event_id].size()
	
	return status

# 获取应该被禁用的互斥卡槽列表
func get_mutually_exclusive_disabled_slots(event_id: int) -> Array:
	var disabled_slots = []
	var slots = get_event_slots(event_id)
	
	# 按互斥组分组
	var groups = {}
	for slot in slots:
		if slot.mutually_exclusive_group > 0:
			if not groups.has(slot.mutually_exclusive_group):
				groups[slot.mutually_exclusive_group] = []
			groups[slot.mutually_exclusive_group].append(slot)
	
	# 检查每个互斥组
	for group_id in groups.keys():
		var group_slots = groups[group_id]
		var has_placed_card = false
		
		# 检查组内是否有卡槽已放置卡牌
		for slot in group_slots:
			if slot.has_card_placed():
				has_placed_card = true
				break
		
		# 如果有卡槽已放置卡牌，则组内其他空卡槽应被禁用
		if has_placed_card:
			for slot in group_slots:
				if not slot.has_card_placed():
					disabled_slots.append(slot.slot_id)
	
	return disabled_slots

# ========== 属性聚合系统 ==========

# 计算指定事件的卡槽属性总和
func calculate_event_slot_attributes(event_id: int) -> Dictionary:
	var total_attributes = {
		"social": 0,
		"resistance": 0,
		"innovation": 0,
		"execution": 0,
		"physical": 0
	}
	
	var slots = get_event_slots(event_id)
	if slots.is_empty():
		print("EventSlotManager: 事件 ", event_id, " 没有卡槽配置")
		return total_attributes
	
	print("EventSlotManager: 开始计算事件 ", event_id, " 的属性聚合")
	
	for slot in slots:
		if slot.has_card_placed():
			var card_attributes = get_card_attributes(slot.placed_card_type, slot.placed_card_id)
			print("EventSlotManager: 卡槽 ", slot.slot_id, " 卡牌属性: ", card_attributes)
			
			for attr_name in card_attributes:
				if total_attributes.has(attr_name):
					total_attributes[attr_name] += card_attributes[attr_name]
	
	print("EventSlotManager: 事件 ", event_id, " 属性聚合结果: ", total_attributes)
	return total_attributes

# 获取指定事件的特定属性总值
func get_total_attribute_for_event(event_id: int, attribute_name: String) -> int:
	var slot_attributes = calculate_event_slot_attributes(event_id)
	return slot_attributes.get(attribute_name, 0)

# 根据聚合方法计算属性
func aggregate_attributes_by_method(event_id: int, method: String) -> Dictionary:
	match method:
		"sum_all_slots":
			return calculate_event_slot_attributes(event_id)
		_:
			print("EventSlotManager: 警告 - 未知的聚合方法: ", method)
			return calculate_event_slot_attributes(event_id)

# 获取卡牌的属性贡献值
func get_card_attributes(card_type: String, card_id: String) -> Dictionary:
	var attributes = {
		"social": 0,
		"resistance": 0,
		"innovation": 0,
		"execution": 0,
		"physical": 0
	}
	
	# 卡牌类型映射：将中文类型名转换为英文标识符
	var type_mapping = {
		"特权卡": "privilege",
		"情报卡": "item", 
		"角色卡": "character",
		"金币卡": "coin"
	}
	
	var mapped_type = type_mapping.get(card_type, card_type)
	print("EventSlotManager: 卡牌类型映射 - 原始:", card_type, " 映射后:", mapped_type)
	
	# 将String类型的card_id转换为int类型
	var card_id_int = card_id.to_int()
	
	match mapped_type:
		"privilege":
			# 特权卡不提供属性贡献，这是设计决定
			print("EventSlotManager: 特权卡不提供属性贡献")
			# 从PrivilegeCardManager获取特权卡数据（用于验证卡牌存在）
			if PrivilegeCardManager:
				var card_data = PrivilegeCardManager.get_card_by_id(card_id)
				if card_data:
					print("EventSlotManager: 特权卡验证成功 - ", card_data.get_display_name())
				else:
					print("EventSlotManager: 警告 - 特权卡数据未找到: ", card_id)
			else:
				print("EventSlotManager: 警告 - PrivilegeCardManager未找到")
		
		"item":
			# 从ItemCardInventoryManager获取情报卡属性
			if ItemCardInventoryManager:
				var card_instance = ItemCardInventoryManager.get_instance_by_id(card_id)
				if card_instance:
					var card_attrs = card_instance.get_attributes()
					print("EventSlotManager: 情报卡属性获取成功 - ", card_attrs)
					# 直接返回卡牌原始属性，不进行映射转换
					attributes = card_attrs.duplicate()
				else:
					print("EventSlotManager: 警告 - 情报卡实例未找到: ", card_id)
			else:
				print("EventSlotManager: 警告 - ItemCardInventoryManager未找到")
		
		"character":
			# 从CharacterCardManager获取人物卡属性
			if CharacterCardManager:
				var card_data = CharacterCardManager.get_card_by_id(card_id)
				if card_data:
					var card_attrs = card_data.get_attributes()
					print("EventSlotManager: 角色卡属性获取成功 - ", card_attrs)
					# 直接返回卡牌原始属性，不进行映射转换
					attributes = card_attrs.duplicate()
				else:
					print("EventSlotManager: 警告 - 角色卡数据未找到: ", card_id)
			else:
				print("EventSlotManager: 警告 - CharacterCardManager未找到")
		
		"coin":
			# 金币卡不提供属性贡献
			print("EventSlotManager: 金币卡不提供属性贡献")
		
		_:
			print("EventSlotManager: 警告 - 未知的卡牌类型: ", card_type, " (映射后: ", mapped_type, ")")
	
	print("EventSlotManager: 卡牌 ", card_type, "[", card_id, "] 最终属性: ", attributes)
	return attributes

# 将卡牌basic属性映射到overall检定属性
func map_card_attributes_to_check_attributes(card_attrs: Dictionary) -> Dictionary:
	var check_attributes = {
		"power": 0,
		"reputation": 0,
		"piety": 0
	}
	
	# 新的属性映射规则:
	# social + execution -> power (社交能力+执行力 = 权势)
	# resistance + innovation -> reputation (抗压能力+创新能力 = 声望)
	# physical -> piety (体魄 = 虔信)
	
	# 计算power: social + execution
	var power_value = 0
	if card_attrs.has("social"):
		power_value += card_attrs["social"]
	if card_attrs.has("execution"):
		power_value += card_attrs["execution"]
	check_attributes["power"] = power_value
	
	# 计算reputation: resistance + innovation
	var reputation_value = 0
	if card_attrs.has("resistance"):
		reputation_value += card_attrs["resistance"]
	if card_attrs.has("innovation"):
		reputation_value += card_attrs["innovation"]
	check_attributes["reputation"] = reputation_value
	
	# 计算piety: physical
	var piety_value = 0
	if card_attrs.has("physical"):
		piety_value += card_attrs["physical"]
	check_attributes["piety"] = piety_value
	
	print("EventSlotManager: 属性映射 - 原始:", card_attrs, " -> 检定:", check_attributes)
	return check_attributes

# 检查事件是否有足够的属性进行检定
func check_event_attribute_threshold(event_id: int, required_attribute: String, threshold: int) -> bool:
	var total_value = get_total_attribute_for_event(event_id, required_attribute)
	return total_value >= threshold

# 获取事件的属性检定预览信息
func get_event_check_preview(event_id: int) -> Dictionary:
	var preview = {
		"slot_attributes": calculate_event_slot_attributes(event_id),
		"has_cards": false,
		"total_slots": 0,
		"filled_slots": 0
	}
	
	var slots = get_event_slots(event_id)
	preview.total_slots = slots.size()
	
	for slot in slots:
		if slot.has_card_placed():
			preview.filled_slots += 1
			preview.has_cards = true
	
	return preview

# ========== 分支选择记录系统 ==========

# 记录事件的分支选择
func record_branch_selection(event_id: int, branch_id: int):
	selected_branches[event_id] = branch_id
	print("EventSlotManager: 记录分支选择 - 事件", event_id, "选择分支", branch_id)

# 获取事件的分支选择记录
func get_selected_branch_id(event_id: int) -> int:
	var branch_id = selected_branches.get(event_id, -1)
	if detailed_debug_mode:
		print("EventSlotManager: 获取分支选择记录 - 事件", event_id, "分支", branch_id)
	return branch_id

# 检查事件是否有分支选择记录
func has_branch_selection(event_id: int) -> bool:
	return selected_branches.has(event_id)

# 清除事件的分支选择记录
func clear_branch_selection(event_id: int):
	if selected_branches.has(event_id):
		selected_branches.erase(event_id)
		print("EventSlotManager: 清除分支选择记录 - 事件", event_id)

# 获取所有分支选择记录（调试用）
func get_all_branch_selections() -> Dictionary:
	return selected_branches.duplicate()

# 调试：打印所有分支选择记录
func print_branch_selections():
	print("EventSlotManager: 当前分支选择记录:")
	for event_id in selected_branches.keys():
		print("  事件", event_id, "-> 分支", selected_branches[event_id])
	if selected_branches.is_empty():
		print("  (无记录)")

# 添加详细调试模式变量（如果不存在）
var detailed_debug_mode: bool = false

# 处理金币卡放置的特殊逻辑
func _handle_coin_card_placement(event_id: int, slot_id: int, card_id: String, slot_data: EventSlotData) -> bool:
	print("EventSlotManager: 处理金币卡放置 - 事件", event_id, "槽位", slot_id, "金币数量", card_id)
	
	var coin_amount = card_id.to_int()
	if coin_amount <= 0:
		print("EventSlotManager: 错误 - 无效的金币数量: ", card_id)
		return false
	
	# 验证玩家是否有足够的金币
	if not AttributeManager:
		print("EventSlotManager: 错误 - AttributeManager未找到")
		return false
	
	if not AttributeManager.has_enough_coins(coin_amount):
		print("EventSlotManager: 金币不足 - 需要", coin_amount, "当前", AttributeManager.get_coins())
		return false
	
	# 消费金币
	var success = AttributeManager.try_spend_coins(coin_amount)
	if not success:
		print("EventSlotManager: 金币消费失败")
		return false
	
	# 设置卡槽数据
	slot_data.placed_card_type = "金币卡"
	slot_data.placed_card_id = card_id
	slot_data.placed_card_data = null
	
	print("EventSlotManager: 金币卡放置成功 - 消费", coin_amount, "金币")
	
	# 发射卡牌放置信号
	slot_card_placed.emit(event_id, slot_id)
	
	return true

# ========== 存档序列化功能 ==========

# 序列化卡槽数据
func serialize_slots() -> Dictionary:
	var serialized_data = {
		"event_slots": {},
		"selected_branches": selected_branches
	}
	
	# 序列化每个事件的卡槽数据
	for event_id in event_slots.keys():
		var slots_array = event_slots[event_id]
		var serialized_slots = []
		
		for slot in slots_array:
			if slot is EventSlotData:
				serialized_slots.append({
					"event_id": slot.event_id,
					"slot_id": slot.slot_id,
					"slot_description": slot.slot_description,
					"allowed_card_types": slot.get_allowed_card_types(),
					"required_for_completion": slot.required_for_completion,
					"placed_card_type": slot.placed_card_type,
					"placed_card_id": slot.placed_card_id,
					"placed_card_data": slot.placed_card_data,
					"specific_requirements": slot.get_specific_card_requirements()
				})
		
		serialized_data.event_slots[str(event_id)] = serialized_slots
	
	print("EventSlotManager: 序列化完成 - 事件数:", serialized_data.event_slots.size(), " 分支选择:", serialized_data.selected_branches.size())
	return serialized_data

# 反序列化卡槽数据
func deserialize_slots(data: Dictionary) -> void:
	print("EventSlotManager: 开始反序列化卡槽数据")
	
	# 清空现有数据
	event_slots.clear()
	selected_branches.clear()
	
	# 恢复分支选择
	if data.has("selected_branches"):
		selected_branches = data.selected_branches
		print("EventSlotManager: 恢复分支选择数据 - 数量:", selected_branches.size())
	
	# 恢复卡槽数据
	if data.has("event_slots"):
		var slots_data = data.event_slots
		
		for event_id_str in slots_data.keys():
			var event_id = int(event_id_str)
			var slots_array_data = slots_data[event_id_str]
			var restored_slots = []
			
			for slot_data in slots_array_data:
				var slot = EventSlotData.new()
				slot.event_id = slot_data.get("event_id", event_id)
				slot.slot_id = slot_data.get("slot_id", 0)
				slot.slot_description = slot_data.get("slot_description", "")
				
				# 将Array转换回JSON字符串存储
				var allowed_types = slot_data.get("allowed_card_types", [])
				slot.allowed_card_types_json = JSON.stringify(allowed_types)
				
				slot.required_for_completion = slot_data.get("required_for_completion", false)
				slot.placed_card_type = slot_data.get("placed_card_type", "")
				slot.placed_card_id = slot_data.get("placed_card_id", "")
				slot.placed_card_data = slot_data.get("placed_card_data", {})
				
				# 将Dictionary转换回JSON字符串存储
				var specific_reqs = slot_data.get("specific_requirements", {})
				slot.specific_card_json = JSON.stringify(specific_reqs)
				
				restored_slots.append(slot)
			
			event_slots[event_id] = restored_slots
			print("EventSlotManager: 恢复事件", event_id, "的卡槽数据 - 数量:", restored_slots.size())
	
	print("EventSlotManager: 反序列化完成 - 事件数:", event_slots.size())
	slots_loaded.emit()
