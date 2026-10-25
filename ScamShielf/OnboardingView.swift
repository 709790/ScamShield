import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("trustedContactName") private var trustedName = ""
    @AppStorage("trustedContactPhone") private var trustedPhone = ""
    @State private var page = 0

    private var contactIsValid: Bool {
        !trustedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && trustedPhone.filter(\.isNumber).count >= 7
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Brand.navy, Color(red: 0.02, green: 0.39, blue: 0.48)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    OnboardingPage(icon: "checkmark.shield.fill", title: "A second opinion in seconds", text: "Paste a suspicious text or choose a screenshot. ScamShield checks it privately on your device and explains every warning sign.", badge: "1 of 3").tag(0)
                    OnboardingPage(icon: "message.fill", title: "Check inside Messages", text: "Open ScamShield from the Messages app drawer, copy the suspicious message, then tap Paste and Check. Apple does not allow extensions to read conversations automatically.", badge: "2 of 3").tag(1)
                    contactPage.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button(action: advance) {
                    Text(page == 2 ? "Finish Setup" : "Continue")
                        .font(.headline).foregroundStyle(Brand.navy).frame(maxWidth: .infinity, minHeight: 52)
                        .background(.white, in: RoundedRectangle(cornerRadius: 15))
                }
                .disabled(page == 2 && !contactIsValid)
                .opacity(page == 2 && !contactIsValid ? 0.55 : 1)
                .padding(.horizontal, 24).padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var contactPage: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle().fill(.white.opacity(0.14)).frame(width: 118, height: 118)
                Image(systemName: "person.crop.circle.badge.checkmark").font(.system(size: 62)).foregroundStyle(.white)
            }
            Text("Add someone you trust").font(.largeTitle.bold()).multilineTextAlignment(.center)
            Text("If ScamShield finds a high-risk pattern, it will offer to call this person before you act.")
                .font(.title3).foregroundStyle(.white.opacity(0.86)).multilineTextAlignment(.center)
            VStack(spacing: 12) {
                TextField("Trusted contact’s name", text: $trustedName).textContentType(.name)
                TextField("Phone number", text: $trustedPhone).textContentType(.telephoneNumber).keyboardType(.phonePad)
            }
            .textFieldStyle(OnboardingFieldStyle())
            Text("ScamShield never calls automatically. You always confirm first.").font(.footnote).foregroundStyle(.white.opacity(0.75)).multilineTextAlignment(.center)
            Spacer()
            Text("3 of 3").font(.caption.bold()).foregroundStyle(.white.opacity(0.7)).padding(.bottom, 30)
        }
        .padding(.horizontal, 28)
    }

    private func advance() {
        if page < 2 {
            withAnimation { page += 1 }
        } else if contactIsValid {
            trustedName = trustedName.trimmingCharacters(in: .whitespacesAndNewlines)
            trustedPhone = trustedPhone.trimmingCharacters(in: .whitespacesAndNewlines)
            hasCompletedOnboarding = true
        }
    }
}

private struct OnboardingPage: View {
    let icon: String
    let title: String
    let text: String
    let badge: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle().fill(.white.opacity(0.14)).frame(width: 136, height: 136)
                Image(systemName: icon).font(.system(size: 68)).foregroundStyle(.white)
            }
            Text(title).font(.largeTitle.bold()).multilineTextAlignment(.center)
            Text(text).font(.title3).foregroundStyle(.white.opacity(0.86)).multilineTextAlignment(.center).lineSpacing(4)
            Spacer()
            Text(badge).font(.caption.bold()).foregroundStyle(.white.opacity(0.7)).padding(.bottom, 30)
        }
        .padding(.horizontal, 28)
    }
}

private struct OnboardingFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration.padding(15).foregroundStyle(.white).background(.white.opacity(0.13), in: RoundedRectangle(cornerRadius: 13)).overlay(RoundedRectangle(cornerRadius: 13).stroke(.white.opacity(0.28)))
    }
}

#Preview { OnboardingView() }
