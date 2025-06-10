extends Control

signal option_selected(option_id, event_id)
signal popup_closed

@onready var title_label = $PopupPanel/TitleLabel
@onready var content_text = $PopupPanel/ContentText
@onready var event_image = $PopupPanel/EventImage
@onready var accept_button = $PopupPanel/ButtonsContainer/AcceptButton
@onready var reject_button = $PopupPanel/ButtonsContainer/RejectButton
@onready var close_button = $PopupPanel/CloseButton
@onready var attributes_bar = $PopupPanel/AttributesBar

var current_event_id = -1

# 属性映射系统
var attribute_mapping = {
	"social": {"name": "社交", "type": "basic"},
	"resistance": {"name": "抗压", "type": "basic"},
	"innovation": {"name": "创新", "type": "basic"},
	"execution": {"name": "执行", "type": "basic"},
	"physical": {"name": "体魄", "type": "basic"},
	"power": {"name": "权势", "type": "overall"},
	"reputation": {"name": "声望", "type": "overall"},
	"piety": {"name": "虔信", "type": "overall"}
}

func _ready():
	# 连接按钮信号
	accept_button.pressed.connect(_on_accept_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	# 默认隐藏
	visible = false
	
	# 确保弹窗显示在最顶层
	z_index = 1000
	print("事件弹窗z_index设置为: ", z_index)

# 显示事件弹窗
func show_event(event_data: Dictionary):
	current_event_id = event_data.event_id
	
	# 设置标题和内容
	title_label.text = event_data.title
	content_text.text = event_data.description
	
	# 如果有图像，加载并显示
	if event_data.has("image_path") and event_data.image_path != "":
		var texture = load(event_data.image_path)
		if texture:
			event_image.texture = texture
			event_image.visible = true
		else:
			event_image.visible = false
	else:
		event_image.visible = false
	
	# 设置确认按钮文本
	accept_button.text = "确认"
	
	# 强制隐藏拒绝按钮
	reject_button.visible = false
	
	# 设置属性展示
	if event_data.has("global_check"):
		_setup_attributes_display(event_data.global_check)
	else:
		_clear_attributes_display()
	
	# 显示弹窗
	visible = true

# 设置属性展示
func _setup_attributes_display(global_check: Dictionary):
	print("EventPopup: 设置属性展示 - global_check: ", global_check)
	
	# 清空现有显示
	_clear_attributes_display()
	
	# 解析global_check数据
	var attribute_requirements = _parse_global_check(global_check)
	
	if attribute_requirements.is_empty():
		print("EventPopup: 无属性需求，隐藏属性栏")
		attributes_bar.visible = false
		return
	
	# 显示属性栏
	attributes_bar.visible = true
	
	# 创建属性图标区域容器
	var icons_container = HBoxContainer.new()
	icons_container.add_theme_constant_override("separation", 20)
	
	# 为每个属性需求创建图标显示项
	for req in attribute_requirements:
		var attribute_item = _create_attribute_icon_item(req.attribute)
		if attribute_item:
			icons_container.add_child(attribute_item)
			print("EventPopup: 添加属性图标项 - ", req.attribute)
	
	# 创建需求信息汇总区域
	var requirements_summary = _create_requirements_summary(attribute_requirements)
	
	# 添加到主AttributesBar
	attributes_bar.add_child(icons_container)
	attributes_bar.add_child(requirements_summary)

# 解析global_check数据
func _parse_global_check(global_check: Dictionary) -> Array:
	var requirements = []
	
	# 处理新格式
	if global_check.has("required_checks"):
		var checks = global_check["required_checks"]
		if checks is Array:
			for check in checks:
				if check is Dictionary and check.has("attribute") and check.has("threshold"):
					requirements.append({
						"attribute": check.get("attribute", ""),
						"threshold": check.get("threshold", 0),
						"success_required": check.get("success_required", 1)
					})
		return requirements
	
	# 处理旧格式 - 向后兼容
	if global_check.has("check_mode"):
		var check_mode = global_check.get("check_mode", "")
		if check_mode == "single_attribute":
			var attr_check = global_check.get("single_attribute_check", {})
			if attr_check.has("attribute_name") and attr_check.has("threshold"):
				requirements.append({
					"attribute": attr_check.get("attribute_name", ""),
					"threshold": attr_check.get("threshold", 0),
					"success_required": attr_check.get("success_required", 1)
				})
		elif check_mode == "multi_attribute":
			var checks = global_check.get("multi_attribute_check", [])
			for check in checks:
				if check.has("attribute_name") and check.has("threshold"):
					requirements.append({
						"attribute": check.get("attribute_name", ""),
						"threshold": check.get("threshold", 0),
						"success_required": check.get("success_required", 1)
					})
	
	return requirements

# 计算需求信息汇总
func _calculate_requirements_summary(requirements: Array) -> Dictionary:
	var total_threshold = 0
	var total_success_required = 0
	
	# 遍历所有属性需求，累加值
	for req in requirements:
		total_threshold += req.threshold  # 所有threshold相加
		total_success_required += req.success_required  # 所有success_required相加
	
	return {
		"total_threshold": total_threshold,
		"total_success_required": total_success_required
	}

# 创建需求信息汇总显示
func _create_requirements_summary(requirements: Array) -> Control:
	var summary = _calculate_requirements_summary(requirements)
	
	var summary_container = VBoxContainer.new()
	summary_container.add_theme_constant_override("separation", 4)
	summary_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	summary_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# 统一的需求信息标签
	var requirement_label = Label.new()
	requirement_label.text = "检定需要累积 >= %d, 至少成功 >= %d 次" % [summary.total_threshold, summary.total_success_required]
	requirement_label.add_theme_font_size_override("font_size", 20)
	requirement_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2, 1))
	requirement_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	summary_container.add_child(requirement_label)
	return summary_container

# 创建属性图标项显示
func _create_attribute_icon_item(attribute_name: String) -> Control:
	# 验证属性名称
	if not attribute_mapping.has(attribute_name):
		print("EventPopup: 警告 - 未知属性名称: ", attribute_name)
		return null
	
	# 创建属性项容器 - 垂直布局
	var item_container = VBoxContainer.new()
	item_container.add_theme_constant_override("separation", 8)
	
	# 创建属性图标
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var icon_path = _get_attribute_icon_path(attribute_name)
	if FileAccess.file_exists(icon_path):
		icon.texture = load(icon_path)
	else:
		print("EventPopup: 警告 - 属性图标不存在: ", icon_path)
	
	item_container.add_child(icon)
	
	# 属性名称标签 - 居中对齐
	var name_label = Label.new()
	name_label.text = attribute_mapping[attribute_name].name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(0, 0, 0, 1))
	item_container.add_child(name_label)
	
	return item_container

# 获取属性图标路径
func _get_attribute_icon_path(attribute_name: String) -> String:
	return "res://assets/cards/attribute/" + attribute_name + ".png"

# 清空属性展示
func _clear_attributes_display():
	for child in attributes_bar.get_children():
		attributes_bar.remove_child(child)
		child.queue_free()

# 隐藏弹窗
func hide_popup():
	visible = false
	current_event_id = -1

# 按钮回调
func _on_accept_button_pressed():
	option_selected.emit(1, current_event_id)
	hide_popup()

func _on_close_button_pressed():
	popup_closed.emit()
	hide_popup() 
