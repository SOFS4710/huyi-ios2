import SwiftUI

/// 设置页（1:1 还原：个人信息/账号登录/温度/扫码绑定+同步间隔/外观/日志中心/关于）
struct SettingsView: View {
    let onOpenLogs: () -> Void
    let onOpenScan: () -> Void
    @State private var showLogin = false
    @State private var role = AppStore.shared.role
    @State private var tempUnit = AppStore.shared.tempUnit
    @State private var dark = AppStore.shared.darkMode
    @State private var interval = AppStore.shared.syncInterval
    @State private var toast: String?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // 个人信息
                HuyiCard {
                    SectionTitle("个人信息")
                    InfoRow(label: "昵称", value: AppStore.shared.nick)
                    InfoRow(label: "个性签名", value: AppStore.shared.sign.isEmpty ? "未设置" : AppStore.shared.sign)
                    InfoRow(label: "出生日期", value: AppStore.shared.birth.isEmpty ? "未设置" : AppStore.shared.birth)
                }

                // 账号登录
                HuyiCard {
                    SectionTitle("账号登录")
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("当前身份：\(role)")
                                .font(.system(size: 15, weight: .medium))
                            Text("登录仅用于展示身份，不影响同步。")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if role == "访客" {
                            Button("登录") { showLogin = true }
                                .buttonStyle(.borderedProminent)
                        } else {
                            Button("退出") {
                                AppStore.shared.role = "访客"
                                role = "访客"
                                AppStore.shared.addLog("退出登录")
                                toast = "已退出登录"
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                // 温度（℃/℉ 切换，硬件页温度跟随）
                HuyiCard {
                    SectionTitle("温度")
                    HStack {
                        Text("温度单位").font(.system(size: 15))
                        Spacer()
                        Picker("", selection: $tempUnit) {
                            Text("℃ 摄氏度").tag("C")
                            Text("℉ 华氏度").tag("F")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 190)
                    }
                    Text("切换后，硬件页检测到的温度会同步改变单位。")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .onChange(of: tempUnit) { _, v in
                            AppStore.shared.tempUnit = v
                            AppStore.shared.addLog("温度单位切换为 \(v == "C" ? "摄氏度" : "华氏度")")
                        }
                }

                // 扫码绑定 / 电脑同步 + 自动同步间隔
                HuyiCard {
                    Button(action: onOpenScan) {
                        HStack(spacing: 12) {
                            Image(systemName: "desktopcomputer")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("扫码绑定 / 电脑同步").font(.system(size: 15))
                                Text("手机扫码绑定电脑，同步笔记与个人资料")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.vertical, 10)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("自动同步间隔").font(.system(size: 15))
                            Text("绑定电脑后每隔多久自动同步一次")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Picker("", selection: $interval) {
                            Text("30 秒").tag(30)
                            Text("60 秒").tag(60)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 140)
                    }
                    .onChange(of: interval) { _, v in
                        AppStore.shared.syncInterval = v
                        AppStore.shared.addLog("自动同步间隔设为 \(v) 秒")
                    }
                }

                // 外观
                HuyiCard {
                    SectionTitle("外观")
                    Toggle(isOn: $dark) {
                        Text("深色模式").font(.system(size: 15))
                    }
                    .onChange(of: dark) { _, v in
                        AppStore.shared.darkMode = v
                        AppStore.shared.addLog(v ? "切换深色模式" : "切换浅色模式")
                    }
                }

                // 日志中心
                HuyiCard {
                    Button(action: onOpenLogs) {
                        HStack {
                            Label("日志中心", systemImage: "doc.text")
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // 关于
                HuyiCard {
                    SectionTitle("关于")
                    InfoRow(label: "应用名称", value: "湖癔网络科技")
                    InfoRow(label: "版本", value: "V2.19")
                    InfoRow(label: "口号", value: "实在科技 · 革根创业")
                    InfoRow(label: "平台", value: "iOS")
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("设置")
        .sheet(isPresented: $showLogin) { loginSheet }
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

    private var loginSheet: some View {
        LoginSheet { acc in
            AppStore.shared.role = acc.role
            role = acc.role
            AppStore.shared.addLog("登录成功：\(acc.role)")
            showLogin = false
            toast = "已登录：\(acc.role)"
        } onCancel: {
            showLogin = false
        }
    }
}

/// 登录弹窗（账号密码与安卓版口径一致；密码不回显）
struct LoginSheet: View {
    let onSuccess: (LoginAccount) -> Void
    let onCancel: () -> Void
    @State private var user = ""
    @State private var pass = ""
    @State private var err: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("账号登录").font(.headline)
            Text("登录仅用于展示身份，密码不公开")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            TextField("用户名", text: $user)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            SecureField("密码", text: $pass)
                .textFieldStyle(.roundedBorder)
            if let err {
                Text(err).font(.system(size: 12)).foregroundColor(.red)
            }
            Button("登录") {
                if let acc = loginAccounts.first(where: { $0.user == user && $0.pass == pass }) {
                    onSuccess(acc)
                } else {
                    err = "用户名或密码错误"
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            Button("取消", action: onCancel)
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
        }
        .padding(24)
        .presentationDetents([.height(300)])
    }
}
