import Foundation
import UIKit

struct EmptyData: Equatable, Hashable {
    static let TYP = "empty"

    func toJsonItem() -> JsonItem {
        let item = JsonItem(EmptyData.TYP)
        return item
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

    func widget() -> WidgetProto {
        EmptyWidget()
    }
}

class EmptyWidget: WidgetProto {
    let view: UIView
    weak var session: ApplinSession?

    init() {
        self.view = UIView()
        self.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.backgroundColor = pastelPink
    }

    func getView() -> UIView {
        self.view
    }

    func isFocused() -> Bool {
        false
    }

    func update(_: ApplinSession, _ spec: Spec, _  subs: [WidgetProto]) throws {
        guard case .empty = spec.value else {
            throw "Expected .empty got: \(spec)"
        }
        if !subs.isEmpty {
            throw "Expected no subs got: \(subs)"
        }
    }
}
