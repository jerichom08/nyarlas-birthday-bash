extends Node2D



func _on_lv_1_pressed() -> void:
	$click.play()
	await get_tree().create_timer(0.2).timeout
	$SceneTransition.change_scene_to("res://scenes/levels/level_1/scene_1.tscn")


func _on_lv_2_pressed() -> void:
	$click.play()
	await get_tree().create_timer(0.2).timeout
	$SceneTransition.change_scene_to("res://scenes/levels/level_2/scene_1.tscn")


func _on_lv_3_pressed() -> void:
	$click.play()
	await get_tree().create_timer(0.2).timeout
	$SceneTransition.change_scene_to("res://scenes/levels/level_3/scene_1.tscn")


func _on_lv_4_pressed() -> void:
	$click.play()
	await get_tree().create_timer(0.2).timeout
	$SceneTransition.change_scene_to("res://scenes/levels/level_4/scene_1.tscn")


func _on_return_pressed() -> void:
	$click.play()
	await get_tree().create_timer(0.2).timeout
	$SceneTransition.change_scene_to("res://scenes/main_menu.tscn")


func _on_ready() -> void:
	if has_node("fin"):
		$fin.play()
	for child in get_children():
		if child is AnimatedSprite2D:
			child.play()
