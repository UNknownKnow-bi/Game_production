class_name CharacterCardInventory
extends Node

# 已解锁的角色卡ID列表
var unlocked_cards: Array[String] = []

# 卡片管理器引用
var card_manager: CardManager

func _init(manager: CardManager):
    card_manager = manager

# 解锁角色卡
func unlock_card(card_id: String) -> bool:
    if not card_manager.get_card_by_id(card_id):
        return false
        
    if not unlocked_cards.has(card_id):
        unlocked_cards.append(card_id)
        print("解锁角色卡: ", card_id)
        return true
    
    return false

# 检查角色卡是否已解锁
func is_card_unlocked(card_id: String) -> bool:
    return unlocked_cards.has(card_id)

# 获取所有已解锁的角色卡数据
func get_unlocked_cards() -> Array:
    var result = []
    for card_id in unlocked_cards:
        var card_data = card_manager.get_card_by_id(card_id)
        if card_data:
            result.append(card_data)
    return result

# 保存解锁状态
func save_unlocked_cards(file_path: String = "user://card_inventory.save") -> bool:
    var file = FileAccess.open(file_path, FileAccess.WRITE)
    if not file:
        printerr("无法打开文件保存解锁状态: ", file_path)
        return false
        
    var save_data = {
        "unlocked_cards": unlocked_cards
    }
    
    file.store_string(JSON.stringify(save_data))
    file.close()
    return true

# 加载解锁状态
func load_unlocked_cards(file_path: String = "user://card_inventory.save") -> bool:
    if not FileAccess.file_exists(file_path):
        print("解锁状态文件不存在: ", file_path)
        return false
        
    var file = FileAccess.open(file_path, FileAccess.READ)
    if not file:
        printerr("无法打开文件加载解锁状态: ", file_path)
        return false
        
    var content = file.get_as_text()
    file.close()
    
    var json_result = JSON.parse_string(content)
    if json_result == null or typeof(json_result) != TYPE_DICTIONARY:
        printerr("解析解锁状态数据失败")
        return false
        
    if json_result.has("unlocked_cards"):
        unlocked_cards = json_result.unlocked_cards
        print("已加载 %d 个已解锁角色卡" % unlocked_cards.size())
        return true
        
    return false 