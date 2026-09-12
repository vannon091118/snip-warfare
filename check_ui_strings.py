import re, sys

strings = [
    'Produktion: keine Gebaeude',
    'Debug-Overlay: %s',
    'Schnellwahl %d gesetzt auf Einheit %d',
    'Einheit %d gewählt',
    'Verteilung: %.1f Nahrung je Einheit je Takt',
    'Noch nicht freigeschaltet: %s',
    'Wachstum: Neuer Stickman am Lager, 3 Nahrung verbraucht.',
    'Wachstum braucht 3 Nahrung im naechsten Lager.',
    'Massenwahl: %d Einheiten im Rechteck',
    'Befehl: Jagen auf Tier #%d',
    'Zuerst eine Einheit auswaehlen.',
    'Auswahl aufgehoben.',
    'Kontext: %s ueber Logik %s',
    'Bauen nicht moeglich: %s',
    'Bauplan anfordern',
    'expansieren',
]

for s in strings:
    problems = []
    s = s.strip()
    
    # Check for AI tells
    if any(w in s.lower() for w in ['pivotal', 'entscheidend', 'schlüssel', 'unersetzlich']):
        problems.append('Significance inflation')
    if re.search(r'dient\s+as|steht\s+as', s, re.I):
        problems.append('Copula avoidance')
    if any(w in s.lower() for w in ['breathtaking', 'stunning', 'profound', 'groundbreaking']):
        problems.append('Promotional')
    if any(w in s.lower() for w in ['industrie', 'experten', 'beobachter']):
        problems.append('Vague attribution')
    if '—' in s or '–' in s:
        problems.append('Em dash')
    if 'in order to' in s.lower() or 'due to the fact' in s.lower():
        problems.append('Filler')
    if any(r in s.lower() for r in ['and thats okay', 'and thats fine']):
        problems.append('Reassurance')
    if s.lower().startswith(('so,', 'look,', "let's", 'i hope')):
        problems.append('Opener tic')
    
    if problems:
        print(f'PROBLEM: "{s}" -> {problems}')
    else:
        print(f'OK:      "{s}"')