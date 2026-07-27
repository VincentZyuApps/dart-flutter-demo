import Cocoa
import Darwin
import FlutterMacOS
import Foundation

public final class SystemInfoVincentzyuPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "system_info_vincentzyu/methods",
            binaryMessenger: registrar.messenger
        )
        registrar.addMethodCallDelegate(SystemInfoVincentzyuPlugin(), channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method == "getInfo" else {
            result(FlutterMethodNotImplemented)
            return
        }
        result(collect())
    }

    private func collect() -> [String: Any] {
        let memory = memoryInfo()
        let disk = diskInfo()
        var values: [String: Any] = [
            "operatingSystem": "\(ProcessInfo.processInfo.operatingSystemVersionString) \(sysctlString("hw.machine") ?? "unknown")",
            "kernel": "Darwin \(sysctlString("kern.osrelease") ?? "unknown")",
            "uptimeSeconds": Int64(ProcessInfo.processInfo.systemUptime),
            "logicalProcessors": ProcessInfo.processInfo.processorCount,
            "memoryTotalBytes": memory.total,
            "locale": Locale.current.identifier,
        ]
        if let host = Host.current().localizedName ?? Host.current().name { values["host"] = host }
        if let cpu = sysctlString("machdep.cpu.brand_string") ?? sysctlString("hw.model") { values["cpuModel"] = cpu }
        if let used = memory.used { values["memoryUsedBytes"] = used }
        if let used = disk.used { values["diskUsedBytes"] = used }
        if let total = disk.total { values["diskTotalBytes"] = total }
        if let ip = localIp() { values["localIp"] = ip }
        return values
    }

    private func memoryInfo() -> (used: Int64?, total: Int64) {
        let physical = ProcessInfo.processInfo.physicalMemory
        let total = Int64(clamping: physical)
        var pageSize: vm_size_t = 0
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
        )
        guard host_page_size(mach_host_self(), &pageSize) == KERN_SUCCESS else { return (nil, total) }
        let status = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard status == KERN_SUCCESS else { return (nil, total) }
        let available = (UInt64(stats.free_count) + UInt64(stats.purgeable_count) +
            UInt64(stats.external_page_count)) * UInt64(pageSize)
        return (Int64(clamping: physical > available ? physical - available : 0), total)
    }

    private func diskInfo() -> (used: Int64?, total: Int64?) {
        guard let values = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey,
        ]), let totalValue = values.volumeTotalCapacity else { return (nil, nil) }
        let total = Int64(totalValue)
        let available = values.volumeAvailableCapacityForImportantUsage ??
            values.volumeAvailableCapacity.map(Int64.init)
        return (available.map { max(total - $0, 0) }, total)
    }

    private func sysctlString(_ name: String) -> String? {
        var size: size_t = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: Int(size))
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
        return String(cString: buffer)
    }

    private func localIp() -> String? {
        var interfaces: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfaces) == 0, let first = interfaces else { return nil }
        defer { freeifaddrs(interfaces) }
        var pointer: UnsafeMutablePointer<ifaddrs>? = first
        var fallback: String?
        while let current = pointer {
            defer { pointer = current.pointee.ifa_next }
            guard let address = current.pointee.ifa_addr,
                  address.pointee.sa_family == UInt8(AF_INET) else { continue }
            let name = String(cString: current.pointee.ifa_name)
            var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            guard getnameinfo(address, socklen_t(address.pointee.sa_len), &host,
                              socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 else { continue }
            let ip = String(cString: host)
            guard !ip.hasPrefix("127."), !ip.hasPrefix("169.254.") else { continue }
            if name.hasPrefix("en") { return ip }
            fallback = fallback ?? ip
        }
        return fallback
    }
}
