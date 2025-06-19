class_name PlayerCardData
extends Resource

# 玩家卡牌实例数据基类
# 表示玩家库存中的一张卡牌实例

@export var card_type: String = ""           # 卡牌类型: "character"/"item"/"privilege"
@export var card_id: String = ""             # 原始卡牌ID
@export var instance_id: String = ""         # 玩家库存中的唯一实例ID
@export var base_attributes: Dictionary = {} # 初始属性（获取时记录）
@export var current_attributes: Dictionary = {} # 当前属性（可升级修改）
@export var acquired_time: int = 0           # 获取时间戳
@export var level: int = 1                   # 卡牌等级
@export var experience: int = 0              # 经验值
@export var is_locked: bool = false          # 是否被锁定（正在使用中）
@export var metadata: Dictionary = {}        # 额外元数据

# 初始化
func _init():
	instance_id = generate_instance_id()
	acquired_time = Time.get_unix_time_from_system()

# 生成唯一实例ID
func generate_instance_id() -> String:
	var timestamp = Time.get_unix_time_from_system()
	var random_suffix = randi() % 10000
	return "%s_%d_%04d" % [card_type, timestamp, random_suffix]

# 设置基础数据
func setup_card_data(type: String, id: String, attributes: Dictionary) -> void:
	card_type = type
	card_id = id
	base_attributes = AttributeMapper.map_attributes(type, attributes)
	current_attributes = base_attributes.duplicate()
	
	print("PlayerCardData: 设置卡牌数据 - 类型:", type, " ID:", id)
	print("PlayerCardData: 映射后属性:", current_attributes)

# 获取当前属性
func get_attributes() -> Dictionary:
	return current_attributes.duplicate()

# 获取特定属性值
func get_attribute_value(attr_name: String) -> int:
	return current_attributes.get(attr_name, 0)

# 设置属性值
func set_attribute_value(attr_name: String, value: int) -> bool:
	if not AttributeMapper.STANDARD_ATTRIBUTES.has(attr_name):
		print("PlayerCardData: 警告 - 无效属性名称:", attr_name)
		return false
	
	current_attributes[attr_name] = value
	return true

# 增加属性值
func add_attribute_value(attr_name: String, value: int) -> bool:
	if not AttributeMapper.STANDARD_ATTRIBUTES.has(attr_name):
		print("PlayerCardData: 警告 - 无效属性名称:", attr_name)
		return false
	
	current_attributes[attr_name] = current_attributes.get(attr_name, 0) + value
	return true

# 升级卡牌
func level_up() -> bool:
	if level >= 10:  # 假设最大等级为10
		print("PlayerCardData: 卡牌已达到最大等级")
		return false
	
	level += 1
	# 升级时属性提升（可根据需要调整）
	for attr_name in current_attributes:
		current_attributes[attr_name] += 1
	
	print("PlayerCardData: 卡牌升级到等级", level)
	return true

# 增加经验值
func add_experience(exp: int) -> bool:
	experience += exp
	var exp_needed = get_experience_needed_for_next_level()
	
	if experience >= exp_needed and level < 10:
		experience -= exp_needed
		return level_up()
	
	return false

# 获取升级所需经验
func get_experience_needed_for_next_level() -> int:
	return level * 100  # 简单的经验计算公式

# 锁定卡牌（使用中）
func lock_card() -> void:
	is_locked = true

# 解锁卡牌
func unlock_card() -> void:
	is_locked = false

# 检查是否可用
func is_available() -> bool:
	return not is_locked

# 获取卡牌显示信息
func get_display_info() -> Dictionary:
	return {
		"instance_id": instance_id,
		"card_type": card_type,
		"card_id": card_id,
		"level": level,
		"experience": experience,
		"attributes": current_attributes,
		"is_locked": is_locked
	}

# 验证数据完整性
func validate() -> bool:
	if card_type.is_empty() or card_id.is_empty():
		return false
	
	if not AttributeMapper.validate_attributes(current_attributes):
		print("PlayerCardData: 属性数据不完整，尝试修复")
		current_attributes = AttributeMapper.fix_attributes(current_attributes)
	
	return true

# 序列化为字典
func to_dict() -> Dictionary:
	return {
		"card_type": card_type,
		"card_id": card_id,
		"instance_id": instance_id,
		"base_attributes": base_attributes,
		"current_attributes": current_attributes,
		"acquired_time": acquired_time,
		"level": level,
		"experience": experience,
		"is_locked": is_locked,
		"metadata": metadata
	}

# 从字典反序列化
func from_dict(data: Dictionary) -> void:
	card_type = data.get("card_type", "")
	card_id = data.get("card_id", "")
	instance_id = data.get("instance_id", "")
	base_attributes = data.get("base_attributes", {})
	current_attributes = data.get("current_attributes", {})
	acquired_time = data.get("acquired_time", 0)
	level = data.get("level", 1)
	experience = data.get("experience", 0)
	is_locked = data.get("is_locked", false)
	metadata = data.get("metadata", {})

# 调试信息
func debug_info() -> String:
	return "PlayerCardData[%s]: %s[%s] Lv.%d (%s)" % [
		instance_id, card_type, card_id, level, 
		"锁定" if is_locked else "可用"
	] 
