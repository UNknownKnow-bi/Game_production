extends Control

# 视频资源路径
var video1_path = "res://resources/videos/open1.ogv"
var video2_path = "res://resources/videos/open2.ogv"
var video3_path = "res://resources/videos/open3.ogv"

# 当前播放的视频索引，用于循环播放open2和open3
var current_video = 0

# 预加载视频资源
var video1 = preload("res://resources/videos/open1.ogv")
var video2 = preload("res://resources/videos/open2.ogv")
var video3 = preload("res://resources/videos/open3.ogv")

# 节点引用
@onready var video_player = $VideoStreamPlayer
@onready var audio_player = $AudioStreamPlayer
@onready var start_button = $UI/StartButton
@onready var announcement_button = $UI/AnnouncementButton
@onready var settings_button = $UI/SettingsButton
@onready var announcement_panel = $UI/AnnouncementPanel
@onready var settings_panel = $UI/SettingsPanel

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
	
	# 连接面板按钮事件
	announcement_panel.get_node("CloseButton").pressed.connect(_on_announcement_close_pressed)
	settings_panel.get_node("ConfirmButton").pressed.connect(_on_settings_confirm_pressed)
	settings_panel.get_node("CancelButton").pressed.connect(_on_settings_cancel_pressed)
	
	# 确保按钮初始状态为不可见
	start_button.visible = false
	announcement_button.visible = false
	settings_button.visible = false
	
	# 确保面板初始状态为不可见
	announcement_panel.visible = false
	settings_panel.visible = false
	
	# 启动延时计时器，5.5秒后显示按钮
	show_button_delayed()

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
	# 目前按钮点击不做任何操作，只显示点击效果
	# 后续可在此处添加场景跳转等功能
	print("开始游戏按钮被点击") 

# 公告栏按钮点击事件
func _on_announcement_button_pressed():
	announcement_panel.visible = true
	print("公告栏按钮被点击")

# 设置按钮点击事件
func _on_settings_button_pressed():
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

# 设置取消按钮点击事件
func _on_settings_cancel_pressed():
	settings_panel.visible = false
	print("取消设置")

# 新增函数：延迟显示按钮
func show_button_delayed():
	# 使用Godot 4.x的异步等待功能
	await get_tree().create_timer(5.5).timeout
	# 同时显示所有按钮
	start_button.visible = true
	announcement_button.visible = true
	settings_button.visible = true 
