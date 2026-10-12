import SwiftUI
import MediaPlayer
import AVFoundation

/// 控制页（1:1 还原安卓 ControlPage：媒体音量/屏幕亮度/手电筒/系统设置快捷入口）
struct ControlView: View {
    @State private var brightness = Double(UIScreen.main.brightness)
    @State private var torchOn = false
    @State private var volume: Float = 0.5

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // 媒体音量（系统音量由系统控制，这里展示实时音量）
                HuyiCard {
                    SectionTitle("媒体音量")
                    HStack {
                        Image(systemName: "speaker.fill")
                        VolumeSlider(value: $volume)
                        Image(systemName: "speaker.wave.3.fill")
                    }
                    .padding(.vertical, 8)
                    Text("音量由 iOS 系统控制，拖动下方滑块调整（带音量 HUD）")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }

                // 屏幕亮度
                HuyiCard {
                    SectionTitle("屏幕亮度")
                    HStack {
                        Image(systemName: "sun.min.fill")
                        Slider(value: $brightness, in: 0.1...1.0) { _ in
                            UIScreen.main.brightness = brightness
                        }
                        Image(systemName: "sun.max.fill")
                    }
                    .padding(.vertical, 8)
                }

                // 手电筒
                HuyiCard {
                    SectionTitle("手电筒")
                    Toggle(isOn: $torchOn) {
                        Label(torchOn ? "手电筒已开启" : "手电筒已关闭",
                              systemImage: "flashlight.on.fill")
                            .foregroundColor(torchOn ? .orange : .primary)
                    }
                    .onChange(of: torchOn) { _, on in toggleTorch(on) }
                }

                // 系统设置快捷入口
                HuyiCard {
                    SectionTitle("系统设置快捷入口")
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Label("打开 iOS 系统设置", systemImage: "gearshape")
                                .foregroundColor(.blue)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("控制")
    }

    private func toggleTorch(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            torchOn = false
        }
    }
}

/// 系统音量滑条（MPVolumeView 包装，真实控制系统音量）
struct VolumeSlider: UIViewRepresentable {
    @Binding var value: Float

    func makeUIView(context: Context) -> MPVolumeView {
        let v = MPVolumeView(frame: .zero)
        v.showsRouteButton = false
        v.setVolumeThumbImage(UIImage(systemName: "circle.fill")?.withTintColor(.blue, renderingMode: .alwaysTemplate), for: .normal)
        return v
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {
        // MPVolumeView 自带系统音量控制，无需手动同步
    }
}
