import SwiftUI

@main
struct ClaudoscopeApp: App {
    @State private var store = SessionStore()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        // Menu bar popover (always present)
        MenuBarExtra {
            MenuBarPopoverContent()
                .environment(store)
                .onChange(of: store.activeSecretAlert != nil) { _, hasAlert in
                    if hasAlert, let alert = store.activeSecretAlert {
                        SecretAlertController.shared.show(
                            alert: alert,
                            onView: {
                                MainWindowController.shared.open(store: store)
                                store.activeSecretAlert = nil
                            },
                            onDismiss: {
                                store.activeSecretAlert = nil
                            }
                        )
                    }
                }
        } label: {
            MenuBarIcon()
        }
        .menuBarExtraStyle(.window)
    }

    init() {
        if !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                OnboardingWindowController.shared.show()
            }
        }
    }
}

/// Menu bar icon using SF Symbols
struct MenuBarIcon: View {
    var body: some View {
        Image(systemName: "apple.terminal")
    }
}
