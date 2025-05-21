extends Control

# 脚本功能：字体大小设置UI界面逻辑
# 允许用户选择小、中、大三种字体大小，并实时预览效果

# 定义信号
signal settings_applied
signal settings_cancelled

func _ready():
	print("字体设置UI _ready 被调用")
	
	# 连接按钮点击信号
	if not has_node("SizePanel/SmallButton") or not has_node("SizePanel/MediumButton") or not has_node("SizePanel/LargeButton"):
		printerr("Error: 字体大小按钮节点不存在")
		return
		
	if not has_node("ButtonPanel/ApplyButton") or not has_node("ButtonPanel/CancelButton"):
		printerr("Error: 确认/取消按钮节点不存在")
		return
	
	$SizePanel/SmallButton.pressed.connect(_on_small_pressed)
	$SizePanel/MediumButton.pressed.connect(_on_medium_pressed)
	$SizePanel/LargeButton.pressed.connect(_on_large_pressed)
	$ButtonPanel/ApplyButton.pressed.connect(_on_apply_pressed)
	$ButtonPanel/CancelButton.pressed.connect(_on_cancel_pressed)
	
	# 监听字体大小变化信号
	FontManager.font_size_changed.connect(update_ui)
	
	# 初始更新UI状态
	update_ui()
	print("字体设置UI初始化完成")

# 小字体按钮点击
func _on_small_pressed():
	FontManager.set_font_size(FontManager.FontSize.SMALL)
	update_preview()

# 中字体按钮点击
func _on_medium_pressed():
	FontManager.set_font_size(FontManager.FontSize.MEDIUM)
	update_preview()

# 大字体按钮点击
func _on_large_pressed():
	FontManager.set_font_size(FontManager.FontSize.LARGE)
	update_preview()

# 应用按钮点击
func _on_apply_pressed():
	# 应用当前设置并保存
	FontManager.save_settings()
	# 关闭设置界面
	queue_free()
	# 发送应用信号
	emit_signal("settings_applied")

# 取消按钮点击
func _on_cancel_pressed():
	# 重新加载设置
	FontManager.load_settings()
	FontManager.apply_global_font()
	# 关闭设置界面
	queue_free()
	# 发送取消信号
	emit_signal("settings_cancelled")

# 更新UI状态，根据当前选择的字体大小
func update_ui():
	# 更新按钮选择状态
	var current_size = FontManager.current_size
	$SizePanel/SmallButton.button_pressed = (current_size == FontManager.FontSize.SMALL)
	$SizePanel/MediumButton.button_pressed = (current_size == FontManager.FontSize.MEDIUM)
	$SizePanel/LargeButton.button_pressed = (current_size == FontManager.FontSize.LARGE)
	
	# 更新预览文本大小
	update_preview()

# 更新预览文本
func update_preview():
	# 应用当前字体大小到预览文本
	var preview_label = $PreviewPanel/PreviewLabel
	if not preview_label:
		return
		
	# 获取字体资源并确保它有效
	var font = FontManager.get_font()
	if not font:
		printerr("Error: Failed to get font from FontManager in preview")
		return
		
	preview_label.add_theme_font_override("font", font)
	preview_label.add_theme_font_size_override("font_size", FontManager.get_font_size("dialog"))
	
	# 更新大小文本
	var size_text = "当前字体大小: " + FontManager.size_to_string(FontManager.current_size)
	$SizePanel/SizeLabel.text = size_text 
