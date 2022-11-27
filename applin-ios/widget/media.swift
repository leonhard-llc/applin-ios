//import Foundation
//import SwiftUI
//import UIKit
//
//struct MediaSpec: Equatable, Hashable, View {
//    static let TYP = "media"
//    let url: URL
//    let cache: Bool?
//
//    init(url: URL, cache: Bool? = nil) {
//        self.url = url
//        self.cache = cache
//    }
//
//    init(_ item: JsonItem, _ config: ApplinConfig) throws {
//        self.url = try item.requireUrl(config)
//        self.cache = item.cache
//    }
//
//    func toJsonItem() -> JsonItem {
//        let item = JsonItem(MarkdownPageSpec.TYP)
//        item.url = self.url.absoluteString
//        item.cache = self.cache
//        return item
//    }
//
//    func keys() -> [String] {
//        ["media:\(self.url)"]
//    }
//
//    func getView(_ session: ApplinSession, _ cache: WidgetCache) -> UIView {
//        var mediaWidget: MediaWidget
//        switch cache.remove(self.keys()) {
//        case let widget as MediaWidget:
//            mediaWidget = widget
//            mediaWidget.spec = self
//        default:
//            mediaWidget = MediaWidget(self)
//        }
//        cache.putNext(mediaWidget)
//        return mediaWidget.getView(session, cache)
//    }
//}
//
//class MediaWidget: Widget {
//    var spec: MediaSpec
//    var subViewController: UIHostingController<AnyView>
//    weak var session: ApplinSession?
//
//    init(_ spec: MediaSpec) {
//        print("MediaWidget.init(\(spec))")
//        self.spec = spec
//        self.subViewController = UIHostingController(rootView: AnyView(spec))
//    }
//
//    func keys() -> [String] {
//        self.spec.keys()
//    }
//
//    func getView(_ session: ApplinSession, _ cache: WidgetCache) -> UIView {
//        self.session = session
//        self.subViewController.rootView = AnyView(self.spec)
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
