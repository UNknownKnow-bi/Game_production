extends Node

# 预加载卡片展示面板场景
const CardDisplayPanelScene = preload("res://scenes/ui/card_display_panel.tscn")

# 交互元素引用
@onready var rabbit_icon = $"../RabbitIcon"
@onready var card_side_char = $"../../CardSideLayer/CardSideChar"
@onready var card_side_others = $"../../CardSideLayer/CardSideOthers"
@onready var beer_icon = $"../BeerIcon"
@onready var cup_icon = $"../CupIcon"

# 卡片展示面板引用
var card_display_panel = null

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
	else:
		card_side_others.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	# 实现交互逻辑，例如显示特定面板或菜单

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
	
	print("显示卡片展示面板")

# 隐藏卡片展示面板
func hide_card_display_panel():
	if card_display_panel != null and is_instance_valid(card_display_panel):
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
	
	print("已重置所有交互状态") 
