extends Control

signal popup_closed()

@onready var content_label: Label = $CenterContainer/PanelContainer/VBoxContainer/ContentLabel
@onready var title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/TitleLabel

func _ready():
	hide()

func show_warning(title: String = "提示", content: String = "必须抽取一张特权卡才能继续"):
	title_label.text = title
	content_label.text = content
	show()

func hide_popup():
	hide()
	popup_closed.emit()

func _on_ok_button_pressed():
	hide_popup() 