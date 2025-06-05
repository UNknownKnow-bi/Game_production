extends Control

# TimeDisplay - 时间显示组件
# 显示当前回合数和场景类型

@onready var round_label = $VBoxContainer/RoundLabel
@onready var scene_type_label = $VBoxContainer/SceneTypeLabel
@onready var task_countdown_label = $VBoxContainer/TaskCountdownLabel

func _ready():
	# 连接TimeManager信号
	if TimeManager:
		TimeManager.round_changed.connect(_on_round_changed)
		TimeManager.scene_type_changed.connect(_on_scene_type_changed)
	
	# 连接PrivilegeCardManager信号
	if PrivilegeCardManager:
		PrivilegeCardManager.cards_updated.connect(_on_cards_updated)
	
	# 初始化显示
	update_display()
	
	print("Time Display: 时间显示组件已初始化")

# 更新显示内容
func update_display():
	if TimeManager:
		var current_round = TimeManager.get_current_round()
		var scene_type = TimeManager.get_current_scene_type()
		
		if round_label:
			round_label.text = "回合: " + str(current_round)
		
		if scene_type_label:
			var scene_text = "工作日" if scene_type == "workday" else "周末"
			scene_type_label.text = scene_text
	
	# 更新任务倒计时
	update_task_countdown()

# 更新任务倒计时显示
func update_task_countdown():
	if not PrivilegeCardManager or not task_countdown_label:
		return
	
	var min_rounds = PrivilegeCardManager.get_minimum_remaining_rounds()
	
	if min_rounds == -1:
		# 没有特权卡
		task_countdown_label.text = "距离\"必须的任务\"\n暂无任务"
		task_countdown_label.modulate = Color(0.67, 0.23, 0.23, 1.0)  # 固定颜色 #ab3b3b
	elif min_rounds <= 0:
		# 有过期的任务
		task_countdown_label.text = "距离\"必须的任务\"\n任务已到期！"
		task_countdown_label.modulate = Color(0.67, 0.23, 0.23, 1.0)  # 固定颜色 #ab3b3b
	elif min_rounds <= 2:
		# 即将到期
		task_countdown_label.text = "距离\"必须的任务\"\n还有" + str(min_rounds) + "个回合"
		task_countdown_label.modulate = Color(0.67, 0.23, 0.23, 1.0)  # 固定颜色 #ab3b3b
	else:
		# 正常状态
		task_countdown_label.text = "距离\"必须的任务\"\n还有" + str(min_rounds) + "个回合"
		task_countdown_label.modulate = Color(0.67, 0.23, 0.23, 1.0)  # 固定颜色 #ab3b3b

# 特权卡更新信号处理
func _on_cards_updated():
	print("Time Display: 特权卡更新，刷新任务倒计时显示")
	update_task_countdown()

# 回合变化信号处理
func _on_round_changed(new_round: int):
	print("Time Display: 回合更新到 ", new_round)
	update_display()

# 场景类型变化信号处理
func _on_scene_type_changed(new_scene_type: String):
	print("Time Display: 场景类型更新到 ", new_scene_type)
	update_display() 
 
