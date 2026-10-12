import SwiftUI

/// 人生计时器
struct LifeTimerView: View {
    @State private var birth = AppStore.shared.birth
    @State private var showEdit = false

    private var aliveDays: Int {
        guard !birth.isEmpty else { return 0 }
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        guard let b = f.date(from: birth) else { return 0 }
        return Int(Date().timeIntervalSince(b) / 86400)
    }

    private var progress: Double {
        // 以平均寿命 75 岁为基准
        min(Double(aliveDays) / (75.0 * 365.0), 1.0)
    }

    private var remainDays: Int {
        max(Int(75.0 * 365.0) - aliveDays, 0)
    }

    var body: some View {
        VStack(spacing: 24) {
            if birth.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "birthday.cake").font(.system(size: 44)).foregroundColor(.pink)
                    Text("未设置出生日期").font(.headline)
                    Button("设置出生日期") { showEdit = true }
                        .buttonStyle(.borderedProminent)
                }
                .padding(.top, 60)
            } else {
                VStack(spacing: 8) {
                    Text("\(aliveDays) 天")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.pink)
                    Text("已存活天数").font(.system(size: 14)).foregroundColor(.secondary)
                }
                .padding(.top, 40)

                VStack(alignment: .leading, spacing: 8) {
                    ProgressView(value: progress)
                        .tint(.pink)
                        .scaleEffect(x: 1, y: 2.5)
                    Text(String(format: "人生进度 %.2f%%", progress * 100))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 40)

                HStack(spacing: 30) {
                    StatBox(title: "剩余（按75岁）", value: "\(remainDays) 天")
                    StatBox(title: "出生日期", value: birth)
                }
                .padding(.horizontal, 24)

                Button("修改出生日期") { showEdit = true }
                    .buttonStyle(.bordered)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("人生计时器")
        .sheet(isPresented: $showEdit) {
            VStack(spacing: 16) {
                Text("设置出生日期").font(.headline)
                TextField("yyyy-MM-dd", text: $birth)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numbersAndPunctuation)
                    .padding(.horizontal, 24)
                HStack {
                    Button("取消") { showEdit = false }
                    Button("保存") {
                        AppStore.shared.birth = birth
                        AppStore.shared.addLog("设置出生日期")
                        showEdit = false
                    }
                }
            }
            .padding(24)
            .presentationDetents([.height(220)])
        }
    }
}

/// 笔记
struct NoteView: View {
    @State private var notes = AppStore.shared.notes
    @State private var newText = ""
    @State private var editing: String?

    var body: some View {
        List {
            ForEach(notes, id: \.self) { n in
                Text(n).font(.system(size: 14))
                    .swipeActions {
                        Button(role: .destructive) {
                            delete(n)
                        } label: { Label("删除", systemImage: "trash") }
                    }
            }
        }
        .navigationTitle("笔记")
        .safeAreaInset(edge: .bottom) {
            HStack {
                TextField("写点什么…", text: $newText)
                    .textFieldStyle(.roundedBorder)
                Button("保存") { add() }
                    .buttonStyle(.borderedProminent)
                    .disabled(newText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(12)
            .background(.ultraThinMaterial)
        }
    }

    private func add() {
        let t = newText.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        notes.insert(t, at: 0)
        AppStore.shared.notes = notes
        newText = ""
        AppStore.shared.addLog("新增笔记")
    }

    private func delete(_ n: String) {
        notes.removeAll { $0 == n }
        AppStore.shared.notes = notes
    }
}
