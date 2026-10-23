"""Fonte das traduções do Psycho Duck.

Gera localization/strings.csv (formato de tradução do Godot).
A chave é o próprio texto em inglês; a coluna pt_BR é a tradução.
Uso: python tools/strings_source.py
"""
import csv
import os

STRINGS = [
    # --- Menu ---------------------------------------------------------------
    ("OPTIONS", "OPÇÕES"),
    ("UPGRADES", "MELHORIAS"),
    ("CREDITS", "CRÉDITOS"),
    ("CONTINUE W%02d", "CONTINUAR %02d"),
    ("BEST WAVE %02d   SOULS %d   SKINS %d/%d", "RECORDE %02d   ALMAS %d   SKINS %d/%d"),
    ("LOCKED - CLEAR WAVE %d", "BLOQUEADA - VENÇA A ONDA %d"),
    ("START A NEW RUN?", "COMEÇAR UMA NOVA RUN?"),
    ("YOUR SAVED RUN (WAVE %02d) WILL BE LOST.", "SUA RUN SALVA (ONDA %02d) SERÁ PERDIDA."),
    ("NEW RUN", "NOVA RUN"),
    ("CANCEL", "CANCELAR"),
    ("Duck", "Pato"),
    ("Black Duck", "Pato Preto"),
    ("Green Duck", "Pato Verde"),
    # --- Loja permanente ------------------------------------------------------
    ("PERMANENT UPGRADES", "MELHORIAS PERMANENTES"),
    ("SPEND SOULS FROM PAST RUNS. BONUSES APPLY TO EVERY RUN.", "GASTE AS ALMAS DAS RUNS ANTERIORES. OS BÔNUS VALEM EM TODAS AS RUNS."),
    ("LV %d/%d", "NV %d/%d"),
    ("MAX", "MÁX"),
    ("Vitality", "Vitalidade"),
    ("Start with +_ Max. HP", "Começa com +_ de vida máx."),
    ("Firepower", "Poder de Fogo"),
    ("Start with +_ Projectile Damage", "Começa com +_ de dano do tiro"),
    ("Sharp Eye", "Olho Atento"),
    ("Start with +_% Critical Chance", "Começa com +_% de chance de crítico"),
    ("Thick Feathers", "Penas Grossas"),
    ("Start with +_% Defense", "Começa com +_% de defesa"),
    ("Soul Magnet", "Ímã de Almas"),
    ("+_% Souls collected", "+_% de almas coletadas"),
    ("Second Wind", "Segundo Fôlego"),
    ("Heal +_% more after each wave", "Cura +_% a mais após cada onda"),
    # --- Partida --------------------------------------------------------------
    ("WAVE %d", "ONDA %d"),
    ("BOSS WAVE", "ONDA DO CHEFE"),
    ("WAVE CLEAR", "ONDA VENCIDA"),
    ("THE ARENA GROWS!", "A ARENA CRESCEU!"),
    ("SHOP TIME", "HORA DA LOJA"),
    ("NEW SKIN: %s!", "NOVA SKIN: %s!"),
    ("Hornet Queen", "Rainha Vespa"),
    # --- Cartas ---------------------------------------------------------------
    ("WAVE %02d - CHOOSE AN UPGRADE", "ONDA %02d - ESCOLHA UMA MELHORIA"),
    ("CLICK A CARD OR PRESS 1-4", "CLIQUE NUMA CARTA OU APERTE 1-4"),
    ("COMMON", "COMUM"),
    ("RARE", "RARO"),
    ("EPIC", "ÉPICO"),
    ("PERMANENT", "PERMANENTE"),
    ("NEW", "NOVO"),
    ("Growth", "Crescimento"),
    ("Max. HP +_", "Vida máx. +_"),
    ("Resist", "Resistência"),
    ("Defense +_%", "Defesa +_%"),
    ("Renew", "Renovar"),
    ("Heal to Max. HP", "Cura toda a vida"),
    ("Impulse", "Impulso"),
    ("Jump & Move Speed +_%", "Pulo e velocidade +_%"),
    ("Eyesight", "Visão"),
    ("Critical Chance +_%", "Chance de crítico +_%"),
    ("Resonance", "Ressonância"),
    ("Atk Speed +_%", "Cadência +_%"),
    ("Catalyst", "Catalisador"),
    ("Projectile Damage +_", "Dano do tiro +_"),
    ("Glasses", "Óculos"),
    ("Critical Chance +10%", "Chance de crítico +10%"),
    ("Top Hat", "Cartola"),
    ("Projectile Damage +15", "Dano do tiro +15"),
    ("Light Pole", "Poste de Luz"),
    ("Laser lamp post", "Poste com laser"),
    ("Pole Power", "Poste Forte"),
    ("Pole Damage +_", "Dano do poste +_"),
    ("Overclock", "Sobrecarga"),
    ("Pole Fire Rate +_%", "Cadência do poste +_%"),
    ("Pole Burst", "Rajada"),
    ("Pole Lasers +_", "Lasers do poste +_"),
    ("Pole Reach", "Alcance"),
    ("Pole Range +_", "Alcance do poste +_"),
    # --- Loja da run ----------------------------------------------------------
    ("SHOP", "LOJA"),
    ("WAVE %02d CLEARED - SPEND YOUR SOULS", "ONDA %02d VENCIDA - GASTE SUAS ALMAS"),
    ("NEW IN THE SHOP: %s", "NOVO NA LOJA: %s"),
    ("REROLL %d", "TROCAR %d"),
    ("LEAVE", "SAIR"),
    ("SOLD", "VENDIDO"),
    ("CLICK OR 1-4 TO BUY  -  R TO REROLL  -  ESC TO LEAVE", "CLIQUE OU 1-4 PARA COMPRAR  -  R PARA TROCAR  -  ESC PARA SAIR"),
    # --- Pausa, fim de jogo e demo --------------------------------------------
    ("PAUSED", "PAUSADO"),
    ("RESUME", "CONTINUAR"),
    ("SETTINGS", "CONFIGURAÇÕES"),
    ("CONTROLS", "CONTROLES"),
    ("SAVE & QUIT", "SALVAR E SAIR"),
    ("ABANDON RUN", "DESISTIR"),
    ("SURE?", "CERTEZA?"),
    ("YOUR RUN IS SAVED AT THE START OF EACH WAVE", "SUA RUN É SALVA NO INÍCIO DE CADA ONDA"),
    ("ON THE WEB, ESC LEAVES FULLSCREEN - USE P TO PAUSE", "NO NAVEGADOR, ESC SAI DA TELA CHEIA - USE P PARA PAUSAR"),
    ("GAME OVER", "FIM DE JOGO"),
    ("WAVE %02d    BEST %02d\nSOULS +%d", "ONDA %02d    RECORDE %02d\nALMAS +%d"),
    ("NEW RECORD!", "NOVO RECORDE!"),
    ("RETRY", "TENTAR DE NOVO"),
    ("MENU", "MENU"),
    ("THANKS FOR PLAYING!", "OBRIGADO POR JOGAR!"),
    ("YOU BEAT THE DEMO. THE FULL GAME IS ON ITS WAY.", "VOCÊ VENCEU A DEMO. O JOGO COMPLETO ESTÁ A CAMINHO."),
    ("KEEP GOING (ENDLESS)", "CONTINUAR (INFINITO)"),
    # --- Controles ------------------------------------------------------------
    ("HOW TO PLAY", "COMO JOGAR"),
    ("MOVE", "ANDAR"),
    ("JUMP", "PULAR"),
    ("DROP FROM PLATFORM", "DESCER DA PLATAFORMA"),
    ("AIM", "MIRAR"),
    ("SHOOT (HOLD)", "ATIRAR (SEGURE)"),
    ("PAUSE", "PAUSAR"),
    ("PICK A CARD", "ESCOLHER CARTA"),
    ("MOUSE", "MOUSE"),
    ("W / SPACE", "W / ESPAÇO"),
    ("LEFT CLICK", "CLIQUE ESQUERDO"),
    ("SURVIVE THE WAVES. PICK AN UPGRADE EACH WAVE.\nEVERY 5 WAVES THE SHOP OPENS.", "SOBREVIVA ÀS ONDAS. ESCOLHA UMA MELHORIA POR ONDA.\nA CADA 5 ONDAS A LOJA ABRE."),
    ("PLAY", "JOGAR"),
    # --- Configurações --------------------------------------------------------
    ("VOLUME", "VOLUME"),
    ("MUSIC", "MÚSICA"),
    ("EFFECTS", "EFEITOS"),
    ("FULLSCREEN", "TELA CHEIA"),
    ("SCREEN SHAKE", "TREMOR DE TELA"),
    ("DAMAGE NUMBERS", "NÚMEROS DE DANO"),
    ("LANGUAGE", "IDIOMA"),
    ("ENGLISH", "ENGLISH"),
    ("PORTUGUÊS", "PORTUGUÊS"),
    ("RESET PROGRESS", "APAGAR PROGRESSO"),
    ("ERASE ALL PROGRESS?", "APAGAR TODO O PROGRESSO?"),
    ("SKINS, RECORDS, SOULS, UPGRADES AND THE SAVED RUN WILL BE DELETED.", "SKINS, RECORDES, ALMAS, MELHORIAS E A RUN SALVA SERÃO APAGADOS."),
    ("ERASE", "APAGAR"),
    ("BACK", "VOLTAR"),
    # --- Créditos -------------------------------------------------------------
    ("A GAME BY", "UM JOGO DA"),
    ("DESIGN, ART AND CODE", "DESIGN, ARTE E CÓDIGO"),
    ("MUSIC AND SOUND", "MÚSICA E SOM"),
    ("FONT", "FONTE"),
    ("MADE WITH", "FEITO COM"),
    ("THANK YOU FOR PLAYING", "OBRIGADO POR JOGAR"),
]


if __name__ == "__main__":
    out = os.path.join(os.path.dirname(__file__), "..", "localization", "strings.csv")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    keys = [k for k, _ in STRINGS]
    duplicates = {k for k in keys if keys.count(k) > 1}
    assert not duplicates, duplicates
    with open(out, "w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f, lineterminator="\n")
        writer.writerow(["keys", "en", "pt_BR"])
        for key, pt in STRINGS:
            writer.writerow([key, key, pt])
    print(f"{len(STRINGS)} textos em {os.path.abspath(out)}")
