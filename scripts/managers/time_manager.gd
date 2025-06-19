extends Node

# TimeManager - 时间管理器单例
# 管理全局游戏时间、回合数和场景类型切换

signal round_changed(new_round: int)
signal scene_type_changed(new_scene_type: String)

var current_round: int = 1
var current_scene_type: String = "workday"  # "workday" 或 "weekend"

# 场景类型分别计数
var workday_round_count: int = 0    # 工作日回合计数
var weekend_round_count: int = 0    # 周末回合计数

# 检定状态管理
var is_settlement_in_progress: bool = false

func _ready():
	# 初始化时的一致性检查
	print("Time Manager: 初始化完成，验证回合数一致性")
	if not validate_round_consistency():
		print("Time Manager: 初始化时发现数据不一致，执行修复")
		repair_inconsistent_data()
	
	print_round_debug_info()

# 增加回合数（分离场景切换逻辑）
func advance_round():
	var old_round = current_round
	
	# 推进当前场景类型的回合计数
	advance_scene_round(current_scene_type)
	
	# 基于场景回合数计算全局回合数，确保一致性
	sync_global_round_from_scene_rounds()
	
	# 通知 GlobalCardUsageManager 回合推进
	var global_usage_manager = get_node_or_null("/root/GlobalCardUsageManager")
	if global_usage_manager:
		global_usage_manager.on_round_changed(current_round, current_scene_type)
	
	round_changed.emit(current_round)
	
	print("Time Manager: 回合推进 ", old_round, " -> ", current_round)
	print("Time Manager: 当前场景类型: ", current_scene_type)
	print("Time Manager: 工作日回合数: ", workday_round_count, " 周末回合数: ", weekend_round_count)
	
	# 验证回合数一致性
	if not validate_round_consistency():
		print("Time Manager: 警告 - 回合推进后数据不一致，尝试修复")
		repair_inconsistent_data()
	
	# 检查是否有检定正在进行
	if is_settlement_in_progress:
		print("Time Manager: 检定正在进行中，延迟场景切换")
		print("Time Manager: 回合已推进，但场景切换将在检定完成后执行")
		# 不立即切换场景，等待检定完成
		return
	
	# 如果没有检定进行，正常切换场景
	print("Time Manager: 没有检定进行，立即执行场景切换")
	trigger_scene_change()

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

# 触发场景切换
func trigger_scene_change():
	print("Time Manager: 触发场景切换")
	
	# 切换场景类型
	if current_scene_type == "workday":
		current_scene_type = "weekend"
	else:
		current_scene_type = "workday"
	
	scene_type_changed.emit(current_scene_type)
	
	# 移除对save_game_state的调用，改为通知GameSaveManager
	if GameSaveManager:
		GameSaveManager.save_game()
		print("Time Manager: 通知GameSaveManager保存游戏状态")
	
	print("Time Manager: 场景类型切换到: ", current_scene_type)

# 设置检定进行状态
func set_settlement_in_progress(in_progress: bool):
	print("Time Manager: 设置检定状态 - ", in_progress)
	is_settlement_in_progress = in_progress
	
	# 如果检定完成，强制触发场景切换（检定完成意味着回合应该切换）
	if not in_progress:
		print("Time Manager: 检定完成，强制执行场景切换")
		print("Time Manager: 当前回合:", current_round, " 当前场景:", current_scene_type)
		
		# 检定完成后总是需要切换场景，因为这意味着回合结束
		var expected_scene = "weekend" if current_round % 2 == 0 else "workday"
		print("Time Manager: 期望场景:", expected_scene)
		
		if current_scene_type != expected_scene:
			print("Time Manager: 场景需要切换，执行场景切换")
			trigger_scene_change()
		else:
			print("Time Manager: 场景已是期望状态，但检定完成意味着应该切换")
			# 强制切换，因为检定完成意味着回合结束
			trigger_scene_change()

# 检查是否需要执行延迟的场景切换（简化逻辑）
func should_trigger_delayed_scene_change() -> bool:
	# 简化逻辑：检定完成后总是需要切换场景
	print("Time Manager: 检查延迟场景切换需求")
	print("Time Manager: 当前回合:", current_round, " 当前场景:", current_scene_type)
	
	var expected_scene = "weekend" if current_round % 2 == 0 else "workday"
	var need_change = current_scene_type != expected_scene
	
	print("Time Manager: 期望场景:", expected_scene, " 需要切换:", need_change)
	return true  # 检定完成后总是触发切换

# 获取当前回合数
func get_current_round() -> int:
	return current_round

# 获取当前场景类型
func get_current_scene_type() -> String:
	return current_scene_type

# 获取检定进行状态
func get_settlement_status() -> bool:
	return is_settlement_in_progress

# 设置回合数（用于调试或加载存档）
func set_current_round(round: int):
	current_round = round
	round_changed.emit(current_round)

# 设置场景类型（用于调试或加载存档）
func set_scene_type(scene_type: String):
	current_scene_type = scene_type
	scene_type_changed.emit(current_scene_type)

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
	print("工作日回合数: ", workday_round_count)
	print("周末回合数: ", weekend_round_count)
	print("场景回合数总和: ", calculate_total_rounds())
	print("数据一致性: ", "✓" if validate_round_consistency() else "✗")
	print("检定进行状态: ", is_settlement_in_progress)
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

# 确保场景类型与回合数一致性
func ensure_scene_consistency():
	print("Time Manager: 确保场景类型与回合数一致性")
	var expected_scene = "weekend" if current_round % 2 == 0 else "workday"
	if current_scene_type != expected_scene:
		print("Time Manager: 场景类型不一致，修正从", current_scene_type, "到", expected_scene)
		current_scene_type = expected_scene
		scene_type_changed.emit(current_scene_type)
	return current_scene_type 