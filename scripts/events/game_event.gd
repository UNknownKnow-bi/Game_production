class_name GameEvent
extends Resource

@export var event_id: int
@export var event_type: String
@export var event_name: String
@export var event_group_name: String
@export var character_name: String
@export var valid_rounds: Array[int] = []
@export var duration_rounds: int
@export var prerequisite_conditions: Dictionary = {}
@export var max_occurrences: int
@export var cooldown: int
@export var global_check: Dictionary = {}
@export var attribute_aggregation: Dictionary = {}
@export var success_results: Dictionary = {}
@export var failure_results: Dictionary = {}
@export var next_event_success: String
@export var next_event_delay_success: String
@export var next_event_failure: String
@export var next_event_delay_failure: String
@export var required_for_completion: Dictionary = {}
@export var icon_path: String
@export var background_path: String
@export var audio_path: String

# 事件文本数据
var pre_check_text: String = ""
var card_display_text: String = ""

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
        print("事件 ", event_name, " - valid_rounds为空，默认有效")
        return true
    
    var is_valid = round_number in valid_rounds
    print("事件 ", event_name, " - 回合检查: 当前回合=", round_number, ", 有效回合=", valid_rounds, ", 结果=", is_valid)
    return is_valid

# 新增字段访问方法
func get_character_name() -> String:
    return character_name

func get_success_results() -> Dictionary:
    return success_results

func get_failure_results() -> Dictionary:
    return failure_results

func get_next_events() -> Dictionary:
    return {
        "success": next_event_success,
        "delay_success": next_event_delay_success,
        "failure": next_event_failure,
        "delay_failure": next_event_delay_failure
    }

# 获取事件详细描述
func get_description() -> String:
    var desc = "[b]%s[/b]\n" % event_name
    desc += "类型: %s\n" % event_type
    desc += "组别: %s\n" % event_group_name
    
    # 添加人物信息
    if not character_name.is_empty():
        desc += "相关人物: %s\n" % character_name
    
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

# 获取调试信息
func get_debug_info() -> Dictionary:
    var debug_info = {
        "event_id": event_id,
        "event_name": event_name,
        "event_type": event_type,
        "event_group_name": event_group_name,
        "character_name": character_name,
        "valid_rounds": valid_rounds,
        "duration_rounds": duration_rounds,
        "max_occurrences": max_occurrences,
        "cooldown": cooldown,
        "category": get_event_category(),
        "has_prerequisites": not prerequisite_conditions.is_empty(),
        "has_global_check": not global_check.is_empty(),
        "prerequisite_conditions": prerequisite_conditions,
        "global_check": global_check
    }
    
    return debug_info

# 打印调试信息
func print_debug_info():
    var info = get_debug_info()
    print("=== 事件调试信息: ", event_name, " ===")
    for key in info:
        print("  ", key, ": ", info[key])
    print("=== 调试信息结束 ===")

# 检查事件是否满足特定条件（用于调试）
func check_condition_debug(condition_name: String, current_value) -> bool:
    match condition_name:
        "round_check":
            return is_valid_in_round(current_value)
        "has_character":
            return not character_name.is_empty()
        "has_prerequisites":
            return not prerequisite_conditions.is_empty()
        _:
            print("未知条件检查: ", condition_name)
            return false

# 验证事件数据完整性
func validate_data_integrity() -> Dictionary:
    var validation_result = {
        "is_valid": true,
        "errors": [],
        "warnings": []
    }
    
    # 检查必需字段
    if event_id <= 0:
        validation_result.errors.append("event_id必须大于0")
        validation_result.is_valid = false
    
    if event_name.is_empty():
        validation_result.errors.append("event_name不能为空")
        validation_result.is_valid = false
    
    if event_type.is_empty():
        validation_result.errors.append("event_type不能为空")
        validation_result.is_valid = false
    
    # 检查ID与类别的一致性
    var expected_category = get_event_category()
    if expected_category == "unknown":
        validation_result.errors.append("无法从event_id确定事件类别: " + str(event_id))
        validation_result.is_valid = false
    
    # 检查数值字段的合理性
    if duration_rounds < 0:
        validation_result.errors.append("duration_rounds不能为负数")
        validation_result.is_valid = false
    
    if max_occurrences < 0:
        validation_result.errors.append("max_occurrences不能为负数")
        validation_result.is_valid = false
    
    if cooldown < 0:
        validation_result.errors.append("cooldown不能为负数")
        validation_result.is_valid = false
    
    # 检查有效回合
    if valid_rounds.is_empty():
        validation_result.warnings.append("valid_rounds为空，事件将在所有回合有效")
    else:
        for round_num in valid_rounds:
            if round_num <= 0:
                validation_result.errors.append("有效回合必须大于0: " + str(round_num))
                validation_result.is_valid = false
    
    # 检查JSON字段的结构
    if not prerequisite_conditions.is_empty():
        if not prerequisite_conditions.has("round_range") and not prerequisite_conditions.has("required_attributes"):
            validation_result.warnings.append("prerequisite_conditions存在但缺少常见字段")
    
    if not global_check.is_empty():
        if not global_check.has("check_mode"):
            validation_result.errors.append("global_check缺少check_mode字段")
            validation_result.is_valid = false
    
    # 检查人物事件的特殊要求
    if expected_category == "character":
        if character_name.is_empty():
            validation_result.warnings.append("人物事件建议设置character_name")
    
    return validation_result

# 打印数据完整性验证结果
func print_validation_result():
    var result = validate_data_integrity()
    print("=== 事件数据完整性验证: ", event_name, " ===")
    print("验证结果: ", "通过" if result.is_valid else "失败")
    
    if not result.errors.is_empty():
        print("错误:")
        for error in result.errors:
            print("  ✗ ", error)
    
    if not result.warnings.is_empty():
        print("警告:")
        for warning in result.warnings:
            print("  ⚠ ", warning)
    
    if result.is_valid and result.warnings.is_empty():
        print("✓ 数据完整性验证完全通过")
    
    print("=== 验证结束 ===")

# 获取检定前文本
func get_pre_check_text() -> String:
    if not pre_check_text.is_empty():
        return pre_check_text
    else:
        # 回退到原始描述
        return get_description()

# 获取卡片显示文本
func get_card_display_text() -> String:
    if not card_display_text.is_empty():
        return card_display_text
    else:
        # 回退到事件名称
        return event_name

# 设置文本数据
func set_text_data(pre_text: String, card_text: String):
    pre_check_text = pre_text
    card_display_text = card_text 