import Testing
@testable import ScamShield

struct ScamShieldTests {
    private let engine = ScamDetectionEngine()

    @Test func grandchildImpersonationWithSecrecyAndMoneyIsHighCaution() {
        let result = engine.analyze("Your grandson needs help immediately. Send money by gift card and don't tell Mom.")
        #expect(result.riskLevel == .highCaution)
        #expect(result.signals.map(\.id).contains("urgency"))
        #expect(result.signals.map(\.id).contains("secrecy"))
        #expect(result.signals.map(\.id).contains("payment"))
        #expect(result.signals.map(\.id).contains("impersonation"))
    }

    @Test func bankAlertWithCredentialsAndInsecureLinkIsHighCaution() {
        let result = engine.analyze("Urgent fraud department alert. Confirm your password at http://192.168.1.2/login")
        #expect(result.riskLevel == .highCaution)
        #expect(result.signals.map(\.id).contains("credentials"))
        #expect(result.signals.map(\.id).contains("url"))
    }

    @Test func ordinaryDeliveryNoticeDoesNotClaimSafety() {
        let result = engine.analyze("Your package was delivered at 2:14 PM. View the photo in the official carrier app.")
        #expect(result.riskLevel == .fewSignals)
        #expect(result.signals.isEmpty)
        #expect(result.guidance.first?.contains("proof") == true)
    }

    @Test func legitimateUrgentContextIsCautionNotHighRisk() {
        let result = engine.analyze("Urgent: practice is canceled today. Please pick up your child right away.")
        #expect(result.riskLevel == .caution)
        #expect(result.signals.map(\.id) == ["urgency"])
    }

    @Test func urgentBankHackCountdownAndLinkInstructionIsHighRisk() {
        let result = engine.analyze("URGENT, YOUR BANK ACCOUNT IS BEING HACKED. YOU HAVE 10 MINS TO GET IT BACK, CLICK THIS LINK")
        #expect(result.riskLevel == .highCaution)
        #expect(result.score == 10)
        #expect(result.shouldOfferTrustedContact)
        #expect(result.signals.map(\.id).contains("urgency"))
        #expect(result.signals.map(\.id).contains("threat"))
        #expect(result.signals.map(\.id).contains("linkAction"))
    }

    @Test func normalGiftCardDiscussionDoesNotMatchPaymentRequest() {
        let result = engine.analyze("I received the birthday gift card. Thank you!")
        #expect(result.riskLevel == .fewSignals)
        #expect(!result.signals.map(\.id).contains("payment"))
    }

    @Test func secureOrdinaryURLIsNotFlaggedByURLRule() {
        let result = engine.analyze("Our agenda is at https://www.example.org/meeting")
        #expect(!result.signals.map(\.id).contains("url"))
    }

    @Test func pressuredSecureLoginLinkIsFlagged() {
        let result = engine.analyze("Click the link now to verify your account: https://secure-check.example/login")
        #expect(result.signals.map(\.id).contains("url"))
        #expect(result.signals.map(\.id).contains("urgency"))
        #expect(result.riskLevel == .highCaution)
    }

    @Test func remoteAccessRequestIsHighCaution() {
        let result = engine.analyze("Microsoft support here. Install AnyDesk and share your screen immediately.")
        #expect(result.signals.map(\.id).contains("remoteAccess"))
        #expect(result.riskLevel == .highCaution)
    }

    @Test func harmlessPasswordStatementIsNotCredentialRequest() {
        let result = engine.analyze("Our class discussed why a strong password is important.")
        #expect(!result.signals.map(\.id).contains("credentials"))
        #expect(result.riskLevel == .fewSignals)
    }
}
