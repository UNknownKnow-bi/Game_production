class_name CoinsDisplay
extends Control

# 金币显示UI组件
# 显示当前金币数量，响应AttributeManager的金币变化

@onready var coin_amount_label: Label = $HBoxContainer/CoinAmount
@onready var coin_icon: TextureRect = $HBoxContainer/CoinIcon

func _ready():
	print("CoinsDisplay: 初始化金币显示组件")
	
	# 连接AttributeManager的金币变化信号
	if AttributeManager:
		AttributeManager.coins_changed.connect(_on_coins_changed)
		AttributeManager.attributes_loaded.connect(_on_attributes_loaded)
		
		# 初始化显示
		_update_coins_display(AttributeManager.get_coins())
		print("CoinsDisplay: 已连接AttributeManager信号")
	else:
		print("CoinsDisplay: 警告 - AttributeManager未找到")

# 更新金币显示
func _update_coins_display(amount: int):
	if coin_amount_label:
		coin_amount_label.text = str(amount)
		print("CoinsDisplay: 更新金币显示为 ", amount)
		
		# 根据金币数量调整颜色
		if amount <= 0:
			coin_amount_label.modulate = Color.RED
		elif amount <= 2:
			coin_amount_label.modulate = Color.ORANGE
		else:
			coin_amount_label.modulate = Color(1, 0.843, 0, 1)  # 金色

# 金币变化信号处理
func _on_coins_changed(old_value: int, new_value: int):
	print("CoinsDisplay: 接收到金币变化信号 - ", old_value, " -> ", new_value)
	_update_coins_display(new_value)
	
	# 播放变化动画
	_play_change_animation(old_value, new_value)

# 属性加载完成信号处理
func _on_attributes_loaded():
	print("CoinsDisplay: 属性加载完成，更新显示")
	if AttributeManager:
		_update_coins_display(AttributeManager.get_coins())

# 播放金币变化动画
func _play_change_animation(old_value: int, new_value: int):
	if not coin_amount_label:
		return
	
	# 创建缩放动画
	var tween = create_tween()
	tween.set_parallel(true)
	
	# 缩放效果
	tween.tween_property(coin_amount_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(coin_amount_label, "scale", Vector2(1.0, 1.0), 0.1).set_delay(0.1)
	
	# 颜色闪烁效果
	if new_value > old_value:
		# 增加金币 - 绿色闪烁
		tween.tween_property(coin_amount_label, "modulate", Color.GREEN, 0.1)
		tween.tween_property(coin_amount_label, "modulate", Color(1, 0.843, 0, 1), 0.3).set_delay(0.1)
	elif new_value < old_value:
		# 减少金币 - 红色闪烁
		tween.tween_property(coin_amount_label, "modulate", Color.RED, 0.1)
		tween.tween_property(coin_amount_label, "modulate", Color(1, 0.843, 0, 1), 0.3).set_delay(0.1)

# 手动刷新显示（用于调试或强制更新）
func refresh_display():
	if AttributeManager:
		_update_coins_display(AttributeManager.get_coins())

# 获取当前显示的金币数量
func get_displayed_coins() -> int:
	if coin_amount_label and coin_amount_label.text.is_valid_int():
		return coin_amount_label.text.to_int()
	return 0 