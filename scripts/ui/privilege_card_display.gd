extends Control

# PrivilegeCardDisplay - 特权卡显示组件
# 显示最快到期的特权卡和相关操作

signal card_detail_requested()
signal force_draw_requested()

@onready var card_container = $VBoxContainer/CardContainer
@onready var card_button = $VBoxContainer/CardContainer/CardButton
@onready var card_image = $VBoxContainer/CardContainer/CardButton/CardImage
@onready var status_label = $VBoxContainer/CardContainer/StatusLabel

func _ready():
	# 连接PrivilegeCardManager信号
	if PrivilegeCardManager:
		PrivilegeCardManager.cards_updated.connect(_on_cards_updated)
	
	# 初始化显示
	update_display()
	
	print("Privilege Card Display: 特权卡显示组件已初始化")

# 更新显示内容
func update_display():
	if not PrivilegeCardManager:
		return
	
	var soonest_card = PrivilegeCardManager.get_soonest_expiring_card()
	
	# 更新卡片显示
	if soonest_card:
		show_card(soonest_card)
	else:
		show_no_card()

# 显示特权卡
func show_card(card: PrivilegeCard):
	if card_container:
		card_container.visible = true
	
	# 加载卡片图片
	if card_image and card.texture_path != "":
		var texture = load(card.texture_path)
		if texture:
			card_image.texture = texture
	
	# 更新状态标签
	if status_label:
		status_label.text = card.get_status_text()
		
		# 根据剩余回合数设置颜色
		if card.is_expiring_soon():
			status_label.modulate = Color.RED
		else:
			status_label.modulate = Color.WHITE

# 显示无卡片状态
func show_no_card():
	if card_container:
		card_container.visible = false
	# 发出强制抽卡信号
	force_draw_requested.emit()
	print("Privilege Card Display: 无卡片，请求强制抽卡")

# 卡片按钮点击处理
func _on_card_button_pressed():
	print("Privilege Card Display: 点击查看卡片详情")
	card_detail_requested.emit()

# 卡片更新信号处理
func _on_cards_updated():
	print("Privilege Card Display: 卡片数据已更新")
	update_display()