import Messages
import SwiftUI
import UIKit

final class MessagesViewController: MSMessagesAppViewController {
    private var host: UIHostingController<MessagesRootView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        let root = MessagesRootView(requestExpanded: { [weak self] in self?.requestPresentationStyle(.expanded) })
        let host = UIHostingController(rootView: root)
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self)
        self.host = host
    }
}

private struct MessagesRootView: View {
    @AppStorage("messagesTrustedContactName") private var trustedName = ""
    @AppStorage("messagesTrustedContactPhone") private var trustedPhone = ""
    @State private var text = ""
    @State private var analysis: ScamAnalysis?
    @State private var showingHighRiskAlert = false
    @State private var showingContactEditor = false
    @Environment(\.openURL) private var openURL
    let requestExpanded: () -> Void
    private let engine = ScamDetectionEngine()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.shield.fill").font(.title).foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("ScamShield").font(.title2.bold())
                            Text("Manual check — private and on device").font(.caption).foregroundStyle(.secondary)
                        }
                    }

                    Text("Messages does not let extensions read your conversation. Copy the suspicious message, then tap Paste.")
                        .font(.callout)

                    Button { showingContactEditor = true } label: {
                        Label(trustedContactReady ? "Trusted contact: \(trustedName)" : "Add a trusted contact", systemImage: trustedContactReady ? "person.fill.checkmark" : "person.badge.plus")
                    }
                    .font(.callout.weight(.semibold))

                    TextEditor(text: $text)
                        .frame(minHeight: 105).padding(7)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.secondary.opacity(0.25)))
                        .accessibilityLabel("Suspicious message text")

                    HStack {
                        Button {
                            text = UIPasteboard.general.string ?? ""
                        } label: { Label("Paste", systemImage: "doc.on.clipboard") }
                        .buttonStyle(.bordered)

                        Button {
                            requestExpanded()
                            let result = engine.analyze(text)
                            analysis = result
                            showingHighRiskAlert = result.riskLevel == .highCaution
                        } label: { Label("Check", systemImage: "shield.fill").frame(maxWidth: .infinity) }
                        .buttonStyle(.borderedProminent)
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    if let analysis { MessageResultView(analysis: analysis) }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
        .sheet(isPresented: $showingContactEditor) {
            MessagesContactEditor(name: $trustedName, phone: $trustedPhone)
        }
        .alert("HIGH RISK OF SCAM", isPresented: $showingHighRiskAlert) {
            if trustedContactReady {
                Button("Call \(trustedName)") { callTrustedContact() }
            } else {
                Button("Add Trusted Contact") { showingContactEditor = true }
            }
            Button("Stop and Verify", role: .cancel) {}
        } message: {
            Text("This message uses strong scam tactics. Do not reply, click, pay, or share information. Call someone you trust before doing anything.")
        }
    }

    private var trustedContactReady: Bool {
        !trustedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && trustedPhone.filter(\.isNumber).count >= 7
    }

    private func callTrustedContact() {
        let digits = trustedPhone.filter { $0.isNumber || $0 == "+" }
        guard let url = URL(string: "tel:\(digits)") else { return }
        openURL(url)
    }
}

private struct MessagesContactEditor: View {
    @Binding var name: String
    @Binding var phone: String
    @Environment(\.dismiss) private var dismiss
    @State private var draftName = ""
    @State private var draftPhone = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Someone you trust") {
                    TextField("Name", text: $draftName).textContentType(.name)
                    TextField("Phone number", text: $draftPhone).textContentType(.telephoneNumber).keyboardType(.phonePad)
                }
                Section { Text("High-risk results will offer to call this person. ScamShield never places a call without your confirmation.") }
            }
            .navigationTitle("Trusted Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
                        phone = draftPhone.trimmingCharacters(in: .whitespacesAndNewlines)
                        dismiss()
                    }
                    .disabled(draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || draftPhone.filter(\.isNumber).count < 7)
                }
            }
            .onAppear { draftName = name; draftPhone = phone }
        }
    }
}

private struct MessageResultView: View {
    let analysis: ScamAnalysis
    private var color: Color { analysis.riskLevel == .highCaution ? .red : (analysis.riskLevel ==
        .caution ? .orange : .blue) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(analysis.riskLevel.title, systemImage: analysis.riskLevel.symbol).font(.headline).foregroundStyle(color)
            Text(analysis.summary).font(.callout.weight(analysis.riskLevel == .highCaution ? .bold : .regular))
            ForEach(analysis.signals) { signal in
                VStack(alignment: .leading, spacing: 2) {
                    Text(signal.title).font(.callout.bold())
                    Text("Found: \(signal.evidence.joined(separator: ", "))").font(.caption).foregroundStyle(.secondary)
                }
            }
            if analysis.riskLevel != .fewSignals {
                Label("Do not interact. Verify another way.", systemImage: "hand.raised.fill").font(.callout.bold()).foregroundStyle(color)
            }
        }
        .padding().background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.4), lineWidth: 2))
    }
}
