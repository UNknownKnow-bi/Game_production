extends Control

# EventCheckSettlement - 事件检定结算UI界面
# 显示检定过程的动画化界面，包括1/0结果展示和最终结算

signal settlement_completed(results: Array)

# UI组件引用 - 使用固定节点（左右分栏布局）
@onready var background: ColorRect = $Background
@onready var settlement_panel: Panel = $SettlementPanel
@onready var left_panel: Control = $SettlementPanel/HSplitContainer/LeftPanel
@onready var right_panel: Control = $SettlementPanel/HSplitContainer/RightPanel
@onready var event_title_label: Label = $SettlementPanel/HSplitContainer/LeftPanel/EventTitleLabel
@onready var content_text_label: RichTextLabel = $SettlementPanel/HSplitContainer/LeftPanel/ContentTextLabel
@onready var continue_button: Button = $SettlementPanel/HSplitContainer/LeftPanel/ContinueButton
@onready var check_results_title: Label = $SettlementPanel/HSplitContainer/RightPanel/RightContainer/CheckResultsTitle
@onready var check_grid_container: GridContainer = $SettlementPanel/HSplitContainer/RightPanel/RightContainer/CheckGridContainer

# 检定数据
var current_events: Array = []
var current_event_index: int = 0
var current_check_result: EventManager.EventCheckResult
var animation_speed: float = 0.5

# 动画状态
var is_animating: bool = false
var check_results_displayed: int = 0

# 文本滚动控制变量
var scroll_speed: float = 50.0  # 每秒滚动像素数
var text_display_delay: float = 0.5  # 文本显示延迟
var scroll_pause_duration: float = 1.0  # 滚动暂停时间
var current_scroll_tween: Tween
var full_text_content: String = ""
var is_text_scrolling: bool = false

# 打字机效果控制变量
var typewriter_speed: float = 30.0  # 每秒显示字符数
var current_typewriter_tween: Tween
var is_typewriter_active: bool = false
var target_text_length: int = 0

# 检定阶段枚举
enum CheckPhase {
	SETUP,          # 设置阶段 - 显示预检文本
	CHECKING,       # 检定阶段 - 显示检定动画
	RESULT_DISPLAY, # 结果阶段 - 显示结果文本
	WAITING_INPUT   # 等待输入 - 显示继续按钮
}

var current_phase: CheckPhase = CheckPhase.SETUP

func _ready():
	print("EventCheckSettlement: 初始化检定结算界面")
	setup_signals()
	
	# 确保节点能够接收输入事件
	set_process_input(true)
	
	hide()

# 设置信号连接
func setup_signals():
	if continue_button:
		continue_button.pressed.connect(_on_continue_button_pressed)

# 开始事件检定结算流程
func start_settlement(events_to_check: Array):
	print("EventCheckSettlement: 开始检定结算流程，事件数量: ", events_to_check.size())
	
	current_events = events_to_check
	current_event_index = 0
	
	if current_events.is_empty():
		print("EventCheckSettlement: 没有事件需要检定")
		_finish_settlement()
		return
	
	show()
	_process_next_event()

# 处理下一个事件
func _process_next_event():
	if current_event_index >= current_events.size():
		_finish_settlement()
		return
	
	var event = current_events[current_event_index]
	print("EventCheckSettlement: 处理事件 ", event.event_name)
	
	# 重置阶段状态
	current_phase = CheckPhase.SETUP
	
	# 执行检定
	if EventManager:
		current_check_result = EventManager.perform_event_check(event)
		_start_check_sequence(event, current_check_result)
	else:
		print("EventCheckSettlement: 错误 - EventManager未找到")
		_finish_settlement()

# 开始检定序列
func _start_check_sequence(event: GameEvent, check_result: EventManager.EventCheckResult):
	print("EventCheckSettlement: 开始检定序列 - ", event.event_name)
	
	# 阶段1：设置预检文本显示
	_setup_pre_check_display(event, check_result)
	
	# 延迟开始检定动画
	await get_tree().create_timer(1.0).timeout
	_start_check_animation(check_result)

# 设置预检显示（阶段1）
func _setup_pre_check_display(event: GameEvent, check_result: EventManager.EventCheckResult):
	current_phase = CheckPhase.SETUP
	
	# 设置事件标题 - 去掉前缀
	event_title_label.text = event.event_name
	
	# 初始化连续文本显示
	_start_continuous_text_display(event, check_result)
	
	# 隐藏右侧检定结果区域
	right_panel.modulate.a = 0.3
	check_results_title.text = "准备检定中..."
	
	# 清空检定网格
	_clear_check_grid()
	
	# 隐藏继续按钮
	continue_button.visible = false
	
	print("EventCheckSettlement: 预检显示设置完成")

# 开始连续文本显示
func _start_continuous_text_display(event: GameEvent, check_result: EventManager.EventCheckResult):
	# 重置文本内容
	full_text_content = ""
	content_text_label.text = ""
	content_text_label.visible_characters = 0
	is_text_scrolling = true
	
	# 第一阶段：显示预检文本
	var pre_text = event.get_pre_check_text()
	if pre_text.is_empty():
		pre_text = "正在进行事件检定..."
	
	# 设置完整文本并直接显示（不使用打字机效果）
	full_text_content = pre_text
	content_text_label.text = full_text_content
	
	# 预检文本不使用打字机效果，直接完整显示
	_start_typewriter_effect(full_text_content.length(), false)

# 自动滚动到底部
func _auto_scroll_to_bottom():
	# 如果打字机正在运行，不执行滚动（打字机完成后会自动调用）
	if is_typewriter_active:
		return
	
	# 等待一帧确保内容已更新
	await get_tree().process_frame
	
	if not content_text_label:
		print("Warning: ContentTextLabel未找到")
		return
	
	# 确保滚动功能可用
	if not content_text_label.scroll_active:
		content_text_label.scroll_active = true
		print("Debug: 启用ContentTextLabel滚动功能")
	
	var scrollbar = content_text_label.get_v_scroll_bar()
	if not scrollbar:
		print("Warning: 无法获取滚动条")
		return
	
	var max_scroll = scrollbar.max_value
	if max_scroll <= 0:
		print("Debug: 内容无需滚动，max_scroll:", max_scroll)
		return
	
	print("Debug: 开始滚动动画，从", scrollbar.value, "到", max_scroll)
	
	# 如果当前有滚动动画，先停止
	if current_scroll_tween:
		current_scroll_tween.kill()
	
	# 创建新的滚动动画
	current_scroll_tween = create_tween()
	current_scroll_tween.tween_method(_set_scroll_position, scrollbar.value, max_scroll, max_scroll / scroll_speed)

# 设置滚动位置
func _set_scroll_position(position: float):
	if content_text_label:
		var scrollbar = content_text_label.get_v_scroll_bar()
		if scrollbar:
			scrollbar.value = int(position)
		else:
			print("Warning: 设置滚动位置时无法获取滚动条")

# 启动打字机效果
func _start_typewriter_effect(target_length: int, enable_typewriter: bool = true):
	if not content_text_label:
		print("Warning: ContentTextLabel未找到，无法启动打字机效果")
		return
	
	# 停止当前的打字机动画
	if current_typewriter_tween:
		current_typewriter_tween.kill()
		current_typewriter_tween = null
	
	# 如果不启用打字机效果，直接显示完整文本
	if not enable_typewriter:
		content_text_label.visible_characters = target_length
		is_typewriter_active = false
		target_text_length = target_length
		_auto_scroll_to_bottom()
		return
	
	# 设置打字机状态
	is_typewriter_active = true
	target_text_length = target_length
	
	# 获取当前显示的字符数
	var current_chars = content_text_label.visible_characters
	if current_chars < 0:
		current_chars = 0
	
	# 如果目标长度小于等于当前长度，直接完成
	if target_length <= current_chars:
		content_text_label.visible_characters = target_length
		_on_typewriter_completed()
		return
	
	# 计算动画时间
	var char_diff = target_length - current_chars
	var animation_duration = float(char_diff) / typewriter_speed
	
	print("Debug: 启动打字机效果，从", current_chars, "到", target_length, "，耗时", animation_duration, "秒（点击或按空格跳过）")
	
	# 创建打字机动画
	current_typewriter_tween = create_tween()
	current_typewriter_tween.tween_method(_update_visible_characters, current_chars, target_length, animation_duration)
	current_typewriter_tween.tween_callback(_on_typewriter_completed)

# 更新显示的字符数量
func _update_visible_characters(char_count: int):
	if content_text_label:
		content_text_label.visible_characters = char_count

# 打字机效果完成回调
func _on_typewriter_completed():
	print("Debug: 打字机效果完成")
	is_typewriter_active = false
	
	# 确保显示完整目标文本
	if content_text_label:
		content_text_label.visible_characters = target_text_length
	
	# 打字机完成后执行滚动
	_auto_scroll_to_bottom()

# 开始检定动画（阶段2）
func _start_check_animation(check_result: EventManager.EventCheckResult):
	current_phase = CheckPhase.CHECKING
	
	# 显示右侧检定结果区域
	var tween = create_tween()
	tween.tween_property(right_panel, "modulate:a", 1.0, 0.5)
	
	check_results_title.text = "检定结果"
	
	print("EventCheckSettlement: 开始检定动画")
	_animate_check_results(check_result)

# 清空检定网格
func _clear_check_grid():
	for child in check_grid_container.get_children():
		child.queue_free()

# 动画显示检定结果
func _animate_check_results(check_result: EventManager.EventCheckResult):
	is_animating = true
	check_results_displayed = 0
	
	# 创建检定结果显示项
	for i in range(check_result.check_attempts):
		var result_item = _create_check_result_item(i, check_result.check_results[i] if i < check_result.check_results.size() else 0)
		result_item.modulate.a = 0.0  # 初始透明
		check_grid_container.add_child(result_item)
	
	# 开始逐个显示动画
	_animate_next_result()

# 创建检定结果显示项
func _create_check_result_item(index: int, result: int) -> Control:
	var item_container = PanelContainer.new()
	item_container.custom_minimum_size = Vector2(60, 60)
	
	var result_label = Label.new()
	result_label.text = str(result)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 20)
	
	# 根据结果设置颜色
	if result == 1:
		result_label.add_theme_color_override("font_color", Color.GREEN)
		item_container.add_theme_color_override("bg_color", Color(0, 0.5, 0, 0.3))
	else:
		result_label.add_theme_color_override("font_color", Color.RED)
		item_container.add_theme_color_override("bg_color", Color(0.5, 0, 0, 0.3))
	
	item_container.add_child(result_label)
	return item_container

# 动画显示下一个结果
func _animate_next_result():
	if check_results_displayed >= check_grid_container.get_child_count():
		# 所有结果都已显示，进入结果显示阶段
		_show_final_result()
		return
	
	var result_item = check_grid_container.get_child(check_results_displayed)
	
	# 淡入动画
	var tween = create_tween()
	tween.tween_property(result_item, "modulate:a", 1.0, animation_speed)
	tween.tween_callback(_on_result_animation_completed)
	
	check_results_displayed += 1

# 结果动画完成回调
func _on_result_animation_completed():
	# 等待一小段时间后显示下一个结果
	await get_tree().create_timer(0.1).timeout
	_animate_next_result()

# 显示最终结果（阶段3）
func _show_final_result():
	print("EventCheckSettlement: 显示最终结果")
	
	current_phase = CheckPhase.RESULT_DISPLAY
	is_animating = false
	
	# 确保检定动画完全结束后再显示检定结果文本
	print("Debug: 检定动画完成，开始显示检定结果文本")
	_append_check_result_text()
	
	# 等待打字机效果完成后再追加成功/失败文本
	while is_typewriter_active:
		await get_tree().process_frame
	
	# 延迟后追加成功/失败文本
	await get_tree().create_timer(scroll_pause_duration).timeout
	_append_final_result_text()
	
	# 等待打字机效果完成后进入等待输入阶段
	while is_typewriter_active:
		await get_tree().process_frame
	
	await get_tree().create_timer(scroll_pause_duration).timeout
	_enter_waiting_input_phase()

# 追加检定结果文本
func _append_check_result_text():
	var result_text = "\n\n"
	
	if current_check_result.is_successful:
		result_text += "检定成功！"
	else:
		result_text += "检定失败"
	
	# 追加到全文内容
	full_text_content += result_text
	content_text_label.text = full_text_content
	
	# 启动打字机效果显示新追加的内容
	_start_typewriter_effect(full_text_content.length())

# 追加最终结果文本（成功/失败文本）
func _append_final_result_text():
	var final_text = "\n\n"
	
	# 获取当前事件
	var current_event = current_events[current_event_index]
	
	if current_check_result.is_successful:
		var success_text = current_event.get_success_text()
		if not success_text.is_empty():
			final_text += success_text
	else:
		var failure_text = current_event.get_failure_text()
		if not failure_text.is_empty():
			final_text += failure_text
	
	# 追加到全文内容
	full_text_content += final_text
	content_text_label.text = full_text_content
	
	# 启动打字机效果显示新追加的内容
	_start_typewriter_effect(full_text_content.length())

# 进入等待输入阶段（阶段4）
func _enter_waiting_input_phase():
	current_phase = CheckPhase.WAITING_INPUT
	
	# 文本显示完成，停止滚动状态
	is_text_scrolling = false
	
	# 显示继续按钮
	continue_button.visible = true
	
	# 执行事件结算
	if EventManager:
		EventManager.execute_event_settlement(current_check_result)
	
	print("EventCheckSettlement: 等待用户输入")

# 继续按钮点击处理
func _on_continue_button_pressed():
	print("EventCheckSettlement: 继续下一个事件")
	
	current_event_index += 1
	_process_next_event()

# 完成结算流程
func _finish_settlement():
	print("EventCheckSettlement: 完成所有事件检定结算")
	
	# 收集所有结果
	var all_results = []
	for i in range(current_event_index):
		if i < current_events.size():
			all_results.append({
				"event": current_events[i],
				"result": current_check_result if i == current_event_index - 1 else null
			})
	
	# 发射完成信号
	settlement_completed.emit(all_results)
	
	# 隐藏界面
	hide()

# 强制关闭界面
func force_close():
	print("EventCheckSettlement: 强制关闭界面")
	
	# 停止滚动动画
	if current_scroll_tween:
		current_scroll_tween.kill()
		current_scroll_tween = null
	
	# 停止打字机动画
	if current_typewriter_tween:
		current_typewriter_tween.kill()
		current_typewriter_tween = null
	
	# 重置滚动状态
	is_text_scrolling = false
	full_text_content = ""
	
	# 重置打字机状态
	is_typewriter_active = false
	target_text_length = 0
	
	hide()
	is_animating = false
	current_phase = CheckPhase.SETUP

# 检查是否正在动画中
func is_animation_playing() -> bool:
	return is_animating or is_text_scrolling or is_typewriter_active

# 输入处理 - 点击跳过打字机效果
func _input(event):
	# 只在打字机活跃时处理输入
	if not is_typewriter_active:
		return
	
	# 检测鼠标左键点击或空格键
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_skip_typewriter()
	elif event is InputEventKey:
		if event.keycode == KEY_SPACE and event.pressed:
			_skip_typewriter()

# 跳过打字机效果
func _skip_typewriter():
	if not is_typewriter_active:
		return
	
	print("Debug: 玩家跳过打字机效果")
	
	# 停止打字机动画
	if current_typewriter_tween:
		current_typewriter_tween.kill()
		current_typewriter_tween = null
	
	# 立即显示完整目标文本
	if content_text_label:
		content_text_label.visible_characters = target_text_length
	
	# 调用完成回调
	_on_typewriter_completed()
