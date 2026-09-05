import Darwin
import Foundation
import IOKit.ps

// MARK: - 表情を動かす指標の切り替え

enum MetricSource: Int, CaseIterable {
    case memory = 0
    case cpu = 1
    case battery = 2
    case random = 3

    var menuLabel: String {
        switch self {
        case .memory: return "メモリ使用率"
        case .cpu: return "CPU使用率"
        case .battery: return "バッテリー残量"
        case .random: return "気まぐれ（お遊び）"
        }
    }
}

// MARK: - CPU使用率（2回の計測の差分から算出。初回は0を返す）

final class CPUUsageMonitor {
    private var previousTicks: host_cpu_load_info?

    func usagePercent() -> Double {
        var info = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &info) { ptr -> kern_return_t in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, intPtr, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        defer { previousTicks = info }
        guard let prev = previousTicks else { return 0 }

        let userDiff = Double(info.cpu_ticks.0 &- prev.cpu_ticks.0)
        let systemDiff = Double(info.cpu_ticks.1 &- prev.cpu_ticks.1)
        let idleDiff = Double(info.cpu_ticks.2 &- prev.cpu_ticks.2)
        let niceDiff = Double(info.cpu_ticks.3 &- prev.cpu_ticks.3)

        let total = userDiff + systemDiff + idleDiff + niceDiff
        guard total > 0 else { return 0 }

        let busy = (userDiff + systemDiff + niceDiff) / total * 100
        return max(0, min(100, busy))
    }
}

// MARK: - バッテリー残量（デスクトップMacなど非搭載機ではnilを返す）

func batteryPercent() -> Double? {
    guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
          let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
          let first = sources.first,
          let description = IOPSGetPowerSourceDescription(snapshot, first)?.takeUnretainedValue() as? [String: AnyObject],
          let capacity = description[kIOPSCurrentCapacityKey] as? Int,
          let maxCapacity = description[kIOPSMaxCapacityKey] as? Int,
          maxCapacity > 0
    else { return nil }
    return Double(capacity) / Double(maxCapacity) * 100
}

// MARK: - 指標を1つ読み取り、表示用の値と猫のストレス度(%)に変換する
// バッテリーだけは「減るほどストレス」なので反転させる。

struct MetricReading {
    let displayLabel: String
    let displayPercent: Double
    let stressPercent: Double
}

func readMetric(_ source: MetricSource, cpuMonitor: CPUUsageMonitor) -> MetricReading {
    switch source {
    case .memory:
        let p = memoryUsagePercent()
        return MetricReading(displayLabel: "メモリ使用率", displayPercent: p, stressPercent: p)
    case .cpu:
        let p = cpuMonitor.usagePercent()
        return MetricReading(displayLabel: "CPU使用率", displayPercent: p, stressPercent: p)
    case .battery:
        guard let p = batteryPercent() else {
            return MetricReading(displayLabel: "バッテリー(検出不可)", displayPercent: 0, stressPercent: 0)
        }
        return MetricReading(displayLabel: "バッテリー残量", displayPercent: p, stressPercent: 100 - p)
    case .random:
        let p = Double.random(in: 0...100)
        return MetricReading(displayLabel: "気まぐれ", displayPercent: p, stressPercent: p)
    }
}
