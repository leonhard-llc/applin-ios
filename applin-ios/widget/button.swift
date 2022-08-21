import Foundation
import UIKit

// TODO: Display disabled button with disabled mode.
struct ButtonData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "button"
    let actions: [ActionData]
    let pageKey: String
    let text: String

    init(pageKey: String, _ actions: [ActionData], text: String) {
        self.actions = actions
        self.pageKey = pageKey
        self.text = text
    }

    init(pageKey: String, _ item: JsonItem) throws {
        self.pageKey = pageKey
        self.actions = try item.optActions() ?? []
        self.text = try item.requireText()
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(ButtonData.TYP)
        item.actions = self.actions.map({ action in action.toString() })
        item.text = self.text
        return item
    }

    func keys() -> [String] {
        ["button:\(self.actions)", "button:\(self.text)"]
    }

    func getTapActions() -> [ActionData]? {
        if self.actions.isEmpty {
            return nil
        }
        return self.actions
    }

    func getView(_ session: ApplinSession, _ cache: WidgetCache) -> UIView {
        let widget = cache.remove(self.keys()) as? ButtonWidget ?? ButtonWidget(self)
        widget.data = self
        cache.putNext(widget)
        return widget.getView(session)
    }

    func vars() -> [(String, Var)] {
        []
    }
}

class ButtonWidget: WidgetProto {
    var data: ButtonData
    var button: UIButton!
    weak var session: ApplinSession?

    init(_ data: ButtonData) {
        print("ButtonWidget.init(\(data))")
        self.data = data
        let action = UIAction(title: "uninitialized", handler: { [weak self] _ in
            print("button UIAction")
            self?.doActions()
        })
        self.button = UIButton(type: .system, primaryAction: action)
        self.button.translatesAutoresizingMaskIntoConstraints = false
    }

    func keys() -> [String] {
        self.data.keys()
    }

    func doActions() {
        print("button actions")
        self.session?.doActions(pageKey: self.data.pageKey, self.data.actions)
    }

    func getView(_ session: ApplinSession, _ widgetCache: WidgetCache) -> UIView {
        self.session = session
        self.button.setTitle(self.data.text, for: .normal)
        self.button.isEnabled = !self.data.actions.isEmpty
        return self.button
    }

//    func buttonRole() -> ButtonRole? {
//        if self.isDestructive {
//            return .destructive
//        } else if self.isCancel {
//            return .cancel
//        } else {
//            return nil
//        }
//    }
//
//    func keyboardShortcut() -> KeyboardShortcut? {
//        if self.isDefault {
//            return .defaultAction
//        } else if self.isCancel {
//            return .cancelAction
//        } else {
//            return nil
//        }
//    }
//
//    func addKeyboardShortcut<V: View>(_ view: V) -> AnyView {
//        if #available(iOS 15.4, *) {
//            return AnyView(view.keyboardShortcut(self.keyboardShortcut()))
//        } else {
//            return AnyView(view)
//        }
//    }
//
//    var body: some View {
//        Button(
//                self.text,
//                role: self.buttonRole(),
//                action: { () in
//                    print("Button(\(self.text)) action")
//                    self.session?.doActions(self.actions)
//                }
//        )
//                .disabled(self.actions.isEmpty)
//                .buttonStyle(.bordered)
//    }
}
