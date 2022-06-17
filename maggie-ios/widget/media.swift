//import Foundation
//import SwiftUI
//import UIKit
//
//struct MediaData: Equatable, Hashable, View {
//    static let TYP = "media"
//    let url: URL
//    let cache: Bool?
//
//    init(url: URL, cache: Bool? = nil) {
//        self.url = url
//        self.cache = cache
//    }
//
//    init(_ item: JsonItem, _ session: MaggieSession?) throws {
//        self.url = try item.requireUrl(session)
//        self.cache = item.cache
//    }
//
//    func toJsonItem() -> JsonItem {
//        let item = JsonItem(MarkdownPageData.TYP)
//        item.url = self.url.absoluteString
//        item.cache = self.cache
//        return item
//    }
//
//    func keys() -> [String] {
//        ["media:\(self.url)"]
//    }
//
//    func getView(_ session: MaggieSession, _ widgetCache: WidgetCache) -> UIView {
//        var mediaWidget: MediaWidget
//        switch widgetCache.remove(self.keys()) {
//        case let widget as MediaWidget:
//            mediaWidget = widget
//            mediaWidget.data = self
//        default:
//            mediaWidget = MediaWidget(self)
//        }
//        widgetCache.putNext(mediaWidget)
//        return mediaWidget.getView(session, widgetCache)
//    }
//}
//
//class MediaWidget: Widget {
//    var data: MediaData
//    var subViewController: UIHostingController<AnyView>
//    weak var session: MaggieSession?
//
//    init(_ data: MediaData) {
//        print("MediaWidget.init(\(data))")
//        self.data = data
//        self.subViewController = UIHostingController(rootView: AnyView(data))
//    }
//
//    func keys() -> [String] {
//        self.data.keys()
//    }
//
//    func getView(_ session: MaggieSession, _ widgetCache: WidgetCache) -> UIView {
//        self.session = session
//        self.subViewController.rootView = AnyView(self.data)
//        return self.subViewController
//    }
//
////    func mediaRole() -> MediaRole? {
////        if self.isDestructive {
////            return .destructive
////        } else if self.isCancel {
////            return .cancel
////        } else {
////            return nil
////        }
////    }
////
////    func keyboardShortcut() -> KeyboardShortcut? {
////        if self.isDefault {
////            return .defaultAction
////        } else if self.isCancel {
////            return .cancelAction
////        } else {
////            return nil
////        }
////    }
////
////    func addKeyboardShortcut<V: View>(_ view: V) -> AnyView {
////        if #available(iOS 15.4, *) {
////            return AnyView(view.keyboardShortcut(self.keyboardShortcut()))
////        } else {
////            return AnyView(view)
////        }
////    }
////
////    var body: some View {
////        Media(
////                self.text,
////                role: self.mediaRole(),
////                action: { () in
////                    print("Media(\(self.text)) action")
////                    self.session?.doActions(self.actions)
////                }
////        )
////                .disabled(self.actions.isEmpty)
////                .mediaStyle(.bordered)
////    }
//}
