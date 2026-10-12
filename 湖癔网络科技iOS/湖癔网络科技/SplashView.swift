import SwiftUI

/// 开屏页（1:1 还原安卓版 SplashScreen）
struct SplashView: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.45, blue: 0.95), Color(red: 0.05, green: 0.25, blue: 0.70)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                // 图标：网络节点
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 104, height: 104)
                    Image(systemName: "network")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)

                Text("湖癔网络科技")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(appeared ? 1 : 0.9)

                Text("让网络更简单")
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.85))

                Text("实在科技 · 革根创业")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.65))

                Spacer()

                Text("V2.19")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.bottom, 24)
            }
            .padding(.top, 60)
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) { appeared = true }
        }
    }
}
