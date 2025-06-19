extends Control

# IncompleteEventWarning - 未完成事件警告弹窗
# 当用户尝试完成未满足条件的事件时显示

signal warning_closed()

@onready var warning_panel = $WarningPanel
@onready var title_label = $WarningPanel/VBoxContainer/TitleLabel
@onready var content_label = $WarningPanel/VBoxContainer/ContentLabel
@onready var missing_slots_list = $WarningPanel/VBoxContainer/MissingSlotsList
@onready var confirm_button = $WarningPanel/VBoxContainer/ButtonsContainer/ConfirmButton
@onready var close_button = $WarningPanel/VBoxContainer/ButtonsContainer/CloseButton
@onready var background = $Background

var current_event_id: int = -1

func _ready():
	# 连接按钮信号
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	background.gui_input.connect(_on_background_clicked)
	
	# 初始状态隐藏
	visible = false
	
	print("IncompleteEventWarning: 初始化完成")

# 显示警告弹窗
func show_warning(event_id: int, missing_slots: Array = []):
	current_event_id = event_id
	
	# 清空现有的缺失卡槽列表
	for child in missing_slots_list.get_children():
		missing_slots_list.remove_child(child)
		child.queue_free()
	
	# 设置内容
	if missing_slots.is_empty():
		content_label.text = "请在必需的卡槽中放置卡牌后再确认完成事件"
	else:
		content_label.text = "以下必需卡槽还未放置卡牌："
		
		# 添加缺失卡槽的详细信息
		for slot_info in missing_slots:
			var slot_label = Label.new()
			slot_label.add_theme_font_override("font", load("res://assets/font/LEEEAFHEI-REGULAR.TTF"))
			slot_label.add_theme_font_size_override("font_size", 18)
			slot_label.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3, 1))
			
			var allowed_types_text = ""
			if slot_info.has("allowed_types") and slot_info.allowed_types is Array:
				allowed_types_text = " (允许: " + ", ".join(slot_info.allowed_types) + ")"
			
			slot_label.text = "• " + slot_info.description + allowed_types_text
			slot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			missing_slots_list.add_child(slot_label)
	
	# 显示弹窗
	visible = true
	
	# 播放弹出动画
	_play_show_animation()
	
	print("IncompleteEventWarning: 显示警告 - 事件", event_id, " 缺失卡槽数:", missing_slots.size())

# 隐藏警告弹窗
func hide_warning():
	# 播放隐藏动画
	_play_hide_animation()
	
	print("IncompleteEventWarning: 隐藏警告")
	warning_closed.emit()

# 播放显示动画
func _play_show_animation():
	# 设置初始状态
	warning_panel.scale = Vector2(0.8, 0.8)
	warning_panel.modulate.a = 0.0
	
	# 创建补间动画
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 缩放动画
	tween.tween_property(warning_panel, "scale", Vector2(1.0, 1.0), 0.3)
	tween.tween_property(warning_panel, "modulate:a", 1.0, 0.3)
	
	# 设置缓动
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

# 播放隐藏动画
func _play_hide_animation():
	# 创建补间动画
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 缩放动画
	tween.tween_property(warning_panel, "scale", Vector2(0.8, 0.8), 0.2)
	tween.tween_property(warning_panel, "modulate:a", 0.0, 0.2)
	
	# 设置缓动
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUART)
	
	# 动画完成后隐藏
	tween.tween_callback(func(): visible = false).set_delay(0.2)

# 设置自定义警告信息
func show_custom_warning(title: String, content: String):
	current_event_id = -1
	
	# 清空缺失卡槽列表
	for child in missing_slots_list.get_children():
		missing_slots_list.remove_child(child)
		child.queue_free()
	
	# 设置自定义内容
	title_label.text = title
	content_label.text = content
	
	# 显示弹窗
	visible = true
	_play_show_animation()
	
	print("IncompleteEventWarning: 显示自定义警告 - ", title)

# 获取当前显示的事件ID
func get_current_event_id() -> int:
	return current_event_id

# 检查是否正在显示
func is_showing() -> bool:
	return visible

# 按钮事件处理
func _on_confirm_button_pressed():
	print("IncompleteEventWarning: 确认按钮被点击")
	hide_warning()

func _on_close_button_pressed():
	print("IncompleteEventWarning: 关闭按钮被点击")
	hide_warning()

# 点击背景关闭弹窗
func _on_background_clicked(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("IncompleteEventWarning: 点击背景关闭弹窗")
			hide_warning()

# 处理ESC键
func _input(event):
	if not visible:
		return
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			print("IncompleteEventWarning: ESC键关闭弹窗")
			hide_warning()
			get_viewport().set_input_as_handled()

# 重新调整弹窗大小以适应内容
func _adjust_panel_size():
	# 等待一帧让布局系统处理完毕
	await get_tree().process_frame
	
	# 计算内容所需的最小高度
	var content_height = 0
	for child in missing_slots_list.get_children():
		if child is Label:
			content_height += child.get_theme_font_size("font_size") + 8
	
	# 设置弹窗的最小高度
	var min_height = 200 + content_height
	var current_size = warning_panel.size
	
	if current_size.y < min_height:
		warning_panel.custom_minimum_size.y = min_height 
