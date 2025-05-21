extends Node

# 交互元素引用
@onready var rabbit_icon = $"../RabbitIcon"
@onready var card_side_char = $"../../CardSideLayer/CardSideChar"
@onready var card_side_others = $"../../CardSideLayer/CardSideOthers"
@onready var beer_icon = $"../BeerIcon"
@onready var cup_icon = $"../CupIcon"

# 交互状态
var is_rabbit_active = false
var is_beer_active = false
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
	is_beer_active = !is_beer_active
	print("Beer状态: ", is_beer_active)
	
	# 更新视觉效果
	if is_beer_active:
		beer_icon.modulate = Color(1.5, 1.5, 1.5, 1.0)
	else:
		beer_icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	# 实现交互逻辑，例如显示特定菜单或面板

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
	else:
		card_side_char.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	# 实现交互逻辑，例如显示特定面板或菜单

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

# 重置所有交互状态
func reset_all_interactions():
	is_rabbit_active = false
	is_beer_active = false
	is_cup_active = false
	is_card_char_active = false
	is_card_others_active = false
	
	# 重置视觉效果
	rabbit_icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
	beer_icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
	cup_icon.modulate = Color(1.0, 1.0, 1.0, 1.0)
	card_side_char.modulate = Color(1.0, 1.0, 1.0, 1.0)
	card_side_others.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	print("已重置所有交互状态") 