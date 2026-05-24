extends CanvasLayer

var cursor_sprite: Sprite2D

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	layer = 100
	cursor_sprite = get_node("CursorSprite")
	cursor_sprite.offset = Vector2(5, 5.5)
	
func _process(_delta: float) -> void:
	offset = get_viewport().get_mouse_position()
