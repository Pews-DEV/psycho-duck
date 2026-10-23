extends AudioStreamPlayer
## Música de fundo contínua entre cenas (o loop vem das opções de importação do .ogg).
## Durante o chefe, a mesma faixa toca mais rápida e mais grave (set_boss_mode).

const THEME := preload("res://assets/audio/music/psycho_duck_theme.ogg")
## Andamento da faixa com o chefe vivo.
const BOSS_TEMPO := 1.15
## Tom com o chefe vivo (abaixo de 1 = mais grave), compensando a aceleração.
const BOSS_PITCH := 0.8

var _pitch_shift: AudioEffectPitchShift
var _boss_mode := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	stream = THEME
	bus = Settings.MUSIC_BUS
	volume_db = -10.0
	var bus_index := AudioServer.get_bus_index(Settings.MUSIC_BUS)
	_pitch_shift = AudioEffectPitchShift.new()
	AudioServer.add_bus_effect(bus_index, _pitch_shift)
	AudioServer.set_bus_effect_enabled(bus_index, AudioServer.get_bus_effect_count(bus_index) - 1, false)
	play()


func set_boss_mode(enabled: bool) -> void:
	if enabled == _boss_mode:
		return
	_boss_mode = enabled
	var bus_index := AudioServer.get_bus_index(Settings.MUSIC_BUS)
	var effect_index := AudioServer.get_bus_effect_count(bus_index) - 1
	if enabled:
		AudioServer.set_bus_effect_enabled(bus_index, effect_index, true)
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "pitch_scale", BOSS_TEMPO if enabled else 1.0, 1.2)
	tween.tween_method(func(value: float) -> void: _pitch_shift.pitch_scale = value,
		_pitch_shift.pitch_scale, BOSS_PITCH if enabled else 1.0, 1.2)
	if not enabled:
		tween.chain().tween_callback(AudioServer.set_bus_effect_enabled.bind(bus_index, effect_index, false))
