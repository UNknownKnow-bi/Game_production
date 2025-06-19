class_name GameEvent
extends Resource

@export var event_id: int
@export var event_type: String
@export var event_name: String
@export var event_group_name: String
@export var character_name: String
@export var valid_rounds: Array[int] = []
@export var duration_rounds: int = 1
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
var success_text: String = ""
var failure_text: String = ""
var card_text_success: String = ""
var card_text_failure: String = ""

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
func is_valid_in_round(round_number: int, event_manager: EventManager = null) -> bool:
	# 检查事件是否已完成
	var is_completed = false
	if event_manager and event_manager.completed_events.has(event_id):
		is_completed = true
		var completion_data = event_manager.completed_events[event_id]
		var completed_round = completion_data.completed_round
		var event_status = completion_data.get("event_status", "completed")
		
		# 已结算事件不再显示
		if event_status == "settled":
			print("事件 ", event_name, " - 已结算事件: 不再显示")
			return false
		
		# 其他已完成事件显示duration_rounds时长
		var display_end = completed_round + duration_rounds
		var in_display_period = round_number <= display_end
		print("事件 ", event_name, " - 已完成显示检查: 完成回合=", completed_round, ", 持续=", duration_rounds, ", 当前=", round_number, ", 显示结束=", display_end, ", 状态=", event_status, ", 结果=", in_display_period)
		return in_display_period
	else:
		# 未完成事件始终显示（出现条件由prerequisite_conditions控制）
		print("事件 ", event_name, " - 未完成事件: 当前回合=", round_number, ", 始终显示=true")
		return true

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
	
	# 添加检定信息 - 支持新格式
	if not global_check.is_empty():
		var attribute_requirements = get_attribute_requirements()
		if not attribute_requirements.is_empty():
			desc += "属性检定:\n"
			for req in attribute_requirements:
				desc += " - %s 属性, 阈值 %s, 成功 %s 次\n" % [
					req.attribute,
					req.threshold,
					req.success_required
				]
	
	return desc

# 获取属性需求列表 (新方法)
func get_attribute_requirements() -> Array:
	var requirements = []
	
	if global_check.is_empty():
		return requirements
	
	# 处理新格式
	if global_check.has("required_checks"):
		var checks = global_check["required_checks"]
		if checks is Array:
			for check in checks:
				if check is Dictionary and check.has("attribute") and check.has("threshold"):
					requirements.append({
						"attribute": check.get("attribute", ""),
						"threshold": check.get("threshold", 0),
						"success_required": check.get("success_required", 1)
					})
		return requirements
	
	# 处理旧格式 - 向后兼容
	if global_check.has("check_mode"):
		var check_mode = global_check.get("check_mode", "")
		if check_mode == "single_attribute":
			var attr_check = global_check.get("single_attribute_check", {})
			if attr_check.has("attribute_name") and attr_check.has("threshold"):
				requirements.append({
					"attribute": attr_check.get("attribute_name", ""),
					"threshold": attr_check.get("threshold", 0),
					"success_required": attr_check.get("success_required", 1)
				})
		elif check_mode == "multi_attribute":
			var checks = global_check.get("multi_attribute_check", [])
			for check in checks:
				if check.has("attribute_name") and check.has("threshold"):
					requirements.append({
						"attribute": check.get("attribute_name", ""),
						"threshold": check.get("threshold", 0),
						"success_required": check.get("success_required", 1)
					})
	
	return requirements

# 检查是否有属性检定需求 (新方法)
func has_attribute_check() -> bool:
	return not get_attribute_requirements().is_empty()

# 获取简化的global_check格式 (新方法)
func get_simplified_global_check() -> Dictionary:
	var requirements = get_attribute_requirements()
	if requirements.is_empty():
		return {}
	
	return {
		"required_checks": requirements
	}

# 转换旧格式到新格式 (新方法)
func convert_legacy_global_check() -> bool:
	if global_check.is_empty():
		return false
	
	# 如果已经是新格式，不需要转换
	if global_check.has("required_checks"):
		return false
	
	# 转换旧格式
	var requirements = get_attribute_requirements()
	if not requirements.is_empty():
		global_check = {
			"required_checks": requirements
		}
		print("GameEvent: 转换旧格式global_check为新格式 - 事件: ", event_name)
		return true
	
	return false

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
	# 添加调试日志：记录字段状态
	if event_id == 1001:  # 专门针对事件ID 1001
		print("📖 [GameEvent.get_pre_check_text] 事件ID 1001调用:")
		print("  pre_check_text状态:")
		print("    长度: ", pre_check_text.length())
		print("    是否为空: ", pre_check_text.is_empty())
		print("    前50字符: '", pre_check_text.substr(0, 50), "'")
	
	if not pre_check_text.is_empty():
		if event_id == 1001:
			print("  ✅ 返回pre_check_text (非空)")
		return pre_check_text
	else:
		# 回退到原始描述
		if event_id == 1001:
			print("  ⚠️ pre_check_text为空，回退到get_description()")
			var desc = get_description()
			print("  回退描述长度: ", desc.length())
			print("  回退描述前100字符: '", desc.substr(0, 100), "'")
		return get_description()

# 获取卡片显示文本
func get_card_display_text() -> String:
	if not card_display_text.is_empty():
		return card_display_text
	else:
		# 回退到事件名称
		return event_name

# 获取成功文本
func get_success_text() -> String:
	if not success_text.is_empty():
		return success_text
	else:
		# 回退到基础描述
		return get_description()

# 获取失败文本
func get_failure_text() -> String:
	if not failure_text.is_empty():
		return failure_text
	else:
		# 回退到基础描述
		return get_description()

# 获取成功卡片文本
func get_card_text_success() -> String:
	if not card_text_success.is_empty():
		return card_text_success
	else:
		# 回退到卡片显示文本
		return get_card_display_text()

# 获取失败卡片文本
func get_card_text_failure() -> String:
	if not card_text_failure.is_empty():
		return card_text_failure
	else:
		# 回退到卡片显示文本
		return get_card_display_text()

# 设置文本数据 - 支持新的7列格式
func set_text_data(pre_text: String, card_text: String, success_txt: String = "", failure_txt: String = "", card_success: String = "", card_failure: String = ""):
	# 添加调试日志：记录方法调用
	if event_id == 1001:  # 专门针对事件ID 1001
		print("🔧 [GameEvent.set_text_data] 事件ID 1001调用:")
		print("  传入参数:")
		print("    pre_text长度: ", pre_text.length())
		print("    pre_text前50字符: '", pre_text.substr(0, 50), "'")
		print("    card_text: '", card_text, "'")
		print("    success_txt长度: ", success_txt.length())
		print("    failure_txt长度: ", failure_txt.length())
		print("  设置前字段状态:")
		print("    当前pre_check_text: '", pre_check_text, "'")
		print("    当前pre_check_text长度: ", pre_check_text.length())
	
	pre_check_text = pre_text
	card_display_text = card_text
	success_text = success_txt
	failure_text = failure_txt
	card_text_success = card_success
	card_text_failure = card_failure
	
	# 添加调试日志：记录设置结果
	if event_id == 1001:  # 专门针对事件ID 1001
		print("  设置后字段状态:")
		print("    新pre_check_text长度: ", pre_check_text.length())
		print("    新pre_check_text前50字符: '", pre_check_text.substr(0, 50), "'")
		print("    新card_display_text: '", card_display_text, "'")
		print("    字段设置是否成功: ", not pre_check_text.is_empty())
		print("🔧 [GameEvent.set_text_data] 完成")

# ========== 奖励结算系统 ==========

# 执行成功结算
func execute_success_results() -> Dictionary:
	print("GameEvent: 执行成功结算 - ", event_name)
	var applied_rewards = {"attributes": {}, "items": [], "coins": 0}
	
	if success_results.is_empty():
		print("GameEvent: 没有成功奖励配置")
		return applied_rewards
	
	# 处理属性奖励
	if success_results.has("attributes"):
		var attr_rewards = success_results["attributes"]
		for attr_name in attr_rewards:
			var delta = attr_rewards[attr_name]
			if AttributeManager:
				AttributeManager.modify_attribute(attr_name, delta)
				applied_rewards.attributes[attr_name] = delta
				print("GameEvent: 奖励属性 ", attr_name, " +", delta)
	
	# 处理物品奖励
	if success_results.has("items"):
		var item_rewards = success_results["items"]
		if item_rewards is Array:
			for item_data in item_rewards:
				if item_data is Array and item_data.size() >= 2:
					var item_type = item_data[0]
					var item_amount = item_data[1]
					applied_rewards.items.append({"type": item_type, "amount": item_amount})
					print("GameEvent: 奖励物品 ", item_type, " x", item_amount)
					
					# 特殊处理金币
					if item_type == "coins":
						applied_rewards.coins += item_amount
						# 直接调用AttributeManager修改金币
						if AttributeManager:
							AttributeManager.modify_coins(item_amount)
							print("GameEvent: 金币奖励已应用到AttributeManager +", item_amount)
					
					# 特殊处理情报卡
					elif item_type == "item_card":
						if ItemCardInventoryManager:
							for i in range(item_amount):
								var acquired_card = ItemCardInventoryManager.acquire_random_item_card()
								if acquired_card:
									print("GameEvent: 情报卡奖励已应用 - ", acquired_card.get_card_name())
								else:
									print("GameEvent: 情报卡奖励处理失败")
						else:
							print("GameEvent: ItemCardInventoryManager未找到，无法处理情报卡奖励")
	
	# 处理直接金币奖励
	if success_results.has("coins"):
		var coin_reward = success_results["coins"]
		applied_rewards.coins += coin_reward
		# 直接调用AttributeManager修改金币
		if AttributeManager:
			AttributeManager.modify_coins(coin_reward)
			print("GameEvent: 直接金币奖励已应用到AttributeManager +", coin_reward)
		print("GameEvent: 奖励金币 +", coin_reward)
	
	print("GameEvent: 成功结算完成 - 总奖励: ", applied_rewards)
	return applied_rewards

# 执行失败结算
func execute_failure_results() -> Dictionary:
	print("GameEvent: 执行失败结算 - ", event_name)
	var applied_penalties = {"attributes": {}, "items": [], "coins": 0}
	
	if failure_results.is_empty():
		print("GameEvent: 没有失败惩罚配置")
		return applied_penalties
	
	# 处理属性惩罚
	if failure_results.has("attributes"):
		var attr_penalties = failure_results["attributes"]
		for attr_name in attr_penalties:
			var delta = attr_penalties[attr_name]
			if AttributeManager:
				AttributeManager.modify_attribute(attr_name, delta)
				applied_penalties.attributes[attr_name] = delta
				print("GameEvent: 惩罚属性 ", attr_name, " ", delta)
	
	# 处理物品惩罚
	if failure_results.has("items"):
		var item_penalties = failure_results["items"]
		if item_penalties is Array:
			for item_data in item_penalties:
				if item_data is Array and item_data.size() >= 2:
					var item_type = item_data[0]
					var item_amount = item_data[1]
					applied_penalties.items.append({"type": item_type, "amount": item_amount})
					print("GameEvent: 惩罚物品 ", item_type, " ", item_amount)
					
					# 特殊处理金币
					if item_type == "coins":
						applied_penalties.coins += item_amount
						# 直接调用AttributeManager修改金币
						if AttributeManager:
							AttributeManager.modify_coins(item_amount)
							print("GameEvent: 金币惩罚已应用到AttributeManager ", item_amount)
	
	# 处理直接金币惩罚
	if failure_results.has("coins"):
		var coin_penalty = failure_results["coins"]
		applied_penalties.coins += coin_penalty
		# 直接调用AttributeManager修改金币
		if AttributeManager:
			AttributeManager.modify_coins(coin_penalty)
			print("GameEvent: 直接金币惩罚已应用到AttributeManager ", coin_penalty)
		print("GameEvent: 惩罚金币 ", coin_penalty)
	
	print("GameEvent: 失败结算完成 - 总惩罚: ", applied_penalties)
	return applied_penalties

# 检查是否可以执行检定
func can_perform_check() -> bool:
	return has_attribute_check()

# 获取检定预览信息
func get_check_preview_info() -> Dictionary:
	var preview = {
		"has_check": has_attribute_check(),
		"requirements": get_attribute_requirements(),
		"can_check": false,
		"success_probability": 0.0
	}
	
	if not preview.has_check:
		return preview
	
	if not EventSlotManager:
		return preview
	
	var slot_attributes = EventSlotManager.calculate_event_slot_attributes(event_id)
	var requirements = get_attribute_requirements()
	
	if not requirements.is_empty():
		var req = requirements[0]
		var attempts = slot_attributes.get(req.attribute, 0)
		
		preview.can_check = attempts >= req.threshold
		if preview.can_check and EventManager:
			preview.success_probability = EventManager.calculate_success_probability(attempts, req.success_required)
	
	return preview
