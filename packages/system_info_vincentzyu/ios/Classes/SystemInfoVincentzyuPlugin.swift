import Darwin
import Flutter
import Foundation
import UIKit

public final class SystemInfoVincentzyuPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "system_info_vincentzyu/methods",
            binaryMessenger: registrar.messenger()
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
        let device = UIDevice.current
        let osName = device.userInterfaceIdiom == .pad ? "iPadOS" : device.systemName
        var values: [String: Any] = [
            "operatingSystem": "\(osName) \(device.systemVersion) (\(machine()))",
            "host": device.name,
            "kernel": kernel(),
            "uptimeSeconds": Int64(ProcessInfo.processInfo.systemUptime),
            "cpuModel": machine(),
            "logicalProcessors": ProcessInfo.processInfo.processorCount,
            "memoryTotalBytes": memory.total,
            "locale": Locale.current.identifier,
        ]
        if let used = memory.used { values["memoryUsedBytes"] = used }
        if let used = disk.used { values["diskUsedBytes"] = used }
        if let total = disk.total { values["diskTotalBytes"] = total }
        if let ip = localIp() { values["localIp"] = ip }
        return values
    }

    private func memoryInfo() -> (used: Int64?, total: Int64) {
        let total = Int64(clamping: ProcessInfo.processInfo.physicalMemory)
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride
        )
        let status = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard status == KERN_SUCCESS else { return (nil, total) }
        let pageSize = UInt64(vm_page_size)
        let reusable = UInt64(stats.purgeable_count) + UInt64(stats.external_page_count)
        let available = (UInt64(stats.free_count) + reusable) * pageSize
        return (Int64(clamping: ProcessInfo.processInfo.physicalMemory > available
            ? ProcessInfo.processInfo.physicalMemory - available : 0), total)
    }

    private func diskInfo() -> (used: Int64?, total: Int64?) {
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
              let values = try? url.resourceValues(forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey,
              ]),
              let totalValue = values.volumeTotalCapacity else { return (nil, nil) }
        let total = Int64(totalValue)
        guard let available = values.volumeAvailableCapacityForImportantUsage else {
            return (nil, total)
        }
        return (max(total - available, 0), total)
    }

    private func kernel() -> String {
        var value = utsname()
        uname(&value)
        return "Darwin \(string(from: &value.release))"
    }

    private func machine() -> String {
        var value = utsname()
        uname(&value)
        return string(from: &value.machine)
    }

    private func string<T>(from value: inout T) -> String {
        withUnsafePointer(to: &value) {
            $0.withMemoryRebound(to: CChar.self, capacity: MemoryLayout<T>.size) {
                String(cString: $0)
            }
        }
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
            guard getnameinfo(
                address,
                socklen_t(address.pointee.sa_len),
                &host,
                socklen_t(host.count),
                nil,
                0,
                NI_NUMERICHOST
            ) == 0 else { continue }
            let ip = String(cString: host)
            guard !ip.hasPrefix("127."), !ip.hasPrefix("169.254.") else { continue }
            if name == "en0" { return ip }
            fallback = fallback ?? ip
        }
        return fallback
    }
}
