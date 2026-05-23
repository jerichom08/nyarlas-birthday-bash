extends Control

@onready var music_slider: HSlider = $MusicSlider
@onready var sfx_slider: HSlider = $SFXSlider

func _ready() -> void:
	music_slider.value = db_to_linear(
		AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
	)
	sfx_slider.value = db_to_linear(
		AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))
	)
	
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)

func _on_music_slider_changed(value: float) -> void:
	var bus_idx := AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))

func _on_sfx_slider_changed(value: float) -> void:
	var bus_idx := AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
