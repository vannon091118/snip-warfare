# -*- coding: utf-8 -*-
"""Sonden OCR Brücke. Eigene Zuständigkeit: Ein Bild optional per OCR lesen."""

from pathlib import Path

from tools.preflight.kern import PROJEKT_STAMM


def ocr_fuer_bild(png_pfad: Path, sid: str) -> str | None:
    if "sonden_bilder" not in str(png_pfad) or not str(png_pfad).endswith(".png"):
        return None
    try:
        import importlib.util as _ilu
        spec = _ilu.spec_from_file_location("_ocr", str(PROJEKT_STAMM / "tools" / "sonden" / "ocr_helfer.py"))
        mod = _ilu.module_from_spec(spec)
        assert spec.loader is not None
        spec.loader.exec_module(mod)
        ok, _grund = mod.verfuegbar()
        if not ok:
            return None
        fs = PROJEKT_STAMM / Path(str(png_pfad).replace("res://", ""))
        if not fs.is_file():
            return None
        txt, diag = mod.lese_zahl(fs)
        return f"OCR {sid}: '{txt[:40]}' {diag}"
    except Exception:
        return None
