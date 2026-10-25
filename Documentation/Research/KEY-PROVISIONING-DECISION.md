# Vytvoření a obnova klíče: rozhodnutí pro iOS

Stav průzkumu: 25. 10. 2026. Pouze veřejné zdroje a lokální kopie;
žádné připojení k pumpě, čtení soukromých klíčů, instrumentace aplikace ani
požadavek na výrobní backend. Níže uvedené výsledky autorů jsme neopakovali.

## Závěr

V prověřených zdrojích není doložen samostatný provisioning pro iOS, který by
fungoval bez Androidu a bez zásahu do stávajícího CamAPS. To není důkaz, že
takový postup nemůže existovat. Přepis lokální kryptografie do Swiftu sám
nevyřeší autorizaci nové relace na pumpě.

## Co jednotlivé cesty skutečně poskytují

| Cesta | Doložený rozsah | Co chybí pro náš projekt |
| --- | --- | --- |
| Baz00k/ypso-keys | Autoři opakovaně ověřili export uloženého klíče z mylife 2.6.1.001 na Androidu 15 s Frida 17.17.0 | Rootovaný Android s existujícími daty; CamAPS nepodporuje. Nevytváří ani neobnovuje relaci. Nový backend/pump key exchange je výslovně neověřený. |
| vicktor/ypsomed-pump | Dokumentace uvádí funkční Android SDK a provisioning přes relay s oficiální aplikací a backendem | Android a závislost na atestaci oficiální aplikace; nejde o nezávislou iOS implementaci. Úspěch autorů není naše reprodukce. |
| SandraK82/ypsopump-research | Statická analýza Android CamAPS: výměna zahrnující aplikaci, pumpu a backend; lokální Curve25519/HChaCha20 | Samotná lokální derivace nevyřeší backendem autorizovaný instalační payload. README popisuje bootstrap přes původní aplikaci, ne ověřený samostatný iOS klient. |
| Experimentální AAPS fork | Import existujícího klíče, ověření stavu a správa čítačů | Není zdrojem nového klíče; vyžaduje externí obnovu. |
| Náš Swift prototyp | Ověřené syntetické odpovědi, integrita, replay čítače, transakční uložení a test pádu procesu | Žádný skutečný provisioning, autentizovaná identita pumpy ani ověřený profil aktuálního firmwaru. |

Export IPA je balíček aplikace, nikoli export jejího aktuálního privátního
úložiště s relací. Ani rozbor čitelného programu automaticky neposkytne
oprávnění backendu přijmout nezávislého klienta. Z Android Play Integrity toku
nelze odvodit konkrétní iOS atestační mechanismus bez dalších důkazů.

## Rozpory, které nesmíme změnit na předpoklady v kódu

- Vicktorův Welcome uvádí přibližně hodinovou platnost (pozorování asi 82 minut).
- Sandra v README a dokumentu 19 tvrdí, že 28 dní kontroluje jen aplikace a pumpa
  klíč časově neomezuje. Jde o závěr analýzy, nikoli doložený dlouhodobý test
  našeho firmwaru. Dokument 19 zároveň obsahuje starý big-endian popis čítačů.
- ypso-keys uvádí nejvýše 28 dní; současně přiznává, že úspěšný export nedokazuje
  přijetí klíče pumpou. AAPS tuto hodnotu používá jako odhad a přesnou životnost
  na pumpě označuje za neznámou.

Tyto výroky nejsou sjednocenou specifikací. Automatickou obnovu po určité době,
nekonečnou životnost nebo řešení změnou data proto neimplementujeme.

## Novější otevřené návrhy

Ověřeny přes GitHub API 25. 10. 2026:

- Sandra PR #1, head `1234172fe1e1ba793df902ebe451d2ce0be0859d`:
  opravy endianity, CRC, rámcování a parseru; autor uvádí ověření na provozu
  skutečné pumpy. Není to samostatný provisioning.
- Sandra PR #2, head `6f1f9d454f9a30bc57fb9e45c71ae7710f96563a`:
  autor uvádí pozorování firmwaru V05.02.03 a popisuje konflikt čítačů při
  souběhu s původní aplikací. Není to důkaz podpory našeho firmwaru ani cesta
  k iOS klíči. Otevřený PR nepovažujeme za přijatou specifikaci.
- vicktor: pouze main, žádný otevřený PR.
- ypso-keys: main a docs/session-key-lifetime, žádný otevřený PR.

Tento cílený průzkum není novým úplným soupisem všech forků.

## Další postup podle dostupných důkazů

1. Pokračovat offline modelem relace: rozlišit nalezení zařízení, přístupovou
   autentizaci, dostupnost klíče a ověřenou šifrovanou odpověď. Žádný z prvních
   tří stavů nesmí znamenat „pumpa ověřena“.
2. Pro iOS provisioning je třeba doložený podporovaný integrační mechanismus
   výrobce nebo reprodukovatelný výzkum iOS výměny pro konkrétní verzi. V tomto
   průzkumu takový podklad nalezen nebyl. Případné oslovení autorů/výrobce
   připravit zvlášť; během tohoto úkolu žádná zpráva odeslána nebyla.
3. Neplánovat nákup Androidu jako zaručené řešení: dostupný exportér neumí
   samotnou obnovu a jeho dokumentace neověřuje nový key exchange.
4. Změnu relace nepovažovat za neškodný test při souběhu s CamAPS. Je nutná
   samostatná testovací pumpa a doložený plán předání řízení, než se rozšíří
   současný rozsah pouhého pozorování reklamních dat.

## Primární zdroje a připnuté revize

Aktuální výchozí revize následujících tří repozitářů ověřeny přes GitHub API:

- [ypso-keys kompatibilita](https://github.com/Baz00k/ypso-keys/blob/10d906a1a1ee7fca9074bdacdf34d890e07fe3ff/docs/compatibility.md)
- [ypso-keys README](https://github.com/Baz00k/ypso-keys/blob/10d906a1a1ee7fca9074bdacdf34d890e07fe3ff/README.md)
- [Vicktor Welcome](https://github.com/vicktor/ypsomed-pump/blob/71ae55e372cb7a4fe1c96bfdd536d3beccbbb8a2/Welcome.md)
- [Sandra výměna klíče](https://github.com/SandraK82/ypsopump-research/blob/de7e867241fafd2fb8061ceeecf42af2883b9eb4/docs/04-key-exchange.md)
- [Sandra životnost](https://github.com/SandraK82/ypsopump-research/blob/de7e867241fafd2fb8061ceeecf42af2883b9eb4/docs/19-key-lifecycle-pump-rotation.md)
- [Opravy protokolu, PR #1](https://github.com/SandraK82/ypsopump-research/pull/1)
- [Pozorování V05.02.03, PR #2](https://github.com/SandraK82/ypsopump-research/pull/2)
- [AAPS provisioning, dříve připnutá revize](https://github.com/Baz00k/AndroidAPS/blob/53c1a66c8b6d4ad899ae8dd240a6de8f30ce6c7e/pump/ypsopump/docs/provisioning.md)
