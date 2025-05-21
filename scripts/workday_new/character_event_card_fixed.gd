@tool
extends PanelContainer
class_name CharacterEventCardFixed

# 内容属性
@export_group("内容")
@export var event_title: String = "事件标题" : set = set_event_title
@export var character_name: String = "相关人物" : set = set_character_name
@export var event_status: String = "new" : set = set_event_status  # "new" 或 "dealing"
@export var character_texture: Texture2D : set = set_character_texture

# 图像裁剪属性
@export_group("图像裁剪")
@export var region_enabled: bool = false : set = set_region_enabled
@export_range(0.0, 1.0, 0.01) var region_y_position: float = 0.0 : set = set_region_y_position
@export_range(0.0, 1.0, 0.01) var region_height: float = 0.45 : set = set_region_height

# 样式属性
@export_group("样式")
@export var border_color: Color = Color(0.7, 0.7, 0.7, 1.0) : set = set_border_color
@export var corner_radius: int = 8 : set = set_corner_radius
@export var border_width: int = 2 : set = set_border_width
@export var background_color: Color = Color("#fff8f1") : set = set_background_color
@export var title_font_size: int = 50 : set = set_title_font_size
@export var name_font_size: int = 50 : set = set_name_font_size

# 用于存储原始纹理的变量
var _original_texture: Texture2D = null

# 节点引用
@onready var character_image = $CardContent/CharacterImage
@onready var title_label = $CardContent/EventTitle
@onready var name_label = $CardContent/EventPerson
@onready var status_icon = $CardContent/StatusIcon

# 资源引用
var new_status_texture = preload("res://assets/workday_new/ui/events/new.png")
var dealing_status_texture = preload("res://assets/workday_new/ui/events/dealing.png")

# 信号
signal card_clicked

func _ready():
    # 连接信号
    gui_input.connect(_on_gui_input)
    
    # 应用样式
    _apply_style()
    
    # 应用内容
    _apply_content()
    
    # 配置CharacterImage的显示模式
    if is_instance_valid(character_image):
        character_image.expand_mode = 3  # EXPAND_IGNORE_SIZE
        character_image.stretch_mode = 4  # STRETCH_KEEP_ASPECT_CONTAINED
        
        # 将CharacterImage移到所有其他节点的下方（最底层）
        var parent = character_image.get_parent()
        if parent:
            # 暂时移除节点
            parent.remove_child(character_image)
            # 将节点添加到最前面（在Godot中，添加顺序决定了绘制顺序，先添加的在下面）
            parent.add_child(character_image)
            # 将已有的其他节点移到最前面，确保它们在CharacterImage上方
            if is_instance_valid(title_label):
                parent.move_child(title_label, -1)  # 移到最后（最上面）
            if is_instance_valid(name_label):
                parent.move_child(name_label, -1)   # 移到最后（最上面）
            if is_instance_valid(status_icon):
                parent.move_child(status_icon, -1)  # 移到最后（最上面）
            
            # 打印节点层级信息
            print("节点层级顺序:")
            for i in range(parent.get_child_count()):
                var child = parent.get_child(i)
                print("  ", i, ": ", child.name, " (", child.get_class(), ")")
    
    # 调试信息：打印当前字体大小
    print("卡片就绪: ", event_title, " - 标题字体大小: ", title_font_size, ", 人物名称字体大小: ", name_font_size)

# 内容属性更新
func set_event_title(text: String):
    event_title = text
    if is_instance_valid(title_label):
        title_label.text = text

func set_character_name(text: String):
    character_name = text
    if is_instance_valid(name_label):
        name_label.text = text

func set_event_status(status: String):
    event_status = status
    if is_instance_valid(status_icon):
        if status == "new":
            status_icon.texture = new_status_texture
        else:
            status_icon.texture = dealing_status_texture

func set_character_texture(texture: Texture2D):
    _original_texture = texture
    character_texture = texture
    
    if is_instance_valid(character_image):
        if region_enabled and texture:
            _apply_texture_region()
        else:
            character_image.texture = texture
            # 确保使用正确的stretch_mode
            character_image.expand_mode = 3  # EXPAND_IGNORE_SIZE
            character_image.stretch_mode = 4  # STRETCH_KEEP_ASPECT_CONTAINED
            
            # 确保CharacterImage保持在最底层
            var parent = character_image.get_parent()
            if parent:
                # 将角色图像移到最底层
                parent.move_child(character_image, 0)
                # 将其他节点移到上层
                if is_instance_valid(title_label) and title_label.get_parent() == parent:
                    parent.move_child(title_label, -1)
                if is_instance_valid(name_label) and name_label.get_parent() == parent:
                    parent.move_child(name_label, -1)
                if is_instance_valid(status_icon) and status_icon.get_parent() == parent:
                    parent.move_child(status_icon, -1)

# 区域裁剪属性更新
func set_region_enabled(enabled: bool):
    region_enabled = enabled
    if _original_texture:
        if region_enabled:
            _apply_texture_region()
        else:
            character_image.texture = _original_texture

func set_region_y_position(position: float):
    region_y_position = position
    if region_enabled and _original_texture:
        _apply_texture_region()

func set_region_height(height: float):
    region_height = height
    if region_enabled and _original_texture:
        _apply_texture_region()

# 处理区域裁剪的方法
func _apply_texture_region():
    if not _original_texture or not is_instance_valid(character_image):
        return
        
    var atlas = AtlasTexture.new()
    atlas.atlas = _original_texture
    
    # 计算裁剪区域
    var original_size = _original_texture.get_size()
    var region_y = original_size.y * region_y_position
    var region_h = original_size.y * region_height
    
    # 确保区域不超出纹理边界
    region_h = min(region_h, original_size.y - region_y)
    
    atlas.region = Rect2(0, region_y, original_size.x, region_h)
    character_image.texture = atlas
    
    # 确保使用正确的stretch_mode
    character_image.expand_mode = 3  # EXPAND_IGNORE_SIZE
    character_image.stretch_mode = 4  # STRETCH_KEEP_ASPECT_CONTAINED
    
    # 确保CharacterImage保持在最底层
    var parent = character_image.get_parent()
    if parent:
        # 将角色图像移到最底层
        parent.move_child(character_image, 0)
        # 将其他节点移到上层
        if is_instance_valid(title_label) and title_label.get_parent() == parent:
            parent.move_child(title_label, -1)
        if is_instance_valid(name_label) and name_label.get_parent() == parent:
            parent.move_child(name_label, -1)
        if is_instance_valid(status_icon) and status_icon.get_parent() == parent:
            parent.move_child(status_icon, -1)

# 样式属性更新
func set_border_color(color: Color):
    border_color = color
    _apply_style()

func set_background_color(color: Color):
    background_color = color
    _apply_style()

func set_corner_radius(radius: int):
    corner_radius = radius
    _apply_style()

func set_border_width(width: int):
    border_width = width
    _apply_style()

# 字体大小属性更新
func set_title_font_size(size: int):
    title_font_size = size
    if is_instance_valid(title_label):
        title_label.add_theme_font_size_override("font_size", size)

func set_name_font_size(size: int):
    name_font_size = size
    if is_instance_valid(name_label):
        name_label.add_theme_font_size_override("font_size", size)

# 应用内容属性
func _apply_content():
    set_event_title(event_title)
    set_character_name(character_name)
    set_event_status(event_status)
    
    # 保存并应用纹理，处理区域裁剪
    if character_texture:
        _original_texture = character_texture
        set_character_texture(character_texture)
    
    # 应用字体大小
    set_title_font_size(title_font_size)
    set_name_font_size(name_font_size)

# 应用样式
func _apply_style():
    # 创建StyleBoxFlat
    var style = StyleBoxFlat.new()
    
    # 设置背景颜色
    style.bg_color = background_color
    
    # 其他样式设置不变
    style.border_color = border_color
    style.border_width_left = border_width
    style.border_width_top = border_width
    style.border_width_right = border_width
    style.border_width_bottom = border_width
    style.corner_radius_top_left = corner_radius
    style.corner_radius_top_right = corner_radius
    style.corner_radius_bottom_left = corner_radius
    style.corner_radius_bottom_right = corner_radius
    
    # 应用样式
    add_theme_stylebox_override("panel", style)

# 点击事件处理
func _on_gui_input(event):
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            # 左键点击发出信号
            card_clicked.emit()

# 获取卡片类型
func get_card_type() -> String:
    return "character" 