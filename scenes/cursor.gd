extends Node2D

var cursor_sprite: Sprite2D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	cursor_sprite = get_node("CursorSprite")
	cursor_sprite.offset = Vector2(5, 5.5)
	
func _process(_delta: float) -> void:
	global_position = get_global_mouse_position()
