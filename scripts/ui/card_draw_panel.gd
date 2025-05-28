extends Control

# CardDrawPanel - 抽卡面板
# 实现随机抽取特权卡界面

signal card_drawn(card_type: String)
signal panel_closed()
signal force_draw_warning_requested()

@onready var card1_image = $CenterContainer/PanelContainer/VBoxContainer/CardGrid/Card1/Card1Image
@onready var card2_image = $CenterContainer/PanelContainer/VBoxContainer/CardGrid/Card2/Card2Image
@onready var card3_image = $CenterContainer/PanelContainer/VBoxContainer/CardGrid/Card3/Card3Image
@onready var card4_image = $CenterContainer/PanelContainer/VBoxContainer/CardGrid/Card4/Card4Image
@onready var title_label = $CenterContainer/PanelContainer/VBoxContainer/Title
@onready var draw_button = $CenterContainer/PanelContainer/VBoxContainer/ButtonContainer/DrawButton
@onready var confirm_button = $CenterContainer/PanelContainer/VBoxContainer/ButtonContainer/ConfirmButton
@onready var card1_container = $CenterContainer/PanelContainer/VBoxContainer/CardGrid/Card1
@onready var card2_container = $CenterContainer/PanelContainer/VBoxContainer/CardGrid/Card2
@onready var card3_container = $CenterContainer/PanelContainer/VBoxContainer/CardGrid/Card3
@onready var card4_container = $CenterContainer/PanelContainer/VBoxContainer/CardGrid/Card4
@onready var card1_highlight = $CenterContainer/PanelContainer/VBoxContainer/CardGrid/Card1/HighlightBorder
@onready var card2_highlight = $CenterContainer/PanelContainer/VBoxContainer/CardGrid/Card2/HighlightBorder
@onready var card3_highlight = $CenterContainer/PanelContainer/VBoxContainer/CardGrid/Card3/HighlightBorder
@onready var card4_highlight = $CenterContainer/PanelContainer/VBoxContainer/CardGrid/Card4/HighlightBorder

const CARD_TYPES = ["挥霍", "装X", "陷害", "秘会"]
const CARD_TEXTURES = {
	"挥霍": "res://assets/cards/挥霍卡.png",
	"装X": "res://assets/cards/装X卡.png",
	"陷害": "res://assets/cards/陷害卡.png",
	"秘会": "res://assets/cards/秘会卡.png"
}

var is_forced_mode: bool = false
var is_drawing: bool = false
var selected_card_index: int = -1
var card_containers: Array = []
var highlight_effects: Array = []

func _ready():
	# 初始化卡片图片
	load_card_images()
	
	# 初始化数组
	card_containers = [card1_container, card2_container, card3_container, card4_container]
	highlight_effects = [card1_highlight, card2_highlight, card3_highlight, card4_highlight]
	
	# 初始状态隐藏面板
	visible = false
	
	print("Card Draw Panel: 抽卡面板已初始化")

# 加载卡片图片
func load_card_images():
	var image_nodes = [card1_image, card2_image, card3_image, card4_image]
	
	for i in range(CARD_TYPES.size()):
		if i < image_nodes.size() and image_nodes[i]:
			var texture_path = CARD_TEXTURES.get(CARD_TYPES[i], "")
			if texture_path != "":
				var texture = load(texture_path)
				if texture:
					image_nodes[i].texture = texture
					print("Card Draw Panel: 加载卡片图片 - ", CARD_TYPES[i])

# 显示抽卡面板
func show_panel(forced: bool = false):
	is_forced_mode = forced
	reset_draw_state()
	
	if is_forced_mode:
		title_label.text = "必须抽取一张特权卡"
	else:
		title_label.text = "抽取特权卡"
	
	visible = true
	print("Card Draw Panel: 显示抽卡面板，强制模式: ", is_forced_mode)

# 显示强制抽卡面板
func show_panel_forced():
	show_panel(true)

# 隐藏抽卡面板
func hide_panel():
	clear_all_highlights()
	visible = false
	print("Card Draw Panel: 隐藏抽卡面板")
	panel_closed.emit()

# 重置抽取状态
func reset_draw_state():
	is_drawing = false
	selected_card_index = -1
	clear_all_highlights()
	draw_button.visible = true
	draw_button.disabled = false
	confirm_button.visible = false

# 清除所有高亮效果
func clear_all_highlights():
	for highlight in highlight_effects:
		if highlight:
			highlight.visible = false

# 高亮选中的卡片
func highlight_selected_card(index: int):
	clear_all_highlights()
	if index >= 0 and index < highlight_effects.size() and highlight_effects[index]:
		highlight_effects[index].visible = true
		print("Card Draw Panel: 高亮卡片 ", index + 1, " - ", CARD_TYPES[index])

# 执行随机抽取
func perform_random_draw():
	if is_drawing:
		return
	
	is_drawing = true
	draw_button.disabled = true
	
	# 随机选择一张卡片
	selected_card_index = randi() % CARD_TYPES.size()
	var selected_card_type = CARD_TYPES[selected_card_index]
	
	print("Card Draw Panel: 随机抽取到 - ", selected_card_type)
	
	# 高亮选中的卡片
	highlight_selected_card(selected_card_index)
	
	# 显示确认按钮
	draw_button.visible = false
	confirm_button.visible = true

# 抽取按钮点击处理
func _on_draw_button_pressed():
	print("Card Draw Panel: 点击抽取按钮")
	perform_random_draw()

# 确认按钮点击处理
func _on_confirm_button_pressed():
	if selected_card_index < 0:
		print("Card Draw Panel: 错误 - 没有选中的卡片")
		return
	
	var selected_card_type = CARD_TYPES[selected_card_index]
	print("Card Draw Panel: 确认抽取卡片 - ", selected_card_type)
	
	# 检查是否可以添加卡片
	if PrivilegeCardManager and PrivilegeCardManager.can_add_card():
		# 添加卡片到管理器
		var success = PrivilegeCardManager.add_privilege_card(selected_card_type)
		if success:
			card_drawn.emit(selected_card_type)
			hide_panel()
		else:
			print("Card Draw Panel: 添加卡片失败")
	else:
		print("Card Draw Panel: 无法添加更多卡片") 