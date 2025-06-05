extends SceneTree

func _init():
	print("=== 事件显示修复验证测试开始 ===")
	
	# 测试1：验证事件管理器能正确加载事件
	test_event_loading()
	
	# 测试2：验证当前回合137下的事件显示
	test_round_137_events()
	
	# 测试3：验证场景类型筛选
	test_scene_type_filtering()
	
	print("=== 事件显示修复验证测试完成 ===")
	quit()

func test_event_loading():
	print("\n--- 测试事件加载 ---")
	
	var event_manager = preload("res://scripts/events/event_manager.gd").new()
	event_manager._ready()
	
	var total_events = event_manager.get_total_events_count()
	print("总事件数量: ", total_events)
	assert(total_events > 0, "应该加载到事件数据")
	
	print("✓ 事件加载测试通过")

func test_round_137_events():
	print("\n--- 测试回合137事件显示 ---")
	
	var event_manager = preload("res://scripts/events/event_manager.gd").new()
	event_manager._ready()
	event_manager.on_round_changed(137)
	
	# 测试人物事件
	var character_events = event_manager.get_available_events("character")
	print("人物事件数量: ", character_events.size())
	
	# 测试随机事件
	var random_events = event_manager.get_available_events("random") 
	print("随机事件数量: ", random_events.size())
	
	# 测试日常事件
	var daily_events = event_manager.get_available_events("daily")
	print("日常事件数量: ", daily_events.size())
	
	# 验证事件应该显示
	var total_available = character_events.size() + random_events.size() + daily_events.size()
	print("回合137可用事件总数: ", total_available)
	assert(total_available > 0, "回合137应该有可用事件")
	
	print("✓ 回合137事件显示测试通过")

func test_scene_type_filtering():
	print("\n--- 测试场景类型筛选 ---")
	
	var event_manager = preload("res://scripts/events/event_manager.gd").new()
	event_manager._ready()
	event_manager.on_round_changed(137)
	
	# 模拟TimeManager场景类型
	var time_manager_mock = {
		"get_current_scene_type": func(): return "workday"
	}
	
	# 这里需要实际测试需要更复杂的模拟
	print("场景类型测试需要完整的TimeManager集成")
	
	print("✓ 场景类型筛选测试跳过（需要完整环境）") 