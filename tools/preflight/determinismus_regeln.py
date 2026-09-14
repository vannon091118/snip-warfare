# -*- coding: utf-8 -*-
"""Determinismus Regeln. Eigene Zuständigkeit: Zufall Zeit Hash Muster."""

import re

ERLAUBTE_ZUFALLS_KLASSEN = ("Kern_Zufall",)
ZUFALLS_MUSTER = re.compile(r"\b(randi|randf|randi_range|randf_range|randfn|randomize)\s*\(")
ZEIT_SEED_MUSTER = re.compile(
    r"Time\.get_(?:unix_time|datetime_string|datetime_dict|time_dict|time_string)_from_system"
    r"|Time\.get_ticks_(?:msec|usec|nsec)"
    r"|OS\.get_(?:unix_time|ticks_msec|ticks_usec|ticks_nsec|system_time_msecs|system_time_secs|datetime)\b"
)
ZWEITER_RNG_MUSTER = re.compile(r"\bRandomNumberGenerator\b|\.seed\s*=|randomize\s*\(")
ERLAUBTE_HASH_KLASSEN = ("Kern_Hash",)
BUILTIN_HASH_MUSTER = re.compile(r"(?<![\w.])hash\s*\(")
