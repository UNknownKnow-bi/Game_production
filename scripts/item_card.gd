class_name ItemCard
extends Control

# 节点引用
@onready var card_base: TextureRect = $CardBase
@onready var item_image: TextureRect = $ItemImage
@onready var text_layer: Control = $TextLayer
@onready var card_name: Label = $TextLayer/CardName
@onready var attributes_label: Label = $TextLayer/AttributesLabel
@onready var tags_label: Label = $TextLayer/TagsLabel

# 数据引用
var card_data: ItemCardData

# 初始化卡片
func _ready():
	print("=== ItemCard场景初始化开始 ===")
	print("ItemCard: 场景大小 - ", size)
	print("ItemCard: 节点引用检查:")
	print("  - CardBase: ", card_base != null)
	print("  - ItemImage: ", item_image != null)
	print("  - TextLayer: ", text_layer != null)
	print("  - CardName: ", card_name != null)
	print("  - AttributesLabel: ", attributes_label != null)
	print("  - TagsLabel: ", tags_label != null)
	
	# 等待真实数据，不使用测试数据
	print("ItemCard: 等待真实卡片数据...")

# 测试函数：显示指定ID的卡片
func test_display_card(card_id: int):
	print("ItemCard: 测试显示卡片ID ", card_id)
	
	# 创建测试数据
	var test_data = ItemCardData.new()
	test_data.card_id = card_id
	test_data.card_name = "午后会谈的艺术"
	test_data.card_level = "P4"
	test_data.card_type = "情报卡"
	test_data.attributes_json = '{"social":2,"execution":2}'
	test_data.card_description = "办公室的午后时光总是最适合深度交流的。你端着刚冲好的咖啡，在茶水间遇到了那位一直想要接触的项目负责人。"
	test_data.card_tags_json = '["平衡发展"]'
	
	print("ItemCard: 测试数据验证 - ", test_data.validate())
	
	# 显示卡片
	display_card(test_data)

# 显示卡片数据
func display_card(data: ItemCardData):
	if not data:
		print("ItemCard: 错误 - 卡片数据为空")
		return
		
	card_data = data
	print("ItemCard: 开始显示卡片 - ", data.card_name)
	print("ItemCard: 卡片等级 - ", data.card_level)
	print("ItemCard: 卡片类型 - ", data.card_type)
	
	# 加载底图
	load_card_base()
	
	# 加载情报卡图片
	load_item_image()
	
	# 设置文字信息
	setup_text_display()
	
	print("ItemCard: ✓ 卡片显示完成")

# 加载道具卡底图
func load_card_base():
	var base_path = card_data.get_card_base_path()
	print("ItemCard: 加载底图路径 - ", base_path)
	
	if FileAccess.file_exists(base_path):
		var texture = load(base_path) as Texture2D
		if texture:
			card_base.texture = texture
			print("ItemCard: ✓ 底图加载成功 - 尺寸: ", texture.get_size())
		else:
			print("ItemCard: ⚠ 底图文件无法加载为纹理")
	else:
		print("ItemCard: ⚠ 底图文件不存在: ", base_path)
		# 设置背景色以便查看卡片轮廓
		card_base.color = Color.GRAY

# 加载情报卡图片
func load_item_image():
	var image_path = card_data.get_item_image_path()
	print("ItemCard: 加载情报卡图片路径 - ", image_path)
	
	if FileAccess.file_exists(image_path):
		var texture = load(image_path) as Texture2D
		if texture:
			item_image.texture = texture
			print("ItemCard: ✓ 情报卡图片加载成功 - 尺寸: ", texture.get_size())
		else:
			print("ItemCard: ⚠ 情报卡图片文件无法加载为纹理")
	else:
		print("ItemCard: ⚠ 情报卡图片文件不存在: ", image_path)
		# 设置背景色以便查看图片区域
		item_image.color = Color.LIGHT_BLUE

# 设置文字显示
func setup_text_display():
	# 设置卡片名称
	card_name.text = card_data.card_name
	print("ItemCard: 设置卡片名称 - ", card_data.card_name)
	
	# 设置属性信息显示
	setup_attributes_display()
	
	# 设置标签信息显示
	setup_tags_display()
	
	print("ItemCard: ✓ 文字信息设置完成")

# 设置属性信息显示
func setup_attributes_display():
	var formatted_attributes = card_data.get_formatted_attributes()
	print("ItemCard: 属性信息 - ", formatted_attributes)
	
	# 直接设置固定节点的文本
	if attributes_label:
		attributes_label.text = formatted_attributes
	else:
		print("ItemCard: ⚠ AttributesLabel节点未找到")

# 设置标签信息显示  
func setup_tags_display():
	var formatted_tags = card_data.get_formatted_tags()
	if formatted_tags.is_empty():
		# 如果没有标签，设置为空文本
		if tags_label:
			tags_label.text = ""
		return
		
	print("ItemCard: 标签信息 - ", formatted_tags)
	
	# 直接设置固定节点的文本
	if tags_label:
		tags_label.text = formatted_tags
	else:
		print("ItemCard: ⚠ TagsLabel节点未找到")

# 更新卡片显示
func update_display():
	if card_data:
		display_card(card_data)

# 获取当前卡片数据
func get_card_data() -> ItemCardData:
	return card_data

# 设置卡片大小
func set_card_size(new_size: Vector2):
	# 布局保护：锁定尺寸为设计尺寸
	var design_size = Vector2(500, 200)
	custom_minimum_size = design_size
	size = design_size
	
	# 确保内部组件保持相对位置
	if card_base:
		card_base.size = design_size
	
	print("ItemCard: 尺寸保护 - 锁定为设计尺寸: ", design_size) 