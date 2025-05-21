extends Node

# 参考分辨率
const REFERENCE_RESOLUTION = Vector2(1920, 1080)

# 当节点添加到场景树时运行
func _ready():
	# 检查并设置项目显示设置
	verify_project_settings()
	
	# 打印验证消息
	print("项目设置验证完成")
	print("当前分辨率: ", DisplayServer.window_get_size())
	print("设计分辨率: ", REFERENCE_RESOLUTION)

# 验证并调整项目设置
func verify_project_settings():
	# 检查显示设置
	var current_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var current_height = ProjectSettings.get_setting("display/window/size/viewport_height")
	var current_stretch_mode = ProjectSettings.get_setting("display/window/stretch/mode")
	
	# 检查窗口尺寸是否与参考分辨率一致
	if current_width != REFERENCE_RESOLUTION.x or current_height != REFERENCE_RESOLUTION.y:
		print("警告: 当前设计分辨率 (%d x %d) 与参考分辨率 (%d x %d) 不匹配" % 
			[current_width, current_height, REFERENCE_RESOLUTION.x, REFERENCE_RESOLUTION.y])
		
		# 调整项目设置（仅在编辑器运行时生效，不会永久保存）
		if Engine.is_editor_hint():
			print("在编辑器中更新分辨率设置...")
			ProjectSettings.set_setting("display/window/size/viewport_width", REFERENCE_RESOLUTION.x)
			ProjectSettings.set_setting("display/window/size/viewport_height", REFERENCE_RESOLUTION.y)
			ProjectSettings.save()
	
	# 检查伸缩模式
	if current_stretch_mode != "viewport":
		print("警告: 当前伸缩模式 '%s' 不是 'viewport'" % current_stretch_mode)
		
		# 调整项目设置（仅在编辑器运行时生效，不会永久保存）
		if Engine.is_editor_hint():
			print("在编辑器中更新伸缩模式...")
			ProjectSettings.set_setting("display/window/stretch/mode", "viewport")
			ProjectSettings.save()

# 获取当前窗口大小与参考分辨率的比例
func get_scale_ratio() -> Vector2:
	var current_size = DisplayServer.window_get_size()
	return Vector2(
		float(current_size.x) / REFERENCE_RESOLUTION.x,
		float(current_size.y) / REFERENCE_RESOLUTION.y
	)

# 获取窗口比例因子（取宽高比例的较小值以保持UI不会超出屏幕）
func get_uniform_scale_factor() -> float:
	var ratio = get_scale_ratio()
	return min(ratio.x, ratio.y) 