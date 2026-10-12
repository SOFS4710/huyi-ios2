import SwiftUI

/// 安全页（1:1 还原安卓 SecurityPage：进入不自动提示，点击扫描才检测；系统级真实检测）
struct SecurityView: View {
    let onOpenNetwork: () -> Void
    @State private var threats: [AppThreat] = []
    @State private var scanning = false
    @State private var scanDone = false
    @State private var fileThreats: [AppThreat] = []
    @State private var fileScanning = false
    @State private var fileDone = false
    @State private var alertText: String?
    @State private var toast: String?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // 状态概览
                HuyiCard {
                    SectionTitle("安全状态")
                    InfoRow(label: "风险应用", value: "\(threats.count) 个（点击下方扫描检测）")
                    InfoRow(label: "检测方式", value: "点击扫描按钮后执行检测")
                }

                // 病毒查杀
                HuyiCard {
                    SectionTitle("病毒查杀（系统级检测）")
                    Text("病毒库版本：\(SecurityService.virusDbVersion)（iOS 系统级安全机制）")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Button {
                        toast = "正在扫描系统安全状态…"
                        scanning = true
                        DispatchQueue.global().async {
                            let r = SecurityService.systemScan()
                            DispatchQueue.main.async {
                                threats = r
                                scanning = false
                                scanDone = true
                                toast = "扫描完成，发现 \(r.count) 个风险项"
                                AppStore.shared.addLog("安全扫描完成：\(r.count) 项")
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if scanning {
                                ProgressView().padding(.trailing, 8)
                            }
                            Text(scanning ? "扫描中…" : "立即重新扫描")
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue))
                    }
                    .buttonStyle(.plain)
                    .disabled(scanning)

                    if scanDone {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("发现 \(threats.count) 个风险项")
                                .font(.system(size: 14, weight: .medium))
                            ForEach(threats) { t in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(t.label).font(.system(size: 14))
                                    Text("\(t.pkg) · \(t.risk)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            if threats.isEmpty {
                                Text("未发现已知风险，设备状态良好")
                                    .font(.system(size: 14))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                // 扫描方式（离线可用）
                HuyiCard {
                    SectionTitle("扫描方式（离线可用）")
                    Text("系统级检测：越狱/篡改痕迹 + 设备保护状态 + 敏感权限审计（真实系统数据）\n本地离线扫描：遍历沙盒内可疑文件特征（无需联网）")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    HStack(spacing: 12) {
                        Button {
                            toast = "系统级检测开始…"
                            fileScanning = true; fileDone = true
                            DispatchQueue.global().async {
                                let r = SecurityService.systemScan()
                                DispatchQueue.main.async {
                                    threats = r; scanDone = true
                                    fileScanning = false
                                    toast = "系统级检测完成，发现 \(r.count) 项"
                                    AppStore.shared.addLog("系统级检测完成：\(r.count) 项")
                                }
                            }
                        } label: {
                            Text(fileScanning ? "检测中…" : "系统级检测")
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue))
                        }
                        .buttonStyle(.plain)
                        .disabled(fileScanning)

                        Button {
                            toast = "本地离线扫描开始…"
                            fileScanning = true; fileDone = true
                            DispatchQueue.global().async {
                                let r = SecurityService.scanLocalFiles()
                                DispatchQueue.main.async {
                                    fileThreats = r
                                    fileScanning = false
                                    toast = "离线扫描完成，发现 \(r.count) 项可疑文件"
                                    AppStore.shared.addLog("本地离线扫描完成：\(r.count) 项")
                                }
                            }
                        } label: {
                            Text(fileScanning ? "扫描中…" : "本地离线扫描")
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color.green))
                        }
                        .buttonStyle(.plain)
                        .disabled(fileScanning)
                    }

                    if fileDone && !fileThreats.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("离线扫描发现 \(fileThreats.count) 项可疑文件：")
                                .font(.system(size: 13, weight: .medium))
                            ForEach(fileThreats) { t in
                                Text("• \(t.label) — \(t.risk)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 6)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("安全")
        .overlay(alignment: .top) {
            if let t = toast {
                Text(t)
                    .font(.system(size: 13))
                    .padding(.horizontal, 16).padding(.vertical, 8)
                    .background(Capsule().fill(Color(.systemGray5)))
                    .padding(.top, 8)
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { self.toast = nil }
                        }
                    }
            }
        }
    }
}
