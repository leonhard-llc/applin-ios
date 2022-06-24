import Foundation
import UIKit

struct FormButtonData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "form-button"
    let actions: [ActionData]
    let text: String

    init(_ actions: [ActionData], text: String) {
        self.actions = actions
        self.text = text
    }

    init(_ item: JsonItem) throws {
        self.actions = try item.optActions() ?? []
        self.text = try item.requireText()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(FormButtonData.TYP)
        item.actions = self.actions.map({ action in action.toString() })
        item.text = self.text
        return item
    }

    func keys() -> [String] {
        ["form-button:\(self.actions)", "form-button:\(self.text)"]
    }

    func getTapActions() -> [ActionData]? {
        self.actions
    }

    func getView(_ session: ApplinSession, _ widgetCache: WidgetCache) -> UIView {
        let widget = widgetCache.remove(self.keys()) as? FormButtonWidget ?? FormButtonWidget(self)
        widget.data = self
        widgetCache.putNext(widget)
        return widget.getView(session, widgetCache)
    }
}

class FormButtonWidget: WidgetProto {
    var data: FormButtonData
    var button: UIButton!
    weak var session: ApplinSession?

    init(_ data: FormButtonData) {
        print("FormButtonWidget.init(\(data))")
        self.data = data
        let action = UIAction(title: "uninitialized", handler: { [weak self] _ in
            print("form-button UIAction")
            self?.doActions()
        })
        self.button = UIButton(type: .system, primaryAction: action)
        self.button.translatesAutoresizingMaskIntoConstraints = false
    }

    func keys() -> [String] {
        self.data.keys()
    }

    func doActions() {
        print("form-button actions")
        self.session?.doActions(self.data.actions)
    }

    func getView(_ session: ApplinSession, _ widgetCache: WidgetCache) -> UIView {
        self.session = session
        self.button.setTitle(self.data.text, for: .normal)
        return self.button
    }
}
