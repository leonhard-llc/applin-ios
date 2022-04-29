import SwiftUI

struct SessionStatusView: View {
    @ObservedObject var session: MaggieSession
    
    init(_ session: MaggieSession) {
        self.session = session
    }
    
    var body: some View {
        get {
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
}

struct SessionStatusView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack() {
                SessionStatusView(MaggieSession.preview())
                Text("Hello")
                Spacer()
            }
            VStack() {
                SessionStatusView(MaggieSession.preview_connected())
                Text("Hello")
                Spacer()
            }
        }
        //.previewLayout(.fixed(width: 400, height: 70))
    }
}
