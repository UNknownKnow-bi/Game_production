extends Control

signal option_selected(option_id, event_id)
signal popup_closed

@onready var title_label = $PopupPanel/TitleLabel
@onready var content_text = $PopupPanel/ContentText
@onready var event_image = $PopupPanel/EventImage
@onready var accept_button = $PopupPanel/ButtonsContainer/AcceptButton
@onready var reject_button = $PopupPanel/ButtonsContainer/RejectButton
@onready var close_button = $PopupPanel/CloseButton

var current_event_id = -1

func _ready():
	# 连接按钮信号
	accept_button.pressed.connect(_on_accept_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	# 默认隐藏
	visible = false
	
	# 确保弹窗显示在最顶层
	z_index = 1000
	print("事件弹窗z_index设置为: ", z_index)

# 显示事件弹窗
func show_event(event_data: Dictionary):
	current_event_id = event_data.event_id
	
	# 设置标题和内容
	title_label.text = event_data.title
	content_text.text = event_data.description
	
	# 如果有图像，加载并显示
	if event_data.has("image_path") and event_data.image_path != "":
		var texture = load(event_data.image_path)
		if texture:
			event_image.texture = texture
			event_image.visible = true
		else:
			event_image.visible = false
	else:
		event_image.visible = false
	
	# 设置确认按钮文本
	accept_button.text = "确认"
	
	# 强制隐藏拒绝按钮
	reject_button.visible = false
	
	# 显示弹窗
	visible = true

# 隐藏弹窗
func hide_popup():
	visible = false
	current_event_id = -1

# 按钮回调
func _on_accept_button_pressed():
	option_selected.emit(1, current_event_id)
	hide_popup()

func _on_close_button_pressed():
	popup_closed.emit()
	hide_popup() 
