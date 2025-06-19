extends Control

# 视频资源路径
var video1_path = "res://assets/videos/open1.ogv"
var video2_path = "res://assets/videos/open2.ogv"
var video3_path = "res://assets/videos/open3.ogv"

# 当前播放的视频索引，用于循环播放open2和open3
var current_video = 0

# 预加载视频资源
var video1 = preload("res://assets/videos/open1.ogv")
var video2 = preload("res://assets/videos/open2.ogv")
var video3 = preload("res://assets/videos/open3.ogv")
# var title_video = preload("res://assets/videos/title.ogv")

# 预加载着色器资源
var title_shader = preload("res://assets/shaders/title_reveal.gdshader")

# 存档清理相关
var clear_save_confirmation_dialog: AcceptDialog
var is_clearing_save_data: bool = false

# 节点引用
@onready var video_player = $VideoStreamPlayer
@onready var audio_player = $AudioStreamPlayer
@onready var start_button = $UI/StartButton
@onready var announcement_button = $UI/AnnouncementButton
@onready var settings_button = $UI/SettingsButton
@onready var announcement_panel = $UI/AnnouncementPanel
@onready var settings_panel = $UI/SettingsPanel
@onready var quit_button = $UI/QuitButton
@onready var game_title = $UI/GameTitle
@onready var font_settings_button = $UI/SettingsPanel/FontSettingsButton

func _ready():
	# 连接视频播放完成信号
	video_player.finished.connect(_on_video_finished)
	
	# 初始播放第一个视频
	video_player.stream = video1
	video_player.play()
	
	# 播放背景音乐并设置循环
	audio_player.play()
	# 连接音频播放完成信号以实现循环
	audio_player.finished.connect(_on_audio_finished)
	
	# 连接按钮点击事件
	start_button.pressed.connect(_on_start_button_pressed)
	announcement_button.pressed.connect(_on_announcement_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	# 连接面板按钮事件
	announcement_panel.get_node("CloseButton").pressed.connect(_on_announcement_close_pressed)
	settings_panel.get_node("ConfirmButton").pressed.connect(_on_settings_confirm_pressed)
	settings_panel.get_node("CancelButton").pressed.connect(_on_settings_cancel_pressed)
	font_settings_button.pressed.connect(_on_font_settings_button_pressed)
	
	# 确保按钮初始状态为不可见
	start_button.visible = false
	announcement_button.visible = false
	settings_button.visible = false
	quit_button.visible = false
	
	# 设置游戏标题初始状态
	setup_game_title()
	
	# 确保面板初始状态为不可见
	announcement_panel.visible = false
	settings_panel.visible = false
	
	# 启动延时计时器，5.5秒后显示按钮
	show_button_delayed()

# 设置游戏标题响应式布局和着色器
func setup_game_title():
	# 设置标题为可见，但通过着色器控制显示
	game_title.visible = false  # 初始设为不可见，将在适当时间显示
	
	# 应用着色器
	var shader_material = ShaderMaterial.new()
	shader_material.shader = title_shader
	shader_material.set_shader_parameter("progress", 0.0)  # 初始完全不可见
	shader_material.set_shader_parameter("edge_softness", 0.05)  # 设置边缘柔和度
	shader_material.set_shader_parameter("glow_intensity", 0.0)  # 初始无发光
	game_title.material = shader_material

func _on_video_finished():
	if video_player.stream == video1:
		# 第一个视频播放完成后，切换到第二个视频
		video_player.stream = video2
		video_player.play()
		current_video = 1
	elif current_video == 1:
		# 第二个视频播放完成后，切换到第三个视频
		video_player.stream = video3
		video_player.play()
		current_video = 2
	else:
		# 第三个视频播放完成后，切换回第二个视频，形成循环
		video_player.stream = video2
		video_player.play()
		current_video = 1

# 音频播放完成时重新播放，实现循环效果
func _on_audio_finished():
	audio_player.play()

func _on_start_button_pressed():
	# 检查是否有存档
	if GameSaveManager and GameSaveManager.has_save_file():
		# 有存档，显示选择对话框
		_show_game_start_options()
	else:
		# 没有存档，直接开始新游戏
		_start_new_game()

# 显示游戏开始选项对话框
func _show_game_start_options():
	var dialog = AcceptDialog.new()
	dialog.title = "游戏选项"
	
	# 获取存档信息
	var save_info = GameSaveManager.get_save_info()
	var message = "检测到存档文件\n\n"
	if not save_info.is_empty():
		message += "存档信息:\n"
		message += "回合: " + str(save_info.get("current_round", 1)) + "\n"
		message += "场景: " + ("工作日" if save_info.get("current_scene_type", "workday") == "workday" else "周末") + "\n"
		message += "保存时间: " + Time.get_datetime_string_from_unix_time(save_info.get("save_timestamp", 0)) + "\n\n"
	
	message += "请选择操作:"
	dialog.dialog_text = message
	
	# 添加继续游戏按钮
	var continue_button = dialog.add_button("继续游戏", false, "continue")
	# 添加新游戏按钮
	var new_game_button = dialog.add_button("新游戏", false, "new_game")
	# 添加取消按钮
	dialog.add_cancel_button("取消")
	
	# 连接信号
	dialog.custom_action.connect(_on_game_start_option_selected)
	dialog.canceled.connect(_on_game_start_canceled)
	
	add_child(dialog)
	dialog.popup_centered()

# 处理游戏开始选项选择
func _on_game_start_option_selected(action: String):
	match action:
		"continue":
			_continue_game()
		"new_game":
			_start_new_game()

# 取消游戏开始选择
func _on_game_start_canceled():
	print("取消游戏开始选择")

# 继续游戏
func _continue_game():
	print("Main Menu: 继续游戏")
	
	if not GameSaveManager:
		print("Main Menu: 错误 - GameSaveManager未找到")
		return
	
	var save_info = GameSaveManager.get_save_info()
	if save_info.is_empty():
		print("Main Menu: 没有找到存档信息")
		return
	
	var scene_type = save_info.get("current_scene_type", "workday")
	print("Main Menu: 存档场景类型: ", scene_type)
	
	# 验证场景类型的有效性
	if scene_type != "workday" and scene_type != "weekend":
		print("Main Menu: 警告 - 存档中的场景类型无效: ", scene_type, "，默认使用workday")
		scene_type = "workday"
	
	# 加载游戏状态
	var load_success = GameSaveManager.load_game()
	if not load_success:
		print("Main Menu: 加载游戏状态失败")
		return
	
	print("Main Menu: 游戏状态加载成功，切换到场景: ", scene_type)
	
	# 根据场景类型切换到对应场景
	if scene_type == "workday":
		get_tree().change_scene_to_file("res://scenes/workday_new/workday_main_new.tscn")
	elif scene_type == "weekend":
		get_tree().change_scene_to_file("res://scenes/weekend/weekend_main.tscn")
	else:
		print("Main Menu: 未知场景类型: ", scene_type, "，默认加载工作日场景")
		get_tree().change_scene_to_file("res://scenes/workday_new/workday_main_new.tscn")

# 开始新游戏
func _start_new_game():
	print("开始新游戏")
	# 执行完整的存档清理
	SaveDataCleaner.clear_all_save_data()
	if GameSaveManager:
		GameSaveManager.delete_save()
		print("已清空旧存档")
	
	# 重置所有Manager到初始状态
	_reset_managers_to_initial_state()
	
	# 跳转到介绍场景
	get_tree().change_scene_to_file("res://scenes/intro_cg.tscn")
	print("开始新游戏：跳转到介绍场景")

# 隐藏所有面板函数
func hide_all_panels():
	announcement_panel.visible = false
	settings_panel.visible = false

# 公告栏按钮点击事件
func _on_announcement_button_pressed():
	hide_all_panels()
	announcement_panel.visible = true
	print("公告栏按钮被点击")

# 设置按钮点击事件
func _on_settings_button_pressed():
	hide_all_panels()
	settings_panel.visible = true
	
	# 连接清空存档按钮（如果存在）
	_setup_clear_save_button()
	
	print("设置按钮被点击")

# 设置清空存档按钮
func _setup_clear_save_button():
	var clear_save_button = settings_panel.get_node_or_null("ClearSaveButton")
	if clear_save_button and not clear_save_button.pressed.is_connected(_on_clear_save_data_pressed):
		clear_save_button.pressed.connect(_on_clear_save_data_pressed)
		print("清空存档按钮已连接")

# 清空存档数据按钮点击事件
func _on_clear_save_data_pressed():
	print("清空存档按钮被点击")
	
	if is_clearing_save_data:
		print("正在清理存档数据，请稍候...")
		return
	
	# 检查是否有存档数据
	if not SaveDataCleaner.has_save_data():
		_show_simple_message("提示", "当前没有存档数据需要清理")
		return
	
	# 显示确认对话框
	_show_clear_save_confirmation()

# 显示清空存档确认对话框
func _show_clear_save_confirmation():
	if clear_save_confirmation_dialog:
		clear_save_confirmation_dialog.queue_free()
	
	clear_save_confirmation_dialog = AcceptDialog.new()
	clear_save_confirmation_dialog.title = "确认清空存档"
	
	var save_info = SaveDataCleaner.get_save_data_info()
	var message = "确定要清空所有存档数据吗？\n\n"
	message += "将删除 " + str(save_info.get("total_files", 0)) + " 个存档文件\n"
	message += "总大小: " + str(save_info.get("total_size", 0)) + " 字节\n\n"
	message += "此操作不可撤销！"
	
	clear_save_confirmation_dialog.dialog_text = message
	clear_save_confirmation_dialog.add_cancel_button("取消")
	
	# 连接确认信号
	clear_save_confirmation_dialog.confirmed.connect(_on_clear_save_confirmed)
	clear_save_confirmation_dialog.canceled.connect(_on_clear_save_canceled)
	
	add_child(clear_save_confirmation_dialog)
	clear_save_confirmation_dialog.popup_centered()

# 确认清空存档
func _on_clear_save_confirmed():
	print("用户确认清空存档")
	is_clearing_save_data = true
	
	# 执行双重清理：旧系统 + 新系统
	var cleaner_success = SaveDataCleaner.clear_all_save_data()
	var game_save_success = true
	
	# 额外清理GameSaveManager存档
	if GameSaveManager:
		game_save_success = GameSaveManager.delete_save()
		print("MainMenu: GameSaveManager存档清理结果:", game_save_success)
	else:
		print("MainMenu: 警告 - GameSaveManager未找到")
	
	# 重置各个Manager到初始状态（保险措施）
	_reset_managers_to_initial_state()
	
	is_clearing_save_data = false
	
	var overall_success = cleaner_success and game_save_success
	if overall_success:
		_show_simple_message("成功", "存档数据已成功清空！\n重新开始游戏将从头开始。")
	else:
		_show_simple_message("错误", "清空存档时发生错误，请检查文件权限。")

# 取消清空存档
func _on_clear_save_canceled():
	print("用户取消清空存档")

# 重置各个Manager到初始状态
func _reset_managers_to_initial_state():
	print("MainMenu: 重置各个Manager到初始状态")
	
	# 重置TimeManager
	if TimeManager:
		TimeManager.current_round = 1
		TimeManager.current_scene_type = "workday"
		TimeManager.workday_round_count = 0
		TimeManager.weekend_round_count = 0
		TimeManager.is_settlement_in_progress = false
		print("MainMenu: TimeManager已重置")
	
	# 重置AttributeManager
	if AttributeManager and AttributeManager.has_method("reset_attributes"):
		AttributeManager.reset_attributes()
		print("MainMenu: AttributeManager已重置")
	
	# 重置PrivilegeCardManager
	if PrivilegeCardManager:
		PrivilegeCardManager.privilege_cards.clear()
		print("MainMenu: PrivilegeCardManager已重置")
	
	# 重置EventManager
	if EventManager:
		EventManager.completed_events.clear()
		EventManager.event_trigger_counts.clear()
		EventManager.event_last_completed.clear()
		EventManager.current_round = 1
		print("MainMenu: EventManager已重置")
	
	# 重置ItemCardInventoryManager
	if ItemCardInventoryManager and ItemCardInventoryManager.has_method("clear_inventory"):
		ItemCardInventoryManager.clear_inventory()
		print("MainMenu: ItemCardInventoryManager已重置")
	
	# 重置GlobalCardUsageManager
	if GlobalCardUsageManager:
		GlobalCardUsageManager.current_round_usage.clear()
		GlobalCardUsageManager.duration_busy_cards.clear()
		GlobalCardUsageManager.current_round = 1
		print("MainMenu: GlobalCardUsageManager已重置")
	
	print("MainMenu: 所有Manager重置完成")

# 显示简单消息对话框
func _show_simple_message(title: String, message: String):
	var message_dialog = AcceptDialog.new()
	message_dialog.title = title
	message_dialog.dialog_text = message
	
	add_child(message_dialog)
	message_dialog.popup_centered()
	
	# 自动清理对话框
	message_dialog.confirmed.connect(func(): message_dialog.queue_free())

# 新游戏按钮点击事件（自动清空存档）
func _on_new_game_button_pressed():
	print("新游戏按钮被点击")
	
	if SaveDataCleaner.has_save_data():
		# 有存档数据，询问是否清空
		var new_game_dialog = AcceptDialog.new()
		new_game_dialog.title = "开始新游戏"
		new_game_dialog.dialog_text = "检测到存档数据，开始新游戏将清空所有进度。\n确定要继续吗？"
		new_game_dialog.add_cancel_button("取消")
		
		new_game_dialog.confirmed.connect(func():
			# 执行双重清理
			SaveDataCleaner.clear_all_save_data()
			if GameSaveManager:
				GameSaveManager.delete_save()
			_reset_managers_to_initial_state()
			get_tree().change_scene_to_file("res://scenes/intro_cg.tscn")
			new_game_dialog.queue_free()
		)
		new_game_dialog.canceled.connect(func(): new_game_dialog.queue_free())
		
		add_child(new_game_dialog)
		new_game_dialog.popup_centered()
	else:
		# 没有存档数据，直接开始
		get_tree().change_scene_to_file("res://scenes/intro_cg.tscn")

# 公告栏关闭按钮点击事件
func _on_announcement_close_pressed():
	announcement_panel.visible = false
	print("关闭公告栏")

# 设置确认按钮点击事件
func _on_settings_confirm_pressed():
	# 在这里添加保存设置的逻辑
	var volume = settings_panel.get_node("VolumeSlider").value
	var fullscreen = settings_panel.get_node("FullscreenCheck").button_pressed
	
	# 应用设置
	audio_player.volume_db = linear_to_db(volume / 100.0)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	settings_panel.visible = false
	print("应用设置：音量=", volume, "% 全屏=", fullscreen)

# 字体设置按钮点击事件
func _on_font_settings_button_pressed():
	print("字体设置功能已禁用")

# 设置取消按钮点击事件
func _on_settings_cancel_pressed():
	settings_panel.visible = false
	print("取消设置")

# 退出按钮点击事件
func _on_quit_button_pressed():
	get_tree().quit()
	print("退出游戏按钮被点击")

# 新增函数：延迟显示按钮
func show_button_delayed():
	# 使用Godot 4.x的异步等待功能
	await get_tree().create_timer(5.5).timeout
	
	# 显示所有按钮
	start_button.visible = true
	announcement_button.visible = true
	settings_button.visible = true 
	quit_button.visible = true
	
	# 为开始游戏按钮添加呼吸动画
	create_button_breathing_animation()
	
	# 等待短暂时间后再显示标题
	await get_tree().create_timer(0.3).timeout
	
	# 显示标题并开始渐变动画
	game_title.visible = true
	
	# 创建主渐变动画
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_method(func(value): 
		game_title.material.set_shader_parameter("progress", value), 
		0.0, 1.0, 1.5  # 1.5秒内完成
	)
	
	# 同时控制glow_intensity参数，产生动态边缘发光
	var glow_tween = create_tween()
	glow_tween.set_ease(Tween.EASE_IN_OUT)  # 平滑过渡
	glow_tween.tween_method(func(value):
		game_title.material.set_shader_parameter("glow_intensity", value),
		0.0, 0.5, 1.7  # 时长略长于主动画，强度适中为0.5
	)
	
	# 等待主动画完成
	await tween.finished
	
	# 创建结束闪光效果
	var finish_tween = create_tween()
	finish_tween.tween_method(func(value):
		game_title.material.set_shader_parameter("glow_intensity", value),
		0.5, 0.1, 0.8  # 从0.5渐变到0.1，持续0.8秒
	)

# 创建按钮呼吸动画
func create_button_breathing_animation():
	var breath_tween = create_tween()
	breath_tween.set_loops()  # 设置为无限循环
	
	# 透明度在0.7到1.0之间变化
	breath_tween.tween_property(start_button, "modulate:a", 0.7, 1.0)  # 1秒淡出到0.7
	breath_tween.tween_property(start_button, "modulate:a", 1.0, 1.0)  # 1秒淡入回1.0
