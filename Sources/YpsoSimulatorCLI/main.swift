import YpsoPumpSimulator

@main struct SimulatorDemo {
    static func main() async throws {
        let adapter = SimulatorAdapter()
        await adapter.connect()
        let status = try await adapter.status()
        print("SIMULATION ONLY — no Bluetooth or physical pump")
        print("Reservoir: \(status.reservoirUnits) U; battery: \(status.batteryBars ?? 0)/5 bars; mode: \(status.mode)")
        do { try adapter.requestBolus(units: 1) }
        catch { print("Delivery request rejected: \(error)") }
        await adapter.disconnect()
    }
}
