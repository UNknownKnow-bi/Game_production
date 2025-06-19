extends Node

# SaveDataCleaner - 存档数据清理工具
# 提供清空所有游戏存档数据的功能

# 存档文件路径列表
const SAVE_FILES = [
	"user://game_data.cfg",      # intro_cg.gd中的用户数据
	"user://game_state.json",    # time_manager.gd中的游戏状态
	"user://game_save.json",     # GameSaveManager主存档文件
	"user://game_save_backup.json", # GameSaveManager备份存档文件
	"user://player_data.save",   # 可能的玩家数据文件
	"user://settings.cfg",       # 可能的设置文件
	"user://progress.dat"        # 可能的进度文件
]

# 清理所有存档数据
func clear_all_save_data() -> bool:
	print("SaveDataCleaner: 开始清理所有存档数据")
	
	var files_removed = 0
	var total_files = 0
	
	# 清理user://目录下的所有存档文件
	var dir = DirAccess.open("user://")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir():
				total_files += 1
				var file_path = "user://" + file_name
				
				# 检查是否为存档文件
				if _is_save_file(file_name):
					print("SaveDataCleaner: 删除文件 ", file_path)
					var err = DirAccess.remove_absolute(file_path)
					if err == OK:
						files_removed += 1
					else:
						print("SaveDataCleaner: 无法删除文件 ", file_path, " 错误代码: ", err)
			
			file_name = dir.get_next()
	else:
		print("SaveDataCleaner: 无法访问user://目录")
		return false
	
	print("SaveDataCleaner: 清理完成，删除了 ", files_removed, " / ", total_files, " 个文件")
	return true

# 检查是否有存档数据
func has_save_data() -> bool:
	var dir = DirAccess.open("user://")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and _is_save_file(file_name):
				return true
			file_name = dir.get_next()
	
	return false

# 获取存档数据信息
func get_save_data_info() -> Dictionary:
	var info = {
		"total_files": 0,
		"total_size": 0
	}
	
	var dir = DirAccess.open("user://")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and _is_save_file(file_name):
				info.total_files += 1
				
				var file_path = "user://" + file_name
				var file = FileAccess.open(file_path, FileAccess.READ)
				if file:
					info.total_size += file.get_length()
			
			file_name = dir.get_next()
	
	return info

# 检查文件是否为存档文件
func _is_save_file(file_name: String) -> bool:
	# 匹配常见的存档文件名模式
	return file_name.ends_with(".save") or \
		   file_name.ends_with(".json") or \
		   file_name.ends_with(".cfg") or \
		   file_name == "game_state.json" or \
		   file_name == "game_save.json" or \
		   file_name == "game_save_backup.json" or \
		   file_name == "game_data.cfg"

# 清理TimeManager的旧存档文件
func clean_time_manager_save_file() -> bool:
	print("SaveDataCleaner: 清理TimeManager旧存档文件")
	
	var time_manager_save_path = "user://game_state.json"
	if FileAccess.file_exists(time_manager_save_path):
		var err = DirAccess.remove_absolute(time_manager_save_path)
		if err == OK:
			print("SaveDataCleaner: 成功删除TimeManager旧存档文件")
			return true
		else:
			print("SaveDataCleaner: 无法删除TimeManager旧存档文件，错误代码:", err)
			return false
	else:
		print("SaveDataCleaner: TimeManager旧存档文件不存在")
		return true

# 获取存在的存档文件列表
static func get_save_files_list() -> Array[String]:
	var existing_files: Array[String] = []
	
	for file_path in SAVE_FILES:
		if FileAccess.file_exists(file_path):
			existing_files.append(file_path)
	
	return existing_files 