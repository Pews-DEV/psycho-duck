"""Gera a pixel art dos inimigos novos, do poste de luz e do ícone do jogo.

Paleta Resurrect 64 (a mesma dos sprites originais) e contorno escuro de 1 px
aplicado automaticamente em volta de cada forma, como na abelha e no vaga-lume.
Uso: python tools/make_sprites.py [pasta_de_preview]
"""
import os
import sys

from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..")

# --- Paleta (Resurrect 64) -------------------------------------------------------
OUTLINE = "#2e222f"
DARK = "#3e3546"
GREY = "#625565"
WING = "#c7dcd0"
WHITE = "#ffffff"
STEEL = "#9babb2"
RED = "#e83b3b"
DEEP_RED = "#ae2334"
YELLOW = "#f9c22b"
GOLD = "#fbb954"
ORANGE = "#f79617"
BLUE = "#4d65b4"
LIGHT_BLUE = "#4d9be6"
NAVY = "#484a77"
PURPLE = "#6b3e75"
LIGHT_PURPLE = "#905ea9"
LILAC = "#a884f3"
PINK = "#cf657f"
LIGHT_PINK = "#ed8099"
HOT_PINK = "#f04f78"
PEACH = "#fca790"
BROWN = "#9e4539"
LIGHT_BROWN = "#cd683d"
TAN = "#e6904e"
PLUM = "#45293f"
CYAN = "#30e1b9"
LIGHT_CYAN = "#8ff8e2"
TEAL = "#0eaf9b"
LAMP = "#fbff86"
LIME = "#d5e04b"


def rgba(color):
    color = color.lstrip("#")
    return tuple(int(color[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


class Sprite:
    def __init__(self, width, height):
        self.w, self.h = width, height
        self.px = [[None] * width for _ in range(height)]

    def set(self, x, y, color):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.px[y][x] = color

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.px[y][x]
        return None

    def ellipse(self, cx, cy, rx, ry, color):
        for y in range(self.h):
            for x in range(self.w):
                if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0:
                    self.set(x, y, color)

    def rect(self, x0, y0, x1, y1, color):
        """Retângulo cheio com cantos inclusivos."""
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.set(x, y, color)

    def recolor_rows(self, y0, y1, color, only=None):
        """Pinta linhas inteiras dentro da forma (listras). `only` limita a uma cor de origem."""
        for y in range(y0, y1 + 1):
            for x in range(self.w):
                current = self.get(x, y)
                if current is not None and current != OUTLINE and (only is None or current == only):
                    self.set(x, y, color)

    def outline(self):
        """Contorno de 1 px em volta de tudo que foi desenhado (vizinhança de 4)."""
        filled = {(x, y) for y in range(self.h) for x in range(self.w) if self.px[y][x] is not None}
        for y in range(self.h):
            for x in range(self.w):
                if (x, y) in filled:
                    continue
                if any((x + dx, y + dy) in filled for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    self.px[y][x] = OUTLINE

    def mirror(self):
        """Copia a metade esquerda para a direita (sprites de frente, simétricos)."""
        for y in range(self.h):
            for x in range(self.w // 2):
                self.px[y][self.w - 1 - x] = self.px[y][x]

    def image(self):
        img = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        for y in range(self.h):
            for x in range(self.w):
                if self.px[y][x] is not None:
                    img.putpixel((x, y), rgba(self.px[y][x]))
        return img


# --- Inimigos ----------------------------------------------------------------------

def skimmer():
    """Besouro espinhoso de voo rasante, visto de lado, virado para a direita."""
    s = Sprite(21, 13)
    s.ellipse(3.5, 5.5, 3.2, 2.2, WING)             # asa, atrás do corpo
    for x in (5, 8, 11, 14):                        # espinhos altos no dorso
        s.rect(x, 2, x, 5, STEEL)
        s.set(x, 1, WHITE)
    s.ellipse(10, 8.5, 8.2, 3.2, BLUE)              # corpo
    s.ellipse(17, 8, 3.2, 3.2, NAVY)                # cabeça
    s.outline()
    s.rect(4, 6, 14, 6, LIGHT_BLUE)                 # brilho do dorso
    s.set(18, 7, RED)                               # olho
    s.set(19, 7, RED)
    s.set(18, 8, DEEP_RED)
    s.set(19, 8, WHITE)
    s.rect(5, 10, 14, 10, NAVY)                     # barriga
    for x in (7, 10, 13):                           # perninhas
        s.set(x, 12, OUTLINE)
    return s


def sniper():
    """Vespa roxa com um olho-luneta vermelho."""
    s = Sprite(19, 16)
    s.ellipse(3.5, 7.5, 3.2, 2.2, WING)             # asas
    s.ellipse(15.5, 7.5, 3.2, 2.2, WING)
    s.ellipse(9.5, 12, 4, 3.2, PURPLE)              # abdômen
    s.ellipse(9.5, 6, 5.2, 4.2, PURPLE)             # cabeça
    s.set(7, 0, PURPLE)                             # antenas
    s.set(8, 1, PURPLE)
    s.set(11, 1, PURPLE)
    s.set(12, 0, PURPLE)
    s.outline()
    s.recolor_rows(11, 11, LIGHT_PURPLE, only=PURPLE)   # listras do abdômen
    s.recolor_rows(13, 13, LIGHT_PURPLE, only=PURPLE)
    s.ellipse(9.5, 6, 2.6, 2.6, OUTLINE)            # luneta
    s.ellipse(9.5, 6, 1.8, 1.8, RED)
    s.set(9, 6, WHITE)
    s.set(9, 5, LIGHT_PURPLE)                       # reflexo da lente
    s.rect(6, 3, 7, 3, LILAC)                       # brilho da cabeça
    return s


def bomber():
    """Besouro rosado com um orbe de energia brilhando na barriga."""
    s = Sprite(19, 16)
    s.ellipse(2.5, 6.5, 2.5, 3.2, WING)             # asas
    s.ellipse(16.5, 6.5, 2.5, 3.2, WING)
    s.ellipse(9.5, 8, 7, 6.5, PINK)                 # corpo
    s.set(7, 0, PINK)                               # antenas
    s.set(6, 1, PINK)
    s.set(12, 0, PINK)
    s.set(13, 1, PINK)
    s.outline()
    s.rect(6, 3, 13, 3, LIGHT_PINK)                 # brilho
    s.set(7, 5, OUTLINE)                            # olhos
    s.set(12, 5, OUTLINE)
    s.ellipse(9.5, 10.5, 3.2, 3.2, OUTLINE)         # orbe
    s.ellipse(9.5, 10.5, 2.4, 2.4, HOT_PINK)
    s.set(9, 10, PEACH)
    s.set(10, 10, PEACH)
    s.set(9, 9, WHITE)
    return s


def drone():
    """Robozinho voador ciano (invocado pelo Carrier e pela rainha)."""
    s = Sprite(11, 10)
    s.rect(2, 1, 8, 1, STEEL)                       # hélice
    s.set(5, 2, STEEL)
    s.ellipse(5.5, 6, 4, 3.4, CYAN)                 # corpo
    s.outline()
    s.rect(3, 5, 7, 5, OUTLINE)                     # visor
    s.set(5, 5, RED)
    s.rect(3, 7, 7, 7, LIGHT_CYAN)                  # brilho de baixo
    return s


def carrier():
    """Nave-mãe blindada: casco marrom, luzes na frente e uma escotilha de drones."""
    s = Sprite(34, 21)
    s.ellipse(17, 9, 16, 8, BROWN)                  # casco
    s.ellipse(17, 7, 13, 5, LIGHT_BROWN)            # placa de cima
    s.rect(9, 15, 12, 18, DARK)                     # propulsores
    s.rect(21, 15, 24, 18, DARK)
    s.outline()
    s.recolor_rows(4, 4, TAN, only=LIGHT_BROWN)     # brilho da placa
    for x in range(5, 30, 4):                       # rebites
        s.set(x, 12, PLUM)
    s.rect(10, 8, 11, 9, LAMP)                      # faróis
    s.rect(22, 8, 23, 9, LAMP)
    s.rect(14, 12, 19, 15, OUTLINE)                 # escotilha
    s.rect(15, 13, 18, 14, PLUM)
    s.rect(16, 13, 17, 13, LIGHT_CYAN)
    s.rect(10, 19, 11, 19, ORANGE)                  # chama dos propulsores
    s.rect(22, 19, 23, 19, ORANGE)
    return s


def hornet_queen():
    """A rainha: vespa grande amarela e preta, de coroa, olhos bravos e ferrão."""
    s = Sprite(46, 38)
    s.ellipse(9, 13, 9, 6, WING)                    # asas de cima
    s.ellipse(37, 13, 9, 6, WING)
    s.ellipse(10, 21, 6, 4, WING)                   # asas de baixo
    s.ellipse(36, 21, 6, 4, WING)
    s.ellipse(23, 26, 10.5, 9.5, YELLOW)            # abdômen
    s.rect(22, 35, 23, 37, OUTLINE)                 # ferrão
    s.ellipse(23, 13, 9, 7.5, YELLOW)               # cabeça
    for x, y in ((17, 4), (17, 3), (20, 2), (23, 1), (26, 2), (29, 3), (29, 4)):  # pontas da coroa
        s.set(x, y, GOLD)
    s.rect(17, 5, 29, 6, GOLD)                      # aro da coroa
    s.outline()
    for row in (22, 23, 27, 28, 32):                # listras pretas
        s.recolor_rows(row, row, OUTLINE, only=YELLOW)
    s.set(20, 5, RED)                               # joias da coroa
    s.set(23, 5, LILAC)
    s.set(26, 5, RED)
    s.rect(15, 10, 20, 10, OUTLINE)                 # sobrancelhas bravas
    s.rect(26, 10, 31, 10, OUTLINE)
    s.set(15, 9, OUTLINE)
    s.set(31, 9, OUTLINE)
    s.rect(17, 12, 19, 13, OUTLINE)                 # olhos
    s.rect(27, 12, 29, 13, OUTLINE)
    s.set(18, 12, RED)
    s.set(28, 12, RED)
    s.rect(20, 17, 26, 17, OUTLINE)                 # boca
    s.set(21, 18, WHITE)                            # dentinhos
    s.set(25, 18, WHITE)
    s.rect(17, 8, 19, 8, GOLD)                      # brilho da cabeça
    return s


# --- Poste e ícone -----------------------------------------------------------------

def light_pole():
    """Poste de luz de ferro com lâmpada; a base fica embaixo e o poste em x = 9..10."""
    s = Sprite(13, 46)
    s.rect(9, 3, 10, 42, DARK)                      # poste
    s.rect(7, 42, 12, 44, DARK)                     # base
    s.rect(2, 2, 10, 3, DARK)                       # braço
    s.rect(1, 4, 6, 5, DARK)                        # luminária
    s.rect(2, 6, 5, 6, LAMP)                        # lâmpada
    s.outline()
    s.rect(10, 4, 10, 41, GREY)                     # brilho do metal
    s.rect(8, 43, 11, 43, GREY)
    return s


def game_icon(size):
    """Ícone: rosto do pato sobre um quadrado escuro arredondado."""
    duck = Image.open(os.path.join(ROOT, "assets/sprites/player/Player.png")).convert("RGBA")
    scale = max(1, (size * 3 // 4) // duck.width)
    big = duck.resize((duck.width * scale, duck.height * scale), Image.NEAREST)
    icon = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    radius = size // 6
    bg = rgba("#323353")
    border = rgba(OUTLINE)
    for y in range(size):
        for x in range(size):
            cx = min(max(x, radius), size - 1 - radius)
            cy = min(max(y, radius), size - 1 - radius)
            d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
            if d <= radius:
                icon.putpixel((x, y), border if d > radius - max(1, size // 32) else bg)
    icon.alpha_composite(big, ((size - big.width) // 2, (size - big.height) // 2 + size // 20))
    return icon


SPRITES = {
    "assets/sprites/enemies/Skimmer.png": skimmer,
    "assets/sprites/enemies/Sniper.png": sniper,
    "assets/sprites/enemies/Bomber.png": bomber,
    "assets/sprites/enemies/Drone.png": drone,
    "assets/sprites/enemies/Carrier.png": carrier,
    "assets/sprites/enemies/HornetQueen.png": hornet_queen,
    "assets/sprites/props/LightPole.png": light_pole,
}


if __name__ == "__main__":
    preview_dir = sys.argv[1] if len(sys.argv) > 1 else None
    images = []
    for path, build in SPRITES.items():
        full = os.path.join(ROOT, path)
        os.makedirs(os.path.dirname(full), exist_ok=True)
        img = build().image()
        img.save(full)
        images.append(img)
        print(path, img.size)
    icon = game_icon(256)
    icon.save(os.path.join(ROOT, "assets/branding/icon.png"))
    icon.save(os.path.join(ROOT, "assets/branding/icon.ico"), sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    print("assets/branding/icon.png / icon.ico")
    if preview_dir:
        # Prancha 6× com todos os sprites lado a lado sobre o céu do jogo.
        scale = 6
        width = sum(i.width * scale + 24 for i in images) + 24
        height = max(i.height for i in images) * scale + 48
        sheet = Image.new("RGBA", (width, height), rgba("#323353"))
        x = 24
        for img in images:
            big = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
            sheet.alpha_composite(big, (x, 24))
            x += big.width + 24
        sheet.save(os.path.join(preview_dir, "sprites_preview.png"))
        icon.resize((128, 128), Image.NEAREST).save(os.path.join(preview_dir, "icon_preview.png"))
