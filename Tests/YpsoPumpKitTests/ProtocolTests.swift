import XCTest
@testable import YpsoPumpKit
import YpsoPumpSimulator

final class ProtocolTests: XCTestCase {
    func testIndependentCRCGoldenVectors() {
        // Fixed outputs cross-checked against Uneo7's standalone crc.py; no devices.
        let vectors: [([UInt8], UInt16)] = [([], 0xffff), ([0], 0xdd7b), ([1], 0xc0cc),
            ([1,2,3], 0xab4a), ([1,2,3,4], 0xe74f), ([1,2,3,4,5], 0x7be3),
            (Array("123456789".utf8), 0x9057)]
        for (bytes, expected) in vectors { XCTAssertEqual(YpsoCRC.checksum(bytes), expected) }
    }
    func testCRCRejectsCorruptionAndShortInput() throws {
        XCTAssertEqual(try YpsoCRC.verifiedPayload([1, 0xcc, 0xc0]), [1])
        XCTAssertThrowsError(try YpsoCRC.verifiedPayload([1, 0xcd, 0xc0]))
        XCTAssertThrowsError(try YpsoCRC.verifiedPayload([]))
        XCTAssertThrowsError(try YpsoCRC.verifiedPayload([0]))
    }
    func testGLBExactLengthAndComplement() throws {
        XCTAssertEqual(try GLB.decode([0x78,0x56,0x34,0x12,0x87,0xa9,0xcb,0xed]), 0x12345678)
        XCTAssertEqual(try GLB.decode([255,255,255,255,0,0,0,0]), UInt32.max)
        for count in [0,1,7,9,16] { XCTAssertThrowsError(try GLB.decode(Array(repeating: 0, count: count))) }
        XCTAssertThrowsError(try GLB.decode(Array(repeating: 0, count: 8)))
    }
    func testOrderedFrames() throws {
        var parser = FrameAssembler()
        XCTAssertNil(try parser.append([0x12] + Array(repeating: 7, count: 19)))
        XCTAssertEqual(try parser.append([0x22, 8]), Array(repeating: 7, count: 19) + [8])
        try parser.finish()
        XCTAssertEqual(try parser.append([0x10]), [])
    }
    func testRejectsBadHeadersSizesAndOrder() throws {
        let invalid: [[UInt8]] = [[],[0],[0x11],[0x01,1],[0x21,1],[0x10,1],
            [0x11] + Array(repeating: 0, count: 20), [0x12,1], [0x22,1]]
        for frame in invalid {
            var parser = FrameAssembler()
            XCTAssertThrowsError(try parser.append(frame))
            XCTAssertEqual(try parser.append([0x11,42]), [42], "Must reset after errors")
        }
    }
    func testRejectsDuplicateAndChangedCount() throws {
        for second in [[UInt8(0x12)] + Array(repeating: 1, count: 19), [0x23,1], [0x10]] {
            var parser = FrameAssembler()
            _ = try parser.append([0x12] + Array(repeating: 1, count: 19))
            XCTAssertThrowsError(try parser.append(second))
        }
    }
    func testTruncationClearsState() throws {
        var parser = FrameAssembler()
        _ = try parser.append([0x12] + Array(repeating: 1, count: 19))
        XCTAssertThrowsError(try parser.finish())
        XCTAssertEqual(try parser.append([0x11,42]), [42])
    }
    func testMaximumMessage() throws {
        var parser = FrameAssembler()
        for index in 1...15 {
            let result = try parser.append([UInt8(index << 4 | 15)] + Array(repeating: 4, count: 19))
            if index == 15 { XCTAssertEqual(result?.count, 285) } else { XCTAssertNil(result) }
        }
    }
    func testLegacyStatusIsExplicit() throws {
        let bytes: [UInt8] = [1,0x39,0x30,0,0,80,0x3e,0x0b]
        let status = try SystemStatus.parsePlaintextWithCRC(bytes, profile: .legacySixByteDocumentation)
        XCTAssertEqual(status.reservoirUnits, 123.45)
        XCTAssertEqual(status.mode, .basal)
        XCTAssertEqual(status.batteryPercent, 80)
        XCTAssertThrowsError(try SystemStatus.parsePlaintextWithCRC(bytes, profile: .alexPoorJune2026EighteenByte))
    }
    func testCharacterizedProfileKeepsBatteryBars() throws {
        let status = try SimulationScenario.normal.parsedStatus()
        XCTAssertEqual(status.rawBody.count, 18)
        XCTAssertEqual(status.reservoirHundredths, 12345)
        XCTAssertNil(status.batteryPercent)
        XCTAssertEqual(status.batteryBars, 4)
        XCTAssertEqual(status.mode, .stopped)
        XCTAssertEqual(status.reportedTemporaryBasalPercent, 100)
    }
    func testIndependentEighteenByteFixture() throws {
        // Synthetic PR #1 layout; CRC independently calculated with the Python reference.
        let bytes: [UInt8] = [0,0x26,2,0,0,1,85,0,0,0,100,0,0,0,0,0,0,0,0xb8,0x6a]
        let status = try SystemStatus.parsePlaintextWithCRC(bytes, profile: .alexPoorJune2026EighteenByte)
        XCTAssertEqual(status.reservoirUnits, 5.5)
        XCTAssertEqual(status.batteryPercent, 85) // Must not mistake mode@5 for battery.
        XCTAssertEqual(status.mode, .unknown(1))
        XCTAssertEqual(status.reportedTemporaryBasalPercent, 100)
        XCTAssertThrowsError(try SystemStatus.parsePlaintextWithCRC(bytes, profile: .legacySixByteDocumentation))
    }
    func testCharacterizedStatusGoldenVector() throws {
        let bytes: [UInt8] = [10,0x39,0x30,0,0,4,100,0,0,0,100,0,0,0,0,0,0,0,0xf3,0xed]
        let status = try SystemStatus.parsePlaintextWithCRC(bytes, profile: .baz00kV050052Protocol13)
        XCTAssertEqual(status.mode, .running)
        XCTAssertEqual(status.reservoirUnits, 123.45)
        XCTAssertEqual(status.batteryBars, 4)
        XCTAssertNil(status.batteryPercent)
        // Same length is NOT enough to identify a profile.
        let historical = try SystemStatus.parsePlaintextWithCRC(bytes, profile: .alexPoorJune2026EighteenByte)
        XCTAssertEqual(historical.batteryPercent, 100)
        XCTAssertEqual(historical.mode, .unknown(4))
    }
    func testCharacterizedStatusRejectsUnsupportedFields() throws {
        let body: [UInt8] = [10,0x39,0x30,0,0,4,100,0,0,0,100,0,0,0,0,0,0,0]
        for (offset,value) in [(0,UInt8(1)), (5,6), (4,255), (9,1), (11,2), (15,6)] {
            var bytes = body
            bytes[offset] = value
            let crc = YpsoCRC.checksum(bytes)
            bytes += [UInt8(truncatingIfNeeded: crc), UInt8(truncatingIfNeeded: crc >> 8)]
            XCTAssertThrowsError(try SystemStatus.parsePlaintextWithCRC(bytes, profile: .baz00kV050052Protocol13))
        }
    }
    func testCorruptStatusAndInvalidConfiguration() throws {
        for fault in [SimulationScenario.Fault.badCRC, .truncated, .timeout] {
            XCTAssertThrowsError(try SimulationScenario(fault: fault).parsedStatus())
        }
        XCTAssertThrowsError(try SimulationScenario(batteryBars: 6))
        XCTAssertThrowsError(try SimulationScenario(reservoirHundredths: 16001))
        var bytes = Array(repeating: UInt8(0), count: 18)
        bytes[6] = 101
        let crc = YpsoCRC.checksum(bytes)
        bytes += [UInt8(truncatingIfNeeded: crc), UInt8(truncatingIfNeeded: crc >> 8)]
        XCTAssertThrowsError(try SystemStatus.parsePlaintextWithCRC(bytes, profile: .alexPoorJune2026EighteenByte))
    }
    func testDeterministicMalformedInputSweep() {
        // Exercises bounds and reset behavior for every possible header and length.
        for header in UInt8.min...UInt8.max {
            for length in 0...22 {
                var parser = FrameAssembler()
                let bytes = length == 0 ? [] : [header] + Array(repeating: UInt8(0xa5), count: length - 1)
                _ = try? parser.append(bytes)
                try? parser.finish()
                XCTAssertEqual(try parser.append([0x11,42]), [42])
            }
        }
    }
}

@MainActor final class SimulatorTests: XCTestCase {
    func testConnectionLifecycle() async throws {
        let adapter = SimulatorAdapter()
        do { _ = try await adapter.status(); XCTFail("Disconnected read succeeded") }
        catch { XCTAssertEqual(error as? SimulatorError, .disconnected) }
        await adapter.connect()
        let status = try await adapter.status()
        XCTAssertEqual(status.reservoirHundredths, 12345)
        await adapter.disconnect()
        do { _ = try await adapter.status(); XCTFail("Disconnected read succeeded") }
        catch { XCTAssertEqual(error as? SimulatorError, .disconnected) }
    }
    func testDeliveryAlwaysRejected() async throws {
        let adapter = SimulatorAdapter()
        await adapter.connect()
        for value in [0, -1, 1, .nan, .infinity] {
            XCTAssertThrowsError(try adapter.requestBolus(units: value)) { XCTAssertEqual($0 as? SimulatorError, .deliveryDisabled) }
            XCTAssertThrowsError(try adapter.requestTemporaryBasal(unitsPerHour: value, durationSeconds: 1800))
        }
        let status = try await adapter.status()
        XCTAssertEqual(status.reservoirHundredths, 12345)
    }
    func testFaultRecoveryAndConcurrentReads() async throws {
        let pump = SimulatedPump(scenario: try SimulationScenario(fault: .timeout))
        let adapter = SimulatorAdapter(pump: pump)
        await adapter.connect()
        do { _ = try await adapter.status(); XCTFail("Timeout ignored") }
        catch { XCTAssertEqual(error as? SimulatorError, .simulatedTimeout) }
        await pump.configure(.normal)
        async let first = adapter.status()
        async let second = adapter.status()
        let (a,b) = try await (first, second)
        XCTAssertEqual(a,b)
    }
    func testReaderRejectsEmptyExtraAndTruncatedMessages() async throws {
        struct Fixture: StatusFrameSource {
            let frames: [[UInt8]]
            func readStatusFrames() async throws -> [[UInt8]] { frames }
        }
        let frames = try SimulationScenario.normal.statusFrames()
        for input in [[], Array(frames.prefix(1)), frames + frames] {
            do {
                _ = try await StatusReader(source: Fixture(frames: input), profile: .alexPoorJune2026EighteenByte).read()
                XCTFail("Malformed stream accepted")
            } catch { XCTAssertTrue(error is ProtocolError) }
        }
    }
}
