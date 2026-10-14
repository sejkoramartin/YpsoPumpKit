# Experimentální integrace Tria

Aktivní směr vývoje od 14. 10. 2026. Workflow aplikace Loop je vypnuté; jeho soubory zůstávají historickým prototypem.

## Připnutý základ

[Trio 1.0.2](https://github.com/nightscout/Trio/tree/0b29cd53415e7f0e668677749cad8daf81c68c2f), commit `0b29cd53415e7f0e668677749cad8daf81c68c2f`. Submoduly se stahují na revizích z tohoto commitu. Trio samo používá fork LoopKit; nepokračujeme ve vývoji aplikace Loop.

`Integration/Trio/simulator.patch` připojuje lokální Swift Package YpsoPumpSimulator do cíle Trio. Katalog i onboarding nabízejí pouze MockPumpManager. Obnova uloženého stavu odmítá identifikátory skutečných pump a při připojení manageru je kontrolován jeho konkrétní typ. Katalog CGM obsahuje pouze žádný senzor a simulátor.

Syntetické rámce procházejí parserem YpsoPumpKit. Most nastaví zásobník 123,45 U, baterii 4/5, pozastavený stav a chyby při bolusu či dočasném bazálu. Další události simuluje MockKit. Není to úplný YpsoPumpManager ani ovladač skutečné pumpy. Debug UI MockKit může měnit simulovaný stav; aplikace nemá fyzický Ypso transport.

## Ověření bez Macu

V GitHub Actions spusťte **Trio simulator build and tests**. Workflow připraví izolovaný checkout, ověří zdrojové podmínky, sestaví testovací aplikaci, spustí `YpsoTrioIsolationTests` a poté pořídí snímek spuštěné aplikace. Výsledky jsou v artefaktu `trio-simulator-results`. Samotný snímek není důkazem dokončeného onboardingu ani funkčnosti všech obrazovek.

Používá Xcode 26.5 podle upstream build workflow a ad-hoc podpis v simulátoru. Nepotřebuje Apple secrets. Zachovává deployment target Tria (iOS 17.6), nepřepisuje globálně verze závislostí. Zdrojová kontrola nenahrazuje kompilaci a runtime testy. Plná upstream sada testů očekává skutečné pumpy v katalogu a není testovací sadou této omezené varianty.

## iPhone a TestFlight — další etapa

Uživatel má placený Apple Developer účet. Tento první prototyp se přesto smí kompilovat pouze pro iOS Simulator (`#error` pro fyzické zařízení). Nenahrává IPA ani nic do App Store Connect.

Před TestFlight je nutné ověřit izolaci na zařízení, nahradit omezení cílové platformy kontrolami konfigurace pro čistě simulovanou aplikaci, zachovat samostatné bundle ID a app group a připravit podepsané sestavení. Změna nesmí umožnit fyzický transport pumpy. Následně bude potřeba nastavit tým, identifikátory a podpisová oprávnění podle [Trio Browser Build](https://triodocs.org/install/build/browser/browser-build-overview/). Soukromé klíče a hesla patří do GitHub Secrets, nikoli do chatu nebo zdrojového kódu. Standardní workflow Tria nelze bez úprav považovat za bezpečnou distribuční cestu pro tuto experimentální variantu.

CamAPS FX ani konfigurace fyzické YpsoPump se nemění. Trio YpsoPump standardně nepodporuje.

## Ověřený výsledek 14. 10. 2026

[Běh 38627648052](https://github.com/sejkoramartin/YpsoPumpKit/actions/runs/38627648052), zdrojový commit `58d1dcc`:

- iOS sestavení přes Xcode 26.5 prošlo.
- Swift Testing skutečně spustil 2 testy v sadě `Ypso simulator isolation`; oba prošly (`TEST SUCCEEDED`).
- Aplikace byla nainstalována a spuštěna v iOS Simulatoru; snímek `trio-launch.png` zobrazuje úvodní onboarding „Hi there!“.
- Celý onboarding ani propojení obrazovek s pumpou nebyly automatizovaně proklikány. Snímek není důkazem tohoto chování.
- Samostatný balíček prošel 19 XCTest testy na Ubuntu a CI balíčku na Linuxu/macOS.
- Podepsané sestavení pro iPhone ani upload do TestFlight zatím neproběhly.
