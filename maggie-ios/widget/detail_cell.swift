//import Foundation
//
//struct MaggieDetailCell: Equatable, Hashable {
//    static func ==(lhs: MaggieDetailCell, rhs: MaggieDetailCell) -> Bool {
//        lhs.text == rhs.text
//                && lhs.actions == rhs.actions
//                && lhs.photoUrl == rhs.photoUrl
//    }
//
//    static let TYP = "detail-cell"
//    let text: String
//    let actions: [MaggieAction]
//    let photoUrl: URL?
//    weak var session: MaggieSession?
//
//    init(_ item: JsonItem, _ session: MaggieSession) throws {
//        self.text = try item.requireText()
//        self.actions = try item.optActions() ?? []
//        self.photoUrl = try item.optPhotoUrl(session)
//        self.session = session
//    }
//
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(self.text)
//        hasher.combine(self.actions)
//        hasher.combine(self.photoUrl)
//    }
//
//    func toJsonItem() -> JsonItem {
//        let item = JsonItem(ButtonData.TYP)
//        item.text = self.text
//        item.actions = self.actions.map({ action in action.toString() })
//        // TODO: Test this.
//        item.photoUrl = self.photoUrl?.relativeString
//        return item
//    }
//
////    var body: some View {
////        let binding = Binding(
////                get: { () in false },
////                set: { show in
////                    print("DetailCell(\(self.text)) action")
////                    if show {
////                        self.session?.doActions(self.actions)
////                    }
////                })
////        let destination = EmptyView().navigationTitle("Empty View")
////        if let photoUrl = self.photoUrl {
////            NavigationLink(
////                    isActive: binding,
////                    destination: { destination },
////                    label: {
////                        HStack {
////                            AsyncImage(url: photoUrl) { image in
////                                image
////                                        .resizable()
////                            } placeholder: {
////                                ProgressView()
////                            }
////                                    .scaledToFit()
////                                    .frame(width: 44, height: 44)
////                                    .border(Color.black)
////                            Text(self.text)
////                        }
////                    })
////                    .disabled(self.actions.isEmpty)
////        } else {
////            NavigationLink(self.text, isActive: binding, destination: { destination })
////                    .disabled(self.actions.isEmpty)
////        }
////    }
//}
