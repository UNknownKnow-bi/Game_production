class_name CharacterCard
extends Control

# 卡片数据
var card_data: CharacterCardData = null

# 公司和职位显示
@export var show_company_name: bool = true
@export var show_job_title: bool = true

# 字体大小
@export var company_name_font_size: int = 24 : set = set_company_name_font_size
@export var job_title_font_size: int = 18 : set = set_job_title_font_size
@export var character_name_font_size: int = 28 : set = set_character_name_font_size

# 按钮事件
signal card_clicked

# 节点引用
@onready var card_face = $CardFace
@onready var character_image = $CharacterImage
@onready var card_overlay = $CardOverlay
@onready var company_name_label = $TextLayer/CompanyName
@onready var job_title_label = $TextLayer/JobTitle
@onready var character_name_label = $TextLayer/CharacterName

func _ready():
    # 连接信号
    gui_input.connect(_on_gui_input)
    
    # 初始化UI
    update_display()
    
    # 确保层级顺序正确
    ensure_layer_order()

# 设置卡片数据
func set_card_data(data: CharacterCardData):
    card_data = data
    update_display()

# 更新显示内容
func update_display():
    if not is_inside_tree() or not card_data:
        return
        
    # 加载卡面
    var card_face_texture = load(card_data.get_card_face_path())
    if card_face_texture:
        card_face.texture = card_face_texture
    
    # 加载角色图片
    var character_texture = load(card_data.get_character_image_path())
    if character_texture:
        character_image.texture = character_texture
    
    # 加载卡罩
    var card_overlay_texture = load(card_data.get_card_overlay_path())
    if card_overlay_texture:
        card_overlay.texture = card_overlay_texture
    
    # 设置文本
    company_name_label.text = card_data.company_name
    company_name_label.visible = show_company_name
    
    job_title_label.text = card_data.job_title
    job_title_label.visible = show_job_title
    
    character_name_label.text = card_data.card_name
    
    # 确保层级顺序正确
    ensure_layer_order()

# 确保层级顺序正确：卡面->角色图片->卡罩->文字
func ensure_layer_order():
    # 检查所有节点是否已就绪
    if not is_inside_tree() or not card_face or not character_image or not card_overlay:
        return
        
    # 确保卡面在最底层
    move_child(card_face, 0)
    
    # 角色图片在卡面上方
    move_child(character_image, 1)
    
    # 卡罩在角色图片上方
    move_child(card_overlay, 2)
    
    # 文字层在最上方
    move_child($TextLayer, 3)

# 字体大小设置
func set_company_name_font_size(size: int):
    company_name_font_size = size
    if company_name_label:
        company_name_label.add_theme_font_size_override("font_size", size)

func set_job_title_font_size(size: int):
    job_title_font_size = size
    if job_title_label:
        job_title_label.add_theme_font_size_override("font_size", size)

func set_character_name_font_size(size: int):
    character_name_font_size = size
    if character_name_label:
        character_name_label.add_theme_font_size_override("font_size", size)

# 点击事件处理
func _on_gui_input(event):
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            card_clicked.emit() 