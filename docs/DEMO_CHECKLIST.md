# Psycho Duck — o que falta para fechar a demo

Revisão de 23/10/2026, a partir do commit `da0f795`.

**Como responder:** em cada pergunta da Parte 1, marque uma opção com `[x]` (ou escreva outra) e complete a linha **Resposta**. A Parte 2 eu faço sem precisar de decisão sua; se discordar de algum item, risque e comente. Com as respostas, eu fecho tudo, testo e faço os commits.

---

## O que já está pronto

- Menu com skins desbloqueáveis, OPTIONS, CONTINUE e fechar.
- Combate: andar, pular, plataformas (descer com S), mira no mouse, críticos e números de dano.
- 7 inimigos (abelha, vaga-lume, Skimmer, Sniper, Bomber, Carrier, drone), elites vermelhos e a Hornet Queen a cada 10 ondas.
- Carta grátis por onda, loja a cada 5 ondas, itens permanentes (óculos e cartola) e a categoria do poste de luz a partir da onda 10.
- Arena que cresce a cada 10 ondas, até a onda 30.
- Pausa, configurações e run salva no início de cada onda.
- Resolução 480×270 (1440×810 na janela; 4× em 1080p), música e 35 efeitos sonoros.

---

## Parte 1 — Decisões suas

### 1. Onde a demo vai ser publicada
- [ ] A) itch.io, jogável no navegador + download para Windows
- [ ] B) Só download (Windows; diga se quer Linux ou macOS também)
- [ ] C) Steam (Next Fest ou página de demo)
- [ ] D) Outro: ____

**Recomendação:** A. A versão web traz mais gente para testar, e o Windows serve para quem prefere baixar. Steam exige página, aprovação e taxa, então faz mais sentido depois.

**Resposta:** A — itch.io (web) + Windows.

---

### 2. Até onde a demo vai
Hoje o jogo é infinito.
- [ ] A) Infinita, igual ao jogo completo
- [ ] B) Termina ao vencer a rainha da **onda 20**, com uma tela "Obrigado por jogar" e a opção de continuar no modo infinito
- [ ] C) Termina na onda 10 (primeiro chefe)
- [ ] D) Outro limite: ____

**Recomendação:** B. Até a onda 20 o jogador vê 2 chefes, 2 expansões da arena, a loja, o poste e a primeira skin desbloqueada, e ainda sobra novidade para o jogo completo.

**Resposta:** B — termina ao vencer a rainha da onda 20, com tela de agradecimento e opção de seguir no infinito.

---

### 3. Idioma
Hoje todo o texto está em inglês (como na 0.2.0).
- [ ] A) Só inglês
- [ ] B) Só português
- [ ] C) Inglês e português, com seletor nas configurações

**Recomendação:** A para a demo. C dá mais trabalho, porque a fonte pixel precisa de acentos testados e as cartas têm pouco espaço para texto, mas é possível.

**Resposta:** C — inglês e português, com seletor nas configurações.

---

### 4. Arte: o que você entrega antes da demo
Estes itens ainda são placeholders (sprite de abelha ou vaga-lume com outra cor, ou desenho feito em código). Marque o que **você vai desenhar** antes da demo; o resto sai como está.

- [ ] Skimmer
- [ ] Sniper
- [ ] Bomber
- [ ] Carrier
- [ ] Drone
- [ ] Hornet Queen (chefe)
- [ ] Poste de luz
- [ ] Ícones das 4 cartas do poste (Power, Overclock, Burst, Reach) e do Light Pole
- [ ] Ícones dos óculos e da cartola nas cartas
- [ ] Skins novas (quantas: ____)
- [ ] Ícone do jogo (janela, executável e favicon da web)
- [ ] Capa/banner para a página da demo

**Prazo para eu receber a arte:**

**Resposta / observações:** Claude faz a pixel art de todos os placeholders, seguindo o estilo dos sprites atuais.

---

### 5. Skins na demo
Hoje há 3: Duck (liberada), Black Duck (vencer a onda 10) e Green Duck (vencer a onda 20).
- [ ] A) Manter assim
- [ ] B) Outra regra: ____

Se você mandar skins novas, diga a onda de cada uma.

**Resposta:** A — manter as 3 skins e as regras atuais.

---

### 6. Almas acumuladas entre runs
As almas que sobram no fim da run vão para um total que aparece no menu, mas **não servem para nada**: os itens permanentes são comprados com as almas da própria run.
- [ ] A) Deixar como está, só como estatística
- [ ] B) Tirar do menu para não confundir
- [ ] C) Criar uma loja permanente no menu (meta-progressão) já na demo

**Recomendação:** B para a demo, e C para o jogo completo. C é um sistema novo e mexe no balanceamento.

**Resposta:** C — loja permanente no menu (meta-progressão).

---

### 7. Ensinar os controles
Hoje o jogo não explica os controles em lugar nenhum (A/D, W/Espaço, S para descer da plataforma, mouse, 1–4 nas cartas, R na loja).
- [ ] A) Dicas na primeira onda (texto discreto no cenário, só na primeira run)
- [ ] B) Uma tela de controles antes da primeira run
- [ ] C) Só uma lista de controles na pausa
- [ ] D) A + C

**Recomendação:** D.

**Resposta:** B — tela de controles antes da primeira run.

---

### 8. Controle (gamepad)
- [ ] A) Só teclado e mouse na demo
- [ ] B) Suporte a gamepad (mira no analógico direito)

**Recomendação:** A, a não ser que a demo vá para a Steam ou Steam Deck. B precisa adaptar a mira e a navegação de todos os menus.

**Resposta:** A — só teclado e mouse.

---

### 9. Música
Hoje há uma única faixa (a da 0.2.0), em loop no menu e na partida.
- [ ] A) Fica assim
- [ ] B) Tenho outras faixas (menu, chefe, loja) e vou mandar
- [ ] C) Quero trocar a faixa da partida durante o chefe, mesmo sem música nova (ex.: mais grave e mais rápida)

**Resposta:** C — variação da faixa durante o chefe.

---

### 10. Efeitos sonoros
Os 35 sons são sintetizados (placeholders).
- [ ] A) Ficam na demo
- [ ] B) Vou trocar alguns/todos (mesmos nomes de arquivo em `assets/audio/sfx/`)
- [ ] C) Algum som está alto ou irritante: ____

**Resposta:** A — os efeitos sintetizados ficam.

---

### 11. Dificuldade
Medido com o bot depois da mudança para 480×270 (14 runs):
- **jogador bom (desvia):** morre entre as ondas 10 e 28, mediana na onda 18; **3 de 10 runs morreram no primeiro chefe (onda 10)**;
- **jogador fraco (parado):** morre entre as ondas 3 e 9;
- as ondas 15 a 25 estão longas (40 a 60 s).

- [ ] A) Ajustar para a meta antiga: jogador bom chega perto da onda 25–30, a rainha da onda 10 deixa de ser uma parede e as ondas ficam abaixo de 40 s
- [ ] B) Deixar mais difícil que isso
- [ ] C) Deixar mais fácil que isso
- [ ] D) Adicionar seletor de dificuldade (Normal / Difícil)

**Recomendação:** A. Se você jogou, conte em que onda costuma morrer; isso vale mais que o bot.

**Onde eu morro jogando:**

**Resposta:** C — um pouco mais fácil, garantindo que o jogador padrão passe da onda 10.

---

### 12. Créditos
A demo precisa de uma tela de créditos. A licença da fonte Silkscreen (OFL) pede atribuição.
- Nomes e funções (ex.: "Pedro — design e arte"):
- Quem fez a música:
- Links (itch, redes, Discord):

**Resposta:** Fazer a tela. Empresa: Briba Studio (logo enviado).

---

### 13. Nome e versão
- Nome na janela e na página: **Psycho Duck** / outro: ____
- Versão que aparece no menu: **0.3.0 Demo** / outra: ____

**Resposta:** Psycho Duck. Versão: 0.3.0 Demo (padrão, sem resposta).

---

### 14. Feedback dos jogadores
- [ ] A) Botão "FEEDBACK" no menu e no game over, abrindo um link (Google Forms, Discord, itch)
- [ ] B) Sem botão

Se A, qual link:

**Resposta:** B — sem botão de feedback.

---

### 15. Progresso e run salva
- Botão **"Apagar progresso"** nas configurações (zera skins, recorde, itens e run salva)? [ ] Sim [ ] Não
- Ao clicar em START com uma run salva, ela é descartada **sem aviso**. Quer uma confirmação ("Começar nova run? A run salva será perdida")? [ ] Sim [ ] Não

**Recomendação:** sim nos dois.

**Resposta:** Confirmação ao começar nova run com uma salva. Botão de apagar progresso incluído (recomendado).

---

## Parte 2 — O que eu faço sem precisar de decisão

| # | Tarefa | Por quê |
|---|---|---|
| T1 | Rebalancear o primeiro chefe e as ondas 15–25 conforme a pergunta 11, e confirmar com o bot | Regressão medida depois da mudança de resolução |
| T2 | Reduzir as luzes dinâmicas: hoje **cada tiro inimigo, orbe e alma tem uma luz própria** | Nas ondas altas podem ser 40+ luzes ao mesmo tempo; no navegador e em GPU integrada isso derruba o FPS. Fica uma luz por inimigo especial, sem luz nos tiros |
| T3 | Instalar os templates de exportação do Godot 4.7.2 (download de cerca de 1 GB) e criar os presets de exportação (Web e Windows, mais o que a pergunta 1 pedir) | Hoje não há templates nem presets: não dá para gerar a demo |
| T4 | Excluir `tests/`, `tools/` e `docs/` do build | O bot e o gerador de sons não devem ir para a demo |
| T5 | Ícone placeholder baseado no pato e tela de abertura com o logo, até a sua arte chegar | Hoje são o ícone e a tela padrão do Godot |
| T6 | Número de versão no menu | Para os relatos de bug dizerem a versão |
| T7 | Lista de controles na pausa (e o que a pergunta 7 decidir) | Hoje os controles não aparecem em lugar nenhum |
| T8 | Tela de créditos com a licença OFL da fonte | Obrigação da licença |
| T9 | Na web: P também pausa, e um aviso "ESC sai da tela cheia; use P para pausar" | No navegador, ESC tira da tela cheia antes de chegar ao jogo |
| T10 | Atualizar o GDD com todos os sistemas atuais | Ele parou na primeira versão do port |
| T11 | Teste final: bot, exportação, jogar no navegador, conferir save e CONTINUE | Garantir que o build publicado funciona |
| T12 | Um commit por tarefa e envio para o GitHub | Histórico para voltar atrás se precisar |

---

## Parte 3 — Riscos e problemas conhecidos

- **Primeiro chefe como parede** (T1 resolve).
- **Desempenho no navegador** com muitas luzes e partículas (T2 resolve; vale testar num PC mais fraco).
- **Testado só nesta máquina.** Resoluções diferentes, monitores ultrawide e navegadores além do Chrome não foram testados.
- **Save no navegador:** fica no IndexedDB daquele navegador; limpar dados do site apaga o progresso.
- **Música na web** só começa depois do primeiro clique (regra dos navegadores).
- **Run salva** volta ao início da onda; almas ganhas no meio da onda se perdem (comportamento esperado, avisado na pausa).

---

## Parte 4 — Página da demo (se for itch.io)

Isto fica com você; eu ajudo com os textos e as imagens se quiser.

- [ ] Texto de descrição (eu posso escrever um rascunho em inglês e português)
- [ ] 3 a 5 screenshots (eu posso gerar pelo jogo)
- [ ] GIF ou vídeo curto de gameplay
- [ ] Capa 630×500 e banner
- [ ] Controles na página
- [ ] Tags (ex.: roguelite, wave survival, pixel art, shooter)
