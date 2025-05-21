extends Node

# 参考分辨率
const REFERENCE_RESOLUTION = Vector2(1920, 1080)

# 获取缩放因子
static func get_scale_factor():
	var viewport_size = Engine.get_main_loop().root.get_viewport().get_visible_rect().size
	
	var scale_x = viewport_size.x / REFERENCE_RESOLUTION.x
	var scale_y = viewport_size.y / REFERENCE_RESOLUTION.y
	var scale = min(scale_x, scale_y)
	
	return Vector2(scale, scale)

# 将相对位置转换为实际位置
static func ratio_to_position(ratio_position):
	return Vector2(
		REFERENCE_RESOLUTION.x * ratio_position.x,
		REFERENCE_RESOLUTION.y * ratio_position.y
	)

# 将相对大小转换为实际大小
static func ratio_to_size(ratio_size):
	return Vector2(
		REFERENCE_RESOLUTION.x * ratio_size.x,
		REFERENCE_RESOLUTION.y * ratio_size.y
	)

# 计算位置以使元素居中
static func center_position(element_size, viewport_size = null):
	if viewport_size == null:
		viewport_size = Engine.get_main_loop().root.get_viewport().get_visible_rect().size
	
	return Vector2(
		(viewport_size.x - element_size.x) / 2,
		(viewport_size.y - element_size.y) / 2
	)

# 应用缩放因子到位置
static func scale_position(position, scale_factor):
	return Vector2(
		position.x * scale_factor.x,
		position.y * scale_factor.y
	)

# 应用缩放因子到大小
static func scale_size(size, scale_factor):
	return Vector2(
		size.x * scale_factor.x,
		size.y * scale_factor.y
	)

# 保持比例的同时调整元素到视口
static func fit_to_viewport(original_size, viewport_size = null):
	if viewport_size == null:
		viewport_size = Engine.get_main_loop().root.get_viewport().get_visible_rect().size
	
	var scale_x = viewport_size.x / original_size.x
	var scale_y = viewport_size.y / original_size.y
	var scale = min(scale_x, scale_y)
	
	var new_size = Vector2(original_size.x * scale, original_size.y * scale)
	var new_position = Vector2(
		(viewport_size.x - new_size.x) / 2,
		(viewport_size.y - new_size.y) / 2
	)
	
	return {
		"size": new_size,
		"position": new_position,
		"scale": scale
	} 