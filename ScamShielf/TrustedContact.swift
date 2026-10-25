import Foundation

struct TrustedContact: Equatable {
    let name: String
    let phone: String

    var callURL: URL? {
        let allowed = phone.filter { $0.isNumber || $0 == "+" }
        guard !allowed.isEmpty else { return nil }
        return URL(string: "tel:\(allowed)")
    }
}
