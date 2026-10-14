# Architektura a další postup

## Současný stav

```text
Synthetic SimulationScenario
  -> SimulatedPump actor : StatusFrameSource
  -> StatusReader (explicit profile)
  -> FrameAssembler -> CRC -> SystemStatus
  -> SimulatorAdapter -> CLI / XCTest

Loop onboarding / restoration
  -> SimulationScenario.parsedStatus() (stejný parser)
  -> YpsoLoopSimulatorBridge
  -> LoopKit MockPumpManager (pouze paměť)
```

Jádro je bez LoopKitu, HealthKitu, UIKit a externích závislostí. Transport je asynchronní čtecí rozhraní pro offline plaintext rámce. Obecné rozhraní slouží parserovým fixture testům; aplikační adaptér přijímá jen konkrétní `SimulatedPump`. Dávkovací metody vždy selžou a nic neserializují.

Loop most přenáší jen zásobník a normalizovaný ukazatel baterie (dílky/5, nikoli měřené procento), explicitně nastaví pozastavenou simulaci a chyby bolus/TBR. Nevyvozuje stav dávkování z neznámého protokolu. Po inicializaci simulované události spravuje MockKit; most neimplementuje pravidelnou synchronizaci ani nový PumpManager identifier. Obnovení uloženého mock stavu znovu aplikuje počáteční scénář. UI může dál zobrazovat upstream název „Pump Simulator“; nabídka výběru nese „YpsoPump — SIMULATION ONLY“.

## LoopKit kontrakty

Studovány `LoopKit/DeviceManager/PumpManager.swift`, `MockKit/MockPumpManager.swift`, `MockKitUI/MockPumpManager+UI.swift`, Loop `Common/Models/PumpManager.swift`, `DeviceDataManager` a `PluginManager`.

Plný budoucí adaptér musí splnit `PumpManager` a `PumpManagerUI`, nikoli jen vracet počet jednotek. Zahrnuje:

- `rawState` s verzováním a migrací, stav/observer/delegate queues, `ensureCurrentPumpData` a čas poslední úspěšné synchronizace;
- hlášení zásobníku a událostí `NewPumpEvent` přes delegáta, deduplikaci historie a reconciliation nejistých výsledků;
- správné capabilities, delivery limits a rounding, suspend/resume a temp-basal lifecycle;
- onboard/settings/HUD přes samostatný UI target; budoucí plugin bundle s identifikátorem a principal class.

Současný most tuto velkou sadu rozhraní používá prostřednictvím upstream MockKit. Nelze jej vydávat za hotový YpsoPumpManager. LoopKit Package.swift navíc v prozkoumané hlavní větvi výslovně označuje vlastní SPM podporu za nedokončenou; iOS integrace proto používá existující workspace/frameworky, ne Linux build LoopKitu.

## Navržené oddělení příštích modulů

| Modul | Zodpovědnost | Stav |
|---|---|---|
| YpsoPumpKit | datové typy a přísné offline parsování | hotový základ |
| YpsoPumpSimulator | scénáře, chyby, actor, sealed test adapter | hotový základ |
| YpsoPumpKitLoopAdapter | vlastní PumpManager, persistence, LoopKit události | pouze bootstrap přes MockKit |
| YpsoPumpKitUI | onboarding/HUD se zřetelnou simulací | zatím používá MockKitUI |
| případný crypto/provisioning modul | ověřené AEAD test vektory a lifecycle | neimplementován |
| případný BLE transport | fyzické zařízení | mimo současné zadání, nepřipravena aktivace |

## Trio

Trio také používá `PumpManagerUI`, delegáty a vlastní `DeviceDataManager`, ale submodule odkazuje na **loopandlearn/LoopKit**, nikoli nutně stejný LoopKit commit. Sdílet lze jádro a simulátor; adaptér je potřeba kompilovat proti oběma přesným verzím. Není správné předpokládat binární ani zdrojovou kompatibilitu. Trio v tomto projektu nebylo upraveno.

## Další postup v bezpečném rozsahu

1. Spustit workflow Loop simulator build v GitHub Actions (macOS runner), případně otevřít workspace na vlastním Macu. Sestavovat pouze pro iOS Simulator. Ověřit nabídku pump, obnovu stavu a odmítnutí dávkování. Toto je nejbližší neprovedená validační brána.
2. Nahradit bootstrap vlastním **simulator-only** PumpManagerem s odděleným identifierem a verzovanou persistencí; otestovat delegate pořadí, stale data, restart, duplicitní historii a chyby bez úspěšných dávkovacích odpovědí.
3. Rozšířit deterministické scénáře o virtuální čas, pump history, reconnect a nejisté výsledky. Oddělit simulované dávky od libovolného byte encoderu.
4. Provést nezávislou revizi PR #1/#2, získat veřejné anonymizované fixture s doloženým firmwarem a ověřit novější Baz00k schema proti starší hypotéze mode@0 versus @5. Nepoužívat vlastní léčenou pumpu jako testovací zařízení.
5. Samostatně navrhnout a offline otestovat kryptografické obálky, replay/counter pravidla a pády procesu. Nyní není implementován ani key exchange, ani alternativní získávání klíčů.
6. Před jakoukoli případnou změnou rozsahu vyřešit legální a podporovanou cestu provisioning na iOS, zjištění identity zařízení bez Android MAC API, firmware matrix a nezávislou bezpečnostní revizi. Tento krok není autorizací hardwarových testů.
7. Ve veřejném repozitáři udržovat oddělený MIT balíček a upstream atribuce; nevkládat cache, klíče ani pacientská data. CI nesmí vytvářet podepsané buildy pro fyzická zařízení.

Na vašem Ubuntu lze bez Androidu pokračovat v bodech 2–5 v offline rozsahu. macOS/Xcode je nutný pro důvěryhodnou validaci iOS/HealthKit/UIKit integrace. Není potřeba měnit CamAPS FX ani nastavení pumpy.

## Co přinášejí novější AAPS forky pro budoucí adaptér

Baz00k/AndroidAPS a alex-poor/AndroidAPS již mají skutečné experimentální drivery. Pro návrh jsou užitečné zejména rozlišení NotSent/PossiblyApplied/AcceptedUnverified, durable session/write journals, jednotlivé generace spojení a rekonsiliace historie. Žádná jejich léčebná implementace nebyla přenesena do tohoto projektu. Jejich AGPL zdroje nelze bez dalšího převzít do MIT balíčku; zde jsou studovány architektonické principy a formáty dat.
