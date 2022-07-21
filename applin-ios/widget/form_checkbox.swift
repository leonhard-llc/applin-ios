import Foundation
import UIKit

struct FormCheckboxData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "form-checkbox"
    let id: String
    let initiallyChecked: Bool
    let rpc: String?
    let text: String

    init(id: String, text: String, initiallyChecked: Bool = false, rpc: String? = nil) {
        self.id = id
        self.initiallyChecked = initiallyChecked
        self.rpc = rpc
        self.text = text
    }

    init(_ item: JsonItem) throws {
        self.id = try item.requireId()
        self.initiallyChecked = item.initialBool ?? false
        self.rpc = item.rpc
        self.text = try item.requireText()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(FormCheckboxData.TYP)
        item.id = self.id
        item.initialBool = self.initiallyChecked ? true : nil
        item.rpc = self.rpc
        item.text = self.text
        return item
    }

    func keys() -> [String] {
        ["form-checkbox:\(self.id)"]
    }

    func getTapActions() -> [ActionData]? {
        if let rpc = self.rpc {
            return [ActionData.rpc(rpc)]
        } else {
            return nil
        }
    }

    func getView(_ session: ApplinSession, _ widgetCache: WidgetCache) -> UIView {
        let widget = widgetCache.remove(self.keys()) as? FormCheckboxWidget ?? FormCheckboxWidget(self)
        widget.data = self
        widgetCache.putNext(widget)
        return widget.getView(session, widgetCache)
    }
}

class FormCheckboxWidget: WidgetProto {
    // TODO: Show as checkbox
    // TODO: Set initial state
    // TODO: Save state in page-level VarCache
    // TODO: Send variable data with RPC
    // TODO: Decide how to handle updates to initial state.
    let checked: UIImage
    let unchecked: UIImage
    var data: FormCheckboxData
    var button: UIButton!
    weak var session: ApplinSession?

    init(_ data: FormCheckboxData) {
        print("FormCheckboxWidget.init(\(data))")
        self.unchecked = UIImage(systemName: "square")!
        self.checked = UIImage(systemName: "checkmark.square.fill")!
        self.data = data
        let action = UIAction(title: "uninitialized", handler: { [weak self] _ in
            print("form-button UIAction")
            self?.doActions()
        })
        self.button = UIButton(type: .system, primaryAction: action)
        self.button.translatesAutoresizingMaskIntoConstraints = false
        self.button.setImage(self.unchecked, for: .normal)
        self.button.setImage(self.checked, for: .highlighted)
        self.button.setImage(self.checked, for: .selected)
    }

    func keys() -> [String] {
        self.data.keys()
    }

    func doActions() {
        print("form-button actions")
        self.session?.doActions(self.data.getTapActions() ?? [])
    }

    func getView(_ session: ApplinSession, _ widgetCache: WidgetCache) -> UIView {
        self.session = session
        self.button.setTitle(" " + self.data.text, for: .normal)
        return self.button
    }
}
