//import Foundation
//
//struct ApplinImage: Equatable, Hashable {
//    static let TYP = "image"
//    let url: URL
//    let width: ApplinDimension
//    let disposition: ApplinDisposition
//
//    init(_ item: JsonItem, _ config: ApplinConfig) throws {
//        self.url = try item.requireUrl(config)
//        self.width = item.getWidth()
//        self.disposition = item.optDisposition() ?? .fit
//    }
//
//    func toJsonItem() -> JsonItem {
//        let item = JsonItem(ApplinImage.TYP)
//        item.url = self.url.absoluteString
//        item.setWidth(width)
//        item.setDisposition(self.disposition)
//        return item
//    }
//
////    var body: some View {
////        switch self.disposition {
////        case .cover:
////            return AnyView(
////                    AsyncImage(url: self.url) { image in
////                        image.resizable()
////                    } placeholder: {
////                        ProgressView()
////                    }
////                            .scaledToFill()
////                            .frame(width: self.width, height: self.height)
////                            .clipped()
////                            .border(Color.black)
////                            .padding(1.0))
////        case .fit:
////            return AnyView(
////                    AsyncImage(url: self.url) { image in
////                        image
////                                .resizable()
////                    } placeholder: {
////                        ProgressView()
////                    }
////                            .scaledToFit()
////                            .frame(width: self.width, height: self.height)
////                            .border(Color.black)
////                            .padding(1.0))
////        case .stretch:
////            return AnyView(
////                    AsyncImage(url: self.url) { image in
////                        image.resizable()
////                    } placeholder: {
////                        ProgressView()
////                    }
////                            .frame(width: self.width, height: self.height)
////                            .border(Color.black)
////                            .padding(1.0))
////        }
////    }
//}
