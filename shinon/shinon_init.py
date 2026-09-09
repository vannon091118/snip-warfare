# -*- coding: utf-8 -*-
"""Shinon Init. Einzige Pflicht Init des Projekts über das shinon Modul. Granular und mechanisch."""

import argparse
import sys
from pathlib import Path

PROJEKT_STAMM = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJEKT_STAMM))

import importlib.util as _ilu

def _lade(datei: str, klasse: str):
    pfad = PROJEKT_STAMM / "shinon" / datei
    spez = _ilu.spec_from_file_location(f"_shinon_init_{klasse.lower()}", str(pfad))
    modul = _ilu.module_from_spec(spez)
    sys.modules[spez.name] = modul
    assert spez.loader is not None
    spez.loader.exec_module(modul)
    return getattr(modul, klasse)


BESCHREIBUNG_SNIPWARFARE = "SnipWarfare -- kleines Team, grosse Karte, jeder Schnitt zaehlt.Prototype in Godot 4.7, 24 ticks Weltuhr."
REPO_VOLL_NAME = "vannon091118/snip-warfare"


def befehl_check() -> int:
    print("Shinon Init --check: Pruefe Pflichten fuer SnipWarfare.")
    Gate = _lade("shinon_gate.py", "ShinonGate")
    ReadmePruefer = _lade("shinon_readme_pruefer.py", "ShinonReadmePruefer")
    SteuerungPruefer = _lade("shinon_steuerung_pruefer.py", "ShinonSteuerungPruefer")
    GitHelfer = _lade("shinon_git_helfer.py", "ShinonGitHelfer")
    befunde = []
    befunde.extend(Gate().pruefen())
    befunde.extend(ReadmePruefer().pruefen())
    befunde.extend(SteuerungPruefer().pruefen())
    git = GitHelfer()
    if befunde:
        print(f"Shinon Init --check: {len(befunde)} Befund(e) blockieren das Gate.")
        for b in befunde:
            print(f"  {b.code} | {b.datei}:{b.zeile} | {b.text}")
        print("Hinweis: Gate muss gruen sein bevor ein Commit oder Push erlaubt ist.")
        return 1
    print("Shinon Init --check: Gate gruen, Readme lebendig, Steuerung lesbar.")
    print(f"Git Repo vorhanden: {git.ist_git_repo()}")
    print(f"Git Status: {git.status_kurz()[:200]}")
    ok, text = git.gh_auth_ok()
    print(f"gh auth: {'ok' if ok else 'nicht ok'} -- {text.splitlines()[0] if text else ''}")
    existiert = git.github_repo_existiert(REPO_VOLL_NAME) if ok else False
    if ok:
        print(f"GitHub {REPO_VOLL_NAME} existiert: {existiert}")
    return 0


def befehl_init() -> int:
    print("Shinon Init --init: Richte SnipWarfare als eigenstaendiges Projekt ein.")
    StatusLeser = _lade("shinon_projekt_status_leser.py", "ShinonProjektStatusLeser")
    Generator = _lade("shinon_readme_generator.py", "ShinonReadmeGenerator")
    GitHelfer = _lade("shinon_git_helfer.py", "ShinonGitHelfer")
    git = GitHelfer()
    # 1. README immer aus echten Daten erzeugen -- Shinon picht selbst, frisch, ohne fremden Zustand.
    status = StatusLeser().lese()
    pfad = Generator().schreibe(status)
    print(f"Shinon Init: README geschrieben nach {pfad}")
    # 2. Lokales Git sicherstellen.
    ok, text = git.git_init()
    print(f"Shinon Init: {text}")
    if not ok:
        return 1
    # 3. .gitignore haerten falls noetig.
    gitignore = PROJEKT_STAMM / ".gitignore"
    if gitignore.is_file():
        inhalt = gitignore.read_text(encoding="utf-8")
        ergaenzungen = []
        if ".godot/" not in inhalt:
            ergaenzungen.append(".godot/")
        if ".tmp/" not in inhalt:
            ergaenzungen.append(".tmp/")
        if ergaenzungen:
            with gitignore.open("a", encoding="utf-8") as datei:
                for zeile in ergaenzungen:
                    datei.write("\n" + zeile)
            print(f"Shinon Init: .gitignore ergaenzt um {', '.join(ergaenzungen)}")
    print("Shinon Init --init: Fertig. Naechster Schritt ist --check und dann --github falls gewuenscht.")
    return 0


def befehl_github() -> int:
    print(f"Shinon Init --github: Erstelle GitHub Repository {REPO_VOLL_NAME} fuer SnipWarfare.")
    GitHelfer = _lade("shinon_git_helfer.py", "ShinonGitHelfer")
    git = GitHelfer()
    ok, text = git.gh_auth_ok()
    if not ok:
        print(f"Shinon Init --github: gh auth fehlt -- {text}")
        print("Shinon verlangt einen gueltigen gh Token, nimmt aber niemals einen Zustand aus einem anderen lokalen Projekt.")
        return 1
    # Nutze nur den Token des aktuell eingeloggten gh Accounts, niemals Dateien aus anderen Repos.
    erstellt_ok, meldung = git.github_repo_erstellen(REPO_VOLL_NAME, BESCHREIBUNG_SNIPWARFARE, privat=False)
    print(meldung)
    if not erstellt_ok:
        return 1
    remote_ok, remote_text = git.remote_setzen(REPO_VOLL_NAME)
    print(remote_text)
    if not remote_ok:
        return 1
    print("Shinon Init --github: Fertig. Push erfolgt separat nach erfolgreichem Preflight und Gate.")
    return 0


def hauptprogramm() -> int:
    parser = argparse.ArgumentParser(description="Shinon Init fuer SnipWarfare -- einzige Pflicht Init ueber das shinon Modul.")
    gruppe = parser.add_mutually_exclusive_group(required=True)
    gruppe.add_argument("--init", action="store_true", help="README aus echten Daten bauen und lokales Git anlegen")
    gruppe.add_argument("--check", action="store_true", help="Gate, Readme und Steuerung mechanisch pruefen")
    gruppe.add_argument("--github", action="store_true", help="GitHub Repository vannon091118/snip-warfare erstellen")
    gruppe.add_argument("--readme", action="store_true", help="Nur die README aus echten Daten neu erzeugen")
    args = parser.parse_args()
    if args.init:
        return befehl_init()
    if args.check:
        return befehl_check()
    if args.github:
        return befehl_github()
    if args.readme:
        StatusLeser = _lade("shinon_projekt_status_leser.py", "ShinonProjektStatusLeser")
        Generator = _lade("shinon_readme_generator.py", "ShinonReadmeGenerator")
        status = StatusLeser().lese()
        pfad = Generator().schreibe(status)
        print(f"README neu geschrieben nach {pfad}")
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(hauptprogramm())
