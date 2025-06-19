extends CanvasLayer

# 故事文本数组
var story_text = [
	"五年职场跋涉 \n 你从小外包公司的程序员，爬到中型科技企业的开发主管 \n 如今终于踏入了WonderTech的大门。",
	"这里是行业的顶点，是无数技术人才梦寐以求的殿堂。",
	"试用期的最后一个月，一切都悬而未决。",
	"作为团队里唯一的女性研发，你感受到的压力是双重的。\n 技术上的每一个瑕疵都可能被放大，而你所有的成功却往往被轻描淡写。",
	"你开始思考 \n 是应该更加强硬地表达自己的观点 \n 还是继续保持低调但高效的工作方式？",
	"是坚持自己的工作理念 \n 还是适应这个竞争激烈的环境？\n 是建立更多的盟友关系 \n 还是专注于个人能力的突破？",
	"职场的游戏已经开始，而[color=red]规则[/color]远比你想象的要复杂。"
]

var current_text_index = 0
var current_tween = null
var can_advance = true

# 首次游玩检查常量
const INTRO_VIEWED_KEY = "intro_viewed"

# 音效资源路径
const CLICK_SOUND_PATH = "res://assets/CG/open/click.mp3"

# 节点引用
@onready var click_sound = $ClickSound
@onready var dialog_text = null  # 将在_ready中初始化
@onready var text_container = $TextContainer

func _ready():
	# 设置背景
	$Background.texture = load("res://assets/CG/open/black.png")
	$Background.expand_mode = 1  # EXPAND_IGNORE_SIZE
	
	# 配置文本容器的垂直居中
	configure_text_container()
	
	# 替换Label为RichTextLabel
	replace_label_with_richtext()
	
	# 加载点击音效
	var click_audio = load(CLICK_SOUND_PATH)
	if click_audio:
		click_sound.stream = click_audio
	
	# 应用字体到跳过按钮
	if has_node("SkipButton"):
		var skip_button = $SkipButton
		# 直接设置合适的字体大小
		skip_button.add_theme_font_size_override("font_size", 33) # 固定值，原来是FontManager.get_font_size("button") * 1.5
		# 添加padding使按钮看起来更大
		skip_button.add_theme_constant_override("h_separation", 10)
		skip_button.add_theme_constant_override("outline_size", 2)
		# 添加一些颜色让按钮更突出
		skip_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))  # 白色文字
		skip_button.add_theme_color_override("font_hover_color", Color(1, 0.9, 0.3, 1))  # 悬停时为黄色
		skip_button.pressed.connect(on_skip_button_pressed)
		
		# 添加悬停效果
		skip_button.mouse_entered.connect(func(): skip_button.modulate = Color(1.2, 1.2, 1.2, 1.0))
		skip_button.mouse_exited.connect(func(): skip_button.modulate = Color(1.0, 1.0, 1.0, 1.0))
	
	# 开始显示文本
	display_current_text()

# 配置TextContainer以支持垂直居中
func configure_text_container():
	# 确保文本容器使用中心对齐
	if text_container is CenterContainer:
		# CenterContainer已经支持居中对齐，无需额外配置
		pass
	else:
		# 如果不是CenterContainer，尝试设置垂直居中属性
		text_container.size_flags_vertical = Control.SIZE_FILL
		text_container.anchor_top = 0.5
		text_container.anchor_bottom = 0.5
		text_container.offset_top = -text_container.size.y / 2
		text_container.offset_bottom = text_container.size.y / 2
		
		# 输出调试信息
		print("配置文本容器：", text_container.get_class())

# 替换Label为RichTextLabel
func replace_label_with_richtext():
	var old_label = $TextContainer/DialogText
	
	# 保存原始设置
	var original_size = old_label.custom_minimum_size
	
	# 删除旧Label
	text_container.remove_child(old_label)
	old_label.queue_free()
	
	# 创建新的RichTextLabel
	var rich_label = RichTextLabel.new()
	rich_label.name = "DialogText"
	text_container.add_child(rich_label)
	
	# 设置RichTextLabel的属性
	rich_label.custom_minimum_size = original_size
	rich_label.bbcode_enabled = true  # 启用BBCode
	rich_label.fit_content = true
	rich_label.scroll_active = false
	rich_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# 使用固定字体大小设置
	var font_path = "res://assets/font/LEEEAFHEI-REGULAR.TTF"
	var font = load(font_path)
	if font:
		rich_label.add_theme_font_override("normal_font", font)
		rich_label.add_theme_font_override("bold_font", font)
		rich_label.add_theme_font_override("italics_font", font)
		rich_label.add_theme_font_override("bold_italics_font", font)
		
		# 设置固定字体大小
		var dialog_font_size = 40 # 原来是从FontManager获取
		rich_label.add_theme_font_size_override("normal_font_size", dialog_font_size)
		rich_label.add_theme_font_size_override("bold_font_size", dialog_font_size)
		rich_label.add_theme_font_size_override("italics_font_size", dialog_font_size)
		rich_label.add_theme_font_size_override("bold_italics_font_size", dialog_font_size)
		
		# 设置行间距
		var line_spacing = int(dialog_font_size * 0.3)
		rich_label.add_theme_constant_override("line_separation", line_spacing)
	else:
		# 如果无法加载字体，则使用默认设置
		rich_label.add_theme_font_size_override("normal_font_size", 28)
		rich_label.add_theme_constant_override("line_separation", 10)  # 增加行间距
	
	rich_label.add_theme_color_override("default_color", Color(1, 1, 1, 1))
	
	# 调整边距设置，改进垂直居中
	rich_label.add_theme_constant_override("margin_top", 70)  # 增加顶部边距推动文本下移
	rich_label.add_theme_constant_override("margin_bottom", 0)  # 减少底部边距
	
	# 修改垂直居中相关设置
	rich_label.size_flags_vertical = Control.SIZE_FILL  # 改为FILL而不是SHRINK_CENTER
	rich_label.size_flags_horizontal = Control.SIZE_FILL
	
	# 设置富文本对齐相关属性
	rich_label.justification_flags = TextServer.JUSTIFICATION_WORD_BOUND | TextServer.JUSTIFICATION_KASHIDA
	rich_label.text_direction = TextServer.DIRECTION_AUTO
	
	# 尝试使用正确的属性设置水平对齐方式
	if "justification" in rich_label:
		rich_label.justification = HORIZONTAL_ALIGNMENT_CENTER
	elif "horizontal_alignment" in rich_label:
		rich_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# 尝试设置垂直对齐（如果属性存在）
	if "vertical_alignment" in rich_label:
		rich_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# 设置文本边距（如果属性存在）
	if "text_margin_top" in rich_label:
		rich_label.set("text_margin_top", 30)
	
	# 添加调试输出
	print("RichTextLabel 创建完成")
	print("- bbcode_enabled:", rich_label.bbcode_enabled)
	print("- size_flags_vertical:", rich_label.size_flags_vertical)
	print("- custom_minimum_size:", rich_label.custom_minimum_size)
	
	# 保存引用
	dialog_text = rich_label

func _input(event):
	if event is InputEventMouseButton and event.pressed and can_advance:
		# 播放点击音效
		play_click_sound()
		
		if current_tween and current_tween.is_running():
			# 当动画播放中，点击立即完成当前文本显示
			current_tween.kill()
			dialog_text.visible_characters = -1  # 显示所有字符
			return
		
		can_advance = false
		await get_tree().create_timer(0.3).timeout  # 略微减少等待时间
		can_advance = true
		advance_text()

# 播放点击音效函数
func play_click_sound():
	if click_sound and click_sound.stream:
		click_sound.play()

# 打字机效果函数
func display_typewriter_text(text: String, speed: float = 0.1):
	# 处理文本，确保换行标签正确
	text = text.replace("[br]", "\n")  # 将[br]标签转换为实际换行
	
	# 方案A：如果之前的属性设置不成功，使用BBCode包装文本确保居中
	if not ("justification" in dialog_text or "horizontal_alignment" in dialog_text):
		# 检查文本是否已包含居中标签
		if not text.begins_with("[center]"):
			text = "[center]" + text + "[/center]"
	
	# 使用clear和append_text而不是直接设置text属性
	dialog_text.clear()
	dialog_text.append_text(text)
	dialog_text.visible_characters = 0
	
	var typewriter_tween = create_tween()
	typewriter_tween.set_trans(Tween.TRANS_LINEAR)
	
	# 计算总字符数（RichTextLabel自动处理富文本标签）
	var total_visible_chars = dialog_text.get_total_character_count()
	
	# 创建打字机效果
	typewriter_tween.tween_property(dialog_text, "visible_characters", 
								   total_visible_chars, total_visible_chars * speed)
	
	current_tween = typewriter_tween
	
	# 在下一帧输出容器和文本尺寸信息，用于调试垂直居中效果
	await get_tree().process_frame
	print("文本容器大小:", text_container.size)
	print("文本标签大小:", dialog_text.size)
	print("文本标签位置:", dialog_text.position)

func display_current_text():
	if current_text_index < story_text.size():
		# 使用打字机效果显示当前文本
		display_typewriter_text(story_text[current_text_index])
	else:
		proceed_to_main_game()

func advance_text():
	current_text_index += 1
	if current_text_index < story_text.size():
		# 立即切换到下一段文本
		display_current_text()
	else:
		fade_out_and_proceed()

func fade_out_and_proceed():
	current_tween = create_tween()
	current_tween.tween_property(dialog_text, "modulate:a", 0.0, 1.0)
	current_tween.tween_callback(proceed_to_main_game)

func proceed_to_main_game():
	# 标记已观看过介绍
	mark_intro_as_viewed()
	
	# 切换到高云峰CG场景，而不是直接进入主游戏
	get_tree().change_scene_to_file("res://scenes/office_cg.tscn")

func on_skip_button_pressed():
	# 播放点击音效
	play_click_sound()
	
	# 跳过介绍，直接进入游戏
	mark_intro_as_viewed()
	proceed_to_main_game()

# 检查是否已经观看过介绍
func has_viewed_intro() -> bool:
	return FileAccess.file_exists("user://game_data.cfg") and load_user_data().get(INTRO_VIEWED_KEY, false)

# 标记介绍已观看
func mark_intro_as_viewed():
	var data = load_user_data()
	data[INTRO_VIEWED_KEY] = true
	save_user_data(data)

# 加载用户数据
func load_user_data() -> Dictionary:
	if FileAccess.file_exists("user://game_data.cfg"):
		var file = FileAccess.open("user://game_data.cfg", FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		if content and content.length() > 0:
			var json_result = JSON.parse_string(content)
			if json_result != null:
				return json_result
	return {}

# 保存用户数据
func save_user_data(data: Dictionary):
	var file = FileAccess.open("user://game_data.cfg", FileAccess.WRITE)
	var json_string = JSON.stringify(data)
	file.store_string(json_string)
	file.close() 
