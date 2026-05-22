extends EnemyBase

@export var hand_clone_scene: PackedScene
@export var flour_scene: PackedScene

@export var clone_speed: float = 700.0
@export var clone_lifetime: float = 0.5

@export var clone_count: int = 10
@export var clone_spacing: float = 40.0

@export var attack_range: float = 400.0
@export var attack_cooldown : float = 3.0

@export var gravity: float = 900.0

@export var damage_cooldown : float = 0.8

@onready var defeat_sfx: AudioStreamPlayer2D = $Defeat
@onready var hit_sfx: AudioStreamPlayer2D = $Hit


@onready var telegraph_sfx = $HandTelegraph
@onready var attack_sfx = $HandAttack
@onready var idle_sfx = $HandIdle
@onready var hurt_sfx: AudioStreamPlayer2D = $HandHurt

var can_take_damage := true
const WORLD_SCALE := 3.0

var attack_executed := false
signal boss_defeated

func _ready() -> void:
	super._ready()
	AudioPlayer._play_music_boss()

	scale *= WORLD_SCALE

	set_state(State.IDLE)

func _physics_process(delta: float) -> void:
	print(state_animations[current_state])

	if not is_on_floor():
		velocity.y += gravity * delta

	update_state_machine()

	move_and_slide()

func play_animation() -> void:
	match current_state:
		State.HIT:
			if sprite.animation != "hit":
				sprite.play("hit")

		_:
			if sprite.animation != "idle":
				sprite.play("idle")

func idle() -> void:
	if can_see_player():
		set_state(State.CHASE)

func chase() -> void:
	if not idle_sfx.playing:
		idle_sfx.play()

	var player := get_player()

	if player == null:
		velocity.x = 0
		return

	var dir : int = sign(player.global_position.x - global_position.x)

	face_direction(dir)

	velocity.x = dir * stats.move_speed

	var dx : float = abs(player.global_position.x - global_position.x)

	if dx <= attack_range and can_attack:
		can_attack = false

		velocity.x = 0

		if idle_sfx.playing:
			idle_sfx.stop()

		if not telegraph_sfx.playing:
			telegraph_sfx.play()

		await telegraph_sfx.finished

		if not attack_sfx.playing:
			attack_sfx.play()

		set_state(State.ATTACK)


func attack() -> void:
	velocity.x = 0

	if attack_executed:
		return

	attack_executed = true

	var player := get_player()

	if player != null:
		await spawn_clone_barrage(player)

	attack_executed = false

	set_state(State.CHASE)

	await get_tree().create_timer(attack_cooldown).timeout

	can_attack = true

func spawn_clone_barrage(player : Node2D) -> void:
	var direction : int = sign(player.global_position.x - global_position.x)

	if direction == 0:
		direction = 1

	var offset := clone_spacing

	for i in range(clone_count):
		spawn_attack_clone(direction, offset)

		offset += clone_spacing

		# wait before spawning next clone
		await get_tree().create_timer(0.12).timeout

func spawn_attack_clone(direction : int, offset : float) -> void:
	if hand_clone_scene == null:
		return

	var clone = hand_clone_scene.instantiate()

	get_parent().add_child(clone)

	# progressively farther outward
	clone.global_position = global_position + Vector2(direction * offset, 0)

	clone.scale = scale * 1

	var clone_sprite : AnimatedSprite2D = clone.get_node_or_null("AnimatedSprite2D")

	if clone_sprite:
		clone_sprite.flip_h = direction < 0

	# despawn clone
	var tween := clone.create_tween()

	tween.tween_interval(clone_lifetime)

	if clone_sprite:
		tween.tween_property(
			clone_sprite,
			"modulate:a",
			0.0,
			0.1
		)

	tween.tween_callback(clone.queue_free)

func hit(damage: int) -> void:
	print("Boss taking damage")

	if is_dead:
		return

	if idle_sfx.playing:
		idle_sfx.stop()

	if telegraph_sfx.playing:
		telegraph_sfx.stop()

	if not hurt_sfx.playing:
		hurt_sfx.play()

	set_state(State.HIT)

	velocity.x = 0

	health -= damage

	if health <= 0:
		defeat_sfx.play()
		defeat()
		return

func defeat() -> void:
	set_state(State.DEFEAT)
	print("defeat")
	if is_dead:
		return

	is_dead = true

	velocity = Vector2.ZERO

	set_state(State.DEFEAT)

	sprite.modulate.a = 0.0

	#set_collisions_enabled(false)
	boss_defeated.emit()
	AudioPlayer._play_music_level()
	fade_out_and_free()

func take_damage(damage: int, _knockback: Vector2 = Vector2.ZERO) -> void:
	if not can_take_damage:
		return

	can_take_damage = false
	
	hit_sfx.play()
	hit(damage)

	await get_tree().create_timer(damage_cooldown).timeout

	can_take_damage = true

func _on_animation_finished() -> void:
	match current_state:
		State.HIT:
			can_attack = true
			set_state(State.CHASE)

func set_collisions_enabled(enabled : bool) -> void:
	# main body collision
	$CollisionShape2D.disabled = !enabled

	# hurtbox
	if hurtbox:
		hurtbox.monitoring = enabled
		hurtbox.monitorable = enabled

	# hitbox
	if hitbox:
		hitbox.monitoring = enabled
		hitbox.monitorable = enabled

func fade_out_and_free() -> void:
	var tween := create_tween()

	tween.tween_property(sprite, "modulate:a", 0.0, 0.4)

	await tween.finished

	var flour = flour_scene.instantiate()
	flour.scale *= 0.1
	get_parent().add_child(flour)
	flour.global_position = global_position


	queue_free()
