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
	
	# 获取所有卡片数据
	var all_cards = item_card_manager.get_all_cards()
	print("ItemCardDisplayPanel: 获取到卡片数量 - ", all_cards.size())
	
	if all_cards.is_empty():
		print("ItemCardDisplayPanel: 警告 - 没有可显示的卡片数据")
		return
	
	# 清除现有卡片（如果有）
	clear_existing_cards()
	
	# 为每个卡片数据创建显示
	for card_data in all_cards:
		create_and_display_card(card_data)
	
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
	
	print("ItemCardDisplayPanel: ✓ 卡片 ", card_data.card_name, " 显示完成")

# 刷新显示
func refresh_display():
	load_and_display_cards()

# 获取当前显示的卡片数量
func get_displayed_card_count() -> int:
	if not vbox_container:
		return 0
	return vbox_container.get_child_count()

# 关闭面板
func close_panel():
	# 发送关闭信号
	panel_closed.emit()
	# 释放资源
	queue_free()

# 关闭按钮点击处理
func _on_close_button_pressed():
	close_panel()

# 背景点击处理
func _on_background_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 点击背景时关闭面板
		close_panel()

# 卡片点击处理
func _on_card_clicked(card_id):
	print("在情报卡展示面板中点击了卡片：", card_id)
	
	# 获取卡片数据
	var card_data = item_card_manager.get_card_by_id(card_id) if item_card_manager else null
	if not card_data:
		return
	
	# 这里可以添加情报卡详情弹窗逻辑
	print("情报卡详情: ", card_data.card_name, " - ", card_data.card_description)

# 切换到角色卡面板
func _on_character_icon_pressed():
	print("ItemCardDisplayPanel: 切换到角色卡面板")
	switch_to_character_panel.emit()

# 切换到物品卡面板
func _on_other_icon_pressed():
	# 当前已经是物品卡面板，不执行切换
	print("ItemCardDisplayPanel: 已经是物品卡面板") 