extends EnemyBase

@export var minotaur_heavy_attack: PackedScene
@export var minotaur_light_attack: PackedScene
@export var milk_scene: PackedScene

@onready var light_attack_sfx: AudioStreamPlayer2D = $MinotaurLightAttack
@onready var heavy_attack_sfx: AudioStreamPlayer2D = $MinotaurHeavyAttack
@onready var defeat_sfx: AudioStreamPlayer2D = $Defeat
@onready var hit_sfx: AudioStreamPlayer2D = $Hit

@onready var landing_marker = $"../MinotaurLandingPoint"

@export var landing_position : Vector2

signal boss_defeated

var active := false
var skeletons_remaining := 3
var jumping_in := false
var jump_start : Vector2
var jump_target : Vector2
var jump_timer := 0.0
var jump_duration := 1.2

var damage_cooldown : float = 1.5
var is_taking_damage : bool = false
var attack_executed: bool = false
const WORLD_SCALE: float = 3.0

func _ready() -> void:
	AudioPlayer._play_music_boss()
	scale *= WORLD_SCALE
	super._ready()
	landing_position = landing_marker.global_position
	sprite.frame_changed.connect(_on_sprite_frame_changed)

func _physics_process(_delta: float) -> void:
	if jumping_in:
		update_jump(_delta)
		return
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
	
	var dir : int = sign(player.global_position.x - global_position.x)
	face_direction(dir)
	
	var dx : int = abs(player.global_position.x - global_position.x)

	if can_attack and dx <= 100:
		velocity.x = 0
		start_attack()
		return
	
	if should_turn_around():
		velocity.x = 0
	else:
		velocity.x = dir * stats.move_speed

func hit(_damage : int) -> void:
	health = max(0, health - _damage)

#func defeat() -> void:
	#pass

func heal(_hp : int) -> void:
	pass

func take_damage(_damage: int, _knockback: Vector2 = Vector2.ZERO) -> void:
	if is_taking_damage:
		return

	is_taking_damage = true

	velocity.x = 0

	health = max(0, health - _damage)

	if health <= 0:
		boss_defeated.emit()
		AudioPlayer._play_music_level()
		defeat_sfx.play()
		set_state(State.DEFEAT)
	else:
		hit_sfx.play()
		set_state(State.HIT)

	set_collisions_enabled(false)

	await get_tree().create_timer(damage_cooldown).timeout

	set_collisions_enabled(true)

	is_taking_damage = false

func start_attack() -> void:
	can_attack = false
	
	if randi_range(0, 1) == 0:
		set_attack(AttackType.LIGHT)
		light_attack_sfx.play()
	else:
		set_attack(AttackType.HEAVY)
		heavy_attack_sfx.play()
		#await heavy_attack_sfx.finished

	set_state(State.ATTACK)

func _on_sprite_frame_changed() -> void:
	if attack_executed:
		return
	if current_attack == AttackType.LIGHT:
		if sprite.animation == "light_attack" and sprite.frame == 3:
			attack_executed = true
			spawn_light_attack()
	
	elif current_attack == AttackType.HEAVY:
		if sprite.animation == "heavy_attack" and sprite.frame == 1:
			attack_executed = true
			spawn_heavy_attack()

func spawn_light_attack() -> void:
	var light_attack = minotaur_light_attack.instantiate()
	get_parent().add_child(light_attack)
	
	light_attack.scale *= WORLD_SCALE
	light_attack.z_index = 10
	
	light_attack.global_position = light_spawn.global_position
	
	if facing_direction < 0:
		light_attack.scale.x *= -1
	
func spawn_heavy_attack() -> void:
	var heavy_attack = minotaur_heavy_attack.instantiate()
	get_parent().add_child(heavy_attack)
	
	heavy_attack.scale *= WORLD_SCALE
	heavy_attack.z_index = 10
	
	heavy_attack.global_position = heavy_spawn.global_position
	
	if facing_direction < 0:
		heavy_attack.scale.x *= -1
func _on_animation_finished() -> void:
	match current_state:
		State.ATTACK:
			reset_attack_cooldown()
			set_state(State.CHASE)
			attack_executed = false
		State.HIT:
			reset_attack_cooldown()
			set_state(State.CHASE)
			attack_executed = false
		State.DEFEAT:
			fade_out_and_free()
func reset_attack_cooldown() -> void:
	await get_tree().create_timer(stats.attack_cooldown).timeout
	can_attack = true

func fade_out_and_free() -> void:
	var tween := create_tween()

	tween.tween_property(sprite, "modulate:a", 0.0, 0.4)

	await tween.finished

	var milk = milk_scene.instantiate()
	milk.scale *= 0.1
	get_parent().add_child(milk)
	#print("Frog Pos: ",global_position)
	milk.global_position = global_position

	#await get_tree().create_timer(1.0).timeout

	queue_free()

#func _on_skeleton_defeated() -> void:
	#skeletons_remaining -= 1
#
	#if skeletons_remaining <= 0:
		#start_jump_in()

func start_jump_in() -> void:
	jumping_in = true

	jump_start = global_position
	jump_target = landing_position

	jump_timer = 0.0

	sprite.play("idle")

func update_jump(delta: float) -> void:
	jump_timer += delta

	var t : float = clamp(jump_timer / jump_duration, 0.0, 1.0)

	# horizontal interpolation
	var pos := jump_start.lerp(jump_target, t)

	# jump arc
	var height := 250.0
	pos.y -= sin(t * PI) * height

	global_position = pos

	if t >= 1.0:
		jumping_in = false
		active = true

		set_state(State.CHASE)

func _on_skeleton_knight_skeleton_defeated() -> void:
	skeletons_remaining -= 1

	if skeletons_remaining <= 0:
		start_jump_in()

func set_collisions_enabled(enabled: bool) -> void:
	if hurtbox:
		hurtbox.set_deferred("monitoring", enabled)
		hurtbox.set_deferred("monitorable", enabled)

	if hitbox:
		hitbox.set_deferred("monitoring", enabled)
		hitbox.set_deferred("monitorable", enabled)
