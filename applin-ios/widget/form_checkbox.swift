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
    // TODO: Send variable data with RPC
    let checked: UIImage
    let unchecked: UIImage
    var data: FormCheckboxData
    var button: UIButton!
    weak var session: ApplinSession?

    init(_ data: FormCheckboxData) {
        print("FormCheckboxWidget.init(\(data))")
        self.checked = UIImage(systemName: "checkmark.square.fill")!
        self.unchecked = UIImage(systemName: "square")!
        self.data = data
        // For unknown reasons, when the handler takes `[weak self]`, the first
        // checkbox on the page gets self set to 'nil'.  The strange work
        // around is to bind `weak self` before creating the handler.
        weak var weakSelf: FormCheckboxWidget? = self
        let action = UIAction(title: "uninitialized", handler: { [weakSelf] _ in
            if let self2 = weakSelf {
                print("FormCheckboxWidget(\(self2.data.varName)).action")
                Task {
                    await self2.doActions()
                }
            } else {
                print("FormCheckboxWidget(nil).action")
            }
        })
        self.button = UIButton(type: .system, primaryAction: action)
        self.button.translatesAutoresizingMaskIntoConstraints = false
        self.button.setImage(self.checked, for: .highlighted)
    }

    func keys() -> [String] {
        self.data.keys()
    }

    func updateImage() {
        if self.getChecked() {
            self.button.setImage(self.checked, for: .normal)
        } else {
            self.button.setImage(self.unchecked, for: .normal)
        }

    }

    func getChecked() -> Bool {
        self.session?.getBoolVar(self.data.varName) ?? self.data.initialBool ?? false
    }

    func setChecked(_ checked: Bool?) {
        self.session?.setBoolVar(self.data.varName, checked)
        self.updateImage()
    }

    @MainActor func doActions() async {
        guard let session = self.session else {
            print("WARN FormCheckboxWidget(\(self.data.varName)).doActions session is nil")
            return
        }
        print("FormCheckboxWidget(\(self.data.varName)).doActions")
        let oldBoolVar = self.session?.getBoolVar(self.data.varName)
        self.setChecked(!self.getChecked())
        if let rpc = self.data.rpc {
            let ok = await session.doActionsAsync([.rpc(rpc)])
            if !ok {
                self.setChecked(oldBoolVar)
            }
        }
    }

    func getView(_ session: ApplinSession, _ widgetCache: WidgetCache) -> UIView {
        self.session = session
        self.button.setTitle(" " + self.data.text, for: .normal)
        self.updateImage()
        return self.button
    }
}
