import SwiftUI
import AppKit

public enum DownloadTargetMode: String, CaseIterable, Identifiable {
    case autoPortal = "Auto-Download"
    case directApk = "Direct APK"
    case portalPage = "Portal Page"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .autoPortal:
            return "Auto-Download (Recommended)"
        case .directApk:
            return "Direct APK"
        case .portalPage:
            return "Portal Page"
        }
    }
}

public struct QRCodeCardView: View {
    @ObservedObject var phoneDeckService = PhoneDeckService.shared
    @State private var targetMode: DownloadTargetMode = .autoPortal
    @State private var copied: Bool = false
    @State private var isEnlarged: Bool = false

    private var localIP: String {
        NetworkHelper.localIPAddress
    }

    public init(phoneDeckService: PhoneDeckService = .shared) {
        self.phoneDeckService = phoneDeckService
    }

    public var targetURL: String {
        switch targetMode {
        case .autoPortal:
            return "http://\(localIP):8080/?auto=1"
        case .directApk:
            return "http://\(localIP):8080/MacDeck.apk"
        case .portalPage:
            return "http://\(localIP):8080"
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Main horizontal split: QR Code on Left, Controls & Info on Right
            HStack(alignment: .top, spacing: 16) {
                // QR Code tile with high contrast quiet-zone white container
                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.18), radius: 6, x: 0, y: 3)

                        if let qrImage = QRCodeGenerator.generate(from: targetURL, size: 140) {
                            Image(nsImage: qrImage)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .padding(10)
                        } else {
                            Image(systemName: "qrcode")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(width: 136, height: 136)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isEnlarged.toggle()
                    }
                    .popover(isPresented: $isEnlarged) {
                        enlargedQRCodePopover
                    }
                    .help("Click to enlarge QR code")

                    HStack(spacing: 4) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 10))
                        Text("Scan with Camera")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.secondary)
                }

                // Details and controls beside the QR code
                VStack(alignment: .leading, spacing: 10) {
                    // Status Badge Row
                    HStack(spacing: 6) {
                        Circle()
                            .fill(phoneDeckService.isPortalOnline ? Color.green : Color.orange)
                            .frame(width: 7, height: 7)

                        Text(phoneDeckService.isPortalOnline ? "Download Gateway Active" : "Gateway Offline")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(phoneDeckService.isPortalOnline ? .green : .orange)

                        Spacer()

                        if !phoneDeckService.isPortalOnline {
                            Button("Start Server") {
                                phoneDeckService.startPortalServerIfNeeded()
                            }
                            .controlSize(.mini)
                            .buttonStyle(.borderedProminent)
                        } else {
                            Text("Latest Universal APK")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.accentColor.opacity(0.12)))
                        }
                    }

                    Text("Scan this QR code with your mobile camera or Google Lens to immediately open the download platform and install the latest APK build.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    // Target Mode Picker
                    VStack(alignment: .leading, spacing: 3) {
                        Text("QR Action:")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)

                        Picker("Target", selection: $targetMode) {
                            ForEach(DownloadTargetMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .controlSize(.small)
                    }

                    // Scannable URL display box
                    HStack {
                        Text(targetURL)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Spacer()

                        Button("Open") {
                            if let url = URL(string: targetURL) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .controlSize(.small)

                        Button(copied ? "Copied!" : "Copy") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(targetURL, forType: .string)
                            copied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copied = false
                            }
                        }
                        .controlSize(.small)
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(NSColor.textBackgroundColor)))
                }
            }

            Divider()

            // 3-Step Setup Guide
            HStack(spacing: 8) {
                StepMiniGuide(num: "1", title: "Scan QR", desc: "Point camera or Lens at code")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.5))
                Spacer()
                StepMiniGuide(num: "2", title: "Download", desc: "Saves latest MacDeck.apk")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.5))
                Spacer()
                StepMiniGuide(num: "3", title: "Install", desc: "Tap APK and connect over Wi-Fi")
            }
        }
    }

    private var enlargedQRCodePopover: some View {
        VStack(spacing: 12) {
            Text("Scan to Download MacDeck")
                .font(.system(size: 13, weight: .bold))

            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)

                if let qrImage = QRCodeGenerator.generate(from: targetURL, size: 220) {
                    Image(nsImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .padding(14)
                }
            }
            .frame(width: 220, height: 220)

            Text(targetURL)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(16)
        .frame(width: 260)
    }
}

public struct StepMiniGuide: View {
    public let num: String
    public let title: String
    public let desc: String

    public init(num: String, title: String, desc: String) {
        self.num = num
        self.title = title
        self.desc = desc
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                Text(num)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.accentColor)
            }
            .frame(width: 16, height: 16)
            .padding(.top, 1)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                Text(desc)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
    }
}
