import Foundation
import SwiftUI

struct MaggieImage: Equatable, Hashable, View {
    static let TYP = "image"
    let url: URL
    let width: CGFloat?
    let height: CGFloat?
    let disposition: MaggieDisposition
    
    init(_ item: JsonItem) throws {
        self.url = try item.takeUrl()
        self.width = try item.takeOptWidth()
        self.height = try item.takeOptHeight()
        self.disposition = item.takeOptDisposition() ?? .fit
    }
    
    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieImage.TYP)
        item.url = self.url
        item.width = self.width != nil ? Double(self.width!) : nil
        item.height = self.height != nil ? Double(self.height!) : nil
        item.setDisposition(self.disposition)
        return item
    }
    
    var body: some View {
        switch self.disposition {
        case .cover:
            return AnyView(
                AsyncImage(url: self.url) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
                    .scaledToFill()
                    .frame(width: self.width, height: self.height)
                    .clipped()
                    .border(Color.black)
                    .padding(1.0))
        case .fit:
            return AnyView(
                AsyncImage(url: self.url) { image in
                    image
                        .resizable()
                } placeholder: {
                    ProgressView()
                }
                    .scaledToFit()
                    .frame(width: self.width, height: self.height)
                    .border(Color.black)
                    .padding(1.0))
        case .stretch:
            return AnyView(
                AsyncImage(url: self.url) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
                    .frame(width: self.width, height: self.height)
                    .border(Color.black)
                    .padding(1.0))
        }
    }
}
