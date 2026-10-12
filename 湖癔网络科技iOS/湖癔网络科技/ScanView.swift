import SwiftUI
import AVFoundation
import Vision

/// 扫码绑定 / 电脑同步（系统相机扫码 100% 出画面 + 手动输入 + 自动同步）
struct ScanView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var mode: Mode = .scan
    @State private var pcInfo: PcInfo?
    @State private var err: String?
    @State private var busy = false
    @State private var boundJson = AppStore.shared.pcBind
    @State private var syncText = ""
    @State private var showCamera = false

    enum Mode { case scan, manual }

    private var boundAddr: String {
        guard let data = boundJson.data(using: .utf8),
              let j = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let a = j["addr"] as? String else { return "" }
        return a
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 1. 扫描电脑端二维码（系统相机）
                HuyiCard {
                    SectionTitle("扫描电脑端二维码")
                    Text("点击下方按钮调用系统相机，拍摄电脑端弹出的绑定二维码，识别成功后自动进入确认。")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Button {
                        showCamera = true
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "camera.viewfinder")
                            Text("打开系统相机扫码")
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue))
                    }
                    .buttonStyle(.plain)
                    Text("将电脑端弹出的绑定二维码对准取景框拍摄，识别成功后自动进入确认")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }

                // 2. 手动输入连接
                HuyiCard {
                    SectionTitle("手动输入连接")
                    Picker("", selection: $mode) {
                        Text("扫码").tag(Mode.scan)
                        Text("手动输入").tag(Mode.manual)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: mode) { _, _ in }

                    if mode == .manual {
                        ManualConnect { base, code in
                            doConnect(base: base, code: code)
                        }
                    } else {
                        Text("也可点击上方按钮使用系统相机扫码")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }

                // 3. 确认绑定
                if let pc = pcInfo {
                    HuyiCard {
                        SectionTitle("确认绑定")
                        Text(pc.name).font(.system(size: 16, weight: .bold))
                        Text(pc.infoText)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        HStack(spacing: 12) {
                            Button("取消") { pcInfo = nil }
                                .buttonStyle(.bordered)
                            Button("确认绑定") {
                                let j: [String: Any] = ["addr": pc.addr, "name": pc.name, "time": Self.nowStr()]
                                let data = try? JSONSerialization.data(withJSONObject: j)
                                boundJson = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                                AppStore.shared.pcBind = boundJson
                                AppStore.shared.addLog("绑定电脑：\(pc.name)")
                                pcInfo = nil
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.top, 8)
                    }
                }

                // 4. 已绑定电脑卡片
                if boundAddr.isNotEmpty {
                    HuyiCard {
                        SectionTitle("已绑定电脑")
                        if let (name, addr, time) = parseBound() {
                            InfoRow(label: "设备名称", value: name)
                            InfoRow(label: "服务地址", value: addr)
                            InfoRow(label: "上次同步", value: time.isEmpty ? "尚未同步" : time)
                        }
                        HStack(spacing: 12) {
                            Button {
                                syncNow()
                            } label: {
                                Text(busy ? "同步中…" : "立即同步")
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue))
                            }
                            .buttonStyle(.plain)
                            .disabled(busy)

                            Button {
                                AppStore.shared.pcBind = ""
                                boundJson = ""
                                AppStore.shared.addLog("取消绑定电脑")
                            } label: {
                                Text("取消绑定")
                                    .foregroundColor(.white)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.red))
                            }
                            .buttonStyle(.plain)
                        }
                        Text("已开启自动同步：每 \(AppStore.shared.syncInterval) 秒向电脑同步一次状态（可在设置页调整间隔）。")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        if !syncText.isEmpty {
                            Text("同步状态：\(syncText)")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                        }
                    }
                }

                if let err {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("扫码绑定 / 电脑同步")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showCamera) {
            QrCameraView { text in
                showCamera = false
                if let (base, code) = PcSyncService.parseQr(text) {
                    doConnect(base: base, code: code)
                } else {
                    err = "二维码内容不是电脑连接地址"
                }
            } onCancel: {
                showCamera = false
            }
        }
        .onAppear {
            if boundAddr.isNotEmpty { startAutoSync() }
        }
    }

    // ===== 连接 =====
    private func doConnect(base: String, code: String?) {
        guard !base.isEmpty else { err = "请输入电脑地址"; return }
        busy = true; err = nil
        Task {
            let info = await PcSyncService.fetchPcInfo(base: base, code: code)
            await MainActor.run {
                busy = false
                if let info {
                    pcInfo = info
                    AppStore.shared.addLog("连接电脑成功：\(info.addr)")
                } else {
                    err = "连接失败：电脑软件未运行 / 不在同一网络 / 地址或配对码不对"
                }
            }
        }
    }

    private func syncNow() {
        busy = true
        Task {
            let r = await PcSyncService.fetchPcInfo(base: boundAddr, code: nil)
            await MainActor.run {
                busy = false
                if r != nil {
                    syncText = Self.nowStr()
                    AppStore.shared.addLog("自动同步成功")
                } else {
                    err = "同步失败：电脑端不可达"
                }
            }
        }
    }

    private func startAutoSync() {
        Task {
            while !AppStore.shared.pcBind.isEmpty {
                try? await Task.sleep(nanoseconds: UInt64(AppStore.shared.syncInterval) * 1_000_000_000)
                guard !AppStore.shared.pcBind.isEmpty else { return }
                let addr = parseBound()?.1 ?? ""
                guard !addr.isEmpty else { return }
                let r = await PcSyncService.fetchPcInfo(base: addr, code: nil)
                if r != nil { syncText = Self.nowStr() }
            }
        }
    }

    private func parseBound() -> (String, String, String)? {
        guard let data = boundJson.data(using: .utf8),
              let j = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        let name = j["name"] as? String ?? "未知电脑"
        let addr = j["addr"] as? String ?? ""
        let time = j["time"] as? String ?? ""
        return (name, addr, time)
    }

    private static func nowStr() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd HH:mm:ss"; return f.string(from: Date())
    }
}

// ===== 手动输入连接 =====
struct ManualConnect: View {
    let onConnect: (String, String?) -> Void
    @State private var ip = ""
    @State private var port = "8765"
    @State private var pairCode = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField("电脑 IP 地址", text: $ip)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numbersAndPunctuation)
                .autocorrectionDisabled()
            HStack(spacing: 10) {
                TextField("端口", text: $port)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .frame(width: 110)
                TextField("6 位配对码", text: $pairCode)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
            }
            Button {
                onConnect("http://\(ip):\(port)", pairCode.isEmpty ? nil : pairCode)
            } label: {
                Text("连接")
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }
}

// ===== 系统相机扫码（AVCaptureSession + Vision，100% 出画面） =====
struct QrCameraView: UIViewControllerRepresentable {
    let onResult: (String) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> QrCameraController {
        let c = QrCameraController()
        c.onResult = onResult
        c.onCancel = onCancel
        return c
    }
    func updateUIViewController(_ uiViewController: QrCameraController, context: Context) {}
}

final class QrCameraController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onResult: ((String) -> Void)?
    var onCancel: (() -> Void)?
    private var session: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var found = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    private func setupCamera() {
        let s = AVCaptureSession()
        s.sessionPreset = .high
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              s.canAddInput(input) else {
            showError("无法访问相机")
            return
        }
        s.addInput(input)
        let output = AVCaptureMetadataOutput()
        if s.canAddOutput(output) {
            s.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr]
        }
        let preview = AVCaptureVideoPreviewLayer(session: s)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.bounds
        view.layer.insertSublayer(preview, at: 0)
        previewLayer = preview
        session = s
        DispatchQueue.global().async { s.startRunning() }
    }

    private func setupUI() {
        // 取景框
        let box = UIView()
        box.layer.borderColor = UIColor.white.cgColor
        box.layer.borderWidth = 2
        box.layer.cornerRadius = 12
        box.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(box)
        NSLayoutConstraint.activate([
            box.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            box.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            box.widthAnchor.constraint(equalToConstant: 240),
            box.heightAnchor.constraint(equalToConstant: 240)
        ])

        // 提示文字
        let label = UILabel()
        label.text = "将电脑端弹出的绑定二维码对准取景框"
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: box.bottomAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])

        // 取消按钮
        let cancel = UIButton(type: .system)
        cancel.setTitle("取消", for: .normal)
        cancel.setTitleColor(.white, for: .normal)
        cancel.titleLabel?.font = .systemFont(ofSize: 16)
        cancel.translatesAutoresizingMaskIntoConstraints = false
        cancel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(cancel)
        NSLayoutConstraint.activate([
            cancel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cancel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 30)
        ])
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !found, let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              obj.type == .qr, let str = obj.stringValue else { return }
        found = true
        session?.stopRunning()
        onResult?(str)
    }

    @objc private func cancelTapped() {
        session?.stopRunning()
        onCancel?()
    }

    private func showError(_ msg: String) {
        let label = UILabel()
        label.text = msg
        label.textColor = .white
        label.textAlignment = .center
        label.frame = view.bounds
        view.addSubview(label)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session?.stopRunning()
    }
}

private extension String {
    var isNotEmpty: Bool { !isEmpty }
}
