# -*- coding: utf-8 -*-
"""Sonden Selbstbeweis. Eigene Zuständigkeit: Ein Szenario darf die Sache,
die es behauptet, nicht selbst herbeiführen.

Genau hier war die Lücke, die schlampige Arbeit durchgewinkt hat: Die
Sichtbarkeits-Sonde setzte ihre Einheit mit einem Cheat und bewies damit
nichts. Ab jetzt gilt mechanisch: Wer eine Leistung des Spiels behauptet,
darf sie nicht selbst erzeugen.
"""

# Schritte, die eine Einheit erzeugen oder bewegen.
EINHEIT_SCHRITTE = ("einheit_im_blick", "einheit_marsch", "einheit_marsch_delta")

# Behauptung im Szenario -> Cheat-Schritte, die sie ungültig machen.
# Eine Einheit selbst zu setzen und dann zu behaupten, das Spiel bringe sie
# hervor oder sie gehe, ist ein Selbstbeweis. Ein Marschbefehl ist dagegen
# eine Spielerhandlung: Er darf bleiben, weil er die Einheit nicht erschafft.
# Ein Bau-Gate-Beweis darf das Gate fragen — die Frage ist der Beweis.
SELBSTBEWEIS_VERBOTE = {
    "einheiten_min": ("einheit_im_blick",),
    "einheit_im_bild": ("einheit_im_blick",),
    "einheit_bewegt": ("einheit_im_blick",),
    "bau_ok_folge": (),
}


def pruefe_selbstbeweis(szenario: dict, pfad: str, melde) -> None:
    """Meldet jeden Verstoß gegen den Selbstbeweis-Vertrag."""
    erwartet = szenario.get("erwartet") or {}
    schritte = szenario.get("schritte") or []
    arten = {str(s.get("art", "")) for s in schritte if isinstance(s, dict)}
    for behauptung, verboten in SELBSTBEWEIS_VERBOTE.items():
        if behauptung not in erwartet:
            continue
        gemeinsam = arten & set(verboten)
        if gemeinsam:
            melde(pfad,
                  "Szenario behauptet %s und fuehrt es mit %s selbst herbei; "
                  "ein Selbstbeweis ist kein Beweis" %
                  (behauptung, ", ".join(sorted(gemeinsam))))
