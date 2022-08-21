import Foundation
import UIKit

struct FormButtonData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "form-button"
    let actions: [ActionData]
    let pageKey: String
    let text: String

    init(pageKey: String, _ actions: [ActionData], text: String) {
        self.actions = actions
        self.pageKey = pageKey
        self.text = text
    }

    init(pageKey: String, _ item: JsonItem) throws {
        self.actions = try item.optActions() ?? []
        self.pageKey = pageKey
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
        if self.actions.isEmpty {
            return nil
        }
        return self.actions
    }

    func getView(_ session: ApplinSession, _ cache: WidgetCache) -> UIView {
        let widget = cache.remove(self.keys()) as? FormButtonWidget ?? FormButtonWidget(self)
        widget.data = self
        cache.putNext(widget)
        return widget.getView(session)
    }

    func vars() -> [(String, Var)] {
        []
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
        self.session?.doActions(pageKey: self.data.pageKey, self.data.actions)
    }

    func getView(_ session: ApplinSession) -> UIView {
        self.session = session
        self.button.setTitle(self.data.text, for: .normal)
        self.button.isEnabled = !self.data.actions.isEmpty
        return self.button
    }
}
