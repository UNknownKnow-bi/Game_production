extends Node

# 字体资源路径
const FONT_PATH = "res://assets/font/LEEEAFHEI-REGULAR.TTF"
const SETTINGS_FILE = "user://settings.cfg"

# 字体大小枚举
enum FontSize { SMALL, MEDIUM, LARGE }

# 当前字体大小设置
var current_size = FontSize.MEDIUM

# 字体资源
var font_resource

# 三档字体大小因子
var size_factors = {
	FontSize.SMALL: 0.8,
	FontSize.MEDIUM: 1.0,
	FontSize.LARGE: 1.2
}

# 各类元素的基础字体大小（中等大小下的值）
var base_sizes = {
	"dialog": 25,
	"speaker": 24,
	"title": 28,
	"button": 22,
	"label": 16,
	"menu": 20,
	"text": 25  # 添加文本类型
}

# 字体大小变化信号
signal font_size_changed

func _ready():
	# 加载字体资源
	font_resource = load(FONT_PATH)
	if not font_resource:
		printerr("Error: Failed to load font from ", FONT_PATH)
		return
		
	# 加载用户设置
	load_settings()
	
	# 连接树变化信号，用于监视新节点
	get_tree().node_added.connect(_on_node_added)
	
	# 延迟一帧应用字体，确保引擎和主题已初始化
	call_deferred("apply_global_font")
	
	# 连接场景变化信号
	get_tree().node_configuration_warning_changed.connect(_on_scene_changed)

# 场景变化时的回调
func _on_scene_changed():
	# 当场景结构发生变化时，重新应用字体
	call_deferred("apply_global_font")
	print("场景结构变化，刷新字体")

# 新节点添加时的回调
func _on_node_added(node):
	# 仅处理UI控件
	if node is Control:
		# 延迟一帧再应用，确保节点完全初始化
		call_deferred("apply_font_to_control", node)
		
		# 如果新节点有子节点，也对子节点应用字体
		if node.get_child_count() > 0:
			call_deferred("apply_font_to_scene_tree", node)

# 设置字体大小
func set_font_size(size):
	if size != current_size:
		current_size = size
		apply_global_font()
		save_settings()
		emit_signal("font_size_changed")
		print("Font size changed to: ", size_to_string(current_size))

# 获取当前字体大小因子
func get_size_factor():
	return size_factors[current_size]

# 获取字体大小文本表示
func size_to_string(size):
	match size:
		FontSize.SMALL: return "小"
		FontSize.MEDIUM: return "中"
		FontSize.LARGE: return "大"
		_: return "中"

# 为指定类型获取字体大小
func get_font_size(type):
	return int(base_sizes.get(type, 16) * get_size_factor())

# 应用全局字体设置
func apply_global_font():
	# 检查字体资源
	if not font_resource:
		printerr("Error: Cannot apply global font, font resource is not loaded")
		return
	
	# 获取当前字体大小因子
	var factor = get_size_factor()
	
	# 创建字体变体对象，为不同的控件类型设置字体
	var control_types = ["Button", "Label", "RichTextLabel", "LineEdit", "OptionButton", "TextEdit"]
	
	# 获取主题（Theme）
	var theme = ThemeDB.get_project_theme()
	
	# 检查主题是否有效
	if not theme:
		printerr("Error: Cannot apply global font, project theme is not loaded")
		return
	
	# 对每种控件类型应用字体
	for type in control_types:
		# 尝试设置字体资源
		theme.set_font("font", type, font_resource)
		
		# 根据控件类型设置字体大小
		var size_type = "label"
		if type.to_lower() == "button": size_type = "button"
		if type.to_lower() == "richtextlabel": size_type = "dialog"
		if type.to_lower() == "textedit": size_type = "text"
		
		var font_size = get_font_size(size_type)
		theme.set_font_size("font_size", type, font_size)
	
	# 对当前场景树应用字体
	var root = get_tree().get_root()
	apply_font_to_scene_tree(root)
	
	print("Global font applied with size factor: ", factor)

# 保存设置
func save_settings():
	var file = FileAccess.open(SETTINGS_FILE, FileAccess.WRITE)
	if file:
		var settings = {
			"font_size": current_size
		}
		var json_string = JSON.stringify(settings)
		file.store_string(json_string)
		file.close()
		print("Font settings saved")
	else:
		printerr("Error: Cannot save font settings")

# 加载设置
func load_settings():
	if FileAccess.file_exists(SETTINGS_FILE):
		var file = FileAccess.open(SETTINGS_FILE, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			
			var json_result = JSON.parse_string(content)
			if json_result != null and json_result.has("font_size"):
				current_size = json_result["font_size"]
				print("Font settings loaded, size: ", size_to_string(current_size))
	else:
		print("No font settings found, using defaults")

# 应用字体到控件
func apply_font_to_control(control):
	# 检查控件和字体资源是否有效
	if not is_instance_valid(control) or not font_resource:
		return
		
	# 根据控件类型应用字体
	if control is Button:
		control.add_theme_font_override("font", font_resource)
		control.add_theme_font_size_override("font_size", get_font_size("button"))
	elif control is Label:
		control.add_theme_font_override("font", font_resource)
		control.add_theme_font_size_override("font_size", get_font_size("label"))
	elif control is RichTextLabel:
		control.add_theme_font_override("normal_font", font_resource)
		control.add_theme_font_override("bold_font", font_resource)
		control.add_theme_font_override("italics_font", font_resource)
		control.add_theme_font_override("bold_italics_font", font_resource)
		
		control.add_theme_font_size_override("normal_font_size", get_font_size("dialog"))
		control.add_theme_font_size_override("bold_font_size", get_font_size("dialog"))
		control.add_theme_font_size_override("italics_font_size", get_font_size("dialog"))
		control.add_theme_font_size_override("bold_italics_font_size", get_font_size("dialog"))
		
		# 设置行间距
		var line_spacing = int(get_font_size("dialog") * 0.3)
		control.add_theme_constant_override("line_separation", line_spacing)
	elif control is LineEdit:
		control.add_theme_font_override("font", font_resource)
		control.add_theme_font_size_override("font_size", get_font_size("label"))
	elif control is TextEdit:
		control.add_theme_font_override("font", font_resource)
		control.add_theme_font_size_override("font_size", get_font_size("text"))

# 应用字体到场景树
func apply_font_to_scene_tree(node):
	# 递归遍历所有子节点
	for child in node.get_children():
		# 为当前节点应用字体
		apply_font_to_control(child)
		
		# 递归处理子节点
		if child.get_child_count() > 0:
			apply_font_to_scene_tree(child)

# 获取当前字体资源
func get_font():
	if not font_resource:
		# 尝试加载字体资源
		font_resource = load(FONT_PATH)
		if not font_resource:
			printerr("Error: Failed to load font from ", FONT_PATH)
			# 返回默认字体或null
			return null
	return font_resource 

# 获取当前所有元素的字体大小
func get_current_sizes():
	var factor = get_size_factor()
	var sizes = {}
	
	# 计算每种类型的实际大小
	for key in base_sizes.keys():
		sizes[key] = int(base_sizes[key] * factor)
	
	return sizes 

# 获取当前字体大小名称
func get_current_size_name():
	return size_to_string(current_size) 

# 方便从任何场景打开字体设置UI
func open_settings():
	print("打开字体设置UI")
	
	# 检查是否已经有设置UI实例
	var settings_ui = get_tree().get_root().get_node_or_null("FontSettingsUI")
	
	if settings_ui:
		settings_ui.visible = true
		return
	
	# 实例化设置UI场景
	var font_settings_scene = load("res://scenes/ui/font_settings_ui.tscn")
	if font_settings_scene:
		settings_ui = font_settings_scene.instantiate()
		settings_ui.name = "FontSettingsUI"
		get_tree().get_root().add_child(settings_ui)
		settings_ui.visible = true
	else:
		printerr("Error: 无法加载字体设置UI场景文件")
		_create_fallback_ui()

# 为特定场景提供的便捷应用方法
func apply_to_scene(scene_node):
	if not is_instance_valid(scene_node):
		return
	
	print("对特定场景应用字体: ", scene_node.name)
	apply_font_to_scene_tree(scene_node)

# 创建备用UI（当无法加载场景时）
func _create_fallback_ui():
	print("创建备用UI")
	var fallback_ui = Control.new()
	fallback_ui.name = "FontSettingsUI_Fallback"
	
	# 添加基本UI元素
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var label = Label.new()
	label.text = "字体设置界面加载失败，请确保场景文件存在"
	label.set_anchors_preset(Control.PRESET_CENTER)
	
	var close_button = Button.new()
	close_button.text = "关闭"
	close_button.position = Vector2(label.position.x, label.position.y + 50)
	close_button.pressed.connect(func(): fallback_ui.queue_free())
	
	fallback_ui.add_child(panel)
	fallback_ui.add_child(label)
	fallback_ui.add_child(close_button)
	
	get_tree().get_root().add_child(fallback_ui)
	print("添加了备用UI") 
