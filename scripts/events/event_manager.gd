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

# 当前游戏回合
var current_round = 1

# 调试模式开关
var debug_mode: bool = false

# 详细调试模式开关
var detailed_debug_mode: bool = false

# 游戏状态信号
signal events_updated
signal event_completed(event_id: int)

# 数据文件路径
const EVENTS_DATA_PATH = "res://data/events/event_table.tsv"

# 事件文本数据存储
var event_text_data = {}  # 存储事件ID到文本数据的映射
const EVENT_TEXT_DATA_PATH = "res://data/events/event_text_table.tsv"

func _ready():
	# 连接TimeManager的round_changed信号
	if TimeManager:
		TimeManager.round_changed.connect(on_round_changed)
		print("EventManager: 已连接TimeManager.round_changed信号")
	else:
		print("EventManager: 警告 - TimeManager未找到，无法同步回合")
	
	# 启用详细调试模式进行问题诊断
	detailed_debug_mode = true
	# 关闭调试模式以启用正确的事件限制检查
	debug_mode = false
	print("EventManager: 启用详细调试模式，关闭debug_mode以正确筛选事件")
	
	# 诊断文件访问状态
	diagnose_file_access(EVENTS_DATA_PATH)
	
	load_events_from_tsv(EVENTS_DATA_PATH)

# TimeManager回合变更回调
func on_round_changed(new_round: int):
	current_round = new_round
	print("EventManager: 回合同步更新 - 当前回合: ", current_round)

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
	print("=== 文件访问诊断开始 ===")
	print("目标文件路径: ", file_path)
	
	# 检查文件是否存在
	if FileAccess.file_exists(file_path):
		print("✓ 文件存在")
	else:
		print("✗ 文件不存在")
		return
	
	# 尝试打开文件
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("✗ 无法打开文件，错误代码: ", FileAccess.get_open_error())
		return
	else:
		print("✓ 文件成功打开")
	
	# 检查文件大小
	var file_size = file.get_length()
	print("文件大小: ", file_size, " 字节")
	
	if file_size == 0:
		print("✗ 文件为空")
		file.close()
		return
	
	# 读取文件内容预览
	var content_preview = file.get_as_text()
	file.close()
	
	print("文件内容长度: ", content_preview.length(), " 字符")
	
	# 显示前200个字符作为预览
	var preview_length = min(200, content_preview.length())
	var preview = content_preview.substr(0, preview_length)
	print("文件内容预览 (前", preview_length, "字符):")
	print("\"", preview, "\"")
	
	# 检查行数
	var lines = content_preview.split("\n")
	print("文件总行数: ", lines.size())
	
	if lines.size() < 2:
		print("✗ 文件行数不足，至少需要2行（表头+数据）")
		return
	
	# 检查表头
	var header = lines[0].split("\t")
	print("表头列数: ", header.size())
	print("表头内容: ", header)
	
	if header.size() < 22:
		print("✗ 表头列数不足，需要至少22列")
		return
	else:
		print("✓ 表头列数符合要求")
	
	print("=== 文件访问诊断完成 ===")

# 验证TSV文件格式
func validate_tsv_file_format(file_path: String) -> bool:
	print("=== TSV文件格式验证开始 ===")
	
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
	var optional_columns = [
		"next_event_success", "next_event_delay_success",
		"next_event_failure", "next_event_delay_failure", 
		"required_for_completion", "icon_path", "background_path", "audio_path"
	]

	print("检查必需列（前14列）...")
	for i in range(required_columns.size()):
		if i >= header.size():
			print("✗ 缺少必需列: ", required_columns[i])
			return false
		elif header[i] != required_columns[i]:
			print("✗ 必需列名不匹配: 期望 '", required_columns[i], "', 实际 '", header[i], "'")
			return false
		else:
			print("✓ 必需列 ", i+1, ": ", required_columns[i])

	print("检查可选列（第15-22列）...")
	var optional_start_index = required_columns.size()
	for i in range(optional_columns.size()):
		var header_index = optional_start_index + i
		if header_index < header.size():
			if header[header_index] == optional_columns[i]:
				print("✓ 可选列 ", header_index+1, ": ", optional_columns[i])
			else:
				print("⚠ 可选列名不匹配: 期望 '", optional_columns[i], "', 实际 '", header[header_index], "'")
		else:
			print("⚠ 缺少可选列: ", optional_columns[i], " (将使用默认值)")

	print("✓ TSV文件格式验证通过 (必需列完整)")
	print("=== TSV文件格式验证完成 ===")
	return true

# 从TSV文件加载事件
func load_events_from_tsv(file_path: String, force_reload: bool = false):
	print("=== EventManager数据加载开始 ===")
	print("文件路径: ", file_path)
	print("强制重载: ", force_reload)
	print("详细调试模式: ", detailed_debug_mode)
	
	# 检查是否已有数据且不强制重载
	if not force_reload and has_loaded_data():
		print("EventManager: 数据已加载，跳过重复加载。当前事件总数: ", get_total_events_count())
		return
	
	# 如果强制重载，清空现有数据
	if force_reload:
		print("EventManager: 强制重载数据，清空现有事件")
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
	
	print("✓ 文件成功打开")
		
	var content = file.get_as_text()
	file.close()
	
	if content.is_empty():
		printerr("✗ 文件内容为空")
		return
	
	print("✓ 文件内容读取成功，长度: ", content.length(), " 字符")
	
	var lines = content.split("\n")
	# 使用split的第二个参数false来保留尾部空字段
	var header = lines[0].split("\t", false)
	
	print("EventManager: 开始解析事件数据")
	print("文件总行数: ", lines.size())
	print("事件表头字段数: ", header.size())
	
	if detailed_debug_mode:
		print("表头详细内容: ", header)
	
	var loaded_count = 0
	var failed_count = 0
	var skipped_count = 0
	
	# 从第二行开始解析数据
	for i in range(1, lines.size()):
		var line = lines[i].strip_edges()
		if line.is_empty():
			skipped_count += 1
			if detailed_debug_mode:
				print("跳过空行: ", i+1)
			continue
		
		if detailed_debug_mode:
			print("=== 处理第", i+1, "行 ===")
			print("原始行内容: \"", line, "\"")
		
		# 使用split的第二个参数false来保留尾部空字段
		var columns = line.split("\t", false)
		# 确保列数补全到22列，支持14-22列的数据
		columns = ensure_column_count(columns)
		if columns.size() < 14:  # 只检查必需字段（0-13）
			print("✗ 第", i+1, "行数据必需列数不足: ", columns.size(), "/14 (最少需要14列)")
			if detailed_debug_mode:
				print("列内容: ", columns)
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
	
	print("=== EventManager数据加载完成 ===")
	print("成功加载: ", loaded_count, " 个事件")
	print("加载失败: ", failed_count, " 个事件")
	print("跳过空行: ", skipped_count, " 行")
	print("EventManager: 各类别事件数量:")
	for category in events:
		print("  ", category, ": ", events[category].size(), " 个事件")

	# 数据完整性报告
	print("\n=== 数据完整性报告 ===")
	print("表头字段数: ", header.size(), "/22")
	if header.size() < 22:
		print("⚠ 缺失可选字段: ", 22 - header.size(), " 个")
		var missing_fields = []
		for i in range(header.size(), 22):
			var field_names = [
				"event_id", "event_type", "event_name", "event_group_name", 
				"character_name", "valid_rounds", "duration_rounds", 
				"prerequisite_conditions", "max_occurrences", "cooldown",
				"global_check", "attribute_aggregation", "success_results",
				"failure_results", "next_event_success", "next_event_delay_success",
				"next_event_failure", "next_event_delay_failure", 
				"required_for_completion", "icon_path", "background_path", "audio_path"
			]
			if i < field_names.size():
				missing_fields.append(field_names[i])
		print("缺失字段: ", missing_fields)
	else:
		print("✓ 所有字段完整")
	print("=== 数据完整性报告结束 ===")

	# 如果没有成功加载任何事件，这是一个严重问题
	if loaded_count == 0:
		printerr("✗ 严重错误: 没有成功加载任何事件！")
		printerr("请检查数据文件格式和内容")
	
	# 加载事件文本数据
	load_event_text_data()

# 确保列数达到22列，不足时补充空字符串
func ensure_column_count(columns: Array) -> Array:
	var result = columns.duplicate()
	while result.size() < 22:
		result.append("")
	
	if detailed_debug_mode and result.size() != columns.size():
		print("列数补全: ", columns.size(), " -> ", result.size(), " 列")
	
	return result

# 安全获取列值，支持默认值
func get_column_safe(columns: Array, index: int, default_value: String = "") -> String:
	if index >= 0 and index < columns.size():
		return columns[index]
	else:
		if detailed_debug_mode:
			print("使用默认值: 列", index, " = \"", default_value, "\"")
		return default_value

# 安全创建GameEvent对象
func create_event_with_error_handling(columns: Array, line_number: int) -> GameEvent:
	if detailed_debug_mode:
		print("开始创建事件对象，行号: ", line_number)
	
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
	
	if detailed_debug_mode:
		print("✓ 事件对象创建成功: ", event.event_name)
	
	# 验证和修复数据完整性
	validate_and_fix_event_data(event)
	
	return event

# 验证和修复事件数据完整性
func validate_and_fix_event_data(event: GameEvent):
	var fixed_issues = []
	
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
	if detailed_debug_mode:
		print("设置属性: ", property_name, " = \"", value, "\" (类型: ", type, ")")
	
	match type:
		"int":
			if value.is_empty():
				# 对duration_rounds字段使用默认值1，其他字段使用0
				var default_value = 1 if property_name == "duration_rounds" else 0
				event.set(property_name, default_value)
				if detailed_debug_mode:
					print("✓ 空值处理: ", property_name, " -> ", default_value)
			else:
				var int_value = value.to_int()
				# 验证duration_rounds的合理性
				if property_name == "duration_rounds":
					if int_value <= 0 or int_value > 999:
						print("⚠ 异常duration_rounds值: ", int_value, " 重置为1")
						int_value = 1
				event.set(property_name, int_value)
				if detailed_debug_mode:
					print("✓ 整数转换: ", value, " -> ", int_value)
		"string":
			event.set(property_name, value)
			if detailed_debug_mode:
				print("✓ 字符串设置: \"", value, "\"")
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
		return result
	else:
		print("JSON解析结果不是Dictionary类型，返回空字典。解析结果类型: ", typeof(result), "，值: ", result)
		return {}
	
	if detailed_debug_mode:
		print("解析JSON字段: ", json_string, " -> ", result)

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

# 获取特定类别的可用事件
func get_available_events(category: String) -> Array:
	var available = []
	if events.has(category):
		for event_id in events[category]:
			var event = events[category][event_id]
			if check_event_availability(event):
				available.append(event)
	
	if debug_mode:
		print("调试模式: ", category, " 类别找到 ", available.size(), " 个可用事件")
	
	return available

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

# 获取周末事件（基于day_type筛选）
func get_weekend_events() -> Array[GameEvent]:
	print("=== EventManager.get_weekend_events 开始 ===")
	
	var weekend_events: Array[GameEvent] = []
	
	# 从所有类别中筛选周末事件
	for category in events:
		for event_id in events[category]:
			var event = events[category][event_id]
			if _is_weekend_event(event):
				weekend_events.append(event)
				print("找到周末事件: ", event.event_name, " (", event.event_type, ") - ID:", event.event_id)
				print("  day_type: ", _get_event_day_type(event))
				print("  character_name: '", event.character_name, "' (长度:", event.character_name.length(), ")")
	
	print("总共筛选到", weekend_events.size(), "个周末事件")
	print("=== EventManager.get_weekend_events 完成 ===")
	
	return weekend_events

# 检查事件是否为周末事件
func _is_weekend_event(event: GameEvent) -> bool:
	if event.prerequisite_conditions.has("day_type"):
		return event.prerequisite_conditions["day_type"] == "weekend"
	return false

# 获取事件的day_type字段
func _get_event_day_type(event: GameEvent) -> String:
	if event.prerequisite_conditions.has("day_type"):
		return event.prerequisite_conditions["day_type"]
	return "未设置"

# 检查事件是否可用
func check_event_availability(event: GameEvent) -> bool:
	# 调试模式下跳过所有限制
	if debug_mode:
		print("调试模式: 跳过事件限制检查 - ", event.event_name)
		return true
	
	# 检查回合有效性
	if not event.is_valid_in_round(current_round, self):
		print("事件过滤: ", event.event_name, " - 回合无效 (当前:", current_round, ", 有效:", event.valid_rounds, ")")
		return false
	
	# 检查前置条件
	if not check_prerequisites(event):
		print("事件过滤: ", event.event_name, " - 前置条件不满足")
		return false
	
	print("事件通过: ", event.event_name, " - 所有检查通过")
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
				print("前置条件失败: ", event.event_name, " - 回合范围 [", range_arr[0], "-", range_arr[1], "], 当前:", current_round)
				return false
	
	# 检查日期类型
	if prereq.has("day_type"):
		var required_day_type = prereq["day_type"]
		var current_scene_type = TimeManager.get_current_scene_type()
		
		if required_day_type != current_scene_type:
			print("前置条件失败: ", event.event_name, " - 需要场景类型: ", required_day_type, ", 当前场景类型: ", current_scene_type)
			return false
		
		print("前置条件通过: ", event.event_name, " - 场景类型匹配: ", required_day_type)
	
	# 检查必需属性
	if prereq.has("required_attributes"):
		var required_attrs = prereq["required_attributes"]
		if not required_attrs.is_empty():
			print("前置条件检查: ", event.event_name, " - 需要属性: ", required_attrs, " (当前未实现属性检查)")
			# 暂时跳过属性检查
			# return false
	
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

# 设置调试模式
func set_debug_mode(enabled: bool):
	debug_mode = enabled
	print("EventManager调试模式: ", "开启" if enabled else "关闭")
	
	# 重新更新可用事件
	update_available_events()

# 标记事件为已完成
func mark_event_completed(event_id: int):
	var completion_data = {
		"completed_round": current_round,
		"completion_time": Time.get_unix_time_from_system()
	}
	completed_events[event_id] = completion_data
	
	print("EventManager: 标记事件完成 - ID:", event_id, " 完成回合:", current_round)
	print("EventManager: 发射event_completed信号...")
	event_completed.emit(event_id)
	print("EventManager: event_completed信号已发射")
	
	# 延迟UI刷新到下一帧，确保所有信号处理完成
	print("EventManager: 延迟UI刷新到下一帧...")
	call_deferred("_deferred_ui_update")

# 延迟的UI更新方法
func _deferred_ui_update():
	print("EventManager: 执行延迟的UI更新...")
	update_available_events()
	print("EventManager: UI更新完成")

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
		"events_by_category": {}
	}
	
	for category in events:
		info.events_by_category[category] = events[category].size()
	
	return info

# 独立测试数据加载
func test_data_loading() -> Dictionary:
	print("=== 独立数据加载测试开始 ===")
	
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
			print("文件总行数: ", test_result.total_lines)
			
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
					print("✓ 第", i+1, "行数据格式正确")
				else:
					test_result.errors.append("第" + str(i+1) + "行列数不足: " + str(columns.size()) + "/22")
					print("✗ 第", i+1, "行数据格式错误")
			
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
							print("测试事件: ", test_event.event_name, " (ID: ", test_event.event_id, ")")
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
	
	print("=== 独立数据加载测试完成 ===")
	print("测试结果: ", test_result)
	return test_result 

# 加载事件文本数据
func load_event_text_data():
	print("=== 事件文本数据加载开始 ===")
	
	if not FileAccess.file_exists(EVENT_TEXT_DATA_PATH):
		print("⚠ 事件文本数据文件不存在: ", EVENT_TEXT_DATA_PATH)
		return
	
	var file = FileAccess.open(EVENT_TEXT_DATA_PATH, FileAccess.READ)
	if not file:
		printerr("✗ 无法打开事件文本数据文件: ", EVENT_TEXT_DATA_PATH)
		return
	
	var content = file.get_as_text()
	file.close()
	
	if content.is_empty():
		print("⚠ 事件文本数据文件为空")
		return
	
	var lines = content.split("\n")
	if lines.size() < 2:
		print("⚠ 事件文本数据文件格式不正确，至少需要表头和一行数据")
		return
	
	# 解析表头
	var header = lines[0].split("\t")
	print("文本数据表头: ", header)
	
	# 验证表头格式
	var expected_headers = ["event_id", "pre_check_text", "card_display_text", "remarks"]
	for i in range(expected_headers.size()):
		if i >= header.size() or header[i] != expected_headers[i]:
			printerr("✗ 文本数据表头格式错误，期望: ", expected_headers)
			return
	
	# 解析数据行
	var loaded_count = 0
	for i in range(1, lines.size()):
		var line = lines[i].strip_edges()
		if line.is_empty():
			continue
		
		var columns = line.split("\t")
		if columns.size() < 4:
			print("⚠ 第", i+1, "行数据不完整，跳过")
			continue
		
		var event_id = columns[0].to_int()
		var pre_check_text = columns[1]
		var card_display_text = columns[2]
		var remarks = columns[3]
		
		# 存储文本数据
		event_text_data[event_id] = {
			"pre_check_text": pre_check_text,
			"card_display_text": card_display_text,
			"remarks": remarks
		}
		
		loaded_count += 1
		if detailed_debug_mode:
			print("✓ 加载事件文本 - ID:", event_id, " 预检文本长度:", pre_check_text.length())
	
	print("✓ 事件文本数据加载完成，共加载 ", loaded_count, " 条记录")
	
	# 将文本数据应用到已加载的事件对象
	apply_text_data_to_events()

# 将文本数据应用到事件对象
func apply_text_data_to_events():
	print("=== 应用文本数据到事件对象 ===")
	
	var applied_count = 0
	for category in events:
		for event_id in events[category]:
			var event = events[category][event_id]
			if event_text_data.has(event.event_id):
				var text_data = event_text_data[event.event_id]
				event.set_text_data(text_data.pre_check_text, text_data.card_display_text)
				applied_count += 1
				if detailed_debug_mode:
					print("✓ 应用文本数据到事件 ID:", event.event_id)
	
	print("✓ 文本数据应用完成，共应用 ", applied_count, " 个事件")

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
