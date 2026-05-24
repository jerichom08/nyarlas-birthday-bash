extends Node2D

@onready var panel: Panel = $Panel
@onready var name_label: Label = $Panel/NameLabel
@onready var dialogue_label: Label = $Panel/DialogueLabel
@onready var next_button: Button = $Panel/NextButton
@onready var portrait: TextureRect = $Panel/Portrait
@onready var choice_box: VBoxContainer = $Panel/ChoiceBox
@onready var yes_button_1: Button = $Panel/ChoiceBox/YesButton1
@onready var yes_button_2: Button = $Panel/ChoiceBox/YesButton2
@onready var timer: Timer = $Timer

@onready var interaction_label: Label = $JoanArea2D/InteractionLabel


@export var joan_icon: Texture2D
@export var lilith_icon: Texture2D

var player_near_joan: bool = false
var dialogue_started: bool = false
var dialogue_index: int = 0
var current_text_finished: bool = false
var choices_done: bool = false
var current_dialogue: Array
var choosing: bool = false

var dialogue_completed: bool = false

var dialogue_array: Array = [
{"speaker": "Joan", "text": ". L-Lilith… is that you?", "icon": "joan"},
{"speaker": "Lilith", "text": ". Joan? What are you doing he—", "icon": "lilith"},
{"speaker": "Joan", "text": ". How could you just vanish without a trace like that? Did I mean so little to you? Did that kiss—", "icon": "joan"},
{"speaker": "Lilith", "text": ". Oh, Joan, that’s… I thought you would’ve—", "icon": "lilith"},
{"speaker": "Joan", "text": ". Forgotten you? After everything? There hasn’t been a single day I didn’t spend looking for you.", "icon": "joan"},
{"speaker": "Joan", "text": ". Everyone said you were dead, but I refused to believe them.", "icon": "joan"},
{"speaker": "Joan", "text": ". I refused to believe that my Lily would go down just like that.", "icon": "joan"},
{"speaker": "Lilith", "text": ". After that fatal blow you received shielding me, I could feel your soul slipping away. I was so scared, Joan, I—", "icon": "lilith"},
{"speaker": "Joan", "text": ". I know, my Lilith. Please, shed no more tears. It hurts me to see you make that face.", "icon": "joan"},
{"speaker": "Joan", "text": ". I can still taste the salt from your tears that fell onto my face, and hear your trembling voice calling my name.", "icon": "joan"},
{"speaker": "Lilith", "text": ". ...", "icon": "lilith"},
{"speaker": "Joan", "text": ". And the forbidden spell you used to resurrect me which made you lose most your powers.", "icon": "joan"},
{"speaker": "Lilith", "text": ". Joan… you are the hero loved by all. You had such a bright future ahead of you, so much glory waiting for you. You were my light.", "icon": "lilith"},
{"speaker": "Lilith", "text": ". And I…", "icon": "lilith"},
{"speaker": "Lilith", "text": ". I don’t deserve to stand by your side.", "icon": "lilith"},
{"speaker": "Lilith", "text": ". I’ve brought you nothing but misfortune. I thought it would be best for me to disappear and—", "icon": "lilith"},
{"speaker": "Joan", "text": ". And yet you still came back to the place where we last saw each other. I knew what we had was real.", "icon": "joan"},
{"speaker": "Lilith", "text": ". No, Joan, you don’t understand. I already led you to your death once. Forget we ever met… and be happy.", "icon": "lilith"},
{"speaker": "Joan", "text": ". Forget? Be happy? You are my happiness.", "icon": "joan"},
{"speaker": "Joan", "text": ". Being a hero means nothing to me if I can’t even be with the one person who matters the most to me.", "icon": "joan"},
{"speaker": "Joan", "text": ". So my sweet Lily, don’t blame yourself...", "icon": "joan"},
{"speaker": "Joan", "text": ". Even if I could go back in time, I would still sacrifice myself for you a hundred times over...", "icon": "joan"},
{"speaker": "Joan", "text": ". Not out of my duty as a hero, nor as some act of kindness—but because it’s you. Only you.", "icon": "joan"},
{"speaker": "Lilith", "text": ". Those sweet words of yours… please, don’t tempt me. I might lose what little reason I have left.", "icon": "lilith"},
{"speaker": "Joan", "text": ". Then I’m afraid I must continue.", "icon": "joan"},
{"speaker": "Joan", "text": ". Throughout our adventure… this is what kept me going.", "icon": "joan"},
{"speaker": "Joan", "text": ". I wanted to properly propose to you once everything was over.", "icon": "joan"},
{"speaker": "Lilith", "text": ". !!", "icon": "lilith"},
{"speaker": "Joan", "text": ". So, Lilith… will you marry me?", "icon": "joan"}
]

var after_choice_dialogue: Array = [
	{"speaker": "Lilith", "text": ". Joan! Of course...", "icon": "lilith"},
	{"speaker": "Lilith", "text": ". If this is a dream, I'm afraid I'd never want to wake up", "icon": "lilith"},
	{"speaker": "Joan", "text": ". I’ll make you the happiest you’ll ever be. I love you.", "icon": "joan"},
	{"speaker": "Lilith", "text": ". I love you too, my Joan.", "icon": "lilith"},
	{"speaker": "Lilith", "text": ". Here, take my warping scroll...", "icon": "lilith"},
	{"speaker": "Lilith", "text": ". This shall take you to my tower.", "icon": "lilith"},
	{"speaker": "Lilith", "text": ". I’m still in the middle of an errand. I’ll meet you home once it’s all sorted.", "icon": "lilith"},
	{"speaker": "Joan", "text": ". I’ll wait for you, my love. Be safe.", "icon": "joan"}
]


func _ready() -> void:
	interaction_label.visible = false
	$JoanArea2D/Joan.play("default")
	$scroll.hide()
	$hearts.hide()

	current_dialogue = dialogue_array
	panel.hide()
	choice_box.hide()

	timer.timeout.connect(_on_timer_timeout)
	next_button.pressed.connect(_on_next_button_pressed)
	yes_button_1.pressed.connect(_on_yes_pressed)
	yes_button_2.pressed.connect(_on_yes_pressed)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interaction"):
		if dialogue_completed:
			return

		if not dialogue_started and player_near_joan:
			start_dialogue()
		elif dialogue_started and not choice_box.visible:
			_advance_dialogue() 


func start_dialogue() -> void:
	interaction_label.visible = false
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(false)

	dialogue_started = true
	dialogue_index = 0
	choices_done = false
	choosing = false
	current_dialogue = dialogue_array

	panel.show()
	show_dialogue()


func show_dialogue() -> void:
	timer.stop()

	if dialogue_index >= current_dialogue.size():
		if not choices_done:
			show_choices()
		else:
			hide_dialogue()
		return

	var current_line = current_dialogue[dialogue_index]

	panel.show()
	name_label.show()
	dialogue_label.show()
	portrait.show()
	next_button.show()
	choice_box.hide()

	name_label.text = current_line["speaker"]
	dialogue_label.text = current_line["text"]
	dialogue_label.visible_characters = 0
	current_text_finished = false

	if current_line["icon"] == "joan":
		portrait.texture = joan_icon
	elif current_line["icon"] == "lilith":
		portrait.texture = lilith_icon

	play_line_effect(current_line["text"])

	timer.start()


func play_line_effect(text: String) -> void:
	if text == ". Throughout our adventure… this is what kept me going.":
		$ring.play("default")
		$animate.play("ring up")
		$woa.play()

	if text == ". I’ll make you the happiest you’ll ever be. I love you.":
		$hearts.show()
		$hearts.play("default")
		$luv.play()
		hide_hearts_later()

	if text == ". Here, take my warping scroll...":
		$scroll.show()
		$scroll.play("default")
		$animate.play("scroll give")
		$give.play()


func hide_hearts_later() -> void:
	await get_tree().create_timer(3.0).timeout
	$hearts.hide()


func _on_timer_timeout() -> void:
	dialogue_label.visible_characters += 1

	if dialogue_label.visible_ratio >= 1:
		timer.stop()
		current_text_finished = true
	else:
		timer.start()


func _on_next_button_pressed() -> void:
	_advance_dialogue()


func _advance_dialogue() -> void:
	$click.play()

	if current_text_finished:
		dialogue_index += 1
		show_dialogue()
	else:
		dialogue_label.visible_characters = -1
		timer.stop()
		current_text_finished = true


func show_choices() -> void:
	timer.stop()

	panel.show()
	next_button.hide()
	choice_box.show()

	name_label.text = "Lilith"
	portrait.texture = lilith_icon
	dialogue_label.text = ""
	dialogue_label.visible_characters = -1

	yes_button_1.text = "Yes"
	yes_button_2.text = "YES (in caps bc no doom in this yuri)"

	yes_button_1.disabled = false
	yes_button_2.disabled = false


func _on_yes_pressed() -> void:
	if choosing:
		return

	choosing = true
	$click.play()

	yes_button_1.disabled = true
	yes_button_2.disabled = true
	choice_box.hide()
	next_button.hide()

	$animate.play("ring give")
	$give.play()
	await get_tree().create_timer(0.5).timeout

	choices_done = true
	current_dialogue = after_choice_dialogue
	dialogue_index = 0
	current_text_finished = false

	show_dialogue()


func hide_dialogue() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(true)
	
	dialogue_completed = true
	player_near_joan = false
	interaction_label.visible = false
	
	SceneTransition.s = true
	timer.stop()
	panel.hide()
	choice_box.hide()
	dialogue_started = false
	$HiddenPlatform.show_platform()


func _on_dialogue_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not dialogue_completed:
		player_near_joan = true
		interaction_label.visible = true

func _on_dialogue_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_near_joan = false
		interaction_label.visible = false


func _on_nextscene(body: Node2D) -> void:
	SceneTransition.change_scene_to("res://scenes/levels/tutorial/scene_4.5.tscn")
	#SceneTransition.change_scene_to("res://scenes/levels/level_4/scene_6.tscn")
