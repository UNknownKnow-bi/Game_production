class_name ItemCardDisplayPanel
extends Panel

# 预加载情报卡场景
const ItemCardScene = preload("res://scenes/item_card.tscn")

# 情报卡管理器引用
var item_card_manager

# 节点引用
@onready var vbox_container: VBoxContainer = $ScrollContainer/VBoxContainer
@onready var close_button = $CloseButton
@onready var character_icon_button = $CharacterIconButton
@onready var other_icon_button = $OtherIconButton

# 信号
signal panel_closed
signal switch_to_character_panel
signal switch_to_item_panel

# 选择模式相关
var is_in_selection_mode: bool = false
var current_slot_data: EventSlotData = null
var allowed_card_types: Array = []

# 信号定义
signal card_selected(card_type: String, card_id: String, card_data)

# 初始化
func _ready():
	print("=== ItemCardDisplayPanel初始化开始 ===")
	print("ItemCardDisplayPanel: 面板大小 - ", size)
	print("ItemCardDisplayPanel: VBoxContainer引用 - ", vbox_container != null)
	
	# 设置初始状态
	item_card_manager = get_node("/root/ItemCardManager")
	
	# 连接信号
	close_button.pressed.connect(_on_close_button_pressed)
	character_icon_button.pressed.connect(_on_character_icon_pressed)
	other_icon_button.pressed.connect(_on_other_icon_pressed)
	
	# 设置按钮状态（当前面板是物品卡面板）
	character_icon_button.disabled = false
	character_icon_button.modulate = Color.WHITE
	other_icon_button.disabled = true
	other_icon_button.modulate = Color(1.0, 1.0, 1.0, 0.5)  # 半透明表示当前面板
	
	# 加载并显示所有物品卡片
	load_and_display_cards()
	
	# 设置背景可点击关闭
	$PanelBackground.gui_input.connect(_on_background_input)

# 加载并显示所有物品卡片
func load_and_display_cards():
	print("ItemCardDisplayPanel: 开始加载物品卡片数据")
	
	# 检查ItemCardManager是否可用
	if not item_card_manager:
		print("ItemCardDisplayPanel: 错误 - ItemCardManager未初始化")
		return
	
	# 从背包管理器获取玩家拥有的情报卡实例
	if not ItemCardInventoryManager:
		print("ItemCardDisplayPanel: 错误 - ItemCardInventoryManager未初始化")
		return
	
	var inventory_instances = ItemCardInventoryManager.get_all_instances()
	print("ItemCardDisplayPanel: 获取到背包中的情报卡数量 - ", inventory_instances.size())
	
	# 清除现有卡片（如果有）
	clear_existing_cards()
	
	if inventory_instances.is_empty():
		# 显示空背包状态
		show_empty_inventory_message()
		return
	
	# 为每个情报卡实例创建显示
	for card_instance in inventory_instances:
		var original_card_data = card_instance.get_original_card_data()
		if original_card_data:
			create_and_display_card(original_card_data)
		else:
			print("ItemCardDisplayPanel: 跳过无效的情报卡实例 - ID: ", card_instance.card_id)
	
	print("ItemCardDisplayPanel: ✓ 所有卡片显示完成")

# 清除现有卡片
func clear_existing_cards():
	if not vbox_container:
		return
		
	for child in vbox_container.get_children():
		child.queue_free()
	
	print("ItemCardDisplayPanel: 清除现有卡片和包装容器")

# 创建并显示单个卡片
func create_and_display_card(card_data: ItemCardData):
	if not card_data or not card_data.validate():
		print("ItemCardDisplayPanel: 跳过无效卡片数据")
		return
	
	print("ItemCardDisplayPanel: 创建卡片显示 - ", card_data.card_name)
	
	# 创建包装容器
	var wrapper_container = Control.new()
	wrapper_container.custom_minimum_size = Vector2(500, 200)
	wrapper_container.size = Vector2(500, 200)
	wrapper_container.size_flags_horizontal = 0
	wrapper_container.size_flags_vertical = 0
	wrapper_container.clip_contents = true
	
	# 加载ItemCard场景
	var item_card_scene = preload("res://scenes/item_card.tscn")
	var item_card_instance = item_card_scene.instantiate()
	
	# 将ItemCard添加到包装容器
	wrapper_container.add_child(item_card_instance)
	
	# 添加包装容器到VBoxContainer
	vbox_container.add_child(wrapper_container)
	
	# 显示卡片数据
	item_card_instance.display_card(card_data)
	
	# 连接卡片点击信号（正常显示模式）
	if item_card_instance.has_signal("card_clicked"):
		var connection_result = item_card_instance.card_clicked.connect(_on_card_clicked_normal_mode.bind(card_data))
		if connection_result == OK:
			print("ItemCardDisplayPanel: ✓ 正常模式信号连接成功 - ", card_data.card_name)
		else:
			print("ItemCardDisplayPanel: ✗ 正常模式信号连接失败 - ", card_data.card_name)
	else:
		print("ItemCardDisplayPanel: ✗ card_clicked信号不存在 - ", card_data.card_name)
	
	print("ItemCardDisplayPanel: ✓ 卡片 ", card_data.card_name, " 显示完成")

# 刷新显示
func refresh_display():
	load_and_display_cards()

# 显示空背包状态消息
func show_empty_inventory_message():
	var empty_message = Label.new()
	empty_message.text = "背包中暂无情报卡\n完成事件获得情报卡奖励后将显示在这里"
	empty_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	empty_message.custom_minimum_size = Vector2(400, 100)
	empty_message.add_theme_font_size_override("font_size", 18)
	empty_message.add_theme_color_override("font_color", Color.GRAY)
	
	vbox_container.add_child(empty_message)
	print("ItemCardDisplayPanel: 显示空背包消息")

# 获取当前显示的卡片数量
func get_displayed_card_count() -> int:
	if not vbox_container:
		return 0
	return vbox_container.get_child_count()

# 进入选择模式
func enter_selection_mode(slot_data: EventSlotData, allowed_types: Array):
	print("ItemCardDisplayPanel: === 进入选择模式 ===")
	print("ItemCardDisplayPanel: 卡槽数据 - 事件ID:", slot_data.event_id if slot_data else "null", " 卡槽ID:", slot_data.slot_id if slot_data else "null")
	print("ItemCardDisplayPanel: 允许的卡片类型 - ", allowed_types)
	
	is_in_selection_mode = true
	current_slot_data = slot_data
	allowed_card_types = allowed_types
	
	print("ItemCardDisplayPanel: 选择模式状态已设置 - ", is_in_selection_mode)
	
	# 刷新显示以突出可选择的卡片
	_refresh_cards_for_selection_mode()

# 退出选择模式
func exit_selection_mode():
	print("ItemCardDisplayPanel: 退出选择模式")
	is_in_selection_mode = false
	current_slot_data = null
	allowed_card_types.clear()
	
	# 恢复正常显示
	refresh_display()

# 刷新卡片显示以适应选择模式
func _refresh_cards_for_selection_mode():
	if not is_in_selection_mode:
		return
	
	print("ItemCardDisplayPanel: === 进入选择模式刷新 ===")
	print("ItemCardDisplayPanel: 当前选择模式状态: ", is_in_selection_mode)
	print("ItemCardDisplayPanel: 允许的卡片类型: ", allowed_card_types)
	
	# 从背包管理器获取玩家拥有的情报卡实例（与正常显示模式保持一致）
	if not ItemCardInventoryManager:
		print("ItemCardDisplayPanel: 错误 - ItemCardInventoryManager未初始化")
		return

	var inventory_instances = ItemCardInventoryManager.get_all_instances()
	print("ItemCardDisplayPanel: 选择模式获取到背包中的情报卡数量 - ", inventory_instances.size())
	
	# 清空现有卡片显示
	for child in vbox_container.get_children():
		vbox_container.remove_child(child)
		child.queue_free()
	
	# 只显示符合允许类型的卡片
	if "情报卡" in allowed_card_types:
		for card_instance in inventory_instances:
			var original_card_data = card_instance.get_original_card_data()
			if not original_card_data:
				print("ItemCardDisplayPanel: 跳过无效的情报卡实例 - ID: ", card_instance.card_id)
				continue
				
			var card_item = ItemCardScene.instantiate()
			vbox_container.add_child(card_item)
			card_item.display_card(original_card_data)
			
			# 检查卡牌是否被占用并标记忙碌状态
			_check_and_mark_busy_card(card_item, "情报卡", str(original_card_data.card_id))
			
			# 延迟连接信号，确保ItemCard的_ready()方法完全执行
			print("ItemCardDisplayPanel: 准备延迟连接信号 - ", original_card_data.card_name)
			call_deferred("_connect_card_signal_deferred", card_item, original_card_data)
			
			# 添加视觉提示表明可选择
			_add_selection_visual_hint(card_item)
			
			print("ItemCardDisplayPanel: 选择模式卡片添加完成 - ", original_card_data.card_name)

# 检查并标记忙碌状态的卡牌
func _check_and_mark_busy_card(card_item, card_type: String, card_id: String):
	var global_usage_manager = get_node_or_null("/root/GlobalCardUsageManager")
	if not global_usage_manager:
		return
	
	if global_usage_manager.is_card_used(card_type, card_id):
		var usage_data = global_usage_manager.get_card_usage(card_type, card_id)
		print("ItemCardDisplayPanel: 卡牌忙碌中 - ", card_type, "[", card_id, "] 在事件", usage_data.event_id)
		
		# 创建忙碌状态覆盖
		_create_busy_overlay(card_item, usage_data)
		
		# 禁用卡牌交互
		card_item.mouse_filter = Control.MOUSE_FILTER_IGNORE

# 创建忙碌状态视觉覆盖
func _create_busy_overlay(card_item, usage_data: CardUsageData):
	# 创建覆盖层容器
	var overlay = ColorRect.new()
	overlay.name = "BusyOverlay"
	overlay.color = Color(0, 0, 0, 0.6)  # 半透明黑色
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 设置覆盖层填满整个卡牌
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# 创建忙碌状态文本
	var busy_label = Label.new()
	busy_label.text = "忙碌中"
	busy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	busy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	busy_label.add_theme_font_size_override("font_size", 24)
	busy_label.add_theme_color_override("font_color", Color.WHITE)
	busy_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 添加描述信息
	var description_label = Label.new()
	description_label.text = "在事件 " + str(usage_data.event_id) + " 中使用"
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description_label.add_theme_font_size_override("font_size", 16)
	description_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	description_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 创建垂直布局容器
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	vbox.add_child(busy_label)
	vbox.add_child(description_label)
	overlay.add_child(vbox)
	
	# 将覆盖层添加到卡牌
	card_item.add_child(overlay)
	
	# 确保覆盖层在最上层
	card_item.move_child(overlay, card_item.get_child_count() - 1)

# 处理卡片选择（用于选择模式）
func _on_card_selected_for_slot(original_card_data):
	print("ItemCardDisplayPanel: === 卡片选择回调触发 ===")
	print("ItemCardDisplayPanel: 选择的卡片 - ", original_card_data.card_name)
	print("ItemCardDisplayPanel: 卡片ID - ", original_card_data.card_id)
	print("ItemCardDisplayPanel: 卡片类型 - ", original_card_data.card_type)
	
	if not current_slot_data:
		print("ItemCardDisplayPanel: ✗ 当前事件槽为空，无法选择卡片")
		return
	
	print("ItemCardDisplayPanel: 目标事件槽 - ", current_slot_data.slot_id)
	
	# 检查卡片是否可用
	if GlobalCardUsageManager.is_card_used("情报卡", str(original_card_data.card_id)):
		print("ItemCardDisplayPanel: ✗ 卡片正在使用中，无法选择")
		var warning_popup = preload("res://scenes/ui/simple_warning_popup.tscn").instantiate()
		if _safe_add_child_to_current_scene(warning_popup):
			warning_popup.show_warning("该卡片正在使用中，请选择其他卡片")
		else:
			print("ItemCardDisplayPanel: 警告 - 无法显示警告弹窗，场景树访问失败")
		return
	
	# 将卡片放置到事件槽
	print("ItemCardDisplayPanel: 开始将卡片放置到事件槽...")
	var success = EventSlotManager.place_card_in_slot(
		current_slot_data.event_id,
		current_slot_data.slot_id,
		original_card_data.card_type,
		str(original_card_data.card_id),
		original_card_data
	)
	
	if success:
		print("ItemCardDisplayPanel: ✓ 卡片成功放置到事件槽")
		print("ItemCardDisplayPanel: EventSlotManager已自动处理卡片使用状态注册和UI更新信号")
		
		# 关闭面板
		print("ItemCardDisplayPanel: 关闭选择面板...")
		hide()
		
		print("ItemCardDisplayPanel: === 卡片选择完成 ===")
		print("ItemCardDisplayPanel: EventSlotManager.slots_updated信号将自动更新事件弹窗的属性显示")
	else:
		print("ItemCardDisplayPanel: ✗ 卡片放置失败")
		var warning_popup = preload("res://scenes/ui/simple_warning_popup.tscn").instantiate()
		if _safe_add_child_to_current_scene(warning_popup):
			warning_popup.show_warning("卡片放置失败，请重试")
		else:
			print("ItemCardDisplayPanel: 警告 - 无法显示警告弹窗，场景树访问失败")

# 显示卡牌忙碌警告
func _show_busy_card_warning(card_id: String, event_id: int):
	print("ItemCardDisplayPanel: 显示卡牌忙碌警告 - ", card_id, " 在事件", event_id)
	# 这里可以显示一个简单的提示，或者发射信号给父级处理
	# 目前只打印日志，实际项目中可以添加UI提示

# 安全地添加子节点到当前场景
func _safe_add_child_to_current_scene(node: Node) -> bool:
	var tree = get_tree()
	if not tree:
		print("ItemCardDisplayPanel: 错误 - 无法获取场景树")
		return false
	
	var current_scene = tree.current_scene
	if not current_scene:
		print("ItemCardDisplayPanel: 错误 - 无法获取当前场景")
		return false
	
	if not is_instance_valid(current_scene):
		print("ItemCardDisplayPanel: 错误 - 当前场景实例无效")
		return false
	
	current_scene.add_child(node)
	return true

# 添加选择模式的视觉提示
func _add_selection_visual_hint(card_item):
	# 检查卡牌是否有忙碌覆盖层
	var has_busy_overlay = card_item.get_node_or_null("BusyOverlay") != null
	
	if not has_busy_overlay:
		# 为可选择的卡牌添加高亮边框
		var highlight_border = ColorRect.new()
		highlight_border.name = "SelectionHighlight"
		highlight_border.color = Color.TRANSPARENT
		highlight_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# 创建样式框架
		var style_box = StyleBoxFlat.new()
		style_box.border_color = Color(0.3, 0.8, 0.3, 0.8)  # 绿色边框
		style_box.border_width_left = 3
		style_box.border_width_right = 3
		style_box.border_width_top = 3
		style_box.border_width_bottom = 3
		style_box.bg_color = Color.TRANSPARENT
		
		# 应用样式到卡牌
		if card_item.has_method("add_theme_stylebox_override"):
			card_item.add_theme_stylebox_override("panel", style_box)
		
		print("ItemCardDisplayPanel: 为卡牌添加选择高亮 - ", card_item.name)

# 关闭面板
func _close_panel():
	print("ItemCardDisplayPanel: === 开始关闭面板 ===")
	print("ItemCardDisplayPanel: 发射panel_closed信号...")
	panel_closed.emit()
	print("ItemCardDisplayPanel: ✓ panel_closed信号已发射")
	print("ItemCardDisplayPanel: 队列释放面板...")
	queue_free()
	print("ItemCardDisplayPanel: ✓ 面板已队列释放")

# 关闭按钮点击处理
func _on_close_button_pressed():
	_close_panel()

# 背景点击处理
func _on_background_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 点击背景时关闭面板
		_close_panel()

# 处理正常显示模式下的卡片点击
func _on_card_clicked_normal_mode(card_data):
	print("ItemCardDisplayPanel: === 正常模式卡片点击 ===")
	print("ItemCardDisplayPanel: 点击的卡片 - ", card_data.card_name)
	print("ItemCardDisplayPanel: 当前模式 - 正常显示模式")
	print("ItemCardDisplayPanel: 卡片ID - ", card_data.card_id)
	print("ItemCardDisplayPanel: 选择模式状态 - ", is_in_selection_mode)
	
	# 在正常模式下，显示卡片详情
	_show_card_details_popup(card_data)

# 显示卡片详情弹窗
func _show_card_details_popup(card_data: ItemCardData):
	print("ItemCardDisplayPanel: === 显示卡片详情 ===")
	print("ItemCardDisplayPanel: 卡片名称 - ", card_data.card_name)
	print("ItemCardDisplayPanel: 卡片描述 - ", card_data.card_description)
	print("ItemCardDisplayPanel: 卡片属性 - ", card_data.get_formatted_attributes())
	print("ItemCardDisplayPanel: 卡片标签 - ", card_data.get_formatted_tags())
	print("ItemCardDisplayPanel: 卡片等级 - ", card_data.card_level)
	print("ItemCardDisplayPanel: 卡片类型 - ", card_data.card_type)
	
	# 这里可以添加实际的详情弹窗显示逻辑
	# 目前先用日志输出来验证功能正常工作
	print("ItemCardDisplayPanel: ✓ 卡片详情显示完成")

# 切换到角色卡面板
func _on_character_icon_pressed():
	print("ItemCardDisplayPanel: 切换到角色卡面板")
	switch_to_character_panel.emit()

# 切换到物品卡面板
func _on_other_icon_pressed():
	# 当前已经是物品卡面板，不执行切换
	print("ItemCardDisplayPanel: 已经是物品卡面板") 

# 延迟连接卡片信号的方法
func _connect_card_signal_deferred(card_item, original_card_data):
	print("ItemCardDisplayPanel: === 延迟信号连接开始 ===")
	print("ItemCardDisplayPanel: 目标卡片 - ", original_card_data.card_name)
	print("ItemCardDisplayPanel: 卡片实例状态检查:")
	print("  - 实例有效: ", is_instance_valid(card_item))
	print("  - 在场景树中: ", card_item.is_inside_tree() if is_instance_valid(card_item) else false)
	
	if not is_instance_valid(card_item):
		print("ItemCardDisplayPanel: ✗ 卡片实例无效，跳过信号连接")
		return
	
	if not card_item.is_inside_tree():
		print("ItemCardDisplayPanel: ✗ 卡片不在场景树中，跳过信号连接")
		return
	
	# 检查信号是否存在
	print("ItemCardDisplayPanel: 检查card_clicked信号存在性...")
	var has_signal_result = card_item.has_signal("card_clicked")
	print("  - has_signal('card_clicked'): ", has_signal_result)
	
	if has_signal_result:
		print("ItemCardDisplayPanel: ✓ card_clicked信号存在，开始连接")
		
		# 先断开可能存在的正常模式连接
		var connections = card_item.card_clicked.get_connections()
		print("  - 当前连接数量: ", connections.size())
		for conn in connections:
			print("    现有连接: ", conn.callable.get_object(), " -> ", conn.callable.get_method())
			if conn.callable.get_method() == "_on_card_clicked_normal_mode":
				card_item.card_clicked.disconnect(conn.callable)
				print("ItemCardDisplayPanel: 断开正常模式信号连接 - ", original_card_data.card_name)
				break
		
		# 连接选择模式信号
		var connection_result = card_item.card_clicked.connect(_on_card_selected_for_slot.bind(original_card_data))
		if connection_result == OK:
			print("ItemCardDisplayPanel: ✓ 选择模式信号连接成功 - ", original_card_data.card_name)
			print("ItemCardDisplayPanel: 连接详情:")
			print("  - 卡片实例ID: ", card_item.get_instance_id())
			print("  - 绑定的card_data: ", original_card_data.card_name, " (ID:", original_card_data.card_id, ")")
			print("  - 回调方法: _on_card_selected_for_slot")
			
			# 验证信号连接状态
			var connections_after = card_item.card_clicked.get_connections()
			print("  - 连接后连接数量: ", connections_after.size())
			for i in range(connections_after.size()):
				var conn = connections_after[i]
				print("    连接", i+1, ": ", conn.callable.get_object(), " -> ", conn.callable.get_method())
		else:
			print("ItemCardDisplayPanel: ✗ 选择模式信号连接失败 - ", original_card_data.card_name, " 错误码:", connection_result)
			# 尝试重试连接
			_retry_signal_connection(card_item, original_card_data, 1)
	else:
		print("ItemCardDisplayPanel: ✗ card_clicked信号不存在 - ", original_card_data.card_name)
		print("ItemCardDisplayPanel: 可用信号列表:")
		var signal_list = card_item.get_signal_list()
		for signal_info in signal_list:
			print("    - ", signal_info.name)
		
		# 尝试重试连接
		_retry_signal_connection(card_item, original_card_data, 1)
	
	print("ItemCardDisplayPanel: === 延迟信号连接完成 ===")

# 重试信号连接
func _retry_signal_connection(card_item, original_card_data, retry_count: int):
	if retry_count > 3:
		print("ItemCardDisplayPanel: ✗ 信号连接重试次数超限，放弃连接 - ", original_card_data.card_name)
		return
	
	print("ItemCardDisplayPanel: 准备重试信号连接 (", retry_count, "/3) - ", original_card_data.card_name)
	
	# 等待一帧后重试
	await get_tree().process_frame
	
	if not is_instance_valid(card_item) or not card_item.is_inside_tree():
		print("ItemCardDisplayPanel: ✗ 重试时卡片实例无效，停止重试")
		return
	
	if card_item.has_signal("card_clicked"):
		print("ItemCardDisplayPanel: ✓ 重试成功，信号现在存在")
		var connection_result = card_item.card_clicked.connect(_on_card_selected_for_slot.bind(original_card_data))
		if connection_result == OK:
			print("ItemCardDisplayPanel: ✓ 重试连接成功 - ", original_card_data.card_name)
		else:
			print("ItemCardDisplayPanel: ✗ 重试连接失败 - ", original_card_data.card_name)
			_retry_signal_connection(card_item, original_card_data, retry_count + 1)
	else:
		print("ItemCardDisplayPanel: 重试时信号仍不存在，继续重试...")
		_retry_signal_connection(card_item, original_card_data, retry_count + 1) 
