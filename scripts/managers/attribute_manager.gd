extends Node

# AttributeManager - 全局属性管理器单例
# 管理游戏中的三个核心属性：权势、声望、虔信，以及金币系统

signal attribute_changed(attribute_name: String, old_value: int, new_value: int)
signal coins_changed(old_value: int, new_value: int)
signal attributes_loaded
signal item_card_acquired_notification(card_instance: ItemCardInstanceData)

# 全局属性数据
var global_attributes = {
	"power": 1,       # 权势属性
	"reputation": 1,  # 声望属性  
	"piety": 1        # 虔信属性
}

# 金币系统
var coins: int = 5  # 初始金币数量

# 属性变化历史（可选，用于调试和统计）
var attribute_history = []

# 属性名称映射（用于UI显示）
var attribute_display_names = {
	"power": "权势",
	"reputation": "声望",
	"piety": "虔信"
}

# 数据文件路径
const SAVE_FILE_PATH = "user://attribute_data.save"

func _ready():
	print("AttributeManager: 开始初始化")
	load_attributes()
	
	# 连接情报卡获得通知
	if ItemCardInventoryManager:
		ItemCardInventoryManager.item_card_acquired.connect(_on_item_card_acquired)
		print("AttributeManager: 已连接情报卡获得通知")
	
	print("AttributeManager: 初始化完成")
	print("AttributeManager: 当前属性值 - ", global_attributes)
	print("AttributeManager: 当前金币数量 - ", coins)

# 处理情报卡获得通知
func _on_item_card_acquired(card_instance: ItemCardInstanceData):
	print("AttributeManager: 接收到情报卡获得通知 - ", card_instance.get_card_name())
	item_card_acquired_notification.emit(card_instance)

# ========== 属性系统方法 ==========

# 获取指定属性值
func get_attribute(attr_name: String) -> int:
	if global_attributes.has(attr_name):
		return global_attributes[attr_name]
	else:
		print("AttributeManager: 警告 - 未知属性名称: ", attr_name)
		return 0

# 设置指定属性值
func set_attribute(attr_name: String, value: int):
	if not global_attributes.has(attr_name):
		print("AttributeManager: 警告 - 未知属性名称: ", attr_name)
		return
	
	var old_value = global_attributes[attr_name]
	global_attributes[attr_name] = max(1, value)  # 确保属性值不低于1
	
	# 记录变化历史
	_record_attribute_change(attr_name, old_value, global_attributes[attr_name], "set")
	
	# 发射信号
	attribute_changed.emit(attr_name, old_value, global_attributes[attr_name])
	
	print("AttributeManager: 设置属性 ", attr_name, " 从 ", old_value, " 到 ", global_attributes[attr_name])

# 修改指定属性值（增加或减少）
func modify_attribute(attr_name: String, delta: int):
	if not global_attributes.has(attr_name):
		print("AttributeManager: 警告 - 未知属性名称: ", attr_name)
		return
	
	var old_value = global_attributes[attr_name]
	global_attributes[attr_name] = max(1, old_value + delta)  # 确保属性值不低于1
	
	# 记录变化历史
	_record_attribute_change(attr_name, old_value, global_attributes[attr_name], "modify", delta)
	
	# 发射信号
	attribute_changed.emit(attr_name, old_value, global_attributes[attr_name])
	
	print("AttributeManager: 修改属性 ", attr_name, " 变化 ", delta, " (", old_value, " -> ", global_attributes[attr_name], ")")

# ========== 金币系统方法 ==========

# 获取当前金币数量
func get_coins() -> int:
	return coins

# 设置金币数量
func set_coins(value: int):
	var old_value = coins
	coins = max(0, value)  # 确保金币不为负数
	
	# 记录变化历史
	_record_attribute_change("coins", old_value, coins, "set")
	
	# 发射信号
	coins_changed.emit(old_value, coins)
	
	print("AttributeManager: 设置金币从 ", old_value, " 到 ", coins)

# 修改金币数量（增加或减少）
func modify_coins(delta: int):
	var old_value = coins
	coins = max(0, coins + delta)  # 确保金币不为负数
	
	# 记录变化历史
	_record_attribute_change("coins", old_value, coins, "modify", delta)
	
	# 发射信号
	coins_changed.emit(old_value, coins)
	
	print("AttributeManager: 修改金币变化 ", delta, " (", old_value, " -> ", coins, ")")

# 检查是否有足够的金币
func has_enough_coins(amount: int) -> bool:
	return coins >= amount

# 尝试消费金币（如果金币足够）
func try_spend_coins(amount: int) -> bool:
	if has_enough_coins(amount):
		modify_coins(-amount)
		return true
	else:
		print("AttributeManager: 金币不足 - 需要 ", amount, " 当前 ", coins)
		return false

# 添加金币
func add_coins(amount: int):
	if amount > 0:
		modify_coins(amount)

# ========== 通用方法 ==========

# 获取所有属性值
func get_all_attributes() -> Dictionary:
	return global_attributes.duplicate()

# 获取属性显示名称
func get_attribute_display_name(attr_name: String) -> String:
	return attribute_display_names.get(attr_name, attr_name)

# 获取所有属性的显示信息
func get_attributes_display_info() -> Array:
	var display_info = []
	for attr_name in global_attributes.keys():
		display_info.append({
			"name": attr_name,
			"display_name": get_attribute_display_name(attr_name),
			"value": global_attributes[attr_name]
		})
	return display_info

# 检查属性是否满足要求
func check_attribute_requirement(attr_name: String, required_value: int) -> bool:
	var current_value = get_attribute(attr_name)
	return current_value >= required_value

# 检查多个属性要求
func check_multiple_requirements(requirements: Dictionary) -> bool:
	for attr_name in requirements.keys():
		if not check_attribute_requirement(attr_name, requirements[attr_name]):
			return false
	return true

# 重置所有属性为默认值
func reset_attributes():
	var old_attributes = global_attributes.duplicate()
	var old_coins = coins
	
	for attr_name in global_attributes.keys():
		global_attributes[attr_name] = 1
	
	coins = 5  # 重置金币为初始值
	
	# 记录重置操作
	_record_attribute_change("all", old_attributes, global_attributes, "reset")
	_record_attribute_change("coins", old_coins, coins, "reset")
	
	print("AttributeManager: 所有属性已重置为1，金币重置为5")
	
	# 发射信号
	for attr_name in global_attributes.keys():
		attribute_changed.emit(attr_name, old_attributes[attr_name], 1)
	coins_changed.emit(old_coins, coins)

# 保存属性数据到文件
func save_attributes():
	var save_data = {
		"global_attributes": global_attributes,
		"coins": coins,  # 保存金币数据
		"attribute_history": attribute_history,
		"save_timestamp": Time.get_unix_time_from_system(),
		"version": "3.0"  # 标记包含金币系统的新版本
	}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("AttributeManager: 属性数据已保存到 ", SAVE_FILE_PATH)
	else:
		print("AttributeManager: 错误 - 无法保存属性数据")

# 从文件加载属性数据
func load_attributes():
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("AttributeManager: 保存文件不存在，使用默认属性值")
		attributes_loaded.emit()
		return
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		print("AttributeManager: 错误 - 无法打开保存文件")
		attributes_loaded.emit()
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("AttributeManager: 错误 - 保存文件格式无效")
		attributes_loaded.emit()
		return
	
	var save_data = json.data
	
	# 检查数据版本并进行迁移
	if save_data.has("version") and save_data.version == "3.0":
		# 最新版本数据，直接加载
		if save_data.has("global_attributes"):
			for attr_name in global_attributes.keys():
				if save_data.global_attributes.has(attr_name):
					global_attributes[attr_name] = save_data.global_attributes[attr_name]
		
		if save_data.has("coins"):
			coins = save_data.coins
		
		print("AttributeManager: 加载最新版本属性数据（包含金币）")
	elif save_data.has("version") and save_data.version == "2.0":
		# 版本2.0数据，需要添加金币
		if save_data.has("global_attributes"):
			for attr_name in global_attributes.keys():
				if save_data.global_attributes.has(attr_name):
					global_attributes[attr_name] = save_data.global_attributes[attr_name]
		
		# 金币使用默认值5
		coins = 5
		print("AttributeManager: 从版本2.0迁移，金币设为默认值5")
	else:
		# 旧版本数据，需要迁移
		print("AttributeManager: 检测到旧版本数据，开始迁移")
		_migrate_old_attributes(save_data)
	
	if save_data.has("attribute_history"):
		attribute_history = save_data.attribute_history
	
	print("AttributeManager: 属性数据已从文件加载")
	print("AttributeManager: 加载的属性值 - ", global_attributes)
	print("AttributeManager: 加载的金币数量 - ", coins)
	
	attributes_loaded.emit()

# 迁移旧属性数据
func _migrate_old_attributes(save_data: Dictionary):
	if save_data.has("global_attributes"):
		var old_attributes = save_data.global_attributes
		
		# 简单的迁移策略：将旧属性值的平均值分配给新属性
		var total_old_value = 0
		var old_count = 0
		
		for old_attr in ["social", "technical", "creative"]:
			if old_attributes.has(old_attr):
				total_old_value += old_attributes[old_attr]
				old_count += 1
		
		if old_count > 0:
			var average_value = max(1, total_old_value / old_count)
			for attr_name in global_attributes.keys():
				global_attributes[attr_name] = average_value
			print("AttributeManager: 旧属性迁移完成，新属性值设为: ", average_value)
		else:
			print("AttributeManager: 未找到有效的旧属性数据，使用默认值")
	
	# 金币使用默认值
	coins = 5
	print("AttributeManager: 金币设为默认值5")
	
	# 保存迁移后的数据
	save_attributes()

# 记录属性变化历史
func _record_attribute_change(attr_name: String, old_value, new_value, operation: String, delta: int = 0):
	var change_record = {
		"timestamp": Time.get_unix_time_from_system(),
		"attribute": attr_name,
		"old_value": old_value,
		"new_value": new_value,
		"operation": operation,
		"delta": delta
	}
	
	attribute_history.append(change_record)
	
	# 限制历史记录数量（保留最近100条）
	if attribute_history.size() > 100:
		attribute_history = attribute_history.slice(-100)

# 获取属性变化历史
func get_attribute_history(attr_name: String = "") -> Array:
	if attr_name.is_empty():
		return attribute_history.duplicate()
	else:
		var filtered_history = []
		for record in attribute_history:
			if record.attribute == attr_name:
				filtered_history.append(record)
		return filtered_history

# 获取调试信息
func get_debug_info() -> Dictionary:
	return {
		"global_attributes": global_attributes,
		"coins": coins,
		"history_count": attribute_history.size(),
		"save_file_exists": FileAccess.file_exists(SAVE_FILE_PATH)
	}

# 打印调试信息
func print_debug_info():
	print("=== AttributeManager 调试信息 ===")
	print("全局属性: ", global_attributes)
	print("金币数量: ", coins)
	print("历史记录数: ", attribute_history.size())
	print("保存文件存在: ", FileAccess.file_exists(SAVE_FILE_PATH))
	print("=== 调试信息结束 ===") 