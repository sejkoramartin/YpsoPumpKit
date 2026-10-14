# GitHub Actions bez vlastního Macu

V repozitáři otevřete **Actions**. Automatický workflow **Swift package CI** spouští testy na Linuxu a macOS a sestavuje knihovnu pro iOS Simulator. Zelený výsledek znamená úspěch uvedených kroků, nikoli funkčnost fyzické pumpy.

Pro Loop zvolte **Loop simulator build → Run workflow → main**. Běh stáhne veřejný LoopWorkspace na commitu `548b33245198eaae165c094c9c68fe333cb69c05`, inicializuje jeho závislosti a aplikuje `Integration/Loop/simulator.patch`. Očekávaný Loop commit je `c30b5c89b1dc4151628f33f1384dd4796eaeeec2`.

Build používá výhradně iOS Simulator a `CODE_SIGNING_ALLOWED=NO`. Není potřeba Apple účet, certifikát ani klíč pumpy. Workflow nemá zapisovací oprávnění do repozitáře a nepoužívá žádná uživatelská secrets. Výsledkem není IPA pro iPhone ani TestFlight vydání. Artifact `loop-simulator-diagnostics` obsahuje log a případný Xcode result bundle, uchované 7 dní.

Most při založení/obnovení simulátoru přenese syntetický zásobník a normalizované dílky baterie do `MockPumpManager`. Nastaví pozastavený stav a chyby bolus/TBR. Fyzické PumpManagery nejsou povolené a kompilace aplikace pro fyzický iPhone skončí `#error`. Následnou simulaci událostí dál obstarává MockKit; nejde ještě o vlastní plný adaptér.

Běh CI neposkytuje interaktivní vzdálenou plochu. Další etapa jsou automatizované UI testy a záznamy/screenshoty ze simulátoru. Chyby sestavení jsou vývojové výsledky, ne důvod povolit hardware nebo odstranit ochranné kontroly.

Historická výzkumná zpráva popisuje lokální průzkum ze 14. 10. 2026. Velké zdrojové checkouty, raw API snapshoty a lokální build logy nejsou součástí publikace; součástí jsou odkazy a přesné commity. Věty ve zprávě o tehdejší nepublikované pracovní kopii jsou historický stav.
