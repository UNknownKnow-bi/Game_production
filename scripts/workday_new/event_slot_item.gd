extends Control

# EventSlotItem - 单个卡槽项目
# 显示卡槽信息，处理点击交互，管理卡牌预览

signal slot_clicked(slot_data: EventSlotData)
signal slot_card_changed(slot_data: EventSlotData)

# 预加载CharacterCard场景
const CharacterCardScene = preload("res://scenes/character_card.tscn")

# 节点引用
@onready var slot_button = $SlotButton
@onready var description_label = $ContentContainer/LeftSection/SlotDescriptionLabel
@onready var allowed_types_label = $ContentContainer/LeftSection/AllowedTypesLabel
@onready var status_label = $ContentContainer/LeftSection/StatusLabel
@onready var empty_slot_icon = $ContentContainer/RightSection/CardPreview/EmptySlotIcon
@onready var card_image = $ContentContainer/RightSection/CardPreview/CardImage
@onready var character_card_container = $ContentContainer/RightSection/CardPreview/CharacterCardContainer
@onready var remove_button = $ContentContainer/RightSection/CardPreview/RemoveButton
@onready var highlight_border = $HighlightBorder
@onready var coin_amount_label: Label

# 数据
var slot_data: EventSlotData
var is_highlighted: bool = false
var is_disabled: bool = false

# CharacterCard实例管理
var character_card_instance = null

func _ready():
	# 连接信号
	slot_button.pressed.connect(_on_slot_button_pressed)
	remove_button.pressed.connect(_on_remove_button_pressed)
	slot_button.mouse_entered.connect(_on_slot_button_mouse_entered)
	slot_button.mouse_exited.connect(_on_slot_button_mouse_exited)
	
	# 禁用按钮焦点边框
	slot_button.focus_mode = Control.FOCUS_NONE
	remove_button.focus_mode = Control.FOCUS_NONE
	
	print("EventSlotItem: 卡槽项目已初始化")

# 设置卡槽数据
func setup_slot(data: EventSlotData):
	slot_data = data
	update_display()

# 更新显示
func update_display():
	if not slot_data:
		return
	
	# 更新描述
	description_label.text = slot_data.slot_description
	
	# 更新允许的卡牌类型
	var allowed_types = slot_data.get_allowed_card_types()
	var types_text = "允许: " + ", ".join(allowed_types)
	allowed_types_label.text = types_text
	
	# 更新状态和卡牌预览
	update_card_status()
	
	# 更新状态标签颜色
	update_status_color()

# 更新卡牌状态显示
func update_card_status():
	if not slot_data:
		return
	
	if slot_data.has_card_placed():
		# 有卡牌放置
		status_label.text = "状态: 已放置 " + slot_data.placed_card_type
		
		# 隐藏空槽图标
		empty_slot_icon.visible = false
		remove_button.visible = true
		
		var card_type = slot_data.placed_card_type
		var card_id = slot_data.placed_card_id
		
		# 根据卡牌类型选择显示方式
		if card_type == "角色卡":
			# 显示完整的CharacterCard
			card_image.visible = false
			character_card_container.visible = true
			if coin_amount_label:
				coin_amount_label.visible = false
			
			# 获取角色卡数据并加载
			var character_data = get_character_card_data(card_id)
			if character_data:
				load_character_card(character_data)
			else:
				print("EventSlotItem: 未找到角色卡数据 - ", card_id)
		elif card_type == "金币卡":
			# 显示金币卡专用界面
			character_card_container.visible = false
			card_image.visible = true
			load_card_image()
			
			# 创建或更新金币数量标签
			create_coin_amount_label()
			update_coin_amount_display()
		else:
			# 显示普通卡牌图片
			character_card_container.visible = false
			card_image.visible = true
			if coin_amount_label:
				coin_amount_label.visible = false
			load_card_image()
	else:
		# 无卡牌放置
		var status_text = "状态: 空"
		if slot_data.required_for_completion:
			status_text += " (必需)"
		status_label.text = status_text
		
		# 显示空槽图标，隐藏所有卡牌显示
		empty_slot_icon.visible = true
		card_image.visible = false
		character_card_container.visible = false
		remove_button.visible = false
		if coin_amount_label:
			coin_amount_label.visible = false
		
		# 清理CharacterCard实例
		destroy_character_card_instance()

# 加载卡牌图片
func load_card_image():
	if not slot_data or not slot_data.has_card_placed():
		return
	
	var card_type = slot_data.placed_card_type
	var card_id = slot_data.placed_card_id
	
	# 根据卡牌类型和ID加载相应的图片
	var image_path = get_card_image_path(card_type, card_id)
	if image_path and FileAccess.file_exists(image_path):
		var texture = load(image_path)
		if texture:
			card_image.texture = texture
			print("EventSlotItem: 加载卡牌图片 ", image_path)
		else:
			print("EventSlotItem: 无法加载卡牌图片 ", image_path)
	else:
		# 使用默认图片或显示卡牌类型
		card_image.texture = null
		print("EventSlotItem: 卡牌图片不存在: ", image_path)

# 获取卡牌图片路径
func get_card_image_path(card_type: String, card_id: String) -> String:
	# 根据卡牌类型确定图片路径规则
	match card_type:
		"角色卡":
			return get_character_card_image_path(card_id)
		"情报卡":
			return "res://assets/workday_new/ui/card_icons/item/" + card_id + ".png"
		"特权卡":
			return get_privilege_card_image_path(card_id)
		"金币卡":
			return "res://assets/ui/coins.png"
		_:
			return ""

# 获取角色卡图片路径
func get_character_card_image_path(card_id: String) -> String:
	var character_data = get_character_card_data(card_id)
	if character_data:
		return character_data.get_character_image_path()
	else:
		print("EventSlotItem: 无法找到角色卡数据 - ID: ", card_id)
		return ""

# 获取特权卡图片路径
func get_privilege_card_image_path(card_id: String) -> String:
	# 通过PrivilegeCardManager获取特权卡数据
	if not PrivilegeCardManager:
		print("EventSlotItem: 警告 - PrivilegeCardManager未找到")
		return ""
	
	# 查找对应的特权卡
	var all_cards = PrivilegeCardManager.get_all_cards()
	for card in all_cards:
		if card.card_id == card_id:
			print("EventSlotItem: 找到特权卡 ", card.card_type, " 图片路径: ", card.texture_path)
			return card.texture_path
	
	print("EventSlotItem: 未找到ID为 ", card_id, " 的特权卡")
	return ""

# 获取角色卡数据
func get_character_card_data(card_id: String) -> CharacterCardData:
	# 获取角色卡管理器
	var card_manager = get_node_or_null("/root/CharacterCardManager")
	if not card_manager:
		print("EventSlotItem: 警告 - CharacterCardManager未找到")
		return null
	
	# 通过ID获取角色卡数据
	var card_data = card_manager.get_card_by_id(card_id)
	if not card_data:
		print("EventSlotItem: 警告 - 未找到ID为 ", card_id, " 的角色卡")
		return null
	
	return card_data

# 更新状态标签颜色
func update_status_color():
	if not slot_data:
		return
	
	if slot_data.has_card_placed():
		# 已放置 - 绿色
		status_label.modulate = Color(0.2, 0.6, 0.2, 1)
	elif slot_data.required_for_completion:
		# 必需但未放置 - 红色
		status_label.modulate = Color(0.8, 0.2, 0.2, 1)
	else:
		# 可选且未放置 - 灰色
		status_label.modulate = Color(0.5, 0.5, 0.5, 1)

# 设置高亮状态
func set_highlight(highlight: bool):
	is_highlighted = highlight
	highlight_border.visible = highlight
	_update_background_style()

# 设置禁用状态
func set_disabled_state(disabled: bool):
	is_disabled = disabled
	_update_background_style()
	print("EventSlotItem: 卡槽", slot_data.slot_id if slot_data else "未知", "禁用状态:", disabled)

# 更新背景样式
func _update_background_style():
	if is_disabled:
		# 禁用状态 - 灰色背景
		slot_button.modulate = Color(0.5, 0.5, 0.5, 0.7)
	elif is_highlighted:
		# 高亮状态
		slot_button.modulate = Color(1.1, 1.1, 1.1, 1)
	else:
		# 正常状态
		slot_button.modulate = Color.WHITE

# 检查是否可以放置指定类型的卡牌
func can_place_card_type(card_type: String) -> bool:
	if not slot_data:
		return false
	
	# 检查卡槽是否已有卡牌
	if slot_data.has_card_placed():
		return false
	
	# 检查卡牌类型是否被允许
	return slot_data.is_card_type_allowed(card_type)

# 模拟放置卡牌（用于预览）
func preview_card_placement(card_type: String, card_id: String):
	if not slot_data:
		return
	
	# 临时设置卡牌信息用于预览
	var original_type = slot_data.placed_card_type
	var original_id = slot_data.placed_card_id
	
	slot_data.placed_card_type = card_type
	slot_data.placed_card_id = card_id
	
	update_card_status()
	
	# 恢复原始状态
	await get_tree().create_timer(2.0).timeout
	slot_data.placed_card_type = original_type
	slot_data.placed_card_id = original_id
	update_card_status()

# 获取卡槽数据
func get_slot_data() -> EventSlotData:
	return slot_data

# 获取卡槽ID
func get_slot_id() -> int:
	return slot_data.slot_id if slot_data else 0

# 检查是否为必需卡槽
func is_required() -> bool:
	return slot_data.required_for_completion if slot_data else false

# 获取允许的卡牌类型
func get_allowed_card_types() -> Array:
	return slot_data.get_allowed_card_types() if slot_data else []

# 信号处理函数
func _on_slot_button_pressed():
	if slot_data:
		print("EventSlotItem: 卡槽被点击 - ", slot_data.slot_id, ": ", slot_data.slot_description)
		slot_clicked.emit(slot_data)

func _on_remove_button_pressed():
	if slot_data and slot_data.has_card_placed():
		print("EventSlotItem: 移除卡牌 - ", slot_data.placed_card_type, "[", slot_data.placed_card_id, "]")
		
		# 通过EventSlotManager移除卡牌
		if EventSlotManager:
			var success = EventSlotManager.remove_card_from_slot(slot_data.event_id, slot_data.slot_id)
			if success:
				update_display()
				slot_card_changed.emit(slot_data)

# 处理鼠标悬停效果
func _on_slot_button_mouse_entered():
	if not is_highlighted and not is_disabled:
		slot_button.modulate = Color(1.05, 1.05, 1.05, 1)

func _on_slot_button_mouse_exited():
	if not is_highlighted and not is_disabled:
		slot_button.modulate = Color.WHITE

# 获取调试信息
func get_debug_info() -> String:
	if not slot_data:
		return "EventSlotItem: 无数据"
	
	var info = "EventSlotItem[%d]: %s\n" % [slot_data.slot_id, slot_data.slot_description]
	info += "  允许类型: %s\n" % str(slot_data.get_allowed_card_types())
	info += "  是否必需: %s\n" % str(slot_data.required_for_completion)
	info += "  当前状态: %s\n" % ("已放置" if slot_data.has_card_placed() else "空")
	
	if slot_data.has_card_placed():
		info += "  放置卡牌: %s [%s]\n" % [slot_data.placed_card_type, slot_data.placed_card_id]
	
	return info 

# 创建CharacterCard实例
func create_character_card_instance():
	if character_card_instance:
		destroy_character_card_instance()
	
	character_card_instance = CharacterCardScene.instantiate()
	character_card_container.add_child(character_card_instance)
	
	# 设置合适的缩放比例以适应容器
	setup_character_card_scale()
	
	print("EventSlotItem: 创建CharacterCard实例")

# 销毁CharacterCard实例
func destroy_character_card_instance():
	if character_card_instance and is_instance_valid(character_card_instance):
		character_card_instance.queue_free()
		character_card_instance = null
		print("EventSlotItem: 销毁CharacterCard实例")

# 设置CharacterCard缩放
func setup_character_card_scale():
	if not character_card_instance:
		return
	
	# 多重延迟执行以确保布局完全稳定
	call_deferred("_wait_for_container_ready")

# 等待容器准备就绪（第一重延迟）
func _wait_for_container_ready():
	if not character_card_instance or not is_instance_valid(character_card_instance):
		return
	
	# 第二重延迟，等待布局系统完成
	call_deferred("_wait_for_layout_stable")

# 布局稳定性检测变量
var _layout_check_count: int = 0
var _last_container_size: Vector2 = Vector2.ZERO
var _max_layout_checks: int = 10

# 等待布局稳定（布局稳定性检测）
func _wait_for_layout_stable():
	if not character_card_instance or not is_instance_valid(character_card_instance):
		return
	
	var current_size = character_card_container.size
	
	# 检查容器尺寸合理性
	if _is_container_size_reasonable(current_size):
		# 尺寸一致性验证：连续3帧获取相同尺寸才认为稳定
		if current_size == _last_container_size:
			_layout_check_count += 1
			if _layout_check_count >= 3:
				# 布局稳定，执行缩放
				print("EventSlotItem: 布局稳定检测通过，执行缩放 - 稳定尺寸: ", current_size)
				_apply_character_card_scale()
				_reset_layout_check()
				return
		else:
			# 尺寸发生变化，重置计数
			_last_container_size = current_size
			_layout_check_count = 1
	else:
		print("EventSlotItem: 检测到异常容器尺寸: ", current_size, " - 继续等待")
	
	# 超时保护机制：最多等待10帧后强制执行
	if _layout_check_count < _max_layout_checks:
		call_deferred("_wait_for_layout_stable")
	else:
		print("EventSlotItem: 布局检测超时，使用标准尺寸强制执行缩放")
		_apply_character_card_scale_with_standard_size()
		_reset_layout_check()

# 重置布局检查状态
func _reset_layout_check():
	_layout_check_count = 0
	_last_container_size = Vector2.ZERO

# 检查容器尺寸是否合理
func _is_container_size_reasonable(size: Vector2) -> bool:
	# 异常尺寸检测：高度超过200像素视为异常
	if size.y > 200:
		return false
	# 宽度应该在合理范围内（80-200像素）
	if size.x < 80 or size.x > 200:
		return false
	# 零尺寸也不合理
	if size == Vector2.ZERO:
		return false
	return true

# 使用标准尺寸强制执行缩放
func _apply_character_card_scale_with_standard_size():
	if not character_card_instance or not is_instance_valid(character_card_instance):
		return
	
	# 使用标准尺寸
	var container_size = Vector2(120, 140)
	var card_original_size = Vector2(300, 420)
	
	# 计算缩放
	var scale_x = container_size.x / card_original_size.x
	var scale_y = container_size.y / card_original_size.y
	var final_scale = min(scale_x, scale_y)
	
	character_card_instance.scale = Vector2(final_scale, final_scale)
	
	# 计算居中位置
	var scaled_size = card_original_size * final_scale
	var offset = (container_size - scaled_size) * 0.5
	character_card_instance.position = offset
	
	print("EventSlotItem: 强制使用标准尺寸缩放 - 容器尺寸: ", container_size, ", 缩放比例: ", final_scale, ", 位置: ", offset)

# 应用CharacterCard缩放（延迟执行）
func _apply_character_card_scale():
	if not character_card_instance or not is_instance_valid(character_card_instance):
		return
	
	# 获取容器的实际尺寸
	var container_size = character_card_container.size
	
	# 增强的尺寸验证机制
	if not _is_container_size_reasonable(container_size):
		print("EventSlotItem: 检测到异常容器尺寸: ", container_size, " - 使用标准尺寸")
		container_size = Vector2(120, 140)
	
	var card_original_size = Vector2(300, 420)
	
	# 使用较小的缩放比例以确保完全适应容器
	var scale_x = container_size.x / card_original_size.x
	var scale_y = container_size.y / card_original_size.y
	var final_scale = min(scale_x, scale_y)
	
	character_card_instance.scale = Vector2(final_scale, final_scale)
	
	# 居中对齐
	var scaled_size = card_original_size * final_scale
	var offset = (container_size - scaled_size) * 0.5
	
	# 位置合理性检查
	if not _is_position_reasonable(offset):
		print("EventSlotItem: 检测到异常位置: ", offset, " - 使用安全回退位置")
		offset = Vector2(10, 0)  # 安全回退位置
	
	character_card_instance.position = offset
	
	# 增强的日志记录
	print("EventSlotItem: CharacterCard缩放应用 - 容器尺寸: ", container_size, ", 缩放比例: ", final_scale, ", 位置: ", offset)
	print("EventSlotItem: 尺寸合理性: ", _is_container_size_reasonable(character_card_container.size), ", 实际容器尺寸: ", character_card_container.size)

# 检查位置是否合理
func _is_position_reasonable(position: Vector2) -> bool:
	# 位置不应该有负值
	if position.x < 0 or position.y < 0:
		return false
	# Y位置不应该超过100像素（异常偏移）
	if position.y > 100:
		return false
	return true

# 应急恢复方法
func _emergency_reset_card_position():
	if not character_card_instance or not is_instance_valid(character_card_instance):
		return
	
	print("EventSlotItem: 执行应急位置重置")
	character_card_instance.position = Vector2(10, 0)  # 安全回退位置
	character_card_instance.scale = Vector2(0.33, 0.33)  # 标准缩放比例

# 加载角色卡显示
func load_character_card(card_data: CharacterCardData):
	if not card_data:
		print("EventSlotItem: 角色卡数据为空")
		return
	
	# 创建CharacterCard实例
	create_character_card_instance()
	
	# 设置卡片数据
	if character_card_instance:
		character_card_instance.set_card_data(card_data)
		print("EventSlotItem: 加载角色卡 - ", card_data.card_name)

# 创建金币数量标签
func create_coin_amount_label():
	if coin_amount_label and is_instance_valid(coin_amount_label):
		return  # 标签已存在
	
	# 创建新的标签节点
	coin_amount_label = Label.new()
	coin_amount_label.name = "CoinAmountLabel"
	
	# 设置标签样式
	coin_amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coin_amount_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	
	# 设置字体和颜色
	var font = load("res://assets/font/LEEEAFHEI-REGULAR.TTF")
	if font:
		coin_amount_label.add_theme_font_override("font", font)
	coin_amount_label.add_theme_font_size_override("font_size", 18)
	coin_amount_label.add_theme_color_override("font_color", Color(1, 0.843, 0, 1))  # 金色
	
	# 设置位置和大小
	coin_amount_label.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	coin_amount_label.offset_left = -40
	coin_amount_label.offset_top = -25
	coin_amount_label.offset_right = -5
	coin_amount_label.offset_bottom = -5
	
	# 添加到CardPreview容器
	var card_preview = $ContentContainer/RightSection/CardPreview
	if card_preview:
		card_preview.add_child(coin_amount_label)
		print("EventSlotItem: 创建金币数量标签")

# 更新金币数量显示
func update_coin_amount_display():
	if not coin_amount_label or not is_instance_valid(coin_amount_label):
		return
	
	var required_amount = get_required_coin_amount()
	if required_amount > 0:
		coin_amount_label.text = "x" + str(required_amount)
		coin_amount_label.visible = true
		print("EventSlotItem: 更新金币数量显示 - x", required_amount)
	else:
		coin_amount_label.visible = false

# 获取所需金币数量
func get_required_coin_amount() -> int:
	if not slot_data or not slot_data.has_card_placed():
		return 0
	
	if slot_data.placed_card_type != "金币卡":
		return 0
	
	# 从specific_card_json中获取金币数量要求
	var requirements = slot_data.get_specific_card_requirements()
	if requirements.has("金币卡") and requirements["金币卡"] is Array:
		var amounts = requirements["金币卡"]
		if amounts.size() > 0:
			return amounts[0].to_int()
	
	return 0 