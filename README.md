# YpsoPumpKit

**Active integration: Trio.** See [Trio simulator setup and TestFlight roadmap](Documentation/TRIO.md). The earlier Loop workflow is disabled.

[![Swift package CI](https://github.com/sejkoramartin/YpsoPumpKit/actions/workflows/ci.yml/badge.svg)](https://github.com/sejkoramartin/YpsoPumpKit/actions/workflows/ci.yml)

A Swift package for offline YpsoPump protocol research and simulator-only experiments toward future LoopKit integration. **This is not a hardware pump driver or a treatment system.**

It contains strict frame reassembly, CRC/GLB parsing, three explicitly selected status layouts, an asynchronous read-only source abstraction, an in-memory pump simulator, a command-line demo and automated tests. The simulator adapter cannot accept a hardware transport; bolus and basal requests always fail without encoding or sending a command.

No Bluetooth, network transport, key extraction, authentication or physical dosing is implemented. All package fixtures are synthetic. Existing CamAPS FX installations and pumps are outside this project's scope.

## Run on Ubuntu or macOS

Install Swift 6 or newer, then:

```bash
git clone https://github.com/sejkoramartin/YpsoPumpKit.git
cd YpsoPumpKit
swift test
swift run ypso-simulator
```

The demo prints synthetic reservoir and battery data and rejects a delivery request. No device is required. The package has no external dependencies. The initial local validation passed 19 XCTest tests on Swift 6.4.1 / Ubuntu 26.04; current CI results are linked above.

## No Mac required for CI

GitHub Actions provides macOS/Xcode:

- **Swift package CI** runs Linux/macOS tests and an iOS Simulator library build on pushes and pull requests.
- **Loop simulator build** is manually started in Actions. It fetches a pinned LoopWorkspace, applies the included simulator-only patch, and builds without signing for iOS Simulator. Diagnostics are downloadable as an artifact.

The Loop integration is an experimental bootstrap bridge into LoopKit's existing `MockPumpManager`, not a complete `YpsoPumpManager`. A compile-time guard rejects physical iPhone builds. A successful build does not establish UI behavior or physical pump compatibility. See [CI instructions](Documentation/CI.md).

## Protocol uncertainty is explicit

Older public sources disagree on status length, battery fields, counters and key lifetime. The package never chooses a layout from length alone. The current synthetic scenario uses the newer V05.00.52/protocol-1.3 research interpretation: battery is 0–5 bars, not a measured percentage. Historical profiles remain available for offline comparison.

- [Protocol profiles](Documentation/PROTOCOL.md)
- [Architecture and roadmap — Czech](Documentation/ARCHITECTURE.md)
- [Research report — Czech](Documentation/Research/REPORT.md)
- [Repository and branch inventory](Documentation/Research/INVENTORY.md)
- [Global PR search](Documentation/Research/GLOBAL-PRS.md)

## License and sources

New Swift code is MIT; see [LICENSE](LICENSE) and [NOTICE](NOTICE). The Loop patch retains [upstream attribution](Integration/Loop/UPSTREAM-LICENSE.md). Referenced AGPL Android implementations are not copied or linked into this package. This project is not affiliated with Ypsomed, CamDiab, LoopKit, Trio or AndroidAPS.
