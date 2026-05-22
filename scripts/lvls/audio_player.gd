extends AudioStreamPlayer

const level_music = preload("res://assets/sounds temp/level sounds/bgm.wav")
const boss_music = preload("res://assets/sounds temp/level sounds/boss.mp3")

#var default_volume := -20.0

func _play_music(music: AudioStream, volume := -20.0) -> void:
	if stream == music and playing:
		return

	stream = music
	volume_db = volume
	play()

func transition_music(new_music: AudioStream, target_volume := -20.0, fade_time := 1.0) -> void:
	var tween := create_tween()

	# fade out current music
	tween.tween_property(self, "volume_db", -80.0, fade_time)

	await tween.finished

	stop()

	stream = new_music
	play()

	volume_db = -80.0

	# fade in new music
	var tween_in := create_tween()

	tween_in.tween_property(self, "volume_db", target_volume, fade_time)

func _play_music_level():
	transition_music(level_music, -20)

func _play_music_boss():
	transition_music(boss_music, -10)
