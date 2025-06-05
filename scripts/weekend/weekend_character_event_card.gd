extends PanelContainer
class_name WeekendCharacterEventCard

# 内容属性
@export_group("内容")
@export var event_title: String = "事件标题" : set = set_event_title
@export var character_name: String = "相关人物" : set = set_character_name
@export var event_status: String = "new" : set = set_event_status  # "new" 或 "dealing"
@export var character_texture: Texture2D : set = set_character_texture
@export var game_event: GameEvent

# 图像裁剪属性
@export_group("图像裁剪")
@export var region_enabled: bool = false : set = set_region_enabled
@export_range(0.0, 1.0, 0.01) var region_y_position: float = 0.0 : set = set_region_y_position
@export_range(0.0, 1.0, 0.01) var region_height: float = 0.45 : set = set_region_height

# 样式属性
@export_group("样式")
@export var border_color: Color = Color(0.7, 0.7, 0.7, 1.0) : set = set_border_color
@export var corner_radius: int = 8 : set = set_corner_radius
@export var border_width: int = 2 : set = set_border_width
@export var background_color: Color = Color(1, 1, 1, 0) : set = set_background_color
@export var title_font_size: int = 28 : set = set_title_font_size
@export var name_font_size: int = 23 : set = set_name_font_size

# 背景纹理属性
@export_group("背景纹理")
@export var character_undo_texture: Texture2D
@export var character_done_texture: Texture2D

# 用于存储原始纹理的变量
var _original_texture: Texture2D = null

# 节点引用
@onready var character_image = $CardContent/EventCharacterPortrait
@onready var title_label = $CardContent/EventTitle
@onready var name_label = $CardContent/EventPerson
@onready var round_info = $CardContent/RoundInfo
@onready var background_image = $CardContent/BackgroundImage

# 资源引用
var new_status_texture = preload("res://assets/workday_new/ui/events/new.png")
var dealing_status_texture = preload("res://assets/workday_new/ui/events/dealing.png")

# 背景纹理资源 - 复用随机事件纹理或使用专门纹理
var default_character_undo_texture = preload("res://assets/workday_new/ui/events/random_undo.png")
var default_character_done_texture = preload("res://assets/workday_new/ui/events/random_done.png")

# 完成状态
var is_completed: bool = false

# 信号
signal card_clicked

func _ready():
	# 确保卡片能接收点击事件
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 设置CardContent容器忽略鼠标事件，让事件传播到父容器
	if has_node("CardContent"):
		get_node("CardContent").mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 设置所有子节点忽略鼠标事件，让事件传播到父容器
	if title_label:
		title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if name_label:
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if round_info:
		round_info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if character_image:
		character_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 连接信号
	gui_input.connect(_on_gui_input)
	
	# 连接EventManager信号
	_connect_event_manager_signals()
	
	# 应用样式和内容
	_apply_style()
	_apply_content()
	
	# 初始化背景纹理
	if not character_undo_texture:
		character_undo_texture = default_character_undo_texture
	if not character_done_texture:
		character_done_texture = default_character_done_texture
	
	print("WeekendCharacterEventCard就绪: ", event_title)

# 内容属性更新
func set_event_title(text: String):
	event_title = text
	if is_instance_valid(title_label):
		title_label.text = text

func set_character_name(text: String):
	character_name = text
	if is_instance_valid(name_label):
		name_label.text = text

func set_event_status(status: String):
	print("WeekendCharacterEventCard: 设置事件状态 - 从 '", event_status, "' 到 '", status, "'")
	
	# 验证状态值
	if status != "new" and status != "dealing":
		print("⚠ WeekendCharacterEventCard: 无效状态值 '", status, "'，默认为'new'")
		status = "new"
	
	var old_status = event_status
	event_status = status
	
	# 更新完成状态
	is_completed = (status == "dealing")
	
	print("✓ WeekendCharacterEventCard: 事件状态更新完成: ", event_status)
	
	# 更新背景图片
	_update_background_texture()

# 角色纹理设置
func set_character_texture(texture: Texture2D):
	character_texture = texture
	_original_texture = texture
	
	if is_instance_valid(character_image) and texture:
		# 应用区域裁剪（如果启用）
		if region_enabled:
			_apply_region_cropping()
		else:
			character_image.texture = texture

# 图像裁剪设置
func set_region_enabled(enabled: bool):
	region_enabled = enabled
	if _original_texture:
		set_character_texture(_original_texture)

func set_region_y_position(position: float):
	region_y_position = position
	if region_enabled and _original_texture:
		_apply_region_cropping()

func set_region_height(height: float):
	region_height = height
	if region_enabled and _original_texture:
		_apply_region_cropping()

# 应用区域裁剪
func _apply_region_cropping():
	if not _original_texture or not is_instance_valid(character_image):
		return
	
	var original_height = _original_texture.get_height()
	var crop_start = int(original_height * region_y_position)
	var crop_height = int(original_height * region_height)
	
	# 创建AtlasTexture进行裁剪
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = _original_texture
	atlas_texture.region = Rect2(0, crop_start, _original_texture.get_width(), crop_height)
	
	character_image.texture = atlas_texture

# 样式设置
func set_border_color(color: Color):
	border_color = color
	_apply_style()

func set_corner_radius(radius: int):
	corner_radius = radius
	_apply_style()

func set_border_width(width: int):
	border_width = width
	_apply_style()

func set_background_color(color: Color):
	background_color = color
	_apply_style()

func set_title_font_size(size: int):
	title_font_size = size
	if is_instance_valid(title_label):
		title_label.add_theme_font_size_override("font_size", size)

func set_name_font_size(size: int):
	name_font_size = size
	if is_instance_valid(name_label):
		name_label.add_theme_font_size_override("font_size", size)

# 应用内容属性
func _apply_content():
	set_event_title(event_title)
	set_character_name(character_name)
	set_event_status(event_status)
	
	# 保存并应用纹理，处理区域裁剪
	if character_texture:
		_original_texture = character_texture
		set_character_texture(character_texture)
	
	# 应用字体大小
	set_title_font_size(title_font_size)
	set_name_font_size(name_font_size)
	
	# 更新回合信息（如果游戏事件已设置）
	if game_event:
		_update_round_info()

# 应用样式
func _apply_style():
	# 创建StyleBoxFlat
	var style = StyleBoxFlat.new()
	
	# 设置背景颜色
	style.bg_color = background_color
	
	# 其他样式设置
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	
	# 应用样式
	add_theme_stylebox_override("panel", style)

# 点击事件处理
func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("WeekendCharacterEventCard: 卡片被点击 - ", event_title)
			card_clicked.emit()

# 游戏事件管理方法
func set_game_event(event: GameEvent) -> void:
	game_event = event
	print("WeekendCharacterEventCard: 设置game_event - ", event.event_name if event else "null")
	
	# 连接EventManager信号
	_connect_event_manager_signals()
	
	# 检查并设置初始状态
	if event:
		var event_manager = get_node_or_null("/root/EventManager")
		if event_manager:
			var initial_completed = event_manager.is_event_completed(event.event_id)
			set_completion_status(initial_completed)
			print("WeekendCharacterEventCard: 初始化状态为: ", "dealing" if initial_completed else "new")
		else:
			set_completion_status(false)
			print("WeekendCharacterEventCard: EventManager未找到，默认设为new状态")
		
		# 更新回合信息
		_update_round_info()
	else:
		set_completion_status(false)

func get_game_event() -> GameEvent:
	return game_event

# 连接EventManager信号
func _connect_event_manager_signals():
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		print("⚠ WeekendCharacterEventCard: EventManager未找到，无法连接信号")
		return
	
	if not event_manager.event_completed.is_connected(_on_event_completed):
		event_manager.event_completed.connect(_on_event_completed)
		print("WeekendCharacterEventCard: 已连接EventManager的event_completed信号")

# 处理事件完成信号
func _on_event_completed(event_id: int):
	print("WeekendCharacterEventCard: 收到事件完成信号 - event_id:", event_id)
	
	if not game_event:
		print("WeekendCharacterEventCard: 无game_event，忽略信号")
		return
		
	if game_event.event_id == event_id:
		print("WeekendCharacterEventCard: 信号匹配当前事件，更新状态")
		set_completion_status(true)
		_update_round_info()
		print("WeekendCharacterEventCard: 事件完成处理完毕 - ", event_id)
	else:
		print("WeekendCharacterEventCard: 信号不匹配当前事件")

# 更新回合信息显示
func _update_round_info():
	if not game_event or not round_info:
		return
	
	var duration_text = str(game_event.duration_rounds)
	round_info.text = duration_text
	print("WeekendCharacterEventCard: 回合信息显示:", duration_text)

# 获取卡片类型
func get_card_type() -> String:
	return "weekend_character"

# 统一状态访问接口实现
func get_completion_status() -> bool:
	return is_completed

func set_completion_status(completed: bool):
	print("WeekendCharacterEventCard: 设置完成状态 - ", "完成" if completed else "未完成")
	
	is_completed = completed
	var new_status = "dealing" if completed else "new"
	
	# 只有状态确实发生变化时才更新
	if event_status != new_status:
		set_event_status(new_status)
	else:
		# 即使状态相同，也要确保背景纹理正确
		_update_background_texture()

# 获取已完成（兼容性方法）
func set_completed(completed: bool):
	set_completion_status(completed)

# 同步EventManager状态
func _sync_with_event_manager():
	print("WeekendCharacterEventCard: 同步EventManager状态...")
	
	var event_manager = get_node_or_null("/root/EventManager")
	if not event_manager:
		print("⚠ WeekendCharacterEventCard: EventManager未找到，无法同步状态")
		return
	
	if not game_event:
		print("⚠ WeekendCharacterEventCard: 无game_event，无法同步状态")
		return
	
	var manager_completed = event_manager.is_event_completed(game_event.event_id)
	print("  EventManager状态: ", "完成" if manager_completed else "未完成")
	print("  卡片当前状态: ", "完成" if is_completed else "未完成")
	
	if manager_completed != is_completed:
		print("  状态不一致，开始同步...")
		set_completion_status(manager_completed)
		print("✓ WeekendCharacterEventCard: 状态同步完成")
	else:
		print("✓ WeekendCharacterEventCard: 状态已一致，无需同步")
		# 确保纹理正确
		_update_background_texture()
	
	# 验证纹理状态
	_verify_texture_state()

# 验证纹理状态
func _verify_texture_state():
	if not is_instance_valid(background_image):
		return
	
	var actual_texture = background_image.texture
	var expected_texture = character_done_texture if is_completed else character_undo_texture
	if not expected_texture:
		expected_texture = default_character_done_texture if is_completed else default_character_undo_texture
	
	print("WeekendCharacterEventCard: 纹理验证 - 期望:", expected_texture, " 实际:", actual_texture)
	
	if actual_texture != expected_texture:
		print("⚠ WeekendCharacterEventCard: 纹理状态不匹配，重新设置")
		background_image.texture = expected_texture

# 更新背景纹理
func _update_background_texture():
	print("WeekendCharacterEventCard: 更新背景纹理...")
	
	if not is_instance_valid(background_image):
		print("⚠ WeekendCharacterEventCard: background_image无效，无法更新背景")
		return
	
	var old_texture = background_image.texture
	var new_texture: Texture2D = null
	
	if is_completed:
		new_texture = character_done_texture if character_done_texture else default_character_done_texture
		print("  设置为完成状态纹理: ", new_texture)
	else:
		new_texture = character_undo_texture if character_undo_texture else default_character_undo_texture
		print("  设置为未完成状态纹理: ", new_texture)
	
	background_image.texture = new_texture
	
	print("  背景纹理更新结果: ", old_texture, " -> ", new_texture)
	print("✓ WeekendCharacterEventCard: 背景纹理更新完成")

func get_status_description() -> String:
	var event_id = game_event.event_id if game_event else -1
	var event_name = game_event.event_name if game_event else "null"
	return "WeekendCharacterEventCard[" + str(event_id) + ":" + event_name + "] event_status: " + event_status + " (completed: " + str(get_completion_status()) + ")"

# 从GameEvent初始化卡片（包含角色图片加载）
func initialize_from_game_event(event: GameEvent):
	print("=== WeekendCharacterEventCard.initialize_from_game_event 开始 ===")
	print("事件: ", event.event_name if event else "null")
	
	if not event:
		print("✗ 事件为空，无法初始化")
		return
	
	# 设置基本信息
	set_game_event(event)
	set_event_title(event.event_name)
	set_character_name(event.character_name)
	
	# 加载角色图片
	if not event.character_name.is_empty() and event.character_name != "{}":
		print("开始加载角色图片: ", event.character_name)
		_load_character_image_for_card(event.character_name)
	else:
		print("无有效角色名称，跳过图片加载")
	
	print("=== WeekendCharacterEventCard.initialize_from_game_event 完成 ===")

# 为卡片加载角色图片的内部方法
func _load_character_image_for_card(character_name: String):
	print("=== WeekendCharacterEventCard._load_character_image_for_card 开始 ===")
	print("角色名称: ", character_name)
	
	var image_path = CharacterMapping.get_character_image_path(character_name)
	if image_path and image_path != "":
		print("找到角色图片路径: ", image_path)
		var texture = load(image_path)
		if texture:
			set_character_texture(texture)
			# 启用图像裁剪
			set_region_enabled(true)
			set_region_y_position(0.0)
			set_region_height(0.45)
			print("✓ 角色图片加载并设置成功")
		else:
			print("✗ 无法加载角色图片: ", image_path)
	else:
		print("✗ 未找到角色图片路径")
	
	print("=== WeekendCharacterEventCard._load_character_image_for_card 完成 ===") 