# -*- coding: utf-8 -*-
"""Vertragstest fuer Kern_Hash (core/logic/kern_hash.gd).

Kern_Hash ist die einzige Stelle, die Hashwerte fuer Seed-Ableitung
berechnet. Die Welt ist deshalb nur so beständig wie seine Zahlen: Ein
Engine-Wechsel, ein Werkzeug-Wechsel oder eine stillschweigende Formel-
Aenderung wuerde aus derselben Welt eine andere machen. Dieser Test spiegelt
die Formel in Python, prueft sie gegen die oeffentlichen FNV-1a-Pruefwerte
der Referenz, friert die Ausgaenge als Goldwerte ein und beweist, dass die
63-Bit-Folge des Projekts mit dem urspruenglichen NamensGenerator-Vertrag
identisch ist. Weicht eine Zahl ab, bricht der Vertrag hier laut, nicht erst
im Spielstand eines Spielers.

Warum 63 Bit: GDScript-Zahlen sind vorzeichenbehaftete 64-Bit-Werte. Die
echte FNV-Basis 0xcbf29ce484222325 passt dort nicht als Literal, das
hoechste Bit stirbt ohnehin an der ersten 63-Bit-Maske. Das Projekt rechnet
deshalb die FNV-1a-Folge von Anfang an in der 63-Bit-Welt; fuer jeden
nichtleeren Text ist das Ergebnis genau der echte FNV-1a-64-Wert, gemaskt
auf 63 Bit.
"""
import pathlib
import re

PROJEKT = pathlib.Path(__file__).resolve().parent
HASH_DATEI = PROJEKT / "core" / "logic" / "kern_hash.gd"

# Echte FNV-1a-64-Weltliteratur.
FNV_OFFSET_BASIS = 0xCBF29CE484222325  # 14695981039346656037, echte Basis
FNV_PRIM = 0x100000001B3               # 1099511628211
MASK_63_BIT = (1 << 63) - 1
MASK_64_BIT = (1 << 64) - 1

# Die 63-Bit-Folge der Basis, wie sie in der GDScript-Datei steht: Das
# Literal 0xcbf29ce484222325 ueberlaeuft die Vorzeichenwelt, die Datei
# traegt seinen auf 63 Bit gemaskten Wert als dezimal Zahl.
FOLGE_BASIS_63 = FNV_OFFSET_BASIS & MASK_63_BIT

# Oeffentliche FNV-1a-64-Pruefwerte der Referenz.
FNV_REFERENZ = {
    "": 0xCBF29CE484222325,
    "a": 0xAF63DC4C8601EC8C,
    "foobar": 0x85944171F73967E8,
}


def _fnv_wort(text: str) -> int:
    """Bit-exakter Python-Spiegel von Kern_Hash.wort."""
    wert = FOLGE_BASIS_63
    for zeichen in text:
        wert ^= ord(zeichen)
        wert = (wert * FNV_PRIM) & MASK_63_BIT
    return wert


def _schritt(wert: int, zahl: int) -> int:
    """Bit-exakter Python-Spiegel von Kern_Hash._schritt."""
    gemaskt = zahl & MASK_63_BIT
    for durchlauf in range(4):
        stueck = (gemaskt >> (durchlauf * 8)) & 0xFF
        wert ^= stueck
        wert = (wert * FNV_PRIM) & MASK_63_BIT
    return wert


def _vektor(x: int, y: int) -> int:
    """Bit-exakter Python-Spiegel von Kern_Hash.vektor."""
    wert = FOLGE_BASIS_63
    wert = _schritt(wert, x)
    wert = _schritt(wert, y)
    return wert


def _wort_gesalzen(text: str, salz: str) -> int:
    """Bit-exakter Python-Spiegel von Kern_Hash.wort_gesalzen."""
    erst = _fnv_wort(salz + "\x1f" + text)
    return _fnv_wort(salz + "\x1e" + str(erst))


def _urspruenglicher_namens_hash(text: str) -> int:
    """Emulation des alten Pop_NamensGenerator.hash aus dem Zeitpunkt vor
    der Kern_Hash-Umstellung: Die Basis wird aus zwei Halbworten zur
    64-Bit-Zahl zusammengesetzt (in GDScript als Vorzeichenzahl negativ),
    das erste Zeichen XOR-et in der 64-Bit-Welt, danach maskiert jeder
    Schritt auf 63 Bit."""
    wert = FNV_OFFSET_BASIS & MASK_64_BIT
    for index, zeichen in enumerate(text):
        wert = (wert ^ ord(zeichen)) & MASK_64_BIT
        wert = (wert * FNV_PRIM) & MASK_63_BIT if index > 0 else \
            ((wert * FNV_PRIM) & MASK_64_BIT) & MASK_63_BIT
    return wert


def _lies_kern_hash_quelle() -> str:
    return HASH_DATEI.read_text(encoding="utf-8")


def test_offset_basis_ist_die_gemaskte_folge():
    """Die Datei traegt die auf 63 Bit gemaskte echte FNV-Basis. Kein
    anderer Startwert ist vertraeglich mit dem Seed-Vertrag."""
    quelle = _lies_kern_hash_quelle()
    treffer = re.search(r"const\s+FNV_OFFSET_BASIS:\s*int\s*=\s*(\d+)", quelle)
    assert treffer is not None, "FNV_OFFSET_BASIS fehlt oder wurde umbenannt"
    assert int(treffer.group(1)) == FOLGE_BASIS_63, (
        "FNV_OFFSET_BASIS wurde veraendert: %s statt %d (0xcbf29ce484222325 "
        "gemaskt auf 63 Bit)" % (treffer.group(1), FOLGE_BASIS_63)
    )


def test_fnv_prims_ist_vertragsbestandteil():
    """Der FNV-Prims 1099511628211 ist Vertragsbestandteil; jede Aenderung
    bricht alle Seed-Ketten und muss hier laut scheitern."""
    quelle = _lies_kern_hash_quelle()
    treffer = re.search(r"const\s+FNV_PRIM:\s*int\s*=\s*(\d+)", quelle)
    assert treffer is not None, "FNV_PRIM fehlt oder wurde umbenannt"
    assert int(treffer.group(1)) == FNV_PRIM, (
        "FNV_PRIM wurde veraendert: %s statt %d" % (treffer.group(1), FNV_PRIM)
    )


def test_63_bit_maske_bleibt_stehen():
    """Die 63-Bit-Maske muss in der GDScript-Datei stehen bleiben; sie ist
    der Grund, warum alle Werte in die Vorzeichenwelt von GDScript passen
    und alle Folgen reproduzierbar bleiben."""
    quelle = _lies_kern_hash_quelle()
    assert "0x7FFFFFFFFFFFFFFF" in quelle, (
        "Die 63-Bit-Maske 0x7FFFFFFFFFFFFFFF fehlt in kern_hash.gd; ohne "
        "sie laufen die Werte aus der GDScript-Zahlenwelt"
    )


def test_spiegel_trifft_die_oeffentlichen_fnv_pruefwerte():
    """Die oeffentlichen FNV-1a-64-Pruefwerte der Referenz, gemaskt auf die
    63-Bit-Welt des Projekts, muessen vom Spiegel getroffen werden. Sie
    entkraeften jeden Verdacht, die Testformel selbst sei ein Tippfehler:
    Ein Vertragstest, der nicht an der Weltliteratur haengt, waechzt vor
    sich selbst."""
    for text, erwartet_64 in FNV_REFERENZ.items():
        erwartet = erwartet_64 & MASK_63_BIT if text != "" else FOLGE_BASIS_63
        assert _fnv_wort(text) == erwartet, (
            "FNV-Spiegel weicht fuer %r ab: %d statt %d"
            % (text, _fnv_wort(text), erwartet)
        )


def test_vertrag_gilt_weiter_fuer_den_urspruenglichen_generator():
    """Die Umstellung von Pop_NamensGenerator.hash auf Kern_Hash.wort muss
    zahlenstumm gewesen sein: Fuer jeden nichtleeren Text liefern der alte
    zusammengesetzte Weg und der neue Weg dieselbe Folge. Wuerde hier eine
    Zahl abweichen, haette die Umstellung stillschweigend Saatgut
    vertauscht."""
    for text in ("wald_keimpunkt_3_rasse", "hoehe", "karte_expansion_7", "x"):
        assert _fnv_wort(text) == _urspruenglicher_namens_hash(text), (
            "Kern_Hash bricht den alten Vertrag fuer %r: %d statt %d"
            % (text, _fnv_wort(text), _urspruenglicher_namens_hash(text))
        )


def test_goldwerte_wort():
    """Goldwerte der Wort-Hashes der drei Noise-Arten beider Generator-
    Stellen. Ein Engine- oder Formel-Wechsel veraendert mindestens einen
    dieser Werte."""
    assert _fnv_wort("hoehe") == 4675452723533303992
    assert _fnv_wort("feuchte") == 906974356213425379
    assert _fnv_wort("feuchtigkeit") == 8332030307086953697
    assert _fnv_wort("temperatur") != _fnv_wort("feuchtigkeit"), (
        "'temperatur' und 'feuchtigkeit' muessen verschiedene Werte tragen, "
        "sonst kollidieren die Noise-Arten von Welt_Generator und "
        "Welt_FeldAnalyser stillschweigend"
    )


def test_goldwerte_vektor():
    """Goldwerte des Positions-Hashes, einschliesslich negativer
    Untergrund-Koordinaten. Welt_ObjektDarsteller urteilt mit diesen
    Zahlen ueber Beeren, der Untergrund traegt negative Z-Ebenen."""
    assert _vektor(0, 0) == 2938590176187398597
    assert _vektor(-1, -1) == 933681686290597949
    assert _vektor(1000, 2000) == 2382384676341877729
    assert _vektor(640, 512) == 3231750147723993573


def test_goldwerte_wort_gesalzen():
    """Goldwerte der gesalzenen Ableitung. Der Kardinalwert ist die
    Karten-Expansion: Welt_MapFabrik leitet daraus den Seed jeder neuen
    Karte ab. Steigt hier eine Zahl, faellt die Welt anders aus."""
    assert _wort_gesalzen("karte_0", "karte_expansion") == 7212530028788668122
    assert _wort_gesalzen("x", "rasse") == 4723535160739591083


def test_gleicher_wert_verschiedene_rollen_kollidiert_nicht():
    """Das Salz trennt die Rollen: Derselbe Eingangswert als Name, als
    Position oder als Identitaet darf nicht auf denselben Hash fallen."""
    for eingang in ("karte_0", "wald", "x"):
        werte = {
            _fnv_wort(eingang),
            _wort_gesalzen(eingang, "rasse"),
            _wort_gesalzen(eingang, "fraktion"),
            _wort_gesalzen(eingang, "karte_expansion"),
        }
        assert len(werte) == 4, (
            "Rollen-Kollision bei Eingang %r: ungesalzen und gesalzen "
            "fallen auf denselben Wert" % eingang
        )


def test_vektor_und_wort_sind_getrennte_welten():
    """Die Byte-Sequenz des Vektors wird aus Zahlenworten gebaut; sie
    darf nicht zufaellig mit dem Wort-Hash derselben Darstellung
    zusammenfallen."""
    for x, y in ((0, 0), (-1, -1), (640, 512), (1000, 2000)):
        als_vektor = _vektor(x, y)
        als_wort = _fnv_wort("%d:%d" % (x, y))
        assert als_vektor != als_wort, (
            "Vektor %d,%d faellt mit dem Wort-Hash seiner "
            "Textdarstellung zusammen" % (x, y)
        )


def test_kern_hash_wird_von_den_seed_stellen_genutzt():
    """Die Verdrahtung: Alle frueheren Builtin-hash-Stellen muessen
    Kern_Hash rufen, damit der Vertrag nicht an einer Nebentuer
    vorbeigeht."""
    stelle_fabrik = (
        PROJEKT / "world" / "logic" / "kategorie_welt" / "welt_map_fabrik.gd"
    ).read_text(encoding="utf-8")
    assert "Kern_Hash.wort_gesalzen(world.world_name" in stelle_fabrik, (
        "Welt_MapFabrik leitet den Expansions-Seed nicht mehr aus "
        "Kern_Hash ab"
    )
    stelle_ladung = (
        PROJEKT / "world" / "logic" / "kategorie_welt" / "welt_ladevorgang.gd"
    ).read_text(encoding="utf-8")
    assert "Kern_Hash.wort(welt_name)" in stelle_ladung, (
        "Welt_Ladevorgang leitet den Namens-Seed nicht mehr aus "
        "Kern_Hash ab"
    )
    stelle_darsteller = (
        PROJEKT / "world" / "logic" / "kategorie_welt" / "welt_objekt_darsteller.gd"
    ).read_text(encoding="utf-8")
    assert "Kern_Hash.vektor(Vector2i" in stelle_darsteller, (
        "Welt_ObjektDarsteller urteilt ueber Beeren nicht mehr mit "
        "Kern_Hash.vektor"
    )


def test_kein_eingebauter_hash_in_den_seed_stellen():
    """Der Builtin hash() hat in den drei Seed-Stellen nichts verloren;
    er ist nur pro Engine-Version stabil und wuerde bei einem Wechsel die
    Welt drehen."""
    verdachtige = [
        "world/logic/kategorie_welt/welt_map_fabrik.gd",
        "world/logic/kategorie_welt/welt_ladevorgang.gd",
        "world/logic/kategorie_welt/welt_objekt_darsteller.gd",
    ]
    for rel in verdachtige:
        quelle = (PROJEKT / rel).read_text(encoding="utf-8")
        assert re.search(r"(?<![\w.])hash\s*\(", quelle) is None, (
            "%s ruft wieder den eingebauten hash(); die Ableitung gehoert "
            "in Kern_Hash" % rel
        )
