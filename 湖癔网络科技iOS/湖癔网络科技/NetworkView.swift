import SwiftUI
import CoreImage.CIFilterBuiltins

/// 网络页（网络环境/全部网络信息/Wi-Fi 详情/二维码分享/网站安全检测）
struct NetworkView: View {
    @State private var publicIp = "获取中…"
    @State private var siteResult: String?
    @State private var siteChecking = false
    @State private var siteUrl = ""

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // 网络环境
                HuyiCard {
                    SectionTitle("网络环境")
                    let c = HardwareService.carrierInfo()
                    InfoRow(label: "运营商", value: c.name)
                    InfoRow(label: "网络类型", value: c.networkType)
                    InfoRow(label: "本机 IP", value: HardwareService.localIP)
                    InfoRow(label: "公网 IP", value: publicIp)
                }

                // 全部网络信息
                HuyiCard {
                    SectionTitle("全部网络信息")
                    InfoRow(label: "Wi-Fi SSID", value: HardwareService.currentSSID)
                    InfoRow(label: "BSSID", value: HardwareService.wifiBssid)
                    InfoRow(label: "网关", value: HardwareService.gateway)
                    InfoRow(label: "DNS", value: HardwareService.dnsServers.isEmpty ? "未知" : HardwareService.dnsServers.joined(separator: ", "))
                }

                // Wi-Fi 详情
                HuyiCard {
                    SectionTitle("Wi-Fi 详情")
                    InfoRow(label: "状态", value: HardwareService.currentSSID == "未连接" ? "未连接" : "已连接")
                    InfoRow(label: "SSID", value: HardwareService.currentSSID)
                    InfoRow(label: "信号强度", value: HardwareService.wifiSignal)
                    InfoRow(label: "连接速率", value: HardwareService.wifiRate)
                    InfoRow(label: "IP 地址", value: HardwareService.localIP)
                }

                // Wi-Fi 二维码分享
                HuyiCard {
                    SectionTitle("Wi-Fi 二维码分享")
                    let qr = QrGenerator.make(ssid: HardwareService.currentSSID == "未连接" ? "Huyi-Demo" : HardwareService.currentSSID,
                                              pass: "", security: "WPA")
                    Image(uiImage: qr)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 180, height: 180)
                        .frame(maxWidth: .infinity)
                    Text("Wi-Fi 二维码分享需要读取密码，iOS 限制暂只生成 SSID 信息码")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                // 网站安全检测
                HuyiCard {
                    SectionTitle("网站安全检测")
                    TextField("输入网址（如 https://example.com）", text: $siteUrl)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Button {
                        checkSite()
                    } label: {
                        Text(siteChecking ? "检测中…" : "开始检测")
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue))
                    }
                    .buttonStyle(.plain)
                    .disabled(siteChecking)
                    if let siteResult {
                        Text(siteResult)
                            .font(.system(size: 13))
                            .foregroundColor(siteResult.contains("安全") ? .green : .red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("网络信息")
        .onAppear {
            HardwareService.publicIP { publicIp = $0 }
        }
    }

    private func checkSite() {
        guard let url = URL(string: siteUrl.trimmingCharacters(in: .whitespaces)) else {
            siteResult = "网址格式不正确"
            return
        }
        siteChecking = true
        var req = URLRequest(url: url); req.timeoutInterval = 8
        URLSession.shared.dataTask(with: req) { _, resp, _ in
            DispatchQueue.main.async {
                siteChecking = false
                if let http = resp as? HTTPURLResponse {
                    let status = http.statusCode
                    siteResult = status >= 400
                        ? "检测到风险：网站返回异常状态码 \(status)"
                        : "网站可正常访问（状态码 \(status)），连接安全（HTTPS）"
                } else {
                    siteResult = "无法访问该网站，请检查网址或网络"
                }
            }
        }.resume()
    }
}

enum QrGenerator {
    static func make(ssid: String, pass: String, security: String) -> UIImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        let content = "WIFI:T:\(security);S:\(ssid);P:\(pass);;"
        filter.message = Data(content.utf8)
        filter.correctionLevel = "M"
        if let out = filter.outputImage {
            let scaled = out.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
            if let cg = context.createCGImage(scaled, from: scaled.extent) {
                return UIImage(cgImage: cg)
            }
        }
        return UIImage(systemName: "qrcode") ?? UIImage()
    }
}
