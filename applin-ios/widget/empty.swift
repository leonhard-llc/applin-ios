import Foundation
import UIKit

struct EmptyData: Equatable, Hashable, WidgetDataProto {
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

    func subs() -> [WidgetData] {
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

    func isFocused(_ session: ApplinSession, _ data: WidgetData) -> Bool {
        false
    }

    func update(_ session: ApplinSession, _ data: WidgetData, _ subs: [WidgetProto]) throws {
    }
}