class_name GameEvent
extends Resource

@export var event_id: int
@export var event_type: String
@export var event_name: String
@export var event_group_name: String
@export var valid_rounds: Array[int] = []
@export var duration_rounds: int
@export var prerequisite_conditions: Dictionary = {}
@export var max_occurrences: int
@export var cooldown: int
@export var global_check: Dictionary = {}
@export var attribute_aggregation: Dictionary = {}
@export var icon_path: String
@export var background_path: String
@export var audio_path: String

# 辅助函数
func get_event_category() -> String:
    var id_str = str(event_id)
    if id_str.begins_with("1"):
        return "character"
    elif id_str.begins_with("2"):
        return "random"
    elif id_str.begins_with("3"):
        return "daily"
    elif id_str.begins_with("4"):
        return "ending"
    return "unknown"

# 检查事件是否在当前回合有效
func is_valid_in_round(round_number: int) -> bool:
    # 检查valid_rounds是否包含当前回合
    if valid_rounds.is_empty():
        return true
    return round_number in valid_rounds

# 获取事件详细描述
func get_description() -> String:
    var desc = "[b]%s[/b]\n" % event_name
    desc += "类型: %s\n" % event_type
    desc += "组别: %s\n" % event_group_name
    
    # 添加检定信息
    if not global_check.is_empty():
        var check_mode = global_check.get("check_mode", "")
        if check_mode == "single_attribute":
            var attr_check = global_check.get("single_attribute_check", {})
            desc += "检定: %s 属性, 阈值 %s\n" % [
                attr_check.get("attribute_name", ""),
                attr_check.get("threshold", 0)
            ]
        elif check_mode == "multi_attribute":
            var checks = global_check.get("multi_attribute_check", [])
            desc += "多属性检定:\n"
            for check in checks:
                desc += " - %s 属性, 阈值 %s\n" % [
                    check.get("attribute_name", ""),
                    check.get("threshold", 0)
                ]
    
    return desc 