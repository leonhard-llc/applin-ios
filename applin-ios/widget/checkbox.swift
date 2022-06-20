import Foundation
import UIKit

struct CheckboxData: Equatable, Hashable {
    static let TYP = "checkbox"
    let id: String
    let initialBool: Bool
    let actions: [ApplinAction]

    init(_ item: JsonItem, _ session: ApplinSession) throws {
        self.actions = try item.optActions() ?? []
        self.id = try item.requireId()
        self.initialBool = item.initialBool ?? false
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(CheckboxData.TYP)
        item.actions = self.actions.map({ action in action.toString() })
        item.id = self.id
        item.initialBool = self.initialBool
        return item
    }

    func keys() -> [String] {
        ["checkbox:\(self.id)"]
    }

    func getView(_ session: ApplinSession, _ widgetCache: WidgetCache) -> UIView {
        var widget: CheckboxWidget
        if let cachedWidget = widgetCache.remove(self.keys()) as? CheckboxWidget {
            widget = cachedWidget
            widget.data = self
        } else {
            widget = CheckboxWidget(self)
        }
        widgetCache.putNext(widget)
        return widget.getView(session, widgetCache)
    }
}

class CheckboxWidget: Widget {
    var data: CheckboxData
    let view: UISwitch
    weak var session: ApplinSession?

    init(_ data: CheckboxData) {
        print("CheckboxWidget.init(\(data))")
        self.data = data
        self.view = UISwitch()
        self.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.preferredStyle = .checkbox
        self.view.addAction(for: .valueChanged, handler: { [weak self] _ in
            print("checkbox .valueChanged")
            self?.valueChanged()
        })
        self.view.setOn(self.data.initialBool, animated: false)
    }

    func keys() -> [String] {
        self.data.keys()
    }

    func valueChanged() {
        print("checkbox actions")
        self.session?.doActions(self.data.actions)
    }

    func getView(_ session: ApplinSession, _ widgetCache: WidgetCache) -> UIView {
        self.session = session
        return self.view
    }
}
