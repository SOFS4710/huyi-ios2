import SwiftUI
import CryptoKit

/// 实用工具页（计算器/随机数/MD5/单位换算/日期计算）
struct ToolsView: View {
    var body: some View {
        List {
            NavigationLink(destination: CalculatorView()) {
                Label("计算器", systemImage: "plus.forwardslash.minus").foregroundColor(.orange)
            }
            NavigationLink(destination: RandomView()) {
                Label("随机数生成", systemImage: "dice").foregroundColor(.blue)
            }
            NavigationLink(destination: Md5View()) {
                Label("MD5 计算", systemImage: "number").foregroundColor(.purple)
            }
            NavigationLink(destination: UnitConvertView()) {
                Label("单位换算", systemImage: "arrow.left.arrow.right").foregroundColor(.green)
            }
            NavigationLink(destination: DateCalcView()) {
                Label("日期计算", systemImage: "calendar.badge.plus").foregroundColor(.red)
            }
        }
        .navigationTitle("实用工具")
    }
}

struct CalculatorView: View {
    @State private var expr = "0"
    @State private var result = ""

    private let buttons: [[String]] = [
        ["7", "8", "9", "÷"],
        ["4", "5", "6", "×"],
        ["1", "2", "3", "-"],
        ["C", "0", ".", "+"],
        ["="]
    ]

    var body: some View {
        VStack {
            Spacer()
            Text(expr).font(.system(size: 40, weight: .light)).frame(maxWidth: .infinity, alignment: .trailing).padding(.horizontal, 24)
            Text(result).font(.system(size: 24)).foregroundColor(.secondary).frame(maxWidth: .infinity, alignment: .trailing).padding(.horizontal, 24)
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { b in
                        Button { tap(b) } label: {
                            Text(b)
                                .font(.system(size: 26))
                                .frame(maxWidth: .infinity, maxHeight: 64)
                                .background(RoundedRectangle(cornerRadius: 14).fill(b == "=" ? Color.blue : Color(.secondarySystemGroupedBackground)))
                                .foregroundColor(b == "=" ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 4)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("计算器")
    }

    private func tap(_ b: String) {
        switch b {
        case "C": expr = "0"; result = ""
        case "=":
            var e = expr.replacingOccurrences(of: "×", with: "*").replacingOccurrences(of: "÷", with: "/")
            e = e.replacingOccurrences(of: "--", with: "+")
            let exp = NSExpression(format: e)
            if let v = exp.expressionValue(with: nil, context: nil) as? NSNumber {
                result = String(format: "%g", v.doubleValue)
            } else {
                result = "错误"
            }
        default:
            expr = expr == "0" ? b : expr + b
        }
    }
}

struct RandomView: View {
    @State private var minV = "1"
    @State private var maxV = "100"
    @State private var out = "点击生成"

    var body: some View {
        VStack(spacing: 20) {
            Text(out).font(.system(size: 48, weight: .bold)).foregroundColor(.blue).padding(.top, 60)
            HStack {
                TextField("最小", text: $minV).textFieldStyle(.roundedBorder).keyboardType(.numberPad)
                Text("—")
                TextField("最大", text: $maxV).textFieldStyle(.roundedBorder).keyboardType(.numberPad)
            }
            .padding(.horizontal, 40)
            Button {
                if let lo = Int(minV), let hi = Int(maxV), lo <= hi {
                    out = "\(Int.random(in: lo...hi))"
                } else {
                    out = "范围错误"
                }
            } label: {
                Text("生成随机数")
                    .foregroundColor(.white).padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue))
            }
            .padding(.horizontal, 40)
            Spacer()
        }
        .navigationTitle("随机数生成")
    }
}

struct Md5View: View {
    @State private var input = ""
    @State private var out = ""

    var body: some View {
        VStack(spacing: 16) {
            TextField("输入文本", text: $input)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 24).padding(.top, 30)
            Button {
                out = Insecure.MD5.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
            } label: {
                Text("计算 MD5")
                    .foregroundColor(.white).padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.purple))
            }
            .padding(.horizontal, 24)
            Text(out.isEmpty ? "结果将显示在这里" : out)
                .font(.system(size: 15, design: .monospaced))
                .foregroundColor(.secondary)
                .textSelection(.enabled)
                .padding(.horizontal, 24)
            Spacer()
        }
        .navigationTitle("MD5 计算")
    }
}

struct UnitConvertView: View {
    @State private var value = "1"
    @State private var from = "米"
    @State private var to = "千米"
    let units = ["米", "千米", "厘米", "英尺", "英寸"]

    var body: some View {
        VStack(spacing: 20) {
            TextField("数值", text: $value)
                .textFieldStyle(.roundedBorder).keyboardType(.decimalPad)
                .padding(.horizontal, 40).padding(.top, 40)
            HStack {
                Picker("", selection: $from) { ForEach(units, id: \.self) { Text($0) } }
                    .pickerStyle(.menu)
                Image(systemName: "arrow.right")
                Picker("", selection: $to) { ForEach(units, id: \.self) { Text($0) } }
                    .pickerStyle(.menu)
            }
            .padding(.horizontal, 30)
            Text("结果：\(convert())")
                .font(.system(size: 22, weight: .medium))
                .padding(.top, 20)
            Spacer()
        }
        .navigationTitle("长度换算")
    }

    private func meterValue() -> Double {
        let v = Double(value) ?? 0
        switch from {
        case "米": return v
        case "千米": return v * 1000
        case "厘米": return v / 100
        case "英尺": return v * 0.3048
        case "英寸": return v * 0.0254
        default: return v
        }
    }

    private func convert() -> String {
        let m = meterValue()
        switch to {
        case "米": return String(format: "%g", m)
        case "千米": return String(format: "%g", m / 1000)
        case "厘米": return String(format: "%g", m * 100)
        case "英尺": return String(format: "%g", m / 0.3048)
        case "英寸": return String(format: "%g", m / 0.0254)
        default: return "0"
        }
    }
}

struct DateCalcView: View {
    @State private var days = "100"
    @State private var start = Date()

    var body: some View {
        VStack(spacing: 20) {
            DatePicker("起始日期", selection: $start, displayedComponents: .date)
                .padding(.horizontal, 40).padding(.top, 40)
            HStack {
                TextField("天数", text: $days).textFieldStyle(.roundedBorder).keyboardType(.numberPad).frame(width: 120)
                Text("天后的日期")
            }
            .padding(.horizontal, 40)
            let result = Calendar.current.date(byAdding: .day, value: Int(days) ?? 0, to: start) ?? start
            Text("结果：\(DateFormatter.localizedString(from: result, dateStyle: .medium, timeStyle: .none))")
                .font(.system(size: 18, weight: .medium))
                .padding(.top, 10)
            Spacer()
        }
        .navigationTitle("日期计算")
    }
}
