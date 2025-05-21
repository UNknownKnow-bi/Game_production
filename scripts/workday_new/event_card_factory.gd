class_name EventCardFactory
extends Node

# 根据事件类型创建卡片
static func create_card(event_type: String):
    var card_scene_path = ""
    
    match event_type:
        "character":
            card_scene_path = "res://scenes/workday_new/components/character_event_card_fixed.tscn"
        _:
            # 使用基础事件卡片
            card_scene_path = "res://scenes/workday_new/components/base_event_card.tscn"
    
    var card_scene = load(card_scene_path)
    if card_scene:
        return card_scene.instantiate()
    else:
        printerr("无法加载事件卡片场景: ", card_scene_path)
        return null

# 初始化卡片内容
static func initialize_card(card, event_data):
    if card == null or not event_data is Dictionary:
        return
    
    # 设置基本属性
    if "title" in event_data:
        card.event_title = event_data.title
    
    if "status" in event_data:
        card.event_status = event_data.status
    
    # 人物事件特有属性
    if card is CharacterEventCardFixed:
        if "character" in event_data:
            card.character_name = event_data.character
        
        # 尝试加载角色纹理
        var texture_path = null
        if "character_texture_path" in event_data:
            texture_path = event_data.character_texture_path
        elif "texture_path" in event_data:
            texture_path = event_data.texture_path
            
        if texture_path:
            var char_texture = load(texture_path)
            if char_texture:
                # 设置纹理（必须先设置纹理再设置区域参数）
                card.character_texture = char_texture
                
                # 处理区域裁剪设置
                if "region_enabled" in event_data:
                    card.region_enabled = event_data.region_enabled
                    
                if "region_y_position" in event_data:
                    card.region_y_position = event_data.region_y_position
                    
                if "region_height" in event_data:
                    card.region_height = event_data.region_height
            else:
                print("警告: 无法加载角色图像: ", texture_path)
        
        # 始终设置字体大小为50px，确保所有卡片使用统一字体大小
        card.title_font_size = 50
        card.name_font_size = 50
            
        # 设置背景类型（如果指定）
        if "bg_type" in event_data:
            card.background_type = event_data.bg_type
            
        # 调试信息：打印初始化后的字体大小
        print("初始化卡片: ", card.event_title, " - 标题字体大小: ", card.title_font_size, ", 人物名称字体大小: ", card.name_font_size) 