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

# 清空所有存档数据
static func clear_all_save_data() -> bool:
	print("SaveDataCleaner: 开始清空所有存档数据")
	
	var files_deleted = 0
	var files_failed = 0
	
	for file_path in SAVE_FILES:
		if FileAccess.file_exists(file_path):
			var error = DirAccess.remove_absolute(file_path)
			if error == OK:
				files_deleted += 1
				print("SaveDataCleaner: 已删除 ", file_path)
			else:
				files_failed += 1
				print("SaveDataCleaner: 删除失败 ", file_path, " 错误代码: ", error)
		else:
			print("SaveDataCleaner: 文件不存在 ", file_path)
	
	print("SaveDataCleaner: 清理完成 - 删除:", files_deleted, " 失败:", files_failed)
	return files_failed == 0

# 获取存在的存档文件列表
static func get_save_files_list() -> Array[String]:
	var existing_files: Array[String] = []
	
	for file_path in SAVE_FILES:
		if FileAccess.file_exists(file_path):
			existing_files.append(file_path)
	
	return existing_files

# 检查是否有存档数据存在
static func has_save_data() -> bool:
	for file_path in SAVE_FILES:
		if FileAccess.file_exists(file_path):
			return true
	return false

# 获取存档数据大小信息
static func get_save_data_info() -> Dictionary:
	var info = {
		"total_files": 0,
		"total_size": 0,
		"files": []
	}
	
	for file_path in SAVE_FILES:
		if FileAccess.file_exists(file_path):
			var file = FileAccess.open(file_path, FileAccess.READ)
			if file:
				var size = file.get_length()
				file.close()
				
				info.total_files += 1
				info.total_size += size
				info.files.append({
					"path": file_path,
					"size": size
				})
	
	return info 