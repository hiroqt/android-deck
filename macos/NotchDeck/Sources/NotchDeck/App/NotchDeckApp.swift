import AppKit

@main
enum NotchDeckMain {
    private static var appDelegate: AppDelegate?

    static func main() {
        if CommandLine.arguments.contains("--version") || CommandLine.arguments.contains("-v") {
            print("NotchDeck 1.0.0 (macOS Liquid Glass Notch Stream Deck)")
            return
        }
        if CommandLine.arguments.contains("--help") || CommandLine.arguments.contains("-h") {
            print("""
            NotchDeck - Liquid Glass Notch Stream Deck for macOS

            USAGE:
              NotchDeck [options]

            OPTIONS:
              -v, --version    Show version information and exit
              -h, --help       Show help information and exit
            """)
            return
        }

        let app = NSApplication.shared
        let delegate = AppDelegate()
        appDelegate = delegate
        app.delegate = delegate
        app.run()
    }
}
