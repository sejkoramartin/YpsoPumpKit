// SPDX-License-Identifier: MIT
import CSodium
import YpsoPumpKit

public enum CryptoError: Error, Equatable {
    case initialization, keyLength, envelopeLength, authentication, missingCounters
    case replay, rebootChanged
}

/// Decrypt-only offline research codec. No transport, provisioning or command API.
public enum OfflineResponse {
    public struct Message: Sendable {
        public let body: [UInt8]
        public let reboot: UInt32
        public let counter: UInt64
    }
    public static func open(_ envelope: [UInt8], key: [UInt8]) throws -> Message {
        guard key.count == 32 else { throw CryptoError.keyLength }
        // 15 fragments * 19 bytes, with 16-byte tag, 24-byte nonce, 12-byte tail.
        guard (52...285).contains(envelope.count) else { throw CryptoError.envelopeLength }
        guard sodium_init() >= 0 else { throw CryptoError.initialization }
        let ciphertext = Array(envelope.dropLast(24))
        let nonce = Array(envelope.suffix(24))
        var plaintext = [UInt8](repeating: 0, count: ciphertext.count - 16)
        var length: UInt64 = 0
        let result = crypto_aead_xchacha20poly1305_ietf_decrypt(
            &plaintext, &length, nil, ciphertext, UInt64(ciphertext.count),
            nil, 0, nonce, key)
        guard result == 0 else { throw CryptoError.authentication }
        guard length == plaintext.count, plaintext.count >= 12 else { throw CryptoError.missingCounters }
        let tail = Array(plaintext.suffix(12))
        let reboot = (0..<4).reduce(UInt32(0)) { $0 | UInt32(tail[$1]) << ($1 * 8) }
        let counter = (0..<8).reduce(UInt64(0)) { $0 | UInt64(tail[4 + $1]) << ($1 * 8) }
        return Message(body: Array(plaintext.dropLast(12)), reboot: reboot, counter: counter)
    }
}

/// In-memory research guard for ONE key and ONE explicitly supplied reboot epoch.
/// Not a persistent security journal: constructing a new instance can reset state.
public actor OfflineStatusSession {
    private let key: [UInt8]
    private let reboot: UInt32
    private var floor: UInt64
    public init(syntheticKey: [UInt8], expectedReboot: UInt32, readFloor: UInt64) throws {
        guard syntheticKey.count == 32 else { throw CryptoError.keyLength }
        key = syntheticKey
        reboot = expectedReboot
        floor = readFloor
    }
    public func readFloor() -> UInt64 { floor }
    public func accept(_ envelope: [UInt8]) throws -> SystemStatus {
        let message = try OfflineResponse.open(envelope, key: key)
        guard message.reboot == reboot else { throw CryptoError.rebootChanged }
        guard message.counter > floor else { throw CryptoError.replay }
        // Consume authenticated counter even if CRC/schema validation later fails.
        // Failed authentication never advances the floor.
        floor = message.counter
        return try SystemStatus.parsePlaintextWithCRC(message.body, profile: .baz00kV050052Protocol13)
    }
}
