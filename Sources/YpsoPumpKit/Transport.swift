// SPDX-License-Identifier: MIT
/// Read-only abstract source of OFFLINE PLAINTEXT research frames.
/// No BLE device address, discovery, connection, write or key exchange API exists.
public protocol StatusFrameSource: Sendable {
    func readStatusFrames() async throws -> [[UInt8]]
}

public struct StatusReader<Source: StatusFrameSource>: Sendable {
    private let source: Source
    private let profile: StatusProfile
    public init(source: Source, profile: StatusProfile) { self.source = source; self.profile = profile }
    public func read() async throws -> SystemStatus {
        var assembler = FrameAssembler()
        var message: [UInt8]?
        for frame in try await source.readStatusFrames() {
            guard message == nil else { throw ProtocolError.invalidFrame }
            message = try assembler.append(frame)
        }
        try assembler.finish()
        guard let message else { throw ProtocolError.incompleteMessage }
        return try SystemStatus.parsePlaintextWithCRC(message, profile: profile)
    }
}
