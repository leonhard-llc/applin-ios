import Foundation
import UIKit

struct FormCheckboxData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "form-checkbox"
    let initialBool: Bool?
    let rpc: String?
    let text: String
    let varName: String

    init(_ item: JsonItem) throws {
        self.initialBool = item.initialBool
        self.rpc = item.rpc
        self.text = try item.requireText()
        self.varName = try item.requireVar()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(FormCheckboxData.TYP)
        item.initialBool = self.initialBool
        item.rpc = self.rpc
        item.text = self.text
        item.varName = self.varName
        return item
    }

    func keys() -> [String] {
        ["form-checkbox:\(self.varName)"]
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
        if self.data.initialBool ?? false {
            self.button.setImage(self.checked, for: .normal)
        } else {
            self.button.setImage(self.unchecked, for: .normal)
        }
        return self.button
    }
}
