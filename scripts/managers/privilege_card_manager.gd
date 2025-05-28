extends Node

# PrivilegeCardManager - 特权卡管理器单例
# 管理所有特权卡的获得、使用、过期逻辑

signal card_added(card: PrivilegeCard)
signal card_removed(card: PrivilegeCard)
signal cards_updated()

var privilege_cards: Array[PrivilegeCard] = []
const MAX_CARDS = 28
const CARD_LIFETIME = 7  # 卡片生命周期：7回合

const CARD_TYPES = ["挥霍", "装X", "陷害", "秘会"]
const CARD_TEXTURES = {
	"挥霍": "res://assets/cards/挥霍卡.png",
	"装X": "res://assets/cards/装X卡.png",
	"陷害": "res://assets/cards/陷害卡.png",
	"秘会": "res://assets/cards/秘会卡.png"
}

func _ready():
	# 连接TimeManager的信号
	if TimeManager:
		TimeManager.round_changed.connect(_on_round_changed)

# 获得新的特权卡
func add_privilege_card(card_type: String) -> bool:
	if privilege_cards.size() >= MAX_CARDS:
		print("Privilege Card Manager: 已达到卡片上限")
		return false
	
	var new_card = PrivilegeCard.new()
	new_card.card_type = card_type
	new_card.card_id = generate_card_id()
	new_card.acquired_round = TimeManager.get_current_round()
	new_card.remaining_rounds = CARD_LIFETIME
	new_card.texture_path = CARD_TEXTURES.get(card_type, "")
	
	privilege_cards.append(new_card)
	card_added.emit(new_card)
	cards_updated.emit()
	
	print("Privilege Card Manager: 获得新卡片 - ", card_type, " (ID: ", new_card.card_id, ")")
	return true

# 移除特权卡
func remove_privilege_card(card_id: String) -> bool:
	for i in range(privilege_cards.size()):
		if privilege_cards[i].card_id == card_id:
			var removed_card = privilege_cards[i]
			privilege_cards.remove_at(i)
			card_removed.emit(removed_card)
			cards_updated.emit()
			print("Privilege Card Manager: 移除卡片 - ", removed_card.card_type, " (ID: ", card_id, ")")
			return true
	return false

# 获取所有特权卡
func get_all_cards() -> Array[PrivilegeCard]:
	return privilege_cards

# 获取最快到期的卡片
func get_soonest_expiring_card() -> PrivilegeCard:
	if privilege_cards.is_empty():
		return null
	
	var soonest_card = privilege_cards[0]
	for card in privilege_cards:
		if card.remaining_rounds < soonest_card.remaining_rounds:
			soonest_card = card
	
	return soonest_card

# 获取所有特权卡中倒计时的最小值
func get_minimum_remaining_rounds() -> int:
	if privilege_cards.is_empty():
		return -1  # 表示没有特权卡
	
	var min_rounds = privilege_cards[0].remaining_rounds
	for card in privilege_cards:
		if card.remaining_rounds < min_rounds:
			min_rounds = card.remaining_rounds
	
	return min_rounds

# 获取当前卡片数量
func get_card_count() -> int:
	return privilege_cards.size()

# 检查是否可以获得新卡片
func can_add_card() -> bool:
	return privilege_cards.size() < MAX_CARDS

# 回合变化时的处理
func _on_round_changed(new_round: int):
	var expired_cards = []
	
	# 更新所有卡片的剩余回合数
	for card in privilege_cards:
		card.remaining_rounds -= 1
		if card.remaining_rounds <= 0:
			expired_cards.append(card)
	
	# 移除过期卡片
	for expired_card in expired_cards:
		remove_privilege_card(expired_card.card_id)
	
	if expired_cards.size() > 0:
		print("Privilege Card Manager: 移除了 ", expired_cards.size(), " 张过期卡片")

# 生成唯一卡片ID
func generate_card_id() -> String:
	return "card_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

# 保存特权卡数据
func save_cards_data() -> Dictionary:
	var cards_data = []
	for card in privilege_cards:
		cards_data.append({
			"card_type": card.card_type,
			"card_id": card.card_id,
			"acquired_round": card.acquired_round,
			"remaining_rounds": card.remaining_rounds,
			"texture_path": card.texture_path
		})
	return {"privilege_cards": cards_data}

# 加载特权卡数据
func load_cards_data(data: Dictionary):
	privilege_cards.clear()
	var cards_data = data.get("privilege_cards", [])
	
	for card_data in cards_data:
		var card = PrivilegeCard.new()
		card.card_type = card_data.get("card_type", "")
		card.card_id = card_data.get("card_id", "")
		card.acquired_round = card_data.get("acquired_round", 1)
		card.remaining_rounds = card_data.get("remaining_rounds", CARD_LIFETIME)
		card.texture_path = card_data.get("texture_path", "")
		privilege_cards.append(card)
	
	cards_updated.emit()
	print("Privilege Card Manager: 加载了 ", privilege_cards.size(), " 张特权卡") 