import Foundation
import UIKit

struct EmptySpec: Equatable, Hashable, ToSpec {
    static let TYP = "empty"

    func toJsonItem() -> JsonItem {
        let item = JsonItem(EmptySpec.TYP)
        return item
    }

    func toSpec() -> Spec {
        Spec(.empty(self))
    }

    func keys() -> [String] {
        []
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
        EmptyWidget.self
    }

    func newWidget() -> Widget {
        EmptyWidget()
    }
}

class EmptyWidget: Widget {
    let view: UIView
    weak var session: ApplinSession?

    init() {
        print("EmptyWidget.init()")
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

    func update(_ session: ApplinSession, _ state: ApplinState, _ spec: Spec, _ subs: [Widget]) throws {
        guard case .empty = spec.value else {
            throw "Expected .empty got: \(spec)"
        }
        if !subs.isEmpty {
            throw "Expected no subs got: \(subs)"
        }
    }
}
