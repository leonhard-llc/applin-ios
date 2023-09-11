import Foundation

struct Instant {
    public static let EARLIEST = Self(secondsSinceEpoch: 0)

    public static func ==(lhs: Instant, rhs: Instant) -> Bool {
        lhs.secondsSinceEpoch == rhs.secondsSinceEpoch
    }

    public static func <(lhs: Instant, rhs: Instant) -> Bool {
        lhs.secondsSinceEpoch < rhs.secondsSinceEpoch
    }

    let secondsSinceEpoch: UInt64

    init(secondsSinceEpoch: UInt64) {
        self.secondsSinceEpoch = secondsSinceEpoch
    }
}

class WallClock {
    func now() -> Instant {
        Instant(secondsSinceEpoch: Date().secondsSinceEpoch())
    }
}
