# Psycho Duck — Guia de design visual

Referência para qualquer arte, cena ou interface nova. Tudo aqui foi tirado do código e dos assets
atuais (versão 0.3.0, Godot 4.7). Quando algo novo fugir destas regras, atualize este arquivo junto.

Índice: [1. Direção](#1-direção-de-arte) · [2. Tela](#2-tela-e-escala) · [3. Paleta](#3-paleta) ·
[4. Pixel art](#4-regras-de-pixel-art) · [5. Personagens](#5-o-pato-e-acessórios) ·
[6. Inimigos](#6-inimigos) · [7. Cenário](#7-cenário-environment) · [8. Luz](#8-luz-e-atmosfera) ·
[9. Efeitos](#9-efeitos-e-feedback) · [10. Interface](#10-interface-ui) · [11. Áudio](#11-áudio) ·
[12. Organização](#12-organização-de-assets) · [13. Pendências](#13-inconsistências-e-pendências)

---

## 1. Direção de arte

- **Pixel art de baixa resolução**, sprites pequenos (8–46 px) com contorno escuro de 1 px.
- **Noite.** O céu é azul-arroxeado escuro, tudo é escurecido por um `CanvasModulate` e as fontes
  de luz (pato, casinha, poste, inimigos que brilham) "furam" a escuridão.
- **Leitura antes de detalhe:** cada inimigo tem uma cor dominante própria e uma silhueta distinta;
  ataques têm aviso (laser, "!", brilho).
- **Juice:** squash & stretch, flash branco ao tomar dano, partículas, tremor de tela, números de
  dano, botões e cartas que "pulam" no hover.
- Tom: fofo e um pouco absurdo (pato com pistola, insetos, cartola). Nada de gore.

## 2. Tela e escala

| Item | Valor | Onde |
|---|---|---|
| Resolução base | **480 × 270** | `project.godot` |
| Janela padrão | 1440 × 810 (3×); 1080p = 4× | `project.godot` |
| Stretch | `canvas_items` | `project.godot` |
| Filtro de textura | **Nearest** (`default_texture_filter=0`) | `project.godot` |
| Renderer | GL Compatibility (web + desktop) | `project.godot` |
| Cor de fundo (clear) | `#2e222f` | `project.godot` |
| Câmera | y fixo em 65, segue o pato só no x, posição arredondada | `scripts/view.gd`, `scenes/game/shake_camera.gd` |
| Topo da tela (mundo) | y = −70 | `View.TOP` |
| Chão (grama) | **y = 156** (44 px acima da borda de baixo) | `Arena.ground_y`, `Enemy.GROUND_Y` |
| Grade | **16 px** | `Arena.TILE` |

Regras:
- Desenhe tudo em 1×, na resolução base. Não use sprites em alta resolução reduzidos.
- Posições de câmera e mira são arredondadas para evitar tremido de subpixel; faça o mesmo em
  qualquer coisa que siga outro objeto.
- Ampliação de arte só em múltiplos inteiros (cartas 2×, título 2×, pato do menu 1,5× é a exceção atual).
- As constantes de tela ficam em `View` (`scripts/view.gd`); use-as em vez de números soltos.

## 3. Paleta

A paleta oficial é a **[Resurrect 64](https://lospec.com/palette-list/resurrect-64)**. Todos os
sprites usam só cores dela. Nomes abaixo são os usados em `tools/make_sprites.py`.

### 3.1 Cores-base do jogo

| Papel | Hex | Nome | Uso |
|---|---|---|---|
| Contorno / tinta | `#2e222f` | OUTLINE | Contorno de todo sprite, fundo de painéis, contorno de texto, clear color |
| Escuro neutro | `#3e3546` | DARK | Metal, cartola, propulsores |
| Cinza | `#625565` | GREY | Brilho de metal escuro |
| Céu / fundo do ícone | `#323353` | — | Céu da partida, fundo do ícone, sombra do pato |
| Asas / texto suave | `#c7dcd0` | WING | Asas de insetos, texto secundário (MUTED), borda de barras |
| Aço | `#9babb2` | STEEL | Espinhos, hélices |
| Branco | `#ffffff` | WHITE | Brilhos de 1 px, ícones de carta |
| Amarelo pato | `#f9c22b` | YELLOW | Corpo do pato, rainha, título |
| Dourado (acento) | `#fbb954` | GOLD | **Cor de destaque da UI**, hover, tiro do pato, barra do chefe, banners |
| Laranja | `#fb6b1d` | — | Bico/pés do pato |
| Laranja-mel | `#f79617` | ORANGE | Abelha, chamas |
| Vermelho | `#e83b3b` | RED | **Dano / perigo**: números de dano, vida, laser de mira, preço caro, olhos |
| Vermelho fundo | `#ae2334` | DEEP_RED | Sombra de olhos |
| Lâmpada | `#fbff86` | LAMP | Lâmpadas, faróis, vaga-lume |

### 3.2 Rampas por material (já usadas)

| Material | Escuro → claro |
|---|---|
| Azul (Skimmer) | `#484a77` → `#4d65b4` → `#4d9be6` |
| Roxo (Sniper) | `#6b3e75` → `#905ea9` → `#a884f3` |
| Rosa (Bomber) | `#cf657f` → `#ed8099` / núcleo `#f04f78` → `#fca790` |
| Marrom (Carrier, casinha) | `#45293f` → `#9e4539` → `#cd683d` → `#e6904e` |
| Ciano (Drone) | `#0eaf9b` → `#30e1b9` → `#8ff8e2` |
| Verde-lima (vaga-lume) | `#d5e04b` → `#fbff86` |
| Verde (grama, pato verde) | `#239063` → `#1ebc73` |
| Pergaminho (cartas) | `#7a4841` → `#ad7757` → `#c09473` |

### 3.3 Cores de código (UI, efeitos e luz)

Estas ficam em constantes nos scripts. As marcadas com ⚠ **não são da Resurrect 64** (ver §13).

| Constante | Hex | Arquivo |
|---|---|---|
| Interface (`UiStyle.*`) | ver §10 | `scenes/ui/ui_style.gd` |
| Mira ⚠ | `#fbf5ef` | `scenes/ui/crosshair.gd` |
| `Fx.DAMAGE_COLOR` | `#e83b3b` | `scripts/fx.gd` |
| `Fx.CRIT_COLOR` | `#fbb954` | idem |
| Tiro do pato / crítico ⚠ | `#fbb954` / `#fff4c2` | `scenes/projectiles/bullet.gd` |
| Tiro inimigo | `#f04f78` | `scenes/projectiles/enemy_bullet.gd` |
| Orbe e poça ⚠ | `#f06ac8` | `energy_orb.gd`, `hazard_puddle.gd` |
| Railgun (Sniper/rainha) ⚠ | `#b4f0ff` | `sniper_enemy.gd`, `boss_enemy.gd` |
| Laser de mira / aviso "!" | `#e83b3b` | `scenes/enemies/enemy.gd` |
| Cura ⚠ / alma | `#5ac54f` / `#8fd3ff` | `scenes/pickups/pickup.gd` |
| Selo de raridade comum / rara / épica | `#9babb2` / `#4d9be6` / `#a884f3` | `scenes/ui/upgrade_card.gd` |
| Texto das cartas / contorno do nome | `#45293f` / `#c09473` | idem |
| Interior da loja | parede `#45293f`, balcão `#e6904e` `#cd683d` `#9e4539` `#6e2727` | `scenes/ui/shop.gd` |
| Fundo do menu | `#323353` (mesmo céu da partida) | `scenes/ui/menu.tscn` |
| Raios do menu | dourado `rgba(.62,.48,.2,.75)`, lilás `rgba(.5,.48,.56,.6)` | `scenes/ui/light_rays.gd` |
| Tinta elite | `Color(1.7, 0.5, 0.5)` (multiplica, passa de 1) | `scenes/enemies/enemy.gd` |
| Escuridão (CanvasModulate) | `rgb(0.56, 0.54, 0.72)` | `scenes/game/game.tscn` |

### 3.4 Semântica das cores (não quebrar)

- **Vermelho `#e83b3b` = perigo/dano.** Vida, dano recebido, laser de mira, elites, aviso do Skimmer, preço inalcançável, "resetar".
- **Dourado `#fbb954` = do jogador / positivo / selecionado.** Tiro do pato, hover, títulos, banners, item permanente, barra do chefe.
- **Rosa/magenta = projétil inimigo.** Tiros `#f04f78`, orbes e poças `#f06ac8`.
- **Ciano-claro `#b4f0ff` = tiro muito rápido (railgun).**
- **Azul-claro `#8fd3ff` = alma (moeda).** Verde = cura.
- Branco-creme `#fbf5ef` = texto e bordas neutras.

## 4. Regras de pixel art

Extraídas de `tools/make_sprites.py` e dos sprites originais:

1. **Só cores da Resurrect 64**, 2–9 cores por sprite (média 4–7).
2. **Contorno de 1 px `#2e222f`** em volta da forma inteira (vizinhança de 4, sem cantos diagonais).
3. Contorno nunca mais claro que o preenchimento; detalhes internos escuros (olhos, listras, boca) também usam `#2e222f`.
4. **Luz vindo de cima**: uma faixa/linha de brilho na parte de cima do corpo (tom mais claro da rampa), barriga/base no tom mais escuro. Sem pillow shading.
5. **Sem anti-aliasing e sem dithering** (sprites abaixo de 32 px).
6. Brilho especular de 1 px em branco/tom mais claro em olhos, lentes e orbes.
7. **Asas sempre em `#c7dcd0`** (padrão dos insetos), desenhadas atrás do corpo.
8. Olhos de inimigo: vermelho `#e83b3b` + `#ae2334` (malvados) ou só pixel `#2e222f` (fofos).
9. Sprites de lado olham **para a direita**; o código espelha com `flip_h`.
10. Sprites de frente podem ser simétricos (`mirror()`).
11. Origem: centro do sprite, exceto onde indicado (pato e poste usam os pés/base).
12. Fundo transparente, PNG RGBA, sem margem sobrando além de 0–1 px.

### Tamanhos de referência

| Categoria | Tamanho | Exemplos |
|---|---|---|
| Pato / skins | 12–14 × 14 | `Player.png` 14×14 |
| Inimigo pequeno | 11–15 × 10 | Drone 11×10, Bee 15×10 |
| Inimigo médio | 19–21 × 13–20 | Firefly, Sniper, Bomber, Skimmer |
| Inimigo grande | 34 × 21 | Carrier |
| Chefe | 46 × 38 | HornetQueen |
| Arma | 10 × 5 | Pistol |
| Acessório | 14–16 × 3–7 | glass, cartola |
| Prop alto | 13 × 46 | LightPole |
| Tile | 16 × 16 | Tileset |
| Ícone de carta | 28 × 19 | `assets/ui/upgrades/*` |

### Gerador de sprites

`python tools/make_sprites.py [pasta_preview]` regera inimigos novos, poste e ícone. Para um sprite
novo feito em código: adicione uma função em `make_sprites.py` seguindo a ordem
**formas → `outline()` → brilhos/detalhes por cima**, registre em `SPRITES` e gere a prancha de
preview (6× sobre `#323353`). Sprites desenhados à mão (Aseprite) também são bem-vindos — mesma paleta e regras.

## 5. O pato e acessórios

- `Player.png` 14×14: amarelo `#f9c22b`, bico/pés `#fb6b1d`, contorno `#2e222f`, sombra `#323353`.
- Skins (`data/skins/*.tres`, ordem em `GameState.SKINS`): **Duck** (`Player.png`), **Black Duck**
  (`black_duck.png`, corpo `#3e3546`, onda 10), **Green Duck** (`green_duck.png`, `#1ebc73`, onda 20).
  Skin nova: mesmo tamanho e mesmos pés na base, para os acessórios encaixarem.
- Sprite com origem nos pés: `Sprite.position = (0, 7)`, `offset = (0, -7)`.
- Pistola 10×5 a 8 px do centro, gira para o mouse e vira com `flip_v`.
- Acessórios (`data/items/*.tres`): Sprite2D filho do sprite do pato, `centered = false`,
  posição = `accessory_offset` relativo aos pés (cartola `(-8, -19)`), herda o material (pisca junto).
- Animação feita em código (sem spritesheet): pulo `scale (0.75, 1.3)`, aterrissagem `(1.3, 0.75)`,
  volta a 1 com lerp; caminhada = quique de 1,5 px; invulnerável = pisca alfa 0,35 a cada 0,06 s.
- Luz própria: `#ffe6b0`, raio 40, energia 0,55.

## 6. Inimigos

| Inimigo | Sprite | Cor dominante | Luz (`glow_color`) | Partícula de morte | Comportamento visual |
|---|---|---|---|---|---|
| Bee | 15×10 | laranja-mel | — | `#f2a83b` | gira para o pato, flash ao atirar |
| Firefly | 19×20 | lima | lima | lima | inclina conforme a velocidade |
| Skimmer | 21×13 | azul | — | `#c7dcd0` | voa rente ao chão; "!" vermelho na borda avisa |
| Sniper | 19×16 | roxo | — | ciano-claro | laser fraco → travado piscando → tiro; some com alfa e teleporta |
| Bomber | 19×16 | rosa | rosa | rosa | balança ao patrulhar; solta orbe que vira poça |
| Carrier | 34×21 | marrom | — | marrom | flash ao soltar drones |
| Drone | 11×10 | ciano | ciano | ciano | igual ao Firefly |
| Hornet Queen | 46×38 | amarelo/preto, coroa | dourado | dourado | 4 ataques, rail ciano-claro |

Regras:
- **Elite**: mesmo sprite, `self_modulate` × `(1.7, 0.5, 0.5)`, escala 1,3, partícula maior. Não faça sprite separado.
- Cada inimigo novo precisa de **uma cor dominante que nenhum outro usa** e de `death_color` combinando.
- `glow_color` só para quem "brilha" na história (vaga-lume, orbe, drone, chefe); a noite fica mais legível com poucas luzes.
- Telegrafar todo ataque perigoso (laser, "!", flash, pausa antes).
- `tint`/`sprite_scale` em `EnemyData` existem para placeholder; arte final deve vir com escala 1.
- z_index: inimigo 2.

## 7. Cenário (environment)

- **Tileset** `assets/sprites/environment/Tileset.png` (128×80 = 8×5 tiles de 16 px):
  grama `(3..5, 3)`, pedra `(2..6, 4)`, caixa `(6, 2)`. O tileset é montado em código (`Arena._make_tileset()`):
  grama e caixa têm colisão cheia; pedra é só visual.
- Chão: uma linha de grama + uma de pedra, alternando os tiles por coluna (`posmod`).
- **Plataformas finas**: faixa de 7 px do topo da linha de pedra (`region (32 + 16·i, 65, 16, 7)`),
  one-way, 4 px de colisão, camada física 7. Degraus a cada 24 px de altura (pulo ≈ 29 px).
- **Casinha/loja** `home-market.png` 76×57, centrada em x = 160, z −1, luz do letreiro `#ffb35c` raio 90.
- **Poste de luz** `LightPole.png` 13×46, nasce do chão (escala y 0 → 1 com TRANS_BACK), luz `#ffe6b0`.
- **Céu**: `ColorRect` `#323353` com z −10. Não há parallax nem fundo desenhado ainda.
- **Arena cresce** a cada 10 ondas: 24 → 30 → 38 → 46 colunas, centrada em x = 160; caixas nas bordas.
- Partículas do cenário: terra `#8a6a4f`, madeira `#c86a3d`, pedra `#c7dcd0`.
- Menu: mesma arena (sem casinha automática) ampliada 2×, raios girando atrás da casinha.

Para cenário novo: tiles de 16 px no mesmo Tileset (ou um novo de mesma grade), mesmo contorno,
paleta terrosa (marrons, verdes `#239063`/`#1ebc73`, cinzas-azulados). Lembre que tudo será
escurecido pelo `CanvasModulate`: teste a leitura **dentro do jogo**, não só no editor.

## 8. Luz e atmosfera

- `CanvasModulate` "Darkness" `rgb(0.56, 0.54, 0.72)` escurece e azula toda a cena da partida.
- Luzes: `Fx.make_light(cor, raio, energia)` → `PointLight2D` com a textura radial `assets/sprites/light.tres`
  (128 px, gradiente branco → 35% em 0,45 → 0). `texture_scale = raio·2/128`.

| Fonte | Cor | Raio | Energia |
|---|---|---|---|
| Pato | `#ffe6b0` | 40 | 0,55 |
| Letreiro da casinha | `#ffb35c` | 90 | 1,1 |
| Poste | `#ffe6b0` | 50 | 0,9 |
| Inimigo com glow | `glow_color` | 30 × escala | 0,9 |
| Orbe / poça | `#f06ac8` | 16 / 20 | 0,8 / 0,6 |
| Cura | `#5ac54f` | 12 | 0,7 |

- Luzes quentes (creme/laranja) = segurança; luzes frias/coloridas = inimigos e perigo.
- Almas não têm luz (são muitas). Evite luz em objetos numerosos.
- **Números de dano e mira** ficam na camada `Overlay` (grupo `fx_overlay`), fora do CanvasModulate, para não escurecer.

## 9. Efeitos e feedback

Tudo em `scripts/fx.gd`:

| Efeito | Como | Parâmetros padrão |
|---|---|---|
| Flash de dano | shader `assets/shaders/flash.gdshader`, material próprio por sprite (`Fx.flash_material()`) | branco, 0,12 s |
| Partículas | `Fx.burst(pai, pos, cor, qtd, vel)` — CPUParticles one-shot, rampa branco → cor → transparente, gravidade 160 | 14 partículas, 60 px/s, 0,5 s, z 40 |
| Número de dano | `Fx.damage_number()` — fonte 8 (crítico 10 com "!"), sobe 12 px e some | vermelho / dourado, contorno 3 `#2e222f`, z 50 |
| Tremor | `Fx.shake(tree, força)` — trauma decai 18/s, teto 6 | dano no pato 4, morte 6 |

Projéteis (desenhados em `_draw`, sem sprite): tiro do pato = ponto r 1,5 + rastro de 5 px a 45%;
tiro inimigo = círculo pulsante; orbe r 3,5 pulsando; poça = faixa de 3 px com bolhas.
z: poça 3, pickups 4, projéteis 5.

Respeite as opções do jogador: `Settings.damage_numbers` e `Settings.screen_shake`.

Movimento/tempo de UI recorrente: hover 0,08 s (escala 1,06), clique 0,94, fade de banner 0,2 → 1,0 → 0,4 s,
fade de cena 0,25 s, intro 0,6 s.

## 10. Interface (UI)

Tudo sai de **`UiStyle`** (`scenes/ui/ui_style.gd`). Tela nova = peças de lá; nada de cor,
tamanho de fonte ou StyleBox soltos no script da tela.

### Fonte
- **Silkscreen Regular**, tema global `assets/ui/theme.tres`.
- **Só tamanhos da grade da fonte:** `FONT_SMALL = 8` (quase tudo), `FONT_LARGE = 16` (títulos de
  painel, número da onda, faixa de aviso), `FONT_HUGE = 32`. Tamanhos como 7, 10, 12, 14 e 20
  deixam as letras tortas; não use.
- Altura da linha em 8 px: 11 px (o `UiStyle.label` usa `line_spacing = -2` em textos com quebra).
- Texto direto sobre o jogo leva contorno `INK` (`outline = true` no `UiStyle.label`); texto
  dentro de painel não leva.

### Paleta da interface (`UiStyle`, todas da Resurrect 64)
| Constante | Hex | Uso |
|---|---|---|
| `INK` | `#2e222f` | contornos, fundo de etiquetas e poços |
| `PLUM` | `#45293f` | trilho de barras, sombra de painel |
| `SURFACE` / `SURFACE_HI` | `#3e3546` / `#625565` | painel / filete, botão secundário |
| `LINE` / `STEEL` | `#7f708a` / `#9babb2` | texto desativado, selo "comum" |
| `TEXT` / `MUTED` | `#ffffff` / `#c7dcd0` | texto principal / secundário |
| `ACCENT` | `#fbb954` | títulos, foco, seleção |
| `GOLD` / `GOLD_HI` / `GOLD_LO` | `#f9c22b` / `#fbff86` / `#f79617` | botão principal |
| `DANGER` (+ `_HI`, `_LO`, `_DARK`) | `#e83b3b` | vida, perigo, botão destrutivo |
| `SOUL` / `RARE` / `EPIC` | `#8fd3ff` / `#4d9be6` / `#a884f3` | almas, raridades |

### Componentes
- **Molduras 9-slice em pixel art**, geradas em código e cacheadas: contorno de 1 px com cantos
  cortados, brilho de 1 px em cima e degrau de sombra embaixo.
  - `panel_box(borda)` — painel com sombra de 2 px.
  - `inset_box(anel)` — poço afundado (entradas da loja permanente).
  - `tag_box(cor)` — etiqueta pequena (preço, carteira, selo de raridade, "!").
- **Botão** (`PixelButton` / `UiStyle.button(texto, variante)`), altura padrão 20:
  - `PRIMARY` (dourado, texto escuro) — **uma por tela**, a ação principal.
  - `SECONDARY` (cinza-roxo) — o resto.
  - `DANGER` (vermelho) — ações que perdem algo (desistir, apagar).
  - Hover/foco: anel de 1 px fora do botão (dourado; branco no principal). Apertado: perde o degrau
    e o texto desce 2 px. **Sem escala no hover** (escala não inteira distorce os pixels).
  - Passar o mouse move o foco: só um botão aceso por vez, com mouse ou teclado.
- **Painel pronto:** `centered_panel(layer, largura, título, borda)` = fundo `DIM` + painel + cabeçalho
  (`header`: título 16 px dourado + filete).
- **Linha de resumo:** `stat_row(ícone, rótulo, valor, cor)` (pausa, fim de jogo).
- **Teclas:** `key_cap("R")` desenha uma tecla; `hint_row(["1-4", "COMPRAR", "R", "TROCAR"])` monta a dica.
- **Ícones 7×7** (`UiStyle.ICONS`, desenhados como texto): heart, shield, damage, crit, rate, speed,
  jump, lamp, crown, shop, lock, skull. Ícone novo: mesma grade, "o" = contorno.
- **Barras:** `draw_bar(canvas, rect, fração, cor, fantasma)` — contorno, trilho `PLUM`, brilho no topo,
  sombra embaixo e "fantasma" do dano que desce aos poucos.
- **Cartas** (`UpgradeCard`): pergaminho em 2×, textos em 8 px, nome com contorno claro (passa por cima
  do rolo do pergaminho), selo de raridade colorido, tecla de atalho no canto de baixo. No hover a
  carta **sobe 5 px**.
- Tamanho de referência das telas: painéis de 240–440 px de largura, margem interna 10, espaçamento 4–6.

### Telas
- **Menu:** título em cima; à esquerda a coluna de ações (JOGAR/CONTINUAR em destaque, depois
  MELHORIAS — com selo "!" quando há melhoria comprável —, OPÇÕES, CRÉDITOS, SAIR); à direita o
  pato na casinha com etiqueta do nome, pontinhos de skin e setas; rodapé com recorde, almas,
  skins e versão.
- **HUD** (`scenes/ui/hud.gd`, 480×270):
  - esquerda-topo: coração + barra de vida (rastro do dano, pisca ao tomar dano) + "32/41"; almas da run.
  - direita-topo: "ONDA 12", inimigos restantes + barra de progresso da onda, próximo evento
    ("LOJA APÓS A ONDA 15" ou "ONDA DO CHEFE").
  - centro-topo: coroa + nome e barra do chefe (só com chefe vivo).
  - centro: faixa escura com aviso em 16 px (`show_banner(texto, cor)`).
  - esquerda-baixo: carga do poste de luz, depois de construído.
  - bordas: setas de inimigos fora da tela; faixas vermelhas pulsando com vida abaixo de 30%.
- **Pausa:** ações à esquerda; à direita "ESTA RUN" com onda, almas, vida e todos os stats do pato e do poste.
- **Fim de jogo:** selo de novo recorde, onda, recorde, almas ganhas e total, próxima skin.
- **Escolha de carta, loja, loja permanente, configurações, controles, créditos, confirmação, fim da demo:**
  todas com `centered_panel`/cabeçalho e os botões acima.

### Camadas (CanvasLayer)
HUD 5 → seleção de upgrade 10 → loja 12 → pausa / game over 20 → fim da demo 25 →
opções, créditos, loja meta 30 → controles 35 → confirmação 40. Painel novo: escolha a camada por essa ordem.

### Conferindo uma tela
`godot --path . res://tests/ui_snapshots.tscn -- --out=<pasta>` abre cada tela e salva um PNG
(não grava save nem run).

## 11. Áudio

- Música única `psycho_duck_theme.ogg` em loop; no chefe, tempo 1,15× e tom 0,8 (`autoload/music.gd`).
- 35 SFX sintetizados estilo sfxr (`tools/make_sfx.py`, mono 16 bits 22050 Hz) em `assets/audio/sfx/<nome>.wav`.
  Para trocar um som, substitua o arquivo mantendo o nome. Nome novo: adicione em `Sfx.NAMES`.
- `Sfx.play(nome, volume_db, variação_de_tom, tom)`; mesmo som não repete em < 45 ms.

## 12. Organização de assets

```
assets/
  sprites/player/        pato e skins
  sprites/enemies/       um PNG por inimigo, PascalCase (HornetQueen.png)
  sprites/weapons/       armas
  sprites/accessories/   itens vestíveis
  sprites/props/         objetos do cenário com lógica (poste)
  sprites/environment/   tileset, casinha
  ui/                    elementos de interface; ui/upgrades/ ícones 28×19 (PascalCase)
  fonts/  shaders/  branding/  audio/music/  audio/sfx/ (snake_case)
data/                    .tres de inimigos, skins, upgrades, itens, meta (snake_case)
```

- Texturas importam com filtro Nearest (padrão do projeto); não ligue mipmaps.
- Dados visuais de inimigo/skin/item ficam no `.tres`, não hardcoded na cena.
- Textos visíveis passam por `tr()` e entram em `localization/strings.csv` (en, pt_BR).

## 13. Inconsistências e pendências

Encontradas no levantamento; vale decidir antes de crescer o jogo:

1. **Cores fora da Resurrect 64 no código** (marcadas ⚠ em §3.3). A interface já foi migrada para a
   paleta (`UiStyle`); faltam projéteis, pickups e partículas. As de luz (`#ffe6b0`, `#ffb35c`) podem ficar,
   porque são tintas de luz. As de UI e projéteis deveriam virar a cor mais próxima da paleta, por exemplo:
   `#fbf5ef`→`#ffffff`, `#5ac54f`→`#1ebc73` ou `#91db69`, `#f06ac8`→`#eaaded`/`#c32454`,
   `#6ec4ff`→`#8fd3ff`, `#d58cff`→`#a884f3`, `#3e2731`→`#45293f`, `#5d2b3a`→`#7a3045`.
2. **Constantes duplicadas**: resolvido na interface (tudo vem de `UiStyle`). Ainda há `#2e222f` solto
   em `fx.gd` e `crosshair.gd`.
3. **Assets sem uso** (sobras da versão Unity): `environment/background.png`, `ui/UISprite.png`,
   `weapons/Circle.png`, `weapons/Square.png` (256×256 brancos), `player/Player-export.png`, `player/duck.png`,
   `ui/mouse.png`, `environment/pole.aseprite`, `icon.svg`.
4. **Céu liso**: não há fundo ilustrado, estrelas, lua ou parallax — maior oportunidade visual do cenário.
5. **Sem spritesheets**: toda animação é transformação em código. Se entrarem animações quadro a quadro,
   definir padrão (AnimatedSprite2D, nomes de animação, FPS).
6. **Pato do menu em 1,5×** (escala não inteira) pode distorcer pixels.
7. Não há escala inteira forçada (`window/stretch/scale_mode` fica em `fractional`): em resoluções que não
   são múltiplas de 480×270, os pixels podem sair com tamanhos desiguais.
