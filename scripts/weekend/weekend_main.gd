extends Control

# WeekendMain - 周末场景主脚本
# 处理周末场景的基础逻辑和UI更新

@onready var time_info_label = $UILayer/CenterContainer/VBoxContainer/TimeInfo
@onready var next_round_button = $UILayer/CenterContainer/VBoxContainer/NextRoundButton

func _ready():
	# 连接TimeManager信号
	if TimeManager:
		TimeManager.round_changed.connect(_on_round_changed)
		TimeManager.scene_type_changed.connect(_on_scene_type_changed)
	
	# 更新UI显示
	update_time_display()
	
	print("Weekend Main: 周末场景已加载")

# 更新时间显示
func update_time_display():
	if TimeManager and time_info_label:
		var current_round = TimeManager.get_current_round()
		var scene_type = TimeManager.get_current_scene_type()
		time_info_label.text = "当前回合: " + str(current_round) + " (" + scene_type + ")"

# 下一回合按钮点击处理
func _on_next_round_button_pressed():
	print("Weekend Main: 点击进入下一回合")
	
	# 推进回合
	if TimeManager:
		TimeManager.advance_round()
		
		# 等待一帧后切换场景
		await get_tree().process_frame
		switch_to_workday_scene()

# 切换到工作日场景
func switch_to_workday_scene():
	print("Weekend Main: 切换到工作日场景")
	get_tree().change_scene_to_file("res://scenes/workday_new/workday_main_new.tscn")

# 回合变化信号处理
func _on_round_changed(new_round: int):
	print("Weekend Main: 回合变化到 ", new_round)
	update_time_display()

# 场景类型变化信号处理
func _on_scene_type_changed(new_scene_type: String):
	print("Weekend Main: 场景类型变化到 ", new_scene_type)
	update_time_display() 