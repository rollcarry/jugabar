import Foundation

public extension Int {
    var formattedWithSeparator: String {
        return NumberFormatter.localizedString(from: NSNumber(value: self), number: .decimal)
    }
}
