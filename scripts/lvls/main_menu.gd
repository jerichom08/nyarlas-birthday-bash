extends Node2D


func _ready() -> void:
	$Lilith.play("default")
	AudioPlayer._play_music_level()
func _on_start_pressed() -> void:
	$click.play()
	await get_tree().create_timer(0.2).timeout
	$SceneTransition.change_scene_to("res://scenes/levels/tutorial/room.tscn")

func _on_options_pressed() -> void:
	$click.play()
	await get_tree().create_timer(0.2).timeout
	$SceneTransition.change_scene_to("res://scenes/options.tscn")

func _on_level_select_pressed() -> void:
	$click.play()
	await get_tree().create_timer(0.2).timeout
	$SceneTransition.change_scene_to("res://scenes/LevelSelect.tscn")
