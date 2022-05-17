import SwiftUI

struct SessionStatusView: View {
    @ObservedObject var session: MaggieSession

    init(_ session: MaggieSession) {
        self.session = session
    }

    var body: some View {
        let message: String
        switch session.state {
        case .startup:
            message = "Connecting"
        case .connectError:
            message = "Connection problem"
        case .serverError:
            message = "Server problem"
        case .connected:
            return AnyView(EmptyView())
        }
        return AnyView(
                VStack(alignment: .center) {
                    HStack(alignment: .center) {
                        Text(message)
                        ProgressView()
                                .padding(EdgeInsets.init(
                                        top: 0, leading: 1, bottom: 0, trailing: 0))
                    }
                    Divider()
                }
        )
    }
}
