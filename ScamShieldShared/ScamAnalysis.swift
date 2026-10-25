import Foundation

enum RiskLevel: String, Equatable, Sendable {
    case fewSignals, caution, highCaution

    var title: String {
        switch self {
        case .fewSignals: "No major warning signs detected"
        case .caution: "Possible scam — use caution"
        case .highCaution: "HIGH RISK OF SCAM"
        }
    }

    var shortTitle: String {
        switch self {
        case .fewSignals: "No strong pattern"
        case .caution: "Use caution"
        case .highCaution: "High risk of scam"
        }
    }

    var symbol: String {
        switch self {
        case .fewSignals: "shield.lefthalf.filled"
        case .caution: "exclamationmark.shield.fill"
        case .highCaution: "hand.raised.fill"
        }
    }
}

struct ScamSignal: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let explanation: String
    let evidence: [String]
    let weight: Int
}

struct ScamAnalysis: Equatable, Sendable {
    let riskLevel: RiskLevel
    let score: Int
    let signals: [ScamSignal]

    var shouldOfferTrustedContact: Bool { riskLevel == .highCaution }

    var summary: String {
        switch riskLevel {
        case .fewSignals:
            "The analyzer did not find a strong scam pattern, but it cannot prove this message is safe."
        case .caution:
            "Pause and verify this message independently before replying, clicking, or sharing information."
        case .highCaution:
            "This message shows multiple strong scam tactics. Stop now: do not reply, click, pay, or share information. Call someone you trust before taking any action."
        }
    }

    var guidance: [String] {
        switch riskLevel {
        case .fewSignals:
            ["Do not treat this result as proof that the message is safe.", "Verify unexpected requests using a number or app you already trust."]
        case .caution, .highCaution:
            ["Stop and do not interact with the message.", "Do not send money, passwords, personal details, or verification codes.", "Contact the claimed person or organization through a number or app you find independently.", "Ask a trusted person for a second opinion."]
        }
    }
}

struct ScamDetectionEngine: Sendable {
    private struct Rule: Sendable {
        let id: String
        let title: String
        let explanation: String
        let patterns: [String]
        let weight: Int
    }

    private let rules: [Rule] = [
        Rule(id: "urgency", title: "Pressure to act immediately", explanation: "Time pressure is used to create panic and stop you from checking the story.", patterns: [#"\b(?:act|respond|reply|pay|call|click).{0,24}\b(?:now|immediately)\b"#, #"\bimmediately\b"#, #"\burgent(?:ly)?\b"#, #"\bright away\b"#, #"\b(?:within|in|have|you have).{0,12}\b(?:\d+|one|two|ten)\s*(?:hours?|hrs?|minutes?|mins?)\b"#, #"\bfinal warning\b"#, #"\b(?:account|service) (?:will be |has been )?(?:closed|suspended|locked)\b"#], weight: 3),
        Rule(id: "secrecy", title: "Told to keep it secret", explanation: "Secrecy isolates you from people who could recognize the scam.", patterns: [#"\b(?:do not|don't|dont) tell\b"#, #"\bkeep (?:this|it) (?:a )?secret\b"#, #"\bbetween (?:you and me|us)\b"#, #"\b(?:do not|don't|dont) contact\b"#], weight: 4),
        Rule(id: "payment", title: "Hard-to-reverse payment requested", explanation: "Gift cards, cryptocurrency, wires, and payment apps offer little protection once money is sent.", patterns: [#"\b(?:buy|get|purchase|send|pay|transfer).{0,28}\bgift cards?\b"#, #"\b(?:send|pay|transfer).{0,28}\b(?:bitcoin|crypto(?:currency)?|wire transfer|western union|moneygram|cash app|zelle|venmo)\b"#, #"\b(?:gift card|bitcoin|crypto) (?:number|code|pin)\b"#], weight: 4),
        Rule(id: "credentials", title: "Sensitive information requested", explanation: "Real organizations should not ask for passwords or one-time security codes in an unexpected message.", patterns: [#"\b(?:send|share|reply with|provide|confirm|enter).{0,35}\b(?:password|verification code|security code|one[ -]?time code|social security number|bank account|routing number|credit card number|pin)\b"#, #"\bwhat is your (?:password|pin|social security number)\b"#], weight: 4),
        Rule(id: "impersonation", title: "Possible impersonation story", explanation: "Scammers often pose as family, banks, government agencies, police, or technical support.", patterns: [#"\b(?:your )?(?:grandson|granddaughter|grandchild)\b"#, #"\bit'?s me.{0,24}\bnew (?:phone|number)\b"#, #"\b(?:irs|social security administration|fraud department|microsoft support|apple support|police department|sheriff'?s office)\b"#, #"\bI'?m (?:your|with the) (?:bank|government|police|tech support)\b"#], weight: 2),
        Rule(id: "threat", title: "Threatening or frightening consequence", explanation: "Claims of account theft, arrest, disconnection, or financial loss are designed to trigger panic.", patterns: [#"\b(?:bank )?account.{0,24}\b(?:hacked|compromised|breached|stolen|taken over|at risk)\b"#, #"\b(?:hacker|someone).{0,24}\b(?:accessing|inside|using).{0,24}\baccount\b"#, #"\b(?:you will|you'll) be arrested\b"#, #"\barrest warrant\b"#, #"\blegal action\b"#, #"\bservice (?:will be )?disconnected\b"#, #"\blose access\b"#, #"\blaw enforcement\b"#], weight: 4),
        Rule(id: "linkAction", title: "Pressured to click a link", explanation: "Unexpected messages that push you to click a link are a common route to fake sign-in pages and stolen information.", patterns: [#"\b(?:click|tap|open|follow|visit|use).{0,18}\b(?:this |the |a )?(?:link|url|website|site)\b"#, #"\b(?:link|url).{0,18}\b(?:below|above|now|immediately)\b"#], weight: 3),
        Rule(id: "prize", title: "Unexpected prize or refund", explanation: "A prize or refund that requires a fee or personal information is a common scam setup.", patterns: [#"\byou (?:have |have been )?(?:won|selected)\b"#, #"\bclaim (?:your|the) (?:prize|reward)\b"#, #"\b(?:refund|prize) (?:fee|processing fee)\b"#], weight: 2),
        Rule(id: "remoteAccess", title: "Asked to install remote-access software", explanation: "Remote-access apps can let a stranger control your device and financial accounts.", patterns: [#"\b(?:install|download).{0,24}\b(?:anydesk|teamviewer|remote desktop|screenconnect)\b"#, #"\bshare your screen\b"#], weight: 5)
    ]

    func analyze(_ text: String) -> ScamAnalysis {
        let normalized = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
        var matches = rules.compactMap { rule -> ScamSignal? in
            let evidence = matchedText(patterns: rule.patterns, in: normalized)
            guard !evidence.isEmpty else { return nil }
            return ScamSignal(id: rule.id, title: rule.title, explanation: rule.explanation, evidence: evidence, weight: rule.weight)
        }

        let linkEvidence = riskyLinks(in: text, normalizedText: normalized)
        if !linkEvidence.isEmpty {
            matches.append(ScamSignal(id: "url", title: "Suspicious or pressured link", explanation: "The link is insecure, disguised, shortened, or paired with instructions to sign in or verify an account.", evidence: linkEvidence, weight: 3))
        }

        var score = matches.reduce(0) { $0 + $1.weight }
        let ids = Set(matches.map(\.id))
        if ids.contains("impersonation") && !ids.isDisjoint(with: ["payment", "credentials", "secrecy"]) { score += 2 }
        if ids.contains("urgency") && !ids.isDisjoint(with: ["payment", "credentials", "threat", "linkAction", "url"]) { score += 2 }
        if matches.count >= 3 { score += 1 }
        score = min(score, 10)

        let level: RiskLevel = score >= 6 ? .highCaution : (score >= 2 ? .caution : .fewSignals)
        return ScamAnalysis(riskLevel: level, score: score, signals: matches)
    }

    private func matchedText(patterns: [String], in text: String) -> [String] {
        var results: [String] = []
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, range: range), let swiftRange = Range(match.range, in: text) {
                let evidence = String(text[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !results.contains(evidence) { results.append(evidence) }
            }
        }
        return results
    }

    private func riskyLinks(in text: String, normalizedText: String) -> [String] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        let pressured = normalizedText.range(of: #"\b(?:click|tap|open|visit|verify|confirm|sign[ -]?in|log[ -]?in).{0,35}(?:link|https?://|www\.)"#, options: .regularExpression) != nil
        return detector.matches(in: text, range: range).compactMap { result in
            guard let url = result.url else { return nil }
            let value = url.absoluteString
            let host = url.host(percentEncoded: false)?.lowercased() ?? ""
            let shorteners = ["bit.ly", "tinyurl.com", "t.co", "goo.gl", "ow.ly", "is.gd", "cutt.ly"]
            let isShortener = shorteners.contains(host)
            let usesIPAddress = host.range(of: #"^\d{1,3}(\.\d{1,3}){3}$"#, options: .regularExpression) != nil
            let insecure = url.scheme?.lowercased() == "http"
            let disguised = value.contains("@") || host.contains("xn--") || host.components(separatedBy: ".").count > 5
            return (pressured || isShortener || usesIPAddress || insecure || disguised) ? value : nil
        }
    }
}
