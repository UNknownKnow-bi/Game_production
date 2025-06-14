extends Control

signal option_selected(option_id, event_id)
signal popup_closed

@onready var title_label = $PopupPanel/HSplitContainer/LeftPanel/TitleLabel
@onready var content_text = $PopupPanel/HSplitContainer/LeftPanel/ContentText
@onready var event_image = $PopupPanel/HSplitContainer/LeftPanel/EventImage
@onready var accept_button = $PopupPanel/HSplitContainer/LeftPanel/ButtonsContainer/AcceptButton
@onready var reject_button = $PopupPanel/HSplitContainer/LeftPanel/ButtonsContainer/RejectButton
@onready var close_button = $PopupPanel/CloseButton
@onready var attributes_bar = $PopupPanel/HSplitContainer/LeftPanel/AttributesBar

# 卡槽系统相关节点
@onready var slots_container = $PopupPanel/HSplitContainer/RightPanel/SlotsPanelContainer/SlotsContainer

# 预加载卡槽项目场景
const EventSlotItemScene = preload("res://scenes/workday_new/components/event_slot_item.tscn")

# 预加载卡片面板场景
const CardDisplayPanelScene = preload("res://scenes/ui/card_display_panel.tscn")
const ItemCardDisplayPanelScene = preload("res://scenes/ui/item_card_display_panel.tscn")
const CardDetailPanelScene = preload("res://scenes/ui/card_detail_panel.tscn")

var current_event_id = -1
var slot_items: Array = []  # 存储卡槽项目引用

# 卡片选择状态管理
var current_selecting_slot: EventSlotData = null
var active_card_panel = null

# 属性映射系统
var attribute_mapping = {
	"social": {"name": "社交", "type": "basic"},
	"resistance": {"name": "抗压", "type": "basic"},
	"innovation": {"name": "创新", "type": "basic"},
	"execution": {"name": "执行", "type": "basic"},
	"physical": {"name": "体魄", "type": "basic"},
	"power": {"name": "权势", "type": "overall"},
	"reputation": {"name": "声望", "type": "overall"},
	"piety": {"name": "虔信", "type": "overall"}
}

func _ready():
	# 连接按钮信号
	accept_button.pressed.connect(_on_accept_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	
	# 连接EventSlotManager信号
	if EventSlotManager:
		EventSlotManager.slots_updated.connect(_on_slots_updated_from_manager)
		print("EventPopup: 已连接EventSlotManager.slots_updated信号")
	
	# 初始化卡槽面板
	_setup_slot_panel()
	
	# 默认隐藏
	visible = false
	
	# 确保弹窗显示在最顶层
	z_index = 1000
	print("事件弹窗z_index设置为: ", z_index)

# 初始化卡槽面板
func _setup_slot_panel():
	# 不再实例化EventSlotPanel，直接使用现有布局
	print("EventPopup: 使用现有卡槽布局结构")

# 调试UI可见性
func _debug_ui_visibility():
	print("=== EventPopup UI可见性调试 ===")
	print("EventPopup visible:", visible)
	print("PopupPanel visible:", $PopupPanel.visible if has_node("PopupPanel") else "节点不存在")
	print("HSplitContainer visible:", $PopupPanel/HSplitContainer.visible if has_node("PopupPanel/HSplitContainer") else "节点不存在")
	print("RightPanel visible:", $PopupPanel/HSplitContainer/RightPanel.visible if has_node("PopupPanel/HSplitContainer/RightPanel") else "节点不存在")
	print("SlotsPanelContainer visible:", $PopupPanel/HSplitContainer/RightPanel/SlotsPanelContainer.visible if has_node("PopupPanel/HSplitContainer/RightPanel/SlotsPanelContainer") else "节点不存在")
	print("SlotsContainer visible:", slots_container.visible if slots_container else "slots_container为null")
	
	if slots_container:
		print("SlotsContainer子节点数:", slots_container.get_child_count())
		print("SlotsContainer大小:", slots_container.size)
		print("SlotsContainer位置:", slots_container.position)
		
		for i in range(slots_container.get_child_count()):
			var child = slots_container.get_child(i)
			print("  子节点", i, ":", child.name, " visible:", child.visible, " 大小:", child.size)
	
	print("slot_items数组长度:", slot_items.size())
	print("=== UI可见性调试结束 ===")

# 显示事件弹窗
func show_event(event_data: Dictionary):
	current_event_id = event_data.event_id
	
	# 设置标题和内容
	title_label.text = event_data.title
	content_text.text = event_data.description
	
	# 如果有图像，加载并显示
	if event_data.has("image_path") and event_data.image_path != "":
		var texture = load(event_data.image_path)
		if texture:
			event_image.texture = texture
			event_image.visible = true
		else:
			event_image.visible = false
	else:
		event_image.visible = false
	
	# 设置确认按钮文本
	accept_button.text = "确认"
	
	# 强制隐藏拒绝按钮
	reject_button.visible = false
	
	# 设置属性展示
	if event_data.has("global_check"):
		_setup_attributes_display(event_data.global_check)
	else:
		_clear_attributes_display()
	
	# 加载卡槽系统
	_load_event_slots(event_data.event_id)
	
	# 显示弹窗
	visible = true
	
	# 调试UI可见性
	call_deferred("_debug_ui_visibility")

# 加载事件卡槽
func _load_event_slots(event_id: int):
	current_event_id = event_id
	_clear_all_slots()
	
	print("EventPopup: 开始加载事件 ", event_id, " 的卡槽")
	
	if not EventSlotManager:
		print("EventPopup: 警告 - EventSlotManager未找到")
		return
	
	var slot_data_array = EventSlotManager.get_event_slots(event_id)
	
	if slot_data_array.is_empty():
		print("EventPopup: 事件 ", event_id, " 没有卡槽配置")
		return
	
	# 按slot_id排序
	slot_data_array.sort_custom(func(a, b): return a.slot_id < b.slot_id)
	
	# 直接创建卡槽项目
	for slot_data in slot_data_array:
		_create_slot_item_direct(slot_data)
	
	print("EventPopup: 成功加载 ", slot_data_array.size(), " 个卡槽")
	
	# 优化时序：确保所有卡槽项目创建完成后再进行布局更新
	call_deferred("_wait_for_slots_layout_complete")

# 等待卡槽布局完成（新增方法）
func _wait_for_slots_layout_complete():
	# 双重延迟执行，确保布局系统完全稳定
	call_deferred("_update_slots_disabled_state")

# 直接创建卡槽项目
func _create_slot_item_direct(slot_data: EventSlotData):
	var slot_item = EventSlotItemScene.instantiate()
	slots_container.add_child(slot_item)
	slot_items.append(slot_item)
	
	# 设置卡槽数据
	slot_item.setup_slot(slot_data)
	
	# 连接信号
	slot_item.slot_clicked.connect(_on_slot_item_clicked_direct)
	slot_item.slot_card_changed.connect(_on_slot_card_changed_direct)
	
	print("EventPopup: 创建卡槽项目 - ", slot_data.slot_id, ": ", slot_data.slot_description)

# 清空所有卡槽项目
func _clear_all_slots():
	for item in slot_items:
		if is_instance_valid(item):
			item.queue_free()
	slot_items.clear()
	
	# 清空容器中的子节点
	for child in slots_container.get_children():
		slots_container.remove_child(child)
		child.queue_free()

# 直接处理卡槽项目点击
func _on_slot_item_clicked_direct(slot_data: EventSlotData):
	print("EventPopup: 卡槽项目被点击 - ", slot_data.slot_id)
	_on_slot_clicked(current_event_id, slot_data.slot_id, slot_data)

# 直接处理卡槽卡牌变化
func _on_slot_card_changed_direct(slot_data: EventSlotData):
	print("EventPopup: 卡槽卡牌状态变化 - ", slot_data.slot_id)
	_on_slots_status_changed(current_event_id)

# 卡槽点击处理
func _on_slot_clicked(event_id: int, slot_id: int, slot_data: EventSlotData):
	print("EventPopup: 卡槽被点击 - 事件", event_id, "槽位", slot_id)
	
	# 获取允许的卡牌类型
	var allowed_types = slot_data.get_allowed_card_types()
	if allowed_types.is_empty():
		print("EventPopup: 卡槽无允许的卡牌类型")
		return
	
	# 按照用户需求的顺序：先角色卡，再特权卡，最后情报卡
	var card_type_priority = ["角色卡", "特权卡", "情报卡"]
	var first_allowed_type = ""
	
	for card_type in card_type_priority:
		if card_type in allowed_types:
			first_allowed_type = card_type
			break
	
	if first_allowed_type.is_empty():
		print("EventPopup: 无匹配的卡牌类型")
		return
	
	# 打开对应的背包面板
	_open_card_selection_panel(first_allowed_type, slot_data)

# 打开卡牌选择面板
func _open_card_selection_panel(card_type: String, slot_data: EventSlotData):
	print("EventPopup: 打开", card_type, "选择面板")
	
	match card_type:
		"角色卡":
			_open_character_card_panel(slot_data)
		"情报卡":
			_open_item_card_panel(slot_data)
		"特权卡":
			_open_privilege_card_panel(slot_data)
		_:
			print("EventPopup: 未知卡牌类型: ", card_type)

# 打开角色卡面板
func _open_character_card_panel(slot_data: EventSlotData):
	print("EventPopup: 打开角色卡选择面板 - 槽位", slot_data.slot_id)
	
	# 保存当前选择的卡槽
	current_selecting_slot = slot_data
	
	# 创建角色卡展示面板实例
	var card_panel = CardDisplayPanelScene.instantiate()
	active_card_panel = card_panel
	
	# 获取UI层并添加面板
	var ui_layer = _find_ui_layer()
	if ui_layer:
		ui_layer.add_child(card_panel)
		card_panel.z_index = 1001  # 确保在EventPopup之上
	else:
		get_tree().root.add_child(card_panel)
		card_panel.z_index = 1001  # 确保在EventPopup之上
	
	# 连接信号
	card_panel.card_selected.connect(_on_card_selected)
	card_panel.panel_closed.connect(_on_card_panel_closed)
	
	# 进入选择模式
	var allowed_types = slot_data.get_allowed_card_types()
	card_panel.enter_selection_mode(slot_data, allowed_types)

# 打开情报卡面板
func _open_item_card_panel(slot_data: EventSlotData):
	print("EventPopup: 打开情报卡选择面板 - 槽位", slot_data.slot_id)
	
	# 保存当前选择的卡槽
	current_selecting_slot = slot_data
	
	# 创建情报卡展示面板实例
	var card_panel = ItemCardDisplayPanelScene.instantiate()
	active_card_panel = card_panel
	
	# 获取UI层并添加面板
	var ui_layer = _find_ui_layer()
	if ui_layer:
		ui_layer.add_child(card_panel)
		card_panel.z_index = 1001  # 确保在EventPopup之上
	else:
		get_tree().root.add_child(card_panel)
		card_panel.z_index = 1001  # 确保在EventPopup之上
	
	# 连接信号
	card_panel.card_selected.connect(_on_card_selected)
	card_panel.panel_closed.connect(_on_card_panel_closed)
	
	# 进入选择模式
	var allowed_types = slot_data.get_allowed_card_types()
	card_panel.enter_selection_mode(slot_data, allowed_types)

# 打开特权卡面板
func _open_privilege_card_panel(slot_data: EventSlotData):
	print("EventPopup: 打开特权卡选择面板 - 槽位", slot_data.slot_id)
	
	# 保存当前选择的卡槽
	current_selecting_slot = slot_data
	
	# 创建特权卡详情面板实例
	var card_panel = CardDetailPanelScene.instantiate()
	active_card_panel = card_panel
	
	# 获取UI层并添加面板
	var ui_layer = _find_ui_layer()
	if ui_layer:
		ui_layer.add_child(card_panel)
		card_panel.z_index = 1001  # 确保在EventPopup之上
	else:
		get_tree().root.add_child(card_panel)
		card_panel.z_index = 1001  # 确保在EventPopup之上
	
	# 显示面板
	card_panel.show_panel()
	
	# 连接信号
	card_panel.card_selected.connect(_on_card_selected)
	card_panel.panel_closed.connect(_on_card_panel_closed)
	
	# 进入选择模式
	var allowed_types = slot_data.get_allowed_card_types()
	card_panel.enter_selection_mode(slot_data, allowed_types)
	
	# 检查特定卡牌要求
	var specific_requirements = slot_data.get_specific_card_requirements()
	if specific_requirements.has("特权卡"):
		var required_cards = specific_requirements["特权卡"]
		print("EventPopup: 特权卡要求: ", required_cards)

# 处理卡片选择
func _on_card_selected(card_type: String, card_id: String, card_data):
	print("EventPopup: 接收到卡片选择 - ", card_type, "[", card_id, "]")
	
	if not current_selecting_slot:
		print("EventPopup: 错误 - 没有当前选择的卡槽")
		return
	
	# 尝试放置卡牌到卡槽
	if EventSlotManager:
		var success = EventSlotManager.place_card_in_slot(
			current_selecting_slot.event_id,
			current_selecting_slot.slot_id,
			card_type,
			card_id,
			card_data
		)
		
		if success:
			print("EventPopup: 卡牌放置成功")
			# 刷新卡槽显示
			_refresh_slot_item(current_selecting_slot)
			# 更新禁用状态
			_update_slots_disabled_state()
		else:
			print("EventPopup: 卡牌放置失败")
	
	# 清理选择状态
	_cleanup_card_selection()

# 处理卡片面板关闭
func _on_card_panel_closed():
	print("EventPopup: 卡片面板已关闭")
	_cleanup_card_selection()

# 清理卡片选择状态
func _cleanup_card_selection():
	current_selecting_slot = null
	if active_card_panel and is_instance_valid(active_card_panel):
		active_card_panel.queue_free()
	active_card_panel = null

# 刷新特定卡槽项目显示
func _refresh_slot_item(slot_data: EventSlotData):
	for item in slot_items:
		if item.has_method("get_slot_data"):
			var item_slot_data = item.get_slot_data()
			if item_slot_data and item_slot_data.event_id == slot_data.event_id and item_slot_data.slot_id == slot_data.slot_id:
				item.update_display()
				break

# 查找UI层
func _find_ui_layer():
	# 尝试找到UILayer
	var ui_layer = get_tree().root.find_child("UILayer", true, false)
	if ui_layer:
		return ui_layer
	
	# 回退方案：寻找CanvasLayer
	var canvas_layers = []
	_find_canvas_layers_recursive(get_tree().root, canvas_layers)
	
	if canvas_layers.size() > 0:
		canvas_layers.sort_custom(func(a, b): return a.layer > b.layer)
		return canvas_layers[0]
	
	return null

# 递归查找CanvasLayer节点
func _find_canvas_layers_recursive(node, result_array):
	for child in node.get_children():
		if child is CanvasLayer:
			result_array.append(child)
		_find_canvas_layers_recursive(child, result_array)

# 卡槽状态变化处理
func _on_slots_status_changed(event_id: int):
	print("EventPopup: 卡槽状态发生变化 - 事件", event_id)
	
	# 重新计算属性贡献
	_update_attribute_display_with_slots()
	
	# 检查完成条件
	_check_completion_status()

# 更新属性显示，包含卡槽贡献
func _update_attribute_display_with_slots():
	if not EventSlotManager or current_event_id <= 0:
		return
	
	# 获取卡槽提供的属性贡献
	var slot_contribution = EventSlotManager.get_event_attribute_contribution(current_event_id)
	print("EventPopup: 卡槽属性贡献: ", slot_contribution)
	
	# 这里可以更新属性栏显示，显示总的属性值（基础+卡槽贡献）

# 检查完成条件
func _check_completion_status():
	if not EventSlotManager or current_event_id <= 0:
		return
	
	var can_complete = EventSlotManager.are_required_slots_filled(current_event_id)
	
	# 根据完成条件更新确认按钮状态
	if can_complete:
		accept_button.disabled = false
		accept_button.text = "确认"
	else:
		accept_button.disabled = true
		accept_button.text = "确认 (需要填充必需卡槽)"

# 设置属性展示
func _setup_attributes_display(global_check: Dictionary):
	print("EventPopup: 设置属性展示 - 接收到的global_check: ", global_check)
	print("EventPopup: global_check数据类型: ", typeof(global_check))
	print("EventPopup: global_check是否为空: ", global_check.is_empty())
	
	if not global_check.is_empty():
		print("EventPopup: global_check包含的键: ", global_check.keys())
		for key in global_check.keys():
			print("EventPopup: ", key, " = ", global_check[key], " (类型: ", typeof(global_check[key]), ")")
	
	# 清空现有显示
	_clear_attributes_display()
	
	# 解析global_check数据
	var attribute_requirements = _parse_global_check(global_check)
	
	if attribute_requirements.is_empty():
		print("EventPopup: 无属性需求，隐藏属性栏")
		attributes_bar.visible = false
		return
	
	# 显示属性栏
	attributes_bar.visible = true
	
	# 创建属性图标区域容器
	var icons_container = HBoxContainer.new()
	icons_container.add_theme_constant_override("separation", 20)
	
	# 为每个属性需求创建图标显示项
	for req in attribute_requirements:
		var attribute_item = _create_attribute_icon_item(req.attribute)
		if attribute_item:
			icons_container.add_child(attribute_item)
			print("EventPopup: 添加属性图标项 - ", req.attribute)
	
	# 创建需求信息汇总区域
	var requirements_summary = _create_requirements_summary(attribute_requirements)
	
	# 添加到主AttributesBar
	attributes_bar.add_child(icons_container)
	attributes_bar.add_child(requirements_summary)

# 解析global_check数据
func _parse_global_check(global_check: Dictionary) -> Array:
	var requirements = []
	
	# 处理新格式
	if global_check.has("required_checks"):
		var checks = global_check["required_checks"]
		if checks is Array:
			for check in checks:
				if check is Dictionary and check.has("attribute") and check.has("threshold"):
					requirements.append({
						"attribute": check.get("attribute", ""),
						"threshold": check.get("threshold", 0),
						"success_required": check.get("success_required", 1)
					})
		return requirements
	
	# 处理旧格式 - 向后兼容
	if global_check.has("check_mode"):
		var check_mode = global_check.get("check_mode", "")
		if check_mode == "single_attribute":
			var attr_check = global_check.get("single_attribute_check", {})
			if attr_check.has("attribute_name") and attr_check.has("threshold"):
				requirements.append({
					"attribute": attr_check.get("attribute_name", ""),
					"threshold": attr_check.get("threshold", 0),
					"success_required": attr_check.get("success_required", 1)
				})
		elif check_mode == "multi_attribute":
			var checks = global_check.get("multi_attribute_check", [])
			for check in checks:
				if check.has("attribute_name") and check.has("threshold"):
					requirements.append({
						"attribute": check.get("attribute_name", ""),
						"threshold": check.get("threshold", 0),
						"success_required": check.get("success_required", 1)
					})
	
	return requirements

# 计算需求信息汇总
func _calculate_requirements_summary(requirements: Array) -> Dictionary:
	var total_threshold = 0
	var total_success_required = 0
	
	# 遍历所有属性需求，累加值
	for req in requirements:
		total_threshold += req.threshold  # 所有threshold相加
		total_success_required += req.success_required  # 所有success_required相加
	
	return {
		"total_threshold": total_threshold,
		"total_success_required": total_success_required
	}

# 创建需求信息汇总显示
func _create_requirements_summary(requirements: Array) -> Control:
	var summary = _calculate_requirements_summary(requirements)
	
	var summary_container = VBoxContainer.new()
	summary_container.add_theme_constant_override("separation", 4)
	summary_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# 统一的需求信息标签
	var requirement_label = Label.new()
	requirement_label.text = "检定需要累积 >= %d, 至少成功 >= %d 次" % [summary.total_threshold, summary.total_success_required]
	requirement_label.add_theme_font_size_override("font_size", 20)
	requirement_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))
	requirement_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	summary_container.add_child(requirement_label)
	return summary_container

# 创建属性图标项显示
func _create_attribute_icon_item(attribute_name: String) -> Control:
	# 验证属性名称
	if not attribute_mapping.has(attribute_name):
		print("EventPopup: 警告 - 未知属性名称: ", attribute_name)
		return null
	
	# 创建属性项容器 - 垂直布局
	var item_container = VBoxContainer.new()
	item_container.add_theme_constant_override("separation", 8)
	
	# 创建属性图标
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var icon_path = _get_attribute_icon_path(attribute_name)
	if FileAccess.file_exists(icon_path):
		icon.texture = load(icon_path)
	else:
		print("EventPopup: 警告 - 属性图标不存在: ", icon_path)
	
	item_container.add_child(icon)
	
	# 属性名称标签 - 居中对齐
	var name_label = Label.new()
	name_label.text = attribute_mapping[attribute_name].name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	item_container.add_child(name_label)
	
	return item_container

# 获取属性图标路径
func _get_attribute_icon_path(attribute_name: String) -> String:
	return "res://assets/cards/attribute/" + attribute_name + ".png"

# 清空属性展示
func _clear_attributes_display():
	for child in attributes_bar.get_children():
		attributes_bar.remove_child(child)
		child.queue_free()

# 隐藏弹窗
func hide_popup():
	visible = false
	current_event_id = -1
	
	# 清空卡槽项目
	_clear_all_slots()

# 按钮回调
func _on_accept_button_pressed():
	# 在确认前检查卡槽完成状态
	if EventSlotManager and current_event_id > 0:
		if not EventSlotManager.are_required_slots_filled(current_event_id):
			print("EventPopup: 无法完成事件 - 必需卡槽未填充")
			return
	
	option_selected.emit(1, current_event_id)
	hide_popup()

func _on_close_button_pressed():
	popup_closed.emit()
	hide_popup()

# 面板关闭时清理
func _on_popup_panel_popup_hide():
	print("EventPopup: 面板隐藏，清理资源")
	_cleanup_card_selection()
	current_event_id = -1
	
	# 清理卡槽引用
	slot_items.clear()

# 处理EventSlotManager的slots_updated信号
func _on_slots_updated_from_manager(event_id: int):
	if event_id == current_event_id:
		print("EventPopup: 接收到EventSlotManager.slots_updated信号 - 事件", event_id)
		# 刷新所有卡槽显示，包括禁用状态
		_refresh_all_slots()
		_update_slots_disabled_state()

# 刷新所有卡槽显示
func _refresh_all_slots():
	for item in slot_items:
		if item.has_method("update_display"):
			item.update_display()

# 更新卡槽禁用状态
func _update_slots_disabled_state():
	if not EventSlotManager or current_event_id <= 0:
		return
	
	var disabled_slots = EventSlotManager.get_mutually_exclusive_disabled_slots(current_event_id)
	print("EventPopup: 需要禁用的卡槽: ", disabled_slots)
	
	for item in slot_items:
		if item.has_method("get_slot_data") and item.has_method("set_disabled_state"):
			var slot_data = item.get_slot_data()
			if slot_data:
				var should_disable = slot_data.slot_id in disabled_slots
				item.set_disabled_state(should_disable)
