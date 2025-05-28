extends Control

# CardDetailPanel - 卡片详情面板
# 显示所有拥有的特权卡的详细信息

signal panel_closed()
signal draw_card_requested()

@onready var background = $Background
@onready var title_label = $CenterContainer/PanelContainer/VBoxContainer/HeaderContainer/Title
@onready var cards_container = $CenterContainer/PanelContainer/VBoxContainer/ScrollContainer/CardGrid
@onready var close_button = $CenterContainer/PanelContainer/VBoxContainer/HeaderContainer/CloseButton
@onready var no_cards_label = $CenterContainer/PanelContainer/VBoxContainer/NoCardsLabel
@onready var scroll_container = $CenterContainer/PanelContainer/VBoxContainer/ScrollContainer
@onready var draw_button = $CenterContainer/PanelContainer/VBoxContainer/BottomContainer/ActionContainer/DrawButton
@onready var card_count_label = $CenterContainer/PanelContainer/VBoxContainer/BottomContainer/ActionContainer/CardCountLabel

# 移除预加载引用，改为直接创建Label节点
# const CARD_ITEM_SCENE = preload("res://scenes/ui/card_item.tscn")

func _ready():
	hide()
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)

# 显示详情面板
func show_panel():
	show()
	update_cards_display()
	update_action_controls()
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

# 创建单个卡片显示项
func create_card_item(card_data):
	# 创建VBoxContainer作为卡片容器
	var card_container = VBoxContainer.new()
	card_container.custom_minimum_size = Vector2(140, 190)
	card_container.add_theme_constant_override("separation", 5)
	
	# 创建TextureRect显示卡片图片
	var card_image = TextureRect.new()
	card_image.custom_minimum_size = Vector2(120, 150)
	card_image.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	card_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# 加载对应的卡片图片
	var texture_path = get_card_texture_path(card_data.card_type)
	if texture_path != "":
		var texture = load(texture_path)
		if texture:
			card_image.texture = texture
		else:
			print("Card Detail Panel: 无法加载图片 ", texture_path)
	
	# 创建Label显示倒计时文字
	var countdown_label = Label.new()
	countdown_label.text = "剩余 %d 回合" % card_data.remaining_rounds
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.modulate = Color(0.67, 0.23, 0.23, 1.0)  # #ab3b3b
	countdown_label.add_theme_font_size_override("font_size", 14)
	
	# 将图片和文字添加到容器
	card_container.add_child(card_image)
	card_container.add_child(countdown_label)
	
	return card_container

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
		draw_button.text = "抽取特权卡" if can_add else "已达上限"

# 抽卡按钮点击处理
func _on_draw_button_pressed():
	print("Card Detail Panel: 点击抽取特权卡")
	draw_card_requested.emit()
