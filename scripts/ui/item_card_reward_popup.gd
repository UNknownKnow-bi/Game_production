class_name ItemCardRewardPopup
extends Control

# 节点引用
@onready var background: ColorRect = $Background
@onready var popup_panel: Panel = $PopupPanel
@onready var title_label: Label = $PopupPanel/VBoxContainer/Title
@onready var card_container: Control = $PopupPanel/VBoxContainer/CardContainer
@onready var card_display: Control = $PopupPanel/VBoxContainer/CardContainer/CardDisplay
@onready var card_name_label: Label = $PopupPanel/VBoxContainer/CardInfo/CardName
@onready var card_attributes_label: Label = $PopupPanel/VBoxContainer/CardInfo/CardAttributes
@onready var close_button: Button = $PopupPanel/VBoxContainer/ButtonContainer/CloseButton

# 当前显示的情报卡实例
var current_card_instance: ItemCardInstanceData = null

# 信号
signal popup_closed()

# 初始化
func _ready():
	print("ItemCardRewardPopup: 初始化")
	
	# 连接按钮信号
	close_button.pressed.connect(_on_close_button_pressed)
	background.gui_input.connect(_on_background_input)
	
	# 设置初始状态为隐藏
	visible = false

# 显示情报卡获得弹窗
func show_card_reward(card_instance: ItemCardInstanceData):
	if not card_instance:
		printerr("ItemCardRewardPopup: 无效的情报卡实例")
		return
	
	current_card_instance = card_instance
	
	print("ItemCardRewardPopup: 显示情报卡获得 - ", card_instance.get_card_name())
	
	# 更新UI信息
	update_card_info()
	
	# 创建并显示情报卡
	create_card_display()
	
	# 显示弹窗
	show_popup()

# 更新卡片信息显示
func update_card_info():
	if not current_card_instance:
		return
	
	# 设置卡片名称
	card_name_label.text = current_card_instance.get_card_name()
	
	# 设置属性信息
	var attributes = current_card_instance.get_attributes()
	var attr_text = ""
	if not attributes.is_empty():
		var attr_parts = []
		var attr_names = {
			"social": "社交",
			"execution": "执行",
			"innovation": "创新", 
			"resistance": "抗压",
			"physical": "体能"
		}
		
		for attr_key in attributes:
			var attr_value = attributes[attr_key]
			var attr_display_name = attr_names.get(attr_key, attr_key)
			attr_parts.append(attr_display_name + "+" + str(attr_value))
		
		attr_text = " ".join(attr_parts)
	else:
		attr_text = "无属性加成"
	
	card_attributes_label.text = attr_text
	
	print("ItemCardRewardPopup: 更新卡片信息 - ", card_name_label.text, " | ", attr_text)

# 创建卡片显示
func create_card_display():
	if not current_card_instance:
		return
	
	# 清除现有的卡片显示
	for child in card_display.get_children():
		child.queue_free()
	
	# 创建ItemCard实例
	var item_card_scene = preload("res://scenes/item_card.tscn")
	var item_card_instance = item_card_scene.instantiate()
	
	# 设置卡片大小和位置
	item_card_instance.custom_minimum_size = Vector2(200, 100)
	item_card_instance.size = Vector2(200, 100)
	
	# 添加到显示容器
	card_display.add_child(item_card_instance)
	
	# 获取原始卡片数据并显示
	var original_card_data = current_card_instance.get_original_card_data()
	if original_card_data:
		item_card_instance.display_card(original_card_data)
		print("ItemCardRewardPopup: 卡片显示创建完成")
	else:
		print("ItemCardRewardPopup: 无法获取原始卡片数据")

# 显示弹窗
func show_popup():
	# 设置初始状态
	visible = true
	modulate = Color(1, 1, 1, 0)
	popup_panel.scale = Vector2(0.8, 0.8)
	
	# 创建动画
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 淡入效果
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.3)
	
	# 缩放效果
	tween.tween_property(popup_panel, "scale", Vector2(1, 1), 0.3)
	tween.tween_method(_update_popup_scale, 0.8, 1.0, 0.3)
	
	print("ItemCardRewardPopup: 弹窗显示动画开始")

# 更新弹窗缩放（用于动画）
func _update_popup_scale(scale_value: float):
	popup_panel.scale = Vector2(scale_value, scale_value)

# 隐藏弹窗
func hide_popup():
	print("ItemCardRewardPopup: 开始隐藏弹窗")
	
	# 创建动画
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 淡出效果
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.2)
	
	# 缩放效果
	tween.tween_property(popup_panel, "scale", Vector2(0.8, 0.8), 0.2)
	
	# 动画完成后隐藏
	tween.tween_callback(func(): 
		visible = false
		popup_closed.emit()
		queue_free()
	).set_delay(0.2)

# 关闭按钮处理
func _on_close_button_pressed():
	print("ItemCardRewardPopup: 关闭按钮被点击")
	hide_popup()

# 背景点击处理
func _on_background_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("ItemCardRewardPopup: 背景被点击")
		hide_popup()

# 处理ESC键关闭
func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		print("ItemCardRewardPopup: ESC键关闭")
		hide_popup()
		get_viewport().set_input_as_handled() 