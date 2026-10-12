import SwiftUI

/// 首页（1:1 还原安卓 HomePage：问候卡 + 统计卡 + 功能入口网格）
struct HomeView: View {
    let onNavigate: (String) -> Void
    @State private var showEdit = false
    @State private var nick = AppStore.shared.nick
    @State private var sign = AppStore.shared.sign
    @State private var birth = AppStore.shared.birth
    @State private var avatarQq = AppStore.shared.avatarQq
    @State private var showAvatarDialog = false

    private var aliveDays: Int {
        guard !birth.isEmpty else { return 0 }
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        guard let b = f.date(from: birth) else { return 0 }
        return Int(Date().timeIntervalSince(b) / 86400)
    }

    private var dateStr: String {
        let now = Date()
        let f = DateFormatter(); f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy年M月d日 EEEE"
        return f.string(from: now)
    }

    private var columns: [GridItem] = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                // 问候卡（横跨两列）
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 14) {
                        Button { showAvatarDialog = true } label: {
                            AvatarImage(qq: avatarQq)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("你好，\(nick)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.blue)
                            Text(sign.isEmpty ? "添加一个个性签名吧！" : sign)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    Text("今天是 \(dateStr)")
                        .font(.system(size: 14))
                    Text("当前登录身份：\(AppStore.shared.role)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .cardStyle()
                .gridCellColumns(2)

                // 统计卡
                HStack {
                    StatBox(title: "已存活天数", value: birth.isEmpty ? "--" : "\(aliveDays) 天")
                    Divider().frame(height: 40)
                    StatBox(title: "今日日期", value: dateStr.components(separatedBy: " ").first ?? "")
                }
                .cardStyle()
                .gridCellColumns(2)

                // 功能入口
                ForEach(defaultEntries) { e in
                    EntryCard(item: e) { onNavigate(e.key) }
                }

                // 底部版权
                VStack(spacing: 4) {
                    Text("湖癔网络科技 V2.19")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text("实在科技 · 革根创业")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .gridCellColumns(2)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("首页")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("编辑") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) { editSheet }
        .sheet(isPresented: $showAvatarDialog) { avatarDialog }
    }

    private var editSheet: some View {
        NavigationStack {
            Form {
                Section("个人信息") {
                    TextField("昵称", text: $nick)
                    TextField("个性签名", text: $sign)
                    TextField("出生日期（yyyy-MM-dd）", text: $birth)
                }
            }
            .navigationTitle("编辑资料")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        AppStore.shared.nick = nick
                        AppStore.shared.sign = sign
                        AppStore.shared.birth = birth
                        AppStore.shared.addLog("更新个人信息")
                        showEdit = false
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showEdit = false }
                }
            }
        }
    }

    private var avatarDialog: some View {
        VStack(spacing: 16) {
            Text("更换头像").font(.headline)
            Text("输入 QQ 号码，加载 QQ 头像（与安卓版一致）")
                .font(.system(size: 13)).foregroundColor(.secondary)
            TextField("QQ 号码", text: $avatarQq)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 8)
            HStack {
                Button("取消") { showAvatarDialog = false }
                Button("确定") {
                    AppStore.shared.avatarQq = avatarQq
                    showAvatarDialog = false
                }
            }
        }
        .padding(24)
        .presentationDetents([.height(220)])
    }
}

private extension View {
    func cardStyle() -> some View {
        self.padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
    }
}
