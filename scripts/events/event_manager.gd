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
	"daily": [],
	"ending": []
}

# 已完成事件记录
var completed_events: Dictionary = {}  # event_id -> completion_data

# 事件触发次数记录
var event_trigger_counts: Dictionary = {}  # event_id -> trigger_count

# 事件最后完成回合记录  
var event_last_completed: Dictionary = {}  # event_id -> last_completed_round

# 当前游戏回合
var current_round = 1

# 回合概率判定缓存
var round_chance_cache: Dictionary = {}  # {round_number: {event_id: bool}}
var current_round_chance_determined: bool = false

# 调试模式开关
var debug_mode: bool = false

# 详细调试模式开关
var detailed_debug_mode: bool = true

# 游戏状态信号
signal events_updated
signal event_completed(event_id: int)

# 数据文件路径
const EVENTS_DATA_PATH = "res://data/events/event_table.tsv"

# 事件文本数据存储
var event_text_data = {}  # 存储事件ID到文本数据的映射
const EVENT_TEXT_DATA_PATH = "res://data/events/event_text_table.csv"

func _ready():
	# 连接TimeManager的round_changed信号
	if TimeManager:
		TimeManager.round_changed.connect(on_round_changed)
		print("EventManager: 已连接TimeManager.round_changed信号")
	else:
		print("EventManager: 警告 - TimeManager未找到，无法同步回合")
	
	# 初始化事件统计字典
	event_trigger_counts = {}
	event_last_completed = {}
	
	# 启用详细调试模式进行问题诊断
	detailed_debug_mode = true
	# 关闭调试模式以启用正确的事件限制检查
	debug_mode = false
	print("EventManager: 启用详细调试模式，关闭debug_mode以正确筛选事件")
	
	# 诊断文件访问状态
	diagnose_file_access(EVENTS_DATA_PATH)
	
	load_events_from_tsv(EVENTS_DATA_PATH)
	
	# 为初始回合进行概率判定
	if has_loaded_data():
		determine_round_event_chances(current_round)
		if detailed_debug_mode:
			print_round_chance_results(current_round)

# TimeManager回合变更回调
func on_round_changed(new_round: int):
	current_round = new_round
	print("EventManager: 回合同步更新 - 当前回合: ", current_round)
	
	# 清除过期的概率判定缓存
	cleanup_old_chance_cache()
	
	# 为新回合进行概率判定
	determine_round_event_chances(new_round)
	
	# 在详细调试模式下打印概率判定结果
	if detailed_debug_mode:
		print_round_chance_results(new_round)
	
	# 释放延迟忙碌的卡牌
	var global_usage_manager = get_node_or_null("/root/GlobalCardUsageManager")
	if global_usage_manager and TimeManager:
		var scene_type = TimeManager.get_current_scene_type()
		global_usage_manager.release_duration_busy_cards(current_round, scene_type)

# 解析有效回合，支持逗号分隔格式
func parse_valid_rounds(rounds_str: String) -> Array[int]:
	var result: Array[int] = []
	
	if rounds_str.is_empty():
		return result
	
	# 处理范围格式 "1-999" -> 转换为数字999 (表示持续时间)
	if "-" in rounds_str:
		var range_parts = rounds_str.split("-")
		if range_parts.size() == 2:
			var end_round = range_parts[1].strip_edges().to_int()
			result.append(end_round)
			if detailed_debug_mode:
				print("解析范围格式: ", rounds_str, " -> [", end_round, "] (作为持续时间)")
		return result
	
	# 处理逗号分隔格式
	var parts = rounds_str.split(",")
	for part in parts:
		var clean_part = part.strip_edges()
		if not clean_part.is_empty():
			var round_num = clean_part.to_int()
			if round_num > 0:
				result.append(round_num)
	
	if detailed_debug_mode:
		print("解析逗号分隔: ", rounds_str, " -> ", result)
	
	return result

# 诊断文件访问状态
func diagnose_file_access(file_path: String):
	# 检查文件是否存在
	if not FileAccess.file_exists(file_path):
		print("✗ 文件不存在: ", file_path)
		return
	
	# 尝试打开文件
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("✗ 无法打开文件，错误代码: ", FileAccess.get_open_error())
		return
	
	# 检查文件大小
	var file_size = file.get_length()
	if file_size == 0:
		print("✗ 文件为空: ", file_path)
		file.close()
		return
	
	file.close()
	print("✓ 文件访问正常")

# 验证TSV文件格式
func validate_tsv_file_format(file_path: String) -> bool:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("✗ 无法打开文件进行格式验证")
		return false
	
	var content = file.get_as_text()
	file.close()
	
	var lines = content.split("\n")
	if lines.size() < 2:
		print("✗ 文件行数不足")
		return false
	
	var header = lines[0].split("\t")
	# 必需列（0-13）和可选列（14-21）
	var required_columns = [
		"event_id", "event_type", "event_name", "event_group_name", 
		"character_name", "valid_rounds", "duration_rounds", 
		"prerequisite_conditions", "max_occurrences", "cooldown",
		"global_check", "attribute_aggregation", "success_results",
		"failure_results"
	]

	# 检查必需列
	for i in range(required_columns.size()):
		if i >= header.size():
			print("✗ 缺少必需列: ", required_columns[i])
			return false
		elif header[i] != required_columns[i]:
			print("✗ 必需列名不匹配: 期望 '", required_columns[i], "', 实际 '", header[i], "'")
			return false

	return true

# 从TSV文件加载事件
func load_events_from_tsv(file_path: String, force_reload: bool = false):
	# 检查是否已有数据且不强制重载
	if not force_reload and has_loaded_data():
		print("EventManager: 数据已加载，跳过重复加载。当前事件总数: ", get_total_events_count())
		return
	
	# 如果强制重载，清空现有数据
	if force_reload:
		for category in events:
			events[category].clear()
	
	# 验证文件格式
	if not validate_tsv_file_format(file_path):
		printerr("✗ TSV文件格式验证失败，停止加载")
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		printerr("✗ 无法打开事件数据文件: ", file_path)
		printerr("文件访问错误代码: ", FileAccess.get_open_error())
		return
	
	var content = file.get_as_text()
	file.close()
	
	if content.is_empty():
		printerr("✗ 文件内容为空")
		return
	
	var lines = content.split("\n")
	# 使用更可靠的TAB分割方法来保留空字段
	var header = split_with_empty_fields(lines[0], "\t")
	
	var loaded_count = 0
	var failed_count = 0
	var skipped_count = 0
	
	print("EventManager: 开始解析事件数据")
	
	if detailed_debug_mode:
		print("表头详细内容: ", header)
	
	# 从第二行开始解析数据
	for i in range(1, lines.size()):
		var line = lines[i].strip_edges()
		if line.is_empty():
			skipped_count += 1
			continue
		
		if detailed_debug_mode:
			print("=== 处理第", i+1, "行 ===")
			print("原始行内容: \"", line, "\"")
		
		# 使用更可靠的TAB分割方法来保留空字段
		var columns = split_with_empty_fields(line, "\t")
		
		# 确保列数补全到22列，支持14-22列的数据
		columns = ensure_column_count(columns)
		if columns.size() < 14:  # 只检查必需字段（0-13）
			print("✗ 第", i+1, "行数据必需列数不足: ", columns.size(), "/14 (最少需要14列)")
			failed_count += 1
			continue
		
		if detailed_debug_mode:
			print("✓ 列数检查通过: ", columns.size(), " 列 (补全后)")
		
		# 安全创建事件对象
		var event = create_event_with_error_handling(columns, i+1)
		if event == null:
			failed_count += 1
			continue
		
		# 将事件添加到对应类别
		var category = event.get_event_category()
		if category != "unknown":
			events[category][event.event_id] = event
			loaded_count += 1
			
			if detailed_debug_mode:
				print("✓ 事件加载成功 - ID:", event.event_id, " 名称:", event.event_name, " 类别:", category)
			else:
				print("EventManager: 加载事件 - ID:", event.event_id, " 名称:", event.event_name, " 类别:", category)
		else:
			print("✗ 事件ID ", event.event_id, " 无法确定类别")
			failed_count += 1
	
	print("EventManager: 成功加载 ", loaded_count, " 个事件")
	if failed_count > 0:
		print("EventManager: 加载失败 ", failed_count, " 个事件")

	# 如果没有成功加载任何事件，这是一个严重问题
	if loaded_count == 0:
		printerr("✗ 严重错误: 没有成功加载任何事件！")
		printerr("请检查数据文件格式和内容")
	
	# 加载事件文本数据
	load_event_text_data()

# 自定义分割函数，正确处理连续分隔符并保留空字段
# 注意：此函数主要用于event_table.tsv等其他TSV文件的解析
# event_text_table.tsv现在使用Godot原生的get_csv_line()方法来正确处理包含换行符的字段
func split_with_empty_fields(text: String, delimiter: String) -> Array:
	var result = []
	var current_field = ""
	var i = 0
	
	while i < text.length():
		if i + delimiter.length() <= text.length() and text.substr(i, delimiter.length()) == delimiter:
			# 遇到分隔符，添加当前字段（可能为空）
			result.append(current_field)
			current_field = ""
			i += delimiter.length()
		else:
			# 普通字符，添加到当前字段
			current_field += text[i]
			i += 1
	
	# 添加最后一个字段
	result.append(current_field)
	
	return result

# 确保列数达到22列，不足时补充空字符串
func ensure_column_count(columns: Array) -> Array:
	var result = columns.duplicate()
	while result.size() < 22:
		result.append("")
	
	return result

# 安全获取列值，支持默认值
func get_column_safe(columns: Array, index: int, default_value: String = "") -> String:
	if index >= 0 and index < columns.size():
		return columns[index]
	else:
		return default_value

# 安全创建GameEvent对象
func create_event_with_error_handling(columns: Array, line_number: int) -> GameEvent:
	var event = GameEvent.new()
	if not event:
		printerr("✗ 第", line_number, "行: 无法创建GameEvent对象")
		return null
	
	# 安全设置基本属性
	if not set_event_property_safe(event, "event_id", columns[0], "int", line_number):
		return null
	if not set_event_property_safe(event, "event_type", columns[1], "string", line_number):
		return null
	if not set_event_property_safe(event, "event_name", columns[2], "string", line_number):
		return null
	if not set_event_property_safe(event, "event_group_name", columns[3], "string", line_number):
		return null
	if not set_event_property_safe(event, "character_name", columns[4], "string", line_number):
		return null
	
	# 解析有效回合
	var valid_rounds_str = columns[5]
	if not valid_rounds_str.is_empty():
		event.valid_rounds = parse_valid_rounds(valid_rounds_str)
		if detailed_debug_mode:
			print("解析valid_rounds: '", valid_rounds_str, "' -> ", event.valid_rounds)
	
	if not set_event_property_safe(event, "duration_rounds", columns[6], "int", line_number):
		return null
	
	# 解析JSON字段
	event.prerequisite_conditions = parse_json_field_safe(columns[7])
	
	if not set_event_property_safe(event, "max_occurrences", columns[8], "int", line_number):
		return null
	if not set_event_property_safe(event, "cooldown", columns[9], "int", line_number):
		return null
	
	event.global_check = parse_json_field_safe(columns[10])
	event.attribute_aggregation = parse_json_field_safe(columns[11])
	event.success_results = parse_json_field_safe(columns[12])
	event.failure_results = parse_json_field_safe(columns[13])
	
	# 设置可选字符串字段（使用安全访问）
	event.next_event_success = get_column_safe(columns, 14)
	event.next_event_delay_success = get_column_safe(columns, 15)
	event.next_event_failure = get_column_safe(columns, 16)
	event.next_event_delay_failure = get_column_safe(columns, 17)
	
	event.required_for_completion = parse_json_field_safe(get_column_safe(columns, 18))
	
	# 设置可选路径字段（使用安全访问）
	event.icon_path = get_column_safe(columns, 19)
	event.background_path = get_column_safe(columns, 20)
	event.audio_path = get_column_safe(columns, 21)
	
	# 验证和修复数据完整性
	validate_and_fix_event_data(event)
	
	return event

# 验证和修复事件数据完整性
func validate_and_fix_event_data(event: GameEvent):
	var fixed_issues = []
	
	# 应用global_check格式转换和验证
	_apply_global_check_conversion(event)
	
	# 检查duration_rounds
	if event.duration_rounds <= 0 or event.duration_rounds > 999:
		print("⚠ 修复异常duration_rounds: ", event.duration_rounds, " -> 1 (事件: ", event.event_name, ")")
		event.duration_rounds = 1
		fixed_issues.append("duration_rounds")
	
	# 检查valid_rounds
	if event.valid_rounds.is_empty():
		print("⚠ 事件 ", event.event_name, " 的valid_rounds为空，将在所有回合有效")
	
	# 检查其他数值字段
	if event.max_occurrences < 0:
		print("⚠ 修复异常max_occurrences: ", event.max_occurrences, " -> 1 (事件: ", event.event_name, ")")
		event.max_occurrences = 1
		fixed_issues.append("max_occurrences")
	
	if event.cooldown < 0:
		print("⚠ 修复异常cooldown: ", event.cooldown, " -> 0 (事件: ", event.event_name, ")")
		event.cooldown = 0
		fixed_issues.append("cooldown")
	
	if fixed_issues.size() > 0:
		print("EventManager: 事件 ", event.event_name, " 修复了字段: ", fixed_issues)

# 安全设置事件属性
func set_event_property_safe(event: GameEvent, property_name: String, value: String, type: String, line_number: int) -> bool:
	match type:
		"int":
			if value.is_empty():
				# 对duration_rounds字段使用默认值1，其他字段使用0
				var default_value = 1 if property_name == "duration_rounds" else 0
				event.set(property_name, default_value)
			else:
				var int_value = value.to_int()
				# 验证duration_rounds的合理性
				if property_name == "duration_rounds":
					if int_value <= 0 or int_value > 999:
						print("⚠ 异常duration_rounds值: ", int_value, " 重置为1")
						int_value = 1
				event.set(property_name, int_value)
		"string":
			event.set(property_name, value)
		_:
			printerr("✗ 第", line_number, "行: 未知属性类型: ", type)
			return false
	
	return true

# 安全解析JSON字段
func parse_json_field_safe(json_string: String) -> Dictionary:
	if json_string.is_empty():
		return {}
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("JSON解析错误: ", json.get_error_message())
		return {}
	
	var result = json.data
	
	# 确保返回Dictionary类型
	if result is Dictionary:
		# 对global_check字段进行格式验证和转换
		if json_string.contains("check_mode"):
			var converted = _convert_legacy_global_check(result)
			if not converted.is_empty():
				return converted
		return result
	else:
		print("JSON解析结果不是Dictionary类型，返回空字典。解析结果类型: ", typeof(result), "，值: ", result)
		return {}

# 转换旧格式global_check为新格式
func _convert_legacy_global_check(old_format: Dictionary) -> Dictionary:
	if old_format.is_empty():
		return {}
	
	# 如果已经是新格式，直接返回
	if old_format.has("required_checks"):
		return old_format
	
	var requirements = []
	
	# 处理旧格式
	if old_format.has("check_mode"):
		var check_mode = old_format.get("check_mode", "")
		if check_mode == "single_attribute":
			var attr_check = old_format.get("single_attribute_check", {})
			if attr_check.has("attribute_name") and attr_check.has("threshold"):
				requirements.append({
					"attribute": attr_check.get("attribute_name", ""),
					"threshold": attr_check.get("threshold", 0),
					"success_required": attr_check.get("success_required", 1)
				})
		elif check_mode == "multi_attribute":
			var checks = old_format.get("multi_attribute_check", [])
			for check in checks:
				if check.has("attribute_name") and check.has("threshold"):
					requirements.append({
						"attribute": check.get("attribute_name", ""),
						"threshold": check.get("threshold", 0),
						"success_required": check.get("success_required", 1)
					})
	
	if requirements.is_empty():
		return old_format
	
	return {
		"required_checks": requirements
	}

# 验证global_check格式
func _validate_global_check_format(global_check: Dictionary) -> bool:
	if global_check.is_empty():
		return true
	
	# 检查新格式
	if global_check.has("required_checks"):
		var checks = global_check["required_checks"]
		if not checks is Array:
			print("EventManager: global_check格式错误 - required_checks不是数组")
			return false
		
		for check in checks:
			if not check is Dictionary:
				print("EventManager: global_check格式错误 - 检查项不是字典")
				return false
			
			if not check.has("attribute") or not check.has("threshold"):
				print("EventManager: global_check格式错误 - 缺少必需字段attribute或threshold")
				return false
			
			var attribute = check.get("attribute", "")
			var threshold = check.get("threshold", 0)
			var success_required = check.get("success_required", 1)
			
			# 验证属性名称
			var valid_attributes = ["social", "resistance", "innovation", "execution", "physical", "power", "reputation", "piety"]
			if not attribute in valid_attributes:
				print("EventManager: global_check格式错误 - 无效属性名称: ", attribute)
				return false
			
			# 验证数值 - 放宽类型检查，允许int或float
			var threshold_value = 0
			if threshold is int:
				threshold_value = threshold
			elif threshold is float:
				threshold_value = int(threshold)
			else:
				print("EventManager: global_check格式错误 - 阈值不是数字: ", threshold)
				return false
			
			if threshold_value < 0:
				print("EventManager: global_check格式错误 - 阈值不能为负数: ", threshold_value)
				return false
			
			var success_required_value = 1
			if success_required is int:
				success_required_value = success_required
			elif success_required is float:
				success_required_value = int(success_required)
			else:
				print("EventManager: global_check格式错误 - 成功要求不是数字: ", success_required)
				return false
			
			if success_required_value < 1:
				print("EventManager: global_check格式错误 - 成功要求必须大于0: ", success_required_value)
				return false
		
		return true
	
	# 检查旧格式 - 为了兼容性
	if global_check.has("check_mode"):
		print("EventManager: 检测到旧格式global_check - 兼容但建议升级")
		return true
	
	print("EventManager: global_check格式未知")
	return false

# 应用global_check格式转换到事件
func _apply_global_check_conversion(event: GameEvent):
	if not event or event.global_check.is_empty():
		return
	
	if not _validate_global_check_format(event.global_check):
		print("EventManager: 事件 ", event.event_name, " 的global_check格式无效，尝试修复...")
		
		# 尝试转换旧格式
		var converted = _convert_legacy_global_check(event.global_check)
		if not converted.is_empty() and _validate_global_check_format(converted):
			event.global_check = converted
			print("EventManager: 事件 ", event.event_name, " 的global_check格式已修复")
		else:
			print("EventManager: 无法修复事件 ", event.event_name, " 的global_check格式")

# 检查是否已有加载的数据
func has_loaded_data() -> bool:
	var total = get_total_events_count()
	return total > 0

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

# 获取特定类别的所有事件（无限制）
func get_all_events_unrestricted(category: String) -> Array:
	var all_events = []
	if events.has(category):
		for event_id in events[category]:
			all_events.append(events[category][event_id])
	
	print("无限制模式: ", category, " 类别共有 ", all_events.size(), " 个事件")
	return all_events

# 获取特定类别的所有事件（用于调试和数据查看）
func get_events_by_category(category: String) -> Array:
	var category_events = []
	if events.has(category):
		for event_id in events[category]:
			category_events.append(events[category][event_id])
	
	if debug_mode:
		print("调试模式: ", category, " 类别共有 ", category_events.size(), " 个事件")
	
	return category_events

# 获取周末事件（基于统一前置条件筛选）
func get_weekend_events() -> Array[GameEvent]:
	print("=== EventManager.get_weekend_events 开始 ===")
	
	var weekend_events: Array[GameEvent] = []
	var settled_events_filtered = 0
	var prerequisite_filtered = 0
	var settled_events_reactivated = 0
	
	# 从所有类别中筛选周末事件
	for category in events:
		for event_id in events[category]:
			var event = events[category][event_id]
			
			# 统一前置条件检查（包括day_type）
			if not check_prerequisites(event):
				prerequisite_filtered += 1
				continue
			
			# 检查最大触发次数限制（对所有事件，包括settled事件）
			if not check_max_occurrences_limit(event):
				continue
			
			# 检查冷却时间限制（对所有事件，包括settled事件）
			if not check_cooldown_after_settlement(event, current_round):
				continue
			
			# 状态感知处理：处理已完成事件的状态
			if completed_events.has(event.event_id):
				var event_status = get_event_status(event.event_id)
				
				if event_status == "settled":
					# settled事件通过了规则检查，可以重新激活
					print("EventManager: 重新激活已结算周末事件 - ", event.event_name, " (ID:", event.event_id, ")")
					# 清除completed_events记录，让事件重新变为可触发状态
					completed_events.erase(event.event_id)
					settled_events_reactivated += 1
				elif event_status == "completed":
					# completed状态：继续后续检查，由event.is_valid_in_round()决定最终可见性
					pass
			
			# 检查事件的day_type是否为weekend
			if event.prerequisite_conditions.has("day_type"):
				var day_type = event.prerequisite_conditions["day_type"]
				if day_type == "weekend":
					weekend_events.append(event)
					print("EventManager: 添加周末事件 - ", event.event_name, " day_type:", day_type)
	
	if settled_events_reactivated > 0:
		print("EventManager: 共重新激活了", settled_events_reactivated, "个已结算周末事件")
	if prerequisite_filtered > 0:
		print("EventManager: 共过滤了", prerequisite_filtered, "个不符合前置条件的周末事件")
	
	print("=== EventManager.get_weekend_events 完成，共收集", weekend_events.size(), "个周末事件 ===")
	return weekend_events

# 检查事件前置条件
func check_prerequisites(event: GameEvent) -> bool:
	# 首先检查概率判定
	if not check_event_chance_for_current_round(event.event_id):
		if detailed_debug_mode:
			print("前置条件失败: ", event.event_name, " - 未通过回合概率判定")
		return false
	
	var prereq = event.prerequisite_conditions
	if prereq.is_empty():
		return true
	
	# 缓存当前场景类型，避免重复调用
	var current_scene_type = ""
	if TimeManager:
		current_scene_type = TimeManager.get_current_scene_type()
	
	# 示例检查：回合范围
	if prereq.has("round_range"):
		var range_arr = prereq["round_range"]
		if range_arr.size() >= 2:
			if current_round < range_arr[0] or current_round > range_arr[1]:
				if detailed_debug_mode:
					print("前置条件失败: ", event.event_name, " - 回合范围 [", range_arr[0], "-", range_arr[1], "], 当前:", current_round)
				return false
	
	# 检查日期类型（核心过滤逻辑）
	if prereq.has("day_type"):
		var required_day_type = prereq["day_type"]
		
		if required_day_type != current_scene_type:
			if detailed_debug_mode:
				print("前置条件失败: ", event.event_name, " - 需要场景类型: ", required_day_type, ", 当前场景类型: ", current_scene_type)
			return false
		else:
			if detailed_debug_mode:
				print("前置条件通过: ", event.event_name, " - 场景类型匹配: ", required_day_type)
	
	# 检查必需的前置事件
	if prereq.has("required_events"):
		var required_events = prereq["required_events"]
		if detailed_debug_mode:
			print("前置条件检查: ", event.event_name, " - 检查required_events: ", required_events)
		if required_events is Array:
			for required_event_id in required_events:
				var event_id_int = required_event_id if required_event_id is int else int(required_event_id)
				var is_settled = is_event_settled(event_id_int)
				var event_status = get_event_status(event_id_int)
				if detailed_debug_mode:
					print("前置条件检查: ", event.event_name, " - 检查事件", event_id_int, " 是否已结算: ", is_settled, " 状态: ", event_status)
				if not is_settled:
					if detailed_debug_mode:
						print("前置条件失败: ", event.event_name, " - 需要事件", event_id_int, "已结算，但当前状态为: ", event_status)
					return false
		if detailed_debug_mode:
			print("前置条件通过: ", event.event_name, " - required_events检查通过")
	
	# 检查排除的事件
	if prereq.has("excluded_events"):
		var excluded_events = prereq["excluded_events"]
		if excluded_events is Array:
			for excluded_event_id in excluded_events:
				var event_id_int = excluded_event_id if excluded_event_id is int else int(excluded_event_id)
				if is_event_settled(event_id_int):
					if detailed_debug_mode:
						print("前置条件失败: ", event.event_name, " - 排除事件", event_id_int, "已结算")
					return false
	
	# 检查分支选择要求
	if prereq.has("required_branch_selection"):
		var branch_req = prereq["required_branch_selection"]
		if branch_req is Dictionary:
			var required_event_id = branch_req.get("event_id", 0)
			var required_branch_id = branch_req.get("branch_id", 0)
			
			if detailed_debug_mode:
				print("前置条件检查: ", event.event_name, " - 检查分支选择要求: 事件", required_event_id, "分支", required_branch_id)
			
			if EventSlotManager:
				var selected_branch = EventSlotManager.get_selected_branch_id(required_event_id)
				if selected_branch != required_branch_id:
					if detailed_debug_mode:
						print("前置条件失败: ", event.event_name, " - 需要事件", required_event_id, "的分支", required_branch_id, "，但实际选择了分支", selected_branch)
					return false
				else:
					if detailed_debug_mode:
						print("前置条件通过: ", event.event_name, " - 分支选择匹配: 事件", required_event_id, "分支", required_branch_id)
			else:
				if detailed_debug_mode:
					print("前置条件失败: ", event.event_name, " - EventSlotManager不可用，无法检查分支选择")
				return false
	
	# 检查必需属性
	if prereq.has("required_attributes"):
		var required_attrs = prereq["required_attributes"]
		if not required_attrs.is_empty():
			# 暂时跳过属性检查
			# return false
			pass
	
	return true

# 更新当前回合的可用事件
func update_available_events():
	print("EventManager: 更新可用事件 - 回合:", current_round)
	
	# 清空当前活跃事件列表
	for category in active_events:
		active_events[category].clear()
	
	# 使用统一的事件获取接口更新各类事件
	for category in ["character", "random", "daily", "ending"]:
		if active_events.has(category):
			var available = get_active_events_by_category(category)
			active_events[category] = available
			print("EventManager: 更新", category, "事件 - 数量:", available.size())
	
	print("已更新可用事件")
	events_updated.emit()

# 设置当前回合
func set_current_round(round_number: int):
	current_round = round_number
	update_available_events()

# 获取当前回合的活跃事件
func get_active_events(round_number: int, event_category: String = "") -> Array:
	var active_events_list = []
	var settled_events_filtered = 0
	var prerequisite_filtered = 0
	var max_occurrences_filtered = 0
	var cooldown_filtered = 0
	var settled_events_reactivated = 0
	
	print("EventManager: 开始收集活跃事件 - 回合:", round_number, " 类别:", event_category)
	
	# 遍历所有类别的事件
	for category in events:
		for event_id in events[category]:
			var event = events[category][event_id]
			
			# 统一前置条件检查（包括day_type）
			if not check_prerequisites(event):
				prerequisite_filtered += 1
				continue
			
			# 检查最大触发次数限制（对所有事件，包括settled事件）
			if not check_max_occurrences_limit(event):
				max_occurrences_filtered += 1
				continue
			
			# 检查冷却时间限制（对所有事件，包括settled事件）
			if not check_cooldown_after_settlement(event, round_number):
				cooldown_filtered += 1
				continue
			
			# 状态感知处理：处理已完成事件的状态
			if completed_events.has(event.event_id):
				var event_status = get_event_status(event.event_id)
				
				if event_status == "settled":
					# settled事件通过了规则检查，可以重新激活
					print("EventManager: 重新激活已结算事件 - ", event.event_name, " (ID:", event.event_id, ")")
					# 清除completed_events记录，让事件重新变为可触发状态
					completed_events.erase(event.event_id)
					settled_events_reactivated += 1
				elif event_status == "completed":
					# completed状态：继续后续检查，由event.is_valid_in_round()决定最终可见性
					pass
			
			# 检查事件是否在当前回合有效（这里会处理completed状态的显示逻辑）
			if event.is_valid_in_round(round_number, self):
				# 如果指定了类别，只返回匹配的事件
				if event_category == "" or event.get_event_category() == event_category:
					active_events_list.append(event)
					print("EventManager: 添加活跃事件 - ", event.event_name, " 类别:", event.get_event_category())
	
	if settled_events_reactivated > 0:
		print("EventManager: 共重新激活了", settled_events_reactivated, "个已结算事件")
	if prerequisite_filtered > 0:
		print("EventManager: 共过滤了", prerequisite_filtered, "个不符合前置条件的事件")
	if max_occurrences_filtered > 0:
		print("EventManager: 共过滤了", max_occurrences_filtered, "个达到最大触发次数的事件")
	if cooldown_filtered > 0:
		print("EventManager: 共过滤了", cooldown_filtered, "个处于冷却期的事件")
	
	print("EventManager: 活跃事件收集完成 - 总数:", active_events_list.size())
	return active_events_list

# 兼容性方法：获取特定类别的活跃事件（使用当前回合）
func get_active_events_by_category(category: String) -> Array:
	return get_active_events(current_round, category)

# 设置调试模式
func set_debug_mode(enabled: bool):
	debug_mode = enabled
	print("EventManager调试模式: ", "开启" if enabled else "关闭")
	
	# 重新更新可用事件
	update_available_events()

# 标记事件为已完成
func mark_event_completed(event_id: int):
	# 获取事件对象以获取 duration_rounds
	var event = get_event_by_id(event_id)
	if not event:
		print("EventManager: 错误 - 找不到事件 ", event_id)
		return
	
	# 获取当前场景类型和场景回合数
	var current_scene_type = "workday"
	var current_scene_round = 1
	if TimeManager:
		current_scene_type = TimeManager.get_current_scene_type()
		current_scene_round = TimeManager.get_scene_round_count(current_scene_type)
	
	# 计算结算回合和场景类型
	var duration_rounds = event.duration_rounds
	# 修复：统一Duration Round语义 - 在持续显示N个回合后的下一个回合结束时检定
	var settlement_round = current_round + duration_rounds
	var settlement_scene_type = current_scene_type
	var settlement_scene_round = current_scene_round + duration_rounds
	
	# 场景感知的结算计算
	if duration_rounds > 1:
		# 计算在相同场景类型下需要等待的回合数
		settlement_scene_round = current_scene_round + duration_rounds
		print("EventManager: 场景感知结算 - 当前场景回合:", current_scene_round, " 结算场景回合:", settlement_scene_round)
	
	# 获取事件占用的卡牌列表
	var cards_in_use = []
	if EventSlotManager:
		var slot_data = EventSlotManager.get_event_slots(event_id)
		for slot in slot_data:
			if slot.has_card_placed():
				cards_in_use.append({
					"card_type": slot.placed_card_type,
					"card_id": slot.placed_card_id,
					"slot_id": slot.slot_id
				})
	
	# 创建完整的完成状态数据
	var completion_data = {
		"completed_round": current_round,
		"completed_scene_type": current_scene_type,
		"completed_scene_round": current_scene_round,  # 新增：完成时的场景回合数
		"completion_time": Time.get_unix_time_from_system(),
		"duration_rounds": duration_rounds,
		"settlement_round": settlement_round,
		"settlement_scene_type": settlement_scene_type,
		"settlement_scene_round": settlement_scene_round,  # 新增：预期结算的场景回合数
		"is_settled": false,
		"event_status": "completed",  # 新增：事件状态管理
		"cards_in_use": cards_in_use
	}
	completed_events[event_id] = completion_data
	
	# 更新事件触发次数
	if event_trigger_counts.has(event_id):
		event_trigger_counts[event_id] += 1
	else:
		event_trigger_counts[event_id] = 1
	
	# 注意：冷却期将在检定完成后开始，而不是在事件完成时开始
	
	print("EventManager: 标记事件完成 - ID:", event_id)
	print("EventManager: Duration Round语义 - 持续显示", duration_rounds, "个回合，在第", duration_rounds + 1, "个回合结束时检定")
	print("EventManager: 延迟检定 - 当前回合:", current_round, " 检定回合:", settlement_round)
	print("EventManager: 场景信息 - 当前:", current_scene_type, "(", current_scene_round, ") 结算:", settlement_scene_type, "(", settlement_scene_round, ")")
	print("EventManager: 占用卡牌数量:", cards_in_use.size())
	
	# 注册卡牌延迟忙碌状态
	var global_usage_manager = get_node_or_null("/root/GlobalCardUsageManager")
	if global_usage_manager:
		for card_info in cards_in_use:
			global_usage_manager.register_duration_busy(
				card_info.card_type,
				card_info.card_id,
				settlement_round,
				settlement_scene_type
			)
			print("EventManager: 注册卡牌延迟忙碌 - ", card_info.card_type, "[", card_info.card_id, "] 至回合", settlement_round)
	
	event_completed.emit(event_id)
	
	# 延迟UI刷新到下一帧，确保所有信号处理完成
	call_deferred("_deferred_ui_update")

# 延迟的UI更新方法
func _deferred_ui_update():
	update_available_events()

# 检查事件是否已完成
func is_event_completed(event_id: int) -> bool:
	return completed_events.has(event_id)

# 获取事件完成数据
func get_event_completion_data(event_id: int) -> Dictionary:
	if completed_events.has(event_id):
		return completed_events[event_id]
	return {}

# 获取调试信息
func get_debug_info() -> Dictionary:
	var info = {
		"debug_mode": debug_mode,
		"current_round": current_round,
		"total_events": get_total_events_count(),
		"events_by_category": {},
		"trigger_statistics": {
			"total_unique_events_triggered": event_trigger_counts.size(),
			"total_trigger_count": 0,
			"events_at_max_occurrences": 0,
			"events_in_cooldown": 0
		}
	}
	
	for category in events:
		info.events_by_category[category] = events[category].size()
	
	# 计算触发统计
	var total_triggers = 0
	var at_max_count = 0 
	var in_cooldown_count = 0
	
	for event_id in event_trigger_counts.keys():
		total_triggers += event_trigger_counts[event_id]
		
		var event = get_event_by_id(event_id)
		if event:
			# 检查是否达到最大次数
			if event.max_occurrences > 0 and event_trigger_counts[event_id] >= event.max_occurrences:
				at_max_count += 1
			
			# 检查是否在冷却期（基于检定完成后的冷却期）
			if event.cooldown > 0 and event_last_completed.has(event_id):
				var last_settled_round = event_last_completed[event_id]
				var rounds_passed = current_round - last_settled_round
				if rounds_passed < event.cooldown:
					in_cooldown_count += 1
	
	info.trigger_statistics.total_trigger_count = total_triggers
	info.trigger_statistics.events_at_max_occurrences = at_max_count
	info.trigger_statistics.events_in_cooldown = in_cooldown_count
	
	return info

# 独立测试数据加载
func test_data_loading() -> Dictionary:
	var test_result = {
		"file_access": false,
		"file_content": false,
		"header_validation": false,
		"data_parsing": false,
		"event_creation": false,
		"total_lines": 0,
		"valid_lines": 0,
		"errors": []
	}
	
	var file_path = EVENTS_DATA_PATH
	
	# 测试文件访问
	if FileAccess.file_exists(file_path):
		test_result.file_access = true
		print("✓ 文件访问测试通过")
	else:
		test_result.errors.append("文件不存在: " + file_path)
		print("✗ 文件访问测试失败")
		return test_result
	
	# 测试文件内容读取
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		
		if not content.is_empty():
			test_result.file_content = true
			print("✓ 文件内容读取测试通过")
			
			var lines = content.split("\n")
			test_result.total_lines = lines.size()
			
			# 测试表头验证
			if lines.size() > 0:
				var header = lines[0].split("\t")
				if header.size() >= 22:
					test_result.header_validation = true
					print("✓ 表头验证测试通过")
				else:
					test_result.errors.append("表头列数不足: " + str(header.size()) + "/22")
					print("✗ 表头验证测试失败")
			
			# 测试数据解析
			var valid_data_lines = 0
			for i in range(1, min(lines.size(), 6)):  # 只测试前5行数据
				var line = lines[i].strip_edges()
				if line.is_empty():
					continue
				
				var columns = line.split("\t")
				if columns.size() >= 22:
					valid_data_lines += 1
				else:
					test_result.errors.append("第" + str(i+1) + "行列数不足: " + str(columns.size()) + "/22")
			
			if valid_data_lines > 0:
				test_result.data_parsing = true
				test_result.valid_lines = valid_data_lines
				print("✓ 数据解析测试通过，有效行数: ", valid_data_lines)
				
				# 测试事件对象创建
				var test_line = lines[1].strip_edges()
				if not test_line.is_empty():
					var test_columns = test_line.split("\t")
					if test_columns.size() >= 22:
						var test_event = create_event_with_error_handling(test_columns, 2)
						if test_event != null:
							test_result.event_creation = true
							print("✓ 事件对象创建测试通过")
						else:
							test_result.errors.append("无法创建测试事件对象")
							print("✗ 事件对象创建测试失败")
			else:
				test_result.errors.append("没有有效的数据行")
				print("✗ 数据解析测试失败")
		else:
			test_result.errors.append("文件内容为空")
			print("✗ 文件内容读取测试失败")
	else:
		test_result.errors.append("无法打开文件")
		print("✗ 文件内容读取测试失败")
	
	return test_result

# 加载事件文本数据
func load_event_text_data():
	if not FileAccess.file_exists(EVENT_TEXT_DATA_PATH):
		print("⚠ 事件文本数据文件不存在: ", EVENT_TEXT_DATA_PATH)
		return
	
	var file = FileAccess.open(EVENT_TEXT_DATA_PATH, FileAccess.READ)
	if not file:
		printerr("✗ 无法打开事件文本数据文件: ", EVENT_TEXT_DATA_PATH)
		return
	
	# 读取表头行
	var header = file.get_csv_line(",")
	if header.is_empty() or (header.size() == 1 and header[0].is_empty()):
		print("⚠ 事件文本数据文件为空")
		file.close()
		return
	
	# 验证表头格式
	var expected_headers = ["event_id", "branch_id", "pre_check_text", "success_text", "failure_text", "card_text_success", "card_text_failure"]
	for i in range(expected_headers.size()):
		if i >= header.size() or header[i].strip_edges() != expected_headers[i]:
			print("⚠ 表头格式不正确，期望:", expected_headers, "实际:", header)
			file.close()
			return
	
	print("✓ 表头验证通过")
	
	# 处理数据记录
	var loaded_count = 0
	var record_count = 0
	
	while not file.eof_reached():
		var columns = file.get_csv_line(",")
		
		# 跳过空行
		if columns.is_empty() or (columns.size() == 1 and columns[0].strip_edges().is_empty()):
			continue
		
		record_count += 1
		
		# 验证列数
		if columns.size() < 7:
			print("⚠ 第", record_count+1, "条记录数据不完整，跳过 - 列数:", columns.size(), "/7")
			continue
		
		# 验证event_id
		var event_id_str = columns[0].strip_edges()
		if event_id_str.is_empty() or not event_id_str.is_valid_int():
			print("⚠ 第", record_count+1, "条记录event_id无效: '", event_id_str, "'，跳过")
			continue
		
		var event_id = event_id_str.to_int()
		var branch_id = columns[1].strip_edges().to_int()
		
		# 解码转义序列：将\\n转换为真实换行符
		var pre_check_text = decode_escape_sequences(columns[2].strip_edges())
		var success_text = decode_escape_sequences(columns[3].strip_edges())
		var failure_text = decode_escape_sequences(columns[4].strip_edges())
		var card_text_success = decode_escape_sequences(columns[5].strip_edges())
		var card_text_failure = decode_escape_sequences(columns[6].strip_edges())
		
		# 存储文本数据
		event_text_data[event_id] = {
			"branch_id": branch_id,
			"pre_check_text": pre_check_text,
			"success_text": success_text,
			"failure_text": failure_text,
			"card_text_success": card_text_success,
			"card_text_failure": card_text_failure,
			"card_display_text": card_text_success if not card_text_success.is_empty() else ("分支" + str(branch_id)),
			"remarks": "branch_" + str(branch_id)
		}
		
		loaded_count += 1
	
	file.close()
	print("✓ 事件文本数据加载完成，共加载 ", loaded_count, " 条记录")
	
	# 应用文本数据到事件对象
	apply_text_data_to_events()

# 解码转义序列
func decode_escape_sequences(text: String) -> String:
	# 将转义序列转换为实际字符
	# \\n -> \n (换行符)
	# \\r -> \r (回车符)  
	# \\t -> \t (制表符)
	# \\\\ -> \ (反斜杠)
	return text.replace("\\n", "\n").replace("\\r", "\r").replace("\\t", "\t").replace("\\\\", "\\")

# 将文本数据应用到事件对象
func apply_text_data_to_events():
	var applied_count = 0
	var total_checked = 0
	
	for category in events:
		for event_id in events[category]:
			total_checked += 1
			var event = events[category][event_id]
			
			if event_text_data.has(event.event_id):
				var text_data = event_text_data[event.event_id]
				
				# 更新为新的数据结构
				event.set_text_data(
					text_data.pre_check_text, 
					text_data.card_display_text,
					text_data.success_text,
					text_data.failure_text,
					text_data.card_text_success,
					text_data.card_text_failure
				)
				
				applied_count += 1
	
	print("✓ 文本数据应用完成: ", applied_count, "/", total_checked, " 个事件")

# 获取事件的预检文本
func get_event_pre_check_text(event_id: int) -> String:
	if event_text_data.has(event_id):
		return event_text_data[event_id].pre_check_text
	return ""

# 获取事件的卡片显示文本
func get_event_card_display_text(event_id: int) -> String:
	if event_text_data.has(event_id):
		return event_text_data[event_id].card_display_text
	return ""

# 获取事件的成功文本
func get_event_success_text(event_id: int) -> String:
	if event_text_data.has(event_id):
		return event_text_data[event_id].success_text
	return ""

# 获取事件的失败文本
func get_event_failure_text(event_id: int) -> String:
	if event_text_data.has(event_id):
		return event_text_data[event_id].failure_text
	return ""

# 获取事件的成功卡片文本
func get_event_card_text_success(event_id: int) -> String:
	if event_text_data.has(event_id):
		return event_text_data[event_id].card_text_success
	return ""

# 获取事件的失败卡片文本
func get_event_card_text_failure(event_id: int) -> String:
	if event_text_data.has(event_id):
		return event_text_data[event_id].card_text_failure
	return ""

# ========== 事件检定系统 ==========

# 事件检定结果类
class EventCheckResult:
	var event_id: int
	var event_name: String
	var attribute_totals: Dictionary
	var check_attempts: int
	var check_results: Array  # [1,0,1,0,...]
	var success_count: int
	var is_successful: bool
	var required_successes: int
	var required_attribute: String
	var threshold: int
	var meets_threshold: bool
	
	func _init():
		event_id = -1
		event_name = ""
		attribute_totals = {}
		check_attempts = 0
		check_results = []
		success_count = 0
		is_successful = false
		required_successes = 0
		required_attribute = ""
		threshold = 0
		meets_threshold = false

# 执行事件检定
func perform_event_check(event: GameEvent) -> EventCheckResult:
	print("EventManager: 开始执行事件检定 - ", event.event_name)
	
	var result = EventCheckResult.new()
	result.event_id = event.event_id
	result.event_name = event.event_name
	
	# 1. 获取卡槽属性总和
	if not EventSlotManager:
		print("EventManager: 错误 - EventSlotManager未找到")
		return result
	
	result.attribute_totals = EventSlotManager.calculate_event_slot_attributes(event.event_id)
	print("EventManager: 卡槽属性总和: ", result.attribute_totals)
	
	# 2. 获取事件的检定要求
	var requirements = event.get_attribute_requirements()
	if requirements.is_empty():
		print("EventManager: 事件 ", event.event_name, " 没有检定要求")
		result.is_successful = true  # 没有检定要求则默认成功
		return result
	
	# 取第一个检定要求（目前只支持单一检定）
	var main_requirement = requirements[0]
	result.required_attribute = main_requirement.attribute
	result.threshold = main_requirement.threshold
	result.required_successes = main_requirement.success_required
	
	print("EventManager: 检定要求 - 属性:", result.required_attribute, " 阈值:", result.threshold, " 成功次数:", result.required_successes)
	
	# 3. 计算检定次数（基于属性总值）
	result.check_attempts = result.attribute_totals.get(result.required_attribute, 0)
	print("EventManager: 检定次数: ", result.check_attempts)
	
	# 4. 阈值检查
	result.meets_threshold = result.check_attempts >= result.threshold
	if not result.meets_threshold:
		print("EventManager: 阈值检查失败 - 需要:", result.threshold, " 实际:", result.check_attempts)
		result.is_successful = false
		return result
	
	print("EventManager: 阈值检查通过，开始随机检定")
	
	# 5. 执行随机检定
	result.check_results = perform_random_checks(result.check_attempts)
	result.success_count = result.check_results.count(1)
	result.is_successful = result.success_count >= result.required_successes
	
	print("EventManager: 随机检定完成 - 成功次数:", result.success_count, "/", result.required_successes, " 最终结果:", "成功" if result.is_successful else "失败")
	
	return result

# 执行随机检定（50%概率）
func perform_random_checks(attempts: int) -> Array:
	var results = []
	print("EventManager: 开始", attempts, "次随机检定")
	
	for i in range(attempts):
		var roll = randi() % 2  # 0或1，50%概率
		results.append(roll)
		print("EventManager: 第", i+1, "次检定结果: ", roll)
	
	return results

# 计算检定成功概率（用于UI预览）
func calculate_success_probability(attempts: int, required_successes: int) -> float:
	if attempts < required_successes:
		return 0.0
	
	if required_successes == 0:
		return 1.0
	
	# 简化计算：使用二项分布的期望值估算
	var expected_successes = attempts * 0.5
	if expected_successes >= required_successes:
		# 粗略估算，实际应该使用二项分布公式
		var success_rate = min(1.0, expected_successes / required_successes)
		return success_rate
	else:
		return 0.3  # 给一个基础概率

# 收集需要检定的事件
func collect_events_for_checking() -> Array:
	var events_to_check = []
	
	print("EventManager: 开始收集需要检定的事件")
	
	# 收集状态为 pending_check 的事件
	for event_id in completed_events.keys():
		var completion_data = completed_events[event_id]
		if completion_data.get("event_status", "completed") == "pending_check":
			var event = get_event_by_id(event_id)
			if event and event.has_attribute_check():
				events_to_check.append(event)
				print("EventManager: 找到需要检定的事件: ", event.event_name, " (ID:", event_id, ")")
	
	print("EventManager: 共找到 ", events_to_check.size(), " 个需要检定的事件")
	return events_to_check

# 收集延迟检定事件（Duration Round检定逻辑的核心方法）
func collect_events_for_delayed_checking(current_round_num: int, scene_type: String) -> Array:
	var events_ready_for_check = []
	
	print("EventManager: 检查延迟检定事件 - 回合:", current_round_num, " 场景:", scene_type)
	
	# 收集状态为 completed 且到达检定时间的事件
	for event_id in completed_events.keys():
		var completion_data = completed_events[event_id]
		if completion_data.get("event_status", "completed") == "completed" and should_check_event(completion_data, current_round_num, scene_type):
			var event = get_event_by_id(event_id)
			if event:
				events_ready_for_check.append(event_id)
				# 设置状态为等待检定
				set_event_status(event_id, "pending_check")
				print("EventManager: 事件到达检定时间: ", event.event_name, " (ID:", event_id, ") Duration:", event.duration_rounds)
	
	print("EventManager: 共有 ", events_ready_for_check.size(), " 个事件到达检定时间")
	return events_ready_for_check

# 检查事件是否应该进行检定（简化版本）
func should_check_event(completion_data: Dictionary, current_round_num: int, scene_type: String) -> bool:
	var settlement_round = completion_data.settlement_round
	var duration_rounds = completion_data.duration_rounds
	var completed_round = completion_data.completed_round
	
	print("EventManager: 检定检查 - 完成回合:", completed_round, " 持续:", duration_rounds, " 当前回合:", current_round_num, " 检定回合:", settlement_round)
	
	# 统一逻辑：当前回合数达到或超过检定回合时进行检定
	var should_check = current_round_num >= settlement_round
	
	if should_check:
		print("EventManager: 事件到达检定时间 - 当前回合:", current_round_num, " >= 检定回合:", settlement_round)
	else:
		print("EventManager: 事件未到检定时间 - 当前回合:", current_round_num, " < 检定回合:", settlement_round)
	
	return should_check

# 根据事件ID获取事件对象
func get_event_by_id(event_id: int) -> GameEvent:
	for category in events:
		if events[category].has(event_id):
			return events[category][event_id]
	return null

# 执行事件检定结算
func execute_event_settlement(check_result: EventCheckResult):
	print("EventManager: 开始执行事件结算 - ", check_result.event_name)
	
	var event = get_event_by_id(check_result.event_id)
	if not event:
		print("EventManager: 错误 - 找不到事件 ", check_result.event_id)
		return
	
	# 执行奖励结算
	var applied_rewards = {}
	if check_result.is_successful:
		print("EventManager: 执行成功结算")
		applied_rewards = event.execute_success_results()
	else:
		print("EventManager: 执行失败结算")
		applied_rewards = event.execute_failure_results()
	
	# 设置事件状态为已结算
	set_event_status(check_result.event_id, "settled")
	
	# 开始冷却期计时（检定完成后才开始冷却）
	event_last_completed[check_result.event_id] = current_round
	print("EventManager: 事件检定完成，开始冷却期 - ", check_result.event_name, " 冷却时间:", event.cooldown, "回合")
	
	# 设置事件状态为settled
	set_event_status(check_result.event_id, "settled")
	
	# 标记为已结算（保持向后兼容）
	if completed_events.has(check_result.event_id):
		completed_events[check_result.event_id].is_settled = true
	
	# 清空事件卡槽
	if EventSlotManager:
		EventSlotManager.clear_event_slots(check_result.event_id)
	
	# 释放延迟忙碌的卡牌
	var global_usage_manager = get_node_or_null("/root/GlobalCardUsageManager")
	if global_usage_manager and completed_events.has(check_result.event_id):
		var completion_data = completed_events[check_result.event_id]
		for card_info in completion_data.cards_in_use:
			global_usage_manager.release_duration_busy_cards(current_round, TimeManager.get_current_scene_type())
	
	print("EventManager: 事件结算完成 - 奖励:", applied_rewards)
	print("EventManager: 事件状态已设置为settled - ID:", check_result.event_id)
	
	# 调试：验证状态设置是否成功
	if detailed_debug_mode:
		var verify_status = get_event_status(check_result.event_id)
		print("EventManager: 验证事件状态设置 - ID:", check_result.event_id, " 当前状态:", verify_status)
		print("EventManager: is_event_settled验证 - ID:", check_result.event_id, " 结果:", is_event_settled(check_result.event_id))
	
	# 记录分支选择（如果事件有分支）
	if EventSlotManager:
		var selected_branch = EventSlotManager.determine_branch_id(check_result.event_id)
		if selected_branch > 0:
			EventSlotManager.record_branch_selection(check_result.event_id, selected_branch)
			print("EventManager: 记录事件", check_result.event_id, "的分支选择:", selected_branch)

# 移除了后续事件触发机制，改为纯前置条件控制

# 处理延迟检定事件（在回合结束时调用，确保检定在正确时机触发）
func process_delayed_checks(current_round_num: int, scene_type: String):
	print("EventManager: 处理延迟检定事件 - 回合:", current_round_num, " 场景:", scene_type, " (回合结束时)")
	
	# 收集到达检定时间的事件
	var events_ready_for_check = collect_events_for_delayed_checking(current_round_num, scene_type)
	
	if events_ready_for_check.size() > 0:
		print("EventManager: 有", events_ready_for_check.size(), "个事件到达检定时间")
		# 这里可以触发检定界面或其他检定流程
		# 实际的检定将在回合结束时通过collect_events_for_checking()收集
	
	return events_ready_for_check.size()

# 保留原有的延迟结算方法（用于检定后的结算）
func process_delayed_settlements(current_round_num: int, scene_type: String):
	print("EventManager: 检查延迟结算事件 - 回合:", current_round_num, " 场景:", scene_type)
	
	var settlements_processed = 0
	var events_to_settle = []
	
	# 收集需要结算的事件（保持原有逻辑用于向后兼容）
	for event_id in completed_events.keys():
		var completion_data = completed_events[event_id]
		if not completion_data.is_settled and should_settle_event(completion_data, current_round_num, scene_type):
			var event = get_event_by_id(event_id)
			if event:
				events_to_settle.append({
					"event": event,
					"completion_data": completion_data
				})
	
	# 执行延迟结算
	for event_info in events_to_settle:
		execute_delayed_settlement(event_info.event, event_info.completion_data)
		settlements_processed += 1
	
	if settlements_processed > 0:
		print("EventManager: 处理了", settlements_processed, "个延迟结算事件")
	
	return settlements_processed

# 检查事件是否应该结算
func should_settle_event(completion_data: Dictionary, current_round_num: int, scene_type: String) -> bool:
	# 检查是否到达结算回合
	if current_round_num < completion_data.settlement_round:
		return false
	
	# 场景感知结算：检查场景类型匹配
	var completed_scene_type = completion_data.completed_scene_type
	var settlement_scene_type = completion_data.settlement_scene_type
	var duration_rounds = completion_data.duration_rounds
	
	print("EventManager: 结算检查 - 完成场景:", completed_scene_type, " 当前场景:", scene_type, " 等待回合:", duration_rounds)
	
	# 如果 duration_rounds = 1，立即结算（已在其他地方处理）
	if duration_rounds <= 1:
		return true
	
	# 场景感知逻辑：计算在相同场景类型下是否已经过了足够的回合
	if TimeManager:
		var completed_scene_round = get_scene_round_at_completion(completion_data)
		var current_scene_round = TimeManager.get_scene_round_count(scene_type)
		
		# 如果在相同场景类型下，检查场景回合数差异
		if scene_type == completed_scene_type:
			var scene_rounds_passed = current_scene_round - completed_scene_round
			print("EventManager: 相同场景结算检查 - 已过场景回合:", scene_rounds_passed, " 需要:", duration_rounds)
			return scene_rounds_passed >= duration_rounds
		else:
			# 不同场景类型，需要更复杂的计算
			# 简化处理：如果已经切换场景且到达结算回合，则结算
			print("EventManager: 跨场景结算检查 - 到达结算回合")
			return true
	
	# 回退到简单的回合检查
	return true

# 获取事件完成时的场景回合数
func get_scene_round_at_completion(completion_data: Dictionary) -> int:
	var completed_scene_type = completion_data.completed_scene_type
	var completed_round = completion_data.completed_round
	
	# 这里需要根据完成时的全局回合数推算场景回合数
	# 简化实现：假设场景回合数等于全局回合数的一半（因为工作日/周末交替）
	# 在实际实现中，应该保存完成时的场景回合数
	if TimeManager:
		# 尝试从TimeManager获取历史场景回合数（如果有的话）
		# 当前简化为使用完成回合数作为估算
		return completed_round
	
	return completed_round

# 执行延迟结算
func execute_delayed_settlement(event: GameEvent, completion_data: Dictionary):
	print("EventManager: 执行延迟结算 - ", event.event_name)
	
	# 这里需要获取原始的检定结果，暂时简化为成功结算
	# 在完整实现中，应该保存检定结果到completion_data中
	var applied_rewards = event.execute_success_results()
	
	# 标记为已结算
	completion_data.is_settled = true
	completed_events[event.event_id] = completion_data
	
	# 开始冷却期计时（检定完成后才开始冷却）
	event_last_completed[event.event_id] = current_round
	print("EventManager: 事件检定完成，开始冷却期 - ", event.event_name, " 冷却时间:", event.cooldown, "回合")
	
	# 释放延迟忙碌的卡牌
	var global_usage_manager = get_node_or_null("/root/GlobalCardUsageManager")
	if global_usage_manager:
		for card_info in completion_data.cards_in_use:
			global_usage_manager.release_duration_busy_cards(current_round, TimeManager.get_current_scene_type())
	
	# 清空事件卡槽
	if EventSlotManager:
		EventSlotManager.clear_event_slots(event.event_id)
	
	print("EventManager: 延迟结算完成 - ", event.event_name, " 奖励:", applied_rewards)

# 获取延迟结算状态信息
func get_delayed_settlement_info() -> Dictionary:
	var info = {
		"total_pending": 0,
		"total_settled": 0,
		"pending_events": [],
		"settled_events": []
	}
	
	for event_id in completed_events.keys():
		var completion_data = completed_events[event_id]
		if completion_data.is_settled:
			info.total_settled += 1
			info.settled_events.append({
				"event_id": event_id,
				"event_name": get_event_name_by_id(event_id),
				"completed_round": completion_data.completed_round,
				"settlement_round": completion_data.settlement_round
			})
		else:
			info.total_pending += 1
			info.pending_events.append({
				"event_id": event_id,
				"event_name": get_event_name_by_id(event_id),
				"completed_round": completion_data.completed_round,
				"settlement_round": completion_data.settlement_round,
				"remaining_rounds": max(0, completion_data.settlement_round - current_round),
				"cards_count": completion_data.cards_in_use.size()
			})
	
	return info

# 根据事件ID获取事件名称
func get_event_name_by_id(event_id: int) -> String:
	var event = get_event_by_id(event_id)
	if event:
		return event.event_name
	return "未知事件"

# 打印延迟结算调试信息
func print_delayed_settlement_debug():
	var info = get_delayed_settlement_info()
	print("=== 延迟结算系统调试信息 ===")
	print("当前回合: ", current_round)
	print("待结算事件: ", info.total_pending, " 个")
	print("已结算事件: ", info.total_settled, " 个")
	
	if info.pending_events.size() > 0:
		print("待结算事件详情:")
		for event_info in info.pending_events:
			print("  - ", event_info.event_name, " (ID:", event_info.event_id, ")")
			print("    完成回合:", event_info.completed_round, " 结算回合:", event_info.settlement_round)
			print("    剩余回合:", event_info.remaining_rounds, " 占用卡牌:", event_info.cards_count, "张")
	
	# 获取延迟忙碌卡牌信息
	var global_usage_manager = get_node_or_null("/root/GlobalCardUsageManager")
	if global_usage_manager:
		var busy_stats = global_usage_manager.get_duration_busy_stats()
		print("延迟忙碌卡牌: ", busy_stats.total_count, " 张")
		print("按类型统计: ", busy_stats.by_type)
		print("按结算回合统计: ", busy_stats.by_settlement_round)
	
	print("=============================")

# 强制执行所有延迟结算（调试用）
func force_execute_all_delayed_settlements():
	print("EventManager: 强制执行所有延迟结算")
	var forced_count = 0
	
	for event_id in completed_events.keys():
		var completion_data = completed_events[event_id]
		if not completion_data.is_settled:
			var event = get_event_by_id(event_id)
			if event:
				execute_delayed_settlement(event, completion_data)
				forced_count += 1
	
	print("EventManager: 强制执行了", forced_count, "个延迟结算")
	return forced_count

# 设置事件状态
func set_event_status(event_id: int, status: String):
	if completed_events.has(event_id):
		completed_events[event_id].event_status = status
		print("EventManager: 设置事件状态 - ID:", event_id, " 状态:", status)
	else:
		print("EventManager: 警告 - 尝试设置不存在事件的状态:", event_id)

# 获取事件状态
func get_event_status(event_id: int) -> String:
	if completed_events.has(event_id):
		return completed_events[event_id].get("event_status", "completed")
	return ""

# 检查事件是否处于特定状态
func is_event_in_status(event_id: int, status: String) -> bool:
	return get_event_status(event_id) == status

# 获取特定状态的事件列表
func get_events_by_status(status: String) -> Array:
	var events_in_status = []
	for event_id in completed_events.keys():
		if get_event_status(event_id) == status:
			events_in_status.append(event_id)
	return events_in_status

# 检查事件是否已结算
func is_event_settled(event_id: int) -> bool:
	var status = get_event_status(event_id)
	var is_settled = status == "settled"
	if detailed_debug_mode:
		print("is_event_settled检查: 事件", event_id, " 状态=", status, " 是否已结算=", is_settled)
	return is_settled

# ========== 回合概率判定系统 ==========

# 为当前回合进行事件概率判定
func determine_round_event_chances(round_number: int):
	print("EventManager: 开始为回合", round_number, "进行事件概率判定")
	
	# 清除旧缓存
	round_chance_cache.clear()
	round_chance_cache[round_number] = {}
	
	var total_events = 0
	var passed_events = 0
	
	# 遍历所有事件进行概率判定
	for category in events:
		for event_id in events[category]:
			var event = events[category][event_id]
			var chance = get_event_chance(event)
			var random_roll = randf()
			var passed = random_roll <= chance
			
			round_chance_cache[round_number][event_id] = passed
			total_events += 1
			if passed:
				passed_events += 1
			
			if detailed_debug_mode:
				print("概率判定: ", event.event_name, " chance=", chance, " 随机数=", "%.3f" % random_roll, " 结果=", "通过" if passed else "失败")
	
	current_round_chance_determined = true
	print("EventManager: 回合", round_number, "概率判定完成 - 通过:", passed_events, "/", total_events)

# 获取事件的概率值
func get_event_chance(event: GameEvent) -> float:
	var prereq = event.prerequisite_conditions
	if prereq.has("chance"):
		var chance_value = prereq.get("chance", 1.0)
		# 确保chance值在0-1范围内
		return clamp(chance_value, 0.0, 1.0)
	return 1.0  # 默认100%概率

# 检查事件是否通过当前回合的概率判定
func check_event_chance_for_current_round(event_id: int) -> bool:
	if not round_chance_cache.has(current_round):
		print("警告: 当前回合", current_round, "未进行概率判定，默认通过")
		return true  # 默认通过
	
	return round_chance_cache[current_round].get(event_id, true)

# 打印回合概率判定结果（调试用）
func print_round_chance_results(round_number: int):
	if not round_chance_cache.has(round_number):
		print("回合", round_number, "无概率判定记录")
		return
	
	print("=== 回合", round_number, "概率判定结果 ===")
	var passed_count = 0
	var total_count = 0
	
	for event_id in round_chance_cache[round_number]:
		var passed = round_chance_cache[round_number][event_id]
		var event = get_event_by_id(event_id)
		if event:
			var chance = get_event_chance(event)
			print("事件", event_id, "(", event.event_name, ") chance=", chance, " 结果=", "通过" if passed else "失败")
			if passed:
				passed_count += 1
			total_count += 1
	
	print("概率判定统计: ", passed_count, "/", total_count, " 通过")
	print("=== 概率判定结果结束 ===")

# 清除过期的概率判定缓存
func cleanup_old_chance_cache():
	var rounds_to_keep = 3  # 保留最近3回合的缓存
	var rounds_to_remove = []
	
	for round_num in round_chance_cache.keys():
		if current_round - round_num > rounds_to_keep:
			rounds_to_remove.append(round_num)
	
	for round_num in rounds_to_remove:
		round_chance_cache.erase(round_num)
		if detailed_debug_mode:
			print("EventManager: 清除回合", round_num, "的概率判定缓存")

# 检查事件是否达到最大触发次数限制
func check_max_occurrences_limit(event: GameEvent) -> bool:
	# 边界条件检查
	if not event:
		print("EventManager: 错误 - 事件对象为空")
		return false
	
	# max_occurrences为0或负数表示无限制
	if event.max_occurrences <= 0:
		return true
	
	# 处理异常的max_occurrences值
	if event.max_occurrences < 0:
		print("EventManager: 警告 - 事件max_occurrences为负数: ", event.event_name, " 值:", event.max_occurrences)
		return true  # 负数当作无限制处理
	
	var current_count = event_trigger_counts.get(event.event_id, 0)
	var can_trigger = current_count < event.max_occurrences
	
	if not can_trigger:
		print("EventManager: 事件达到最大触发次数 - ", event.event_name, " (", current_count, "/", event.max_occurrences, ")")
	
	return can_trigger

# 检查事件是否还在冷却期内（检定完成后的冷却期）
func check_cooldown_after_settlement(event: GameEvent, current_round_num: int) -> bool:
	# 边界条件检查
	if not event:
		print("EventManager: 错误 - 事件对象为空")
		return false
	
	# 检查回合数是否有效
	if current_round_num <= 0:
		print("EventManager: 警告 - 当前回合数无效: ", current_round_num)
		return true  # 回合数无效时默认允许触发
	
	# cooldown为0或负数表示无冷却时间
	if event.cooldown <= 0:
		return true
	
	# 处理异常的cooldown值
	if event.cooldown < 0:
		print("EventManager: 警告 - 事件cooldown为负数: ", event.event_name, " 值:", event.cooldown)
		return true  # 负数当作无冷却处理
	
	# 如果事件从未完成过，则可以触发
	if not event_last_completed.has(event.event_id):
		return true
	
	var last_completed_round = event_last_completed[event.event_id]
	
	# 检查最后完成回合数是否有效
	if last_completed_round <= 0:
		print("EventManager: 警告 - 事件最后完成回合数无效: ", event.event_name, " 值:", last_completed_round)
		return true  # 无效数据时默认允许触发
	
	var rounds_passed = current_round_num - last_completed_round
	var can_trigger = rounds_passed >= event.cooldown
	
	if not can_trigger:
		var remaining_cooldown = event.cooldown - rounds_passed
		print("EventManager: 事件处于冷却期 - ", event.event_name, " 剩余冷却:", remaining_cooldown, "回合")
	
	return can_trigger

# 获取事件触发统计信息（调试用）
func get_event_trigger_statistics() -> Dictionary:
	var stats = {
		"total_unique_events_triggered": event_trigger_counts.size(),
		"total_trigger_count": 0,
		"events_at_max_occurrences": 0,
		"events_in_cooldown": 0,
		"detailed_stats": {}
	}
	
	# 计算总触发次数
	for event_id in event_trigger_counts.keys():
		stats.total_trigger_count += event_trigger_counts[event_id]
	
	# 统计详细信息
	for event_id in event_trigger_counts.keys():
		var event = get_event_by_id(event_id)
		if event:
			var current_count = event_trigger_counts[event_id]
			var is_at_max = (event.max_occurrences > 0 and current_count >= event.max_occurrences)
			var is_in_cooldown = false
			
			if event.cooldown > 0 and event_last_completed.has(event_id):
				var last_settled_round = event_last_completed[event_id]
				var rounds_passed = current_round - last_settled_round
				if rounds_passed < event.cooldown:
					is_in_cooldown = true
			
			if is_at_max:
				stats.events_at_max_occurrences += 1
			if is_in_cooldown:
				stats.events_in_cooldown += 1
			
			stats.detailed_stats[event_id] = {
				"event_name": event.event_name,
				"trigger_count": current_count,
				"max_occurrences": event.max_occurrences,
				"cooldown": event.cooldown,
				"last_completed_round": event_last_completed.get(event_id, -1),
				"is_at_max_occurrences": is_at_max,
				"is_in_cooldown": is_in_cooldown
			}
	
	return stats 

# 测试冷却期逻辑修复（调试用）
func test_cooldown_logic_fix():
	print("=== 冷却期逻辑修复测试 ===")
	print("当前回合: ", current_round)
	
	var test_results = {
		"events_with_cooldown": 0,
		"events_in_cooldown": 0,
		"events_ready_for_retrigger": 0,
		"events_at_max_occurrences": 0
	}
	
	for event_id in event_trigger_counts.keys():
		var event = get_event_by_id(event_id)
		if not event:
			continue
			
		if event.cooldown > 0:
			test_results.events_with_cooldown += 1
			
			if event_last_completed.has(event_id):
				var last_settled_round = event_last_completed[event_id]
				var rounds_passed = current_round - last_settled_round
				var is_in_cooldown = rounds_passed < event.cooldown
				
				print("事件: ", event.event_name)
				print("  - 触发次数: ", event_trigger_counts[event_id], "/", event.max_occurrences)
				print("  - 最后检定完成回合: ", last_settled_round)
				print("  - 已过回合数: ", rounds_passed, "/", event.cooldown)
				print("  - 冷却状态: ", "冷却中" if is_in_cooldown else "可触发")
				
				if is_in_cooldown:
					test_results.events_in_cooldown += 1
				else:
					# 检查是否可以重新触发
					var can_retrigger = true
					if event.max_occurrences > 0 and event_trigger_counts[event_id] >= event.max_occurrences:
						can_retrigger = false
						test_results.events_at_max_occurrences += 1
					
					if can_retrigger:
						test_results.events_ready_for_retrigger += 1
						print("  - 可重新触发: 是")
					else:
						print("  - 可重新触发: 否（已达最大次数）")
				print("")
	
	print("测试结果汇总:")
	print("  - 有冷却时间的事件: ", test_results.events_with_cooldown)
	print("  - 正在冷却的事件: ", test_results.events_in_cooldown)
	print("  - 冷却结束可重触发的事件: ", test_results.events_ready_for_retrigger)
	print("  - 达到最大次数的事件: ", test_results.events_at_max_occurrences)
	print("=============================")
	
	return test_results
