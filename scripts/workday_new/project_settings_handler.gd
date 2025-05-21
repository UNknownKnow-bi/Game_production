extends Node

# 参考分辨率
const REFERENCE_RESOLUTION = Vector2(1920, 1080)

# 窗口设置
const DEFAULT_WINDOW_SIZE = Vector2i(1920, 1080)
const MIN_WINDOW_SIZE = Vector2i(800, 600)

# 使用非静态方法设置窗口标题（更安全）
func set_window_title(title):
	if Engine.get_main_loop() and Engine.get_main_loop().root and Engine.get_main_loop().root.get_window():
		Engine.get_main_loop().root.get_window().title = title
	else:
		# 如果场景树尚未初始化，则使用DisplayServer（可能需要在场景加载后再次设置）
		if DisplayServer.has_method("window_set_title"):
			# 尝试使用DisplayServer.window_set_title，如果可用
			DisplayServer.window_set_title(title, DisplayServer.MAIN_WINDOW_ID)
		print("警告：窗口标题将在加载后应用")

# 使用非静态方法获取窗口标题（更安全）
func get_window_title():
	if Engine.get_main_loop() and Engine.get_main_loop().root and Engine.get_main_loop().root.get_window():
		return Engine.get_main_loop().root.get_window().title
	# 如果无法获取标题，返回空字符串
	return ""

# 应用推荐的项目设置
static func apply_recommended_settings():
	# 创建一个实例来调用非静态方法
	var settings = load("res://scripts/workday_new/project_settings_handler.gd").new()
	
	# 设置窗口大小
	DisplayServer.window_set_size(DEFAULT_WINDOW_SIZE, DisplayServer.MAIN_WINDOW_ID)
	
	# 设置最小窗口大小
	DisplayServer.window_set_min_size(MIN_WINDOW_SIZE, DisplayServer.MAIN_WINDOW_ID)
	
	# 允许窗口调整大小
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false, DisplayServer.MAIN_WINDOW_ID)
	
	# 设置窗口标题
	settings.set_window_title("工作日模拟器")
	
	# 设置窗口居中
	var screen_size = DisplayServer.screen_get_size()
	var window_position = (screen_size - DEFAULT_WINDOW_SIZE) / 2
	DisplayServer.window_set_position(window_position, DisplayServer.MAIN_WINDOW_ID)
	
	print("已应用推荐的项目设置")
	settings.free()

# 应用自定义设置
static func apply_custom_settings(window_size = DEFAULT_WINDOW_SIZE, window_title = "工作日模拟器"):
	# 创建一个实例来调用非静态方法
	var settings = load("res://scripts/workday_new/project_settings_handler.gd").new()
	
	# 设置窗口大小
	DisplayServer.window_set_size(window_size, DisplayServer.MAIN_WINDOW_ID)
	
	# 设置窗口标题
	settings.set_window_title(window_title)
	
	# 设置窗口居中
	var screen_size = DisplayServer.screen_get_size()
	var window_position = (screen_size - window_size) / 2
	DisplayServer.window_set_position(window_position, DisplayServer.MAIN_WINDOW_ID)
	
	print("已应用自定义设置")
	settings.free()

# 检查并应用必要的设置
static func check_and_apply_settings():
	# 创建一个实例来调用非静态方法
	var settings = load("res://scripts/workday_new/project_settings_handler.gd").new()
	
	var current_size = DisplayServer.window_get_size(DisplayServer.MAIN_WINDOW_ID)
	# 获取窗口标题
	var current_title = settings.get_window_title()
	
	var settings_need_update = false
	
	# 检查窗口大小
	if current_size.x < MIN_WINDOW_SIZE.x or current_size.y < MIN_WINDOW_SIZE.y:
		settings_need_update = true
	
	# 检查窗口标题
	if current_title != "工作日模拟器" and current_title != "":
		settings_need_update = true
	
	# 应用设置（如有必要）
	if settings_need_update:
		apply_recommended_settings()
	
	var result = settings_need_update
	settings.free()
	return result

# 切换全屏模式
static func toggle_fullscreen():
	var is_fullscreen = DisplayServer.window_get_mode(DisplayServer.MAIN_WINDOW_ID) == DisplayServer.WINDOW_MODE_FULLSCREEN
	
	if is_fullscreen:
		# 切换到窗口模式
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, DisplayServer.MAIN_WINDOW_ID)
		DisplayServer.window_set_size(DEFAULT_WINDOW_SIZE, DisplayServer.MAIN_WINDOW_ID)
		
		# 居中窗口
		var screen_size = DisplayServer.screen_get_size()
		var window_position = (screen_size - DEFAULT_WINDOW_SIZE) / 2
		DisplayServer.window_set_position(window_position, DisplayServer.MAIN_WINDOW_ID)
		
		print("已切换到窗口模式")
	else:
		# 切换到全屏模式
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.MAIN_WINDOW_ID)
		print("已切换到全屏模式")
	
	return !is_fullscreen  # 返回切换后的全屏状态 
