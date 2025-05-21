extends Control

# 参考分辨率
const REFERENCE_RESOLUTION = Vector2(1920, 1080)

# 缩放模式: "keep_width", "keep_height", "keep_aspect"
@export var stretch_mode: String = "keep_aspect"

# 自动应用缩放
@export var auto_scale: bool = true

func _ready():
	# 设置最小大小为参考分辨率
	custom_minimum_size = REFERENCE_RESOLUTION
	
	# 连接窗口大小变化信号
	get_tree().get_root().size_changed.connect(Callable(self, "_on_window_size_changed"))
	
	# 初始调整
	if auto_scale:
		_on_window_size_changed()

# 窗口大小变化回调
func _on_window_size_changed():
	var viewport_size = get_viewport_rect().size
	var scale_factor = calculate_scale_factor(viewport_size)
	apply_scale(scale_factor)
	
	# 调整位置以保持居中
	position = (viewport_size - (REFERENCE_RESOLUTION * scale_factor)) / 2

# 计算缩放因子
func calculate_scale_factor(viewport_size: Vector2) -> Vector2:
	var scale_factor = Vector2.ONE
	
	match stretch_mode:
		"keep_width":
			# 保持宽度不变，高度自适应
			var scale_y = viewport_size.y / REFERENCE_RESOLUTION.y
			scale_factor = Vector2(scale_y, scale_y)
		"keep_height":
			# 保持高度不变，宽度自适应
			var scale_x = viewport_size.x / REFERENCE_RESOLUTION.x
			scale_factor = Vector2(scale_x, scale_x)
		"keep_aspect", _:
			# 保持宽高比，取较小值以确保内容完全显示
			var scale_x = viewport_size.x / REFERENCE_RESOLUTION.x
			var scale_y = viewport_size.y / REFERENCE_RESOLUTION.y
			var scale = min(scale_x, scale_y)
			scale_factor = Vector2(scale, scale)
	
	return scale_factor

# 应用缩放
func apply_scale(scale_factor: Vector2):
	# 设置节点缩放
	scale = scale_factor
	
	# 发出缩放变化信号，其他节点可以连接此信号
	scale_changed.emit(scale_factor)

# 缩放变化信号
signal scale_changed(scale_factor)

# 获取当前缩放因子
func get_current_scale() -> Vector2:
	return scale

# 将相对坐标转换为实际坐标
func ratio_to_position(ratio_position: Vector2) -> Vector2:
	return Vector2(
		REFERENCE_RESOLUTION.x * ratio_position.x,
		REFERENCE_RESOLUTION.y * ratio_position.y
	)

# 将相对大小转换为实际大小
func ratio_to_size(ratio_size: Vector2) -> Vector2:
	return Vector2(
		REFERENCE_RESOLUTION.x * ratio_size.x,
		REFERENCE_RESOLUTION.y * ratio_size.y
	) 