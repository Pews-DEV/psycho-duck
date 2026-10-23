extends Node
## Configurações do jogador, salvas em user://settings.cfg.

const PATH := "user://settings.cfg"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"

var master_volume := 0.8
var music_volume := 0.7
var sfx_volume := 0.8
var fullscreen := false
var screen_shake := true
var damage_numbers := true
## "en" ou "pt_BR"; vazio na primeira vez = segue o idioma do sistema.
var language := ""

const LANGUAGES: Array[String] = ["en", "pt_BR"]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus in [MUSIC_BUS, SFX_BUS]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, &"Master")
	load_settings()
	if language == "":
		language = "pt_BR" if OS.get_locale_language() == "pt" else "en"
	apply()


func apply() -> void:
	TranslationServer.set_locale(language)
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
	AudioServer.set_bus_mute(0, master_volume <= 0.0)
	_set_bus(MUSIC_BUS, music_volume)
	_set_bus(SFX_BUS, sfx_volume)
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(mode)


func _set_bus(bus: StringName, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_volume_db(index, linear_to_db(volume))
	AudioServer.set_bus_mute(index, volume <= 0.0)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("game", "screen_shake", screen_shake)
	config.set_value("game", "damage_numbers", damage_numbers)
	config.set_value("game", "language", language)
	config.save(PATH)


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return
	master_volume = config.get_value("audio", "master", master_volume)
	music_volume = config.get_value("audio", "music", music_volume)
	sfx_volume = config.get_value("audio", "sfx", sfx_volume)
	fullscreen = config.get_value("video", "fullscreen", fullscreen)
	screen_shake = config.get_value("game", "screen_shake", screen_shake)
	damage_numbers = config.get_value("game", "damage_numbers", damage_numbers)
	language = config.get_value("game", "language", language)
