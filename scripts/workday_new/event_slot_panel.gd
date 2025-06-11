extends Control

# EventSlotPanel - 事件卡槽面板
# 管理单个事件的所有卡槽显示和交互

signal slot_clicked(event_id: int, slot_id: int, slot_data: EventSlotData)
signal slots_status_changed(event_id: int)

# 节点引用
@onready var title_label = $VBoxContainer/HeaderContainer/TitleLabel
@onready var info_button = $VBoxContainer/HeaderContainer/InfoButton
@onready var scroll_container = $VBoxContainer/ScrollContainer
@onready var slots_container = $VBoxContainer/ScrollContainer/SlotsContainer
@onready var no_slots_label = $VBoxContainer/NoSlotsLabel

# 预加载卡槽项目场景
const EventSlotItemScene = preload("res://scenes/workday_new/components/event_slot_item.tscn")

# 当前事件信息
var current_event_id: int = 0
var slot_items: Array = []  # 存储所有卡槽项目的引用

func _ready():
	# 连接信号
	info_button.pressed.connect(_on_info_button_pressed)
	
	# 连接EventSlotManager信号
	if EventSlotManager:
		EventSlotManager.slots_updated.connect(_on_slots_updated)
	
	print("EventSlotPanel: 卡槽面板已初始化")

# 加载指定事件的卡槽
func load_event_slots(event_id: int):
	current_event_id = event_id
	clear_slots()
	
	print("EventSlotPanel: 开始加载事件 ", event_id, " 的卡槽")
	
	if not EventSlotManager:
		print("EventSlotPanel: 警告 - EventSlotManager未找到")
		_show_no_slots()
		return
	
	var slot_data_array = EventSlotManager.get_event_slots(event_id)
	
	if slot_data_array.is_empty():
		print("EventSlotPanel: 事件 ", event_id, " 没有卡槽配置")
		_show_no_slots()
		return
	
	# 显示卡槽容器，隐藏无卡槽提示
	scroll_container.visible = true
	no_slots_label.visible = false
	
	# 按slot_id排序
	slot_data_array.sort_custom(func(a, b): return a.slot_id < b.slot_id)
	
	# 为每个卡槽创建项目
	for slot_data in slot_data_array:
		_create_slot_item(slot_data)
	
	print("EventSlotPanel: 成功加载 ", slot_data_array.size(), " 个卡槽")

# 创建单个卡槽项目
func _create_slot_item(slot_data: EventSlotData):
	var slot_item = EventSlotItemScene.instantiate()
	slots_container.add_child(slot_item)
	slot_items.append(slot_item)
	
	# 设置卡槽数据
	slot_item.setup_slot(slot_data)
	
	# 连接信号
	slot_item.slot_clicked.connect(_on_slot_item_clicked)
	slot_item.slot_card_changed.connect(_on_slot_card_changed)
	
	print("EventSlotPanel: 创建卡槽项目 - ", slot_data.slot_id, ": ", slot_data.slot_description)

# 清空所有卡槽项目
func clear_slots():
	for item in slot_items:
		if is_instance_valid(item):
			item.queue_free()
	slot_items.clear()
	
	# 清空容器中的子节点
	for child in slots_container.get_children():
		slots_container.remove_child(child)
		child.queue_free()

# 显示无卡槽状态
func _show_no_slots():
	scroll_container.visible = false
	no_slots_label.visible = true

# 更新标题
func set_title(title: String):
	if title_label:
		title_label.text = title

# 刷新所有卡槽显示
func refresh_slots():
	if current_event_id > 0:
		load_event_slots(current_event_id)

# 获取卡槽填充状态
func get_slots_status() -> Dictionary:
	var status = {
		"total_slots": slot_items.size(),
		"filled_slots": 0,
		"required_slots": 0,
		"required_filled": 0
	}
	
	for item in slot_items:
		if item.has_method("get_slot_data"):
			var slot_data = item.get_slot_data()
			if slot_data:
				if slot_data.required_for_completion:
					status.required_slots += 1
					if slot_data.has_card_placed():
						status.required_filled += 1
				
				if slot_data.has_card_placed():
					status.filled_slots += 1
	
	return status

# 检查是否满足完成条件
func can_complete_event() -> bool:
	if not EventSlotManager:
		return true
	
	return EventSlotManager.are_required_slots_filled(current_event_id)

# 信号处理函数
func _on_slot_item_clicked(slot_data: EventSlotData):
	print("EventSlotPanel: 卡槽项目被点击 - ", slot_data.slot_id)
	slot_clicked.emit(current_event_id, slot_data.slot_id, slot_data)

func _on_slot_card_changed(slot_data: EventSlotData):
	print("EventSlotPanel: 卡槽卡牌状态变化 - ", slot_data.slot_id)
	slots_status_changed.emit(current_event_id)

func _on_slots_updated(event_id: int):
	if event_id == current_event_id:
		print("EventSlotPanel: 接收到卡槽更新信号，刷新显示")
		refresh_slots()

func _on_info_button_pressed():
	print("EventSlotPanel: 显示卡槽信息帮助")
	# 这里可以显示帮助信息弹窗
	if EventSlotManager:
		var debug_info = EventSlotManager.get_debug_info(current_event_id)
		print("=== 卡槽调试信息 ===")
		print(debug_info)

# 根据卡牌类型获取对应的卡槽
func get_slots_for_card_type(card_type: String) -> Array:
	var matching_slots = []
	
	for item in slot_items:
		if item.has_method("get_slot_data"):
			var slot_data = item.get_slot_data()
			if slot_data and slot_data.is_card_type_allowed(card_type):
				matching_slots.append(slot_data)
	
	return matching_slots

# 高亮显示可用的卡槽
func highlight_available_slots(card_type: String):
	for item in slot_items:
		if item.has_method("set_highlight") and item.has_method("get_slot_data"):
			var slot_data = item.get_slot_data()
			if slot_data:
				var can_place = slot_data.is_card_type_allowed(card_type) and not slot_data.has_card_placed()
				item.set_highlight(can_place)

# 清除所有高亮
func clear_all_highlights():
	for item in slot_items:
		if item.has_method("set_highlight"):
			item.set_highlight(false)

# 获取已放置的卡牌信息
func get_placed_cards_info() -> Array:
	var placed_cards = []
	
	for item in slot_items:
		if item.has_method("get_slot_data"):
			var slot_data = item.get_slot_data()
			if slot_data and slot_data.has_card_placed():
				placed_cards.append({
					"slot_id": slot_data.slot_id,
					"card_type": slot_data.placed_card_type,
					"card_id": slot_data.placed_card_id,
					"contributes_to_check": slot_data.contributes_to_check
				})
	
	return placed_cards

# 获取属性贡献
func get_total_attribute_contribution() -> Dictionary:
	if not EventSlotManager:
		return {}
	
	return EventSlotManager.get_event_attribute_contribution(current_event_id) 