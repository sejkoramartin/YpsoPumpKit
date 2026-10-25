import Foundation
import XCTest
@testable import OfflineCrypto

@MainActor final class JournalTests: XCTestCase {
    enum Injected: Error { case write }
    func temporaryPath() -> String { FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path }
    func testRestartAndDuplicateWriters() async throws {
        let f = try Fixtures.load(); let path = temporaryPath()
        defer { try? FileManager.default.removeItem(atPath: path) }
        let first = try PersistentStatusSession(path: path, syntheticKey: hex(f.key), expectedReboot: 7)
        try await first.initialize(readFloor: 0)
        _ = try await first.accept(hex(f.vectors[0].envelope))
        let reopened = try PersistentStatusSession(path: path, syntheticKey: hex(f.key), expectedReboot: 7)
        do { _ = try await reopened.accept(hex(f.vectors[0].envelope)); XCTFail("Replay after reopen") }
        catch { XCTAssertEqual(error as? CryptoError, .replay) }
        _ = try await reopened.accept(hex(f.vectors[1].envelope))
        do { _ = try await first.accept(hex(f.vectors[1].envelope)); XCTFail("Stale instance") }
        catch { XCTAssertEqual(error as? CryptoError, .replay) }
        do { try await reopened.initialize(readFloor: 0); XCTFail("Reset allowed") } catch {}
    }
    func testFailedTransactionDoesNotPublishOrConsume() async throws {
        let f = try Fixtures.load(); let path = temporaryPath()
        defer { try? FileManager.default.removeItem(atPath: path) }
        let session = try PersistentStatusSession(path: path, syntheticKey: hex(f.key), expectedReboot: 7)
        try await session.initialize(readFloor: 0)
        do {
            _ = try await session.accept(hex(f.vectors[0].envelope), beforeCommit: { throw Injected.write })
            XCTFail("Published before commit")
        } catch { XCTAssertTrue(error is Injected) }
        let reopened = try PersistentStatusSession(path: path, syntheticKey: hex(f.key), expectedReboot: 7)
        _ = try await reopened.accept(hex(f.vectors[0].envelope))
    }
    func testBadCRCIsDurableAndCorruptionFailsClosed() async throws {
        let f = try Fixtures.load(); let path = temporaryPath()
        defer { try? FileManager.default.removeItem(atPath: path) }
        let session = try PersistentStatusSession(path: path, syntheticKey: hex(f.key), expectedReboot: 7)
        try await session.initialize(readFloor: 0)
        do { _ = try await session.accept(hex(f.vectors[2].envelope)); XCTFail() } catch {}
        let reopened = try PersistentStatusSession(path: path, syntheticKey: hex(f.key), expectedReboot: 7)
        do { _ = try await reopened.accept(hex(f.vectors[1].envelope)); XCTFail() }
        catch { XCTAssertEqual(error as? CryptoError, .replay) }
        try Data("corrupt".utf8).write(to: URL(fileURLWithPath: path))
        do { _ = try await reopened.accept(hex(f.vectors[0].envelope)); XCTFail() }
        catch { XCTAssertTrue(error is JournalError) }
    }
    func testMissingJournalFailsClosed() async throws {
        let f = try Fixtures.load(); let path = temporaryPath()
        let session = try PersistentStatusSession(path: path, syntheticKey: hex(f.key), expectedReboot: 7)
        do { _ = try await session.accept(hex(f.vectors[0].envelope)); XCTFail() }
        catch { XCTAssertTrue(error is JournalError) }
        XCTAssertFalse(FileManager.default.fileExists(atPath: path))
    }
    func testWholeFileRollbackIsExplicitlyNotProtected() async throws {
        let f = try Fixtures.load(); let path = temporaryPath()
        defer { try? FileManager.default.removeItem(atPath: path) }
        let session = try PersistentStatusSession(path: path, syntheticKey: hex(f.key), expectedReboot: 7)
        try await session.initialize(readFloor: 0)
        let snapshot = try Data(contentsOf: URL(fileURLWithPath: path))
        _ = try await session.accept(hex(f.vectors[0].envelope))
        try snapshot.write(to: URL(fileURLWithPath: path))
        // Demonstrates a limitation, not a security guarantee: trusted external
        // monotonic state is required to detect restoring the entire journal.
        _ = try await session.accept(hex(f.vectors[0].envelope))
    }
    func testFullUnsignedFloorAndIdentityBinding() async throws {
        let f = try Fixtures.load(); let path = temporaryPath()
        defer { try? FileManager.default.removeItem(atPath: path) }
        let session = try PersistentStatusSession(path: path, syntheticKey: hex(f.key), expectedReboot: 7)
        try await session.initialize(readFloor: UInt64.max)
        do { _ = try await session.accept(hex(f.vectors[0].envelope)); XCTFail() }
        catch { XCTAssertEqual(error as? CryptoError, .replay) }
        let other = try PersistentStatusSession(path: path, syntheticKey: hex(f.key), expectedReboot: 8)
        do { _ = try await other.accept(hex(f.vectors[3].envelope)); XCTFail() }
        catch { XCTAssertTrue(error is JournalError) }
    }
}
