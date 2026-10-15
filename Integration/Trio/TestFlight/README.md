# Simulator-only TestFlight build

The manually dispatched `Trio simulator TestFlight` workflow prepares the pinned
Trio simulator patch, checks isolation invariants, assigns the separate simulator
identity, and signs four targets using supplied App Store profiles. It uploads
the IPA to TestFlight without external tester distribution or review submission.
It never creates, renews or revokes Apple certificates. There is no Match dependency.

## Required configuration

Repository variable `APPLE_TEAM_ID`: your ten-character developer team ID.
Optional `DISTRIBUTION_IDENTITY`: `Apple Distribution` (default), or
`iPhone Distribution` when using an iOS Distribution certificate.

Repository secrets:

- `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_PRIVATE_KEY`: App Store Connect API credentials;
  private key is raw PEM text.
- `DISTRIBUTION_P12`: base64-encoded distribution certificate **with its private key**.
- `P12_PASSWORD`: password protecting that P12.
- `PROFILE_APP`, `PROFILE_WATCH`, `PROFILE_COMPLICATION`, `PROFILE_ACTIVITY`:
  base64-encoded App Store provisioning profiles, respectively for the main bundle,
  `.watchkitapp`, `.watchkitapp.TrioWatchComplication`, `.LiveActivity`.

All bundle identifiers begin with `org.ypsopumpkit.<TEAM_ID>.trio.sim`.
Profiles must include the selected signing certificate and required entitlements.
The main target currently retains upstream HealthKit, NFC, push, time-sensitive
notification and App Group entitlements, although simulator source disables
Bluetooth and HealthKit operations. Those capabilities must be configured before
creating profiles. The separate App Group is
`group.org.ypsopumpkit.<TEAM_ID>.trio.sim`.

Install no secrets in this repository. The workflow runs only manually on main,
uses a temporary macOS keychain, and does not publish signing assets or an IPA as
public Actions artifacts. Fastlane is locked by the pinned upstream Gemfile.lock.
The workflow cannot succeed until all signing prerequisites are supplied.

## Validation status

The unsigned iPhone Release and simulator integration checks passed. On
2026-10-15, the first signed archive, IPA export, and upload to App Store Connect
[completed successfully](https://github.com/sejkoramartin/YpsoPumpKit/actions/runs/38795021261)
using an iOS Distribution certificate. Linux/macOS package tests and signing-tool
checks also passed for that source revision. Apple subsequently marked build
`1.0.2 (1)` valid, and the internal TestFlight group shows `Testing`.
Installation and launch on a physical iPhone remain to be checked by the tester.

Run `python3 Scripts/test-signing-assets.py` and
`ruby -c Integration/Trio/TestFlight/Fastfile` for tool checks. These do not replace
an actual signed archive and upload. The bundled Watch targets need signing
profiles even when testing only on an iPhone; an Apple Watch is not required for
the iPhone app.
