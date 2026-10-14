# Inventář veřejných repozitářů, větví a PR

Průzkum: 2026-10-14. Git reference jsou přesný snapshot dostupných heads a PR heads; neznamenají ověření funkčnosti. Stav PR je z uloženého GitHub API. Prázdný výsledek vyhledávání nedokazuje neexistenci implementace.

## Rozsah a limity

Použity GitHub repository search (`ypsopump`, `ypsomed-pump`, `Ypso insulin`), seznamy forků tří výchozích projektů, odkazy z AAPS #4563, všechny zveřejněné větve nalezených repozitářů a refs/pull/*/head. API seznamy se stránkují po 100. Anonymní API narazilo na limit 403; chybějící reference doplnil `git ls-remote`. Git refs neposkytují otevřený/uzavřený stav PR. Nelze zaručit všechny veřejné repozitáře na internetu, smazané větve, soukromé forky ani obsah všech nesouvisejících AAPS PR. Žádný nalezený Swift YpsoPump driver nebyl potvrzen.

LibreLinkUpDesktop je nerelevantní výsledek hledání (CGM desktop, nikoli ovladač pumpy); jeho snapshoty byly zachovány, ale není započten do ovladačů.

## Relevantní větve a forky

| Repozitář / větev | Commit | Vyhodnocení |
|---|---|---|
| [Baz00k/AndroidAPS:chore/review-project-skills](https://github.com/Baz00k/AndroidAPS/tree/chore/review-project-skills) | `f575801435e28305cf6b73b98d92698016d439f5` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [Baz00k/AndroidAPS:feat/stats-aaps4-reports](https://github.com/Baz00k/AndroidAPS/tree/feat/stats-aaps4-reports) | `6b770cebc358d60e5963d8fa2e036caacfdc4918` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [Baz00k/AndroidAPS:feature/closed-loop-controller](https://github.com/Baz00k/AndroidAPS/tree/feature/closed-loop-controller) | `29099876d168c35eb13062eb72c00b4becbd9ad4` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [Baz00k/AndroidAPS:fix/issue-193](https://github.com/Baz00k/AndroidAPS/tree/fix/issue-193) | `4f7a57e301eb68e3fed9d075afa810eeb33d9e6d` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [Baz00k/AndroidAPS:fix/issue-197](https://github.com/Baz00k/AndroidAPS/tree/fix/issue-197) | `3a64ecaf9e6538f2cc51d7e549ea1b642dbf8e5f` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [Baz00k/AndroidAPS:fix/issue-215](https://github.com/Baz00k/AndroidAPS/tree/fix/issue-215) | `502e2a0aae8cee56f9e67f4238b32cf8144abc08` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [Baz00k/AndroidAPS:fix/issue-229](https://github.com/Baz00k/AndroidAPS/tree/fix/issue-229) | `8e0eb847f50b54eedd58a68ddd9d6422795987d1` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [Baz00k/AndroidAPS:main](https://github.com/Baz00k/AndroidAPS/tree/main) | `53c1a66c8b6d4ad899ae8dd240a6de8f30ce6c7e` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [Baz00k/AndroidAPS:master](https://github.com/Baz00k/AndroidAPS/tree/master) | `05a3433598ac49a3ecafcbd218fc5c1fc39c8719` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [Baz00k/AndroidAPS:refactor/issue-216](https://github.com/Baz00k/AndroidAPS/tree/refactor/issue-216) | `7848d06e493e38eecad7b7cafdccb0893454c3d6` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [Baz00k/AndroidAPS:refactor/issue-217](https://github.com/Baz00k/AndroidAPS/tree/refactor/issue-217) | `4766e130e04a95f2780003876a2bc5bc33fa8f26` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [Baz00k/AndroidAPS:refactor/issue-274](https://github.com/Baz00k/AndroidAPS/tree/refactor/issue-274) | `14f4602a96c8145e3bb7173af8abb8ada78230ff` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [Baz00k/AndroidAPS:refactor/ypso-write-lane](https://github.com/Baz00k/AndroidAPS/tree/refactor/ypso-write-lane) | `accaaa39ba802b5b2e41bf44a918ad69099a3aad` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [Baz00k/AndroidAPS:test/placeholder-pump-serial](https://github.com/Baz00k/AndroidAPS/tree/test/placeholder-pump-serial) | `403a8564f82f805860d042068e6ada48ae9f4c6d` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [Baz00k/ypso-keys:docs/session-key-lifetime](https://github.com/Baz00k/ypso-keys/tree/docs/session-key-lifetime) | `fa99320cc0630f15daa769c7011bfc63c1bf088b` | Android/mylife key-export nástroj; ne ovladač, bez podpory CamAPS/iOS; nespouštěn |
| [Baz00k/ypso-keys:main](https://github.com/Baz00k/ypso-keys/tree/main) | `10d906a1a1ee7fca9074bdacdf34d890e07fe3ff` | Android/mylife key-export nástroj; ne ovladač, bez podpory CamAPS/iOS; nespouštěn |
| [Baz00k/ypsopump-research:main](https://github.com/Baz00k/ypsopump-research/tree/main) | `de7e867241fafd2fb8061ceeecf42af2883b9eb4` | Identický head jako SandraK82/main; nikoli nezávislá implementace |
| [LoopKit/LoopKit:dev](https://github.com/LoopKit/LoopKit/tree/dev) | `29a8e0f0a4fb0104a2989f63bd4d61da520f3363` | Reference uložena; samostatná funkčnost neověřena |
| [LoopKit/LoopKit:master](https://github.com/LoopKit/LoopKit/tree/master) | `62fa53e14eec7eaf9e28da07db19a54f36cc64e8` | Reference uložena; samostatná funkčnost neověřena |
| [LoopKit/Loop:dev](https://github.com/LoopKit/Loop/tree/dev) | `691afb313b34fa40bc13b2aff26db6cc3f9721c5` | Reference uložena; samostatná funkčnost neověřena |
| [LoopKit/Loop:main](https://github.com/LoopKit/Loop/tree/main) | `dcff017c984dbac81013ad47fdd9e77071932746` | Reference uložena; samostatná funkčnost neověřena |
| [MilosKozak/AndroidAPS:dev](https://github.com/MilosKozak/AndroidAPS/tree/dev) | `ce23adba36c41bfa8461505cdc7563953c0096df` | Reference uložena; samostatná funkčnost neověřena |
| [MilosKozak/AndroidAPS:master](https://github.com/MilosKozak/AndroidAPS/tree/master) | `936ed3c26388ceb8dd5d8801eae38410d39d5878` | Reference uložena; samostatná funkčnost neověřena |
| [MilosKozak/ypsomed-pump:main](https://github.com/MilosKozak/ypsomed-pump/tree/main) | `7c44285d750312dad8610cabfd51fabd75c16b85` | Stejný SDK jako vicktor main; rozdíly heads jsou README / funding (ověřeno diff sdk) |
| [Raimund58/ypsomed-pump:main](https://github.com/Raimund58/ypsomed-pump/tree/main) | `7c44285d750312dad8610cabfd51fabd75c16b85` | Stejný SDK jako vicktor main; rozdíly heads jsou README / funding (ověřeno diff sdk) |
| [Raimund58/ypsopump-research:main](https://github.com/Raimund58/ypsopump-research/tree/main) | `0720dc4b3f1af6196696a4edabc0a2d0ef4132e1` | Starší výzkumný snapshot; méně dokumentace a bez pozdější testovací aplikace |
| [SandraK82/ypsopump-research:main](https://github.com/SandraK82/ypsopump-research/tree/main) | `de7e867241fafd2fb8061ceeecf42af2883b9eb4` | Identický head jako SandraK82/main; nikoli nezávislá implementace |
| [Uneo7/Ypso:main](https://github.com/Uneo7/Ypso/tree/main) | `e8b794a7efcec27ba8994c2d582cc067dcd3e052` | Původní Python reference, stejný head ve forku; standalone CRC použito jen k ověření vektorů |
| [alex-poor/AndroidAPS:camaps-replica](https://github.com/alex-poor/AndroidAPS/tree/camaps-replica) | `7e783c8e76aa1cae370a0ae226748aa3d47a3fa0` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [alex-poor/AndroidAPS:diaswarm-addon](https://github.com/alex-poor/AndroidAPS/tree/diaswarm-addon) | `0777afd7a7080555d971c9c353e9c945632b7356` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [alex-poor/AndroidAPS:feature/libre3-lag-override](https://github.com/alex-poor/AndroidAPS/tree/feature/libre3-lag-override) | `ebdad536b1feca5bc03b8a2ff8d3d89b1c7301a2` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [alex-poor/AndroidAPS:main](https://github.com/alex-poor/AndroidAPS/tree/main) | `6fc570be2e1890ff92fa8918f6c265cdad985d5d` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [alex-poor/AndroidAPS:master](https://github.com/alex-poor/AndroidAPS/tree/master) | `05a3433598ac49a3ecafcbd218fc5c1fc39c8719` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [alex-poor/AndroidAPS:r8-shrink](https://github.com/alex-poor/AndroidAPS/tree/r8-shrink) | `3beacc11bf215162e4e90acb7dadca55548729b1` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [alex-poor/AndroidAPS:skin-entry-point](https://github.com/alex-poor/AndroidAPS/tree/skin-entry-point) | `c82d4188054d5e88ca646988e0bc320706dc93e6` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [alex-poor/AndroidAPS:skin-file-association](https://github.com/alex-poor/AndroidAPS/tree/skin-file-association) | `6fc6148363bfbeb53067c3a59521aaac93203898` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [alex-poor/AndroidAPS:skin-font-robustness](https://github.com/alex-poor/AndroidAPS/tree/skin-font-robustness) | `702eaad6f01b0bac3f6ef5c33d0131c3ab2bc4ea` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [alex-poor/AndroidAPS:skin-screen-selectable](https://github.com/alex-poor/AndroidAPS/tree/skin-screen-selectable) | `c483a8e75dd934423aeac30152984ef1d1692dbb` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [alex-poor/AndroidAPS:skin-single-palette](https://github.com/alex-poor/AndroidAPS/tree/skin-single-palette) | `77ab5ffa4221d7f55c86323a6149749e6d95c112` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [alex-poor/AndroidAPS:skinnable-type-and-shape](https://github.com/alex-poor/AndroidAPS/tree/skinnable-type-and-shape) | `1502431eb161d7b9bdead6bca94913cd76a33fb6` | Skutečný experimentální AAPS driver; main prostudován, ostatní heads inventarizovány; viz GLOBAL-PRS.md a REPORT.md |
| [alex-poor/ypsopump-research:docs/write-path-command-encoding](https://github.com/alex-poor/ypsopump-research/tree/docs/write-path-command-encoding) | `6f1f9d454f9a30bc57fb9e45c71ae7710f96563a` | PR #2: pozorování V05.02.03, GLB bez CRC, countery; otevřený |
| [alex-poor/ypsopump-research:fix/ypso-crypto-protocol](https://github.com/alex-poor/ypsopump-research/tree/fix/ypso-crypto-protocol) | `1234172fe1e1ba793df902ebe451d2ce0be0859d` | PR #1: opravy crypto API, LE counterů, CRC, framingu a 18B statusu; otevřený |
| [alex-poor/ypsopump-research:main](https://github.com/alex-poor/ypsopump-research/tree/main) | `de7e867241fafd2fb8061ceeecf42af2883b9eb4` | Identický head jako SandraK82/main; nikoli nezávislá implementace |
| [andyrozman/AndroidAPS:dev](https://github.com/andyrozman/AndroidAPS/tree/dev) | `6deea754463b8df40251a765c4d12a289200cde3` | Reference uložena; samostatná funkčnost neověřena |
| [andyrozman/AndroidAPS:master](https://github.com/andyrozman/AndroidAPS/tree/master) | `3df83535f9f8f3246308121900c2785c50915fa8` | Reference uložena; samostatná funkčnost neověřena |
| [andyrozman/AndroidAPS:ypsopump_andy_v2](https://github.com/andyrozman/AndroidAPS/tree/ypsopump_andy_v2) | `1d41bdebda51f1dc4df672014738c339873f4962` | Historický AAPS modul; čtení/staré verze 1.5/1.6, nedokončený, výchozí Faked režim |
| [el-zaidi/ypsomed-pump:main](https://github.com/el-zaidi/ypsomed-pump/tree/main) | `71ae55e372cb7a4fe1c96bfdd536d3beccbbb8a2` | Stejný SDK jako vicktor main; rozdíly heads jsou README / funding (ověřeno diff sdk) |
| [fox-1942/ypsopump-research:main](https://github.com/fox-1942/ypsopump-research/tree/main) | `de7e867241fafd2fb8061ceeecf42af2883b9eb4` | Identický head jako SandraK82/main; nikoli nezávislá implementace |
| [jodran2005/ypsomed-pump:main](https://github.com/jodran2005/ypsomed-pump/tree/main) | `edea58a4feea33d0c02b5850df6223ef8ad665e1` | Stejný SDK jako vicktor main; rozdíly heads jsou README / funding (ověřeno diff sdk) |
| [jodran2005/ypsopump-research:main](https://github.com/jodran2005/ypsopump-research/tree/main) | `de7e867241fafd2fb8061ceeecf42af2883b9eb4` | Identický head jako SandraK82/main; nikoli nezávislá implementace |
| [kachytronico/Ypso:main](https://github.com/kachytronico/Ypso/tree/main) | `e8b794a7efcec27ba8994c2d582cc067dcd3e052` | Původní Python reference, stejný head ve forku; standalone CRC použito jen k ověření vektorů |
| [kachytronico/ypsomed-pump:main](https://github.com/kachytronico/ypsomed-pump/tree/main) | `edea58a4feea33d0c02b5850df6223ef8ad665e1` | Stejný SDK jako vicktor main; rozdíly heads jsou README / funding (ověřeno diff sdk) |
| [kachytronico/ypsopump-research:main](https://github.com/kachytronico/ypsopump-research/tree/main) | `de7e867241fafd2fb8061ceeecf42af2883b9eb4` | Identický head jako SandraK82/main; nikoli nezávislá implementace |
| [keencave/ypsomed-pump:main](https://github.com/keencave/ypsomed-pump/tree/main) | `edea58a4feea33d0c02b5850df6223ef8ad665e1` | Stejný SDK jako vicktor main; rozdíly heads jsou README / funding (ověřeno diff sdk) |
| [keencave/ypsopump-research:main](https://github.com/keencave/ypsopump-research/tree/main) | `de7e867241fafd2fb8061ceeecf42af2883b9eb4` | Identický head jako SandraK82/main; nikoli nezávislá implementace |
| [master3395/ypsopump-research-SandraK82:main](https://github.com/master3395/ypsopump-research-SandraK82/tree/main) | `de7e867241fafd2fb8061ceeecf42af2883b9eb4` | Identický head jako SandraK82/main; nikoli nezávislá implementace |
| [master3395/ypsopump-research:main](https://github.com/master3395/ypsopump-research/tree/main) | `718ae5d8b4d8f80ce74401f37874b92db2c8de98` | Novější analýza CamAPS 189/192 a web dokumentace; žádné změny aaps-driver |
| [nightscout/AndroidAPS:dev](https://github.com/nightscout/AndroidAPS/tree/dev) | `3b7d0d8c0795157ee1aa43e32061abc465c597ce` | Reference uložena; samostatná funkčnost neověřena |
| [nightscout/AndroidAPS:master](https://github.com/nightscout/AndroidAPS/tree/master) | `936ed3c26388ceb8dd5d8801eae38410d39d5878` | Reference uložena; samostatná funkčnost neověřena |
| [nightscout/Trio:dev](https://github.com/nightscout/Trio/tree/dev) | `1bacd86fb19dc325dff044b8cfe52fb7da6c8b98` | Reference uložena; samostatná funkčnost neověřena |
| [nightscout/Trio:main](https://github.com/nightscout/Trio/tree/main) | `0b29cd53415e7f0e668677749cad8daf81c68c2f` | Reference uložena; samostatná funkčnost neověřena |
| [qq254344379/ypsomed-pump:main](https://github.com/qq254344379/ypsomed-pump/tree/main) | `7c44285d750312dad8610cabfd51fabd75c16b85` | Stejný SDK jako vicktor main; rozdíly heads jsou README / funding (ověřeno diff sdk) |
| [vicktor/ypsomed-pump:main](https://github.com/vicktor/ypsomed-pump/tree/main) | `71ae55e372cb7a4fe1c96bfdd536d3beccbbb8a2` | Stejný SDK jako vicktor main; rozdíly heads jsou README / funding (ověřeno diff sdk) |

## Pull requesty v tematických repozitářích

| PR | Stav při načtení | Head |
|---|---|---|
| [Baz00k/ypso-keys#6: Fix CI after the Frida dependency update](https://github.com/Baz00k/ypso-keys/pull/6) | closed | `ada56bfa20d197918f039df34c13c38e19e5634d` |
| [Baz00k/ypso-keys#5: docs: rewrite docs in plainer language](https://github.com/Baz00k/ypso-keys/pull/5) | closed | `9a5ff60b5ffc55356f72fbff2a59e05131b9e95d` |
| [Baz00k/ypso-keys#4: docs: document the 28-day session key lifetime](https://github.com/Baz00k/ypso-keys/pull/4) | closed | `fa99320cc0630f15daa769c7011bfc63c1bf088b` |
| [Baz00k/ypso-keys#3: refactor: remove synthetic session-review and validity fields](https://github.com/Baz00k/ypso-keys/pull/3) | closed | `cb18ba5d91e79dd154fa8bcc7c5d0935eaea5a33` |
| [SandraK82/ypsopump-research#2: docs: add 20 — write path command encoding & counter behaviour (live-pump observations)](https://github.com/SandraK82/ypsopump-research/pull/2) | open | `6f1f9d454f9a30bc57fb9e45c71ae7710f96563a` |
| [SandraK82/ypsopump-research#1: Fix YpsoPump driver crypto/protocol layer (verified against real pump traffic)](https://github.com/SandraK82/ypsopump-research/pull/1) | open | `1234172fe1e1ba793df902ebe451d2ce0be0859d` |

Kompletní refs včetně nesouvisejících větví Loop/Trio/AAPS jsou v lokálním archivu průzkumu (nezveřejněn). Metadata PR a zdrojové URL jsou uloženy v JSON vedle nich. U Viktorova projektu nejsou v git snapshotu PR heads. U AAPS byly pro dotaz `repo:nightscout/AndroidAPS ypso` nalezeny #4563, #4575, #5136, #3896 a #1879; samotná zmínka není integrace. U Loopu #696; u LoopKit/Trio bez výsledku.

## Lokální checkouty a licence

| Cesta | Commit |
|---|---|
| `Loop-simulator` | `c30b5c89b1dc4151628f33f1384dd4796eaeeec2` |
| `upstream/AndroidAPS-alex-poor` | `6fc570be2e1890ff92fa8918f6c265cdad985d5d` |
| `upstream/AndroidAPS-Baz00k` | `53c1a66c8b6d4ad899ae8dd240a6de8f30ce6c7e` |
| `upstream/AndroidAPS-ypso` | `1d41bdebda51f1dc4df672014738c339873f4962` |
| `upstream/ypsomed-pump` | `71ae55e372cb7a4fe1c96bfdd536d3beccbbb8a2` |
| `upstream/Ypso` | `e8b794a7efcec27ba8994c2d582cc067dcd3e052` |
| `upstream/Trio` | `0b29cd53415e7f0e668677749cad8daf81c68c2f` |
| `upstream/ypso-keys` | `10d906a1a1ee7fca9074bdacdf34d890e07fe3ff` |
| `upstream/LoopWorkspace` | `548b33245198eaae165c094c9c68fe333cb69c05` |
| `upstream/ypsopump-research` | `de7e867241fafd2fb8061ceeecf42af2883b9eb4` |
| `upstream/LoopKit` | `29a8e0f0a4fb0104a2989f63bd4d61da520f3363` |
| `upstream/research-crypto-fix` | `1234172fe1e1ba793df902ebe451d2ce0be0859d` |

## Doplněné globální hledání

Dotaz `ypsopump fork:true` přidal Baz00k/AndroidAPS a alex-poor/AndroidAPS. Globální `ypsopump type:pr` vrátil 60 výsledků bez truncation: [kompletní tabulka](GLOBAL-PRS.md). Main větve těchto dvou forků obsahují skutečné dávkovací implementace (nespouštěny); aktuální stav nelze odvozovat z jejich starších PR nazvaných status-only.
