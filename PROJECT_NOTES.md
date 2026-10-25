# ScamShield project notes

## Progress

- [x] SwiftUI pasted-text input
- [x] Screenshot selection with PhotosPicker
- [x] On-device Apple Vision text recognition
- [x] Explainable on-device scam-signal rules
- [x] Uncertain results and independent-verification guidance
- [x] Unit tests covering scams, benign messages, and false-positive cases
- [x] iMessage extension with explicit manual paste and shared on-device analysis
- [x] Trusted-contact setup and high-risk call confirmation
- [ ] Share extension (optional)

## How the analysis works

`ScamDetectionEngine` normalizes the message and uses regular-expression rules that look for both suspicious topics and action-oriented context. For example, merely mentioning a gift card or password is not enough to trigger the payment or credential rules; the message must ask the reader to buy, send, share, confirm, or enter it. Rules cover urgency, secrecy, hard-to-reverse payments, sensitive information, impersonation, threats, prizes, remote-access software, and suspicious or pressured links. Combined patterns such as impersonation plus payment or urgency plus a credential request receive an additional score. A total of 0–2 shows no strong pattern, 3–6 shows warning signs, and 7 or more shows a prominent stop warning. The interface always says the result is not a guarantee.

This simple approach is intentionally transparent. Important limitations include missed phrases, lost context, false positives, OCR mistakes, and new scam tactics.

## Contribution record

### Original student decisions and inputs

- App idea, name, audience, pitch, and focus on older adults
- Core flow: pasted text or screenshot to warning-sign explanations and safer next steps
- Choice to prioritize privacy, accessibility, and on-device processing
- Choice to pursue iMessage and Share extensions only after the core app works
- Initial Xcode project creation

### Codex assistance on October 23, 2026

- Implemented the first SwiftUI core-app interface
- Implemented PhotosPicker loading and Apple Vision OCR
- Designed and implemented the weighted, phrase-based detection rules and suspicious-URL checks
- Added accessible labels, uncertainty language, privacy messaging, and a labeled sample
- Added unit tests and this technical/contribution documentation
- Ran builds and tests and reported their exact results
- Added an iMessage app extension that requires the user to copy and paste text; it does not claim access to conversations
- Added persistent trusted-contact details, an explicit confirmation alert, and a user-initiated phone call action

The student should review, explain, and refine the rule phrases, weights, interface language, and test cases. AI assistance should be disclosed in the competition submission.
