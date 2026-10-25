import Foundation
import OfflineCrypto
#if os(Linux)
import Glibc
#else
import Darwin
#endif

// Test executable: fixed synthetic key and fixture only, no transport.
@main struct JournalCrashProbe {
    static func main() async throws {
        let args = CommandLine.arguments
        guard args.count == 4 else { exit(64) }
        let mode = args[1]
        let session = try PersistentStatusSession(path: args[2], syntheticKey: Array(0...31), expectedReboot: 7)
        let json = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: args[3]))) as! [String: Any]
        let vector = (json["vectors"] as! [[String: Any]])[0]
        let text = vector["envelope"] as! String
        let bytes: [UInt8] = stride(from: 0, to: text.count, by: 2).map {
            let start = text.index(text.startIndex, offsetBy: $0)
            return UInt8(text[start..<text.index(start, offsetBy: 2)], radix: 16)!
        }
        if mode == "initialize" { try await session.initialize(readFloor: 0); return }
        do {
            _ = try await session.accept(bytes, beforeCommit: {
                if mode == "kill-before" { kill(getpid(), SIGKILL) }
            }, afterCommit: {
                if mode == "kill-after" { kill(getpid(), SIGKILL) }
            })
            print("accepted")
        } catch CryptoError.replay { print("replay"); exit(23) }
    }
}
