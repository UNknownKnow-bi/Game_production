extends Node

# EventSlotManager - 事件卡槽管理器单例
# 管理所有事件的卡槽配置和状态

signal slot_card_placed(event_id: int, slot_id: int, card_type: String, card_id: String)
signal slot_card_removed(event_id: int, slot_id: int)
signal slots_updated(event_id: int)
signal slots_loaded

# 存储所有卡槽数据，按event_id分组
var event_slots: Dictionary = {}  # event_id -> Array[EventSlotData]

# 数据文件路径
const SLOTS_DATA_PATH = "res://data/events/event_slots.tsv"

func _ready():
	print("EventSlotManager: 开始初始化")
	load_slots_from_tsv(SLOTS_DATA_PATH)
	print("EventSlotManager: 初始化完成，加载状态: ", get_loading_status())

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
	
	# 处理互斥冲突
	var removed_cards = remove_conflicting_cards(event_id, slot_id)
	if removed_cards.size() > 0:
		print("EventSlotManager: 处理互斥冲突，移除了 ", removed_cards.size(), " 张卡牌")
		for removed_card in removed_cards:
			slot_card_removed.emit(event_id, removed_card.slot_id)
	
	if slot_data.place_card(card_type, card_id, card_data):
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
		slot_data.remove_card()
		print("EventSlotManager: 从卡槽 ", event_id, "-", slot_id, " 移除卡牌")
		slot_card_removed.emit(event_id, slot_id)
		slots_updated.emit(event_id)
		return true
	else:
		print("EventSlotManager: 卡槽 ", event_id, "-", slot_id, " 没有卡牌可移除")
		return false

# 检查事件的必须卡槽是否都已填充
func are_required_slots_filled(event_id: int) -> bool:
	var slots = get_event_slots(event_id)
	for slot in slots:
		if slot.required_for_completion and not slot.has_card_placed():
			return false
	return true

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
	for slot in slots:
		if slot.has_card_placed():
			slot.remove_card()
	
	print("EventSlotManager: 清空事件 ", event_id, " 的所有卡槽")
	slots_updated.emit(event_id)

# 获取调试信息
func get_debug_info(event_id: int = -1) -> String:
	var info = "=== EventSlotManager 调试信息 ===\n"
	
	if event_id > 0:
		# 显示特定事件的信息
		var slots = get_event_slots(event_id)
		info += "事件 %d 的卡槽信息:\n" % event_id
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