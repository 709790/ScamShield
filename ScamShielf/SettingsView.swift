import SwiftUI

struct SettingsView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true
    @AppStorage("trustedContactName") private var trustedName = ""
    @AppStorage("trustedContactPhone") private var trustedPhone = ""
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingLogout = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "checkmark.shield.fill").font(.system(size: 36)).foregroundStyle(Brand.navy)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("ScamShield").font(.title3.bold())
                            Text("Private, on-device protection").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 5)
                }

                Section("Trusted contact") {
                    LabeledContent("Name", value: trustedName.isEmpty ? "Not configured" : trustedName)
                    if !trustedPhone.isEmpty { LabeledContent("Phone", value: trustedPhone) }
                    Text("Edit your trusted contact from the person icon on the main screen.").font(.caption).foregroundStyle(.secondary)
                }

                Section("How ScamShield works") {
                    Label("Messages are analyzed on device", systemImage: "iphone.and.arrow.forward")
                    Label("Screenshots use Apple Vision OCR", systemImage: "viewfinder")
                    Label("Results explain every matched signal", systemImage: "list.bullet.rectangle")
                }

                Section {
                    Button(role: .destructive) { confirmingLogout = true } label: {
                        Label("Log Out and Redo Onboarding", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } footer: {
                    Text("ScamShield has no online account. Logging out restarts the local onboarding tutorial and keeps your trusted contact ready to review or change.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .confirmationDialog("Redo onboarding?", isPresented: $confirmingLogout, titleVisibility: .visible) {
                Button("Log Out and Restart", role: .destructive) {
                    dismiss()
                    hasCompletedOnboarding = false
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You’ll return to the welcome screens. Your trusted contact will stay filled in so you can confirm or update it.")
            }
        }
    }
}

#Preview { SettingsView() }
