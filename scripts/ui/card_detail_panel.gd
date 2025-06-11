extends Control

# CardDetailPanel - 卡片详情面板
# 显示所有拥有的特权卡的详细信息

signal panel_closed()
signal draw_card_requested()
signal card_selected(card_type: String, card_id: String, card_data)

@onready var background_image = $BackgroundImage
@onready var main_container = $CenterContainer/MainContainer
@onready var title_label = $CenterContainer/MainContainer/VBoxContainer/HeaderContainer/Title
@onready var cards_container = $CenterContainer/MainContainer/VBoxContainer/ScrollContainer/CardGrid
@onready var close_button = $CenterContainer/MainContainer/VBoxContainer/HeaderContainer/CloseButton
@onready var no_cards_label = $CenterContainer/MainContainer/VBoxContainer/NoCardsLabel
@onready var scroll_container = $CenterContainer/MainContainer/VBoxContainer/ScrollContainer
@onready var draw_button = $CenterContainer/MainContainer/VBoxContainer/BottomContainer/ActionContainer/DrawButton
@onready var card_count_label = $CenterContainer/MainContainer/VBoxContainer/BottomContainer/ActionContainer/CardCountLabel

# 选择模式相关
var is_in_selection_mode: bool = false
var current_slot_data: EventSlotData = null
var allowed_card_types: Array = []

# 移除预加载引用，改为直接创建Label节点
# const CARD_ITEM_SCENE = preload("res://scenes/ui/card_item.tscn")

func _ready():
	# 修复背景图片阻挡点击事件的问题
	if background_image:
		background_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		print("Card Detail Panel: 设置BackgroundImage为忽略鼠标事件")
	
	# 修复容器控件阻挡点击事件的问题
	var center_container = $CenterContainer
	if center_container:
		center_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		print("Card Detail Panel: 设置CenterContainer为忽略鼠标事件")
	
	if main_container:
		main_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		print("Card Detail Panel: 设置MainContainer为忽略鼠标事件")
	
	var vbox_container = $CenterContainer/MainContainer/VBoxContainer
	if vbox_container:
		vbox_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		print("Card Detail Panel: 设置VBoxContainer为忽略鼠标事件")
	
	if scroll_container:
		scroll_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		print("Card Detail Panel: 设置ScrollContainer为忽略鼠标事件")
	
	if cards_container:
		cards_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		print("Card Detail Panel: 设置CardGrid为忽略鼠标事件")
	
	# 连接按钮信号
	close_button.pressed.connect(_on_close_button_pressed)
	draw_button.pressed.connect(_on_draw_button_pressed)
	
	# 连接PrivilegeCardManager的cards_updated信号以自动刷新显示
	if PrivilegeCardManager:
		PrivilegeCardManager.cards_updated.connect(update_cards_display)
		print("Card Detail Panel: 已连接PrivilegeCardManager.cards_updated信号")
	else:
		print("Card Detail Panel: 警告 - PrivilegeCardManager不存在，无法连接信号")
	
	# 隐藏面板
	hide()

# 显示详情面板
func show_panel():
	show()
	update_cards_display()
	update_action_controls()
	
	# 确保面板在其父节点的顶层渲染
	if get_parent():
		get_parent().move_child(self, get_parent().get_child_count() - 1)
		print("Card Detail Panel: 已移动到父节点的最上层位置")
		print("Card Detail Panel: 父节点子节点总数: ", get_parent().get_child_count())
		print("Card Detail Panel: 当前在父节点中的索引: ", get_index())
	else:
		print("Card Detail Panel: 警告 - 未找到父节点，无法移动到顶层")
	
	print("Card Detail Panel: 显示卡片详情面板")

# 隐藏详情面板
func hide_panel():
	hide()
	print("Card Detail Panel: 隐藏卡片详情面板")
	panel_closed.emit()

# 刷新卡片显示
func update_cards_display():
	# 添加null检查
	if not cards_container:
		print("Card Detail Panel: 错误 - cards_container为null")
		return
	
	print("Card Detail Panel: cards_container找到，路径正确")
	
	# 清空现有内容
	for child in cards_container.get_children():
		child.queue_free()
	
	# 检查PrivilegeCardManager是否存在
	if not PrivilegeCardManager:
		print("Card Detail Panel: 错误 - PrivilegeCardManager不存在")
		show_no_cards()
		return
	
	# 获取所有特权卡（不仅仅是即将过期的）
	var all_cards = PrivilegeCardManager.get_all_cards()
	print("Card Detail Panel: 获取到 %d 张卡片" % all_cards.size())
	
	if all_cards.is_empty():
		show_no_cards()
	else:
		show_cards(all_cards)

# 显示无卡片状态
func show_no_cards():
	if scroll_container:
		scroll_container.visible = false
	if no_cards_label:
		no_cards_label.visible = true
	print("Card Detail Panel: 显示无卡片状态")

# 显示卡片列表
func show_cards(cards: Array):
	if scroll_container:
		scroll_container.visible = true
	if no_cards_label:
		no_cards_label.visible = false
	
	for card in cards:
		var card_item = create_card_item(card)
		cards_container.add_child(card_item)
	
	print("Card Detail Panel: 显示 %d 张卡片" % cards.size())

# 创建卡片项目
func create_card_item(card_data):
	# 创建卡片显示项目
	var card_item = Control.new()
	card_item.custom_minimum_size = Vector2(260, 400)
	
	# 添加背景
	var background = ColorRect.new()
	background.color = Color(0.2, 0.2, 0.2, 0.8)
	background.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	background.size_flags_vertical = Control.SIZE_EXPAND_FILL
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_item.add_child(background)
	
	# 创建垂直布局容器
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_item.add_child(vbox)
	
	# 添加卡片图片
	var card_image = TextureRect.new()
	card_image.custom_minimum_size = Vector2(260, 320)
	card_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_image.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	card_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(card_image)
	
	# 加载卡片图片
	if card_data and card_data.texture_path != "":
		print("CardDetailPanel: 尝试加载图片 - ", card_data.texture_path)
		if FileAccess.file_exists(card_data.texture_path):
			var texture = load(card_data.texture_path)
			if texture:
				card_image.texture = texture
				print("CardDetailPanel: ✓ 图片加载成功")
			else:
				print("CardDetailPanel: ⚠ 图片文件无法加载为纹理")
		else:
			print("CardDetailPanel: ⚠ 图片文件不存在: ", card_data.texture_path)
	else:
		print("CardDetailPanel: ⚠ 卡片数据缺少texture_path")
	
	# 添加卡片名称标签
	var label = Label.new()
	label.text = card_data.get_display_name() if card_data.has_method("get_display_name") else "未知卡片"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(label)
	
	# 添加点击检测
	var button = Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_item.add_child(button)
	
	# 调试Button布局
	print("CardDetailPanel: Button创建完成，大小: ", button.size, " 位置: ", button.position)
	
	# 添加card_clicked信号
	card_item.add_user_signal("card_clicked")
	button.pressed.connect(func(): 
		print("CardDetailPanel: Button被点击，发射card_clicked信号")
		card_item.emit_signal("card_clicked")
	)
	
	return card_item

# 获取卡片图片路径
func get_card_texture_path(card_type: String) -> String:
	match card_type:
		"挥霍":
			return "res://assets/cards/挥霍卡.png"
		"装X":
			return "res://assets/cards/装X卡.png"
		"陷害":
			return "res://assets/cards/陷害卡.png"
		"秘会":
			return "res://assets/cards/秘会卡.png"
		_:
			print("Card Detail Panel: 未知卡片类型 ", card_type)
			return ""

# 关闭按钮处理
func _on_close_button_pressed():
	print("Card Detail Panel: 点击关闭按钮")
	hide_panel()

# 更新操作控件
func update_action_controls():
	if not PrivilegeCardManager:
		return
	
	var card_count = PrivilegeCardManager.get_card_count()
	var can_add = PrivilegeCardManager.can_add_card()
	
	# 更新卡片数量显示
	if card_count_label:
		card_count_label.text = str(card_count) + "/28"
	
	# 更新抽卡按钮状态
	if draw_button:
		draw_button.disabled = not can_add

# 抽卡按钮点击处理
func _on_draw_button_pressed():
	print("Card Detail Panel: 点击抽取特权卡")
	draw_card_requested.emit()

# 进入选择模式
func enter_selection_mode(slot_data: EventSlotData, allowed_types: Array):
	print("CardDetailPanel: 进入选择模式")
	is_in_selection_mode = true
	current_slot_data = slot_data
	allowed_card_types = allowed_types
	
	# 刷新显示以突出可选择的卡片
	_refresh_cards_for_selection_mode()

# 退出选择模式
func exit_selection_mode():
	print("CardDetailPanel: 退出选择模式")
	is_in_selection_mode = false
	current_slot_data = null
	allowed_card_types.clear()
	
	# 恢复正常显示
	update_cards_display()

# 刷新卡片显示以适应选择模式
func _refresh_cards_for_selection_mode():
	if not is_in_selection_mode:
		return
	
	print("CardDetailPanel: 刷新选择模式显示, 允许类型: ", allowed_card_types)
	
	# 获取所有特权卡
	var privilege_cards = []
	if PrivilegeCardManager:
		privilege_cards = PrivilegeCardManager.get_all_cards()
	
	# 清空现有卡片显示
	for child in cards_container.get_children():
		cards_container.remove_child(child)
		child.queue_free()
	
	# 只显示符合允许类型的卡片
	if "特权卡" in allowed_card_types:
		for card in privilege_cards:
			# 检查特定卡牌要求
			if _is_card_allowed(card):
				var card_item = create_card_item(card)
				cards_container.add_child(card_item)
				
				# 连接选择信号而非详情信号 - 使用正确的用户自定义信号连接方式
				if card_item.has_signal("card_clicked"):
					card_item.connect("card_clicked", _on_card_selected_for_slot.bind(card))
				
				# 添加视觉提示表明可选择
				_add_selection_visual_hint(card_item)

# 检查卡片是否被允许（基于特定卡牌要求）
func _is_card_allowed(card_data) -> bool:
	if not current_slot_data:
		return true
	
	var specific_requirements = current_slot_data.get_specific_card_requirements()
	if not specific_requirements.has("特权卡"):
		return true
	
	var required_cards = specific_requirements["特权卡"]
	if required_cards.is_empty():
		return true
	
	# 检查卡片类型是否在要求列表中
	return card_data.card_type in required_cards

# 处理卡片选择（选择模式）
func _on_card_selected_for_slot(card_data):
	if not is_in_selection_mode:
		return
	
	print("CardDetailPanel: 选择模式下卡片被点击: ", card_data.get_display_name())
	
	# 发射选择信号
	card_selected.emit("特权卡", card_data.card_id, card_data)
	
	# 关闭面板
	_close_panel()

# 添加选择模式的视觉提示
func _add_selection_visual_hint(card_item):
	# 可以添加边框高亮、选择图标等视觉效果
	# 这里简单地修改样式表或添加标识
	pass

# 关闭面板
func _close_panel():
	print("CardDetailPanel: 关闭面板")
	panel_closed.emit()
	queue_free()
 
