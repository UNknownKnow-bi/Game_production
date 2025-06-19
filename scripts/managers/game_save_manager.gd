extends Node

# GameSaveManager - 统一游戏存储管理器
# 管理所有游戏状态的保存和加载

signal save_completed
signal load_completed
signal save_failed(error_message: String)
signal load_failed(error_message: String)

# 存档文件路径
const SAVE_FILE_PATH = "user://game_save.json"
const BACKUP_SAVE_PATH = "user://game_save_backup.json"

# 存档版本
const SAVE_VERSION = "1.0"

# 存档数据缓存
var cached_save_data: Dictionary = {}
var is_saving: bool = false
var is_loading: bool = false

func _ready():
	print("GameSaveManager: 统一存储管理器初始化")
	
	# 连接应用退出信号，确保退出时保存
	get_tree().auto_accept_quit = false
	get_tree().connect("quit_request", _on_quit_request)

# 保存完整游戏状态
func save_game() -> bool:
	if is_saving:
		print("GameSaveManager: 正在保存中，跳过重复保存")
		return false
	
	is_saving = true
	print("GameSaveManager: 开始保存游戏状态")
	
	var save_data = collect_all_save_data()
	var success = write_save_file(save_data)
	
	is_saving = false
	
	if success:
		cached_save_data = save_data.duplicate()
		save_completed.emit()
		print("GameSaveManager: 游戏状态保存成功")
	else:
		save_failed.emit("保存文件写入失败")
		print("GameSaveManager: 游戏状态保存失败")
	
	return success

# 加载完整游戏状态
func load_game() -> bool:
	if is_loading:
		print("GameSaveManager: 正在加载中，跳过重复加载")
		return false
	
	is_loading = true
	print("GameSaveManager: 开始加载游戏状态")
	
	var save_data = read_save_file()
	if save_data.is_empty():
		is_loading = false
		load_failed.emit("存档文件不存在或损坏")
		print("GameSaveManager: 游戏状态加载失败")
		return false
	
	var success = distribute_save_data(save_data)
	
	is_loading = false
	
	if success:
		cached_save_data = save_data.duplicate()
		load_completed.emit()
		print("GameSaveManager: 游戏状态加载成功")
	else:
		load_failed.emit("存档数据分发失败")
		print("GameSaveManager: 游戏状态加载失败")
	
	return success

# 收集所有组件的存档数据
func collect_all_save_data() -> Dictionary:
	var save_data = {
		"version": SAVE_VERSION,
		"save_timestamp": Time.get_unix_time_from_system(),
		"game_progress": {},
		"player_attributes": {},
		"cards": {},
		"events": {},
		"settings": {}
	}
	
	# 收集游戏进度数据
	if TimeManager:
		save_data.game_progress = {
			"current_round": TimeManager.get_current_round(),
			"current_scene_type": TimeManager.get_current_scene_type(),
			"workday_round_count": TimeManager.workday_round_count,
			"weekend_round_count": TimeManager.weekend_round_count,
			"is_settlement_in_progress": TimeManager.get_settlement_status()
		}
		print("GameSaveManager: 收集游戏进度数据 - 回合:", save_data.game_progress.current_round)
	
	# 收集玩家属性数据
	if AttributeManager:
		save_data.player_attributes = {
			"power": AttributeManager.get_attribute("power"),
			"reputation": AttributeManager.get_attribute("reputation"),
			"piety": AttributeManager.get_attribute("piety"),
			"coins": AttributeManager.get_coins(),
			"attribute_history": AttributeManager.get_attribute_history()
		}
		print("GameSaveManager: 收集玩家属性数据 - 金币:", save_data.player_attributes.coins)
	
	# 收集卡牌数据
	save_data.cards = collect_cards_data()
	
	# 收集事件数据
	save_data.events = collect_events_data()
	
	# 收集设置数据
	save_data.settings = collect_settings_data()
	
	print("GameSaveManager: 存档数据收集完成，总大小:", JSON.stringify(save_data).length(), "字符")
	return save_data

# 收集卡牌相关数据
func collect_cards_data() -> Dictionary:
	var cards_data = {
		"privilege_cards": [],
		"item_card_inventory": [],
		"character_unlocked": [],
		"card_usage_states": {}
	}
	
	# 特权卡数据
	if PrivilegeCardManager:
		var privilege_data = PrivilegeCardManager.save_cards_data()
		cards_data.privilege_cards = privilege_data.get("privilege_cards", [])
		print("GameSaveManager: 收集特权卡数据 - 数量:", cards_data.privilege_cards.size())
	
	# 情报卡背包数据
	if ItemCardInventoryManager:
		cards_data.item_card_inventory = ItemCardInventoryManager.serialize_inventory()
		print("GameSaveManager: 收集情报卡数据 - 数量:", cards_data.item_card_inventory.size())
	
	# 角色卡解锁数据
	if CharacterCardManager and CharacterCardManager.has_method("get_unlocked_card_ids"):
		cards_data.character_unlocked = CharacterCardManager.get_unlocked_card_ids()
		print("GameSaveManager: 收集角色卡解锁数据")
	
	# 卡牌使用状态数据
	if GlobalCardUsageManager and GlobalCardUsageManager.has_method("serialize_usage_data"):
		cards_data.card_usage_states = GlobalCardUsageManager.serialize_usage_data()
		print("GameSaveManager: 收集卡牌使用状态数据")
	
	return cards_data

# 收集事件相关数据
func collect_events_data() -> Dictionary:
	var events_data = {
		"completed_events": {},
		"event_trigger_counts": {},
		"event_last_completed": {},
		"event_slots": {}
	}
	
	# EventManager数据
	if EventManager:
		events_data.completed_events = EventManager.completed_events
		events_data.event_trigger_counts = EventManager.event_trigger_counts
		events_data.event_last_completed = EventManager.event_last_completed
		print("GameSaveManager: 收集事件管理器数据 - 已完成事件:", events_data.completed_events.size())
	
	# EventSlotManager数据
	if EventSlotManager and EventSlotManager.has_method("serialize_slots"):
		events_data.event_slots = EventSlotManager.serialize_slots()
		print("GameSaveManager: 收集事件卡槽数据")
	
	return events_data

# 收集设置数据
func collect_settings_data() -> Dictionary:
	var settings_data = {
		"intro_viewed": false,
		"initial_card_selected": ""
	}
	
	# 检查intro观看状态
	if FileAccess.file_exists("user://game_data.cfg"):
		var file = FileAccess.open("user://game_data.cfg", FileAccess.READ)
		if file:
			var content = file.get_as_text()
			file.close()
			var json_result = JSON.parse_string(content)
			if json_result != null and json_result is Dictionary:
				settings_data.intro_viewed = json_result.get("intro_viewed", false)
				settings_data.initial_card_selected = json_result.get("selected_card_type", "")
	
	print("GameSaveManager: 收集设置数据 - intro已观看:", settings_data.intro_viewed)
	return settings_data

# 分发存档数据到各个组件
func distribute_save_data(save_data: Dictionary) -> bool:
	print("GameSaveManager: 开始分发存档数据")
	
	# 验证存档版本
	if not save_data.has("version"):
		print("GameSaveManager: 警告 - 存档缺少版本信息")
	
	# 分发游戏进度数据
	if save_data.has("game_progress") and TimeManager:
		var progress_data = save_data.game_progress
		TimeManager.set_current_round(progress_data.get("current_round", 1))
		TimeManager.set_scene_type(progress_data.get("current_scene_type", "workday"))
		TimeManager.workday_round_count = progress_data.get("workday_round_count", 0)
		TimeManager.weekend_round_count = progress_data.get("weekend_round_count", 0)
		TimeManager.is_settlement_in_progress = progress_data.get("is_settlement_in_progress", false)
		print("GameSaveManager: 分发游戏进度数据 - 回合:", progress_data.get("current_round", 1))
	
	# 分发玩家属性数据
	if save_data.has("player_attributes") and AttributeManager:
		var attr_data = save_data.player_attributes
		AttributeManager.set_attribute("power", attr_data.get("power", 1))
		AttributeManager.set_attribute("reputation", attr_data.get("reputation", 1))
		AttributeManager.set_attribute("piety", attr_data.get("piety", 1))
		AttributeManager.set_coins(attr_data.get("coins", 5))
		if attr_data.has("attribute_history"):
			AttributeManager.attribute_history = attr_data.attribute_history
		print("GameSaveManager: 分发玩家属性数据 - 金币:", attr_data.get("coins", 5))
	
	# 分发卡牌数据
	if save_data.has("cards"):
		distribute_cards_data(save_data.cards)
	
	# 分发事件数据
	if save_data.has("events"):
		distribute_events_data(save_data.events)
	
	# 分发设置数据
	if save_data.has("settings"):
		distribute_settings_data(save_data.settings)
	
	print("GameSaveManager: 存档数据分发完成")
	return true

# 分发卡牌数据
func distribute_cards_data(cards_data: Dictionary):
	# 特权卡数据
	if cards_data.has("privilege_cards") and PrivilegeCardManager:
		var privilege_save_data = {"privilege_cards": cards_data.privilege_cards}
		PrivilegeCardManager.load_cards_data(privilege_save_data)
		print("GameSaveManager: 分发特权卡数据 - 数量:", cards_data.privilege_cards.size())
	
	# 情报卡背包数据
	if cards_data.has("item_card_inventory") and ItemCardInventoryManager:
		ItemCardInventoryManager.deserialize_inventory(cards_data.item_card_inventory)
		print("GameSaveManager: 分发情报卡数据 - 数量:", cards_data.item_card_inventory.size())
	
	# 角色卡解锁数据
	if cards_data.has("character_unlocked") and CharacterCardManager:
		if CharacterCardManager.has_method("load_unlocked_cards"):
			CharacterCardManager.load_unlocked_cards(cards_data.character_unlocked)
			print("GameSaveManager: 分发角色卡解锁数据")
	
	# 卡牌使用状态数据
	if cards_data.has("card_usage_states") and GlobalCardUsageManager:
		if GlobalCardUsageManager.has_method("deserialize_usage_data"):
			GlobalCardUsageManager.deserialize_usage_data(cards_data.card_usage_states)
			print("GameSaveManager: 分发卡牌使用状态数据")

# 分发事件数据
func distribute_events_data(events_data: Dictionary):
	# EventManager数据
	if EventManager:
		if events_data.has("completed_events"):
			EventManager.completed_events = events_data.completed_events
		if events_data.has("event_trigger_counts"):
			EventManager.event_trigger_counts = events_data.event_trigger_counts
		if events_data.has("event_last_completed"):
			EventManager.event_last_completed = events_data.event_last_completed
		print("GameSaveManager: 分发事件管理器数据")
	
	# EventSlotManager数据
	if events_data.has("event_slots") and EventSlotManager:
		if EventSlotManager.has_method("deserialize_slots"):
			EventSlotManager.deserialize_slots(events_data.event_slots)
			print("GameSaveManager: 分发事件卡槽数据")

# 分发设置数据
func distribute_settings_data(settings_data: Dictionary):
	# 保存设置到原有文件以保持兼容性
	var game_data = {
		"intro_viewed": settings_data.get("intro_viewed", false),
		"selected_card_type": settings_data.get("initial_card_selected", "")
	}
	
	var file = FileAccess.open("user://game_data.cfg", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(game_data))
		file.close()
		print("GameSaveManager: 分发设置数据完成")

# 写入存档文件
func write_save_file(save_data: Dictionary) -> bool:
	# 创建备份
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var backup_success = copy_file(SAVE_FILE_PATH, BACKUP_SAVE_PATH)
		if backup_success:
			print("GameSaveManager: 创建存档备份成功")
		else:
			print("GameSaveManager: 警告 - 创建存档备份失败")
	
	# 写入新存档
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if not file:
		print("GameSaveManager: 错误 - 无法创建存档文件")
		return false
	
	var json_string = JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	
	print("GameSaveManager: 存档文件写入成功，大小:", json_string.length(), "字符")
	return true

# 读取存档文件
func read_save_file() -> Dictionary:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("GameSaveManager: 存档文件不存在")
		return {}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		print("GameSaveManager: 错误 - 无法打开存档文件")
		# 尝试加载备份
		return try_load_backup()
	
	var content = file.get_as_text()
	file.close()
	
	if content.is_empty():
		print("GameSaveManager: 存档文件为空")
		return try_load_backup()
	
	var json = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		print("GameSaveManager: 存档文件解析失败，错误代码:", parse_result)
		return try_load_backup()
	
	print("GameSaveManager: 存档文件读取成功")
	return json.data

# 尝试加载备份存档
func try_load_backup() -> Dictionary:
	if not FileAccess.file_exists(BACKUP_SAVE_PATH):
		print("GameSaveManager: 备份存档也不存在")
		return {}
	
	print("GameSaveManager: 尝试加载备份存档")
	var file = FileAccess.open(BACKUP_SAVE_PATH, FileAccess.READ)
	if not file:
		print("GameSaveManager: 无法打开备份存档")
		return {}
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		print("GameSaveManager: 备份存档解析失败")
		return {}
	
	print("GameSaveManager: 备份存档加载成功")
	return json.data

# 复制文件
func copy_file(source_path: String, dest_path: String) -> bool:
	var source_file = FileAccess.open(source_path, FileAccess.READ)
	if not source_file:
		return false
	
	var content = source_file.get_as_text()
	source_file.close()
	
	var dest_file = FileAccess.open(dest_path, FileAccess.WRITE)
	if not dest_file:
		return false
	
	dest_file.store_string(content)
	dest_file.close()
	return true

# 检查是否有存档
func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

# 获取存档信息
func get_save_info() -> Dictionary:
	if not has_save_file():
		return {}
	
	var save_data = read_save_file()
	if save_data.is_empty():
		return {}
	
	return {
		"version": save_data.get("version", "未知"),
		"save_timestamp": save_data.get("save_timestamp", 0),
		"current_round": save_data.get("game_progress", {}).get("current_round", 1),
		"current_scene_type": save_data.get("game_progress", {}).get("current_scene_type", "workday"),
		"current_scene": save_data.get("game_progress", {}).get("current_scene_type", "workday")
	}

# 删除存档
func delete_save() -> bool:
	var success = true
	
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var error = DirAccess.remove_absolute(SAVE_FILE_PATH)
		if error != OK:
			print("GameSaveManager: 删除主存档失败，错误代码:", error)
			success = false
		else:
			print("GameSaveManager: 主存档删除成功")
	
	if FileAccess.file_exists(BACKUP_SAVE_PATH):
		var error = DirAccess.remove_absolute(BACKUP_SAVE_PATH)
		if error != OK:
			print("GameSaveManager: 删除备份存档失败，错误代码:", error)
			success = false
		else:
			print("GameSaveManager: 备份存档删除成功")
	
	# 清空缓存
	cached_save_data.clear()
	
	return success

# 应用退出时自动保存
func _on_quit_request():
	print("GameSaveManager: 应用即将退出，执行自动保存")
	
	# 确保TimeManager使用正确的当前场景类型进行存档
	if TimeManager:
		# 如果有场景切换在进行中，先强制确认以保存正确状态
		if TimeManager.is_scene_change_pending():
			print("GameSaveManager: 检测到场景切换进行中，使用实际当前场景进行存档")
		
		# 强制保存TimeManager状态，确保使用实际场景类型
		TimeManager.save_game_state()
		print("GameSaveManager: TimeManager状态已保存")
	
	# 执行完整的游戏保存
	save_game()
	print("GameSaveManager: 退出前自动保存完成")

# 获取调试信息
func get_debug_info() -> Dictionary:
	return {
		"has_save_file": has_save_file(),
		"has_backup": FileAccess.file_exists(BACKUP_SAVE_PATH),
		"cached_data_size": cached_save_data.size(),
		"is_saving": is_saving,
		"is_loading": is_loading,
		"save_info": get_save_info()
	} 
