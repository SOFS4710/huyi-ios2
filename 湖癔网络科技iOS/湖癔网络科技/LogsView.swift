import SwiftUI

/// 日志中心
struct LogsView: View {
    @State private var logs = AppStore.shared.logs

    var body: some View {
        List {
            ForEach(logs, id: \.self) { l in
                Text(l)
                    .font(.system(size: 13))
                    .padding(.vertical, 4)
            }
        }
        .navigationTitle("日志中心")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("清空") {
                    AppStore.shared.clearLogs()
                    logs = []
                }
            }
        }
    }
}

/// 节日日历（当月网格 + 常见节日）
struct CalendarView: View {
    @State private var month = Date()

    private let holidays: [String: String] = [
        "01-01": "元旦", "02-14": "情人节", "03-08": "妇女节",
        "04-05": "清明节", "05-01": "劳动节", "06-01": "儿童节",
        "10-01": "国庆节", "10-06": "中秋节", "12-25": "圣诞节"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // 月份切换
            HStack {
                Button { changeMonth(-1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(monthTitle).font(.headline)
                Spacer()
                Button { changeMonth(1) } label: { Image(systemName: "chevron.right") }
            }
            .padding(.horizontal, 20).padding(.vertical, 12)

            // 星期头
            HStack {
                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { d in
                    Text(d).font(.system(size: 12)).frame(maxWidth: .infinity).foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)

            // 日期网格
            let cells = monthCells()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(cells, id: \.self) { day in
                    if let d = day {
                        let isToday = Calendar.current.isDateInToday(d)
                        let key = Self.key(d)
                        VStack(spacing: 2) {
                            Text("\(Calendar.current.component(.day, from: d))")
                                .font(.system(size: 14, weight: isToday ? .bold : .regular))
                                .foregroundColor(isToday ? .white : .primary)
                            if let h = holidays[key] {
                                Text(h).font(.system(size: 9)).foregroundColor(.red).lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isToday ? Color.blue : Color.clear)
                        )
                    } else {
                        Color.clear.frame(maxWidth: .infinity, minHeight: 44)
                    }
                }
            }
            .padding(.horizontal, 8)

            Spacer()
        }
        .navigationTitle("节日日历")
    }

    private var monthTitle: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy年M月"
        return f.string(from: month)
    }

    private func changeMonth(_ delta: Int) {
        if let m = Calendar.current.date(byAdding: .month, value: delta, to: month) { month = m }
    }

    private func monthCells() -> [Date?] {
        var cal = Calendar.current
        cal.firstWeekday = 1
        let range = cal.range(of: .day, in: .month, for: month)!
        let first = cal.date(from: cal.dateComponents([.year, .month], from: month))!
        let lead = cal.component(.weekday, from: first) - 1
        var out: [Date?] = Array(repeating: nil, count: lead)
        for d in range {
            if let dt = cal.date(byAdding: .day, value: d - 1, to: first) { out.append(dt) }
        }
        while out.count % 7 != 0 { out.append(nil) }
        return out
    }

    private static func key(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MM-dd"; return f.string(from: d)
    }
}
