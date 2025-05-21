extends Node

# 事件集合
var events = {
    "character": {},  # 人物事件 (ID: 1xxxx)
    "random": {},     # 随机事件 (ID: 2xxxx)
    "daily": {},      # 日常事件 (ID: 3xxxx)
    "ending": {}      # 结局事件 (ID: 4xxxx)
}

# 当前活跃事件
var active_events = {
    "character": [],
    "random": [],
    "daily": []
}

# 当前游戏回合
var current_round = 1

# 游戏状态信号
signal events_updated

# 从TSV文件加载事件
func load_events_from_tsv(file_path: String):
    var file = FileAccess.open(file_path, FileAccess.READ)
    if not file:
        printerr("无法打开事件文件: ", file_path)
        return
        
    var content = file.get_as_text()
    file.close()
    
    var lines = content.split("\n")
    var header = lines[0].split("\t")
    
    # 从第二行开始解析数据
    for i in range(1, lines.size()):
        var line = lines[i].strip_edges()
        if line.is_empty():
            continue
            
        var columns = line.split("\t")
        if columns.size() < header.size():
            continue
            
        # 创建事件对象
        var event = GameEvent.new()
        event.event_id = int(columns[0])
        event.event_type = columns[1]
        event.event_name = columns[2]
        event.event_group_name = columns[3]
        
        # 解析有效回合
        var valid_rounds_str = columns[4]
        if not valid_rounds_str.is_empty():
            for round_str in valid_rounds_str.split(","):
                event.valid_rounds.append(int(round_str))
        
        event.duration_rounds = int(columns[5])
        
        # 解析JSON字段
        event.prerequisite_conditions = parse_json_field(columns[6])
        event.max_occurrences = int(columns[7])
        event.cooldown = int(columns[8])
        event.global_check = parse_json_field(columns[9])
        event.attribute_aggregation = parse_json_field(columns[10])
        
        # 设置路径字段
        event.icon_path = columns[11]
        event.background_path = columns[12]
        event.audio_path = columns[13]
        
        # 将事件添加到对应类别
        var category = event.get_event_category()
        if category != "unknown":
            events[category][event.event_id] = event
    
    print("已加载 %d 个事件" % get_total_events_count())

# 获取事件总数
func get_total_events_count() -> int:
    var total = 0
    for category in events:
        total += events[category].size()
    return total

# 解析JSON字符串
func parse_json_field(json_str: String) -> Dictionary:
    if json_str.is_empty():
        return {}
    
    var json_parse_result = JSON.parse_string(json_str)
    if json_parse_result != null:
        return json_parse_result
    else:
        printerr("JSON解析错误: ", json_str)
        return {}

# 获取特定类别的可用事件
func get_available_events(category: String) -> Array:
    var available = []
    if events.has(category):
        for event_id in events[category]:
            var event = events[category][event_id]
            if check_event_availability(event):
                available.append(event)
    return available

# 检查事件是否可用
func check_event_availability(event: GameEvent) -> bool:
    # 检查回合有效性
    if not event.is_valid_in_round(current_round):
        return false
    
    # 检查前置条件
    if not check_prerequisites(event):
        return false
    
    # 这里可以添加更多检查逻辑，如最大触发次数、冷却时间等
    
    return true

# 检查事件前置条件
func check_prerequisites(event: GameEvent) -> bool:
    var prereq = event.prerequisite_conditions
    if prereq.is_empty():
        return true
    
    # 示例检查：回合范围
    if prereq.has("round_range"):
        var range_arr = prereq["round_range"]
        if range_arr.size() >= 2:
            if current_round < range_arr[0] or current_round > range_arr[1]:
                return false
    
    # 这里可以添加更多前置条件检查
    
    return true

# 更新当前回合的可用事件
func update_available_events():
    # 清空当前活跃事件列表
    for category in active_events:
        active_events[category].clear()
    
    # 获取各类事件的可用事件
    for category in events:
        if active_events.has(category):  # 确保类别存在
            var available = get_available_events(category)
            # 这里可以添加事件筛选和随机选择逻辑
            active_events[category] = available
    
    # 发出事件更新信号
    events_updated.emit()
    
    print("已更新可用事件")

# 设置当前回合
func set_current_round(round_number: int):
    current_round = round_number
    update_available_events()

# 获取特定类别的活跃事件
func get_active_events(category: String) -> Array:
    if active_events.has(category):
        return active_events[category]
    return [] 