import XCTest
import Foundation
import OfflineCrypto
import YpsoPumpKit

private func hex(_ s: String) -> [UInt8] {
    stride(from: 0, to: s.count, by: 2).map {
        let start = s.index(s.startIndex, offsetBy: $0)
        return UInt8(s[start..<s.index(start, offsetBy: 2)], radix: 16)!
    }
}
private struct Fixtures: Decodable {
    struct Vector: Decodable { let name: String; let envelope: String; let body: String; let reboot: UInt32; let counter: UInt64 }
    let key: String
    let vectors: [Vector]
    static func load() throws -> Self {
        let url = Bundle.module.url(forResource: "responses", withExtension: "json", subdirectory: "Fixtures")!
        return try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
    }
}
@MainActor final class CryptoTests: XCTestCase {
    func testFixedSyntheticVectorsAndLittleEndianTail() throws {
        let f = try Fixtures.load()
        for v in f.vectors {
            let message = try OfflineResponse.open(hex(v.envelope), key: hex(f.key))
            XCTAssertEqual(message.body, hex(v.body))
            XCTAssertEqual(message.reboot, v.reboot)
            XCTAssertEqual(message.counter, v.counter)
        }
    }
    func testEveryEnvelopeByteIsAuthenticated() throws {
        let f = try Fixtures.load(); let bytes = hex(f.vectors[0].envelope)
        for i in bytes.indices {
            var altered = bytes; altered[i] ^= 1
            XCTAssertThrowsError(try OfflineResponse.open(altered, key: hex(f.key))) {
                XCTAssertEqual($0 as? CryptoError, .authentication)
            }
        }
    }
    func testWrongKeyAndNoncePosition() throws {
        let f = try Fixtures.load(); let bytes = hex(f.vectors[0].envelope)
        XCTAssertThrowsError(try OfflineResponse.open(bytes, key: [UInt8](repeating: 42, count: 32)))
        XCTAssertThrowsError(try OfflineResponse.open(Array(bytes.suffix(24)) + bytes.dropLast(24), key: hex(f.key)))
    }
    func testLengthBoundariesAndTruncations() throws {
        let f = try Fixtures.load(); let bytes = hex(f.vectors[0].envelope)
        for size in 0..<bytes.count {
            XCTAssertThrowsError(try OfflineResponse.open(Array(bytes.prefix(size)), key: hex(f.key)))
        }
        XCTAssertThrowsError(try OfflineResponse.open(bytes, key: [0]))
        XCTAssertThrowsError(try OfflineResponse.open([UInt8](repeating: 0, count: 286), key: hex(f.key)))
    }
    func testReplayAndIncreasingCounter() async throws {
        let f = try Fixtures.load(); let session = try OfflineStatusSession(syntheticKey: hex(f.key), expectedReboot: 7, readFloor: 0)
        _ = try await session.accept(hex(f.vectors[0].envelope))
        do { _ = try await session.accept(hex(f.vectors[0].envelope)); XCTFail() }
        catch { XCTAssertEqual(error as? CryptoError, .replay) }
        _ = try await session.accept(hex(f.vectors[1].envelope))
        let floor = await session.readFloor(); XCTAssertEqual(floor, 2)
    }
    func testAuthenticationFailureDoesNotAdvanceFloor() async throws {
        let f = try Fixtures.load(); let session = try OfflineStatusSession(syntheticKey: hex(f.key), expectedReboot: 7, readFloor: 0)
        var bytes = hex(f.vectors[0].envelope); bytes[0] ^= 1
        do { _ = try await session.accept(bytes); XCTFail() } catch {}
        let floor = await session.readFloor(); XCTAssertEqual(floor, 0)
        _ = try await session.accept(hex(f.vectors[0].envelope))
    }
    func testAuthenticatedBadCRCConsumesCounter() async throws {
        let f = try Fixtures.load(); let session = try OfflineStatusSession(syntheticKey: hex(f.key), expectedReboot: 7, readFloor: 0)
        do { _ = try await session.accept(hex(f.vectors[2].envelope)); XCTFail() }
        catch { XCTAssertEqual(error as? ProtocolError, .invalidCRC) }
        let floor = await session.readFloor(); XCTAssertEqual(floor, 3)
        do { _ = try await session.accept(hex(f.vectors[1].envelope)); XCTFail() }
        catch { XCTAssertEqual(error as? CryptoError, .replay) }
    }
    func testRebootChangesFailClosedAndExplicitFloorSurvivesRecreation() async throws {
        let f = try Fixtures.load(); let session = try OfflineStatusSession(syntheticKey: hex(f.key), expectedReboot: 7, readFloor: 2)
        for index in [3,4] {
            do { _ = try await session.accept(hex(f.vectors[index].envelope)); XCTFail() }
            catch { XCTAssertEqual(error as? CryptoError, .rebootChanged) }
        }
        do { _ = try await session.accept(hex(f.vectors[0].envelope)); XCTFail() }
        catch { XCTAssertEqual(error as? CryptoError, .replay) }
        let floor = await session.readFloor(); XCTAssertEqual(floor, 2)
    }
}
