struct DisplayID: Hashable, Comparable, CustomStringConvertible, Sendable {
    let rawValue: String

    var description: String {
        rawValue
    }

    static func < (lhs: DisplayID, rhs: DisplayID) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
