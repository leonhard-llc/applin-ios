import Foundation
import UIKit

public struct TextSpec: Equatable, Hashable, ToSpec {
    static let TYP = "text"
    let text: String

    public init(_ text: String) {
        self.text = text
    }

    init(_ item: JsonItem) throws {
        self.text = try item.requireText()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(TextSpec.TYP)
        item.text = self.text
        return item
    }

    public func toSpec() -> Spec {
        Spec(.text(self))
    }

    func keys() -> [String] {
        ["text:\(self.text)"]
    }

    func priority() -> WidgetPriority {
        .stateless
    }

    func subs() -> [Spec] {
        []
    }

    func vars() -> [(String, Var)] {
        []
    }

    func widgetClass() -> AnyClass {
        TextWidget.self
    }

    func newWidget() -> Widget {
        TextWidget()
    }

    func visitActions(_ f: (ActionSpec) -> ()) {
    }
}

class TextWidget: Widget {
    let paddedLabel: PaddedLabel

    init() {
        self.paddedLabel = PaddedLabel()
        self.paddedLabel.translatesAutoresizingMaskIntoConstraints = false
    }

    func getView() -> UIView {
        self.paddedLabel
    }

    func isFocused() -> Bool {
        false
    }

    func update(_ ctx: PageContext, _ spec: Spec, _ subs: [Widget]) throws {
        guard case let .text(textSpec) = spec.value else {
            throw "Expected .text got: \(spec)"
        }
        if !subs.isEmpty {
            throw "Expected no subs got: \(subs)"
        }
        if textSpec.text.isEmpty == true {
            self.paddedLabel.text = " "
        } else {
            self.paddedLabel.text = textSpec.text
        }
    }
}
