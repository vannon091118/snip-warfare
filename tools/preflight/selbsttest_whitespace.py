# -*- coding: utf-8 -*-
"""Selbsttest Whitespace. Eigene Zuständigkeit: Der Whitespace-Anteil des E000."""

import importlib.util
import pathlib

from .kern import PROJEKT_STAMM


def pruefe(probleme: list[str]) -> None:
    try:
        ws_pfad = PROJEKT_STAMM / "tools" / "preflight" / "whitespace_regeln.py"
        ws_spez = importlib.util.spec_from_file_location("_ws_mod", str(ws_pfad))
        ws_mod = importlib.util.module_from_spec(ws_spez)
        assert ws_spez.loader is not None
        ws_spez.loader.exec_module(ws_mod)
        probe_crlf, zeile_crlf = ws_mod.ursachen_fuer(pathlib.Path("probe.py"), b"a = 1\r\n", "a = 1\r\n")
        if not any("CRLF" in u for u in probe_crlf):
            probleme.append("Whitespace Pruefer meldet CRLF nicht")
        if zeile_crlf != 1:
            probleme.append(f"Whitespace CRLF Zeile falsch: {zeile_crlf}")
        probe_trail, zeile_trail = ws_mod.ursachen_fuer(pathlib.Path("probe.py"), b"a = 1   \n", "a = 1   \n")
        if not any("trailing" in u for u in probe_trail):
            probleme.append("Whitespace trailing nicht gemeldet")
        if zeile_trail != 1:
            probleme.append(f"Whitespace trailing Zeile falsch: {zeile_trail}")
        probe_trail2, zeile_trail2 = ws_mod.ursachen_fuer(pathlib.Path("probe.py"), b"a\n" + b"b   \n", "a\n" + "b   \n")
        if zeile_trail2 != 2:
            probleme.append(f"Whitespace trailing Zeile 2 falsch: {zeile_trail2}")
        probe_final, zeile_final = ws_mod.ursachen_fuer(pathlib.Path("probe.py"), b"a = 1", "a = 1")
        if not any("finales" in u for u in probe_final):
            probleme.append("Whitespace finales Newline nicht gemeldet")
        if zeile_final != 1:
            probleme.append(f"Whitespace finales Zeile falsch: {zeile_final}")
        probe_tab, zeile_tab = ws_mod.ursachen_fuer(pathlib.Path("probe.py"), b"a\t= 1\n", "a\t= 1\n")
        if not any("Tab" in u for u in probe_tab):
            probleme.append("Whitespace Tab in py nicht gemeldet")
        if zeile_tab != 1:
            probleme.append(f"Whitespace Tab Zeile falsch: {zeile_tab}")
        probe_tab2, zeile_tab2 = ws_mod.ursachen_fuer(pathlib.Path("probe.py"), b"a = 1\n" + b"b\t\n", "a = 1\n" + "b\t\n")
        if zeile_tab2 != 2:
            probleme.append(f"Whitespace Tab Zeile 2 falsch: {zeile_tab2}")
        probe_gd_tab, _ = ws_mod.ursachen_fuer(pathlib.Path("probe.gd"), b"\ta = 1\n", "\ta = 1\n")
        if any("Tab" in u for u in probe_gd_tab):
            probleme.append("Whitespace darf Tabs in .gd nicht melden")
    except Exception as e:
        probleme.append(f"Whitespace Selbsttest Ausnahme: {e}")
