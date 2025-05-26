extends Control

# 卡片管理器引用
@onready var card_manager = get_node("/root/CharacterCardManager")

# 卡片场景
const CharacterCardScene = preload("res://scenes/character_card.tscn")
const CharacterDetailPopupScene = preload("res://scenes/character_detail_popup.tscn")

@onready var grid_container = $ScrollContainer/GridContainer

func _ready():
	print("使用自动加载的CharacterCardManager")
	
	# 等待卡片数据加载完成
	await get_tree().process_frame
	
	# 创建所有角色卡
	create_all_cards()

# 创建所有角色卡
func create_all_cards():
	var all_cards = card_manager.get_all_cards()
	
	for card_data in all_cards:
		var card_instance = CharacterCardScene.instantiate()
		grid_container.add_child(card_instance)
		
		# 设置卡片数据
		card_instance.set_card_data(card_data)
		
		# 连接点击信号
		card_instance.card_clicked.connect(_on_card_clicked.bind(card_data.card_id))
		
	print("已创建 %d 个角色卡" % all_cards.size())

# 卡片点击处理
func _on_card_clicked(card_id: String):
	print("点击了角色卡：", card_id)
	
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
		# 回退方案：添加到当前节点并提高z_index
		add_child(popup)
		popup.z_index = 1000  # 设置很高的z_index确保在最上层
		print("警告：未找到UILayer，添加到当前节点")
	
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
