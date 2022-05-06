import Foundation
import SwiftUI

struct MaggieDetailCell: Equatable, Hashable, View {
    static func == (lhs: MaggieDetailCell, rhs: MaggieDetailCell) -> Bool {
        return lhs.text == rhs.text
        && lhs.actions == rhs.actions
        && lhs.photoUrl == rhs.photoUrl
    }

    static let TYP = "detail-cell"
    let text: String
    let actions: [MaggieAction]
    let photoUrl: URL?
    weak var session: MaggieSession?
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.text = try item.takeText()
        self.actions = try item.takeOptActions() ?? []
        self.photoUrl = item.takeOptPhotoUrl()
        self.session = session
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.text)
        hasher.combine(self.actions)
        hasher.combine(self.photoUrl)
    }
    
    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieButton.TYP)
        item.text = self.text
        item.actions = self.actions.map({action in action.toString()})
        item.photoUrl = self.photoUrl
        return item
    }
    
    var body: some View {
        let binding = Binding(
            get: {() in false},
            set: { show in
                print("DetailCell(\(self.text)) action")
                if show {
                    self.session?.doActions(self.actions)
                }
            })
        let destination = EmptyView().navigationTitle("Empty View")
        //if let photoUrl = self.photoUrl {
        //    NavigationLink(isActive: binding, destination: {destination}) {
        //        HStack{
        //            AsyncImage(url: photoUrl) { image in
        //                image
        //                    .resizable()
        //            } placeholder: {
        //                ProgressView()
        //            }
        //                .scaledToFit()
        //                .frame(width: 100, height: 100)
        //                .border(Color.black)
        //            Text(self.text)
        //        }
        //    }
        //    .frame(maxWidth: .infinity)
        //    .disabled(self.actions.isEmpty)
        //} else {
        NavigationLink(self.text, isActive: binding, destination: {destination})
//            .frame(maxWidth: .infinity, minHeight: 44)
//        .disabled(self.actions.isEmpty)
    }
}
