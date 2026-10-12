import Foundation

/// 电脑端同步（与安卓版协议一致：端口 8765，/info、/api/ping，可带配对码）
enum PcSyncService {

    /// 扫码结果 JSON：{"v":1,"t":"huyi",ip,port,code,id,name}
    static func parseQr(_ raw: String) -> (base: String, code: String?)? {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.hasPrefix("http://") || t.hasPrefix("https://") { return (t, nil) }
        guard let data = t.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["t"] as? String == "huyi" || json["v"] as? Int == 1,
              let ip = json["ip"] as? String else { return nil }
        let port = json["port"] as? Int ?? 8765
        let code = json["code"] as? String
        let base = "http://\(ip):\(port)"
        return (base, code)
    }

    /// 请求电脑接口（优先 /info，失败试 /api/ping），返回解析后的电脑信息
    static func fetchPcInfo(base: String, code: String?) async -> PcInfo? {
        guard base.hasPrefix("http") else { return nil }
        let suffix = code.flatMap { $0.isEmpty ? nil : "?code=\($0)" } ?? ""
        for path in ["/info", "/api/ping"] {
            guard let url = URL(string: base + path + suffix) else { continue }
            var req = URLRequest(url: url)
            req.timeoutInterval = 5
            do {
                let (data, resp) = try await URLSession.shared.data(for: req)
                guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else { continue }
                let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
                let name = (obj["name"] as? String) ?? (obj["computerName"] as? String) ?? "未知电脑"
                return PcInfo(addr: base, name: name, infoText: buildInfoText(obj))
            } catch {
                continue
            }
        }
        return nil
    }

    /// 拼接电脑详情文本（网卡/显示器/系统等）
    private static func buildInfoText(_ json: [String: Any]) -> String {
        var lines: [String] = []
        if let os = json["os"] as? String { lines.append("系统：\(os)") }
        if let nics = json["nics"] as? [[String: Any]] {
            for nic in nics.prefix(3) {
                let n = nic["name"] as? String ?? "网卡"
                let ip = nic["ip"] as? String ?? ""
                lines.append("\(n)：\(ip)")
            }
        } else if let nics = json["网卡"] as? [[String: Any]] {
            for nic in nics.prefix(3) {
                let n = nic["name"] as? String ?? "网卡"
                let ip = nic["ip"] as? String ?? ""
                lines.append("\(n)：\(ip)")
            }
        }
        if let monitors = json["monitors"] as? [[String: Any]] {
            for m in monitors.prefix(2) {
                let n = m["name"] as? String ?? "显示器"
                let res = m["resolution"] as? String ?? m["分辨率"] as? String ?? ""
                lines.append("\(n)：\(res)")
            }
        } else if let monitors = json["显示器"] as? [[String: Any]] {
            for m in monitors.prefix(2) {
                let n = m["name"] as? String ?? "显示器"
                let res = m["resolution"] as? String ?? m["分辨率"] as? String ?? ""
                lines.append("\(n)：\(res)")
            }
        }
        if lines.isEmpty { lines.append("已连接电脑端服务") }
        return lines.joined(separator: "\n")
    }
}
