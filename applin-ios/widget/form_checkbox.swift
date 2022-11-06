import Foundation
import UIKit

struct FormCheckboxData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "form-checkbox"
    let pageKey: String
    let initialBool: Bool?
    let rpc: String?
    let text: String
    let varName: String

    init(pageKey: String, _ item: JsonItem) throws {
        self.pageKey = pageKey
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

    func priority() -> WidgetPriority {
        .focusable
    }

    func subs() -> [WidgetData] {
        []
    }

    func widgetClass() -> AnyClass {
        FormCheckboxWidget.self
    }

    func widget() -> WidgetProto {
        FormCheckboxWidget(self)
    }

    func vars() -> [(String, Var)] {
        [(self.varName, .boolean(self.initialBool ?? false))]
    }
}

class FormCheckboxWidget: WidgetProto {
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
            print("FormCheckboxWidget(\(weakSelf?.data.varName ?? "nil")) UIAction")
            weakSelf?.tap()
        })
        var config = UIButton.Configuration.borderless()
        config.imagePadding = 8.0
        self.button = UIButton(configuration: config, primaryAction: action)
        self.button.translatesAutoresizingMaskIntoConstraints = false
        self.button.setImage(self.checked, for: .highlighted)
    }

    func getView() -> UIView {
        self.button
    }

    func isFocused(_ session: ApplinSession, _ data: WidgetData) -> Bool {
        self.button.isFocused
    }

    func getChecked() -> Bool {
        self.session?.getBoolVar(self.data.varName) ?? self.data.initialBool ?? false
    }

    func updateImage() {
        if self.getChecked() {
            self.button.setImage(self.checked, for: .normal)
        } else {
            self.button.setImage(self.unchecked, for: .normal)
        }
    }

    func setChecked(_ checked: Bool?) {
        self.session?.setBoolVar(self.data.varName, checked)
        self.updateImage()
    }

    func tap() {
        guard let session = self.session else {
            print("WARN FormCheckboxWidget(\(self.data.varName)).tap session is nil")
            return
        }
        Task { @MainActor in
            print("FormCheckboxWidget(\(self.data.varName)).tap")
            let oldBoolVar = session.getBoolVar(self.data.varName)
            self.setChecked(!self.getChecked())
            if let rpc = self.data.rpc {
                let ok = await session.doActionsAsync(pageKey: self.data.pageKey, [.rpc(rpc)])
                if !ok {
                    self.setChecked(oldBoolVar)
                }
            }
        }
    }

    func update(_ session: ApplinSession, _ data: WidgetData, _ subs: [WidgetProto]) throws {
        guard case let .formCheckbox(formCheckboxData) = data else {
            throw "Expected .formCheckbox got: \(data)"
        }
        self.data = formCheckboxData
        self.session = session
        self.button.setTitle(self.data.text, for: .normal)
        self.updateImage()
    }
}
