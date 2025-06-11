class_name PrivilegeCard
extends Resource

# 特权卡数据类
# 定义特权卡的所有属性

@export var card_type: String = ""  # 卡片类型："挥霍"/"装X"/"陷害"/"秘会"
@export var card_id: String = ""    # 唯一标识符
@export var acquired_round: int = 1  # 获得时的回合数
@export var remaining_rounds: int = 7  # 剩余生命周期
@export var texture_path: String = ""  # 卡片图片路径

func _init(type: String = "", id: String = "", acquired: int = 1, remaining: int = 7, texture: String = ""):
	card_type = type
	card_id = id
	acquired_round = acquired
	remaining_rounds = remaining
	texture_path = texture

# 获取卡片显示名称
func get_display_name() -> String:
	return card_type + "卡"

# 获取卡片类型
func get_card_type() -> String:
	return card_type

# 检查卡片是否即将过期（剩余回合数 <= 2）
func is_expiring_soon() -> bool:
	return remaining_rounds <= 2

# 检查卡片是否已过期
func is_expired() -> bool:
	return remaining_rounds <= 0

# 获取卡片状态描述
func get_status_text() -> String:
	if is_expired():
		return "已过期"
	elif is_expiring_soon():
		return "即将过期 (" + str(remaining_rounds) + "回合)"
	else:
		return "剩余 " + str(remaining_rounds) + " 回合" 