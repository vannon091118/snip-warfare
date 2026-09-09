# Godot Headless Referenzpfad

Dieser Ordner enthält **keine Binärdatei** im Repo.

Relativer Referenzpfad extern: `C:/Users/Vannon/Desktop/godu/godot_console.exe` (173 MB, nicht ins Repo kopieren).
Lokaler Pfad wenn vorhanden: `tools/godot/godot.exe` oder `tools/godot/godot_console.exe`.

Preflight löst in dieser Reihenfolge auf (fail-closed):
1. `GODOT_BIN` Umgebungsvariable falls gesetzt
2. `--godot-befehl PFAD` Flag
3. `tools/godot/godot_console.exe` falls vorhanden
4. `tools/godot/godot.exe` falls vorhanden
5. `godot` im PATH
6. Fallback extern `C:/Users/Vannon/Desktop/godu/godot_console.exe`

Ohne gefundenen Godot bricht der Preflight mit **E018 fail-closed** ab.
Scope-getrennt: `python tools/preflight.py --kategorie godot` führt nur den Engine Lauf aus,
`--kategorie klassen --kategorie shinon` läuft ohne Engine. Nach jeder Code Änderung
muss der passende Scope grün sein, ein Full Run wird nicht erzwungen.

Debugging: Jede Godot Zeile wird über `tools/debug_uebersetzer.py` in
E016/E017/E018 übersetzt. E016 Parse, E017 unbekannte Definition, E018 Warning/Hidden.
Siehe `python tools/preflight.py --hilfe-fehler` für Zuordnung.

Prozess Kill ist fail-closed: Timeout 300s, hängende Godot Prozesse werden
gekilled und als E018 gemeldet, kein stilles Grün.
