class_name DailyEventCard
extends PanelContainer

# 导出属性
@export var event_title: String = ""
@export var is_completed: bool = false
@export var title_font_size: int = 70

# 样式属性
var background_type: String = "default"
var style_applied: bool = false

# 节点引用
@onready var title_label: Label = $CardContent/EventTitle
@onready var background_image: TextureRect = $CardContent/BackgroundImage

# 资源引用
var daily_done_texture: Texture2D
var daily_undo_texture: Texture2D

# 游戏事件引用
var game_event: GameEvent

# 信号
signal card_clicked

func _ready():
	print("=== DailyEventCard._ready 开始 ===")
	print("卡片实例ID: ", get_instance_id())
	
	# 确保卡片能接收点击事件
	mouse_filter = Control.MOUSE_FILTER_STOP
	print("✓ 主容器鼠标过滤设置为STOP")
	
	# 设置CardContent容器忽略鼠标事件，让事件传播到父容器
	if has_node("CardContent"):
		get_node("CardContent").mouse_filter = Control.MOUSE_FILTER_IGNORE
		print("✓ CardContent鼠标过滤设置为IGNORE")
	
	# 获取节点引用
	print("正在获取节点引用...")
	background_image = get_node_or_null("CardContent/BackgroundImage")
	title_label = get_node_or_null("CardContent/EventTitle")
	
	# 验证节点引用
	print("节点引用验证:")
	print("  background_image: ", "✓" if background_image else "✗", " - ", background_image)
	print("  title_label: ", "✓" if title_label else "✗", " - ", title_label)
	
	# 设置鼠标过滤
	print("正在设置鼠标过滤...")
	if background_image:
		background_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		print("  background_image鼠标过滤设置为IGNORE")
	if title_label:
		title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		print("  title_label鼠标过滤设置为IGNORE")
	
	# 加载背景纹理资源
	print("正在加载纹理资源...")
	daily_done_texture = load("res://assets/workday_new/ui/events/daily_done_new.png")
	daily_undo_texture = load("res://assets/workday_new/ui/events/daily_undo_new.png")
	
	print("纹理资源加载状态:")
	print("  daily_done_texture: ", "✓" if daily_done_texture else "✗")
	print("  daily_undo_texture: ", "✓" if daily_undo_texture else "✗")
	
	# 应用初始样式
	print("正在应用初始样式...")
	_apply_style()
	
	# 连接点击信号
	print("正在连接gui_input信号...")
	var connection_result = gui_input.connect(_on_gui_input)
	if connection_result == OK:
		print("✓ gui_input信号连接成功")
	else:
		print("✗ gui_input信号连接失败，错误代码: ", connection_result)
	
	print("=== DailyEventCard._ready 完成 ===")

func _on_gui_input(event):
	print("=== DailyEventCard._on_gui_input 触发 ===")
	print("卡片实例ID: ", get_instance_id())
	print("事件类型: ", event.get_class())
	
	if event is InputEventMouseButton:
		print("鼠标按钮事件详情:")
		print("  按钮索引: ", event.button_index)
		print("  是否按下: ", event.pressed)
		print("  是否为左键: ", event.button_index == MOUSE_BUTTON_LEFT)
		print("  位置: ", event.position)
		
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("✓ 左键点击条件满足，准备发射card_clicked信号")
			print("当前事件标题: ", event_title)
			print("关联的GameEvent: ", game_event)
			card_clicked.emit()
			print("✓ card_clicked信号已发射")
		else:
			print("左键点击条件不满足，忽略事件")
	else:
		print("非鼠标按钮事件，忽略")
	
	print("=== DailyEventCard._on_gui_input 完成 ===")

# 设置事件标题
func set_event_title(title: String):
	event_title = title
	if title_label:
		title_label.text = title

# 设置完成状态
func set_completed(completed: bool):
	is_completed = completed
	_update_textures()

# 设置标题字体大小
func set_title_font_size(size: int):
	title_font_size = size
	if title_label:
		title_label.add_theme_font_size_override("font_size", size)

# 更新纹理（背景和状态图标）
func _update_textures():
	if is_completed:
		# 完成状态
		if background_image and daily_done_texture:
			background_image.texture = daily_done_texture
	else:
		# 未完成状态
		if background_image and daily_undo_texture:
			background_image.texture = daily_undo_texture

# 应用样式
func _apply_style():
	if not style_applied:
		style_applied = true
		
		# 应用标题样式
		if title_label:
			title_label.text = event_title
			title_label.add_theme_font_size_override("font_size", title_font_size)
		
		# 更新纹理
		_update_textures()

# 设置游戏事件
func set_game_event(new_game_event: GameEvent):
	print("=== DailyEventCard.set_game_event 调用 ===")
	print("卡片实例ID: ", get_instance_id())
	print("传入GameEvent: ", new_game_event)
	
	if new_game_event:
		print("GameEvent详情:")
		print("  事件ID: ", new_game_event.event_id)
		print("  事件名称: ", new_game_event.event_name)
		print("  事件类型: ", new_game_event.get_event_category())
	else:
		print("⚠️ 传入的GameEvent为null")
	
	game_event = new_game_event
	print("✓ GameEvent已设置")
	print("=== DailyEventCard.set_game_event 完成 ===")

# 获取游戏事件
func get_game_event() -> GameEvent:
	return game_event

# 更新卡片内容
func update_content():
	if game_event:
		set_event_title(game_event.event_name)
		# 根据游戏事件状态设置完成状态
		# 这里可以根据实际需求调整逻辑
		set_completed(false)
	
	_apply_style() 