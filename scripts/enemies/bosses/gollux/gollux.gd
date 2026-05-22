extends EnemyBase

@export var gollux_heavy_attack: PackedScene
@export var gollux_light_attack: PackedScene
@export var sugar_scene: PackedScene

@export var damage_cooldown : float = 2

@onready var light_attack_sfx : AudioStreamPlayer2D = $GolluxLightAttack
@onready var heavy_attack_sfx : AudioStreamPlayer2D = $GolluxHeavyAttack
@onready var defeat_sfx: AudioStreamPlayer2D = $Defeat
@onready var hit_sfx: AudioStreamPlayer2D = $Hit

signal boss_defeated

const WORLD_SCALE := 3.0
var can_take_damage: bool = true

func _ready() -> void:
	AudioPlayer._play_music_boss()
	super._ready()
	scale *= WORLD_SCALE
	
func _physics_process(_delta: float) -> void:
	print(state_animations[current_state])
	update_state_machine()
	move_and_slide()
	
func idle() -> void:
	if can_see_player():
		set_state(State.CHASE)

func chase() -> void:
	var player: Node2D = get_player()

	if player == null:
		velocity.x = 0
		return

	var dir : int = sign(
		player.global_position.x - global_position.x
	)

	face_direction(dir)

	var dx : float = abs(
		player.global_position.x - global_position.x
	)

	if can_attack:
		if dx <= 100:
			velocity.x = 0
			start_attack(AttackType.LIGHT)
			return

		if dx > 100 and dx <= 200:
			velocity.x = 0
			start_attack(AttackType.HEAVY)
			return

	if should_turn_around():
		velocity.x = 0
	else:
		velocity.x = dir * stats.move_speed

func hit(damage: int) -> void:
	set_state(State.HIT)
	health = max(0, health - damage)
	if health == 0:
		defeat_sfx.play()
		set_state(State.DEFEAT)

func take_damage(damage: int, _knockback: Vector2 = Vector2.ZERO) -> void:
	if not can_take_damage:
		return

	can_take_damage = false
	
	hit_sfx.play()
	hit(damage)

	await get_tree().create_timer(damage_cooldown).timeout

	can_take_damage = true


func start_attack(attack_type: AttackType) -> void:
	can_attack = false

	current_attack = attack_type

	match attack_type:
		AttackType.LIGHT:
			light_attack_sfx.play()

		AttackType.HEAVY:
			heavy_attack_sfx.play()

	set_state(State.ATTACK)

func spawn_light_attack() -> void:
	var light_attack = gollux_light_attack.instantiate()
	get_parent().add_child(light_attack)
	
	light_attack.scale *= WORLD_SCALE
	light_attack.z_index = 10
	
	light_attack.global_position = light_spawn.global_position
	
	if facing_direction < 0:
		light_attack.scale.x *= -1

func spawn_heavy_attack() -> void:
	var heavy_attack = gollux_heavy_attack.instantiate()
	get_parent().add_child(heavy_attack)
	
	heavy_attack.scale *= WORLD_SCALE
	heavy_attack.z_index = 10
	
	heavy_attack.global_position = heavy_spawn.global_position
	
	if facing_direction < 0:
		heavy_attack.scale.x *= -1

func _on_animated_sprite_2d_animation_finished() -> void:
	match current_state:
		State.ATTACK:
			set_state(State.CHASE)
			can_attack = true
		State.HIT:
			set_state(State.CHASE)
			can_attack = true
		State.DEFEAT:
			boss_defeated.emit()
			AudioPlayer._play_music_level()
			fade_out_and_free()

func _on_animated_sprite_2d_frame_changed() -> void:
	if current_state != State.ATTACK:
		return
	match current_attack:
		AttackType.LIGHT:
			if sprite.frame == 5:
				spawn_light_attack()
		AttackType.HEAVY:
			if sprite.frame == 5:
				spawn_heavy_attack()
		
func fade_out_and_free() -> void:
	var tween := create_tween()

	tween.tween_property(sprite, "modulate:a", 0.0, 0.4)

	await tween.finished

	var sugar = sugar_scene.instantiate()
	sugar.scale *= 0.1
	get_parent().add_child(sugar)
	#print("Frog Pos: ",global_position)
	sugar.global_position = global_position

	#await get_tree().create_timer(1.0).timeout

	queue_free()
