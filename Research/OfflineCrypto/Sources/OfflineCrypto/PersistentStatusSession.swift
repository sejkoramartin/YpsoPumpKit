// SPDX-License-Identifier: MIT
import Foundation
import CSQLite
import CSodium
import YpsoPumpKit

public enum JournalError: Error { case storage, invalidState, identity }

/// Offline research only. SQLite protects transactions, not rollback of the entire file.
public actor PersistentStatusSession {
    private let path: String
    private let key: [UInt8]
    private let epoch: UInt32
    private let fingerprint: String

    public init(path: String, syntheticKey: [UInt8], expectedReboot: UInt32) throws {
        guard syntheticKey.count == 32 else { throw CryptoError.keyLength }
        guard sodium_init() >= 0 else { throw CryptoError.initialization }
        var hash = [UInt8](repeating: 0, count: 32)
        crypto_hash_sha256(&hash, syntheticKey, UInt64(syntheticKey.count))
        self.fingerprint = hash.map { String(format: "%02x", $0) }.joined()
        self.path = path; self.key = syntheticKey; self.epoch = expectedReboot
    }

    /// Explicit bootstrap only. Never replaces an existing journal or baseline.
    public func initialize(readFloor: UInt64) throws {
        try database(create: true) { db in
            try execute(db, "BEGIN EXCLUSIVE")
            do {
                // No IF NOT EXISTS: reinitializing even a valid database must fail.
                try execute(db, "CREATE TABLE state (id INTEGER PRIMARY KEY CHECK(id=1), version INTEGER NOT NULL CHECK(version=1), fingerprint TEXT NOT NULL, epoch TEXT NOT NULL, counter TEXT NOT NULL)")
                try execute(db, "INSERT INTO state VALUES (1,1,'\(fingerprint)','\(epoch)','\(readFloor)')")
                try execute(db, "COMMIT")
            } catch { try? execute(db, "ROLLBACK"); throw error }
        }
    }

    public func accept(_ envelope: [UInt8]) throws -> SystemStatus {
        try accept(envelope, beforeCommit: {})
    }

    // Internal failure-injection point; no plaintext status escapes before COMMIT.
    func accept(_ envelope: [UInt8], beforeCommit: @Sendable () throws -> Void) throws -> SystemStatus {
        let message = try OfflineResponse.open(envelope, key: key)
        guard message.reboot == epoch else { throw CryptoError.rebootChanged }
        try database(create: false) { db in
            try execute(db, "BEGIN IMMEDIATE")
            do {
                var statement: OpaquePointer?
                guard sqlite3_prepare_v2(db, "SELECT version,fingerprint,epoch,counter FROM state WHERE id=1", -1, &statement, nil) == SQLITE_OK else { throw JournalError.storage }
                defer { sqlite3_finalize(statement) }
                guard sqlite3_step(statement) == SQLITE_ROW,
                      sqlite3_column_int(statement, 0) == 1,
                      let identity = sqlite3_column_text(statement, 1),
                      let storedEpoch = sqlite3_column_text(statement, 2),
                      let storedCounter = sqlite3_column_text(statement, 3),
                      let e = UInt32(String(cString: storedEpoch)),
                      let floor = UInt64(String(cString: storedCounter)) else { throw JournalError.invalidState }
                guard String(cString: identity) == fingerprint, e == epoch else { throw JournalError.identity }
                guard message.counter > floor else { throw CryptoError.replay }
                guard sqlite3_step(statement) == SQLITE_DONE else { throw JournalError.invalidState }
                try execute(db, "UPDATE state SET counter='\(message.counter)' WHERE id=1")
                try beforeCommit()
                try execute(db, "COMMIT")
            } catch { try? execute(db, "ROLLBACK"); throw error }
        }
        // Authenticated malformed bodies consume the counter durably too.
        return try SystemStatus.parsePlaintextWithCRC(message.body, profile: .baz00kV050052Protocol13)
    }

    private func execute(_ db: OpaquePointer, _ sql: String) throws {
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else { throw JournalError.storage }
    }
    private func database<T>(create: Bool, body: (OpaquePointer) throws -> T) throws -> T {
        var pointer: OpaquePointer?
        let flags = SQLITE_OPEN_READWRITE | (create ? SQLITE_OPEN_CREATE : 0)
        let result = sqlite3_open_v2(path, &pointer, flags, nil)
        guard result == SQLITE_OK, let db = pointer else {
            if let pointer { sqlite3_close(pointer) }; throw JournalError.storage
        }
        defer { sqlite3_close(db) }
        sqlite3_busy_timeout(db, 1000)
        try execute(db, "PRAGMA synchronous=FULL")
        return try body(db)
    }
}
