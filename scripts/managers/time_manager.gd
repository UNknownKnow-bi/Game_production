extends Node

# TimeManager - 时间管理器单例
# 管理全局游戏时间、回合数和场景类型切换

signal round_changed(new_round: int)
signal scene_type_changed(new_scene_type: String)

var current_round: int = 1
var current_scene_type: String = "workday"  # "workday" 或 "weekend"

const SAVE_FILE_PATH = "user://game_state.json"

func _ready():
	load_game_state()

# 增加回合数
func advance_round():
	current_round += 1
	round_changed.emit(current_round)
	
	# 切换场景类型
	if current_scene_type == "workday":
		current_scene_type = "weekend"
	else:
		current_scene_type = "workday"
	
	scene_type_changed.emit(current_scene_type)
	save_game_state()
	print("Time Manager: 回合推进到 ", current_round, ", 场景类型: ", current_scene_type)

# 获取当前回合数
func get_current_round() -> int:
	return current_round

# 获取当前场景类型
func get_current_scene_type() -> String:
	return current_scene_type

# 设置回合数（用于调试或加载存档）
func set_current_round(round: int):
	current_round = round
	round_changed.emit(current_round)

# 设置场景类型（用于调试或加载存档）
func set_scene_type(scene_type: String):
	current_scene_type = scene_type
	scene_type_changed.emit(current_scene_type)

# 保存游戏状态
func save_game_state():
	var save_data = {
		"current_round": current_round,
		"current_scene_type": current_scene_type
	}
	
	# 添加特权卡数据
	if PrivilegeCardManager:
		var cards_data = PrivilegeCardManager.save_cards_data()
		save_data.merge(cards_data)
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Time Manager: 游戏状态已保存")

# 加载游戏状态
func load_game_state():
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_text)
			if parse_result == OK:
				var save_data = json.data
				current_round = save_data.get("current_round", 1)
				current_scene_type = save_data.get("current_scene_type", "workday")
				
				# 加载特权卡数据
				if PrivilegeCardManager:
					PrivilegeCardManager.load_cards_data(save_data)
				
				print("Time Manager: 游戏状态已加载 - 回合: ", current_round, ", 场景: ", current_scene_type)
			else:
				print("Time Manager: 存档文件解析失败，使用默认值")
	else:
		print("Time Manager: 未找到存档文件，使用默认值") 