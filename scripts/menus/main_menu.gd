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
	
	# 使用FontManager应用字体到主菜单
	if FontManager:
		FontManager.apply_to_scene(self)
		print("FontManager已应用到主菜单场景")
	
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
	# 跳转到介绍场景，而不是直接进入工作日主场景
	get_tree().change_scene_to_file("res://scenes/intro_cg.tscn")
	print("开始游戏按钮被点击，跳转到介绍场景")

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
	print("设置按钮被点击")

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
	# 调用FontManager打开字体设置UI
	if FontManager:
		FontManager.open_settings()
		print("打开字体设置界面")
	else:
		print("FontManager未加载，无法打开字体设置")

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
