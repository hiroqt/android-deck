import SwiftUI

public struct InlineSlotEditorSheet: View {
    @Binding var slot: DeckSlot
    public let onSave: (DeckSlot) -> Void
    public let onCancel: () -> Void

    @State private var selectedActionType: ActionType
    @State private var title: String
    @State private var target: String
    @State private var iconName: String
    @State private var searchText = ""
    @State private var availableApps: [InstalledAppInfo] = []

    public init(
        slot: Binding<DeckSlot>,
        onSave: @escaping (DeckSlot) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.init(slot: slot, initialApps: [], onSave: onSave, onCancel: onCancel)
    }

    public init(
        slot: Binding<DeckSlot>,
        initialApps: [InstalledAppInfo],
        onSave: @escaping (DeckSlot) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self._slot = slot
        self.onSave = onSave
        self.onCancel = onCancel
        self._selectedActionType = State(initialValue: slot.wrappedValue.actionType)
        self._title = State(initialValue: slot.wrappedValue.title)
        self._target = State(initialValue: slot.wrappedValue.target)
        self._iconName = State(initialValue: slot.wrappedValue.iconName ?? "square.fill")
        self._availableApps = State(initialValue: initialApps)
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text("Edit Slot #\(slot.index + 1)")
                .font(.headline)
                .foregroundColor(.white)

            Picker("Action Type", selection: $selectedActionType) {
                Text("App").tag(ActionType.appLauncher)
                Text("Media").tag(ActionType.mediaControl)
                Text("System").tag(ActionType.systemToggle)
                Text("Script").tag(ActionType.shellScript)
                Text("URL").tag(ActionType.urlBookmark)
            }
            .pickerStyle(.segmented)

            // Dynamic Form based on ActionType
            VStack(alignment: .leading, spacing: 10) {
                TextField("Label", text: $title)
                    .textFieldStyle(.roundedBorder)

                if selectedActionType == .appLauncher {
                    TextField("Search installed apps...", text: $searchText)
                        .textFieldStyle(.roundedBorder)

                    List(filteredApps) { app in
                        HStack {
                            if let icon = app.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                            }
                            Text(app.name)
                            Spacer()
                            if target == app.bundleIdentifier {
                                Image(systemName: "checkmark").foregroundColor(.cyan)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            target = app.bundleIdentifier
                            if title.isEmpty || title == "New Slot" {
                                title = app.name
                            }
                        }
                    }
                    .frame(height: 120)
                } else if selectedActionType == .systemToggle {
                    Picker("System Action", selection: $target) {
                        Text("Microphone Mute").tag("micMute")
                        Text("Volume Mute").tag("volumeMute")
                        Text("Screenshot Tool").tag("screenshot")
                        Text("Lock Screen").tag("lockScreen")
                    }
                } else if selectedActionType == .mediaControl {
                    Picker("Media Command", selection: $target) {
                        Text("Play / Pause").tag("playPause")
                        Text("Next Track").tag("nextTrack")
                        Text("Previous Track").tag("previousTrack")
                    }
                } else if selectedActionType == .shellScript {
                    TextField("Shell Command (e.g. open -a Simulator)", text: $target)
                        .textFieldStyle(.roundedBorder)
                } else if selectedActionType == .urlBookmark {
                    TextField("URL (e.g. https://github.com)", text: $target)
                        .textFieldStyle(.roundedBorder)
                }
            }

            HStack {
                Button("Cancel", action: onCancel)
                Spacer()
                Button("Save") {
                    let updated = Self.buildUpdatedSlot(
                        from: slot,
                        actionType: selectedActionType,
                        title: title,
                        target: target
                    )
                    onSave(updated)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 360, height: 320)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
        .onAppear {
            if availableApps.isEmpty {
                self.availableApps = AppScannerService.shared.scanInstalledApps()
            }
        }
    }

    public static func filterApps(_ apps: [InstalledAppInfo], searchText: String) -> [InstalledAppInfo] {
        if searchText.isEmpty { return apps }
        return apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var filteredApps: [InstalledAppInfo] {
        Self.filterApps(availableApps, searchText: searchText)
    }

    public static func defaultIconFor(action: ActionType, target: String) -> String {
        switch action {
        case .appLauncher: return "app.fill"
        case .mediaControl: return "playpause.fill"
        case .systemToggle:
            if target == "micMute" { return "mic.fill" }
            if target == "volumeMute" { return "speaker.slash.fill" }
            if target == "screenshot" { return "camera.fill" }
            return "lock.fill"
        case .shellScript: return "terminal.fill"
        case .urlBookmark: return "link"
        }
    }

    private func defaultIconFor(action: ActionType, target: String) -> String {
        Self.defaultIconFor(action: action, target: target)
    }

    public static func buildUpdatedSlot(
        from original: DeckSlot,
        actionType: ActionType,
        title: String,
        target: String
    ) -> DeckSlot {
        var updated = original
        updated.actionType = actionType
        updated.title = title
        updated.target = target
        updated.iconName = defaultIconFor(action: actionType, target: target)
        return updated
    }
}
