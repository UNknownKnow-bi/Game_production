extends Node

# 预加载卡片展示面板场景
const CardDisplayPanelScene = preload("res://scenes/ui/card_display_panel.tscn")
# 预加载情报卡展示面板场景
const ItemCardDisplayPanelScene = preload("res://scenes/ui/item_card_display_panel.tscn")

# 交互元素引用
@onready var rabbit_icon = $"../RabbitIcon"
@onready var card_side_char = $"../../CardSideLayer/CardSideChar"
@onready var card_side_others = $"../../CardSideLayer/CardSideOthers"
@onready var beer_icon = $"../BeerIcon"
@onready var cup_icon = $"../CupIcon"

# 卡片展示面板引用
var card_display_panel = null
# 情报卡展示面板引用
var item_card_display_panel = null

# 交互状态
var is_rabbit_active = false
var is_cup_active = false
var is_card_char_active = false
var is_card_others_active = false

func _ready():
	# 初始化UI控制器
	print("UI控制器已初始化")

# 处理Rabbit图标交互
func handle_rabbit_interaction():
	is_rabbit_active = !is_rabbit_active
	print("Rabbit状态: ", is_rabbit_active)
	
	# 更新视觉效果
	if is_rabbit_active:
		rabbit_icon.modulate = Color(1.5, 1.5, 1.5, 1.0)
	else:
		rabbit_icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	# 实现交互逻辑，例如显示特定菜单或面板

# 处理Beer图标交互
func handle_beer_interaction():
	print("Beer图标被点击 - 准备进入下一回合")
	
	# 直接推进回合，触发场景切换到weekend
	if TimeManager:
		print("Beer: 调用TimeManager推进回合")
		TimeManager.advance_round()
		print("Beer: 回合已推进，场景即将切换到weekend...")
	else:
		print("Beer: 错误 - TimeManager不存在")

# 处理Cup图标交互
func handle_cup_interaction():
	is_cup_active = !is_cup_active
	print("Cup状态: ", is_cup_active)
	
	# 更新视觉效果
	if is_cup_active:
		cup_icon.modulate = Color(1.5, 1.5, 1.5, 1.0)
	else:
		cup_icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	# 实现交互逻辑，例如显示特定菜单或面板

# 处理Card Side Char交互
func handle_card_side_char_interaction():
	is_card_char_active = !is_card_char_active
	print("Card Side Char状态: ", is_card_char_active)
	
	# 更新视觉效果
	if is_card_char_active:
		card_side_char.modulate = Color(1.3, 1.3, 1.3, 1.0)
		# 显示卡片展示面板
		show_card_display_panel()
	else:
		card_side_char.modulate = Color(1.0, 1.0, 1.0, 1.0)
		# 隐藏卡片展示面板
		hide_card_display_panel()

# 处理Card Side Others交互
func handle_card_side_others_interaction():
	is_card_others_active = !is_card_others_active
	print("Card Side Others状态: ", is_card_others_active)
	
	# 更新视觉效果
	if is_card_others_active:
		card_side_others.modulate = Color(1.3, 1.3, 1.3, 1.0)
		# 显示情报卡展示面板
		show_item_card_display_panel()
	else:
		card_side_others.modulate = Color(1.0, 1.0, 1.0, 1.0)
		# 隐藏情报卡展示面板
		hide_item_card_display_panel()

# 显示卡片展示面板
func show_card_display_panel():
	# 如果面板已存在，直接返回
	if card_display_panel != null and is_instance_valid(card_display_panel):
		return
		
	# 创建卡片展示面板实例
	card_display_panel = CardDisplayPanelScene.instantiate()
	
	# 获取UI层节点
	var ui_layer = get_parent()
	ui_layer.add_child(card_display_panel)
	
	# 连接面板关闭信号
	card_display_panel.panel_closed.connect(_on_card_display_panel_closed)
	# 连接切换信号
	card_display_panel.switch_to_item_panel.connect(_on_switch_to_item_panel)
	
	print("显示卡片展示面板")

# 隐藏卡片展示面板
func hide_card_display_panel():
	if card_display_panel != null and is_instance_valid(card_display_panel):
		# 断开信号连接
		if card_display_panel.panel_closed.is_connected(_on_card_display_panel_closed):
			card_display_panel.panel_closed.disconnect(_on_card_display_panel_closed)
		if card_display_panel.switch_to_item_panel.is_connected(_on_switch_to_item_panel):
			card_display_panel.switch_to_item_panel.disconnect(_on_switch_to_item_panel)
		card_display_panel.close_panel()
		card_display_panel = null
		print("隐藏卡片展示面板")

# 处理卡片展示面板关闭事件
func _on_card_display_panel_closed():
	# 重置状态
	is_card_char_active = false
	card_side_char.modulate = Color(1.0, 1.0, 1.0, 1.0)
	card_display_panel = null
	print("卡片展示面板已关闭")

# 显示情报卡展示面板
func show_item_card_display_panel():
	# 如果面板已存在，直接返回
	if item_card_display_panel != null and is_instance_valid(item_card_display_panel):
		return
		
	# 创建情报卡展示面板实例
	item_card_display_panel = ItemCardDisplayPanelScene.instantiate()
	
	# 获取UI层节点
	var ui_layer = get_parent()
	ui_layer.add_child(item_card_display_panel)
	
	# 连接面板关闭信号
	item_card_display_panel.panel_closed.connect(_on_item_card_display_panel_closed)
	# 连接切换信号
	item_card_display_panel.switch_to_character_panel.connect(_on_switch_to_character_panel)
	
	print("显示情报卡展示面板")

# 隐藏情报卡展示面板
func hide_item_card_display_panel():
	if item_card_display_panel != null and is_instance_valid(item_card_display_panel):
		# 断开信号连接
		if item_card_display_panel.panel_closed.is_connected(_on_item_card_display_panel_closed):
			item_card_display_panel.panel_closed.disconnect(_on_item_card_display_panel_closed)
		if item_card_display_panel.switch_to_character_panel.is_connected(_on_switch_to_character_panel):
			item_card_display_panel.switch_to_character_panel.disconnect(_on_switch_to_character_panel)
		item_card_display_panel.close_panel()
		item_card_display_panel = null
		print("隐藏情报卡展示面板")

# 处理情报卡展示面板关闭事件
func _on_item_card_display_panel_closed():
	# 重置状态
	is_card_others_active = false
	card_side_others.modulate = Color(1.0, 1.0, 1.0, 1.0)
	item_card_display_panel = null
	print("情报卡展示面板已关闭")

# 重置所有交互状态
func reset_all_interactions():
	is_rabbit_active = false
	is_cup_active = false
	is_card_char_active = false
	is_card_others_active = false
	
	# 重置视觉效果
	rabbit_icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
	beer_icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
	cup_icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
	card_side_char.modulate = Color(1.0, 1.0, 1.0, 1.0)
	card_side_others.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	# 关闭卡片展示面板
	hide_card_display_panel()
	# 关闭情报卡展示面板
	hide_item_card_display_panel()
	
	print("已重置所有交互状态")

# 处理切换到物品卡面板信号
func _on_switch_to_item_panel():
	print("UI Controller: 切换到物品卡面板")
	# 隐藏当前角色卡面板
	hide_card_display_panel()
	# 重置角色卡按钮状态
	is_card_char_active = false
	card_side_char.modulate = Color(1.0, 1.0, 1.0, 1.0)
	# 显示物品卡面板
	is_card_others_active = true
	card_side_others.modulate = Color(1.3, 1.3, 1.3, 1.0)
	show_item_card_display_panel()

# 处理切换到角色卡面板信号
func _on_switch_to_character_panel():
	print("UI Controller: 切换到角色卡面板")
	# 隐藏当前物品卡面板
	hide_item_card_display_panel()
	# 重置物品卡按钮状态
	is_card_others_active = false
	card_side_others.modulate = Color(1.0, 1.0, 1.0, 1.0)
	# 显示角色卡面板
	is_card_char_active = true
	card_side_char.modulate = Color(1.3, 1.3, 1.3, 1.0)
	show_card_display_panel() 
