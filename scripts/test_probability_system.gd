extends Node

# 概率系统测试脚本
# 用于验证回合概率判定系统是否正常工作

func _ready():
	print("=== 概率系统测试开始 ===")
	
	# 等待EventManager初始化完成
	await get_tree().process_frame
	
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		print("错误: 无法找到EventManager")
		return
	
	# 测试多个回合的概率判定
	test_multiple_rounds(event_manager)

func test_multiple_rounds(event_manager):
	print("\n=== 测试多回合概率判定 ===")
	
	# 测试5个回合
	for round_num in range(1, 6):
		print("\n--- 测试回合", round_num, " ---")
		
		# 触发回合变更
		event_manager.on_round_changed(round_num)
		
		# 检查特定事件的概率判定结果
		var test_events = [2001, 2005, 2008]  # 这些事件有不同的概率设置
		
		for event_id in test_events:
			var event = event_manager.get_event_by_id(event_id)
			if event:
				var chance = event_manager.get_event_chance(event)
				var passed = event_manager.check_event_chance_for_current_round(event_id)
				print("事件", event_id, "(", event.event_name, ") - 概率:", chance, " 结果:", "通过" if passed else "失败")
		
		# 等待一帧
		await get_tree().process_frame
	
	print("\n=== 概率系统测试完成 ===")

func test_probability_distribution():
	print("\n=== 概率分布测试 ===")
	
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		return
	
	# 测试1000次概率判定，统计分布
	var test_rounds = 1000
	var event_id = 2001  # 30%概率的事件
	var success_count = 0
	
	for i in range(test_rounds):
		event_manager.determine_round_event_chances(i + 100)  # 使用不同的回合号
		if event_manager.check_event_chance_for_current_round(event_id):
			success_count += 1
	
	var actual_rate = float(success_count) / test_rounds
	print("事件", event_id, "在", test_rounds, "次测试中:")
	print("- 期望概率: 30%")
	print("- 实际概率: ", "%.1f%%" % (actual_rate * 100))
	print("- 成功次数: ", success_count, "/", test_rounds) 