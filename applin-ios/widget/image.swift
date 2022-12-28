import Foundation
import UIKit

struct ImageSpec: Equatable, Hashable {
    static let TYP = "image"
    let aspectRatio: Double
    let url: URL

    init(_ config: ApplinConfig, _ item: JsonItem) throws {
        self.aspectRatio = try item.requireAspectRatio()
        self.url = try item.requireUrl(config)
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(ImageSpec.TYP)
        item.aspectRatio = self.aspectRatio
        item.url = self.url.relativeString
        return item
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

    func update(_ session: ApplinSession, _ spec: Spec, _ subs: [Widget]) throws {
        guard case let .image(imageSpec) = spec.value else {
            throw "Expected .image got: \(spec)"
        }
        if !subs.isEmpty {
            throw "Expected no subs got: \(subs)"
        }
        self.imageView.update(imageSpec.url, aspectRatio: imageSpec.aspectRatio)
    }
}
