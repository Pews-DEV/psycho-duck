class_name ShopCategory
extends Resource
## Categoria de melhorias que a loja libera numa onda (a primeira é o poste de luz).
## Para criar uma nova: um .tres com as cartas e a onda, e adicionar na lista `categories` da Shop.

@export var id: StringName
@export var display_name := ""
## A loja passa a oferecer estas cartas a partir desta onda.
@export var unlock_wave := 10
@export var offers: Array[UpgradeData] = []
## Carta mostrada garantida no primeiro slot enquanto estiver disponível (ex.: construir o poste).
@export var featured: UpgradeData
