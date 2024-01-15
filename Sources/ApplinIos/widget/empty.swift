import Foundation
import UIKit

public struct EmptySpec: Equatable, Hashable, ToSpec {
    static let TYP = "empty"

    public init() {
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(EmptySpec.TYP)
        return item
    }

    func hasValidatedInput() -> Bool {
        false
    }

    func keys() -> [String] {
        []
    }

    func newWidget() -> Widget {
        EmptyWidget()
    }

    func priority() -> WidgetPriority {
        .stateless
    }

    func subs() -> [Spec] {
        []
    }

    public func toSpec() -> Spec {
        Spec(.empty(self))
    }

    func vars() -> [(String, Var)] {
        []
    }

    func widgetClass() -> AnyClass {
        EmptyWidget.self
    }
}

class EmptyWidget: Widget {
    let view: UIView

    init() {
        self.view = NamedUIView(name: "Empty")
        self.view.translatesAutoresizingMaskIntoConstraints = false
        //self.view.backgroundColor = pastelPink
    }

    func getView() -> UIView {
        self.view
    }

    func isFocused() -> Bool {
        false
    }

    func update(_ ctx: PageContext, _ spec: Spec, _ subs: [Widget]) throws {
        guard case .empty = spec.value else {
            throw "Expected .empty got: \(spec)"
        }
        if !subs.isEmpty {
            throw "Expected no subs got: \(subs)"
        }
    }
}
