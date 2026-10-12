import Foundation
import LocalAuthentication
import AVFoundation
import CoreLocation
import UIKit

/// 安全检测（iOS 系统级真实检测；iOS 沙盒无法枚举第三方应用，改为真实系统安全审计）
enum SecurityService {

    /// 病毒库版本（与安卓版一致）
    static let virusDbVersion = "2026 版"

    /// 越狱/篡改检测（真实：检查常见越狱痕迹路径与 scheme）
    static func jailbreakCheck() -> (jailbroken: Bool, detail: String) {
        let paths = [
            "/Applications/Cydia.app",
            "/Applications/Sileo.app",
            "/usr/bin/ssh",
            "/usr/sbin/sshd",
            "/bin/bash",
            "/etc/apt",
            "/private/var/lib/apt",
            "/Library/MobileSubstrate/MobileSubstrate.dylib"
        ]
        let schemes = ["cydia://", "sileo://", "zbra://"]
        for p in paths where FileManager.default.fileExists(atPath: p) {
            return (true, "检测到越狱痕迹：\(p)")
        }
        for s in schemes where UIApplication.shared.canOpenURL(URL(string: s)!) {
            return (true, "检测到越狱商店：\(s)")
        }
        return (false, "未发现越狱/篡改痕迹")
    }

    /// 生物识别与密码（真实：LocalAuthentication）
    static func authProtection() -> (enabled: Bool, detail: String) {
        let ctx = LAContext()
        var err: NSError?
        let can = ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &err)
        var type = "密码"
        if ctx.biometryType == .faceID { type = "面容 ID" }
        if ctx.biometryType == .touchID { type = "触控 ID" }
        if ctx.biometryType == .opticID { type = "光学 ID" }
        return (can, can ? "已开启 \(type) 设备解锁" : "未设置设备密码/生物识别")
    }

    /// 本 App 敏感权限审计（真实：当前系统授权状态）
    static func permissionAudit() -> [AppThreat] {
        var out: [AppThreat] = []
        let cam = AVCaptureDevice.authorizationStatus(for: .video)
        if cam == .authorized {
            out.append(AppThreat(label: "相机权限", pkg: "camera", risk: "已授权（敏感）"))
        }
        let loc = CLLocationManager.authorizationStatus()
        if loc == .authorizedAlways || loc == .authorizedWhenInUse {
            out.append(AppThreat(label: "定位权限", pkg: "location", risk: "已授权（敏感）"))
        }
        return out
    }

    /// 系统级扫描：越狱检测 + 设备保护 + 权限审计（真实数据）
    static func systemScan() -> [AppThreat] {
        var out: [AppThreat] = []
        let jb = jailbreakCheck()
        if jb.jailbroken {
            out.append(AppThreat(label: "越狱检测", pkg: "system", risk: "高风险（\(jb.detail)）"))
        }
        let auth = authProtection()
        if !auth.enabled {
            out.append(AppThreat(label: "设备保护", pkg: "system", risk: "中风险（未设置设备密码/生物识别）"))
        }
        for t in permissionAudit() {
            out.append(t)
        }
        return out
    }

    /// 离线文件扫描：检查本 App 沙盒缓存内可疑文件（真实遍历）
    static func scanLocalFiles() -> [AppThreat] {
        var out: [AppThreat] = []
        let dirs = [FileManager.default.temporaryDirectory.path]
        let suspiciousExt = ["apk", "exe", "bat", "sh", "scr", "vbs"]
        let fm = FileManager.default
        for dir in dirs {
            guard let files = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for f in files {
                let ext = (f as NSString).pathExtension.lowercased()
                if suspiciousExt.contains(ext) {
                    out.append(AppThreat(label: f, pkg: "file", risk: "可疑可执行文件（\(ext)）"))
                }
            }
        }
        return out
    }
}
