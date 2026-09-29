"""Resume a saída do balance_bot: onda de morte por run e médias por onda.

Uso: python tests/balance_report.py runs.jsonl [outra.jsonl ...]
"""
import collections
import json
import sys
for f in sys.argv[1:]:
    rows=[json.loads(l) for l in open(f, encoding='utf-8') if l.startswith('{')]
    runs=collections.defaultdict(list)
    for r in rows: runs[r['run']].append(r)
    ends=sorted(max(x['wave'] for x in v) if any(x['died'] for x in v) else 99 for v in runs.values())
    print(f"{f}: morte nas ondas {ends} (99 = sobreviveu até o limite)")
    print("  onda   dur   dano  %vida  vidaMax  almas  dmg   aps  crit  def")
    for w in (1,3,5,8,10,12,15,18,20,25,30,35,40):
        ws=[r for r in rows if r['wave']==w and not r['died']]
        if ws:
            a=lambda k: sum(r[k] for r in ws)/len(ws)
            print(f"  {w:4d} {a('duration'):5.1f}s {a('damage'):5.1f} {100*a('damage')/a('max_hp'):5.0f}% {a('max_hp'):7.0f} {a('souls'):6.0f} {a('dmg'):4.0f} {a('aps'):5.2f} {a('crit'):4.0f} {a('def'):4.0f}  (n={len(ws)})")
