# Offline protokolový profil

Implementace zpracovává jen předem připravená plaintext data. Není zde AEAD dešifrování ani ověření původu zprávy. CRC není autentizace. Syntetický transport není BLE wire capture: skutečné fragmenty běžně nesou šifrovanou obálku, kterou tento prototyp nepřijímá jako stav.

## Implementované vrstvy

| Vrstva | Kontrakt | Odmítnutí |
|---|---|---|
| Framing | horní nibble = index od 1, dolní = počet; 19 B dat, max. 15 rámců | délka >20, index mimo pořadí, změna počtu, duplicitní/krátký mezilehlý rámec |
| Prázdná zpráva | explicitní legacy sentinel `10` | jiná nulová délka/počet |
| CRC | polynomial 0x04C11DB7, počátek FFFFFFFF, reverze bloků po 4 B s doplněním nul, dolních 16 bitů LE | chybné CRC nebo chybějící trailer |
| GLB | přesně 8 B: UInt32 LE a bitový doplněk | chybná délka nebo XOR != FFFFFFFF |
| Status legacy | 6 B + CRC; mode@0, reservoir UInt32 LE@1 /100, battery@5 | jiná délka nebo baterie >100 |
| Status historický PR #1 | 18 B + CRC; reservoir@1 /100, battery@6, hlášené procento@10 | jiná délka, CRC nebo baterie >100; mode zůstává unknown |

| Status Baz00k V05.00.52 / protocol 1.3 | 18 B + CRC; mode@0 (3 Stop, 10 running), reservoir@1, battery **bars**@5, basal UInt32@6, TBR percent@10, remaining minutes@14 | odmítnutí neznámého módu, sentinel/out-of-range polí; batteryPercent = nil |

`FrameAssembler.finish()` je nutné zavolat při konci záznamu/timeoutu; odhalí chybějící konec a vyčistí stav. Chybný rámec rovněž vyčistí stav. `StatusReader` přijme právě jednu kompletní zprávu a odmítne další rámce. Neprovádí opakování ani odhad oprav poškozené zprávy. Neznámé režimy se nezaměňují za běžící bazál. Novější profil odmítá nepozorované režimy; `running` neznamená automaticky konkrétní bazální režim.

`SimulationScenario` vytváří pouze novější Baz00k 18B profil, rozsah zásobníku omezuje na syntetických 0–160 U a nabízí poškozené CRC, truncation a okamžitě vyvolaný timeout. Nenapodobuje skutečné časování BLE, fyziku dávkování ani kryptografický session lifecycle. `SimulatedPump` serializuje přístup pomocí actoru. `SimulatorAdapter` neumožňuje vložit jiný transport.

## Původ a jistota údajů

- CRC/GLB/framing: [SandraK82 MIT zdroje](https://github.com/SandraK82/ypsopump-research/tree/de7e867241fafd2fb8061ceeecf42af2883b9eb4/ypsopump-test/app/src/main/java/com/ypsopump/test/protocol). Swift parser je přísnější než zdrojový assembler, který pouze spojoval fragmenty bez kontroly pořadí.
- Šestibajtový popis: [vicktor dokumentace](https://github.com/vicktor/ypsomed-pump/blob/71ae55e372cb7a4fe1c96bfdd536d3beccbbb8a2/YpsoPump_Technical_Documentation_EN). Zachován jako historický profil, nikoli jako výchozí správný formát.
- 18B profil: [StatusCommand na head PR #1](https://github.com/alex-poor/ypsopump-research/blob/1234172fe1e1ba793df902ebe451d2ce0be0859d/aaps-driver/src/main/kotlin/app/aaps/pump/ypsopump/comm/commands/StatusCommand.kt). Autor uvádí ověření na pumpě, ale význam mode@5 označuje jako odhad. Popis PR ještě uvádí starší 6B verzi; pro tento projekt rozhoduje konkrétní commit.
- Pevné CRC vektory byly nezávisle spočteny standalone `crc.py` v [Uneo7/Ypso](https://github.com/Uneo7/Ypso). V testech není závislost na Pythonu; běží jen Swift.

Záměrně nejsou implementovány UUID pro dávkovací zápis, request encoding, autentizační salt, backend credentials, session klíče, counter persistence ani export dávkovacích paketů. Odlišnost endianity counterů (původně BE, v nových PR LE) je výzkumné zjištění, nikoli již implementovaná autentizace.

## Aktualizace podle novějšího AAPS forku

[Baz00k protocol.md, commit 53c1a66](https://github.com/Baz00k/AndroidAPS/blob/53c1a66c8b6d4ad899ae8dd240a6de8f30ce6c7e/pump/ypsopump/docs/protocol.md) a jeho StatusCommand popisují cílové V05.00.52 / protocol 1.3. Jsou novější než hypotéza v PR #1. Stejných 18 bajtů může ve starém parseru vrátit například 100 % baterie, přestože byte 6 začíná bazální rychlost! Regresní test proto výslovně ukazuje rozdílnou interpretaci stejné délky.

Novější profil ověřuje intervaly převzaté jako popis protokolu: reservoir <=20000 centi-U a bez FFFFFFFF, battery 0–5, basal <=4000 centi-U/h, procento <=500, minuty <=1440. To není nastavení dávkovacích limitů; žádné dávkování neimplementuje. Simulátor má vlastní konzervativnější limit zásobníku 160 U. Přijímání vyšších verzí firmware v Android forku je jeho compatibility policy, nikoli naše potvrzení, že každá vyšší verze funguje.

`FrameAssembler` podporuje starý prázdný sentinel 0x10 jen jako offline formát. `StatusReader` jej nepřijme jako status. Novější AAPS evidence nepovažuje nulový počet fragmentů za kvalifikovaný fyzický protokol. Staré formáty zůstávají pro reprodukci výzkumu; nepatří k automatickému výběru.
