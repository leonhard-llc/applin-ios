import Foundation

@globalActor
struct BackgroundActor {
    actor ActorType {
    }

    static let shared: ActorType = ActorType()
}
