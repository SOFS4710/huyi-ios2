import Foundation
import SwiftUI

// ===== 威胁项（安全页） =====
struct AppThreat: Identifiable {
    let id = UUID()
    let label: String
    let pkg: String
    let risk: String
}

// ===== 电脑信息（扫码绑定后展示） =====
struct PcInfo: Identifiable {
    let id = UUID()
    let addr: String
    let name: String
    let infoText: String
}

// ===== 温度区（thermal） =====
struct ThermalZone: Identifiable {
    let id = UUID()
    let name: String
    let tempC: Double
    var label: String { name }
}

// ===== 首页功能入口 =====
struct EntryItem: Identifiable {
    let id = UUID()
    let key: String
    let title: String
    let icon: String   // SF Symbol 名
    let tint: Color
}

// ===== 首页默认功能入口（与安卓版一致） =====
let defaultEntries: [EntryItem] = [
    EntryItem(key: "network", title: "网络信息", icon: "wifi", tint: .blue),
    EntryItem(key: "calendar", title: "节日日历", icon: "calendar", tint: .orange),
    EntryItem(key: "lifetimer", title: "人生计时器", icon: "timer", tint: .pink),
    EntryItem(key: "note", title: "笔记", icon: "note.text", tint: .green),
    EntryItem(key: "tools", title: "实用工具", icon: "wrench.and.screwdriver", tint: .purple),
    EntryItem(key: "scan", title: "扫码绑定", icon: "qrcode.viewfinder", tint: .teal)
]

// ===== 登录账号（与安卓版口径一致；仅用于展示身份，密码不回显） =====
struct LoginAccount {
    let user: String
    let pass: String
    let role: String
}
let loginAccounts: [LoginAccount] = [
    LoginAccount(user: "HUYIKEJI", pass: "LXY520", role: "创始人"),
    LoginAccount(user: "admin-huyikeji", pass: "huyikeji", role: "管理员"),
    LoginAccount(user: "employee-huyikeji", pass: "123456", role: "员工")
]

// ===== 工具列表（工具页） =====
struct ToolItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let tint: Color
}
let toolList: [ToolItem] = [
    ToolItem(title: "计算器", icon: "plus.forwardslash.minus", tint: .orange),
    ToolItem(title: "随机数生成", icon: "dice", tint: .blue),
    ToolItem(title: "MD5 计算", icon: "number", tint: .purple),
    ToolItem(title: "单位换算", icon: "arrow.left.arrow.right", tint: .green),
    ToolItem(title: "日期计算", icon: "calendar.badge.plus", tint: .red)
]
