class_name SnakeGame
extends Node2D

const GRID_SIZE: int = 32
const MOVE_DELAY_BASE: float = 0.18
const MIN_MOVE_DELAY: float = 0.06
const MIN_GRID_CELLS: int = 12
const BACKGROUND_COLOR: Color = Color(0.04, 0.04, 0.08)
const GRID_LINE_COLOR: Color = Color(0.08, 0.08, 0.14)
const SNAKE_HEAD_COLOR: Color = Color(0.9, 0.9, 0.2)
const SNAKE_BODY_COLOR: Color = Color(0.28, 0.82, 0.3)
const APPLE_COLOR: Color = Color(0.94, 0.2, 0.22)
const ACCELERATION_KEY: int = KEY_SPACE
const ACCELERATION_FACTOR: float = 0.55

var grid_columns: int = 0
var grid_rows: int = 0
var snake: Array[Vector2i] = []
var direction: Vector2i = Vector2i.RIGHT
var pending_direction: Vector2i = Vector2i.RIGHT
var move_timer: float = 0.0
var apple_position: Vector2i = Vector2i.ZERO
var score: int = 0

var _head_texture: Texture2D = null
var _body_texture: Texture2D = null
var _apple_texture: Texture2D = null

@onready var score_label: Label = $ScoreLabel

func _ready() -> void:
	set_process(true)
	randomize()
	var viewport_size: Vector2 = get_viewport_rect().size
	grid_columns = max(MIN_GRID_CELLS, int(viewport_size.x / GRID_SIZE))
	grid_rows = max(MIN_GRID_CELLS, int(viewport_size.y / GRID_SIZE))
	_head_texture = load("res://assets/sprites/snake_head.png")
	_body_texture = load("res://assets/sprites/snake_body.png")
	_apple_texture = load("res://assets/sprites/apple.png")
	score_label.add_theme_font_size_override("font_size", 24)
	get_tree().get_root().size_changed.connect(_on_viewport_size_changed)
	_reset_game()

func _process(delta: float) -> void:
	_handle_input()
	move_timer += delta
	var base_delay: float = max(MIN_MOVE_DELAY, MOVE_DELAY_BASE - score * 0.008)
	var current_delay: float = _apply_acceleration(base_delay)
	while move_timer >= current_delay:
		move_timer -= current_delay
		_advance_snake()
		base_delay = max(MIN_MOVE_DELAY, MOVE_DELAY_BASE - score * 0.008)
		current_delay = _apply_acceleration(base_delay)

func _handle_input() -> void:
	if Input.is_action_just_pressed("ui_up") and direction != Vector2i.DOWN:
		pending_direction = Vector2i.UP
	if Input.is_action_just_pressed("ui_down") and direction != Vector2i.UP:
		pending_direction = Vector2i.DOWN
	if Input.is_action_just_pressed("ui_left") and direction != Vector2i.RIGHT:
		pending_direction = Vector2i.LEFT
	if Input.is_action_just_pressed("ui_right") and direction != Vector2i.LEFT:
		pending_direction = Vector2i.RIGHT

func _is_accelerating() -> bool:
	return Input.is_key_pressed(ACCELERATION_KEY)

func _apply_acceleration(delay: float) -> float:
	if _is_accelerating():
		return max(MIN_MOVE_DELAY, delay * ACCELERATION_FACTOR)
	return delay

func _advance_snake() -> void:
	direction = pending_direction
	var head_position: Vector2i = snake[0]
	var next_x: int = (head_position.x + direction.x + grid_columns) % grid_columns
	var next_y: int = (head_position.y + direction.y + grid_rows) % grid_rows
	var next_head: Vector2i = Vector2i(next_x, next_y)
	var will_grow: bool = next_head == apple_position
	if not will_grow:
		snake.pop_back()
	if snake.has(next_head):
		_reset_game()
		return
	snake.insert(0, next_head)
	if will_grow:
		score += 1
		_spawn_apple()
		_refresh_score_label()
	queue_redraw()

func _spawn_apple() -> void:
	var attempts: int = 0
	var new_position: Vector2i = Vector2i.ZERO
	while true:
		new_position = Vector2i(randi() % grid_columns, randi() % grid_rows)
		attempts += 1
		if not snake.has(new_position) or attempts >= grid_columns * grid_rows:
			break
	apple_position = new_position
	queue_redraw()

func _reset_game() -> void:
	var center_x: int = grid_columns / 2
	var center_y: int = grid_rows / 2
	snake = [Vector2i(center_x, center_y), Vector2i(center_x - 1, center_y), Vector2i(center_x - 2, center_y)]
	direction = Vector2i.RIGHT
	pending_direction = direction
	move_timer = 0.0
	score = 0
	_spawn_apple()
	_refresh_score_label()
	queue_redraw()

func _on_viewport_size_changed() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	grid_columns = max(MIN_GRID_CELLS, int(viewport_size.x / GRID_SIZE))
	grid_rows = max(MIN_GRID_CELLS, int(viewport_size.y / GRID_SIZE))
	queue_redraw()

func _refresh_score_label() -> void:
	var score_text: String = "Score: %d" % score
	score_label.text = score_text

func _get_head_angle() -> float:
	if direction == Vector2i.DOWN:
		return PI / 2.0
	elif direction == Vector2i.LEFT:
		return PI
	elif direction == Vector2i.UP:
		return -PI / 2.0
	return 0.0  # RIGHT is the sprite's default facing direction

func _draw() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), BACKGROUND_COLOR, true)
	var grid_rect_size: Vector2 = Vector2(GRID_SIZE, GRID_SIZE)
	for column_index in range(grid_columns + 1):
		var line_start: Vector2 = Vector2(column_index * GRID_SIZE, 0)
		var line_end: Vector2 = Vector2(column_index * GRID_SIZE, grid_rows * GRID_SIZE)
		draw_line(line_start, line_end, GRID_LINE_COLOR, 1.0)
	for row_index in range(grid_rows + 1):
		var line_start: Vector2 = Vector2(0, row_index * GRID_SIZE)
		var line_end: Vector2 = Vector2(grid_columns * GRID_SIZE, row_index * GRID_SIZE)
		draw_line(line_start, line_end, GRID_LINE_COLOR, 1.0)
	# Draw apple
	var apple_rect: Rect2 = Rect2(apple_position * GRID_SIZE, grid_rect_size)
	if _apple_texture:
		draw_texture_rect(_apple_texture, apple_rect, false)
	else:
		draw_rect(apple_rect, APPLE_COLOR)
	# Draw snake body segments (all segments except head)
	for segment_index in range(1, snake.size()):
		var segment: Vector2i = snake[segment_index]
		var segment_rect: Rect2 = Rect2(segment * GRID_SIZE, grid_rect_size)
		if _body_texture:
			draw_texture_rect(_body_texture, segment_rect, false)
		else:
			draw_rect(segment_rect, SNAKE_BODY_COLOR)
	# Draw snake head with rotation based on movement direction
	if snake.size() > 0:
		var head: Vector2i = snake[0]
		if _head_texture:
			var half_size: Vector2 = grid_rect_size / 2.0
			var head_center: Vector2 = Vector2(head * GRID_SIZE) + half_size
			draw_set_transform(head_center, _get_head_angle(), Vector2.ONE)
			draw_texture_rect(_head_texture, Rect2(-half_size, grid_rect_size), false)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_rect(Rect2(head * GRID_SIZE, grid_rect_size), SNAKE_HEAD_COLOR)
