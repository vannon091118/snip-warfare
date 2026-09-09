class_name Orchestrator_Manager
## Kategorie logik: Manager koordiniert Orchestrator Zustände und Einheiten-Zuweisung

signal orchestrator_platziert(status: Orchestrator_Status, konfig: Orchestrator_Konfiguration)

var _orchestratoren: Array[Dictionary] = []  # [{"status": Orchestrator_Status, "konfig": Orchestrator_Konfiguration}, ...]
var _einheit_manager: Einheit_Manager = null
var _welt_modell: Welt_Model = null
var _wald_registry: Welt_Registry = null
var _job_registry: Job_Registry = null

## Kategorie logik: Integration & Tick
func _ready() -> void:
    Kern_Weltuhr.tick.connect(_auf_tick)

func _exit_tree() -> void:
    if Kern_Weltuhr.tick.is_connected(_auf_tick):
        Kern_Weltuhr.tick.disconnect(_auf_tick)

func referenzen_setzen(einheit_manager: Einheit_Manager, welt_modell: Welt_Model, wald_registry: Welt_Registry, job_registry: Job_Registry = null) -> void:
    _einheit_manager = einheit_manager
    _welt_modell = welt_modell
    _wald_registry = wald_registry
    _job_registry = job_registry

func orchestrator_platzieren(konfig: Orchestrator_Konfiguration) -> int:
    var status := Orchestrator_Status.new()
    status.konfigurieren(konfig)
    status.bedarf_pruefen.connect(_auf_bedarf_pruefen)
    status.zustand_geaendert.connect(_auf_status_geaendert)
    var idx := _orchestratoren.size()
    _orchestratoren.append({"status": status, "konfig": konfig})
    return idx

func _auf_tick(_tick_nummer: int, _delta: float) -> void:
    for eintrag in _orchestratoren:
        eintrag.status.tick()

## Kategorie logik: Bedarfsprüfung & Job-Zuweisung
func _auf_bedarf_pruefen(konfig: Orchestrator_Konfiguration) -> void:
    if not _einheit_manager or not _welt_modell or not _wald_registry:
        return

    var untätige_einheiten := _einheiten_im_radius(konfig)

    var sortierte_bedarfe := konfig.bedarfsliste.duplicate(true)
    sortierte_bedarfe.sort(func(a, b): return int(b.get("prioritaet", 1)) <= int(a.get("prioritaet", 1)))

    for bedarf in sortierte_bedarfe:
        if untätige_einheiten.empty():
            break
        var ressource := bedarf.get("ressource", "")
        var job_id := bedarf.get("job_id", "")
        if job_id == "":
            continue

        var menge_remaining := int(bedarf.get("menge", 0))
        while menge_remaining > 0 and not untätige_einheiten.empty():
            var einheit_idx := untätige_einheiten.pop_front()
            if _einheit_manager.job_id_einheit(einheit_idx) != "":
                continue

            var objekt_idx := _naechstes_objekt_fuer_ressource(ressource, konfig.position, konfig.radius)
            if objekt_idx < 0:
                continue

            var ziel_position := _welt_modell.objekt_position(objekt_idx)
            _einheit_manager.job_vergeben(
                einheit_idx,
                job_id,
                Job_Basis.ZielTyp.OBJEKT,
                objekt_idx,
                ziel_position
            )
            menge_remaining -= 1

## Kategorie logik: Radius-Suche
func _einheiten_im_radius(konfig: Orchestrator_Konfiguration) -> Array[int]:
    var gefundene: Array[int] = []
    if not _einheit_manager:
        return gefundene
    var einheiten_anzahl := _einheit_manager.einheit_zahl()
    for index in einheiten_anzahl:
        var position := _einheit_manager.einheit_position(index)
        if position.distance_to(konfig.position) <= konfig.radius and _einheit_manager.job_id_einheit(index) == "":
            gefundene.append(index)
    return gefundene

func _naechstes_objekt_fuer_ressource(ressource: String, zentrum: Vector2, radius: float) -> int:
    if not _welt_modell or not _wald_registry:
        return -1
    var bester_index := -1
    var beste_distanz := INF
    for index in _welt_modell.objekte.size():
        var eintrag := _welt_modell.objekte[index]
        var element_id := str(eintrag.get("element_id", ""))
        if element_id == "":
            continue
        var objekt := _wald_registry.finde_objekt(element_id)
        if objekt == null or str(objekt.arbeits_ressource) != ressource:
            continue
        var objekt_position := _welt_modell.objekt_position(index)
        var distanz := objekt_position.distance_to(zentrum)
        if distanz <= radius and distanz < beste_distanz:
            beste_distanz = distanz
            bester_index = index
    return bester_index