import Foundation
import UIKit

struct MaggieButton: Equatable, Hashable {
    static func ==(lhs: MaggieButton, rhs: MaggieButton) -> Bool {
        lhs.text == rhs.text
                && lhs.isDefault == rhs.isDefault
                && lhs.isDestructive == rhs.isDestructive
                && lhs.actions == rhs.actions
    }

    static let TYP = "button"
    let text: String
    let isCancel: Bool
    let isDefault: Bool
    let isDestructive: Bool
    let actions: [MaggieAction]
    weak var session: MaggieSession?

    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.text = try item.requireText()
        self.isCancel = item.isCancel ?? false
        self.isDefault = item.isDefault ?? false
        self.isDestructive = item.isDestructive ?? false
        self.actions = try item.optActions() ?? []
        self.session = session
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.text)
        hasher.combine(self.isDefault)
        hasher.combine(self.isDestructive)
        hasher.combine(self.actions)
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieButton.TYP)
        item.text = self.text
        item.isDefault = self.isDefault
        item.isDestructive = self.isDestructive
        item.actions = self.actions.map({ action in action.toString() })
        return item
    }

    func makeView(_ session: MaggieSession) -> UIView {
        let action = UIAction(title: self.text, handler: { _ in session.doActions(self.actions) })
        let button = UIButton(type: .system, primaryAction: action)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
//        let container = UIView()
//        container.translatesAutoresizingMaskIntoConstraints = false
//        container.addSubview(button)
//        // None of these work.  The docs lie:
//        // https://developer.apple.com/documentation/uikit/uiview/positioning_content_within_layout_margins
//        // container.directionalLayoutMargins =
//        //        NSDirectionalEdgeInsets(top: 20.0, leading: 20.0, bottom: 20.0, trailing: 20.0)
//        // container.alignmentRectInsets = UIEdgeInsets(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0)
//        // container.frame.inset(by: UIEdgeInsets(top: -20.0, left: -20.0, bottom: -20.0, right: -20.0))
//        NSLayoutConstraint.activate([
//            button.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8.0),
//            button.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8.0),
//            button.topAnchor.constraint(equalTo: container.topAnchor, constant: 8.0),
//            button.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8.0)
//        ])
//        return container
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
