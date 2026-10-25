# Authentication evidence and remaining gaps

Reviewed 25 October 2026. This is an offline comparison, not a tested hardware
connection procedure. No real credentials, serials or device captures are included.

## Evidence scope

The inspected Baz00k/AndroidAPS checkout is pinned to
`53c1a66c8b6d4ad899ae8dd240a6de8f30ce6c7e`. It was clean during review.
The online GitHub page fetch failed during this review, so this is explicitly
not a claim about the latest branch or all currently supported firmware.
Implementation observations do not establish compatibility with our user's pump.

| Layer | Evidence in pinned AAPS fork | Our implementation / remaining gap |
| --- | --- | --- |
| Discovery | Device-name/serial recognition and expected address mapping | iOS advertisement candidate only; no verified device identity |
| Bluetooth bond | Android bond state and explicit pairing request; source states bond does not establish a working pump session | No pairing; Android-specific flow cannot simply be copied into iOS |
| Access authentication | Separate MAC-derived MD5 password written to AUTH characteristic after service discovery | No AUTH writes; need firmware-specific evidence and a verified identity mapping |
| Shared key provisioning | Session document requires a 32-byte shared key plus identity and source timestamps | Only synthetic key; no independently implemented key establishment or renewal |
| Encrypted responses | XChaCha20-Poly1305, appended nonce and authenticated reboot/read counter | Offline decryption and synthetic fixtures cross-checked with PyCryptodome |
| Replay state | Persistent identity/key generations, candidate verification and counter management | SQLite floor for one synthetic key and fixed epoch; restart tests pass, whole-file rollback remains unprotected |
| Key lifetime | Advisory 28-day deadline with source/import/user origins | Not evidence that every firmware expires a key after exactly 28 days; no renewal flow |
| Platform identity | Android address-based identity plus serial validation | iOS scan identifier must not be treated as a Bluetooth MAC; no verified iOS mapping implemented |
| Firmware compatibility | Our status parser explicitly targets the characterized V05.00.52 / protocol 1.3 layout | Current physical pump firmware and matching authenticated response layout remain unverified |

## Important distinctions

The access password is not the 32-byte shared encryption key. The reviewed import
parser consumes an existing key; parsing that document does not explain or
implement initial key agreement. A successful AUTH characteristic write is also
not proof that an encrypted status can be authenticated with a supplied key.
The fork's connection state names must not be interpreted as our hardware evidence.

CamAPS application version, its YpsoPump library version, and pump firmware are
different version identifiers. A screenshot of application versions cannot select
a verified pump protocol profile. Likewise, an advertised service UUID alone does
not prove an AUTH/status characteristic layout or the identity of the broadcaster.

## Next development gates

1. Model discovery, access authentication and encrypted-status validation as separate
   simulator states. Test wrong identity, stale key, missing key and epoch changes.
2. Establish independent, firmware-labelled evidence for incoming message layouts;
   synthetic fixtures validate code behavior, not device interoperability.
3. Document a legitimate key provisioning/renewal path and a trusted initial counter
   baseline. Neither the IPA nor the public password derivation alone supplies this.
4. Define recovery after backup restoration, journal loss and reboot-epoch change;
   retain fail-closed behavior until those cases have an explicit policy.
5. Only then reassess a separate, narrowly scoped hardware test design. No physical
   connection, pairing, AUTH write or therapy command is added by this work.

## Reproducible source references

All links point to the reviewed revision; no AGPL implementation was copied.

- [Bluetooth pairing](https://github.com/Baz00k/AndroidAPS/blob/53c1a66c8b6d4ad899ae8dd240a6de8f30ce6c7e/pump/ypsopump/src/main/kotlin/app/aaps/pump/ypsopump/ble/YpsoPumpPairing.kt)
- [Access authentication](https://github.com/Baz00k/AndroidAPS/blob/53c1a66c8b6d4ad899ae8dd240a6de8f30ce6c7e/pump/ypsopump/src/main/kotlin/app/aaps/pump/ypsopump/ble/YpsoAuthentication.kt)
- [Connection lifecycle](https://github.com/Baz00k/AndroidAPS/blob/53c1a66c8b6d4ad899ae8dd240a6de8f30ce6c7e/pump/ypsopump/src/main/kotlin/app/aaps/pump/ypsopump/ble/YpsoPumpLink.kt)
- [Imported session document](https://github.com/Baz00k/AndroidAPS/blob/53c1a66c8b6d4ad899ae8dd240a6de8f30ce6c7e/pump/ypsopump/src/main/kotlin/app/aaps/pump/ypsopump/provisioning/YpsoSessionDocument.kt)
- [Encrypted response codec](https://github.com/Baz00k/AndroidAPS/blob/53c1a66c8b6d4ad899ae8dd240a6de8f30ce6c7e/pump/ypsopump/src/main/kotlin/app/aaps/pump/ypsopump/crypto/SessionCrypto.kt)
- [Session state](https://github.com/Baz00k/AndroidAPS/blob/53c1a66c8b6d4ad899ae8dd240a6de8f30ce6c7e/pump/ypsopump/src/main/kotlin/app/aaps/pump/ypsopump/crypto/PumpSession.kt)
- [Advisory key timing](https://github.com/Baz00k/AndroidAPS/blob/53c1a66c8b6d4ad899ae8dd240a6de8f30ce6c7e/pump/ypsopump/src/main/kotlin/app/aaps/pump/ypsopump/crypto/KeyTiming.kt)
