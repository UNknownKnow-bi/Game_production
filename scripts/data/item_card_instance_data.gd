class_name ItemCardInstanceData
extends Resource

# 情报卡实例数据类
# 表示玩家背包中的一张情报卡实例

@export var instance_id: String = ""         # 实例唯一ID
@export var card_id: int = 0                # 原始卡牌ID
@export var acquired_time: int = 0           # 获得时间戳

# 缓存的原始卡牌数据引用
var _original_card_data: ItemCardData = null

# 初始化
func _init():
	instance_id = generate_instance_id()
	acquired_time = Time.get_unix_time_from_system()

# 生成唯一实例ID
func generate_instance_id() -> String:
	var timestamp = Time.get_unix_time_from_system()
	var random_suffix = randi() % 10000
	return "item_%d_%04d" % [timestamp, random_suffix]

# 设置原始卡牌ID
func set_card_id(id: int) -> void:
	card_id = id
	_original_card_data = null  # 清除缓存，下次访问时重新获取

# 获取原始卡牌数据
func get_original_card_data() -> ItemCardData:
	if not _original_card_data and ItemCardManager:
		_original_card_data = ItemCardManager.get_card_by_id(card_id)
	return _original_card_data

# 获取卡牌名称
func get_card_name() -> String:
	var original_data = get_original_card_data()
	return original_data.card_name if original_data else "未知情报卡"

# 获取卡牌等级
func get_card_level() -> String:
	var original_data = get_original_card_data()
	return original_data.card_level if original_data else "P1"

# 获取卡牌属性
func get_attributes() -> Dictionary:
	var original_data = get_original_card_data()
	return original_data.get_attributes() if original_data else {}

# 获取卡牌描述
func get_description() -> String:
	var original_data = get_original_card_data()
	return original_data.card_description if original_data else ""

# 获取卡牌图片路径
func get_card_image_path() -> String:
	var original_data = get_original_card_data()
	return original_data.get_item_image_path() if original_data else ""

# 获取卡牌底图路径
func get_card_base_path() -> String:
	var original_data = get_original_card_data()
	return original_data.get_card_base_path() if original_data else ""

# 验证数据完整性
func validate() -> bool:
	if instance_id.is_empty():
		printerr("ItemCardInstanceData: instance_id为空")
		return false
	
	if card_id <= 0:
		printerr("ItemCardInstanceData: card_id无效")
		return false
	
	if acquired_time <= 0:
		printerr("ItemCardInstanceData: acquired_time无效")
		return false
	
	return true 