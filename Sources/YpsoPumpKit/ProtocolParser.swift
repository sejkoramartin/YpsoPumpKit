// SPDX-License-Identifier: MIT
// Protocol observations and attribution: Documentation/PROTOCOL.md and NOTICE.
import Foundation

public enum ProtocolError: Error, Equatable, Sendable {
    case invalidLength(expected: Int, actual: Int)
    case invalidCRC
    case invalidComplement
    case invalidFrame
    case unexpectedFrame(expected: Int, actual: Int)
    case incompleteMessage
    case invalidBattery(UInt8)
    case invalidStatus
}

/// Offline checksum only. Not a command encoder or an authentication mechanism.
public enum YpsoCRC {
    /// CRC-32/MPEG polynomial, reversed zero-padded 4-byte words, low 16 bits.
    public static func checksum(_ bytes: [UInt8]) -> UInt16 {
        var crc: UInt32 = .max
        for base in stride(from: 0, to: bytes.count, by: 4) {
            for offset in (0..<4).reversed() {
                let byte = base + offset < bytes.count ? bytes[base + offset] : 0
                crc ^= UInt32(byte) << 24
                for _ in 0..<8 {
                    crc = crc & 0x80000000 != 0 ? (crc << 1) ^ 0x04C11DB7 : crc << 1
                }
            }
        }
        return UInt16(truncatingIfNeeded: crc)
    }

    public static func verifiedPayload(_ bytes: [UInt8]) throws -> [UInt8] {
        guard bytes.count >= 2 else {
            throw ProtocolError.invalidLength(expected: 2, actual: bytes.count)
        }
        let payload = Array(bytes.dropLast(2))
        let received = UInt16(bytes[bytes.count - 2]) | UInt16(bytes[bytes.count - 1]) << 8
        guard checksum(payload) == received else { throw ProtocolError.invalidCRC }
        return payload
    }
}

public enum GLB {
    /// Exactly one unsigned 32-bit little-endian value and its one's complement.
    public static func decode(_ bytes: [UInt8]) throws -> UInt32 {
        guard bytes.count == 8 else {
            throw ProtocolError.invalidLength(expected: 8, actual: bytes.count)
        }
        let value = uint32LE(bytes, at: 0)
        guard value ^ uint32LE(bytes, at: 4) == UInt32.max else {
            throw ProtocolError.invalidComplement
        }
        return value
    }
}

func uint32LE(_ bytes: [UInt8], at offset: Int) -> UInt32 {
    (0..<4).reduce(0) { $0 | UInt32(bytes[offset + $1]) << ($1 * 8) }
}

/// Strict ordered reassembly of one message. A malformed frame clears partial state.
/// Profile: 1 header + at most 19 data bytes, up to 15 fragments (285 bytes).
public struct FrameAssembler: Sendable {
    private var total = 0
    private var next = 1
    private var buffer: [UInt8] = []
    public init() {}
    public mutating func reset() { total = 0; next = 1; buffer = [] }

    public mutating func append(_ frame: [UInt8]) throws -> [UInt8]? {
        do {
            guard !frame.isEmpty, frame.count <= 20 else { throw ProtocolError.invalidFrame }
            if frame == [0x10], next == 1 { reset(); return [] }
            let count = Int(frame[0] & 15)
            let index = Int(frame[0] >> 4)
            guard count > 0, index > 0, index <= count, frame.count > 1 else {
                throw ProtocolError.invalidFrame
            }
            guard index == next else { throw ProtocolError.unexpectedFrame(expected: next, actual: index) }
            if next == 1 { total = count }
            guard total == count, index == count || frame.count == 20 else {
                throw ProtocolError.invalidFrame
            }
            buffer.append(contentsOf: frame.dropFirst())
            next += 1
            if index == total { let result = buffer; reset(); return result }
            return nil
        } catch { reset(); throw error }
    }

    /// Caller must call this on end-of-stream/timeout, or discard the assembler.
    public mutating func finish() throws {
        if next != 1 { reset(); throw ProtocolError.incompleteMessage }
    }
}

public enum DeliveryMode: Equatable, Sendable {
    case running, stopped, basal, temporaryBasal, fastBolus, extendedBolus, bolusAndBasal, priming, paused
    case unknown(UInt8)
    init(byte: UInt8) {
        switch byte {
        case 0: self = .stopped
        case 1: self = .basal
        case 2: self = .temporaryBasal
        case 3: self = .fastBolus
        case 4: self = .extendedBolus
        case 5: self = .bolusAndBasal
        case 6: self = .priming
        case 7: self = .paused
        default: self = .unknown(byte)
        }
    }
}

/// Explicit profiles prevent silently interpreting contradictory source layouts.
public enum StatusProfile: Sendable {
    case legacySixByteDocumentation
    case alexPoorJune2026EighteenByte
    case baz00kV050052Protocol13
}

/// Research status only. Never use a guessed delivery mode to drive dosing.
public struct SystemStatus: Equatable, Sendable {
    public let mode: DeliveryMode
    public let reservoirHundredths: UInt32
    public let batteryPercent: UInt8?
    public let batteryBars: UInt8?
    public let rawBody: [UInt8]
    public let reportedTemporaryBasalPercent: UInt32?
    public var reservoirUnits: Double { Double(reservoirHundredths) / 100 }

    public static func parsePlaintextWithCRC(_ bytes: [UInt8], profile: StatusProfile) throws -> SystemStatus {
        let length = profile == .legacySixByteDocumentation ? 6 : 18
        guard bytes.count == length + 2 else {
            throw ProtocolError.invalidLength(expected: length + 2, actual: bytes.count)
        }
        let payload = try YpsoCRC.verifiedPayload(bytes)
        if profile == .baz00kV050052Protocol13 {
            let reservoir = uint32LE(payload, at: 1)
            let basal = uint32LE(payload, at: 6)
            let percent = uint32LE(payload, at: 10)
            let remaining = uint32LE(payload, at: 14)
            guard [UInt8(3), 10].contains(payload[0]), reservoir <= 20000,
                  payload[5] <= 5, basal <= 4000, percent <= 500, remaining <= 1440 else {
                throw ProtocolError.invalidStatus
            }
            return SystemStatus(mode: payload[0] == 3 ? .stopped : .running,
                                reservoirHundredths: reservoir, batteryPercent: nil,
                                batteryBars: payload[5], rawBody: payload,
                                reportedTemporaryBasalPercent: percent)
        }
        let batteryOffset = profile == .legacySixByteDocumentation ? 5 : 6
        guard payload[batteryOffset] <= 100 else { throw ProtocolError.invalidBattery(payload[batteryOffset]) }
        // PR #1 admits mode@5 vs mode@0 is unresolved. Preserve bytes, do not guess.
        let mode: DeliveryMode = profile == .legacySixByteDocumentation
            ? DeliveryMode(byte: payload[0]) : .unknown(payload[5])
        return SystemStatus(mode: mode, reservoirHundredths: uint32LE(payload, at: 1),
                            batteryPercent: payload[batteryOffset], batteryBars: nil, rawBody: payload,
                            reportedTemporaryBasalPercent: length == 18 ? uint32LE(payload, at: 10) : nil)
    }
}
