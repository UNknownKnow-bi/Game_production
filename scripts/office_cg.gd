extends CanvasLayer

# 场景资源
const ELEVATOR_SCENE = "res://assets/CG/open2/elevator_gao.png"
const OFFICE_SCENE = "res://assets/CG/open2/ofiice_gao.png"
const CLICK_SOUND_PATH = "res://assets/CG/open/click.mp3"

# 特权卡类型
const CARD_TYPES = ["挥霍", "装X", "陷害", "秘会"]

# 直接定义字体路径
const CUSTOM_FONT_PATH = "res://assets/font/LEEEAFHEI-REGULAR.TTF"

# 文本框自适应配置
const DIALOG_BOX_HEIGHT_RATIO = 0.25     # 对话框高度占屏幕的比例
const DIALOG_TEXT_MARGIN_RATIO = 0.05    # 文本边距占对话框的比例
const MIN_DIALOG_BOX_HEIGHT = 150        # 最小对话框高度
const MAX_DIALOG_BOX_HEIGHT = 300        # 最大对话框高度

# 字体大小配置 - 使用固定大小
const FONT_SIZE_SPEAKER = 33      # 说话人名称
const FONT_SIZE_DIALOG = 40       # 对话文本
const FONT_SIZE_TITLE = 28        # 标题
const FONT_SIZE_BUTTON = 22       # 按钮文本
const FONT_SIZE_RESULT = 22       # 结果文本

# 行间距配置
const LINE_SPACING_DIALOG = 10     # 对话文本行间距
const LINE_SPACING_RESULT = 5     # 结果文本行间距

# 动态文本调整配置
const REFERENCE_WIDTH = 1920.0    # 参考分辨率宽度
const REFERENCE_HEIGHT = 1080.0   # 参考分辨率高度
const MIN_FONT_SIZE_FACTOR = 0.8  # 最小字体大小因子
const MAX_FONT_SIZE_FACTOR = 1.5  # 最大字体大小因子
const LINE_SPACING_RATIO = 0.3    # 行间距与字体大小的比例

# 对话文本数组，每个元素包含说话人和内容
var dialog_data = [
	{"speaker": "", "text": "你站在电梯里,看着数字缓缓跳动。这是你入职WonderTech的第三周,试用期还有一个月。作为研发部门的新人,你正在努力适应这家顶级互联网公司的节奏。", "scene": ELEVATOR_SCENE},
	{"speaker": "", "text": "电梯在15层停下,门缓缓打开。一个西装革履的男人走了进来,你认出他是产品部的高管高云峰。他看起来三十出头,但眼神中透露出远超年龄的锐利。", "scene": ELEVATOR_SCENE},
	{"speaker": "高云峰", "text": "新来的？", "scene": ELEVATOR_SCENE},
	{"speaker": "我", "text": "是的,高总。我是研发部的...", "scene": ELEVATOR_SCENE},
	{"speaker": "高云峰", "text": "我知道你是谁。", "scene": ELEVATOR_SCENE},
	{"speaker": "", "text": "他打断你的话,嘴角勾起一抹意味深长的笑。", "scene": ELEVATOR_SCENE},
	{"speaker": "高云峰", "text": "你的简历我看过,很有意思。特别是...你处理上一家公司那个项目的方式。", "scene": ELEVATOR_SCENE},
	{"speaker": "", "text": "你的心跳漏了一拍。那件事你从未对任何人提起过。", "scene": ELEVATOR_SCENE},
	{"speaker": "高云峰", "text": "跟我来办公室聊聊。", "scene": ELEVATOR_SCENE},
	{"speaker": "", "text": "电梯到达顶层,他率先走了出去。", "scene": ELEVATOR_SCENE},
	{"speaker": "", "text": "[场景：高云峰办公室]", "scene": OFFICE_SCENE},
	{"speaker": "", "text": "高云峰的办公室宽敞明亮,落地窗外是整个城市的全景。他示意你坐下,自己则站在窗前,背对着你。", "scene": OFFICE_SCENE},
	{"speaker": "高云峰", "text": "你知道为什么我会注意到你吗？", "scene": OFFICE_SCENE},
	{"speaker": "", "text": "他的声音带着一丝玩味。", "scene": OFFICE_SCENE},
	{"speaker": "高云峰", "text": "因为我在你身上看到了...野心。那种不甘于平庸,想要往上爬的野心。", "scene": OFFICE_SCENE},
	{"speaker": "", "text": "他转过身,目光如炬。", "scene": OFFICE_SCENE},
	{"speaker": "高云峰", "text": "这个公司就像一座金字塔,每个人都在往上爬。但大多数人,一辈子都只能在中层徘徊。他们以为只要努力工作就能得到回报,多么天真。", "scene": OFFICE_SCENE},
	{"speaker": "", "text": "他从抽屉里拿出一个精致的盒子。", "scene": OFFICE_SCENE},
	{"speaker": "高云峰", "text": "我给你准备了一份礼物。28张特权通行证,每一张都代表着一次...改变命运的机会。", "scene": OFFICE_SCENE},
	{"speaker": "我", "text": "高总,我不明白...", "scene": OFFICE_SCENE},
	{"speaker": "高云峰", "text": "你当然明白。", "scene": OFFICE_SCENE},
	{"speaker": "", "text": "他走到你面前,将盒子放在桌上。", "scene": OFFICE_SCENE},
	{"speaker": "高云峰", "text": "你知道这个公司有多少人想要我的位置吗？但他们都太...正直了。在这个弱肉强食的世界里,正直是最无用的品质。", "scene": OFFICE_SCENE},
	{"speaker": "", "text": "他打开盒子,里面是28张精美的卡片。", "scene": OFFICE_SCENE},
	{"speaker": "高云峰", "text": "这些卡片,可以帮你解决很多...麻烦。比如,让某个碍事的人消失,或者...让某个重要的人对你另眼相看。", "scene": OFFICE_SCENE},
	{"speaker": "我", "text": "但是...", "scene": OFFICE_SCENE},
	{"speaker": "高云峰", "text": "没有但是。", "scene": OFFICE_SCENE},
	{"speaker": "", "text": "他的声音突然变得冰冷。", "scene": OFFICE_SCENE},
	{"speaker": "高云峰", "text": "试用期还有一个月,你觉得自己能顺利通过吗？特别是在...我知道你那些小秘密的情况下。", "scene": OFFICE_SCENE},
	{"speaker": "", "text": "你感到一阵寒意。这个男人似乎知道很多不该知道的事情。", "scene": OFFICE_SCENE},
	{"speaker": "高云峰", "text": "现在,抽一张卡。", "scene": OFFICE_SCENE},
	{"speaker": "", "text": "他推过盒子。", "scene": OFFICE_SCENE},
	{"speaker": "高云峰", "text": "让我看看你的...运气。", "scene": OFFICE_SCENE, "trigger_card_selection": true},
	{"speaker": "高云峰", "text": "有意思。", "scene": OFFICE_SCENE},
	{"speaker": "", "text": "他看着你抽出的卡片,露出一个意味深长的笑容。", "scene": OFFICE_SCENE},
	{"speaker": "高云峰", "text": "看来命运已经为你做出了选择。记住,在这个公司里,每个人都是棋子。区别只在于,你是想当别人的棋子,还是...下棋的人。", "scene": OFFICE_SCENE},
	{"speaker": "", "text": "他站起身,走到窗前,夕阳的余晖为他的侧脸镀上一层阴影。", "scene": OFFICE_SCENE},
	{"speaker": "", "text": "他转过身,嘴角勾起一抹意味深长的笑。", "scene": OFFICE_SCENE},
	{"speaker": "高云峰", "text": "让我看看你到底会怎么用这张卡。", "scene": OFFICE_SCENE},
	{"speaker": "", "text": "他的声音低沉而富有磁性,却带着一丝不易察觉的威胁。", "scene": OFFICE_SCENE},
	{"speaker": "高云峰", "text": "当然,你不想玩这场游戏的话...", "scene": OFFICE_SCENE},
	{"speaker": "", "text": "他故意停顿了一下,目光在你脸上逡巡。", "scene": OFFICE_SCENE},
	{"speaker": "高云峰", "text": "只是不知道,你的试用期....", "scene": OFFICE_SCENE},
	{"speaker": "", "text": "他缓缓靠近，眼神在你身上游移，语气愈发阴冷。", "scene": OFFICE_SCENE},
	{"speaker": "高云峰", "text": "你要明白，这里不是讲道理的地方。你可以选择退出，也可以假装什么都没发生。但代价……未必是你能承受的。", "scene": OFFICE_SCENE},
	{"speaker": "", "text": "他低声笑了笑，仿佛在欣赏一场猎物的挣扎。", "scene": OFFICE_SCENE},
	{"speaker": "高云峰", "text": "所以，别让我失望。用好这张卡，也许你还能在这座大厦里活得久一点。", "scene": OFFICE_SCENE},
	{"speaker": "高云峰", "text": "现在,你可以回去了。记住,今天的事,不要告诉任何人。否则...", "scene": OFFICE_SCENE},
	{"speaker": "", "text": "他没有说完,但威胁的意味已经很明显。", "scene": OFFICE_SCENE},
	{"speaker": "", "text": "你离开办公室时，回头看了一眼。高云峰依旧站在窗前，背影在夕阳下拉得很长，仿佛整个房间都被他的阴影笼罩。", "scene": OFFICE_SCENE},
	{"speaker": "", "text": "你手中的特权卡微微发烫，预感到这场游戏才刚刚开始。", "scene": OFFICE_SCENE},
	{"speaker": "", "text": "这张卡片,究竟是通往成功的钥匙,还是...堕落的开始？", "scene": OFFICE_SCENE}
]

var current_dialog_index = 0
var current_tween = null
var can_advance = true
var in_card_selection = false
var selected_card_type = ""
var card_selected = false

# 节点引用
@onready var background = $Background
@onready var speaker_label = $DialogBox/SpeakerLabel
@onready var dialog_text = $DialogBox/DialogText
@onready var click_sound = $ClickSound
@onready var card_selection_panel = $CardSelectionPanel

# 游戏数据保存常量
const CARD_TYPE_KEY = "selected_card_type"

# 直接加载字体
var custom_font = preload(CUSTOM_FONT_PATH)

func _ready():
	# 隐藏卡片选择面板
	card_selection_panel.visible = false
	
	# 设置初始场景背景
	background.texture = load(dialog_data[0].scene)
	
	# 加载点击音效
	var click_audio = load(CLICK_SOUND_PATH)
	if click_audio:
		click_sound.stream = click_audio
	
	# 设置按钮信号
	$CardSelectionPanel/DrawCardButton.pressed.connect(on_draw_card_button_pressed)
	$CardSelectionPanel/ConfirmButton.pressed.connect(on_confirm_button_pressed)
	$CardSelectionPanel/ConfirmButton.visible = false
	
	# 初始化标签状态
	if dialog_data[0].speaker.strip_edges() == "":
		speaker_label.visible = false
		$DialogBox/Separator.visible = false
		dialog_text.position.y = 30
	else:
		speaker_label.visible = true
		$DialogBox/Separator.visible = true
		dialog_text.position.y = 60
	
	# 监听屏幕大小变化
	get_tree().root.size_changed.connect(_on_screen_resized)
	
	# 首先调整对话框大小
	adjust_dialog_box_size()
	
	# 再应用字体设置
	apply_custom_font_settings()
	
	# 开始显示对话
	display_current_dialog()

# 屏幕大小变化响应函数
func _on_screen_resized():
	print("屏幕大小已更改，调整UI...")
	
	# 先调整对话框大小和位置
	adjust_dialog_box_size()
	
	# 再应用字体设置
	apply_custom_font_settings()
	
	# 如果当前有显示文本，重新调整其显示
	if current_dialog_index < dialog_data.size():
		var current_text = dialog_data[current_dialog_index].text
		# 使用当前设置刷新文本显示
		dialog_text.clear()
		if not current_text.begins_with("[center]"):
			current_text = "[center]" + current_text + "[/center]"
		dialog_text.append_text(current_text)
	
	# 同时调整卡片选择面板的大小和位置
	adjust_card_panel_size()
	
	print("UI调整完成")

# 计算缩放因子 - 增强函数以考虑文本框大小
func calculate_scale_factor() -> float:
	var screen_size = get_viewport().size
	
	# 基于宽度和高度分别计算缩放因子
	var width_factor = screen_size.x / REFERENCE_WIDTH
	var height_factor = screen_size.y / REFERENCE_HEIGHT
	
	# 计算文本框高度因子
	var dialog_box_height = screen_size.y * DIALOG_BOX_HEIGHT_RATIO
	dialog_box_height = clamp(dialog_box_height, MIN_DIALOG_BOX_HEIGHT, MAX_DIALOG_BOX_HEIGHT)
	var dialog_height_factor = dialog_box_height / (REFERENCE_HEIGHT * DIALOG_BOX_HEIGHT_RATIO)
	
	# 综合考虑屏幕比例和文本框比例
	# 文本框比例权重略高，确保文本在文本框中显示合适
	var scale_factor = min(width_factor, height_factor) * 0.4 + dialog_height_factor * 0.6
	
	# 限制缩放因子范围
	scale_factor = clamp(scale_factor, MIN_FONT_SIZE_FACTOR, MAX_FONT_SIZE_FACTOR)
	
	print("计算的缩放因子: ", scale_factor, " (屏幕: ", width_factor, "x", height_factor, ", 文本框: ", dialog_height_factor, ")")
	
	return scale_factor

# 应用自定义字体设置 - 增强版本，考虑文本框尺寸
func apply_custom_font_settings():
	# 获取屏幕尺寸缩放因子 - 考虑了文本框尺寸
	var scale_factor = calculate_scale_factor()
	
	# 获取当前对话框尺寸
	var screen_size = get_viewport().size
	var dialog_box_height = screen_size.y * DIALOG_BOX_HEIGHT_RATIO
	dialog_box_height = clamp(dialog_box_height, MIN_DIALOG_BOX_HEIGHT, MAX_DIALOG_BOX_HEIGHT)
	
	# 动态计算最大字体大小以确保舒适阅读
	# 对话文本大小不应超过对话框高度的一定比例
	var max_dialog_font_size = int(dialog_box_height * 0.2)  # 20%的对话框高度
	var dialog_font_size = min(int(FONT_SIZE_DIALOG * scale_factor), max_dialog_font_size)
	
	# 使用固定字体大小和缩放因子计算最终大小
	var dynamic_font_sizes = {
		"speaker": int(FONT_SIZE_SPEAKER * scale_factor),
		"dialog": dialog_font_size, 
		"title": int(FONT_SIZE_TITLE * scale_factor),
		"button": int(FONT_SIZE_BUTTON * scale_factor),
		"result": int(FONT_SIZE_RESULT * scale_factor)
	}
	
	# 动态计算行间距 - 根据字体大小调整
	var dynamic_line_spacings = {
		"dialog": int(dynamic_font_sizes["dialog"] * LINE_SPACING_RATIO),
		"result": int(dynamic_font_sizes["result"] * LINE_SPACING_RATIO)
	}
	
	# 应用字体和字体大小设置
	
	# 1. Label节点字体和字体大小设置
	# 说话人标签
	speaker_label.add_theme_font_override("font", custom_font)
	speaker_label.add_theme_font_size_override("font_size", dynamic_font_sizes["speaker"])
	
	# 分隔线
	$DialogBox/Separator.add_theme_font_override("font", custom_font)
	
	# 继续指示标志
	$DialogBox/ContinueIndicator.add_theme_font_override("font", custom_font)
	$DialogBox/ContinueIndicator.add_theme_font_size_override("font_size", dynamic_font_sizes["dialog"])
	
	# 卡片选择标题
	$CardSelectionPanel/TitleLabel.add_theme_font_override("font", custom_font)
	$CardSelectionPanel/TitleLabel.add_theme_font_size_override("font_size", dynamic_font_sizes["title"])
	
	# 2. RichTextLabel节点字体和字体大小设置
	# 对话文本
	dialog_text.add_theme_font_override("normal_font", custom_font)
	dialog_text.add_theme_font_override("bold_font", custom_font)
	dialog_text.add_theme_font_override("italics_font", custom_font)
	dialog_text.add_theme_font_override("bold_italics_font", custom_font)
	
	dialog_text.add_theme_font_size_override("normal_font_size", dynamic_font_sizes["dialog"])
	dialog_text.add_theme_font_size_override("bold_font_size", dynamic_font_sizes["dialog"])
	dialog_text.add_theme_font_size_override("italics_font_size", dynamic_font_sizes["dialog"])
	dialog_text.add_theme_font_size_override("bold_italics_font_size", dynamic_font_sizes["dialog"])
	
	# 添加对话文本的行间距设置
	dialog_text.add_theme_constant_override("line_separation", dynamic_line_spacings["dialog"])
	
	# 结果标签
	$CardSelectionPanel/ResultLabel.add_theme_font_override("normal_font", custom_font)
	$CardSelectionPanel/ResultLabel.add_theme_font_override("bold_font", custom_font)
	$CardSelectionPanel/ResultLabel.add_theme_font_override("italics_font", custom_font)
	$CardSelectionPanel/ResultLabel.add_theme_font_override("bold_italics_font", custom_font)
	
	$CardSelectionPanel/ResultLabel.add_theme_font_size_override("normal_font_size", dynamic_font_sizes["result"])
	$CardSelectionPanel/ResultLabel.add_theme_font_size_override("bold_font_size", dynamic_font_sizes["result"])
	$CardSelectionPanel/ResultLabel.add_theme_font_size_override("italics_font_size", dynamic_font_sizes["result"])
	$CardSelectionPanel/ResultLabel.add_theme_font_size_override("bold_italics_font_size", dynamic_font_sizes["result"])
	
	# 添加结果标签的行间距设置
	$CardSelectionPanel/ResultLabel.add_theme_constant_override("line_separation", dynamic_line_spacings["result"])
	
	# 3. Button节点字体和字体大小设置
	# 抽卡按钮
	$CardSelectionPanel/DrawCardButton.add_theme_font_override("font", custom_font)
	$CardSelectionPanel/DrawCardButton.add_theme_font_size_override("font_size", dynamic_font_sizes["button"])
	
	# 确认按钮
	$CardSelectionPanel/ConfirmButton.add_theme_font_override("font", custom_font)
	$CardSelectionPanel/ConfirmButton.add_theme_font_size_override("font_size", dynamic_font_sizes["button"])
	
	print("自定义字体设置已应用，缩放因子: ", scale_factor, "，对话文本大小: ", dynamic_font_sizes["dialog"])

# 兼容性函数重定向
func apply_global_font_settings():
	apply_custom_font_settings()

func apply_custom_font():
	apply_custom_font_settings()

func apply_dynamic_text_settings():
	apply_custom_font_settings()

func apply_custom_font_with_dynamic_settings(font_sizes: Dictionary, line_spacings: Dictionary):
	apply_custom_font_settings()

func _input(event):
	if event is InputEventMouseButton and event.pressed and can_advance and not in_card_selection:
		play_click_sound()
		
		if current_tween and current_tween.is_running():
			# 当动画播放中，点击立即完成当前文本显示
			current_tween.kill()
			dialog_text.visible_characters = -1
			return
		
		can_advance = false
		await get_tree().create_timer(0.3).timeout
		can_advance = true
		advance_dialog()

# 播放点击音效
func play_click_sound():
	if click_sound and click_sound.stream:
		click_sound.play()

# 显示当前对话
func display_current_dialog():
	if current_dialog_index < dialog_data.size():
		var dialog = dialog_data[current_dialog_index]
		
		# 设置场景背景
		if background.texture != load(dialog.scene):
			background.texture = load(dialog.scene)
		
		# 设置说话人并控制分隔线显示
		speaker_label.text = dialog.speaker
		if dialog.speaker.strip_edges() == "":
			# 说话人为空，隐藏说话人标签和分隔线
			speaker_label.visible = false
			$DialogBox/Separator.visible = false
			# 调整文本位置上移
			dialog_text.position.y = 30
		else:
			# 说话人不为空，显示说话人标签和分隔线
			speaker_label.visible = true
			$DialogBox/Separator.visible = true
			# 恢复文本原始位置
			dialog_text.position.y = 60
		
		# 使用打字机效果显示文本
		display_typewriter_text(dialog.text)
		
		# 检查是否需要触发卡片选择
		if dialog.get("trigger_card_selection", false):
			in_card_selection = true
			show_card_selection_panel()
	else:
		proceed_to_main_game()

# 打字机效果函数
func display_typewriter_text(text: String, speed: float = 0.08):
	# 使用RichTextLabel清除并设置新文本
	dialog_text.clear()
	
	# 确保文本居中显示
	if not text.begins_with("[center]"):
		text = "[center]" + text + "[/center]"
	
	dialog_text.append_text(text)
	dialog_text.visible_characters = 0
	
	var typewriter_tween = create_tween()
	typewriter_tween.set_trans(Tween.TRANS_LINEAR)
	
	# 计算总字符数
	var total_visible_chars = dialog_text.get_total_character_count()
	
	# 创建打字机效果
	typewriter_tween.tween_property(dialog_text, "visible_characters", 
								   total_visible_chars, total_visible_chars * speed)
	
	current_tween = typewriter_tween

# 推进对话
func advance_dialog():
	current_dialog_index += 1
	display_current_dialog()

# 显示卡片选择面板
func show_card_selection_panel():
	card_selection_panel.visible = true
	$CardSelectionPanel/ResultLabel.text = "[center]请抽取一张特权卡[/center]"
	$CardSelectionPanel/DrawCardButton.visible = true
	$CardSelectionPanel/ConfirmButton.visible = false
	card_selected = false

# 抽卡按钮点击事件
func on_draw_card_button_pressed():
	play_click_sound()
	
	# 随机抽取卡片类型（等概率）
	var random_index = randi() % CARD_TYPES.size()
	selected_card_type = CARD_TYPES[random_index]
	
	# 显示抽取结果，使用居中格式
	$CardSelectionPanel/ResultLabel.text = "[center]你抽到了：[color=yellow]" + selected_card_type + "[/color] 特权卡[/center]"
	
	# 显示确认按钮，隐藏抽卡按钮
	$CardSelectionPanel/DrawCardButton.visible = false
	$CardSelectionPanel/ConfirmButton.visible = true
	
	# 保存抽取的卡片类型
	save_card_type(selected_card_type)
	
	card_selected = true

# 确认按钮点击事件
func on_confirm_button_pressed():
	play_click_sound()
	
	# 隐藏卡片选择面板
	card_selection_panel.visible = false
	in_card_selection = false
	
	# 继续对话
	advance_dialog()

# 保存卡片类型
func save_card_type(card_type: String):
	var data = load_user_data()
	data[CARD_TYPE_KEY] = card_type
	save_user_data(data)

# 跳转到主游戏场景
func proceed_to_main_game():
	get_tree().change_scene_to_file("res://scenes/workday_new/workday_main_new.tscn")

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

# 文本框自适应函数
func adjust_dialog_box_size():
	var screen_size = get_viewport().size
	
	# 由于我们已经设置了对话框使用锚点自适应高度
	# 现在只需要确保内部元素位置正确
	
	# 计算文本边距
	var dialog_text_margin = screen_size.x * DIALOG_TEXT_MARGIN_RATIO
	
	# 设置对话文本区域的左右边距
	dialog_text.position.x = dialog_text_margin
	dialog_text.size.x = screen_size.x - (2 * dialog_text_margin)
	
	# 根据是否有说话人来调整文本区域位置
	if speaker_label.visible:
		dialog_text.position.y = 60
	else:
		dialog_text.position.y = 30
	
	# 计算对话框的近似高度(屏幕高度的25%)
	var dialog_box_height = screen_size.y * DIALOG_BOX_HEIGHT_RATIO
	
	# 确保继续指示器在正确位置
	$DialogBox/ContinueIndicator.position = Vector2(
		screen_size.x - 50,  # 右侧距离
		dialog_box_height - 40  # 底部距离
	)
	
	print("对话框布局已调整，宽度:", screen_size.x - (2 * dialog_text_margin), "文本边距:", dialog_text_margin)

# 调整卡片选择面板的大小和位置
func adjust_card_panel_size():
	var screen_size = get_viewport().size
	
	# 卡片面板尺寸计算 - 宽度为屏幕宽度的50%，高度为屏幕高度的40%
	var card_panel_width = screen_size.x * 0.5
	var card_panel_height = screen_size.y * 0.4
	
	# 设置卡片面板的位置和大小 - 居中显示
	$CardSelectionPanel.position = Vector2(
		(screen_size.x - card_panel_width) / 2,  # 水平居中
		(screen_size.y - card_panel_height) / 2   # 垂直居中
	)
	
	# 在Godot 4中，能够直接设置Control节点的size
	$CardSelectionPanel.size = Vector2(card_panel_width, card_panel_height)
	
	print("卡片选择面板大小已调整：", card_panel_width, "x", card_panel_height)
