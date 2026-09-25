import SwiftUI
import AppKit

public struct PhoneAppPickerSheet: View {
    public let slotIndex: Int
    public let currentBundleId: String
    public let onSelectApp: (InstalledAppInfo) -> Void
    public let onCancel: () -> Void

    @State private var searchText = ""
    @State private var apps: [InstalledAppInfo] = []

    public init(
        slotIndex: Int,
        currentBundleId: String = "",
        initialApps: [InstalledAppInfo] = [],
        onSelectApp: @escaping (InstalledAppInfo) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.slotIndex = slotIndex
        self.currentBundleId = currentBundleId
        self._apps = State(initialValue: initialApps)
        self.onSelectApp = onSelectApp
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Slot \(slotIndex + 1) — Phone Display")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Select a Mac application to display on your Android Stream Deck")
                        .font(.system(size: 10))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                Spacer()
                Button("Cancel", action: onCancel)
                    .buttonStyle(.plain)
                    .foregroundColor(Color.white.opacity(0.7))
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)

            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.white.opacity(0.4))
                TextField("Search Mac Applications...", text: $searchText)
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 14)

            // App List
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filteredApps) { app in
                        Button(action: {
                            onSelectApp(app)
                        }) {
                            HStack(spacing: 10) {
                                if let icon = app.icon {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 28, height: 28)
                                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                } else {
                                    Image(systemName: "app.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(app.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                    Text(app.bundleIdentifier)
                                        .font(.system(size: 9))
                                        .foregroundColor(Color.white.opacity(0.4))
                                        .lineLimit(1)
                                }

                                Spacer()

                                if currentBundleId == app.bundleIdentifier {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.cyan)
                                        .font(.system(size: 15))
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(currentBundleId == app.bundleIdentifier ? Color.cyan.opacity(0.15) : Color.white.opacity(0.04))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
            }
            .frame(height: 200)
        }
        .frame(width: 360, height: 290)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .onAppear {
            if apps.isEmpty {
                apps = AppScannerService.shared.scanInstalledApps()
            }
        }
    }

    private var filteredApps: [InstalledAppInfo] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return apps
        }
        return apps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }
}
