import PhotosUI
import SwiftUI

struct ContentView: View {
    @AppStorage("trustedContactName") private var trustedName = ""
    @AppStorage("trustedContactPhone") private var trustedPhone = ""
    @State private var message = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var analysis: ScamAnalysis?
    @State private var isReadingImage = false
    @State private var errorMessage: String?
    @State private var showingContactEditor = false
    @State private var showingSettings = false
    @State private var showingCallOffer = false
    @Environment(\.openURL) private var openURL

    private let engine = ScamDetectionEngine()
    private let recognizer = TextRecognitionService()

    private var trustedContact: TrustedContact? {
        let name = trustedName.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = trustedPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty || phone.isEmpty ? nil : TrustedContact(name: name, phone: phone)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    hero
                    safetySteps
                    inputCard
                    if let analysis {
                        ResultCard(analysis: analysis, contact: trustedContact, call: callTrustedContact)
                            .transition(.opacity)
                    }
                    privacyCard
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 30)
            }
            .background(background)
            .navigationTitle("ScamShield")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image(systemName: "shield.fill").foregroundStyle(Brand.navy).accessibilityHidden(true)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingContactEditor = true } label: {
                        Image(systemName: trustedContact == nil ? "person.crop.circle.badge.plus" : "person.crop.circle.badge.checkmark")
                    }
                    .accessibilityLabel(trustedContact == nil ? "Add trusted contact" : "Edit trusted contact")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingSettings = true } label: { Image(systemName: "gearshape.fill") }
                        .accessibilityLabel("Settings")
                }
            }
        }
        .tint(Brand.navy)
        .sheet(isPresented: $showingContactEditor) {
            TrustedContactEditor(name: $trustedName, phone: $trustedPhone)
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .alert("HIGH RISK OF SCAM", isPresented: $showingCallOffer) {
            Button("Call Now") { callTrustedContact() }
            Button("Not Now", role: .cancel) {}
        } message: {
            Text("Stop. Do not reply or click anything. Call \(trustedContact?.name ?? "your trusted contact") now for a second opinion.")
        }
        .alert("Couldn’t read screenshot", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: { Text(errorMessage ?? "Unknown error") }
    }

    private var background: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.92, green: 0.97, blue: 1), Color(.systemGroupedBackground)], startPoint: .topLeading, endPoint: .center).ignoresSafeArea()
            Circle().fill(Brand.green.opacity(0.07)).frame(width: 260).blur(radius: 2).offset(x: 150, y: -250)
            Circle().fill(Brand.navy.opacity(0.06)).frame(width: 190).offset(x: -160, y: 120)
        }
    }

    private var hero: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().stroke(Brand.green.opacity(0.18), lineWidth: 8).frame(width: 96, height: 96)
                Circle().fill(Brand.navy.gradient).frame(width: 78, height: 78).shadow(color: Brand.navy.opacity(0.25), radius: 14, y: 7)
                Image(systemName: "checkmark.shield.fill").font(.system(size: 39)).foregroundStyle(.white)
            }
            Text("Check before you trust").font(.largeTitle.bold()).multilineTextAlignment(.center)
            Text("Paste a message or scan a screenshot. Your private, on-device check explains exactly what looks suspicious.")
                .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
            if let contact = trustedContact {
                Label("\(contact.name) is ready as your trusted contact", systemImage: "person.fill.checkmark")
                    .font(.footnote.weight(.semibold)).foregroundStyle(Brand.green)
            } else {
                Button("Add a trusted contact") { showingContactEditor = true }
                    .font(.footnote.weight(.semibold))
            }
        }
        .padding(.top, 18)
    }

    private var safetySteps: some View {
        HStack(spacing: 8) {
            MiniStep(icon: "doc.on.clipboard.fill", title: "Paste", number: "1")
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
            MiniStep(icon: "shield.lefthalf.filled", title: "Check", number: "2")
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
            MiniStep(icon: "person.2.fill", title: "Verify", number: "3")
        }
        .padding(12).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.8)))
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Message to check", systemImage: "text.bubble.fill").font(.headline)
                Spacer()
                if !message.isEmpty {
                    Button("Clear") { message = ""; analysis = nil }.font(.callout)
                }
            }
            ZStack(alignment: .topLeading) {
                if message.isEmpty {
                    Text("Paste the full message here…").foregroundStyle(.tertiary).padding(.horizontal, 13).padding(.vertical, 16).allowsHitTesting(false)
                }
                TextEditor(text: $message)
                    .scrollContentBackground(.hidden).frame(minHeight: 145).padding(8)
                    .accessibilityLabel("Message to check")
            }
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Brand.navy.opacity(0.14)))

            PhotosPicker(selection: $photoItem, matching: .images) {
                Label(isReadingImage ? "Reading screenshot…" : "Scan a Screenshot", systemImage: "viewfinder")
                    .frame(maxWidth: .infinity, minHeight: 46)
            }
            .buttonStyle(.bordered).disabled(isReadingImage)
            .onChange(of: photoItem) { _, item in guard let item else { return }; Task { await readScreenshot(item) } }

            if isReadingImage {
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small)
                    Text("Apple Vision is reading the screenshot on this device…").font(.caption).foregroundStyle(.secondary)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Button(action: analyze) {
                Label("Check This Message", systemImage: "shield.fill")
                    .frame(maxWidth: .infinity, minHeight: 50).font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isReadingImage)

            Button("Load a clearly labeled scam example") {
                message = "URGENT: This is the bank fraud department. Your account will be locked. Send the verification code now and don't tell anyone. Click http://account-check.example/login"
                analyze()
            }
            .font(.footnote).frame(maxWidth: .infinity)
        }
        .cardStyle()
        .animation(.easeInOut(duration: 0.25), value: isReadingImage)
    }

    private var privacyCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.shield.fill").font(.title2).foregroundStyle(Brand.green)
            VStack(alignment: .leading, spacing: 3) {
                Text("Private by design").font(.headline)
                Text("Analysis and screenshot reading happen on this device. ScamShield does not upload or save your messages.").font(.footnote).foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }

    private func analyze() {
        let result = engine.analyze(message)
        withAnimation(.easeOut(duration: 0.2)) { analysis = result }
        if result.shouldOfferTrustedContact && trustedContact != nil { showingCallOffer = true }
    }

    private func callTrustedContact() {
        guard let url = trustedContact?.callURL else { return }
        openURL(url)
    }

    @MainActor private func readScreenshot(_ item: PhotosPickerItem) async {
        isReadingImage = true
        defer { isReadingImage = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { throw TextRecognitionError.invalidImage }
            message = try await recognizer.recognizeText(in: data)
            analyze()
        } catch { errorMessage = error.localizedDescription }
    }
}

private struct MiniStep: View {
    let icon: String
    let title: String
    let number: String
    var body: some View {
        VStack(spacing: 5) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: icon).font(.title3).foregroundStyle(Brand.navy).frame(width: 34, height: 28)
                Text(number).font(.system(size: 8, weight: .bold)).foregroundStyle(.white).frame(width: 14, height: 14).background(Brand.green, in: Circle()).offset(x: 4, y: -4)
            }
            Text(title).font(.caption2.bold()).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ResultCard: View {
    let analysis: ScamAnalysis
    let contact: TrustedContact?
    let call: () -> Void

    private var color: Color {
        switch analysis.riskLevel { case .fewSignals: Brand.green; case .caution: .orange; case .highCaution: Brand.red }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 13) {
                Image(systemName: analysis.riskLevel.symbol).font(.system(size: 32)).foregroundStyle(color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(analysis.riskLevel.title).font(.title2.bold()).foregroundStyle(color)
                    Text("Risk score \(analysis.score) of 10").font(.caption.weight(.semibold)).foregroundStyle(.secondary).contentTransition(.numericText())
                }
            }
            RiskMeter(score: analysis.score, color: color)
            Text(analysis.summary).font(.body.weight(analysis.riskLevel == .highCaution ? .bold : .regular))

            if !analysis.signals.isEmpty {
                Divider()
                Text("Why ScamShield flagged it").font(.headline)
                ForEach(analysis.signals) { signal in
                    HStack(alignment: .top, spacing: 11) {
                        Image(systemName: "exclamationmark.circle.fill").foregroundStyle(color).padding(.top, 2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(signal.title).font(.headline)
                            Text(signal.explanation).font(.callout)
                            Text("Found: \(signal.evidence.map { "“\($0)”" }.joined(separator: ", "))").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Divider()
            Text("What to do now").font(.headline)
            ForEach(Array(analysis.guidance.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)").font(.caption.bold()).foregroundStyle(.white).frame(width: 24, height: 24).background(color, in: Circle())
                    Text(item).font(.callout)
                }
            }
            if analysis.riskLevel != .fewSignals, let contact {
                Button(action: call) {
                    Label("Call \(contact.name)", systemImage: "phone.fill").frame(maxWidth: .infinity, minHeight: 48).font(.headline)
                }
                .buttonStyle(.borderedProminent).tint(Brand.green)
            }
        }
        .cardStyle(border: color)
        .accessibilityElement(children: .contain)
    }
}

private struct RiskMeter: View {
    let score: Int
    let color: Color
    @State private var displayedScore = 0
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.secondary.opacity(0.12))
                Capsule().fill(color.gradient).frame(width: proxy.size.width * CGFloat(displayedScore) / 10)
            }
        }
        .frame(height: 8)
        .onAppear { withAnimation(.easeOut(duration: 0.45)) { displayedScore = score } }
    }
}

private struct TrustedContactEditor: View {
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
                Section { Text("When a message shows a high-risk scam pattern, ScamShield will offer to call this person. The call only starts after you confirm.") }
                Section {
                    Button("Remove Trusted Contact", role: .destructive) { name = ""; phone = ""; dismiss() }
                        .disabled(name.isEmpty && phone.isEmpty)
                }
            }
            .navigationTitle("Trusted Contact").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { name = draftName.trimmingCharacters(in: .whitespacesAndNewlines); phone = draftPhone.trimmingCharacters(in: .whitespacesAndNewlines); dismiss() }.disabled(draftName.trimmingCharacters(in: .whitespaces).isEmpty || draftPhone.filter(\.isNumber).count < 7) }
            }
            .onAppear { draftName = name; draftPhone = phone }
        }
    }
}

enum Brand {
    static let navy = Color(red: 0.05, green: 0.20, blue: 0.38)
    static let green = Color(red: 0.05, green: 0.48, blue: 0.34)
    static let red = Color(red: 0.78, green: 0.08, blue: 0.11)
}

private extension View {
    func cardStyle(border: Color? = nil) -> some View {
        padding(18).background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke((border ?? .clear).opacity(0.35), lineWidth: 2))
            .shadow(color: Brand.navy.opacity(0.08), radius: 14, y: 6)
    }
}

#Preview { ContentView() }
