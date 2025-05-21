extends Control

# 卡片管理器引用
@onready var card_manager = get_node("/root/CharacterCardManager")

# 卡片场景
const CharacterCardScene = preload("res://scenes/character_card.tscn")

@onready var grid_container = $ScrollContainer/GridContainer

func _ready():
    print("使用自动加载的CharacterCardManager")
    
    # 等待卡片数据加载完成
    await get_tree().process_frame
    
    # 创建所有角色卡
    create_all_cards()

# 创建所有角色卡
func create_all_cards():
    var all_cards = card_manager.get_all_cards()
    
    for card_data in all_cards:
        var card_instance = CharacterCardScene.instantiate()
        grid_container.add_child(card_instance)
        
        # 设置卡片数据
        card_instance.set_card_data(card_data)
        
        # 连接点击信号
        card_instance.card_clicked.connect(_on_card_clicked.bind(card_data.card_id))
        
    print("已创建 %d 个角色卡" % all_cards.size())

# 卡片点击处理
func _on_card_clicked(card_id: String):
    print("点击了角色卡：", card_id)
    # 这里可以添加更多交互，如显示详情、添加到背包等 