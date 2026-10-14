# YpsoPump → iOS Loop: zjištění k 14. 10. 2026

Výsledek tohoto projektu je funkční offline Swift knihovna a lokální experiment se simulátorem. **Není doložen hotový veřejný iOS ovladač YpsoPump ani obecně použitelná cesta získání klíčů bez Androidu.** To je výsledek vymezeného průzkumu, ne důkaz neexistence. Žádný fyzický přístroj, účet CamAPS ani výrobní backend nebyl kontaktován.

Nejnovější nalezené **AAPS** implementace jsou `Baz00k/AndroidAPS` a `alex-poor/AndroidAPS`; obsahují skutečný experimentální dávkovací driver. Jejich hlavní větve byly prostudovány z dnešních commitů. Starší SDK/scaffold nejsou celý současný stav. Podrobná [aktualizace a korekce statusu](#aktualizace-skutečné-novější-aaps-integrační-forky) níže vysvětluje, proč simulátor používá třetí profil s dílky baterie.

Přesné head SHA, seznamy větví/PR a lokální checkouty jsou v [INVENTORY.md](INVENTORY.md) a [source-lock.json](source-lock.json). Veřejné podklady pocházejí převážně z komunitního reverse engineeringu; jejich autorův údaj „ověřeno na pumpě“ není naše nezávislé ověření.

## Porovnání nalezených implementací

| Projekt / větev | Skutečně nalezený obsah | Význam a omezení |
|---|---|---|
| [vicktor/ypsomed-pump](https://github.com/vicktor/ypsomed-pump) `main` | Kotlin `pump-common`, `ypso-sdk`, BLE, crypto, history, příkazy a technický popis | Nejucelenější SDK; není samo o sobě hotový AAPS driver. AGPL-3.0. Dokumentace obsahuje zastaralé či rozporné údaje. |
| [SandraK82/ypsopump-research](https://github.com/SandraK82/ypsopump-research) `main` | MIT dokumentace, samostatná testovací Android aplikace, `aaps-driver` | AAPS vrstva obsahuje TODO pro async BLE, profile write, TDD a čas. README výslovně požaduje ověření payloadů a integrace. Kopírování do AAPS neznamená funkční ovladač. |
| [alex-poor PR #1](https://github.com/SandraK82/ypsopump-research/pull/1) | Oprava libsodium API, endianity, CRC, rámců a statusu | Otevřený PR; není v hlavní větvi SandraK82. Head obsahuje další opravu statusu na 18 B, kterou shrnutí PR ještě neodráží. Test harness uváděný autorem není plně přibalen. |
| [alex-poor PR #2](https://github.com/SandraK82/ypsopump-research/pull/2) | Nový dokument o GLB/CRC a counterech na V05.02.03 | Důležité opravy statických odhadů; bez podpory všech firmware a bez portu do iOS. |
| [Uneo7/Ypso](https://github.com/Uneo7/Ypso) | Python BLE/crypto/protocol reference a CLI | Referenční implementace pro Kotlin. Zde spuštěn pouze samostatný čistý výpočet CRC, nikoli CLI/SDK/pairing. Ve Swift balíčku není kopie jejího kódu. |
| [andyrozman/AndroidAPS:ypsopump_andy_v2](https://github.com/andyrozman/AndroidAPS/tree/ypsopump_andy_v2) | Historický AAPS modul `ypsopump`, historie/settings, fake režim | Poznámky rozlišují 1.5/1.6, původně čtecí pumpy bez loopingu. Nedokončený a založený na starší architektuře AAPS. Nelze zaměnit za moderní šifrovaný driver. |
| [master3395/ypsopump-research](https://github.com/master3395/ypsopump-research) | CamAPS Android build 189 vs 192, CGM/Liberty dokumentace, web | Skutečně odlišný fork, ale `aaps-driver` je vůči Sandra main beze změn. Neprokazuje novou podporu pump firmware. |
| [Baz00k/ypso-keys](https://github.com/Baz00k/ypso-keys) | CLI pro export session z mylife na rooted Androidu | README uvádí mylife 2.6.1.001 / Android 15, nikoli CamAPS. Není iOS řešení ani driver a klíč neobnovuje. Zde pouze přečten, nespouštěn. |
| Další forky | Převážně totožné heads nebo starší snapshoty | Seskupeny podle SHA, nikoli započteny jako nové implementace; odlišné heads Viktorových forků nemění SDK. |

Vyhledávání zahrnulo také LoopKit/Loop, LoopKit/LoopKit a nightscout/Trio. V nalezených výsledcích není potvrzená YpsoPump integrace těchto projektů. Jejich API/architektura byly studovány ze zdrojů, ne pouze z README.

## Co skutečně říká AAPS issue #4563

[Issue #4563](https://github.com/nightscout/AndroidAPS/issues/4563) zůstává otevřené. Název „integration done“ oznamuje výzkum/SDK, nikoli merge ovladače do AAPS. Diskuse odkazuje na historickou větev Andyho Rozmana a na prototyp Sandry. V dubnu autoři stále popisují potřebu revize proti aktuálnímu AAPS a obtížné získávání klíčů.

Významná časová oprava: v únoru Viktor hlásil obnovu zhruba po hodině, 4. března oznámil funkční 28denní klíč při změně postupu s tokenem. Proto staré tvrzení „klíč musí být vždy obnoven po 82 minutách“ není přijatelné jako obecný závěr. Část komentářů GitHub ve webovém zobrazení skrývá za „Load more“; nelze tvrdit, že byly přečteny všechny. API issue/comments narazilo na anonymní rate limit.

## Protokol, struktury a rozpory

| Oblast | Starší popis / implementace | Novější evidence | Rozhodnutí pro Swift |
|---|---|---|---|
| Transport | ProBluetooth nad GATT, rozdělení po 19 datových bajtech | Index a celkový počet v nibble hlavičky | Přísný offline assembler s kontrolou pořadí a limitu 285 B |
| Integrity CRC | Název „CRC16“, ale CRC-32 polynomial a dolních 16 bitů | Python/Kotlin i PR #2 popisují reverzi čtyřbajtových bloků | Nezávislé pevné vektory; žádné tiché přijímání vadného CRC |
| GLB | UInt32 LE + one's complement | PR #2 odlišuje selektory bez CRC od jiných payloadů | Samostatný decoder s přesnou délkou; žádný univerzální CRC wrapper pro všechny typy |
| SYSTEM_STATUS | Viktor 6 B; původní Sandra AAPS jiný odhad | PR #1 head uvádí 18 B, battery@6, reservoir@1 | Dva explicitní profily, bez autodetekce a bez předstírání firmware kompatibility |
| Delivery mode | Starší tabulka mapuje byte@0 | PR #1 připouští @5 i @0 jako nevyřešený význam | Raw body uchováno, mode = unknown; nesmí rozhodovat o dávkování |
| Counters | BE v původní dokumentaci | PR #1/#2 uvádějí LE z provozu | Kryptografická vrstva zatím neimplementována; nezakódovat starý BE předpoklad |
| ATT 138/139 | Zjednodušeně chyba counteru | PR #2 popisuje i odmítnutí nesprávného payloadu | Neukládat automatický „opravný“ retry; výsledek chyby nelze hádat |
| Profile A/B | Teoretický zápis přes settings | Viktor hlásí, že ukládání/aktivace nefungují; pozdější komentáře to také zpochybňují | Není implementován zápis ani jeho emulace jako fyzická schopnost |

Pro GATT zdroje popisují security/write/device-info služby. Historické projekty a dokumenty se liší v počtu služeb a v textové reprezentaci UUID; nelze bez kontroly endianity mechanicky převádět Android stringy do CoreBluetooth. Pro tento experiment nejsou zapotřebí žádné aktivní UUID ani BLE discovery.

Ne všechny čtecí operace jsou čistě GATT read: například historie/settings mohou nejprve zapisovat index selektoru. Zde se žádná z nich neprovádí na zařízení; „read-only“ znamená rozhraní k offline datům.

## Autentizace, šifrování a iOS

Zdroje popisují oddělený handshake odvozený od Bluetooth MAC a konstanty, pak XChaCha20-Poly1305 a provisioning zahrnující Curve25519/HChaCha20 a backend ProRegia. V aplikační cestě vystupují challenge, token/attestation a session countery. Není to standardní BLE pairing, který lze prostě nahradit iOS dialogem.

Původní Android řešení předpokládá dostupnou Bluetooth MAC. Apple nabízí [CBPeer.identifier jako UUID](https://developer.apple.com/documentation/corebluetooth/cbpeer/identifier); ten nelze použít jako MAC do stejného odvození. Pro budoucí iOS práci je třeba doložený způsob identity/provisioningu, ne přepis Android API po řádcích. Ani samotný port XChaCha nestačí k vyřešení klíčů a synchronizace.

Pro uživatele s iPhonem bez Androidu nebyla doložena použitelná veřejná metoda provisioning v nezávislém iOS klientovi. Baz00k ani Viktorův Android relay tuto podmínku nesplňují. Tento projekt neobsahuje relay, Frida/ADB použití, přihlášení na vendor backend ani získávání klíčů z CamAPS. Existující CamAPS FX zůstává nedotčený.

## Firmware: co víme a co ne

- V05.02.03 je konkrétně uveden ve Viktorově SDK a dokumentu PR #2. Je to evidence o vybraném zařízení, ne o každé YpsoPump prodávané dnes.
- Starší Andyho poznámky 1.5/1.6 se týkají jiné fáze produktu a nelze je zaměnit za moderní firmware V05.02.03.
- Verze APK CamAPS 189/190/192 a mylife 2.6.1 nejsou verze firmware pumpy. Fork s novější APK analýzou neprokazuje novou pump firmware kompatibilitu.
- Tvrzení, že pumpa nikdy neinvaliduje klíče a expirace je výhradně aplikační, není naší revizí potvrzeno. Ani úspěšné dešifrování fixture neprokazuje správnost obnovy, restartů a replay ochrany.
- Není zjištěna verze ani změněno nastavení vaší pumpy. Není doložena možnost bezpečného souběhu nezávislého ovladače s CamAPS; nic se nepáruje ani neodpojuje.
- Otevřené zůstávají přesná historie dávkování, čas/pásmo, pořadí counterů po resetu, více klientů, rozlišení zamítnutého a nejistého příkazu, limity a zaokrouhlení.

## Implementační rozhodnutí

Základní Swift knihovna nepřebírá celý SDK, závislosti ani autentizaci. Vlastní přísný parser odděluje data a interpretaci, zachovává nejistoty a používá pouze syntetické fixture. Testovací transport je v paměti. Veřejné dávkovací metody adaptéru jsou explicitně odmítající rozhraní bez packet encoderu.

Experimentální Loop fork je založen na commitu uvedeném v LoopWorkspace, aby souhlasil se závislostmi. Jeho Xcode projekt skutečně odkazuje na lokální SPM produkt. Most předá výsledek parseru do MockKitu. Výběr/obnova fyzických PumpManagerů je odmítnuta; aplikace má navíc compile-time zákaz fyzického iPhone targetu. Omezení a validační kroky jsou v [návodu k integraci](../CI.md).

## Licence a reprodukovatelnost

Nový Swift kód je MIT s uvedením výzkumných zdrojů. Viktorův SDK je AGPL-3.0 a není do balíčku kopírován ani linkován. Upstream checkouty zachovávají původní licence. Dokument PR #2 je dostupný v původním repozitáři na commitu `6f1f9d454f9a30bc57fb9e45c71ae7710f96563a`; zde není redistribuován. Před případným veřejným vydáním je třeba samostatně projít přesný publikační obsah; zde nic zveřejněno nebylo.

Vyhledávací skripty a snapshoty umožňují dohledat postup. `scripts/refs.py` obnovuje pouze veřejné reference; `research.py` může znovu narazit na API limit. Detaily implementace a další kroky: [ARCHITECTURE.md](../ARCHITECTURE.md).

## Aktualizace: skutečné novější AAPS integrační forky

Globální vyhledávání PR a repository search s `fork:true` doplnily zásadní dva zdroje. [Úplných 60 výsledků PR](GLOBAL-PRS.md) je uloženo včetně stavů a dat. Původní vyhledávání bez `fork:true` tyto repozitáře přehlédlo. Toto zjištění neznamená integraci do upstream nightscout/AndroidAPS, ale mění srovnání dostupných implementací:

| Zdroj | Prostudovaný head | Výsledek |
|---|---|---|
| [alex-poor/AndroidAPS](https://github.com/alex-poor/AndroidAPS) | `6fc570be2e1890ff92fa8918f6c265cdad985d5d` | Skutečný experimentální AAPS driver. README uvádí autorovy testy na V05.02.03, bolus/TBR/history a provoz od července. Jde o tvrzení autora omezeného testování, ne naše ověření ani schválení upstreamem. |
| [Baz00k/AndroidAPS](https://github.com/Baz00k/AndroidAPS) | `53c1a66c8b6d4ad899ae8dd240a6de8f30ce6c7e` | Rozvinutý fork alex-poor s driverem, session journaling, provisioning, historií, příkazy a testy. Aktuální kód již není status-only, i když starší web cache a historické PR tak říkají. README nyní omezuje další práci na chyby/Ypso driver při čekání na AAPS 4.0. |

Zdrojové snapshoty, nikoli zastaralá indexovaná webová README, rozhodují o stavu tohoto přehledu. Forky byly pouze staženy a čteny; jejich Android buildy, testy ani hardware kód nebyly spuštěny. Větve mimo main jsou inventarizované podle refs, ne všechny jednotlivě kódově zrevidované.

### Nejdůležitější korekce proti starším zdrojům

**Status:** Baz00k `pump/ypsopump/docs/protocol.md` popisuje na V05.00.52 / protocol 1.3 přesně 18 B: režim @0 (3 Stop, 10 běží), reservoir UInt32@1, **baterie 0–5 dílků @5**, bazální rychlost UInt32@6, TBR procento UInt32@10, zbývající minuty UInt32@14. Vyšší firmware přijímá podle vlastní policy, ale neuvádí fyzickou charakterizaci každé verze. Starší 18B hypotéza „battery@6“ tedy nesmí být vydávána za univerzální správný parser. Swift nyní nabízí třetí explicitní profil a simulátor používá tento novější. Procento baterie je `nil`; MockKit dostává pouze UI odhad dílky/5.

**Expirace:** alex-poor README uvádí pozorování z 28. července, kdy pumpa po 28 dnech odmítala šifrovaná čtení kódem 140. To přímo zpochybňuje kategorické tvrzení starších poznámek, že pumpa expiraci nikdy nevynucuje. Baz00k PR #225 řeší advisory expiraci/reminders; změna data v UI klíč neobnovuje. Ani tato evidence sama nedokládá všechny varianty klíčů/firmware.

**Příkazy a historie:** novější Baz00k PR #48/#74 přidávají bolus/TBR a historické účtování, #195 řeší nejednoznačné přiřazení bazální historie, #276 sjednocuje zápisové cesty. PR #31 a pozdější protocol.md mají rozdílné časové závěry o numeric callbacks. Správný návrh nemůže z pouhého ACK odvodit doručenou dávku, slepě opakovat příkaz ani slučovat záznamy jen podle času/množství. To jsou vývojové důvody pro zachování výhradně simulovaného rozsahu.

**Profil pumpy a iOS:** aktuální driver stále nepíše bazální program pumpy; porovnává ho s AAPS profilem. Provisioning používá externě získanou session a Android Keystore. Nejde o řešení pro tento iPhone bez Androidu. Současný Swift projekt neobsahuje export/import klíčů, controller handoff ani dávkovací kód.

### Priority zdrojů pro další práci

Začněte aktuálními `pump/ypsopump/docs/` a testy Baz00k, srovnejte s alex-poor main a až poté s historickým výzkumem. Zejména `CapturedStatusProtocolTest`, session/journal testy a modely výsledků příkazů jsou užitečný podklad pro **nové syntetické** fixture a offline návrh. Nezaměňujte testy cizího projektu (zde nespouštěné) za 19 skutečně provedených testů Swift balíčku.
