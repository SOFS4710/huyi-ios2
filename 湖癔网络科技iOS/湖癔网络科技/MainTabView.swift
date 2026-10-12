import SwiftUI

/// 主框架：底部 5 Tab（首页/硬件/控制/安全/设置）+ 附加页 NavigationStack
struct MainTabView: View {
    enum Tab { case home, hardware, control, security, settings }
    @State private var tab: Tab = .home
    @State private var path: [String] = []

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                switch tab {
                case .home:
                    HomeView { key in path.append(key) }
                case .hardware:
                    HardwareView()
                case .control:
                    ControlView()
                case .security:
                    SecurityView { path.append("network") }
                case .settings:
                    SettingsView(onOpenLogs: { path.append("logs") },
                                 onOpenScan: { path.append("scan") })
                }
            }
            .navigationDestination(for: String.self) { key in
                switch key {
                case "network": NetworkView()
                case "calendar": CalendarView()
                case "lifetimer": LifeTimerView()
                case "note": NoteView()
                case "tools": ToolsView()
                case "logs": LogsView()
                case "scan": ScanView()
                default: Text("页面不存在")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            // 底部导航栏（内容自动避让，不遮挡）
            HStack {
                tabButton(.home, "首页", "house.fill", "house")
                tabButton(.hardware, "硬件", "memorychip.fill", "memorychip")
                tabButton(.control, "控制", "gearshape.fill", "gearshape")
                tabButton(.security, "安全", "shield.fill", "shield")
                tabButton(.settings, "设置", "person.fill", "person")
            }
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) { Divider() }
        }
    }

    private func tabButton(_ t: Tab, _ label: String, _ on: String, _ off: String) -> some View {
        Button {
            tab = t
            path = []
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab == t ? on : off)
                    .font(.system(size: 20))
                Text(label)
                    .font(.system(size: 11))
            }
            .foregroundColor(tab == t ? .blue : .secondary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
