extends CharacterBody2D

const WIN_SIZE = Vector2(64, 64)
const AUTO_MOVE_SPEED = 100.0
const USER_MOVE_SPEED = 175.0

@onready var body = $Body
@onready var animation_tree = $AnimationTree
@onready var select_new_direction: Timer = $SelectNewDirection

var playback
var direction: Vector2
var screen: Vector2
var is_dragging: bool = false
var win_pos: Vector2
var mouse_pos: Vector2
var mouse_in_pos: Vector2
var vel: Vector2
var is_user_moving = false

var auto_direction: Vector2


func _ready():
	playback = animation_tree.get("parameters/playback")
	screen = DisplayServer.screen_get_size()
	get_tree().get_root().size = WIN_SIZE
	select_new_direction.timeout.connect(_on_select_new_direction_timeout)
	select_new_direction.set_wait_time(4.0)
	select_new_direction.start()
	win_pos = get_tree().get_root().position
	
	print("screen.x = ", screen.x)
	print("screen.y = ", screen.y)
	print("screen.x - WIN_SIZE.x = ", screen.x - WIN_SIZE.x)
	print("screen.y - WIN_SIZE.y = ", screen.y - WIN_SIZE.y)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			is_dragging = true
			mouse_in_pos = get_viewport().get_mouse_position()
		else:
			is_dragging = false
		
	if event is InputEventMouseMotion and is_dragging:
		mouse_pos = get_viewport().get_mouse_position()
		win_pos = Vector2(get_tree().get_root().position) + mouse_pos - mouse_in_pos 
	
	if event is InputEventKey and event.is_action_pressed("ui_cancel"):
		get_tree().quit()


func _physics_process(delta):      
	
	is_user_moving = false
	direction = Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down")).normalized()
	if direction != Vector2.ZERO:
		is_user_moving = true
		#print(direction)
		vel = direction * delta * USER_MOVE_SPEED
		auto_direction = Vector2.ZERO
	elif !is_dragging and !is_user_moving:
		#print(select_new_direction.wait_time)
		#print(select_new_direction.time_left)
		#print(is_dragging)
			
		vel = auto_direction * AUTO_MOVE_SPEED * delta
	
	if vel.x > 0 and body.flip_h:
		body.flip_h = false
	elif vel.x < 0 and !body.flip_h:
		body.flip_h = true
	
	#print(auto_direction)
	#print(vel)
	#print(get_tree().get_root().position)
	
	win_pos += vel
	win_pos.x = clamp(win_pos.x, 0, screen.x - WIN_SIZE.x)
	win_pos.y = clamp(win_pos.y, 0, screen.y - WIN_SIZE.y)
	
	get_tree().get_root().position = win_pos
	pick_new_state()
	vel = Vector2.ZERO


var walking: bool = false
func _on_select_new_direction_timeout() -> void:
	# 刚启动第一次走动时长固定为计时器初始时长(4s)
	if !walking:
		# 设置下次待机时长
		select_new_direction.set_wait_time(randf_range(5, 10))
		# 先随机一个方向分量
		var nx = randf_range(-1.0, 1.0)
		var ny = randf_range(-1.0, 1.0)
		# 使用当前浮点位置 win_pos 做边缘判断（不用root.position，因为返回的）
		var cur = win_pos

		# 左侧靠近：强制 X 分量为向右（0.1..1）
		if cur.x < 100.0:
			nx = randf_range(0.1, 1.0)
		# 右侧靠近：强制 X 分量为向左（-1..-0.1）
		elif cur.x > screen.x - WIN_SIZE.x - 100.0:
			nx = randf_range(-1.0, -0.1)

		# 顶部靠近：强制 Y 分量为向下（0.1..1）
		if cur.y < 100.0:
			ny = randf_range(0.1, 1.0)
		# 底部靠近：强制 Y 分量为向上（-1..-0.1）
		elif cur.y > screen.y - WIN_SIZE.y - 100.0:
			ny = randf_range(-1.0, -0.1)

		# 组合方向并归一化（如果方向为 0，会退回到一个随机方向）
		auto_direction = Vector2(nx, ny)
		if auto_direction == Vector2.ZERO:
			auto_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		else:
			auto_direction = auto_direction.normalized()

		walking = true
	else:
		# 设置下次走动时长
		select_new_direction.set_wait_time(randf_range(3, 5))
		auto_direction = Vector2.ZERO
		walking = false


func pick_new_state():
	if is_dragging:
		playback.travel("fly")
	elif vel != Vector2.ZERO:
		playback.travel("walk")
	else:
		playback.travel("idle")
