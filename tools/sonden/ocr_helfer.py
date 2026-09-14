# -*- coding: utf-8 -*-
"""OCR-Helfer — optionales Dev-Werkzeug, kein Gate.

Liest HUD-Zahlen aus einem Bildausschnitt. Projekt-abgestimmt: Papier-Hintergrund,
Pixel-Font. Wenn tesseract/pytesseract fehlt, meldet sich der Helfer als
"nicht verfuegbar" und pruef_sonden wirft keinen Befund — reines Dev-Werkzeug.

Verwendung nur aus tools/sonden/pruef_sonden heraus, nie aus Spielcode.
"""

from pathlib import Path
import shutil

try:
    from PIL import Image as PILImage  # type: ignore
except Exception:  # Pillow optional — Sonden pruefen nie hart darauf.
    PILImage = None  # type: ignore

PROJEKT_STAMM = Path(__file__).resolve().parent.parent.parent


def verfuegbar() -> tuple[bool, str]:
    if shutil.which("tesseract") is None:
        return False, "tesseract nicht im PATH"
    try:
        import pytesseract  # type: ignore  # noqa: F401
    except Exception as e:
        return False, f"pytesseract fehlt: {e}"
    if PILImage is None:
        return False, "Pillow fehlt"
    return True, "ok"


def lese_zahl(bild_pfad: Path | str, *, whitelist: str = "0123456789:.", psm: int = 7) -> tuple[str, str]:
    """Gibt (text, diagnose) zurueck. Diagnose erklaert Vorverarbeitung."""
    ok, grund = verfuegbar()
    if not ok:
        return "", grund
    import pytesseract  # type: ignore

    pfad = Path(bild_pfad)
    if not pfad.is_file():
        return "", f"Bild fehlt: {pfad}"
    try:
        img = PILImage.open(pfad)  # type: ignore[union-attr]
    except Exception as e:
        return "", f"Pillow open fehlgeschlagen: {e}"

    # Projekt-Profil: 3x upscale, Graustufen, Schwellwert auf hellem Papier.
    try:
        w, h = img.size
        img = img.resize((w * 3, h * 3), PILImage.NEAREST)  # type: ignore[union-attr]
        img = img.convert("L")  # type: ignore[union-attr]
        # Unter 170 = Schrift, darueber Papier — harter Schnitt passt zu unserem Atlas.
        img = img.point(lambda p: 0 if p < 170 else 255, mode="1")  # type: ignore[union-attr]
        cfg = f"--psm {psm} -c tessedit_char_whitelist={whitelist}"
        text = pytesseract.image_to_string(img, config=cfg)
        diagnose = f"ocr profil=papier psm={psm} whitelist={whitelist} groesse={w}x{h}->3x"
        return text.strip(), diagnose
    except Exception as e:
        return "", f"ocr fehlgeschlagen: {e}"
