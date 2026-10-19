"""Source invariants supplement (not replace) the simulator integration tests."""
from pathlib import Path
import sys
root = Path(sys.argv[1])
catalog = (root / 'Trio/Sources/APS/Devices/DeviceCatalog.swift').read_text()
pumps = catalog.split('static let pumps:')[1].split('// MARK: - Lookups')[0]
assert pumps.count('PumpCatalogEntry(') == 1
assert 'MockPumpManager.self' in pumps
manager = (root / 'Trio/Sources/APS/DeviceDataManager.swift').read_text()
assert '#if !YPSO_SIMULATION_ONLY\n#error(' in manager
assert 'guard let mock = pumpManager as? MockPumpManager' in manager
assert 'managerIdentifier == MockPumpManager.pluginIdentifier ? MockPumpManager.self : nil' in manager
assert 'state.bolusEnactmentShouldError = true' in manager
assert 'state.tempBasalEnactmentShouldError = true' in manager
assert 'state.suspendState = .suspended(Date())' in manager
print('Verified Trio simulator-only source invariants')

provider = (root / 'Trio/Sources/Services/Bluetooth/BluetoothStateManager.swift').read_text()
assert 'CBCentralManager' not in provider
assert 'completion(.denied)' in provider
transmitter = (root / 'Trio/Sources/APS/CGM/BluetoothTransmitter.swift').read_text()
assert 'CBCentralManager(' not in transmitter
assert 'preconditionFailure("Bluetooth transmitters are unavailable' in transmitter
health = (root / 'Trio/Sources/Services/HealthKit/HealthKitManager.swift').read_text()
assert health.count('guard !YpsoTrioSimulationPolicy.isEnabled else') == 12
assert 'static let isEnabled = true' in manager
config = (root / 'Config.xcconfig').read_text()
assert 'YPSO_SIMULATION_ONLY' in config
print('Verified offline Bluetooth and HealthKit policy')

onboarding = (root / 'Trio/Sources/Modules/Onboarding/View/OnboardingSteps/BluetoothPermissionStepView.swift').read_text()
assert 'struct SystemAlert:' in onboarding  # Also used by notification onboarding.
assert 'authorizeBluetooth' not in onboarding

# The only authorized real-Bluetooth exception is the user-started advertisement
# diagnostic. Therapy providers above remain offline.
diagnostic = (root / 'Trio/Sources/Modules/PumpConfig/View/PumpConfigRootView.swift').read_text()
assert diagnostic.count('CBCentralManager(delegate:') == 1
for forbidden in ('.connect(', '.retrievePeripherals(', '.retrieveConnectedPeripherals(',
                  '.discoverServices(', '.writeValue(', '.readValue(', '.setNotifyValue('):
    assert forbidden not in diagnostic, forbidden
assert 'withTimeInterval: 30' in diagnostic
assert 'if phase != .active' in diagnostic
assert '.onDisappear { scanner.stop() }' in diagnostic
assert 'CBAdvertisementDataLocalNameKey' in diagnostic
print('Verified bounded advertisement-only diagnostic exception')
