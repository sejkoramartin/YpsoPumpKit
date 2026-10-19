# CamAPS FX: offline rozbor protokolu a autentizace

Stav 19. 10. 2026. Jde o revizi veřejných výzkumných podkladů a otevřeného
Android ovladače, nikoli dekompilaci uživatelovy iOS aplikace. Nemáme její IPA ani hash. Číslo verze bylo doloženo snímkem uživatele. Nebyl kontaktován backend výrobce, získán skutečný klíč,
změněna instalace CamAPS nebo navázáno spojení s pumpou.

## Oddělené vrstvy

| Vrstva | Význam | Co sama nedokazuje |
|---|---|---|
| Reklama BLE | Viditelný název a veřejné údaje | Identitu, oprávnění ani dostupnost relace |
| Párování Bluetooth | Důvěra na úrovni platformy/spojení | Platnost aplikačního klíče |
| Přístupová autentizace | Veřejný Android driver popisuje samostatné odvození z adresy | Správnou identitu pumpy ani novost dat |
| Šifrovaná relace | Autentizované zprávy a ochrana proti opakování | Správnost dávkování či neomezenou životnost klíče |
| Provisioning | Zřízení/obnova oprávněné relace | Není nahrazen pouhým portem kryptografické knihovny |

## Co je doloženo v konkrétních zdrojích

1. **SandraK82, revize de7e867241fafd2fb8061ceeecf42af2883b9eb4:**
   výzkum Android CamAPS FX 1.4(190).111 popisuje XChaCha20-Poly1305,
   32bajtový klíč, 24bajtový nonce a výměnu založenou na Curve25519 a HChaCha20.
   Jde o tvrzení autorů výzkumu, ne naši reprodukci s binárkou aplikace.
   [Šifrování](https://github.com/SandraK82/ypsopump-research/blob/de7e867241fafd2fb8061ceeecf42af2883b9eb4/docs/03-encryption.md)

2. **Baz00k/AndroidAPS, revize a90e5e3bbe6ace962cbd903fc09e60913a7ce982:**
   současný popis odděluje párování, přístupovou autentizaci, kontrolu identity
   a ověření šifrovaného stavu. Nonce je za ciphertextem a tagem; dešifrovaná
   odpověď obsahuje autentizovaný 12bajtový konec s little-endian čítači.
   Replay stav se uchovává před zveřejněním přijatého stavu. Ztracené potvrzení
   není důkaz zamítnutí příkazu. Dokument fyzicky charakterizuje V05.00.52;
   přijímání novějších verzí není jejich jednotlivým ověřením.
   [Protokol](https://github.com/Baz00k/AndroidAPS/blob/a90e5e3bbe6ace962cbd903fc09e60913a7ce982/pump/ypsopump/docs/protocol.md)

3. **master3395/ypsopump-research, revize 718ae5d8b4d8f80ce74401f37874b92db2c8de98:**
   srovnání 189/192 se týká Android APK, ne iOS. Nelze z něj odvodit
   totožné knihovny, úložiště klíčů nebo ochrany iPhone aplikace.
   [Srovnání verzí](https://github.com/master3395/ypsopump-research/blob/718ae5d8b4d8f80ce74401f37874b92db2c8de98/docs/20-camaps-apk-189-vs-192.md)

## Zásadní rozpor: životnost klíče

Starší Sandra/master3395 texty tvrdí, že časovou expiraci vynucuje pouze aplikace.
Novější [issue Baz00k #211](https://github.com/Baz00k/AndroidAPS/issues/211)
uvádí pozorování správce projektu: klíč v AAPS přestal fungovat 8. 10. 2026
 a pro připomínky se používá maximum 28 dnů. Chybí úplná charakterizace
okolností a firmware, takže ani toto není univerzální důkaz konkrétního
mechanismu uvnitř pumpy. Tvrzení o neomezené platnosti není spolehlivý návrhový
předpoklad. Import starého klíče ani změna lokálního data není obnova relace.

## Dopad na YpsoPumpKit a Trio

- Aktuální Swift parser zpracovává plaintext fixture, ne autentizované odpovědi.
  CRC nenahrazuje kryptografickou autentizaci.
- Reklamní diagnostika pro iPhone neimplementuje žádnou z dalších vrstev.
- Příští offline modul má ověřovat kryptografické vektory se syntetickými klíči,
  poškozený tag, délky, pořadí nonce a trvalou ochranu proti opakování.
- Zvlášť je nutné modelovat restart, ztracenou odpověď a odmítnutý klíč;
  automatické opakování nelze odvozovat z pouhého timeoutu.
- Pro přímý rozbor doložené verze CamAPS iOS chybí oprávněně dostupná binárka.
  První krok bude inventář, hash, metadata a zjištění, které části lze vůbec
  staticky analyzovat. Android zjištění zůstanou oddělená od iOS evidence.

Tato revize nepřidává autentizační transport, získávání klíčů ani dávkovací příkazy.

## Identifikace uživatelovy iOS aplikace ze snímku

Uživatel dodal obrazovku O programu 19. 10. 2026:

- CamAPS FX (PI): 1.4.196.501; úplná zobrazená verze: 1.4.196.501.260.
- YpsoPump Library: 1.0.10.
- Main Platform: 1.0.0; Control Algorithm: 0.3.71.
- Tyto údaje nejsou verzí firmware pumpy ani důkazem binární kompatibility
  s Android APK 189/190/192. Snímek nepotvrzuje implementaci kryptografie.

Chybí vlastní binární artefakt a jeho původ/hash. Zatím lze porovnávat dokumentaci
a veřejný výzkum; přímá reverzní analýza tohoto iOS sestavení neproběhla.
