class_name View
extends RefCounted
## Medidas da tela (resolução base 480×270, escalada 3× na janela e 4× em 1080p).
## O chão fica em y = 156, a 44 px da borda de baixo; o resto é céu.

const SIZE := Vector2(480, 270)
const HALF_WIDTH := 240.0
## Centro vertical da câmera (fixo): a tela vai de TOP a TOP + SIZE.y.
const CAMERA_Y := 65.0
const TOP := CAMERA_Y - 135.0
