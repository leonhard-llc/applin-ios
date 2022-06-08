import Foundation
import UIKit

struct ButtonData: Equatable, Hashable {
    static let TYP = "button"
    let actions: [MaggieAction]
    let isCancel: Bool
    let isDefault: Bool
    let isDestructive: Bool
    let text: String

    init(_ item: JsonItem) throws {
        self.actions = try item.optActions() ?? []
        self.isCancel = item.isCancel ?? false
        self.isDefault = item.isDefault ?? false
        self.isDestructive = item.isDestructive ?? false
        self.text = try item.requireText()
    }

    init(_ actions: [MaggieAction], text: String) {
        self.actions = actions
        self.isCancel = false
        self.isDefault = false
        self.isDestructive = false
        self.text = text
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(ButtonData.TYP)
        item.actions = self.actions.map({ action in action.toString() })
        item.isDefault = self.isDefault
        item.isDestructive = self.isDestructive
        item.text = self.text
        return item
    }

    func keys() -> [String] {
        ["button:\(self.text)", "button:\(self.actions)"]
    }

    func getView(_ session: MaggieSession, _ widgetCache: WidgetCache) -> UIView {
        var buttonWidget: ButtonWidget
        switch widgetCache.remove(self.keys()) {
        case let widget as ButtonWidget:
            buttonWidget = widget
            buttonWidget.data = self
        default:
            buttonWidget = ButtonWidget(self)
        }
        widgetCache.putNext(buttonWidget)
        return buttonWidget.getView(session, widgetCache)
    }
}

class ButtonWidget: Widget {
    var data: ButtonData
    var button: UIButton!
    weak var session: MaggieSession?

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
        self.session?.doActions(self.data.actions)
    }

    func getView(_ session: MaggieSession, _ widgetCache: WidgetCache) -> UIView {
        self.session = session
        self.button.setTitle(self.data.text, for: .normal)
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
