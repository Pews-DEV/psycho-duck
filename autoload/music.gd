extends AudioStreamPlayer
## Música de fundo contínua entre cenas (o loop vem das opções de importação do .ogg).

const THEME := preload("res://assets/audio/music/psycho_duck_theme.ogg")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	stream = THEME
	bus = Settings.MUSIC_BUS
	volume_db = -10.0
	play()

