extends Control

# WeekendMain - 周末场景主脚本
# 处理周末场景的基础逻辑和UI更新

# 导入WeekendPlayerManager
const WeekendPlayerManager = preload("res://scripts/weekend/weekend_player_manager.gd")
# 预加载CardDisplayPanel场景
const CardDisplayPanelScene = preload("res://scenes/ui/card_display_panel.tscn")

# 特权卡系统组件引用
@onready var privilege_card_display = $UILayer/PrivilegeCardDisplay
@onready var card_draw_panel = $UILayer/CardDrawPanel
@onready var card_detail_panel = $UILayer/CardDetailPanel
@onready var simple_warning_popup = $UILayer/SimpleWarningPopup
@onready var event_popup = $UILayer/EventPopup
@onready var time_display = $UILayer/TimeDisplay
@onready var star_button = $UILayer/StarIcon
@onready var card_side_char: TextureButton = $CardSideLayer/CardSideChar
@onready var card_side_others: TextureButton = $CardSideLayer/CardSideOthers

# 日常事件热区系统组件引用
@onready var hotzone1 = $UILayer/DailyEventHotzone1
@onready var hotzone2 = $UILayer/DailyEventHotzone2
@onready var hotzone3 = $UILayer/DailyEventHotzone3
@onready var weekend_event_hotzone = $UILayer/WeekendEventHotzone4

# 热区管理器
var hotzone_manager: DailyEventHotzoneManager
var weekend_hotzone_manager: WeekendEventHotzoneManager

# 玩家管理器实例
var player_manager: WeekendPlayerManager

# CardDisplayPanel状态变量
var card_display_panel: Control = null

# 按钮交互状态
var is_card_char_active = false
var is_card_others_active = false

# 周末事件卡片系统
var weekend_test_events: Array[GameEvent] = []

func _ready():
	# 初始化玩家管理器
	player_manager = WeekendPlayerManager.new()
	player_manager.set_main_scene(self)
	
	# 连接玩家管理器信号
	player_manager.card_bar_opened.connect(_on_card_bar_opened)
	player_manager.card_bar_closed.connect(_on_card_bar_closed)
	
	# 连接信号
	card_side_char.pressed.connect(_on_card_side_char_pressed)
	card_side_char.mouse_entered.connect(_on_card_side_char_mouse_entered)
	card_side_char.mouse_exited.connect(_on_card_side_char_mouse_exited)
	card_side_others.pressed.connect(_on_card_side_others_pressed)
	card_side_others.mouse_entered.connect(_on_card_side_others_mouse_entered)
	card_side_others.mouse_exited.connect(_on_card_side_others_mouse_exited)
	
	_setup_privilege_card_system()
	_setup_star_button()
	_setup_daily_event_system()
	_setup_weekend_event_system()
	
	print("Weekend Main: 周末场景已加载")

# 初始化特权卡系统
func _setup_privilege_card_system():
	print("Weekend Main: 初始化特权卡系统")
	
	# 连接特权卡显示组件的信号
	if privilege_card_display:
		privilege_card_display.card_detail_requested.connect(_on_card_detail_requested)
		privilege_card_display.force_draw_requested.connect(_on_force_draw_requested)
		print("Weekend Main: 特权卡显示组件信号已连接")
	
	# 连接抽卡面板的信号
	if card_draw_panel:
		card_draw_panel.card_drawn.connect(_on_card_drawn)
		card_draw_panel.panel_closed.connect(_on_draw_panel_closed)
		card_draw_panel.force_draw_warning_requested.connect(_on_force_draw_warning_requested)
		print("Weekend Main: 抽卡面板信号已连接")
	
	# 连接卡片详情面板的信号
	if card_detail_panel:
		card_detail_panel.panel_closed.connect(_on_detail_panel_closed)
		card_detail_panel.draw_card_requested.connect(_on_draw_card_requested)
		print("Weekend Main: 卡片详情面板信号已连接")
	
	# 连接简单警告弹窗的信号
	if simple_warning_popup:
		simple_warning_popup.popup_closed.connect(_on_warning_popup_closed)
		print("Weekend Main: 简单警告弹窗信号已连接")
	
	# 连接事件弹窗的信号
	if event_popup:
		event_popup.option_selected.connect(_on_event_option_selected)
		event_popup.popup_closed.connect(_on_event_popup_closed)
		print("Weekend Main: 事件弹窗信号已连接")
	
	# 连接TimeManager信号
	if TimeManager:
		TimeManager.scene_type_changed.connect(_on_scene_type_changed)
		print("Weekend Main: TimeManager信号已连接")
	
	# 在所有信号连接完成后，手动触发特权卡显示更新
	if privilege_card_display:
		privilege_card_display.update_display()
		print("Weekend Main: 手动触发特权卡显示更新")

# 设置星形按钮
func _setup_star_button():
	print("Weekend Main: 初始化星形按钮")
	
	# 连接星形按钮信号
	if star_button:
		star_button.pressed.connect(_on_star_button_pressed)
		star_button.mouse_entered.connect(_on_star_button_mouse_entered)
		star_button.mouse_exited.connect(_on_star_button_mouse_exited)
		print("Weekend Main: 星形按钮信号已连接")

# 处理星形按钮点击事件
func _on_star_button_pressed():
	print("Weekend Main: 点击星形按钮，进入下一回合")
	
	# 推进回合 - TimeManager会自动发射scene_type_changed信号进行场景切换
	if TimeManager:
		TimeManager.advance_round()
		print("Weekend Main: 回合推进完成，等待TimeManager信号处理场景切换")
	else:
		print("Weekend Main: 错误 - TimeManager不存在")

# 处理星形按钮鼠标悬停事件
func _on_star_button_mouse_entered():
	if star_button:
		star_button.modulate = Color(1.2, 1.2, 1.2, 1.0)

# 处理星形按钮鼠标离开事件
func _on_star_button_mouse_exited():
	if star_button:
		star_button.modulate = Color(1.0, 1.0, 1.0, 1.0)

# 处理卡片详情请求
func _on_card_detail_requested():
	print("Weekend Main: 显示卡片详情面板")
	if card_detail_panel:
		card_detail_panel.show_panel()

# 处理强制抽卡请求
func _on_force_draw_requested():
	print("Weekend Main: 收到强制抽卡请求")
	if card_draw_panel:
		card_draw_panel.show_panel_forced()

# 处理卡片抽取完成
func _on_card_drawn(card_type: String):
	print("Weekend Main: 成功抽取卡片 - ", card_type)

# 处理抽卡面板关闭
func _on_draw_panel_closed():
	print("Weekend Main: 抽卡面板已关闭")

# 处理详情面板关闭
func _on_detail_panel_closed():
	print("Weekend Main: 详情面板已关闭")

# 处理抽卡请求
func _on_draw_card_requested():
	print("Weekend Main: 显示抽卡面板")
	if card_draw_panel:
		card_draw_panel.show_panel()

# 处理强制抽卡警告请求
func _on_force_draw_warning_requested():
	print("Weekend Main: 显示强制抽卡警告")
	_show_simple_warning("提示", "必须抽取一张特权卡才能继续")

# 处理警告弹窗关闭
func _on_warning_popup_closed():
	print("Weekend Main: 警告弹窗已关闭")

# 处理事件选项选择
func _on_event_option_selected(option_id: int, event_id: int):
	print("Weekend Main: 选择了事件选项: ", option_id, " 事件ID: ", event_id)
	
	# 获取EventManager
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		print("⚠ 错误: 无法找到EventManager")
		return
	
	# 标记事件为已完成
	event_manager.mark_event_completed(event_id)
	print("Weekend Main: 事件 ", event_id, " 已标记为完成")
	
	# 延迟验证事件完成后的状态
	call_deferred("_verify_event_completion_status", event_id)

# 处理事件弹窗关闭
func _on_event_popup_closed():
	print("Weekend Main: 事件弹窗已关闭")

# 验证事件完成后的状态
func _verify_event_completion_status(event_id: int):
	print("Weekend Main: 验证事件完成状态 - ID:", event_id)
	
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		print("⚠ Weekend Main: EventManager未找到，无法验证状态")
		return
	
	# 验证事件是否确实被标记为完成
	var is_completed = event_manager.is_event_completed(event_id)
	print("Weekend Main: 事件", event_id, "完成状态:", is_completed)
	
	# 强制刷新热区卡片状态
	if weekend_hotzone_manager:
		print("Weekend Main: 调用WeekendEventHotzoneManager状态更新")
		weekend_hotzone_manager.update_card_status_for_event(event_id)
		
		# 额外的全面状态刷新（确保所有卡片状态正确）
		call_deferred("_delayed_comprehensive_status_refresh")
	
	# 同时刷新daily热区卡片状态
	if hotzone_manager:
		print("Weekend Main: 调用DailyEventHotzoneManager状态更新")
		# 检查DailyEventHotzoneManager是否有相应的更新方法
		if hotzone_manager.has_method("update_card_status_for_event"):
			hotzone_manager.update_card_status_for_event(event_id)
		elif hotzone_manager.has_method("refresh_cards_status"):
			hotzone_manager.refresh_cards_status()

# 延迟的全面状态刷新
func _delayed_comprehensive_status_refresh():
	print("Weekend Main: 执行延迟的全面状态刷新")
	
	if weekend_hotzone_manager:
		weekend_hotzone_manager.sync_all_cards_with_event_manager()
		weekend_hotzone_manager.verify_cards_signal_connections()
	
	if hotzone_manager and hotzone_manager.has_method("sync_all_cards_with_event_manager"):
		hotzone_manager.sync_all_cards_with_event_manager()
	
	print("Weekend Main: 全面状态刷新完成")

# 显示简单警告弹窗
func _show_simple_warning(title: String = "提示", content: String = "必须抽取一张特权卡才能继续"):
	if simple_warning_popup:
		simple_warning_popup.show_warning(title, content)

# 处理场景类型变化
func _on_scene_type_changed(new_scene_type: String):
	print("Weekend Main: 场景类型变化到 ", new_scene_type)
	
	# 如果切换到工作日，则切换场景
	if new_scene_type == "workday":
		print("Weekend Main: 切换到工作日场景")
		get_tree().change_scene_to_file("res://scenes/workday_new/workday_main_new.tscn")

# 切换到工作日场景 - 此方法现在仅由TimeManager信号调用
func switch_to_workday_scene():
	print("Weekend Main: 切换到工作日场景")
	get_tree().change_scene_to_file("res://scenes/workday_new/workday_main_new.tscn") 

# 初始化日常事件热区系统
func _setup_daily_event_system():
	print("Weekend Main: 初始化日常事件热区系统")
	
	# 创建日常事件热区管理器
	hotzone_manager = DailyEventHotzoneManager.new()
	add_child(hotzone_manager)
	
	# 设置日常事件热区容器（热区1-3）
	var hotzone_containers: Array[Control] = [hotzone1, hotzone2, hotzone3]
	hotzone_manager.set_hotzone_containers(hotzone_containers)
	
	# 连接热区卡片点击信号
	if hotzone_manager:
		hotzone_manager.card_clicked.connect(_on_hotzone_card_clicked)
		print("Weekend Main: 日常热区卡片点击信号已连接")
	
	# 创建周末事件热区管理器
	weekend_hotzone_manager = WeekendEventHotzoneManager.new()
	add_child(weekend_hotzone_manager)

	# 设置周末事件热区容器（热区4）
	weekend_hotzone_manager.set_hotzone_container(weekend_event_hotzone)
	
	# 连接周末热区卡片点击信号
	if weekend_hotzone_manager:
		weekend_hotzone_manager.card_clicked.connect(_on_weekend_hotzone_card_clicked)
		print("Weekend Main: 周末热区卡片点击信号已连接")
	
	print("Weekend Main: 双重热区管理器初始化完成")

# 初始化周末事件系统
func _setup_weekend_event_system():
	print("=== Weekend Main: 初始化周末事件系统 ===")

	# 加载测试事件数据
	_load_weekend_test_events()
	
	# 创建周末事件卡片
	_create_weekend_event_cards()
	
	# 启用热区随机定位（测试功能）
	if hotzone_manager:
		hotzone_manager.set_random_positioning(true)
		print("Weekend Main: 启用热区随机定位模式")
	
	print("=== Weekend Main: 周末事件系统初始化完成 ===")

# 加载周末测试事件数据
func _load_weekend_test_events():
	print("=== Weekend Main: 加载周末事件数据 ===")
	
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		print("✗ EventManager未找到，无法加载事件")
		return
	
	# 直接从EventManager获取周末事件
	var weekend_events = event_manager.get_weekend_events()
	
	if weekend_events.size() > 0:
		weekend_test_events = weekend_events
		print("✓ 成功加载", weekend_test_events.size(), "个周末事件")
		
		# 打印加载的事件信息
		for i in range(weekend_test_events.size()):
			var event = weekend_test_events[i]
			print("  事件", i+1, ": ", event.event_name, " (", event.event_type, ") ID:", event.event_id)
			print("    角色: '", event.character_name, "' (长度:", event.character_name.length(), ")")
			print("    day_type检查: ", _get_event_day_type(event))
	else:
		print("✗ 无法加载周末事件")

# 获取事件的day_type字段
func _get_event_day_type(event: GameEvent) -> String:
	if event.prerequisite_conditions.has("day_type"):
		return event.prerequisite_conditions["day_type"]
	return "未设置"

# 创建周末事件卡片
func _create_weekend_event_cards():
	print("=== Weekend Main: 周末事件卡片系统准备 ===")
	
	if weekend_test_events.is_empty():
		print("✗ 没有周末测试事件，跳过卡片系统初始化")
		return
	
	print("✓ 周末事件数据已加载，共", weekend_test_events.size(), "个事件")
	print("  将由WeekendEventHotzoneManager负责创建和管理卡片")
	
	# 直接进行热区测试，让热区管理器负责卡片创建
	_test_weekend_cards_in_hotzones()

# 测试周末卡片在热区中的显示
func _test_weekend_cards_in_hotzones():
	print("=== Weekend Main: 测试周末卡片在热区显示 ===")
	
	if weekend_test_events.is_empty():
		print("✗ 没有周末测试事件可测试")
		return
	
	if not weekend_hotzone_manager:
		print("✗ 周末热区管理器未初始化")
		return
	
	print("测试前的配置状态:")
	print("  热区容器类型: ", weekend_event_hotzone.get_class())
	print("  热区容器尺寸: ", weekend_event_hotzone.size)
	print("  热区管理器随机定位: ", weekend_hotzone_manager.enable_random_positioning)
	print("  热区管理器对角分布: ", weekend_hotzone_manager.enable_diagonal_distribution)
	
	# 启用随机定位测试
	weekend_hotzone_manager.set_random_positioning(true)
	print("✓ 启用随机定位")
	
	# 启用对角分布模式
	weekend_hotzone_manager.enable_diagonal_distribution = true
	print("✓ 启用对角分布模式")
	
	# 打印当前设置
	print("当前配置:")
	print("  cards_per_hotzone: ", weekend_hotzone_manager.cards_per_hotzone)
	print("  max_cards_display: ", weekend_hotzone_manager.max_cards_display)
	print("  card_size: ", weekend_hotzone_manager.card_size)
	print("  min_card_distance: ", weekend_hotzone_manager.min_card_distance)
	print("  corner_region_ratio: ", weekend_hotzone_manager.corner_region_ratio)
	
	# 使用WeekendEventHotzoneManager显示weekend character和random事件
	weekend_hotzone_manager.display_weekend_events(weekend_test_events)
	
	print("✓ 周末卡片热区测试完成")

# 处理热区卡片点击
func _on_hotzone_card_clicked(game_event: GameEvent):
	print("Weekend Main: 热区卡片被点击 - ", game_event.event_name)
	print("  事件类型: ", game_event.event_type)
	print("  有效回合: ", game_event.valid_rounds)
	print("  角色: ", game_event.character_name)
	
	# 显示事件详情弹窗
	_show_event_popup(game_event)
	
# 处理周末热区卡片点击
func _on_weekend_hotzone_card_clicked(game_event: GameEvent):
	print("Weekend Main: 周末热区卡片被点击 - ", game_event.event_name)
	print("  事件类型: ", game_event.event_type)
	print("  有效回合: ", game_event.valid_rounds)
	print("  角色: ", game_event.character_name)
	
	# 显示事件详情弹窗
	_show_event_popup(game_event)

# 显示事件弹窗
func _show_event_popup(event: GameEvent):
	print("Weekend Main: 显示事件弹窗 - ", event.event_name)
	
	if not event_popup:
		print("⚠ 警告: 事件弹窗组件未找到")
		return
	
	# 准备事件数据
	var event_data = {
		"event_id": event.event_id,
		"title": event.event_name,
		"description": event.get_pre_check_text() if event.has_method("get_pre_check_text") else event.event_description,
		"image_path": event.background_path if not event.background_path.is_empty() else "",
		"has_reject_option": true
	}
	
	# 显示事件弹窗
	event_popup.show_event(event_data)
	print("Weekend Main: 事件弹窗已显示")

# 测试valid_rounds逻辑
func test_valid_rounds_logic():
	print("=== Weekend Main: 测试valid_rounds逻辑 ===")
	
	if not weekend_hotzone_manager:
		print("⚠ 周末热区管理器未找到")
		return
	
	# 直接测试加载的事件数据
	for event in weekend_test_events:
		if event:
			print("测试事件: ", event.event_name)
			print("  有效回合: ", event.valid_rounds)
			print("  当前回合: ", TimeManager.current_round if TimeManager else "未知")
			
			# 测试有效性检查
			if event.has_method("is_valid_in_round"):
				var current_round = TimeManager.current_round if TimeManager else 1
				var is_valid = event.is_valid_in_round(current_round)
				print("  在当前回合有效: ", is_valid)

# 测试位置随机分布
func test_random_positioning():
	print("=== Weekend Main: 测试位置随机分布 ===")
	
	if hotzone_manager:
		# 切换随机定位模式
		var current_mode = hotzone_manager.enable_random_positioning
		hotzone_manager.set_random_positioning(not current_mode)
		print("随机定位模式切换为: ", not current_mode)
		
		# 重新创建卡片测试
		_test_weekend_cards_in_hotzones()

# 获取周末事件系统状态
func get_weekend_system_status() -> Dictionary:
	return {
		"test_events_loaded": weekend_test_events.size(),
		"hotzone_status": hotzone_manager.get_hotzone_status() if hotzone_manager else {},
		"weekend_hotzone_status": weekend_hotzone_manager.get_hotzone_status() if weekend_hotzone_manager else {},
		"random_positioning": hotzone_manager.enable_random_positioning if hotzone_manager else false
	}

func _on_card_side_char_pressed():
	# 切换CardSideChar状态并显示/隐藏CardDisplayPanel
	is_card_char_active = !is_card_char_active
	print("Weekend Main: Card Side Char状态: ", is_card_char_active)
	
	# 更新视觉效果
	if is_card_char_active:
		card_side_char.modulate = Color(1.3, 1.3, 1.3, 1.0)
		# 显示CardDisplayPanel
		show_card_display()
	else:
		card_side_char.modulate = Color(1.0, 1.0, 1.0, 1.0)
		# 隐藏CardDisplayPanel
		hide_card_display()

func _on_card_side_others_pressed():
	# 切换CardSideOthers状态，但不显示CardDisplayPanel
	is_card_others_active = !is_card_others_active
	print("Weekend Main: Card Side Others状态: ", is_card_others_active)
	
	# 更新视觉效果
	if is_card_others_active:
		card_side_others.modulate = Color(1.3, 1.3, 1.3, 1.0)
	else:
		card_side_others.modulate = Color(1.0, 1.0, 1.0, 1.0)

# CardSideChar鼠标悬停事件
func _on_card_side_char_mouse_entered():
	# 鼠标悬停效果
	card_side_char.modulate = Color(1.2, 1.2, 1.2, 1.0)

func _on_card_side_char_mouse_exited():
	# 如果没有激活，则恢复正常颜色
	if not is_card_char_active:
		card_side_char.modulate = Color(1.0, 1.0, 1.0, 1.0)

# CardSideOthers鼠标悬停事件
func _on_card_side_others_mouse_entered():
	# 鼠标悬停效果
	card_side_others.modulate = Color(1.2, 1.2, 1.2, 1.0)

func _on_card_side_others_mouse_exited():
	# 如果没有激活，则恢复正常颜色
	if not is_card_others_active:
		card_side_others.modulate = Color(1.0, 1.0, 1.0, 1.0)

# 设置卡片侧边栏可见性
func set_card_side_visibility(char_visible: bool, others_visible: bool):
	card_side_char.visible = char_visible
	card_side_others.visible = others_visible

# 获取玩家管理器
func get_player_manager() -> WeekendPlayerManager:
	return player_manager

# 卡片侧边栏打开时的回调
func _on_card_bar_opened():
	print("Weekend Main: 卡片侧边栏已打开")

# 卡片侧边栏关闭时的回调
func _on_card_bar_closed():
	print("Weekend Main: 卡片侧边栏已关闭")

# 显示CardDisplayPanel
func show_card_display():
	if card_display_panel:
		return
	
	# 实例化CardDisplayPanel
	card_display_panel = CardDisplayPanelScene.instantiate()
	
	# 添加到UILayer
	$UILayer.add_child(card_display_panel)
	
	# 连接关闭信号
	card_display_panel.panel_closed.connect(_on_card_display_panel_closed)
	
	# 设置modulate颜色变化视觉反馈
	card_display_panel.modulate = Color(0.8, 0.8, 0.8, 0.0)
	var tween = create_tween()
	tween.tween_property(card_display_panel, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)
	
	print("Weekend Main: CardDisplayPanel已显示")

# 隐藏CardDisplayPanel
func hide_card_display():
	if not card_display_panel:
		return
	
	# 断开信号连接
	if card_display_panel.panel_closed.is_connected(_on_card_display_panel_closed):
		card_display_panel.panel_closed.disconnect(_on_card_display_panel_closed)
	
	# 移除并清理
	card_display_panel.queue_free()
	card_display_panel = null
	
	print("Weekend Main: CardDisplayPanel已隐藏")

# 切换CardDisplayPanel显示状态
func toggle_card_display():
	if card_display_panel:
		hide_card_display()
	else:
		show_card_display()

# 处理CardDisplayPanel关闭信号
func _on_card_display_panel_closed():
	print("Weekend Main: CardDisplayPanel被关闭")
	# 重置CardSideChar状态
	is_card_char_active = false
	card_side_char.modulate = Color(1.0, 1.0, 1.0, 1.0)
	hide_card_display()
