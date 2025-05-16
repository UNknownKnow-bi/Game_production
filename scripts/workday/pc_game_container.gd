extends Node2D

# 子节点引用
@onready var sub_viewport = $SubViewport
@onready var viewport_display = $ViewportDisplay

# 位置和大小
var default_position = Vector2(0, 0)
var default_size = Vector2(800, 600)

# 信号
signal content_loaded
signal content_unloaded

func _ready():
	# 初始化SubViewport
	sub_viewport.size = default_size
	sub_viewport.handle_input_locally = true
	sub_viewport.gui_disable_input = false
	
	# 设置黑色背景 - 使用ColorRect而不是尝试设置SubViewport属性
	# 创建一个黑色背景节点
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 1) # 纯黑色
	background.name = "Background"
	background.size = sub_viewport.size
	# 确保背景覆盖整个视口区域
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	# 添加到SubViewport作为第一个子节点
	sub_viewport.add_child(background)
	# 确保背景在最底层
	background.z_index = -100
	
	# 应用圆角Shader
	apply_rounded_corners()
	
	# 设置ViewportDisplay
	viewport_display.texture = sub_viewport.get_texture()
	viewport_display.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	viewport_display.stretch_mode = TextureRect.STRETCH_SCALE  # 不保持比例
	
	set_display_rect(default_position, default_size)

# 应用圆角Shader
func apply_rounded_corners():
	# 加载Shader资源
	var shader = load("res://shaders/rounded_corners.gdshader")
	if shader:
		# 创建ShaderMaterial
		var material = ShaderMaterial.new()
		material.shader = shader
		
		# 设置固定圆角半径
		material.set_shader_parameter("corner_radius", 8.0)
		
		# 应用到ViewportDisplay
		viewport_display.material = material

# 设置显示区域的位置和大小
func set_display_rect(position, size):
	viewport_display.position = position
	viewport_display.size = size
	
	# 更新SubViewport大小
	sub_viewport.size = Vector2i(size.x, size.y)
	
	# 更新背景大小
	var background = sub_viewport.get_node_or_null("Background")
	if background:
		background.size = Vector2(size.x, size.y)

# 加载内容到视窗中
func load_content(node):
	# 保存背景节点的引用
	var background = sub_viewport.get_node_or_null("Background")
	
	# 移除当前内容，但保留背景
	for child in sub_viewport.get_children():
		if child != background:
			child.queue_free()
	
	# 添加新内容
	if node:
		sub_viewport.add_child(node)
		# 确保内容在背景之上
		if background:
			background.z_index = -100
			node.z_index = 0
		emit_signal("content_loaded")

# 保存当前配置
func save_configuration():
	var config = {
		"position": viewport_display.position,
		"size": viewport_display.size
	}
	
	# 保存配置（可以使用ConfigFile或其他方式）
	# 这里简化为直接返回配置
	return config

# 加载配置
func load_configuration(config):
	if config.has("position"):
		default_position = config.position
	
	if config.has("size"):
		default_size = config.size
		sub_viewport.size = default_size
	
	set_display_rect(default_position, default_size)
