# WeekendPlayerManager - 周末玩家管理器
# 处理周末场景中玩家的卡片界面显示逻辑
extends RefCounted
class_name WeekendPlayerManager

# 信号定义
signal card_bar_opened  # 卡片侧边栏打开
signal card_bar_closed  # 卡片侧边栏关闭

# 卡片侧边栏状态
var is_card_bar_opened: bool = false

# 主场景引用
var main_scene: Control

# 初始化
func _init():
	print("WeekendPlayerManager: 周末玩家管理器已初始化")

# 设置主场景引用
func set_main_scene(scene: Control):
	main_scene = scene

# 显示卡片侧边栏
func show_card_bar():
	if main_scene and not is_card_bar_opened:
		main_scene.set_card_side_visibility(true, true)
		is_card_bar_opened = true
		card_bar_opened.emit()
		print("WeekendPlayerManager: 卡片侧边栏已显示")

# 隐藏卡片侧边栏
func hide_card_bar():
	if main_scene and is_card_bar_opened:
		main_scene.set_card_side_visibility(false, false)
		is_card_bar_opened = false
		card_bar_closed.emit()
		print("WeekendPlayerManager: 卡片侧边栏已隐藏")

# 切换卡片侧边栏显示状态
func toggle_card_bar():
	if is_card_bar_opened:
		hide_card_bar()
	else:
		show_card_bar()

# 获取卡片侧边栏状态
func get_card_bar_status() -> bool:
	return is_card_bar_opened 