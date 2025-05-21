extends Node

# 参考分辨率
const REFERENCE_RESOLUTION = Vector2(1920, 1080)

# 获取当前窗口大小相对于参考分辨率的缩放因子
static func get_scale_factor() -> Vector2:
	var viewport_size = Engine.get_main_loop().get_root().get_viewport().get_visible_rect().size
	
	var scale_x = viewport_size.x / REFERENCE_RESOLUTION.x
	var scale_y = viewport_size.y / REFERENCE_RESOLUTION.y
	var scale = min(scale_x, scale_y)
	
	return Vector2(scale, scale)

# 将相对位置转换为实际位置
static func ratio_to_position(ratio_position: Vector2) -> Vector2:
	return Vector2(
		REFERENCE_RESOLUTION.x * ratio_position.x,
		REFERENCE_RESOLUTION.y * ratio_position.y
	)

# 将相对大小转换为实际大小
static func ratio_to_size(ratio_size: Vector2) -> Vector2:
	return Vector2(
		REFERENCE_RESOLUTION.x * ratio_size.x,
		REFERENCE_RESOLUTION.y * ratio_size.y
	)

# 根据实际位置获取相对位置比例
static func position_to_ratio(position: Vector2) -> Vector2:
	return Vector2(
		position.x / REFERENCE_RESOLUTION.x,
		position.y / REFERENCE_RESOLUTION.y
	)

# 根据实际大小获取相对大小比例
static func size_to_ratio(size: Vector2) -> Vector2:
	return Vector2(
		size.x / REFERENCE_RESOLUTION.x,
		size.y / REFERENCE_RESOLUTION.y
	)

# 获取UI元素应该设置的位置，考虑了缩放因素
static func get_scaled_position(ratio_position: Vector2) -> Vector2:
	var base_position = ratio_to_position(ratio_position)
	var scale_factor = get_scale_factor()
	return base_position * scale_factor

# 获取UI元素应该设置的大小，考虑了缩放因素
static func get_scaled_size(ratio_size: Vector2) -> Vector2:
	var base_size = ratio_to_size(ratio_size)
	var scale_factor = get_scale_factor()
	return base_size * scale_factor

# 计算基于父节点大小的相对位置
static func parent_relative_position(parent_size: Vector2, ratio_position: Vector2) -> Vector2:
	return Vector2(
		parent_size.x * ratio_position.x,
		parent_size.y * ratio_position.y
	)

# 计算基于父节点大小的相对尺寸
static func parent_relative_size(parent_size: Vector2, ratio_size: Vector2) -> Vector2:
	return Vector2(
		parent_size.x * ratio_size.x,
		parent_size.y * ratio_size.y
	) 
