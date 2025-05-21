# 事件对象池，用于优化事件创建和重用
class_name EventPool
extends Node

# 对象池
var pool = {}

# 获取或创建对象
func get_object(object_class, object_id, create_func):
	var pool_key = "%s_%s" % [object_class, object_id]
	
	if pool.has(pool_key):
		return pool[pool_key]
	
	var new_object = create_func.call()
	pool[pool_key] = new_object
	return new_object

# 回收对象
func recycle_object(object_class, object_id):
	var pool_key = "%s_%s" % [object_class, object_id]
	
	if not pool.has(pool_key):
		return
	
	pool.erase(pool_key)

# 清空对象池
func clear_pool():
	pool.clear() 
