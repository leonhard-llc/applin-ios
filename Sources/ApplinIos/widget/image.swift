import Foundation
import UIKit

public struct ImageSpec: Equatable, Hashable, ToSpec {
    static let TYP = "image"
    let aspectRatio: Double
    let disposition: ApplinDisposition?
    let url: URL

    init(_ config: ApplinConfig, _ item: JsonItem) throws {
        self.aspectRatio = try item.requireAspectRatio()
        self.disposition = item.optDisposition()
        self.url = try item.requireUrl(config)
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(ImageSpec.TYP)
        item.aspectRatio = self.aspectRatio
        item.setDisposition(self.disposition)
        item.url = self.url.relativeString
        return item
    }

    init(_ config: ApplinConfig, url: String, aspectRatio: Double, disposition: ApplinDisposition? = nil) {
        self.aspectRatio = aspectRatio
        self.disposition = disposition
        self.url = URL(string: url)!
    }

    public func toSpec() -> Spec {
        Spec(.image(self))
    }

    func keys() -> [String] {
        ["image::\(self.url.absoluteString)"]
    }

    func priority() -> WidgetPriority {
        .stateful
    }

    func subs() -> [Spec] {
        []
    }

    func widgetClass() -> AnyClass {
        ImageWidget.self
    }

    func newWidget() -> Widget {
        ImageWidget(aspectRatio: self.aspectRatio)
    }

    func vars() -> [(String, Var)] {
        []
    }

    func visitActions(_ f: (ActionSpec) -> ()) {
    }
}

class ImageWidget: Widget {
    private let imageView: ImageView

    public init(aspectRatio: Double) {
        self.imageView = ImageView(aspectRatio: aspectRatio)
    }

    func getView() -> UIView {
        self.imageView
    }

    func isFocused() -> Bool {
        false
    }

    func update(_ ctx: PageContext, _ spec: Spec, _ subs: [Widget]) throws {
        guard case let .image(imageSpec) = spec.value else {
            throw "Expected .image got: \(spec)"
        }
        if !subs.isEmpty {
            throw "Expected no subs got: \(subs)"
        }
        self.imageView.update(imageSpec.url, aspectRatio: imageSpec.aspectRatio, imageSpec.disposition ?? .cover)
    }
}
