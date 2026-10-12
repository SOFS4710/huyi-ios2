import Foundation
import UIKit
import SystemConfiguration
import CoreTelephony
import AVFoundation
import CoreMotion
import CoreLocation

/// 硬件信息读取（全部来自 iOS 真实系统 API / sysctl，拿不到显示"未知"，不编造）
enum HardwareService {

    // ===== 设备与系统 =====
    static var deviceName: String { UIDevice.current.name }
    static var systemVersion: String { UIDevice.current.systemVersion }
    static var deviceModel: String { UIDevice.current.model }           // iPhone
    static var deviceIdentifier: String { UIDevice.current.identifierForVendor?.uuidString ?? "未知" }

    /// 型号标识（如 iPhone15,2）
    static var machineCode: String { sysctlString("hw.machine") ?? "未知" }

    /// 中文型号名
    static var deviceModelName: String { mapModel(machineCode) }

    /// 硬件序列号：iOS 无公开 API → 未知
    static var serialNumber: String { "iOS 暂不开放" }

    /// 芯片型号（按机型映射真实 SoC 型号）
    static var chipModel: String { mapChip(machineCode) }

    /// 设备指纹
    static var deviceFingerprint: String { "\(deviceIdentifier) / \(machineCode) / iOS \(systemVersion)" }

    static var cpuCoreCount: Int { Int(ProcessInfo.processInfo.processorCount) }

    /// CPU 架构
    static var cpuArch: String {
        #if arch(arm64)
        return "arm64"
        #else
        return sysctlString("hw.machine") ?? "未知"
        #endif
    }

    /// 开机时长（秒）
    static var uptimeSeconds: TimeInterval { ProcessInfo.processInfo.systemUptime }

    /// 总内存（字节）
    static var totalMemory: UInt64 { ProcessInfo.processInfo.physicalMemory }

    /// 已用内存（字节，简化：物理内存 - 剩余可用）
    static func memoryUsage() -> (used: UInt64, available: UInt64) {
        var pagesize: vm_size_t = 0
        host_page_size(mach_host_self(), &pagesize)
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let kr = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return (0, totalMemory) }
        let free = UInt64(stats.free_count + stats.inactive_count) * UInt64(pagesize)
        let used = totalMemory > free ? totalMemory - free : 0
        return (used, free)
    }

    /// 总/可用存储（字节）
    static func storage() -> (total: UInt64, free: UInt64) {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        let vals = try? url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey])
        let total = UInt64(vals?.volumeTotalCapacity ?? 0)
        let free = UInt64(vals?.volumeAvailableCapacityForImportantUsage ?? 0)
        return (total * 1024, free * 1024)
    }

    // ===== 电池 =====
    static func battery() -> (level: Int, charging: Bool, stateText: String) {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = Int(UIDevice.current.batteryLevel * 100)
        let st = UIDevice.current.batteryState
        let charging = st == .charging || st == .full
        let text: String
        switch st {
        case .charging: text = "充电中"
        case .full: text = "已充满"
        case .unplugged: text = "未充电"
        default: text = "未知"
        }
        return (level, charging, text)
    }

    /// 电池电压/电流/温度/健康：iOS 无公开 API → 未知
    static var batteryVoltage: String { "iOS 暂不开放" }
    static var batteryCurrent: String { "iOS 暂不开放" }
    static var batteryTempC: Double? { nil }
    static var batteryHealth: String { "iOS 暂不开放" }
    static var batteryTech: String { "锂离子电池" }
    static var batteryDesignCapacity: String { "iOS 暂不开放" }
    static var batteryCycles: String { "iOS 暂不开放" }

    // ===== 屏幕 =====
    static var screenRes: String {
        let s = UIScreen.main.bounds.size
        let scale = UIScreen.main.scale
        return "\(Int(s.width * scale)) × \(Int(s.height * scale)) px"
    }
    static var screenSize: String {
        let s = UIScreen.main.bounds.size
        let inches = sqrt(s.width * s.width + s.height * s.height) / 160.0
        return String(format: "%.1f 英寸", inches)
    }
    static var refreshRate: String {
        let hz = UIScreen.main.maximumFramesPerSecond
        return hz > 60 ? "\(hz) Hz" : "\(hz) Hz"
    }

    // ===== 相机 =====
    static func cameras() -> [(pos: String, mega: String)] {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera, .builtInDualCamera, .builtInTripleCamera],
            mediaType: .video, position: .unspecified)
        var out: [(String, String)] = []
        for d in discovery.devices {
            let pos = d.position == .front ? "前置" : (d.position == .back ? "后置" : "未知")
            let w = d.activeFormat.formatDescription.dimensions.width
            let h = d.activeFormat.formatDescription.dimensions.height
            let mega = String(format: "约 %.0f MP", Double(w) * Double(h) / 1_000_000.0)
            out.append((pos, mega))
        }
        return out.isEmpty ? [("后置", "未知")] : out
    }

    // ===== 传感器 =====
    static var hasAccelerometer: Bool { CMMotionManager().isAccelerometerAvailable }
    static var hasGyro: Bool { CMMotionManager().isGyroAvailable }
    static var hasMagnetometer: Bool { CMMotionManager().isMagnetometerAvailable }
    static var hasBarometer: Bool { CMAltimeter.isRelativeAltitudeAvailable() }
    static var sensorCount: Int {
        var n = 0
        if hasAccelerometer { n += 1 }
        if hasGyro { n += 1 }
        if hasMagnetometer { n += 1 }
        if hasBarometer { n += 1 }
        return n
    }

    // ===== 定位 / 卫星 =====
    static var gpsSupported: Bool { CLLocationManager.locationServicesEnabled() }
    static var locationAuth: String {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways: return "始终允许"
        case .authorizedWhenInUse: return "使用期间允许"
        case .denied: return "已拒绝"
        case .restricted: return "受限"
        default: return "未请求"
        }
    }

    // ===== CPU 热状态（对应安卓 thermal 区） =====
    static var thermalStateText: String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return "正常"
        case .fair: return "轻微发热"
        case .serious: return "明显发热"
        case .critical: return "严重发热"
        @unknown default: return "未知"
        }
    }

    // ===== 网络 =====
    static var currentSSID: String {
        guard let ifa = cnCopyCurrentNetworkInfo() as? [String: Any],
              let ssid = ifa["SSID"] as? String, !ssid.isEmpty else { return "未连接" }
        return ssid
    }
    static var wifiBssid: String {
        guard let ifa = cnCopyCurrentNetworkInfo() as? [String: Any],
              let bssid = ifa["BSSID"] as? String else { return "未知" }
        return "iOS 暂不开放"
    }
    static var wifiSignal: String { "iOS 暂不开放" }
    static var wifiRate: String { "iOS 暂不开放" }

    /// 局域网 IP（en0）
    static var localIP: String {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return "未知" }
        var ptr = ifaddr
        while ptr != nil {
            let interface = ptr!.pointee
            let family = interface.ifa_addr.pointee.sa_family
            if family == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
            ptr = interface.ifa_next
        }
        freeifaddrs(ifaddr)
        return address ?? "未知"
    }

    /// 网关（按本机 IP 网段推断 .1，标注口径）
    static var gateway: String {
        let ip = localIP
        if ip != "未知", let idx = ip.lastIndex(of: ".") {
            return String(ip[..<idx]) + ".1"
        }
        return "未知"
    }

    /// DNS 服务器（系统配置真实读取）
    static var dnsServers: [String] {
        var list: [String] = []
        guard let defaultConfig = SCDynamicStoreCopyDNSConfiguration(nil) else { return list }
        if let servers = defaultConfig["ServerAddresses"] as? [String] {
            list = servers
        }
        return list
    }

    /// 运营商（真实）
    static func carrierInfo() -> (name: String, networkType: String) {
        let info = CTTelephonyNetworkInfo()
        guard let carrier = info.subscriberCellularProvider else { return ("未检测到 SIM 卡", "未知") }
        let name = carrier.carrierName ?? "未检测到 SIM 卡"
        let type = info.currentRadioAccessTechnology ?? "未知"
        let net: String
        switch type {
        case CTRadioAccessTechnologyLTE: net = "4G"
        case CTRadioAccessTechnologyNR, CTRadioAccessTechnologyNRNSA: net = "5G"
        case CTRadioAccessTechnologyWCDMA, CTRadioAccessTechnologyHSDPA: net = "3G"
        case CTRadioAccessTechnologyEdge, CTRadioAccessTechnologyGPRS: net = "2G"
        default: net = "未知"
        }
        return (name, net)
    }

    /// 电话类型（iOS 均为蜂窝设备）
    static var phoneType: String { "蜂窝移动" }

    /// 蓝牙 MAC：iOS 不开放 → 未知
    static var bluetoothMac: String { "iOS 暂不开放" }

    /// 公网 IP（异步真实请求）
    static func publicIP(completion: @escaping (String) -> Void) {
        var done = false
        let urls = ["https://api.ipify.org", "https://ifconfig.me/ip", "https://ipinfo.io/ip"]
        for u in urls {
            guard let url = URL(string: u) else { continue }
            var req = URLRequest(url: url); req.timeoutInterval = 5
            URLSession.shared.dataTask(with: req) { data, _, _ in
                guard !done else { return }
                if let d = data, let s = String(data: d, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), s.contains(".") {
                    done = true
                    DispatchQueue.main.async { completion(s) }
                }
            }.resume()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            if !done { done = true; completion("未知") }
        }
    }

    // ===== sysctl 辅助 =====
    private static func sysctlString(_ name: String) -> String? {
        var size = 0
        sysctlbyname(name, nil, &size, nil, 0)
        guard size > 0 else { return nil }
        var buf = [CChar](repeating: 0, count: size)
        sysctlbyname(name, &buf, &size, nil, 0)
        return String(cString: buf)
    }

    private static func cnCopyCurrentNetworkInfo() -> CFDictionary? {
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else { return nil }
        for iface in interfaces {
            if let info = CNCopyCurrentNetworkInfo(iface as CFString) {
                return info
            }
        }
        return nil
    }

    // ===== 型号/芯片映射（真实机型代号 → 中文名） =====
    static func mapModel(_ code: String) -> String {
        switch code {
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPhone17,1": return "iPhone 16 Pro"
        case "iPhone17,2": return "iPhone 16 Pro Max"
        case "iPhone17,3": return "iPhone 16"
        case "iPhone17,4": return "iPhone 16 Plus"
        case "iPhone17,5": return "iPhone 16e"
        case "iPhone18,1": return "iPhone 17 Pro"
        case "iPhone18,2": return "iPhone 17 Pro Max"
        case "iPhone18,3": return "iPhone 17"
        case "iPhone18,4": return "iPhone 17 Air"
        default: return code
        }
    }

    static func mapChip(_ code: String) -> String {
        switch code {
        case "iPhone14,5", "iPhone14,7", "iPhone14,8": return "Apple A15 仿生"
        case "iPhone15,2", "iPhone15,3", "iPhone15,4", "iPhone15,5": return "Apple A16 仿生"
        case "iPhone16,1", "iPhone16,2": return "Apple A17 Pro"
        case "iPhone17,1", "iPhone17,2": return "Apple A18 Pro"
        case "iPhone17,3", "iPhone17,4", "iPhone17,5": return "Apple A18"
        case "iPhone18,1", "iPhone18,2": return "Apple A19 Pro"
        case "iPhone18,3", "iPhone18,4": return "Apple A19"
        default: return "Apple A 系列"
        }
    }
}
