import Darwin
import Foundation

// MARK: - メモリ使用率取得

func memoryUsagePercent() -> Double {
    var stats = vm_statistics64()
    var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

    let result = withUnsafeMutablePointer(to: &stats) { statsPtr -> kern_return_t in
        statsPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
            host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
        }
    }
    guard result == KERN_SUCCESS else { return 0 }

    var pageSize: vm_size_t = 0
    host_page_size(mach_host_self(), &pageSize)
    let pageSizeD = Double(pageSize)

    let active = Double(stats.active_count) * pageSizeD
    let wired = Double(stats.wire_count) * pageSizeD
    let compressed = Double(stats.compressor_page_count) * pageSizeD

    let used = active + wired + compressed
    let total = Double(ProcessInfo.processInfo.physicalMemory)

    return max(0, min(100, used / total * 100))
}
