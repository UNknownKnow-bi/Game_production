extends Control

# 节点引用
@onready var background = $Background
@onready var card_side_bar_char = $CardSideBar/CardSideBarChar
@onready var card_side_bar_others = $CardSideBar/CardSideBarOthers
@onready var pc = $UIElements/PC
@onready var rabbit_icon = $UIElements/Icons/RabbitIcon
@onready var cup_icon = $UIElements/Icons/CupIcon
@onready var bear_icon = $UIElements/Icons/BearIcon

# PC游戏容器引用
@onready var pc_game_container = $UIElements/PC/PCGameContainer

func _ready():
	# 初始化函数，可在此处添加场景初始化逻辑
	print("工作日主场景已加载")
	
	# 确保图层顺序正确
	background.z_index = 0  # 最底层
	$CardSideBar.z_index = 1  # 中间层
	pc.z_index = 2  # PC层，可以阻挡卡片侧边栏
	$UIElements/Icons.z_index = 3  # 最上层
	
	# 初始化UI元素的位置
	# 这里我们只添加了基本的初始化，具体位置会由用户手动调整
	
	# 设置PC游戏容器初始位置和大小
	setup_pc_game_container()
	
	# 使用FontManager应用字体到场景
	if FontManager:
		FontManager.apply_to_scene(self)
		print("FontManager已应用到工作日主场景")

# 设置PC游戏容器
func setup_pc_game_container():
	if pc_game_container:
		# 使用从scene文件中读取到的确切位置和大小
		var container_position = Vector2(34, -90)  # 位置
		var container_size = Vector2(1206, 679)    # 计算得到的尺寸 (右边界 - 左边界, 下边界 - 上边界)
		pc_game_container.set_display_rect(container_position, container_size)
		
		# 添加测试内容
		add_test_content()

# 可选：添加测试内容
func add_test_content():
	if pc_game_container:
		var test_node = Node2D.new()
		
		# 添加一个简单的测试矩形
		var rect = ColorRect.new()
		rect.size = Vector2(200, 200)
		rect.position = Vector2(50, 50)
		rect.color = Color(0.5, 0.8, 0.2, 1.0)  # 浅绿色
		test_node.add_child(rect)
		
		# 添加标签
		var label = Label.new()
		label.text = "测试内容"
		label.position = Vector2(125, 125)
		
		# 应用字体到动态创建的标签
		if FontManager:
			var font = FontManager.get_font()
			if font:
				label.add_theme_font_override("font", font)
				label.add_theme_font_size_override("font_size", FontManager.get_font_size("label"))
		
		test_node.add_child(label)
		
		pc_game_container.load_content(test_node)