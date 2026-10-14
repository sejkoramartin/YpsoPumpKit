// SPDX-License-Identifier: MIT
import YpsoPumpKit

public enum SimulatorError: Error, Equatable, Sendable {
    case disconnected, simulatedTimeout, invalidConfiguration, deliveryDisabled
}

/// Synthetic scenarios; none are device captures or authenticated BLE messages.
public struct SimulationScenario: Equatable, Sendable {
    public enum Fault: Sendable { case none, badCRC, truncated, timeout }
    public let reservoirHundredths: UInt32
    public let batteryBars: UInt8
    public let mode: UInt8
    public let fault: Fault
    public init(reservoirHundredths: UInt32 = 12345, batteryBars: UInt8 = 4,
                mode: UInt8 = 3, fault: Fault = .none) throws {
        guard reservoirHundredths <= 16000, batteryBars <= 5, [UInt8(3), 10].contains(mode) else {
            throw SimulatorError.invalidConfiguration
        }
        self.reservoirHundredths = reservoirHundredths
        self.batteryBars = batteryBars
        self.mode = mode
        self.fault = fault
    }
    public static let normal = try! SimulationScenario()

    public func statusFrames() throws -> [[UInt8]] {
        if fault == .timeout { throw SimulatorError.simulatedTimeout }
        var bytes: [UInt8] = [mode]
        bytes += (0..<4).map { UInt8(truncatingIfNeeded: reservoirHundredths >> ($0 * 8)) }
        bytes += [batteryBars, 0, 0, 0, 0, 100, 0, 0, 0, 0, 0, 0, 0]
        let crc = YpsoCRC.checksum(bytes)
        bytes += [UInt8(truncatingIfNeeded: crc), UInt8(truncatingIfNeeded: crc >> 8)]
        if fault == .badCRC { bytes[18] ^= 1 }
        if fault == .truncated { bytes.removeLast() }
        return [[0x12] + Array(bytes.prefix(19)), [0x22] + Array(bytes.dropFirst(19))]
    }

    public func parsedStatus() throws -> SystemStatus {
        var assembler = FrameAssembler()
        var message: [UInt8]?
        for frame in try statusFrames() { message = try assembler.append(frame) }
        try assembler.finish()
        guard let bytes = message else {
            throw ProtocolError.incompleteMessage
        }
        return try SystemStatus.parsePlaintextWithCRC(bytes, profile: .baz00kV050052Protocol13)
    }
}

public actor SimulatedPump: StatusFrameSource {
    private var connected = false
    private var scenario: SimulationScenario
    public init(scenario: SimulationScenario = .normal) { self.scenario = scenario }
    public func connect() { connected = true }
    public func disconnect() { connected = false }
    public func configure(_ scenario: SimulationScenario) { self.scenario = scenario }
    public func readStatusFrames() throws -> [[UInt8]] {
        guard connected else { throw SimulatorError.disconnected }
        return try scenario.statusFrames()
    }
}

/// The application adapter is deliberately sealed to a concrete in-memory pump.
/// It cannot accept an arbitrary transport, so tests cannot accidentally inject BLE.
public struct SimulatorAdapter: Sendable {
    private let pump: SimulatedPump
    public init(pump: SimulatedPump = SimulatedPump()) { self.pump = pump }
    public func connect() async { await pump.connect() }
    public func disconnect() async { await pump.disconnect() }
    public func status() async throws -> SystemStatus { try await StatusReader(source: pump, profile: .baz00kV050052Protocol13).read() }
    public func requestBolus(units: Double) throws { throw SimulatorError.deliveryDisabled }
    public func requestTemporaryBasal(unitsPerHour: Double, durationSeconds: Double) throws {
        throw SimulatorError.deliveryDisabled
    }
}
