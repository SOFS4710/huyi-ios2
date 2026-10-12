import SwiftUI

// ===== 通用卡片 =====
struct HuyiCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.blue.opacity(0.15), lineWidth: 1)
            )
    }
}

struct SectionTitle: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 信息行：左标题 + 右数值
struct InfoRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 110, alignment: .leading)
            Spacer(minLength: 4)
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 6)
    }
}

/// 蓝字一行（非按钮，无卡片底）——权限提示
struct PermText: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(.blue)
    }
}

/// 首页统计块
struct StatBox: View {
    let title: String
    let value: String
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.blue)
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// 首页功能入口卡
struct EntryCard: View {
    let item: EntryItem
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: item.icon)
                    .font(.system(size: 24))
                    .foregroundColor(item.tint)
                Text(item.title)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
}

/// 圆角头像（QQ 号加载网络头像，失败用占位）
struct AvatarImage: View {
    let qq: String
    var body: some View {
        if qq.isEmpty {
            ZStack {
                Circle().fill(Color.blue.opacity(0.2))
                Image(systemName: "person.fill").foregroundColor(.blue)
            }
        } else {
            AsyncImage(url: URL(string: "https://q1.qlogo.cn/g?b=qq&nk=\(qq)&s=100")) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                ZStack {
                    Circle().fill(Color.blue.opacity(0.2))
                    Image(systemName: "person.fill").foregroundColor(.blue)
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())
        }
    }
}
