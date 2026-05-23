extends Node2D

func _on_return_pressed() -> void:
	$click.play()
	await get_tree().create_timer(0.2).timeout
	$SceneTransition.change_scene_to("res://scenes/main_menu.tscn")
