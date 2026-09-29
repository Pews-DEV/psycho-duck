extends Node
## Efeitos sonoros: Sfx.play(&"shoot"). Os arquivos ficam em res://assets/audio/sfx/<nome>.wav
## (gerados por tools/make_sfx.py; troque o .wav mantendo o nome para usar um som próprio).

const DIR := "res://assets/audio/sfx/"
const NAMES: Array[StringName] = [
	&"shoot", &"jump", &"land", &"player_hurt", &"player_death",
	&"enemy_hit", &"crit_hit", &"enemy_death", &"elite_death", &"enemy_shoot",
	&"sniper_charge", &"sniper_shot", &"skimmer_warn", &"orb_drop", &"puddle",
	&"carrier_spawn", &"boss_appear", &"boss_attack", &"boss_death",
	&"soul_pickup", &"heal_pickup", &"pole_laser", &"pole_build",
	&"ui_hover", &"ui_click", &"card_pick", &"buy", &"deny", &"reroll", &"door",
	&"wave_start", &"wave_clear", &"arena_grow", &"skin_unlock", &"game_over",
]
const VOICES := 16
## O mesmo som não toca de novo antes deste intervalo (evita estouro com muitos acertos).
const MIN_INTERVAL := 0.045

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var _last_played := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for sound in NAMES:
		var path := DIR + String(sound) + ".wav"
		if ResourceLoader.exists(path):
			_streams[sound] = load(path)
	for i in VOICES:
		var player := AudioStreamPlayer.new()
		player.bus = Settings.SFX_BUS
		add_child(player)
		_players.append(player)


## Toca um som. `pitch_variation` sorteia o tom em ±variação para não soar repetitivo.
func play(sound: StringName, volume_db := 0.0, pitch_variation := 0.06, pitch := 1.0) -> void:
	var stream: AudioStream = _streams.get(sound)
	if stream == null:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_played.get(sound, -1.0) < MIN_INTERVAL:
		return
	_last_played[sound] = now
	var player := _players[_next]
	_next = (_next + 1) % VOICES
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch * (1.0 + randf_range(-pitch_variation, pitch_variation))
	player.play()
