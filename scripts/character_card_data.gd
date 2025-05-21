class_name CharacterCardData
extends Resource

@export var card_id: String
@export var card_name: String 
@export var card_picture: String  # 存储相对路径
@export var card_level: String  # P1, P2, P3, P4
@export var company_name: String = "WonderTech"
@export var job_title: String = "生态员工"  # 职位信息，可选

# 获取资源路径
func get_character_image_path() -> String:
	return "res://assets/character/" + card_picture

func get_card_face_path() -> String:
	return "res://assets/cards/" + card_level + ".png"
	
func get_card_overlay_path() -> String:
	return "res://assets/cards/" + card_level + "_cloud.png" 
