extends Control

# 预加载角色卡片场景
const CharacterCardScene = preload("res://scenes/character_card.tscn")
const CharacterDetailPopupScene = preload("res://scenes/character_detail_popup.tscn")

# 卡片管理器引用
var card_manager

# 节点引用
@onready var card_grid = $CardScrollContainer/CardGridContainer
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

func _ready():
	# 设置初始状态
	card_manager = get_node("/root/CharacterCardManager")
	
	# 连接信号
	close_button.pressed.connect(_on_close_button_pressed)
	character_icon_button.pressed.connect(_on_character_icon_pressed)
	other_icon_button.pressed.connect(_on_other_icon_pressed)
	
	# 设置按钮状态（当前面板是角色卡面板）
	character_icon_button.disabled = true
	character_icon_button.modulate = Color(1.0, 1.0, 1.0, 0.5)  # 半透明表示当前面板
	other_icon_button.disabled = false
	other_icon_button.modulate = Color.WHITE
	
	# 加载卡片
	load_cards()
	
	# 设置背景可点击关闭
	$PanelBackground.gui_input.connect(_on_background_input)

# 加载角色卡片
func load_cards():
	# 清空现有卡片
	for child in card_grid.get_children():
		card_grid.remove_child(child)
		child.queue_free()
	
	# 从卡片管理器获取所有卡片
	var all_cards = card_manager.get_all_cards()
	
	# 创建并添加卡片
	for card_data in all_cards:
		var card_instance = CharacterCardScene.instantiate()
		card_grid.add_child(card_instance)
		
		# 设置卡片数据
		card_instance.set_card_data(card_data)
		
		# 连接卡片点击信号
		card_instance.card_clicked.connect(_on_card_clicked.bind(card_data.card_id))
	
	print("已加载 %d 个角色卡到展示面板" % all_cards.size())

# 进入选择模式
func enter_selection_mode(slot_data: EventSlotData, allowed_types: Array):
	print("CardDisplayPanel: 进入选择模式")
	is_in_selection_mode = true
	current_slot_data = slot_data
	allowed_card_types = allowed_types
	
	# 刷新显示以突出可选择的卡片
	_refresh_cards_for_selection_mode()

# 退出选择模式
func exit_selection_mode():
	print("CardDisplayPanel: 退出选择模式")
	is_in_selection_mode = false
	current_slot_data = null
	allowed_card_types.clear()
	
	# 恢复正常显示
	load_cards()

# 刷新卡片显示以适应选择模式
func _refresh_cards_for_selection_mode():
	if not is_in_selection_mode:
		return
	
	print("CardDisplayPanel: 刷新选择模式显示, 允许类型: ", allowed_card_types)
	
	# 获取所有角色卡
	var character_cards = CharacterCardManager.get_all_cards() if CharacterCardManager else []
	
	# 清空现有卡片显示
	for child in card_grid.get_children():
		card_grid.remove_child(child)
		child.queue_free()
	
	# 只显示符合允许类型的卡片
	if "角色卡" in allowed_card_types:
		for card in character_cards:
			var card_item = CharacterCardScene.instantiate()
			card_grid.add_child(card_item)
			card_item.set_card_data(card)
			
			# 检查卡牌是否被占用并标记忙碌状态
			_check_and_mark_busy_card(card_item, "角色卡", card.card_id)
			
			# 连接选择信号而非详情信号
			if card_item.has_signal("card_clicked"):
				card_item.card_clicked.connect(_on_card_selected_for_slot.bind(card))
			
			# 添加视觉提示表明可选择
			_add_selection_visual_hint(card_item)

# 检查并标记忙碌状态的卡牌
func _check_and_mark_busy_card(card_item, card_type: String, card_id: String):
	var global_usage_manager = get_node_or_null("/root/GlobalCardUsageManager")
	if not global_usage_manager:
		return
	
	if global_usage_manager.is_card_used(card_type, card_id):
		var usage_data = global_usage_manager.get_card_usage(card_type, card_id)
		print("CardDisplayPanel: 卡牌忙碌中 - ", card_type, "[", card_id, "] 在事件", usage_data.event_id)
		
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

# 处理卡片选择（选择模式）
func _on_card_selected_for_slot(card_data):
	if not is_in_selection_mode:
		return
	
	# 检查卡牌是否被占用
	var global_usage_manager = get_node_or_null("/root/GlobalCardUsageManager")
	if global_usage_manager and global_usage_manager.is_card_used("角色卡", card_data.card_id):
		var usage_data = global_usage_manager.get_card_usage("角色卡", card_data.card_id)
		print("CardDisplayPanel: 尝试选择忙碌中的卡牌 - ", card_data.card_id, " 在事件", usage_data.event_id)
		
		# 显示卡牌忙碌提示
		_show_busy_card_warning(card_data.card_id, usage_data.event_id)
		return
	
	print("CardDisplayPanel: 选择模式下卡片被点击: ", card_data.card_id)
	
	# 发射选择信号
	card_selected.emit("角色卡", card_data.card_id, card_data)
	
	# 关闭面板
	_close_panel()

# 显示卡牌忙碌警告
func _show_busy_card_warning(card_id: String, event_id: int):
	print("CardDisplayPanel: 显示卡牌忙碌警告 - ", card_id, " 在事件", event_id)
	# 这里可以显示一个简单的提示，或者发射信号给父级处理
	# 目前只打印日志，实际项目中可以添加UI提示

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
		
		print("CardDisplayPanel: 为卡牌添加选择高亮 - ", card_item.name)

# 关闭面板
func _close_panel():
	print("CardDisplayPanel: 关闭面板")
	panel_closed.emit()
	queue_free()

# 关闭按钮点击处理
func _on_close_button_pressed():
	_close_panel()

# 背景点击处理
func _on_background_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 点击背景时关闭面板
		_close_panel()

# 卡片点击处理
func _on_card_clicked(card_id):
	print("在展示面板中点击了卡片：", card_id)
	
	# 获取卡片数据
	var card_data = card_manager.get_card_by_id(card_id)
	if not card_data:
		return
	
	# 创建详情弹窗
	var popup = CharacterDetailPopupScene.instantiate()
	
	# 查找UILayer并添加弹窗
	var ui_layer = _find_ui_layer()
	if ui_layer:
		ui_layer.add_child(popup)
	else:
		# 回退方案：添加到根节点并提高z_index
		get_tree().root.add_child(popup)
		popup.z_index = 1000  # 设置很高的z_index确保在最上层
		print("警告：未找到UILayer，添加到根节点")
	
	# 连接弹窗关闭信号
	popup.popup_closed.connect(_on_detail_popup_closed.bind(popup))
	
	# 显示角色详情
	popup.show_character_detail(card_data)

# 查找UILayer节点
func _find_ui_layer():
	# 方法1：尝试按名称查找
	var ui_layer = get_tree().root.find_child("UILayer", true, false)
	if ui_layer:
		return ui_layer
		
	# 方法2：尝试按类型查找第一个CanvasLayer
	var canvas_layers = []
	
	# 从根节点开始搜索所有CanvasLayer
	var root = get_tree().root
	for child in root.get_children():
		if child is CanvasLayer:
			canvas_layers.append(child)
		_find_canvas_layers_recursive(child, canvas_layers)
	
	# 按layer属性排序，选择layer值最大的
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

# 详情弹窗关闭处理
func _on_detail_popup_closed(popup):
	# 移除弹窗
	if popup and is_instance_valid(popup):
		popup.queue_free()

# 角色图标按钮点击处理
func _on_character_icon_pressed():
	# 当前已经是角色卡面板，不执行切换
	print("CardDisplayPanel: 已经是角色卡面板")

# 其他图标按钮点击处理
func _on_other_icon_pressed():
	# 切换到物品卡面板
	print("CardDisplayPanel: 切换到物品卡面板")
	switch_to_item_panel.emit() 
