#@tool
extends PanelContainer
class_name CharacterEventCardFixed

# 内容属性
@export_group("内容")
@export var event_title: String = "事件标题" : set = set_event_title
@export var character_name: String = "相关人物" : set = set_character_name
@export var event_status: String = "new" : set = set_event_status  # "new" 或 "dealing"
@export var character_texture: Texture2D : set = set_character_texture
@export var game_event: GameEvent

# 图像裁剪属性
@export_group("图像裁剪")
@export var region_enabled: bool = false : set = set_region_enabled
@export_range(0.0, 1.0, 0.01) var region_y_position: float = 0.0 : set = set_region_y_position
@export_range(0.0, 1.0, 0.01) var region_height: float = 0.45 : set = set_region_height

# 样式属性
@export_group("样式")
@export var border_color: Color = Color(0.7, 0.7, 0.7, 1.0) : set = set_border_color
@export var corner_radius: int = 8 : set = set_corner_radius
@export var border_width: int = 2 : set = set_border_width
@export var background_color: Color = Color("#fff8f1") : set = set_background_color
@export var title_font_size: int = 50 : set = set_title_font_size
@export var name_font_size: int = 50 : set = set_name_font_size

# 用于存储原始纹理的变量
var _original_texture: Texture2D = null

# 节点引用
@onready var character_image = $CardContent/EventCharacterPortrait
@onready var title_label = $CardContent/EventTitle
@onready var name_label = $CardContent/EventPerson
@onready var status_icon = $CardContent/StatusIcon
@onready var round_info = $CardContent/RoundInfo

# 资源引用
var new_status_texture = preload("res://assets/workday_new/ui/events/new.png")
var dealing_status_texture = preload("res://assets/workday_new/ui/events/dealing.png")

# 信号
signal card_clicked

func _ready():
	# 确保卡片能接收点击事件
	mouse_filter = Control.MOUSE_FILTER_STOP  # 停止事件传播，由卡片处理
	
	# 设置CardContent容器忽略鼠标事件，让事件传播到父容器
	if has_node("CardContent"):
		get_node("CardContent").mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 设置所有子节点忽略鼠标事件，让事件传播到父容器
	if title_label:
		title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if name_label:
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if status_icon:
		status_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if round_info:
		round_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if character_image:
		character_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_node("CardContent/EventCharacterPortrait"):
		get_node("CardContent/EventCharacterPortrait").mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 检查是否需要创建EventCharacterPortrait节点
	if not has_node("CardContent/EventCharacterPortrait"):
		print("未找到EventCharacterPortrait节点，正在动态创建...")
		var image_node = TextureRect.new()
		image_node.name = "EventCharacterPortrait"
		image_node.expand_mode = 3  # EXPAND_IGNORE_SIZE
		image_node.stretch_mode = 4  # STRETCH_KEEP_ASPECT_CONTAINED
		image_node.set_anchors_preset(Control.PRESET_FULL_RECT) # 填充整个区域
		image_node.position = Vector2(0, 0)
		image_node.size = Vector2(420, 270)
		image_node.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 新创建的节点也设置为忽略鼠标事件
		$CardContent.add_child(image_node)
		$CardContent.move_child(image_node, 0) # 移到最底层
		character_image = image_node
		print("已创建EventCharacterPortrait节点")
	
	# 连接信号
	gui_input.connect(_on_gui_input)
	
	# 连接EventManager信号
	_connect_event_manager_signals()
	
	# 应用样式
	_apply_style()
	
	# 应用内容
	_apply_content()
	
	# 配置CharacterImage的显示模式
	if is_instance_valid(character_image):
		character_image.expand_mode = 3  # EXPAND_IGNORE_SIZE
		character_image.stretch_mode = 4  # STRETCH_KEEP_ASPECT_CONTAINED
		
		# 将CharacterImage移到所有其他节点的下方（最底层）
		var parent = character_image.get_parent()
		if parent:
			# 暂时移除节点
			parent.remove_child(character_image)
			# 将节点添加到最前面（在Godot中，添加顺序决定了绘制顺序，先添加的在下面）
			parent.add_child(character_image)
			# 将已有的其他节点移到最前面，确保它们在CharacterImage上方
			if is_instance_valid(title_label):
				parent.move_child(title_label, -1)  # 移到最后（最上面）
			if is_instance_valid(name_label):
				parent.move_child(name_label, -1)   # 移到最后（最上面）
			if is_instance_valid(status_icon):
				parent.move_child(status_icon, -1)  # 移到最后（最上面）
			if is_instance_valid(round_info) and round_info.get_parent() == parent:
				parent.move_child(round_info, -1)
			
			# 打印节点层级信息
			print("节点层级顺序:")
			for i in range(parent.get_child_count()):
				var child = parent.get_child(i)
				print("  ", i, ": ", child.name, " (", child.get_class(), ")")
	
	# 调试信息：打印当前字体大小
	print("卡片就绪: ", event_title, " - 标题字体大小: ", title_font_size, ", 人物名称字体大小: ", name_font_size)

# 内容属性更新
func set_event_title(text: String):
	event_title = text
	if is_instance_valid(title_label):
		title_label.text = text

func set_character_name(text: String):
	character_name = text
	if is_instance_valid(name_label):
		name_label.text = text

func set_event_status(status: String):
	print("CharacterEventCardFixed: 设置事件状态 - 从 '", event_status, "' 到 '", status, "'")
	
	# 验证状态值
	if status != "new" and status != "dealing":
		print("⚠ CharacterEventCardFixed: 无效状态值 '", status, "'，默认为'new'")
		status = "new"
	
	event_status = status
	
	if is_instance_valid(status_icon):
		print("CharacterEventCardFixed: 更新StatusIcon纹理...")
		var old_texture = status_icon.texture
		
		if status == "new":
			status_icon.texture = new_status_texture
			print("  设置为new状态纹理: ", new_status_texture)
		else:
			status_icon.texture = dealing_status_texture
			print("  设置为dealing状态纹理: ", dealing_status_texture)
		
		var new_texture = status_icon.texture
		print("  纹理更新结果: ", old_texture, " -> ", new_texture)
		
		# 强制重绘
		if status_icon.has_method("queue_redraw"):
			status_icon.queue_redraw()
		
		print("✓ CharacterEventCardFixed: StatusIcon纹理更新完成")
	else:
		print("⚠ CharacterEventCardFixed: status_icon无效，无法更新纹理")

func set_character_texture(texture: Texture2D):
	_original_texture = texture
	character_texture = texture
	
	if is_instance_valid(character_image):
		if region_enabled and texture:
			_apply_texture_region()
		else:
			character_image.texture = texture
			# 确保使用正确的stretch_mode
			character_image.expand_mode = 3  # EXPAND_IGNORE_SIZE
			character_image.stretch_mode = 4  # STRETCH_KEEP_ASPECT_CONTAINED
			
			# 确保CharacterImage保持在最底层
			var parent = character_image.get_parent()
			if parent:
				# 将角色图像移到最底层
				parent.move_child(character_image, 0)
				# 将其他节点移到上层
				if is_instance_valid(title_label) and title_label.get_parent() == parent:
					parent.move_child(title_label, -1)
				if is_instance_valid(name_label) and name_label.get_parent() == parent:
					parent.move_child(name_label, -1)
				if is_instance_valid(status_icon) and status_icon.get_parent() == parent:
					parent.move_child(status_icon, -1)
				if is_instance_valid(round_info) and round_info.get_parent() == parent:
					parent.move_child(round_info, -1)

# 区域裁剪属性更新
func set_region_enabled(enabled: bool):
	region_enabled = enabled
	if _original_texture:
		if region_enabled:
			_apply_texture_region()
		else:
			character_image.texture = _original_texture

func set_region_y_position(position: float):
	region_y_position = position
	if region_enabled and _original_texture:
		_apply_texture_region()

func set_region_height(height: float):
	region_height = height
	if region_enabled and _original_texture:
		_apply_texture_region()

# 处理区域裁剪的方法
func _apply_texture_region():
	if not _original_texture or not is_instance_valid(character_image):
		return
		
	var atlas = AtlasTexture.new()
	atlas.atlas = _original_texture
	
	# 计算裁剪区域
	var original_size = _original_texture.get_size()
	var region_y = original_size.y * region_y_position
	var region_h = original_size.y * region_height
	
	# 确保区域不超出纹理边界
	region_h = min(region_h, original_size.y - region_y)
	
	atlas.region = Rect2(0, region_y, original_size.x, region_h)
	character_image.texture = atlas
	
	# 确保使用正确的stretch_mode
	character_image.expand_mode = 3  # EXPAND_IGNORE_SIZE
	character_image.stretch_mode = 4  # STRETCH_KEEP_ASPECT_CONTAINED
	
	# 确保CharacterImage保持在最底层
	var parent = character_image.get_parent()
	if parent:
		# 将角色图像移到最底层
		parent.move_child(character_image, 0)
		# 将其他节点移到上层
		if is_instance_valid(title_label) and title_label.get_parent() == parent:
			parent.move_child(title_label, -1)
		if is_instance_valid(name_label) and name_label.get_parent() == parent:
			parent.move_child(name_label, -1)
		if is_instance_valid(status_icon) and status_icon.get_parent() == parent:
			parent.move_child(status_icon, -1)
		if is_instance_valid(round_info) and round_info.get_parent() == parent:
			parent.move_child(round_info, -1)

# 样式属性更新
func set_border_color(color: Color):
	border_color = color
	_apply_style()

func set_background_color(color: Color):
	background_color = color
	_apply_style()

func set_corner_radius(radius: int):
	corner_radius = radius
	_apply_style()

func set_border_width(width: int):
	border_width = width
	_apply_style()

# 字体大小属性更新
func set_title_font_size(size: int):
	title_font_size = size
	if is_instance_valid(title_label):
		title_label.add_theme_font_size_override("font_size", size)

func set_name_font_size(size: int):
	name_font_size = size
	if is_instance_valid(name_label):
		name_label.add_theme_font_size_override("font_size", size)

# 应用内容属性
func _apply_content():
	set_event_title(event_title)
	set_character_name(character_name)
	set_event_status(event_status)
	
	# 保存并应用纹理，处理区域裁剪
	if character_texture:
		_original_texture = character_texture
		set_character_texture(character_texture)
	
	# 应用字体大小
	set_title_font_size(title_font_size)
	set_name_font_size(name_font_size)
	
	# 更新回合信息（如果游戏事件已设置）
	if game_event:
		_update_round_info()

# 应用样式
func _apply_style():
	# 创建StyleBoxFlat
	var style = StyleBoxFlat.new()
	
	# 设置背景颜色
	style.bg_color = background_color
	
	# 其他样式设置不变
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	
	# 应用样式
	add_theme_stylebox_override("panel", style)

# 点击事件处理
func _on_gui_input(event):
	print("CharacterEventCardFixed: 接收到输入事件 - 类型: ", event.get_class())
	if event is InputEventMouseButton:
		print("CharacterEventCardFixed: 鼠标按钮事件 - 按下: ", event.pressed, ", 按钮: ", event.button_index)
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("CharacterEventCardFixed: 卡片被点击 - ", event_title)
			print("CharacterEventCardFixed: game_event状态 - ", game_event.event_name if game_event else "null")
			print("CharacterEventCardFixed: 鼠标过滤设置 - ", mouse_filter)
			print("CharacterEventCardFixed: 发射card_clicked信号...")
			if game_event:
				print("CharacterEventCardFixed: 发射card_clicked信号，事件: ", game_event.event_name)
			else:
				print("CharacterEventCardFixed: 错误 - 没有关联的game_event，无法处理点击")
			card_clicked.emit()
			print("CharacterEventCardFixed: card_clicked信号已发射")

# 获取卡片类型
func get_card_type() -> String:
	return "character" 

# 游戏事件管理方法
func set_game_event(event: GameEvent) -> void:
	game_event = event
	print("CharacterEventCardFixed: 设置game_event - ", event.event_name if event else "null")
	
	# 连接EventManager信号（确保在设置事件时信号已连接）
	_connect_event_manager_signals()
	
	# 检查并设置初始状态
	if event:
		var event_manager = get_node_or_null("/root/EventManager")
		if event_manager:
			var initial_completed = event_manager.is_event_completed(event.event_id)
			if initial_completed:
				set_event_status("dealing")
			else:
				set_event_status("new")
			print("CharacterEventCardFixed: 初始化状态为: ", "dealing" if initial_completed else "new")
			
			# 延迟状态检查，确保状态正确性
			call_deferred("_delayed_status_check")
		else:
			# 如果EventManager未找到，默认为new
			set_event_status("new")
			print("CharacterEventCardFixed: EventManager未找到，默认设为new状态")
		
		# 更新回合信息
		_update_round_info()
	else:
		set_event_status("new")

func get_game_event() -> GameEvent:
	return game_event 

# 连接EventManager信号
func _connect_event_manager_signals():
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		print("⚠ CharacterEventCardFixed: EventManager未找到，无法连接信号")
		return
	
	if not event_manager.event_completed.is_connected(_on_event_completed):
		event_manager.event_completed.connect(_on_event_completed)
		print("CharacterEventCardFixed: 已连接EventManager的event_completed信号")

# 处理事件完成信号
func _on_event_completed(event_id: int):
	print("CharacterEventCardFixed: 收到事件完成信号 - event_id:", event_id)
	
	if not game_event:
		print("CharacterEventCardFixed: 无game_event，忽略信号")
		return
		
	if game_event.event_id == event_id:
		print("CharacterEventCardFixed: 信号匹配当前事件，强制更新状态")
		
		# 强制更新状态为dealing（已处理）
		_force_status_update("dealing")
		
		# 更新回合信息显示
		_update_round_info()
		
		# 验证状态一致性
		call_deferred("_verify_status_consistency")
		
		print("CharacterEventCardFixed: 事件完成处理完毕 - ", event_id)
	else:
		print("CharacterEventCardFixed: 信号不匹配当前事件 (当前:", game_event.event_id, " 信号:", event_id, ")")

# 更新回合信息显示
func _update_round_info():
	if not game_event or not round_info:
		return
	
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		print("⚠ CharacterEventCardFixed: EventManager未找到，回合信息不更新")
		return
	
	# 统一显示格式：只显示数字
	var duration_text = str(game_event.duration_rounds)
	round_info.text = duration_text
	print("CharacterEventCardFixed: 回合信息显示:", duration_text)

# 验证状态一致性的方法
func _verify_status_consistency():
	if not game_event:
		print("⚠ CharacterEventCardFixed: 无game_event，无法验证状态")
		return false
	
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		print("⚠ CharacterEventCardFixed: EventManager未找到，无法验证状态")
		return false
	
	var manager_completed = event_manager.is_event_completed(game_event.event_id)
	var card_status_is_dealing = (event_status == "dealing")
	
	print("CharacterEventCardFixed: 状态一致性检查")
	print("  事件ID: ", game_event.event_id)
	print("  事件名称: ", game_event.event_name)
	print("  EventManager完成状态: ", manager_completed)
	print("  卡片状态: ", event_status)
	print("  状态一致性: ", manager_completed == card_status_is_dealing)
	
	if manager_completed != card_status_is_dealing:
		print("⚠ CharacterEventCardFixed: 状态不一致，需要修正")
		return false
	
	print("✓ CharacterEventCardFixed: 状态一致")
	return true

# 强制状态更新方法
func _force_status_update(new_status: String):
	print("CharacterEventCardFixed: 强制状态更新到 '", new_status, "'")
	
	# 直接更新状态，跳过常规验证
	event_status = new_status
	
	if is_instance_valid(status_icon):
		print("CharacterEventCardFixed: 强制更新StatusIcon纹理...")
		
		if new_status == "new":
			status_icon.texture = new_status_texture
		else:
			status_icon.texture = dealing_status_texture
		
		# 强制刷新UI
		if status_icon.has_method("queue_redraw"):
			status_icon.queue_redraw()
		
		# 确保父容器也刷新
		var parent = status_icon.get_parent()
		while parent and parent != self:
			if parent.has_method("queue_redraw"):
				parent.queue_redraw()
			parent = parent.get_parent()
		
		print("✓ CharacterEventCardFixed: 强制状态更新完成")
	else:
		print("⚠ CharacterEventCardFixed: status_icon无效，强制更新失败")

# 验证并修正初始状态的方法
func _verify_and_fix_initial_status():
	print("CharacterEventCardFixed: 验证并修正初始状态...")
	
	if not _verify_status_consistency():
		print("CharacterEventCardFixed: 检测到状态不一致，进行修正")
		
		var event_manager = get_node_or_null("/root/EventManager")
		if event_manager and game_event:
			var should_be_completed = event_manager.is_event_completed(game_event.event_id)
			var correct_status = "dealing" if should_be_completed else "new"
			
			print("CharacterEventCardFixed: 修正状态到 '", correct_status, "'")
			_force_status_update(correct_status)
			
			# 再次验证
			call_deferred("_verify_status_consistency")
	else:
		print("✓ CharacterEventCardFixed: 初始状态正确")

# 延迟状态检查方法
func _delayed_status_check():
	print("CharacterEventCardFixed: 执行延迟状态检查...")
	
	if not game_event:
		print("CharacterEventCardFixed: 无game_event，跳过延迟检查")
		return
	
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		print("CharacterEventCardFixed: EventManager未找到，跳过延迟检查")
		return
	
	var current_completed = event_manager.is_event_completed(game_event.event_id)
	var current_status_dealing = (event_status == "dealing")
	
	if current_completed != current_status_dealing:
		print("CharacterEventCardFixed: 延迟检查发现状态不一致，进行修正")
		var correct_status = "dealing" if current_completed else "new"
		_force_status_update(correct_status)
	else:
		print("✓ CharacterEventCardFixed: 延迟检查确认状态正确")

# 运行时状态监控报告方法
func get_status_report() -> Dictionary:
	var report = {
		"card_instance_id": get_instance_id(),
		"event_title": event_title,
		"event_status": event_status,
		"game_event_id": game_event.event_id if game_event else -1,
		"game_event_name": game_event.event_name if game_event else "null",
		"status_icon_valid": is_instance_valid(status_icon),
		"status_icon_texture": str(status_icon.texture) if is_instance_valid(status_icon) else "null",
		"manager_completed_status": "unknown"
	}
	
	var event_manager = get_node_or_null("/root/EventManager")
	if event_manager and game_event:
		report.manager_completed_status = event_manager.is_event_completed(game_event.event_id)
	
	return report

# 打印状态报告
func print_status_report():
	var report = get_status_report()
	print("=== CharacterEventCard状态报告 ===")
	for key in report:
		print("  ", key, ": ", report[key])
	print("=== 报告结束 ===")

# 启用持续状态监控（可选，用于调试）
func enable_status_monitoring(interval_seconds: float = 5.0):
	print("CharacterEventCardFixed: 启用状态监控，间隔", interval_seconds, "秒")
	
	var timer = Timer.new()
	timer.wait_time = interval_seconds
	timer.timeout.connect(_on_monitoring_timer_timeout)
	add_child(timer)
	timer.start()

# 监控定时器回调
func _on_monitoring_timer_timeout():
	print("CharacterEventCardFixed: 状态监控检查 - ", event_title)
	if not _verify_status_consistency():
		print("⚠ 监控检测到状态问题，执行修正")
		_verify_and_fix_initial_status()

# 统一状态访问接口实现
func get_completion_status() -> bool:
	# CharacterEventCard使用event_status管理状态
	return event_status == "dealing"

func set_completion_status(completed: bool):
	# 使用现有的set_event_status方法
	if completed:
		set_event_status("dealing")
	else:
		set_event_status("new")

func get_status_description() -> String:
	# 返回详细状态描述，用于调试
	var event_id = game_event.event_id if game_event else -1
	var event_name = game_event.event_name if game_event else "null"
	return "CharacterEventCard[" + str(event_id) + ":" + event_name + "] event_status: " + event_status + " (completed: " + str(get_completion_status()) + ")"
