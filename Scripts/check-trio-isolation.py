"""Source invariants supplement (not replace) the simulator integration tests."""
from pathlib import Path
import sys
root = Path(sys.argv[1])
catalog = (root / 'Trio/Sources/APS/Devices/DeviceCatalog.swift').read_text()
pumps = catalog.split('static let pumps:')[1].split('// MARK: - Lookups')[0]
assert pumps.count('PumpCatalogEntry(') == 1
assert 'MockPumpManager.self' in pumps
manager = (root / 'Trio/Sources/APS/DeviceDataManager.swift').read_text()
assert '#if !targetEnvironment(simulator)\n#error(' in manager
assert 'guard let mock = pumpManager as? MockPumpManager' in manager
assert 'managerIdentifier == MockPumpManager.pluginIdentifier ? MockPumpManager.self : nil' in manager
assert 'state.bolusEnactmentShouldError = true' in manager
assert 'state.tempBasalEnactmentShouldError = true' in manager
assert 'state.suspendState = .suspended(Date())' in manager
print('Verified Trio simulator-only source invariants')
