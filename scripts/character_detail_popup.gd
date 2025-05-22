extends Control

signal popup_closed

# 节点引用
@onready var card_instance = $DetailPanel/LeftSection/CharacterCard
@onready var close_button = $DetailPanel/CloseButton
@onready var attributes_container = $DetailPanel/RightSection/AttributesContainer
@onready var description_text = $DetailPanel/RightSection/DescriptionPanel/DescriptionText
@onready var tags_container = $DetailPanel/RightSection/TagsContainer

# 字体资源
var custom_font

# 当前显示的卡片数据
var current_card_data: CharacterCardData = null

# 属性标签和进度条映射
var attribute_bars = {}
var attribute_labels = {}

# 标签节点列表
var tag_nodes = []

func _ready():
	# 预加载字体资源
	custom_font = load("res://assets/font/LEEEAFHEI-REGULAR.TTF")
	
	# 连接信号
	close_button.pressed.connect(_on_close_button_pressed)
	
	# 设置背景可点击关闭
	$Background.gui_input.connect(_on_background_input)
	
	# 初始化为隐藏状态
	visible = false
	
	# 确保弹窗显示在最顶层
	ensure_top_layer()

# 确保弹窗显示在最顶层
func ensure_top_layer():
	# 如果弹窗是CanvasLayer的子节点，不需要额外设置
	var parent = get_parent()
	if parent is CanvasLayer:
		return
		
	# 否则，设置一个很高的z_index
	z_index = 1000
	
	# 检查是否在场景树中
	if not is_inside_tree():
		# 如果不在场景树中，等待进入场景树后再次尝试
		call_deferred("ensure_top_layer")

# 显示角色详情
func show_character_detail(card_data: CharacterCardData):
	current_card_data = card_data
	
	# 设置卡片显示
	card_instance.set_card_data(card_data)
	
	# 显示角色描述
	description_text.text = card_data.character_description
	description_text.add_theme_font_override("normal_font", custom_font)
	description_text.add_theme_font_size_override("normal_font_size", 23)  # 假设当前大小是 20，增加 3px
	
	# 显示属性
	_update_attributes_display()
	
	# 显示标签
	_update_tags_display()
	
	# 显示弹窗
	visible = true
	
	# 再次确保显示在最顶层
	ensure_top_layer()

# 更新属性显示
func _update_attributes_display():
	# 清除现有属性显示
	for child in attributes_container.get_children():
		attributes_container.remove_child(child)
		child.queue_free()
	
	attribute_bars.clear()
	attribute_labels.clear()
	
	# 获取属性列表
	var attributes_list = current_card_data.get_attributes_list()
	
	# 创建属性显示
	for attribute_data in attributes_list:
		var attribute_name = attribute_data.name
		var attribute_value = attribute_data.value
		
		# 创建属性行容器
		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_theme_constant_override("separation", 3)  # 减少间距，原来未设置，默认为 4
		
		# 创建属性名称标签
		var name_label = Label.new()
		name_label.text = _format_attribute_name(attribute_name)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.size_flags_stretch_ratio = 0.2  # 修改比例，原来为 0.4
		name_label.add_theme_font_override("font", custom_font)
		name_label.add_theme_font_size_override("font_size", 23)  # 设置合适的字体大小，后续确认当前大小并+3px
		hbox.add_child(name_label)
		
		# 创建属性值进度条
		var progress_bar = ProgressBar.new()
		progress_bar.max_value = 10
		progress_bar.value = attribute_value
		progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress_bar.size_flags_stretch_ratio = 0.6
		hbox.add_child(progress_bar)
		
		# 创建属性值标签
		var value_label = Label.new()
		value_label.text = str(int(attribute_value))
		value_label.size_flags_horizontal = Control.SIZE_SHRINK_END
		value_label.add_theme_font_override("font", custom_font)
		value_label.add_theme_font_size_override("font_size", 23)  # 设置合适的字体大小，后续确认当前大小并+3px
		hbox.add_child(value_label)
		
		# 添加到容器
		attributes_container.add_child(hbox)
		
		# 保存引用
		attribute_bars[attribute_name] = progress_bar
		attribute_labels[attribute_name] = value_label

# 更新标签显示
func _update_tags_display():
	# 清除现有标签
	for child in tags_container.get_children():
		tags_container.remove_child(child)
		child.queue_free()
	
	tag_nodes.clear()
	
	# 添加新标签
	if current_card_data.tags.is_empty():
		var empty_label = Label.new()
		empty_label.text = "无标签"
		tags_container.add_child(empty_label)
		return
	
	# 创建标签流布局
	var flow_container = HFlowContainer.new()
	flow_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tags_container.add_child(flow_container)
	
	# 添加标签按钮
	for tag in current_card_data.tags:
		var tag_button = Button.new()
		tag_button.text = tag
		tag_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
		tag_button.disabled = true
		
		flow_container.add_child(tag_button)
		tag_nodes.append(tag_button)

# 格式化属性名称（首字母大写，添加本地化）
func _format_attribute_name(attribute_name: String) -> String:
	var attribute_map = {
		"social": "社交能力",
		"resistance": "抗压能力",
		"innovation": "创新能力",
		"execution": "执行能力",
		"physical": "身体素质"
	}
	
	if attribute_map.has(attribute_name):
		return attribute_map[attribute_name]
	
	# 回退处理：首字母大写
	if attribute_name.length() > 0:
		return attribute_name.substr(0, 1).to_upper() + attribute_name.substr(1)
	
	return attribute_name

# 关闭弹窗
func close_popup():
	visible = false
	current_card_data = null
	popup_closed.emit()

# 关闭按钮点击处理
func _on_close_button_pressed():
	close_popup()

# 背景点击处理
func _on_background_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_popup() 
