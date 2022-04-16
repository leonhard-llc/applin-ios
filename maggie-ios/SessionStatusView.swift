import SwiftUI

struct SessionStatusView: View {
    @ObservedObject var session: MaggieSession
    
    init(_ session: MaggieSession) {
        self.session = session
    }
    
    var body: some View {
        get {
            if session.connected {
                return AnyView(EmptyView())
            } else {
                return AnyView(
                    VStack(alignment: .center) {
                        HStack(alignment: .center) {
                            Text("Connecting")
                            ProgressView()
                                .padding(EdgeInsets.init(
                                    top: 0, leading: 1, bottom: 0, trailing: 0))
                        }
                        Divider()
                    })
            }
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
