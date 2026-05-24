extends Area2D

@export var fall_speed := 150.0
@export var hover_height := 8.0
@export var hover_speed := 2.0
@export var collect_time := 0.2
@export var hud_scale := Vector2(0.5, 0.5)

@export var floor_y := 525

@onready var sprite: Sprite2D = $Sprite2D
@onready var success_sfx: AudioStreamPlayer2D = $Success
@onready var drop_sfx: AudioStreamPlayer2D = $Drop

var landed := false
var hover_time := 0.0
var collected := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	# detach drop sound so it survives queue_free
	var drop := drop_sfx

	drop.reparent(get_tree().current_scene)
	drop.global_position = global_position
	drop.play()

	drop.finished.connect(drop.queue_free)


func _process(delta: float) -> void:
	if not landed:
		global_position.y += fall_speed * delta

		if global_position.y >= floor_y:
			global_position.y = floor_y
			landed = true

		return

	if collected:
		return

	hover_time += delta

	global_position.y = (
		floor_y
		+ sin(hover_time * hover_speed) * hover_height
	)


func _on_body_entered(body: Node2D) -> void:
	if collected:
		return

	if not body.is_in_group("player"):
		return

	collected = true
	collect(body)


func collect(player: Node2D) -> void:
	IngredientManager.add_ingredient(sprite.texture, hud_scale)

	# detach collect sound so it survives queue_free
	var success := success_sfx

	success.reparent(get_tree().current_scene)
	success.global_position = global_position
	success.play()

	success.finished.connect(success.queue_free)

	monitoring = false

	var tween := create_tween()

	tween.set_parallel(true)

	tween.tween_property(
		self,
		"global_position",
		player.global_position,
		collect_time
	)

	tween.tween_property(
		sprite,
		"scale",
		Vector2.ZERO,
		collect_time
	)

	tween.tween_property(
		sprite,
		"modulate:a",
		0.0,
		collect_time
	)

	tween.chain().tween_callback(queue_free)
