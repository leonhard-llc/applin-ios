import Foundation

public struct LamportInstant: Comparable, Equatable {
    public static func ==(lhs: LamportInstant, rhs: LamportInstant) -> Bool {
        lhs.time == rhs.time
    }

    public static func <(lhs: LamportInstant, rhs: LamportInstant) -> Bool {
        lhs.time < rhs.time
    }

    private let time: UInt64

    fileprivate init(_ time: UInt64) {
        self.time = time
    }
}

class LamportClock {
    private let time = AtomicUInt64(1)

    public func now() -> LamportInstant {
        LamportInstant(self.time.increment())
    }
}
