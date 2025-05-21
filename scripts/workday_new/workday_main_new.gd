extends Node2D

# 预加载需要的脚本
const ResponsiveLayout = preload("res://scripts/workday_new/responsive_layout_new.gd")
const WindowSettings = preload("res://scripts/workday_new/project_settings_handler.gd")

# 节点引用
@onready var background = $Background
@onready var card_side_layer = $CardSideLayer
@onready var content_layer = $ContentLayer
@onready var ui_layer = $UILayer
@onready var ui_controller = $UILayer/UIController

# 可交互元素引用
@onready var card_side_char = $CardSideLayer/CardSideChar
@onready var card_side_others = $CardSideLayer/CardSideOthers
@onready var rabbit_icon = $UILayer/RabbitIcon
@onready var beer_icon = $UILayer/BeerIcon
@onready var cup_icon = $UILayer/CupIcon
@onready var pc = $ContentLayer/PC

# 添加事件系统引用
@onready var event_system = $ContentLayer/EventSystem

# 游戏状态
var is_fullscreen = false

func _ready():
	# 应用推荐的项目设置
	WindowSettings.apply_recommended_settings()
	
	# 初始化主场景
	print("新工作日场景已加载")
	
	# 确保节点层级顺序
	background.z_index = 0
	card_side_layer.z_index = 1
	content_layer.z_index = 2
	# UILayer已自动置顶，无需设置z_index
	
	# 连接可交互元素信号
	connect_interactive_elements()
	
	# 设置键盘快捷键
	set_process_input(true)
	
	# 初始化事件系统
	initialize_event_system()
	
	# 添加简单的窗口大小变化处理
	get_tree().get_root().size_changed.connect(Callable(self, "_on_window_size_changed_simple"))
	_on_window_size_changed_simple()

# 设置所有元素的固定位置和大小
func set_fixed_positions():
	# 背景位置固定
	var background_sprite = $Background/MainBackground
	if background_sprite:
		background_sprite.position = Vector2(960, 540)  # 居中
	
	# PC位置固定
	if pc:
		pc.position = Vector2(960, 540)  # 居中
	
	# Card Side元素固定位置和大小
	if card_side_char:
		card_side_char.position = Vector2(135, 143)
		card_side_char.size = Vector2(240, 800)
	
	if card_side_others:
		card_side_others.position = Vector2(1545, 143)
		card_side_others.size = Vector2(240, 800)
	
	# 图标固定位置和大小
	if rabbit_icon:
		rabbit_icon.position = Vector2(1720, 50)
		rabbit_icon.size = Vector2(100, 100)
	
	if beer_icon:
		beer_icon.position = Vector2(1600, 50)
		beer_icon.size = Vector2(100, 100)
	
	if cup_icon:
		cup_icon.position = Vector2(1480, 50)
		cup_icon.size = Vector2(100, 100)

# 打印当前元素位置和大小(用于调试)
func debug_print_positions():
	# 打印背景位置
	var background_sprite = $Background/MainBackground
	if background_sprite:
		print("背景位置: ", background_sprite.position, " 缩放: ", background_sprite.scale)
	
	# 打印PC位置
	if pc:
		print("PC位置: ", pc.position, " 缩放: ", pc.scale)
	
	# 打印Card Side元素位置和大小
	if card_side_char:
		print("角色卡位置: ", card_side_char.position, " 大小: ", card_side_char.size)
	
	if card_side_others:
		print("其他卡位置: ", card_side_others.position, " 大小: ", card_side_others.size)
	
	# 打印图标位置和大小
	if rabbit_icon:
		print("Rabbit图标位置: ", rabbit_icon.position, " 大小: ", rabbit_icon.size)
	
	if beer_icon:
		print("Beer图标位置: ", beer_icon.position, " 大小: ", beer_icon.size)
	
	if cup_icon:
		print("Cup图标位置: ", cup_icon.position, " 大小: ", cup_icon.size)

# 处理键盘输入
func _input(event):
	# F11切换全屏模式
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		is_fullscreen = WindowSettings.toggle_fullscreen()
		_on_window_size_changed_simple()  # 更新缩放
	
	# Esc键退出全屏
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and is_fullscreen:
		is_fullscreen = WindowSettings.toggle_fullscreen()
		_on_window_size_changed_simple()  # 更新缩放
	
	# F12打印所有元素位置（仅调试用）
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		print("========== 调试信息：当前元素位置 ==========")
		debug_print_positions()
		print("==========================================")

# 简单的全局缩放处理
func _on_window_size_changed_simple():
	# 获取当前窗口大小
	var viewport_size = get_viewport_rect().size
	var reference_resolution = Vector2(1920, 1080)  # 参考分辨率
	var target_ratio = reference_resolution.x / reference_resolution.y
	var viewport_ratio = viewport_size.x / viewport_size.y
	
	# 重置变换
	scale = Vector2(1, 1)
	position = Vector2(0, 0)
	
	if viewport_ratio >= target_ratio:
		# 窗口比场景更宽
		var scale_factor = viewport_size.y / reference_resolution.y
		scale = Vector2(scale_factor, scale_factor)
		position = Vector2((viewport_size.x - (reference_resolution.x * scale_factor)) / 2, 0)
	else:
		# 窗口比场景更高
		var scale_factor = viewport_size.x / reference_resolution.x
		scale = Vector2(scale_factor, scale_factor)
		position = Vector2(0, (viewport_size.y - (reference_resolution.y * scale_factor)) / 2)
	
	print("窗口大小变化: %dx%d, 缩放: %.2f" % [viewport_size.x, viewport_size.y, scale.x])
	
	# 如果事件系统存在，应用相同的缩放
	if event_system:
		# 事件系统已经是场景的子节点，会自动继承缩放
		pass
	
	# 可选：打印当前元素位置（调试用）
	# debug_print_positions()

func connect_interactive_elements():
	# 连接Rabbit图标信号
	if rabbit_icon:
		rabbit_icon.pressed.connect(_on_rabbit_icon_pressed)
		rabbit_icon.mouse_entered.connect(_on_rabbit_icon_mouse_entered)
		rabbit_icon.mouse_exited.connect(_on_rabbit_icon_mouse_exited)
	
	# 连接Card Side Char信号
	if card_side_char:
		card_side_char.pressed.connect(_on_card_side_char_pressed)
		card_side_char.mouse_entered.connect(_on_card_side_char_mouse_entered)
		card_side_char.mouse_exited.connect(_on_card_side_char_mouse_exited)
	
	# 连接Card Side Others信号
	if card_side_others:
		card_side_others.pressed.connect(_on_card_side_others_pressed)
		card_side_others.mouse_entered.connect(_on_card_side_others_mouse_entered)
		card_side_others.mouse_exited.connect(_on_card_side_others_mouse_exited)
	
	# 连接Beer图标信号
	if beer_icon:
		beer_icon.pressed.connect(_on_beer_icon_pressed)
		beer_icon.mouse_entered.connect(_on_beer_icon_mouse_entered)
		beer_icon.mouse_exited.connect(_on_beer_icon_mouse_exited)
	
	# 连接Cup图标信号
	if cup_icon:
		cup_icon.pressed.connect(_on_cup_icon_pressed)
		cup_icon.mouse_entered.connect(_on_cup_icon_mouse_entered)
		cup_icon.mouse_exited.connect(_on_cup_icon_mouse_exited)

# 处理交互元素事件
func _on_rabbit_icon_pressed():
	print("点击了Rabbit图标")
	if ui_controller:
		ui_controller.handle_rabbit_interaction()

func _on_rabbit_icon_mouse_entered():
	# 鼠标悬停效果
	rabbit_icon.modulate = Color(1.2, 1.2, 1.2, 1.0)

func _on_rabbit_icon_mouse_exited():
	# 如果没有激活，则恢复正常颜色
	if ui_controller and not ui_controller.is_rabbit_active:
		rabbit_icon.modulate = Color(1.0, 1.0, 1.0, 1.0)

# Card Side Char事件处理
func _on_card_side_char_pressed():
	print("点击了Card Side Char")
	if ui_controller:
		ui_controller.handle_card_side_char_interaction()

func _on_card_side_char_mouse_entered():
	# 鼠标悬停效果
	card_side_char.modulate = Color(1.2, 1.2, 1.2, 1.0)

func _on_card_side_char_mouse_exited():
	# 如果没有激活，则恢复正常颜色
	if ui_controller and not ui_controller.is_card_char_active:
		card_side_char.modulate = Color(1.0, 1.0, 1.0, 1.0)

# Card Side Others事件处理
func _on_card_side_others_pressed():
	print("点击了Card Side Others")
	if ui_controller:
		ui_controller.handle_card_side_others_interaction()

func _on_card_side_others_mouse_entered():
	# 鼠标悬停效果
	card_side_others.modulate = Color(1.2, 1.2, 1.2, 1.0)

func _on_card_side_others_mouse_exited():
	# 如果没有激活，则恢复正常颜色
	if ui_controller and not ui_controller.is_card_others_active:
		card_side_others.modulate = Color(1.0, 1.0, 1.0, 1.0)

# Beer图标事件处理
func _on_beer_icon_pressed():
	print("点击了Beer图标")
	if ui_controller:
		ui_controller.handle_beer_interaction()

func _on_beer_icon_mouse_entered():
	# 鼠标悬停效果
	beer_icon.modulate = Color(1.2, 1.2, 1.2, 1.0)

func _on_beer_icon_mouse_exited():
	# 如果没有激活，则恢复正常颜色
	if ui_controller and not ui_controller.is_beer_active:
		beer_icon.modulate = Color(1.0, 1.0, 1.0, 1.0)

# Cup图标事件处理
func _on_cup_icon_pressed():
	print("点击了Cup图标")
	if ui_controller:
		ui_controller.handle_cup_interaction()

func _on_cup_icon_mouse_entered():
	# 鼠标悬停效果
	cup_icon.modulate = Color(1.2, 1.2, 1.2, 1.0)

func _on_cup_icon_mouse_exited():
	# 如果没有激活，则恢复正常颜色
	if ui_controller and not ui_controller.is_cup_active:
		cup_icon.modulate = Color(1.0, 1.0, 1.0, 1.0)

# 重置所有交互
func reset_all_interactions():
	if ui_controller:
		ui_controller.reset_all_interactions() 

# 添加事件系统初始化函数
func initialize_event_system():
	if not event_system:
		printerr("事件系统未找到")
		return
	
	# 检查EventManager是否存在
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		printerr("EventManager not found in autoload nodes")
		return
	
	# 记录初始CardContainer位置(用于调试)
	print("==== 初始化事件系统前的CardContainer位置 ====")
	_log_card_container_positions()
	
	# 加载事件数据
	event_manager.load_events_from_tsv("res://data/events/sample_events.tsv")
	
	# 更新可用事件
	event_manager.update_available_events()
	
	# 连接事件系统的面板信号
	_connect_event_panel_signals()
	
	# 加载保存的布局（如果有）
	load_event_system_layout()
	
	# 确保事件系统更新函数被调用（以显示样本事件卡片）
	print("触发事件系统更新，将显示样本事件卡片...")
	if event_system.has_method("_on_events_updated"):
		event_system._on_events_updated()
		
		# 延迟一帧，确保所有更新都应用完毕
		await get_tree().process_frame
		
		# 手动检查卡片是否创建
		_check_event_cards()
	
	# 记录最终CardContainer位置(用于调试)
	print("==== 初始化事件系统后的CardContainer位置 ====")
	_log_card_container_positions()
	
	print("事件系统已初始化")

# 连接事件面板信号
func _connect_event_panel_signals():
	if event_system:
		var left_panel = event_system.get_node_or_null("LeftPanel")
		var middle_panel = event_system.get_node_or_null("MiddlePanel")
		var right_panel = event_system.get_node_or_null("RightPanel")
		
		if left_panel and not left_panel.panel_clicked.is_connected(_on_character_event_panel_clicked):
			left_panel.panel_clicked.connect(_on_character_event_panel_clicked)
		
		if middle_panel and not middle_panel.panel_clicked.is_connected(_on_random_event_panel_clicked):
			middle_panel.panel_clicked.connect(_on_random_event_panel_clicked)
		
		if right_panel and not right_panel.panel_clicked.is_connected(_on_daily_event_panel_clicked):
			right_panel.panel_clicked.connect(_on_daily_event_panel_clicked)

# 处理角色事件面板点击
func _on_character_event_panel_clicked():
	_handle_event_panel_click("character")

# 处理随机事件面板点击
func _on_random_event_panel_clicked():
	_handle_event_panel_click("random")

# 处理日常事件面板点击
func _on_daily_event_panel_clicked():
	_handle_event_panel_click("daily")

# 通用事件面板点击处理
func _handle_event_panel_click(category: String):
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		return
	
	var active_events = event_manager.get_active_events(category)
	if active_events.is_empty():
		print("没有可用的%s" % event_manager.get_category_display_name(category))
		return
	
	# 获取第一个事件
	var event = active_events[0]
	print("处理%s: %s" % [category, event.event_name])
	
	# 显示事件弹窗
	_show_event_popup(event)

# 显示事件弹窗
func _show_event_popup(event):
	# 检查是否已存在事件弹窗
	var popup = get_node_or_null("EventPopup")
	if not popup:
		# 加载并实例化事件弹窗
		var popup_scene = load("res://scenes/workday_new/components/event_popup.tscn")
		if popup_scene:
			popup = popup_scene.instantiate()
			popup.name = "EventPopup"
			add_child(popup)
			popup.option_selected.connect(_on_event_option_selected)
	
	if popup:
		# 准备事件数据
		var event_data = {
			"event_id": event.event_id,
			"title": event.event_name,
			"description": event.get_description(),
			"image_path": event.background_path if not event.background_path.is_empty() else "",
			"has_reject_option": true  # 可以从事件数据中决定
		}
		
		# 显示事件弹窗
		popup.show_event(event_data)

# 处理事件选项选择
func _on_event_option_selected(option_id: int, event_id: int):
	print("选择了事件选项: ", option_id, " 事件ID: ", event_id)
	
	# 根据选项处理事件结果
	var event_manager = get_node_or_null("/root/EventManager")
	if event_manager:
		# 可以添加事件结果处理逻辑
		pass

# 保存事件系统布局
func save_event_system_layout():
	if not event_system or not event_system.is_initialized:
		return
	
	var layout = event_system.save_panels_layout()
	
	# 这里可以将布局保存到配置文件
	# 暂时只打印信息
	print("保存事件系统布局: ", layout)
	
	# 示例：将布局保存到用户数据目录
	# var config = ConfigFile.new()
	# config.set_value("event_system", "layout", layout)
	# config.save("user://event_system_layout.cfg")

# 加载事件系统布局
func load_event_system_layout():
	if not event_system:
		return
	
	# 这里可以从配置文件加载布局
	# 暂时使用默认布局
	print("加载事件系统默认布局")
	
	# 示例：从用户数据目录加载布局
	# var config = ConfigFile.new()
	# var err = config.load("user://event_system_layout.cfg")
	# if err == OK:
	#     var layout = config.get_value("event_system", "layout", {})
	#     event_system.load_panels_layout(layout)

# 在场景退出前保存布局
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		save_event_system_layout()

# 记录CardContainer位置的辅助函数
func _log_card_container_positions():
	if not event_system:
		return
		
	var left_panel = event_system.get_node_or_null("LeftPanel")
	var middle_panel = event_system.get_node_or_null("MiddlePanel")
	var right_panel = event_system.get_node_or_null("RightPanel")
	
	if left_panel:
		var container = left_panel.get_node_or_null("CardContainer")
		if container:
			print("Left Panel CardContainer - 位置: ", container.position, " 大小: ", container.size, " 子节点数: ", container.get_child_count(), " 可见性: ", container.visible)
	
	if middle_panel:
		var container = middle_panel.get_node_or_null("CardContainer")
		if container:
			print("Middle Panel CardContainer - 位置: ", container.position, " 大小: ", container.size, " 子节点数: ", container.get_child_count())
	
	if right_panel:
		var container = right_panel.get_node_or_null("CardContainer")
		if container:
			print("Right Panel CardContainer - 位置: ", container.position, " 大小: ", container.size, " 子节点数: ", container.get_child_count())

# 检查事件卡片是否创建
func _check_event_cards():
	if not event_system:
		return
		
	var left_panel = event_system.get_node_or_null("LeftPanel")
	if left_panel:
		print("Left Panel - 事件卡片数量: ", left_panel.event_cards.size())
		
		# 如果没有卡片，尝试手动创建
		if left_panel.event_cards.size() == 0:
			print("左侧面板无卡片，手动创建样本卡片...")
			left_panel.create_sample_event_cards(4)
			
			# 确保卡片容器可见
			var container = left_panel.get_node_or_null("CardContainer")
			if container:
				container.visible = true
				print("卡片容器设置为可见状态")
		else:
			print("左侧面板已有卡片，数量: ", left_panel.event_cards.size())
			
			# 检查每张卡片的状态
			for i in range(left_panel.event_cards.size()):
				var card = left_panel.event_cards[i]
				print("卡片 #", i+1, " - 标题: ", card.event_title, " 尺寸: ", card.size)
