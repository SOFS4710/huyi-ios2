import Foundation

/// 全局存储（UserDefaults 持久化，对应安卓版 Store.kt）
final class AppStore {
    static let shared = AppStore()
    private let d = UserDefaults.standard

    // ---- 个人信息 ----
    var nick: String { get { d.string(forKey: "nick") ?? "朱淳熙" } set { d.set(newValue, forKey: "nick") } }
    var sign: String { get { d.string(forKey: "sign") ?? "" } set { d.set(newValue, forKey: "sign") } }
    var birth: String { get { d.string(forKey: "birth") ?? "" } set { d.set(newValue, forKey: "birth") } } // yyyy-MM-dd
    var avatarQq: String { get { d.string(forKey: "avatar_qq") ?? "" } set { d.set(newValue, forKey: "avatar_qq") } }

    // ---- 登录身份（仅展示，不存密码） ----
    var role: String { get { d.string(forKey: "role") ?? "访客" } set { d.set(newValue, forKey: "role") } }

    // ---- 温度单位（C=摄氏度 / F=华氏度），硬件检测温度跟随 ----
    var tempUnit: String { get { d.string(forKey: "temp_unit") ?? "C" } set { d.set(newValue, forKey: "temp_unit") } }

    // ---- 深色模式 ----
    var darkMode: Bool { get { d.bool(forKey: "dark_mode") } set { d.set(newValue, forKey: "dark_mode") } }

    // ---- 绑定的电脑信息（JSON 字符串） ----
    var pcBind: String { get { d.string(forKey: "pc_bind") ?? "" } set { d.set(newValue, forKey: "pc_bind") } }

    // ---- 自动同步间隔（秒，默认 60） ----
    var syncInterval: Int { get { d.integer(forKey: "sync_interval") == 0 ? 60 : d.integer(forKey: "sync_interval") } set { d.set(newValue, forKey: "sync_interval") } }

    // ---- 日志 ----
    var logs: [String] { get { d.stringArray(forKey: "logs") ?? [] } set { d.set(newValue, forKey: "logs") } }
    func addLog(_ s: String) {
        var l = logs; l.insert("[\(Self.nowStr())] \(s)", at: 0)
        if l.count > 200 { l = Array(l.prefix(200)) }
        d.set(l, forKey: "logs")
    }
    func clearLogs() { d.set([String](), forKey: "logs") }

    // ---- 笔记 ----
    var notes: [String] { get { d.stringArray(forKey: "notes") ?? [] } set { d.set(newValue, forKey: "notes") } }

    private static func nowStr() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm:ss"; return f.string(from: Date())
    }

    // ---- 温度换算 ----
    func tempText(celsius: Double) -> String {
        if tempUnit == "F" {
            return String(format: "%.1f ℉", celsius * 9.0 / 5.0 + 32.0)
        }
        return String(format: "%.1f ℃", celsius)
    }
}
