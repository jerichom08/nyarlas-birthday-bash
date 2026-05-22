extends EnemyBase

@export var frog_spit_attack: PackedScene
@export var frog_tongue_attack: PackedScene
@export var spider_scene: PackedScene
@export var egg_scene: PackedScene

@export var damage_cooldown : float = 2

@onready var tongue_sfx : AudioStreamPlayer2D = $TongueSound
@onready var spit_sfx: AudioStreamPlayer2D = $SpitSound
@onready var snore_sfx: AudioStreamPlayer2D = $SnoreSound
@onready var ribbit_sfx: AudioStreamPlayer2D = $RibbitSound
@onready var slime_sfx: AudioStreamPlayer2D = $SlimeSound
@onready var hit_sfx: AudioStreamPlayer2D = $HitSound
@onready var heal_sfx: AudioStreamPlayer2D = $HealSound
@onready var defeat_sfx: AudioStreamPlayer2D = $Defeat




var active_spiders: Array[Node2D] = []
var defeat_count: int = 0
var spiders_spawned : bool = false
var attack_executed : bool = false
var is_invincible: bool = false
var ribbiting: bool = false
var getting_hit: bool = false
const WORLD_SCALE = 3.0

signal boss_defeated

func set_state(new_state: State) -> void:
	if current_state == new_state:
		return

	current_state = new_state

	match new_state:
		State.HIT:
			hit_sfx.play()

	if new_state == State.ATTACK:
		attack_executed = false
	else:
		current_attack = AttackType.NONE

	play_animation()

func _ready() -> void:
	AudioPlayer._play_music_boss()
	super._ready()
	set_state(State.REST)
	snore_sfx.play(1)
	sprite.frame_changed.connect(_on_sprite_frame_changed)

func _physics_process(_delta: float) -> void:
	print(state_animations[current_state])
	update_state_machine()
	move_and_slide()

func idle() -> void:
	set_state(State.IDLE)
	if can_see_player():
		set_state(State.CHASE)

func rest() -> void:
	#snore_sfx.play(1)
	set_state(State.REST)
	if can_see_player():
		snore_sfx.stop()
		set_state(State.CHASE)
		start_ribbit_loop()

func chase() -> void:
	set_state(State.CHASE)
	
	var player: Node2D = get_player()
	if player == null:
		velocity.x = 0
		return
	
	var dir : int = sign(player.global_position.x - global_position.x)
	face_direction(dir)
	
	var dx : int = abs(player.global_position.x - global_position.x)

	if can_attack and dx <= 400:
		velocity.x = 0
		start_attack(dx)
		return
	
	if should_turn_around():
		velocity.x = 0
	else:
		velocity.x = dir * stats.move_speed

func start_attack(dx: int) -> void:
	can_attack = false
	#attack_executed = false
	
	if dx > 300:
		set_attack(AttackType.HEAVY)
	else:
		set_attack(AttackType.LIGHT)
	
	set_state(State.ATTACK)

func hit(damage: int) -> void:
	getting_hit = true
	snore_sfx.stop()
	
	set_state(State.HIT)
	
	velocity.x = 0
	health = max(0, health - damage)
	
	if health == 0:
		defeat()

func defeat() -> void:
	defeat_sfx.play()
	hitbox.monitoring = false
	defeat_count += 1
	is_invincible = true
	if defeat_count == 1:
		sprite.play("defeat")
		await sprite.animation_finished
		await get_tree().create_timer(1.0).timeout
		heal(stats.max_health)
	else:
		set_state(State.DEFEAT)



func heal(hp: int) -> void:
	hurtbox.monitorable = false
	hitbox.monitoring = true
	heal_sfx.play(3.5)
	is_invincible = true
	if defeat_count > 0:
		spawn_spiders()
	
	health = min(stats.max_health, health + hp)
	set_state(State.HEAL)

func spawn_spiders() -> void:
	if spiders_spawned:
		return
	
	spiders_spawned = true
	for i in range(50):
		var spider = spider_scene.instantiate()
		get_parent().add_child(spider)
		spider.sprite.modulate.a = 0.0
		spider.set_state(State.IDLE)
		spider.fade_in()
		spider.face_direction(1)
		#spider.scale *= WORLD_SCALE
		
		# Slight random spread
		var offset := Vector2(randf_range(-100, 100), randf_range(0, 200))
		spider.global_position = global_position + offset
		
		active_spiders.append(spider)

func clear_spiders() -> void:
	for spider in active_spiders:
		if is_instance_valid(spider):
			spider.fade_out_and_free()
	
	active_spiders.clear()
	spiders_spawned = false

func take_damage(damage: int, _knockback: Vector2) -> void:
	if is_invincible:
		return

	is_invincible = true

	hit(damage)

	await get_tree().create_timer(damage_cooldown).timeout

	if current_state != State.DEFEAT and current_state != State.HEAL:
		is_invincible = false

func spawn_light_attack() -> void:
	spit_sfx.play(1)
	var light_attack = frog_spit_attack.instantiate()
	get_parent().add_child(light_attack)
	
	light_attack.scale *= WORLD_SCALE
	light_attack.z_index = 10
	
	light_attack.global_position = light_spawn.global_position
	
	if facing_direction < 0:
		light_attack.scale.x *= -1

func spawn_heavy_attack() -> void:
	tongue_sfx.play(1.1)
	var heavy_attack = frog_tongue_attack.instantiate()
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
		
		State.HIT:
			getting_hit = false
			set_state(State.CHASE)

		State.HEAL:
			clear_spiders()
			is_invincible = false
			hurtbox.monitorable = true
			set_state(State.CHASE)

		State.DEFEAT:
			is_invincible = false
			#print(defeat_count)
			if defeat_count > 2:
				#await get_tree().create_timer(5.0).timeout
				#queue_free()
				AudioPlayer._play_music_level()
				boss_defeated.emit()
				fade_out_and_free()

func _on_sprite_frame_changed() -> void:
	if sprite.animation == "chase" and !getting_hit:
		
		if sprite.frame == 1:
			slime_sfx.play(1)

		if sprite.frame == 5:
			slime_sfx.play(2)
	if attack_executed:
		return
	slime_sfx.stop()
	if current_attack == AttackType.LIGHT:
		if sprite.animation == "light_attack" and sprite.frame == 7:
			attack_executed = true
			spawn_light_attack()
	
	elif current_attack == AttackType.HEAVY:
		if sprite.animation == "heavy_attack" and sprite.frame == 2:
			attack_executed = true
			spawn_heavy_attack()

func reset_attack_cooldown() -> void:
	await get_tree().create_timer(stats.attack_cooldown).timeout
	can_attack = true

func fade_out_and_free() -> void:
	var tween := create_tween()

	tween.tween_property(sprite, "modulate:a", 0.0, 0.4)

	await tween.finished

	var egg = egg_scene.instantiate()
	get_parent().add_child(egg)
	#print("Frog Pos: ",global_position)
	egg.global_position = global_position

	#await get_tree().create_timer(1.0).timeout

	queue_free()

func start_ribbit_loop() -> void:
	if ribbiting:
		return

	ribbiting = true

	while current_state == State.CHASE:
		ribbit_sfx.play()

		await get_tree().create_timer(
			randf_range(2.0, 5.0)
		).timeout

	ribbiting = false
