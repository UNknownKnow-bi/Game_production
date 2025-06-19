class_name PlayerAttributesPopup
extends Control

# 节点引用
@onready var background: ColorRect = $Background
@onready var popup_panel: Panel = $PopupPanel
@onready var main_control: Control = $PopupPanel/MainControl
@onready var close_button: Button = $PopupPanel/MainControl/CloseButton

# 属性图标节点引用
@onready var power_icon: TextureRect = $PopupPanel/MainControl/PowerIcon
@onready var power_label: Label = $PopupPanel/MainControl/PowerLabel
@onready var power_value: Label = $PopupPanel/MainControl/PowerValue
@onready var reputation_icon: TextureRect = $PopupPanel/MainControl/ReputationIcon
@onready var reputation_label: Label = $PopupPanel/MainControl/ReputationLabel
@onready var reputation_value: Label = $PopupPanel/MainControl/ReputationValue
@onready var piety_icon: TextureRect = $PopupPanel/MainControl/PietyIcon
@onready var piety_label: Label = $PopupPanel/MainControl/PietyLabel
@onready var piety_value: Label = $PopupPanel/MainControl/PietyValue

# 属性图标路径映射
var attribute_icon_paths = {
	"power": "res://assets/cards/attribute/power.png",
	"reputation": "res://assets/cards/attribute/reputation.png",
	"piety": "res://assets/cards/attribute/piety.png"
}

func _ready():
	print("PlayerAttributesPopup: 初始化开始")
	
	# 连接背景点击事件（点击背景关闭弹窗）
	background.gui_input.connect(_on_background_input)
	
	# 设置初始可见性
	visible = false
	
	# 加载属性图标
	_load_attribute_icons()
	
	print("PlayerAttributesPopup: 初始化完成")

# 显示弹窗
func show_popup():
	print("PlayerAttributesPopup: 显示弹窗")
	
	# 更新属性数值
	_update_attribute_values()
	
	# 显示弹窗
	visible = true
	
	# 确保显示在最顶层
	z_index = 1000

# 隐藏弹窗
func hide_popup():
	print("PlayerAttributesPopup: 隐藏弹窗")
	visible = false

# 加载属性图标
func _load_attribute_icons():
	print("PlayerAttributesPopup: 开始加载属性图标")
	
	# 加载权势图标
	var power_texture = _load_icon_texture("power")
	if power_texture:
		power_icon.texture = power_texture
		print("PlayerAttributesPopup: 权势图标加载成功")
	else:
		print("PlayerAttributesPopup: 权势图标加载失败")
	
	# 加载声望图标
	var reputation_texture = _load_icon_texture("reputation")
	if reputation_texture:
		reputation_icon.texture = reputation_texture
		print("PlayerAttributesPopup: 声望图标加载成功")
	else:
		print("PlayerAttributesPopup: 声望图标加载失败")
	
	# 加载虔信图标
	var piety_texture = _load_icon_texture("piety")
	if piety_texture:
		piety_icon.texture = piety_texture
		print("PlayerAttributesPopup: 虔信图标加载成功")
	else:
		print("PlayerAttributesPopup: 虔信图标加载失败")

# 加载单个图标纹理
func _load_icon_texture(attribute_name: String) -> Texture2D:
	var icon_path = attribute_icon_paths.get(attribute_name, "")
	if icon_path.is_empty():
		print("PlayerAttributesPopup: 未找到属性图标路径: ", attribute_name)
		return null
	
	if not FileAccess.file_exists(icon_path):
		print("PlayerAttributesPopup: 图标文件不存在: ", icon_path)
		return null
	
	var texture = load(icon_path) as Texture2D
	if not texture:
		print("PlayerAttributesPopup: 无法加载图标纹理: ", icon_path)
		return null
	
	return texture

# 更新属性数值显示
func _update_attribute_values():
	print("PlayerAttributesPopup: 更新属性数值")
	
	if not AttributeManager:
		print("PlayerAttributesPopup: AttributeManager未找到")
		return
	
	# 获取当前属性值
	var attributes = AttributeManager.get_all_attributes()
	
	# 更新权势数值
	var power_val = attributes.get("power", 1)
	power_value.text = str(power_val)
	print("PlayerAttributesPopup: 权势值更新为: ", power_val)
	
	# 更新声望数值
	var reputation_val = attributes.get("reputation", 1)
	reputation_value.text = str(reputation_val)
	print("PlayerAttributesPopup: 声望值更新为: ", reputation_val)
	
	# 更新虔信数值
	var piety_val = attributes.get("piety", 1)
	piety_value.text = str(piety_val)
	print("PlayerAttributesPopup: 虔信值更新为: ", piety_val)

# 关闭按钮点击处理
func _on_close_button_pressed():
	print("PlayerAttributesPopup: 关闭按钮被点击")
	hide_popup()

# 背景点击处理
func _on_background_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("PlayerAttributesPopup: 背景被点击，关闭弹窗")
			hide_popup()

# 清理资源
func _exit_tree():
	print("PlayerAttributesPopup: 清理资源")
	if background and background.gui_input.is_connected(_on_background_input):
		background.gui_input.disconnect(_on_background_input) 