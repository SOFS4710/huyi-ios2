import SwiftUI

/// 硬件页（1:1 还原安卓版单页连滚：概览→设备→系统→芯片→卫星→屏幕→相机→网络→存储→电池→传感器→温度）
struct HardwareView: View {
    @State private var publicIp = "获取中…"
    @State private var batteryLevel = 0
    @State private var batteryState = "未知"
    @State private var thermalText = "正常"
    @State private var now = Date()

    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                overviewSection
                deviceSection
                systemSection
                chipSection
                gpsSection
                screenSection
                cameraSection
                networkSection
                storageSection
                batterySection
                sensorSection
                thermalSection
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("硬件")
        .onAppear {
            HardwareService.publicIP { publicIp = $0 }
            refreshBattery()
            thermalText = HardwareService.thermalStateText
        }
        .onReceive(timer) { _ in
            now = Date()
            refreshBattery()
            thermalText = HardwareService.thermalStateText
        }
    }

    private func refreshBattery() {
        let b = HardwareService.battery()
        batteryLevel = b.level
        batteryState = b.stateText
    }

    private func fmt(_ bytes: UInt64) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    private func uptimeText() -> String {
        let s = Int(HardwareService.uptimeSeconds)
        let d = s / 86400, h = (s % 86400) / 3600, m = (s % 3600) / 60
        return "\(d) 天 \(h) 小时 \(m) 分钟"
    }

    // ===== 概览 =====
    private var overviewSection: some View {
        HuyiCard {
            SectionTitle("概览")
            InfoRow(label: "设备名称", value: HardwareService.deviceName)
            InfoRow(label: "设备型号", value: HardwareService.deviceModelName)
            InfoRow(label: "系统版本", value: "iOS \(HardwareService.systemVersion)")
            InfoRow(label: "屏幕分辨率", value: HardwareService.screenRes)
            InfoRow(label: "总内存", value: fmt(HardwareService.totalMemory))
            InfoRow(label: "总存储", value: fmt(HardwareService.storage().total))
            InfoRow(label: "电池电量", value: "\(batteryLevel)%（\(batteryState)）")
            InfoRow(label: "CPU 核心数", value: "\(HardwareService.cpuCoreCount) 核")
            InfoRow(label: "传感器", value: "\(HardwareService.sensorCount) 个")
            InfoRow(label: "公网 IP", value: publicIp)
        }
    }

    // ===== 设备标识 =====
    private var deviceSection: some View {
        HuyiCard {
            SectionTitle("设备标识")
            InfoRow(label: "设备 ID", value: HardwareService.deviceIdentifier)
            InfoRow(label: "硬件序列号", value: HardwareService.serialNumber)
            InfoRow(label: "设备指纹", value: HardwareService.deviceFingerprint)
        }
    }

    // ===== 系统 =====
    private var systemSection: some View {
        HuyiCard {
            SectionTitle("系统")
            InfoRow(label: "已开机时长", value: uptimeText())
            InfoRow(label: "系统版本", value: "iOS \(HardwareService.systemVersion)")
            InfoRow(label: "内核架构", value: HardwareService.cpuArch)
            InfoRow(label: "设备名称", value: HardwareService.deviceName)
        }
    }

    // ===== 芯片 =====
    private var chipSection: some View {
        HuyiCard {
            SectionTitle("芯片")
            InfoRow(label: "芯片型号", value: HardwareService.chipModel)
            InfoRow(label: "CPU 核心数", value: "\(HardwareService.cpuCoreCount) 核")
            InfoRow(label: "架构", value: HardwareService.cpuArch)
            InfoRow(label: "机型代号", value: HardwareService.machineCode)
        }
    }

    // ===== 卫星 / GPS（用户要求：默认都支持，只写两行） =====
    private var gpsSection: some View {
        HuyiCard {
            SectionTitle("卫星定位")
            InfoRow(label: "支持卫星定位", value: HardwareService.gpsSupported ? "支持" : "未知")
            InfoRow(label: "支持 GPS", value: HardwareService.gpsSupported ? "支持" : "未知")
        }
    }

    // ===== 屏幕 =====
    private var screenSection: some View {
        HuyiCard {
            SectionTitle("屏幕")
            InfoRow(label: "分辨率", value: HardwareService.screenRes)
            InfoRow(label: "尺寸", value: HardwareService.screenSize)
            InfoRow(label: "刷新率", value: HardwareService.refreshRate)
            InfoRow(label: "缩放倍率", value: "@\(Int(UIScreen.main.scale))x")
        }
    }

    // ===== 相机 =====
    private var cameraSection: some View {
        HuyiCard {
            SectionTitle("相机")
            ForEach(HardwareService.cameras(), id: \.pos) { c in
                InfoRow(label: c.pos, value: c.mega)
            }
        }
    }

    // ===== 网络（已删除 WiFi 标准/网络类型行，与安卓版一致） =====
    private var networkSection: some View {
        HuyiCard {
            SectionTitle("网络")
            InfoRow(label: "Wi-Fi 状态", value: HardwareService.currentSSID == "未连接" ? "未连接" : "已连接")
            InfoRow(label: "SSID", value: HardwareService.currentSSID)
            InfoRow(label: "信号强度", value: HardwareService.wifiSignal)
            InfoRow(label: "连接速率", value: HardwareService.wifiRate)
            InfoRow(label: "IP 地址", value: HardwareService.localIP)
            InfoRow(label: "网关", value: HardwareService.gateway)
            InfoRow(label: "DNS", value: HardwareService.dnsServers.isEmpty ? "未知" : HardwareService.dnsServers.joined(separator: ", "))
            InfoRow(label: "运营商", value: HardwareService.carrierInfo().name)
            InfoRow(label: "SIM 状态", value: HardwareService.carrierInfo().name == "未检测到 SIM 卡" ? "未检测到 SIM 卡" : "正常")
            InfoRow(label: "蓝牙 MAC", value: HardwareService.bluetoothMac)
        }
    }

    // ===== 存储 =====
    private var storageSection: some View {
        HuyiCard {
            SectionTitle("存储")
            let s = HardwareService.storage()
            InfoRow(label: "总容量", value: fmt(s.total))
            InfoRow(label: "可用空间", value: fmt(s.free))
            InfoRow(label: "已使用", value: fmt(s.total > s.free ? s.total - s.free : 0))
        }
    }

    // ===== 电池（实时；iOS 无法读取的显示"未知"） =====
    private var batterySection: some View {
        HuyiCard {
            SectionTitle("电池信息（实时）")
            InfoRow(label: "电量", value: "\(batteryLevel)%")
            InfoRow(label: "充电状态", value: batteryState)
            InfoRow(label: "电流", value: HardwareService.batteryCurrent)
            InfoRow(label: "电压", value: HardwareService.batteryVoltage)
            InfoRow(label: "温度", value: HardwareService.batteryTempC.map { AppStore.shared.tempText(celsius: $0) } ?? "iOS 暂不开放")
            InfoRow(label: "健康状态", value: HardwareService.batteryHealth)
            InfoRow(label: "技术类型", value: HardwareService.batteryTech)
            InfoRow(label: "设计容量", value: HardwareService.batteryDesignCapacity)
            InfoRow(label: "循环次数", value: HardwareService.batteryCycles)
        }
    }

    // ===== 传感器 =====
    private var sensorSection: some View {
        HuyiCard {
            SectionTitle("传感器列表（\(HardwareService.sensorCount) 个）")
            InfoRow(label: "加速度计", value: HardwareService.hasAccelerometer ? "支持" : "未知")
            InfoRow(label: "陀螺仪", value: HardwareService.hasGyro ? "支持" : "未知")
            InfoRow(label: "磁力计", value: HardwareService.hasMagnetometer ? "支持" : "未知")
            InfoRow(label: "气压计", value: HardwareService.hasBarometer ? "支持" : "未知")
        }
    }

    // ===== 温度 =====
    private var thermalSection: some View {
        HuyiCard {
            SectionTitle("温度状态")
            InfoRow(label: "CPU 热状态", value: thermalText)
            InfoRow(label: "温度单位", value: AppStore.shared.tempUnit == "C" ? "摄氏度（℃）" : "华氏度（℉）")
        }
    }
}
