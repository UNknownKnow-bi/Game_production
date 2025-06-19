extends Node

# TimeManager - 时间管理器单例
# 管理全局游戏时间、回合数和场景类型切换

signal round_changed(new_round: int)
signal scene_type_changed(new_scene_type: String)

var current_round: int = 1
var current_scene_type: String = "workday"  # 作为缓存，非主要状态

# 场景类型分别计数
var workday_round_count: int = 0    # 工作日回合计数
var weekend_round_count: int = 0    # 周末回合计数

const SAVE_FILE_PATH = "user://game_state.json"

# 根据回合数推导场景类型（核心函数）
func get_scene_type_from_round(round: int) -> String:
	return "weekend" if round % 2 == 0 else "workday"

# 获取当前应该的场景类型
func get_expected_scene_type() -> String:
	return get_scene_type_from_round(current_round)

# 检查当前场景是否正确
func is_scene_correct() -> bool:
	return current_scene_type == get_expected_scene_type()

func _ready():
	load_game_state()
	
	# 初始化时的一致性检查
	print("Time Manager: 初始化完成，验证回合数一致性")
	if not validate_round_consistency():
		print("Time Manager: 初始化时发现数据不一致，执行修复")
		repair_inconsistent_data()
		save_game_state()
	
	print_round_debug_info()

# 推进回合（简化逻辑）
func advance_round():
	var old_round = current_round
	var old_scene = current_scene_type
	
	# 推进回合
	current_round += 1
	
	# 推进场景回合计数
	advance_scene_round(old_scene)
	
	# 获取新的预期场景类型
	var expected_scene = get_expected_scene_type()
	
	print("Time Manager: 回合推进 ", old_round, " -> ", current_round)
	print("Time Manager: 预期场景切换 ", old_scene, " -> ", expected_scene)
	
	# 发出回合变更信号
	round_changed.emit(current_round)
	
	# 通知 GlobalCardUsageManager
	var global_usage_manager = get_node_or_null("/root/GlobalCardUsageManager")
	if global_usage_manager:
		global_usage_manager.on_round_changed(current_round, expected_scene)
	
	# 如果需要切换场景，触发切换
	if current_scene_type != expected_scene:
		trigger_scene_change_to(expected_scene)
	else:
		# 场景不变，直接存档
		save_game_state()

# 推进指定场景类型的回合计数
func advance_scene_round(scene_type: String):
	if scene_type == "workday":
		workday_round_count += 1
		print("Time Manager: 工作日回合推进至: ", workday_round_count)
	elif scene_type == "weekend":
		weekend_round_count += 1
		print("Time Manager: 周末回合推进至: ", weekend_round_count)

# 获取指定场景类型的回合数
func get_scene_round_count(scene_type: String) -> int:
	if scene_type == "workday":
		return workday_round_count
	elif scene_type == "weekend":
		return weekend_round_count
	else:
		return 0

# 触发场景切换到指定类型
func trigger_scene_change_to(target_scene: String):
	print("Time Manager: 触发场景切换到: ", target_scene)
	
	# 更新当前场景类型（立即更新，不使用pending机制）
	current_scene_type = target_scene
	
	# 发出场景切换信号
	scene_type_changed.emit(target_scene)
	
	# 注意：存档将在场景切换完成后进行

# 场景切换完成确认（在新场景的_ready中调用）
func confirm_scene_switched():
	print("Time Manager: 场景切换完成确认 - 当前场景: ", current_scene_type)
	
	# 验证场景正确性
	if is_scene_correct():
		print("Time Manager: 场景状态正确，执行存档")
		save_game_state()
	else:
		print("Time Manager: 警告 - 场景状态不正确")
		# 修正场景状态
		current_scene_type = get_expected_scene_type()
		save_game_state()

# 获取当前回合数
func get_current_round() -> int:
	return current_round

# 获取当前场景类型
func get_current_scene_type() -> String:
	return current_scene_type
	
# 向后兼容方法 - 始终返回false
func get_settlement_status() -> bool:
	print("警告：调用了已弃用的get_settlement_status方法")
	return false



# 设置回合数（用于调试或加载存档）
func set_current_round(round: int):
	current_round = round
	round_changed.emit(current_round)

# 设置场景类型（用于调试或加载存档）
func set_scene_type(scene_type: String):
	current_scene_type = scene_type
	scene_type_changed.emit(current_scene_type)

# 保存游戏状态
func save_game_state():
	# 确保场景类型正确
	var correct_scene_type = get_expected_scene_type()
	if current_scene_type != correct_scene_type:
		print("Time Manager: 修正场景类型 ", current_scene_type, " -> ", correct_scene_type)
		current_scene_type = correct_scene_type
	
	var save_data = {
		"current_round": current_round,
		"current_scene_type": current_scene_type,
		"workday_round_count": workday_round_count,
		"weekend_round_count": weekend_round_count
	}
	
	# 添加特权卡数据
	if PrivilegeCardManager:
		var cards_data = PrivilegeCardManager.save_cards_data()
		save_data.merge(cards_data)
	
	# 添加已完成事件数据
	var event_manager = get_node_or_null("/root/EventManager")
	if event_manager and event_manager.has_method("get_completed_events_data"):
		save_data["completed_events"] = event_manager.completed_events
		# 添加新的事件统计数据
		save_data["event_trigger_counts"] = event_manager.event_trigger_counts
		save_data["event_last_completed"] = event_manager.event_last_completed
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Time Manager: 游戏状态已保存 - 回合:", current_round, " 场景:", current_scene_type)
		print("Time Manager: 保存事件触发统计 - 触发次数记录:", event_manager.event_trigger_counts.size(), "个, 最后完成记录:", event_manager.event_last_completed.size(), "个")

# 加载游戏状态
func load_game_state():
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("Time Manager: 存档文件不存在，使用默认设置")
		return
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		print("Time Manager: 无法打开存档文件")
		return
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		print("Time Manager: 存档文件解析失败")
		return
	
	var save_data = json.data
	
	# 加载回合数
	current_round = save_data.get("current_round", 1)
	
	# 基于回合数推导场景类型（主要逻辑）
	current_scene_type = get_expected_scene_type()
	
	# 验证存档中的场景类型（用于调试）
	var saved_scene_type = save_data.get("current_scene_type", "workday")
	if saved_scene_type != current_scene_type:
		print("Time Manager: 存档场景类型不一致，已修正 ", saved_scene_type, " -> ", current_scene_type)
	
	# 加载场景类型回合计数
	workday_round_count = save_data.get("workday_round_count", 0)
	weekend_round_count = save_data.get("weekend_round_count", 0)
	
	# 数据一致性检查和修复
	print("Time Manager: 存档加载完成，检查数据一致性")
	print_round_debug_info()
	
	if not validate_round_consistency():
		print("Time Manager: 检测到存档数据不一致，执行修复")
		repair_inconsistent_data()
		
		# 修复后保存，确保数据一致性
		save_game_state()
		print("Time Manager: 数据修复完成并已保存")
	else:
		print("Time Manager: 存档数据一致性验证通过")
	
	# 发出信号通知其他系统
	round_changed.emit(current_round)
	scene_type_changed.emit(current_scene_type)
	
	# 加载特权卡数据
	if PrivilegeCardManager and save_data.has("privilege_cards"):
		PrivilegeCardManager.load_cards_data(save_data)
	
	# 加载已完成事件数据
	var event_manager = get_node_or_null("/root/EventManager")
	if event_manager:
		# 加载已完成事件数据
		var completed_events = save_data.get("completed_events", [])
		if not completed_events.is_empty():
			event_manager.completed_events = completed_events
			print("Time Manager: 已加载完成事件数据，数量: ", event_manager.completed_events.size())
		
		# 加载事件触发次数数据
		event_manager.event_trigger_counts = save_data.get("event_trigger_counts", {})
		print("Time Manager: 已加载事件触发次数数据，数量: ", event_manager.event_trigger_counts.size())
		
		# 加载事件最后完成数据
		event_manager.event_last_completed = save_data.get("event_last_completed", {})
		print("Time Manager: 已加载事件最后完成数据，数量: ", event_manager.event_last_completed.size())
	
	print("Time Manager: 游戏状态已加载 - 回合:", current_round, " 场景:", current_scene_type)
	print("Time Manager: 工作日回合数:", workday_round_count, " 周末回合数:", weekend_round_count)

# 基于场景回合数同步全局回合数
func sync_global_round_from_scene_rounds():
	var calculated_total = calculate_total_rounds()
	if current_round != calculated_total:
		print("Time Manager: 同步全局回合数 - 原值:", current_round, " 新值:", calculated_total)
		current_round = calculated_total

# 计算场景回合数总和
func calculate_total_rounds() -> int:
	return workday_round_count + weekend_round_count

# 验证回合数一致性
func validate_round_consistency() -> bool:
	var calculated_total = calculate_total_rounds()
	var is_consistent = (current_round == calculated_total)
	if not is_consistent:
		print("Time Manager: 回合数不一致 - 全局:", current_round, " 场景总和:", calculated_total)
		print("Time Manager: 工作日:", workday_round_count, " 周末:", weekend_round_count)
	return is_consistent

# 修复数据不一致问题
func repair_inconsistent_data():
	print("Time Manager: 开始修复回合数不一致问题")
	
	var calculated_total = calculate_total_rounds()
	
	# 如果场景回合数总和合理，优先信任场景回合数
	if calculated_total > 0:
		print("Time Manager: 基于场景回合数修复 - 设置全局回合数为:", calculated_total)
		current_round = calculated_total
		round_changed.emit(current_round)
	else:
		# 如果场景回合数异常，基于全局回合数重新分配
		print("Time Manager: 场景回合数异常，基于全局回合数重新分配")
		redistribute_rounds_from_global()
	
	print("Time Manager: 修复完成 - 全局回合:", current_round, " 工作日:", workday_round_count, " 周末:", weekend_round_count)

# 基于全局回合数重新分配场景回合数
func redistribute_rounds_from_global():
	if current_round <= 0:
		print("Time Manager: 全局回合数异常，重置为初始状态")
		current_round = 1
		workday_round_count = 0
		weekend_round_count = 0
		current_scene_type = "workday"
		return
	
	# 简化分配：假设工作日和周末交替，平均分配
	var half_rounds = current_round / 2
	workday_round_count = half_rounds
	weekend_round_count = current_round - half_rounds
	
	print("Time Manager: 重新分配场景回合数 - 工作日:", workday_round_count, " 周末:", weekend_round_count)



# 打印回合数调试信息
func print_round_debug_info():
	print("=== Time Manager 回合数调试信息 ===")
	print("全局回合数: ", current_round)
	print("当前场景类型: ", current_scene_type)
	print("预期场景类型: ", get_expected_scene_type())
	print("工作日回合数: ", workday_round_count)
	print("周末回合数: ", weekend_round_count)
	print("场景回合数总和: ", calculate_total_rounds())
	print("数据一致性: ", "✓" if validate_round_consistency() else "✗")
	print("场景正确性: ", "✓" if is_scene_correct() else "✗")
	print("===============================")

# 强制同步回合数（调试用）
func force_sync_rounds():
	print("Time Manager: 强制同步回合数")
	print_round_debug_info()
	
	if not validate_round_consistency():
		repair_inconsistent_data()
		print("Time Manager: 强制同步完成")
		print_round_debug_info()
	else:
		print("Time Manager: 回合数已一致，无需同步") 