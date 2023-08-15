import Foundation

// https://www.andyibanez.com/posts/mainactor-and-global-actors-in-swift/

// https://www.avanderlee.com/swift/actors/
// https://developer.apple.com/documentation/xcode/diagnosing-memory-thread-and-crash-issues-early
@globalActor
struct BackgroundActor {
    actor ActorType {
    }

    static let shared: ActorType = ActorType()
}
