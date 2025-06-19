extends Node

# 情报卡背包管理器
# 管理玩家拥有的情报卡实例

# 单例模式
static var instance: ItemCardInventoryManager

# 玩家背包中的情报卡实例列表（初始为空）
var inventory_items: Array[ItemCardInstanceData] = []

# 信号
signal item_card_acquired(card_instance: ItemCardInstanceData)
signal inventory_updated()

# 初始化
func _ready():
	if instance == null:
		instance = self
		print("=== ItemCardInventoryManager 初始化开始 ===")
		print("ItemCardInventoryManager: 初始化空背包")
		inventory_items = []
		print("ItemCardInventoryManager: 背包大小 - ", inventory_items.size())
	else:
		queue_free()

# 随机获得一张情报卡
func acquire_random_item_card() -> ItemCardInstanceData:
	print("ItemCardInventoryManager: 开始随机获得情报卡")
	
	# 从ItemCardManager获取所有可用的情报卡
	if not ItemCardManager:
		printerr("ItemCardInventoryManager: ItemCardManager未找到")
		return null
	
	var all_cards = ItemCardManager.get_all_cards()
	if all_cards.is_empty():
		printerr("ItemCardInventoryManager: 没有可用的情报卡配置")
		return null
	
	# 随机选择一张卡片
	var random_index = randi() % all_cards.size()
	var selected_card_data = all_cards[random_index]
	
	print("ItemCardInventoryManager: 随机选中情报卡 - ", selected_card_data.card_name)
	
	# 创建情报卡实例
	var card_instance = ItemCardInstanceData.new()
	card_instance.set_card_id(selected_card_data.card_id)
	
	# 添加到背包
	add_item_card_instance(card_instance)
	
	print("ItemCardInventoryManager: 情报卡已添加到背包 - ", card_instance.get_card_name())
	return card_instance

# 添加情报卡实例到背包
func add_item_card_instance(card_instance: ItemCardInstanceData) -> void:
	if not card_instance or not card_instance.validate():
		printerr("ItemCardInventoryManager: 尝试添加无效的情报卡实例")
		return
	
	inventory_items.append(card_instance)
	print("ItemCardInventoryManager: 情报卡实例已添加 - ", card_instance.get_card_name(), " (实例ID: ", card_instance.instance_id, ")")
	
	# 发射信号
	item_card_acquired.emit(card_instance)
	inventory_updated.emit()

# 移除情报卡实例
func remove_item_card_instance(instance_id: String) -> bool:
	for i in range(inventory_items.size()):
		if inventory_items[i].instance_id == instance_id:
			var removed_card = inventory_items[i]
			inventory_items.remove_at(i)
			print("ItemCardInventoryManager: 移除情报卡实例 - ", removed_card.get_card_name())
			inventory_updated.emit()
			return true
	
	print("ItemCardInventoryManager: 未找到要移除的情报卡实例 - ", instance_id)
	return false

# 获取背包中的所有情报卡实例
func get_all_instances() -> Array[ItemCardInstanceData]:
	return inventory_items.duplicate()

# 根据实例ID获取情报卡实例
func get_instance_by_id(instance_id: String) -> ItemCardInstanceData:
	for item_instance in inventory_items:
		if item_instance.instance_id == instance_id:
			return item_instance
	return null

# 根据原始卡牌ID获取所有实例
func get_instances_by_card_id(card_id: int) -> Array[ItemCardInstanceData]:
	var matching_instances: Array[ItemCardInstanceData] = []
	for item_instance in inventory_items:
		if item_instance.card_id == card_id:
			matching_instances.append(item_instance)
	return matching_instances

# 获取背包中情报卡的总数量
func get_inventory_count() -> int:
	return inventory_items.size()

# 检查背包是否为空
func is_inventory_empty() -> bool:
	return inventory_items.is_empty()

# 清空背包（用于重置或测试）
func clear_inventory() -> void:
	inventory_items.clear()
	print("ItemCardInventoryManager: 背包已清空")
	inventory_updated.emit()

# 获取背包统计信息
func get_inventory_stats() -> Dictionary:
	var stats = {
		"total_count": inventory_items.size(),
		"by_level": {"P1": 0, "P2": 0, "P3": 0, "P4": 0},
		"by_card_id": {}
	}
	
	for item_instance in inventory_items:
		var level = item_instance.get_card_level()
		if level in stats.by_level:
			stats.by_level[level] += 1
		
		var card_id = item_instance.card_id
		if card_id in stats.by_card_id:
			stats.by_card_id[card_id] += 1
		else:
			stats.by_card_id[card_id] = 1
	
	return stats

# 静态访问方法
static func get_instance():
	return instance

# 存档数据序列化
func serialize_inventory() -> Array:
	var serialized_data = []
	for item_instance in inventory_items:
		serialized_data.append({
			"instance_id": item_instance.instance_id,
			"card_id": item_instance.card_id,
			"acquired_time": item_instance.acquired_time
		})
	return serialized_data

# 存档数据反序列化
func deserialize_inventory(data: Array) -> void:
	inventory_items.clear()
	
	for item_data in data:
		if item_data is Dictionary:
			var card_instance = ItemCardInstanceData.new()
			card_instance.instance_id = item_data.get("instance_id", "")
			card_instance.card_id = item_data.get("card_id", 0)
			card_instance.acquired_time = item_data.get("acquired_time", 0)
			
			if card_instance.validate():
				inventory_items.append(card_instance)
			else:
				print("ItemCardInventoryManager: 跳过无效的存档数据 - ", item_data)
	
	print("ItemCardInventoryManager: 从存档加载了 ", inventory_items.size(), " 张情报卡")
	inventory_updated.emit() 