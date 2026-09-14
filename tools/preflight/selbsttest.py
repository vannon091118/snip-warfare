# -*- coding: utf-8 -*-
"""E000 Selbsttest: Fassade über echte Teil-Domänen."""

from .kern import ERLAUBTE_ZUFALLS_KLASSEN, ZUFALLS_MUSTER, ZEIT_SEED_MUSTER, ERLAUBTE_HASH_KLASSEN, BUILTIN_HASH_MUSTER
from .pruef_determinismus import _sammle_zufallsfundstellen, _sammle_hash_fundstellen, _matrix_zuordnung_aus_code


def selbsttest():
    probleme: list[str] = []
    probe = "extends RefCounted\nclass_name E000_Probe\nvar wert := randi()\n"
    if len(_sammle_zufallsfundstellen(probe, "E000_Probe")) != 1:
        probleme.append("Zufallsdetektor randi() nicht gefunden")
    kern = "extends RefCounted\nclass_name Kern_Zufall\nvar wert := randi()\n"
    if len(_sammle_zufallsfundstellen(kern, "Kern_Zufall")) != 0:
        probleme.append("Zufallsdetektor meldet erlaubte Kern_Zufall")
    mq = 'match str(eintrag.get("name", "")):\n\t"TestA":\n\t\treturn Probe_MutationA.new()\n\t"TestB":\n\t\treturn Probe_MutationB.new()\n'
    if _matrix_zuordnung_aus_code(mq) != {"TestA": "Probe_MutationA", "TestB": "Probe_MutationB"}:
        probleme.append("Matrix-Zuordnung falsch")
    if ZUFALLS_MUSTER.search(probe) is None:
        probleme.append("Zufallsmuster findet randi() nicht")
    if "Kern_Zufall" not in ERLAUBTE_ZUFALLS_KLASSEN:
        probleme.append("Kern_Zufall fehlt")
    hash_probe = 'extends RefCounted\nclass_name E000_HashProbe\nvar wert := hash("x")\n'
    if len(_sammle_hash_fundstellen(hash_probe, "E000_HashProbe")) != 1:
        probleme.append("Hash randi() nicht gefunden")
    hash_kern = 'extends RefCounted\nclass_name Kern_Hash\nvar wert := hash("x")\n'
    if len(_sammle_hash_fundstellen(hash_kern, "Kern_Hash")) != 0:
        probleme.append("Hash meldet erlaubte Kern_Hash")
    meth_probe = 'extends RefCounted\nclass_name E000_HashProbe2\nvar wert := irgendein_objekt.hash("x")\n'
    if len(_sammle_hash_fundstellen(meth_probe, "E000_HashProbe2")) != 0:
        probleme.append("Hash meldet objekt.hash() faelschlich")
    if BUILTIN_HASH_MUSTER.search('Kern_Hash.wort_gesalzen("x", "y")') is not None:
        probleme.append("Hash meldet Kern_Hash.wort_gesalzen faelschlich")
    if "Kern_Hash" not in ERLAUBTE_HASH_KLASSEN:
        probleme.append("Kern_Hash fehlt")
    uhr = ["Time.get_unix_time_from_system()", "Time.get_datetime_string_from_system()", "Time.get_datetime_dict_from_system()", "Time.get_time_dict_from_system()", "Time.get_time_string_from_system()", "Time.get_ticks_msec()", "Time.get_ticks_usec()", "Time.get_ticks_nsec()", "OS.get_unix_time()", "OS.get_ticks_msec()", "OS.get_ticks_usec()", "OS.get_system_time_msecs()", "OS.get_datetime()"]
    for u in uhr:
        if ZEIT_SEED_MUSTER.search(u) is None:
            probleme.append(f"Zeit ueberliest {u}")
    for z in ["var s := Time.get_unix_time_from_datetime_dict(a)", "var iso := Time.get_datetime_string_from_datetime_dict(a, false)", "var t := Kern_Weltuhr.ticks_aus_faktor(f)"]:
        if ZEIT_SEED_MUSTER.search(z) is not None:
            probleme.append(f"Zeit meldet Konvertierung faelschlich: {z[:30]}")
    from .selbsttest_version import pruefe as pruefe_version
    pruefe_version(probleme)
    try:
        from .pruef_index import pruefe_index  # noqa
        from index.kern import erste_abweichung
        if erste_abweichung("a\nb\n", "a\nc\n") != (2, "b", "c"):
            probleme.append("Index Abweichung nicht gefunden")
        if erste_abweichung("gleich\n", "gleich\n") is not None:
            probleme.append("Index meldet Gleichheit faelschlich")
    except ImportError:
        probleme.append("Index nicht importierbar")
    from .selbsttest_shinon import pruefe as pruefe_shinon
    pruefe_shinon(probleme)
    from .selbsttest_whitespace import pruefe as pruefe_ws
    pruefe_ws(probleme)
    return probleme
