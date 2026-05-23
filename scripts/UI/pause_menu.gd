extends CanvasLayer

@onready var pause_panel: Control = $PausePanel/MarginContainer/VBoxContainer
@onready var restart_button = $PausePanel/MarginContainer/VBoxContainer/Restart
@onready var options_button = $PausePanel/MarginContainer/VBoxContainer/Options
@onready var main_menu_button = $PausePanel/MarginContainer/VBoxContainer/MainMenu
@onready var options_panel: Control = $OptionsPanel
@onready var return_button = $OptionsPanel/Return

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	restart_button.process_mode = Node.PROCESS_MODE_ALWAYS
	main_menu_button.process_mode = Node.PROCESS_MODE_ALWAYS

	restart_button.pressed.connect(_on_restart_level_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	options_button.pressed.connect(_on_options_pressed)
	return_button.pressed.connect(_on_return_pressed)

func _input(event):
	var current_scene = get_tree().current_scene
	
	if current_scene == null:
		return
	
	if current_scene.scene_file_path == "res://scenes/main_menu.tscn" or current_scene.scene_file_path == "res://scenes/LevelSelect.tscn" or current_scene.scene_file_path == "res://scenes/Fin.tscn" or current_scene.scene_file_path == "res://scenes/levels/tutorial/room.tscn" or current_scene.scene_file_path == "res://scenes/options.tscn":
		return
	
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	get_tree().paused = !get_tree().paused
	visible = get_tree().paused
	if not get_tree().paused:
		_on_return_pressed()

func _on_options_pressed():
	pause_panel.visible = false
	options_panel.visible = true
	
func _on_return_pressed():
	options_panel.visible = false
	pause_panel.visible = true

func _on_restart_level_pressed():
	print("Restart button clicked")
	get_tree().paused = false
	visible = false
	_on_return_pressed()
	var player = get_tree().get_first_node_in_group("player")
	
	if player and player.has_method("reset_room"):
		player.reset_room()

func _on_main_menu_pressed():
	get_tree().paused = false
	visible = false
	_on_return_pressed()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
