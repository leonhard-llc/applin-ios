import SwiftUI

struct ContentView: View {
    @ObservedObject var session: MaggieSession
    
    init(_ session: MaggieSession) {
        self.session = session
    }
     
    var body: some View {
        get {
            print("ContentView: session.state=\(session.state)")
            switch session.state {
            case .Connecting:
                return AnyView(ProgressView() {
                    Text("Loading")
                })
            case .Connected:
                return AnyView(Text("Connected"))
            case .Sending:
                return AnyView(Text("Sending"))
            case let .ServerError(err):
                return AnyView(Text("Error: \(err)"))
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(MaggieSession.preview())
    }
}
