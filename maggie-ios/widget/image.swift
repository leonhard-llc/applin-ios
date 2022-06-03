import Foundation

struct MaggieImage: Equatable, Hashable {
    static let TYP = "image"
    let url: URL
    let width: MaggieDimension
    let disposition: MaggieDisposition

    init(_ item: JsonItem, _ session: MaggieSession?) throws {
        self.url = try item.requireUrl(session)
        self.width = item.getWidth()
        self.disposition = item.optDisposition() ?? .fit
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieImage.TYP)
        item.url = self.url.absoluteString
        item.setWidth(width)
        item.setDisposition(self.disposition)
        return item
    }

//    var body: some View {
//        switch self.disposition {
//        case .cover:
//            return AnyView(
//                    AsyncImage(url: self.url) { image in
//                        image.resizable()
//                    } placeholder: {
//                        ProgressView()
//                    }
//                            .scaledToFill()
//                            .frame(width: self.width, height: self.height)
//                            .clipped()
//                            .border(Color.black)
//                            .padding(1.0))
//        case .fit:
//            return AnyView(
//                    AsyncImage(url: self.url) { image in
//                        image
//                                .resizable()
//                    } placeholder: {
//                        ProgressView()
//                    }
//                            .scaledToFit()
//                            .frame(width: self.width, height: self.height)
//                            .border(Color.black)
//                            .padding(1.0))
//        case .stretch:
//            return AnyView(
//                    AsyncImage(url: self.url) { image in
//                        image.resizable()
//                    } placeholder: {
//                        ProgressView()
//                    }
//                            .frame(width: self.width, height: self.height)
//                            .border(Color.black)
//                            .padding(1.0))
//        }
//    }
}
