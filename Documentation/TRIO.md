# Experimentální integrace Tria

Aktivní směr vývoje od 14. 10. 2026. Workflow aplikace Loop je vypnuté; jeho soubory zůstávají historickým prototypem.

## Připnutý základ

[Trio 1.0.2](https://github.com/nightscout/Trio/tree/0b29cd53415e7f0e668677749cad8daf81c68c2f), commit `0b29cd53415e7f0e668677749cad8daf81c68c2f`. Submoduly se stahují na revizích z tohoto commitu. Trio samo používá fork LoopKit; nepokračujeme ve vývoji aplikace Loop.

`Integration/Trio/simulator.patch` připojuje lokální Swift Package YpsoPumpSimulator do cíle Trio. Katalog i onboarding nabízejí pouze MockPumpManager. Obnova uloženého stavu odmítá identifikátory skutečných pump a při připojení manageru je kontrolován jeho konkrétní typ. Katalog CGM obsahuje pouze žádný senzor a simulátor.

Syntetické rámce procházejí parserem YpsoPumpKit. Most nastaví zásobník 123,45 U, baterii 4/5, pozastavený stav a chyby při bolusu či dočasném bazálu. Další události simuluje MockKit. Není to úplný YpsoPumpManager ani ovladač skutečné pumpy. Debug UI MockKit může měnit simulovaný stav; aplikace nemá fyzický Ypso transport.

## Ověření bez Macu

V GitHub Actions spusťte **Trio simulator build and tests**. Workflow připraví izolovaný checkout, ověří zdrojové podmínky, sestaví testovací aplikaci, spustí `YpsoTrioIsolationTests` a poté pořídí snímek spuštěné aplikace. Výsledky jsou v artefaktu `trio-simulator-results`. Samotný snímek není důkazem dokončeného onboardingu ani funkčnosti všech obrazovek.

Používá Xcode 26.5 podle upstream build workflow a ad-hoc podpis v simulátoru. Nepotřebuje Apple secrets. Zachovává deployment target Tria (iOS 17.6), nepřepisuje globálně verze závislostí. Zdrojová kontrola nenahrazuje kompilaci a runtime testy. Plná upstream sada testů očekává skutečné pumpy v katalogu a není testovací sadou této omezené varianty.

## iPhone a TestFlight — příprava

Varianta pro iPhone má pevný příznak `YPSO_SIMULATION_ONLY`. Bez něj kompilace skončí chybou. Katalog a obnova managerů stále povolují pouze MockPumpManager. Bluetooth provider nevytváří CBCentralManager a zamítá žádost o autorizaci; konstrukce BluetoothTransmitter selže před jakoukoli komunikací. Obnova hardwarového CGM vrací nil. Úvodní nastavení vysvětluje simulaci a nepoptává Bluetooth oprávnění.

Apple Health uploady, mazání a žádosti o oprávnění jsou blokované pevnou politikou simulace, aby se testovací data nedostala do skutečného zdravotního úložiště. To není audit veškeré síťové aktivity upstream aplikace: např. obecné služby Tria zůstávají ve zdrojích. Pro první test používejte čerstvou instalaci, pouze syntetické hodnoty a žádné účty vzdálených zdravotních služeb.

Workflow **Trio unsigned iPhone build** ověřuje Release kompilaci pro fyzickou platformu bez podpisu, instalace a uploadu. Úspěch tohoto buildu není důkazem běhu na iPhonu. Simulator workflow ověřuje katalog, syntetickou telemetrii, odmítnutí dávkování a offline Bluetooth provider.

Konfiguraci pro budoucí podpis lze připravit pomocí:

```sh
APPLE_TEAM_ID=YOURTEAMID python3 Scripts/write-trio-signing-config.py /tmp/ConfigOverride.xcconfig
```

Skript vyžaduje desetiznakové Team ID, odmítá přepsat existující výstupní soubor a pouze vytvoří konfiguraci. S volbou `--checkout /cesta/k/cerstvemu/Trio` sjednotí také hlavní Config.xcconfig a jeho override, protože Fastlane čte hlavní soubor přímo. Tato volba odmítá dříve přizpůsobenou identitu a je určena pouze pro čerstvý checkout připravený naším skriptem. Nic neregistruje u Apple. Bundle ID má tvar `org.ypsopumpkit.TEAMID.trio.sim`, app group `group.org.ypsopumpkit.TEAMID.trio.sim` a název **Ypso Trio SIM**. Konfigurace patří až do samostatného checkoutu, nikoli do běžné instalace Tria.

Uživatel má placený Apple Developer účet. Stále zbývá registrace identifikátorů, App Store Connect záznam, distribuční certifikát a provisioning profiles. Soukromé klíče patří do GitHub Secrets, nikoli do chatu nebo zdrojů. Podepsaný build a upload nejsou v tomto kroku prováděny. Celý onboarding a chování na fyzickém iPhonu se musí ještě ověřit; nesmí se přitom připojit skutečná pumpa. CamAPS FX ani nastavení pumpy se nemění.

## Ověřený výsledek 14. 10. 2026

[Běh 38627648052](https://github.com/sejkoramartin/YpsoPumpKit/actions/runs/38627648052), zdrojový commit `58d1dcc`:

- iOS sestavení přes Xcode 26.5 prošlo.
- Swift Testing skutečně spustil 2 testy v sadě `Ypso simulator isolation`; oba prošly (`TEST SUCCEEDED`).
- Aplikace byla nainstalována a spuštěna v iOS Simulatoru; snímek `trio-launch.png` zobrazuje úvodní onboarding „Hi there!“.
- Celý onboarding ani propojení obrazovek s pumpou nebyly automatizovaně proklikány. Snímek není důkazem tohoto chování.
- Samostatný balíček prošel 19 XCTest testy na Ubuntu a CI balíčku na Linuxu/macOS.
- Podepsané sestavení pro iPhone ani upload do TestFlight zatím neproběhly.

## Ověření přípravy pro iPhone — commit 5b195d9

- [Simulátorový běh 38633729946](https://github.com/sejkoramartin/YpsoPumpKit/actions/runs/38633729946): 4 Swift Testing testy ve 2 sadách prošly. Ověřují katalog a obnovu, syntetický stav, offline Bluetooth provider a odmítnutí bolusu i dočasného bazálu v MockPumpManager.
- [Nepodepsaný Release build 38633734547](https://github.com/sejkoramartin/YpsoPumpKit/actions/runs/38633734547): `BUILD SUCCEEDED` pro `generic/platform=iOS` na Xcode 26.5. Nejde o podepsanou nebo instalovatelnou IPA.
- Spuštění v iOS Simulatoru a snímek úvodní obrazovky byly ověřeny: zobrazuje se **Ypso Trio — SIMULATION ONLY**.
- Blokování Apple Health je kontrolováno ve zdroji, nikoli samostatným runtime testem zápisu do zdravotního úložiště.
- Celý onboarding, skutečné spuštění na iPhonu, podpis, provisioning a TestFlight upload zatím ověřeny nejsou.
- První novější běh odhalil chybějící společný `SystemAlert` po nahrazení Bluetooth obrazovky; opravná revize jej zachovává pro oznámení bez obnovy Bluetooth autorizace.

Generátor podpisové identity byl ověřen lokálně na syntetickém Team ID: hlavní Config.xcconfig a override obsahují shodné Bundle ID a App Group. Neplatné Team ID a přepsání již existujícího výstupu odmítá. Tento test neověřuje registraci ani dostupnost ID u Apple.
