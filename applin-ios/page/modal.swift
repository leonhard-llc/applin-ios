import Foundation
import UIKit

enum ModalKind: String {
    case alert
    case drawer

    public func typ() -> String {
        switch self {
        case .alert:
            return "alert-modal"
        case .drawer:
            return "drawer-modal"
        }
    }
}

struct ModalData: Equatable {
    let kind: ModalKind
    let typ: String
    let title: String
    let text: String?
    let widgets: [ModalButtonData]

    init(_ kind: ModalKind, title: String, text: String?, _ widgets: [ModalButtonData]) {
        self.kind = kind
        self.typ = kind.typ()
        self.title = title
        self.text = text
        self.widgets = widgets
    }

    init(_ kind: ModalKind, _ item: JsonItem, _ session: ApplinSession) throws {
        self.kind = kind
        self.typ = kind.typ()
        self.title = try item.requireTitle()
        self.text = item.text
        var widgets: [ModalButtonData] = []
        guard let items = item.widgets else {
            throw ApplinError.deserializeError("\(self.typ).widgets is empty")
        }
        for item in items {
            if item.typ == ModalButtonData.TYP {
                widgets.append(try ModalButtonData(item))
            } else {
                throw ApplinError.deserializeError(
                        "\(self.typ).widgets contains entry that is not \(ModalButtonData.TYP): \(item.typ)")
            }
        }
        self.widgets = widgets
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(self.kind.typ())
        item.title = self.title
        item.text = self.text
        item.widgets = self.widgets.map({ widgets in widgets.toJsonItem() })
        return item
    }

    func makeController(_ session: ApplinSession) -> UIAlertController {
        let style: UIAlertController.Style
        switch self.kind {
        case .alert:
            style = .alert
        case .drawer:
            style = .actionSheet
        }
        let controller = UIAlertController(title: self.title, message: self.text, preferredStyle: style)
        for widget in self.widgets {
            controller.addAction(widget.toAlertAction(session))
        }
        return controller
    }
}

// TODONT: Don't try to sub-class UIAlertController to intercept `dismiss(animated:completion:)` calls.
//         The superclass will throw "Unable to simultaneously satisfy constraints." errors and display
//         the dialog with maximum height.
//         Strangely, displaying a second dialog causes the one underneath to display properly.
// class AlertController: UIAlertController {
//    let preferredStyleOverride: UIAlertController.Style
//    // https://stackoverflow.com/a/45895513
//    override var preferredStyle: UIAlertController.Style {
//        return self.preferredStyleOverride
//    }
//
//    init(title: String?, message: String?, preferredStyle: UIAlertController.Style) {
//        self.preferredStyleOverride = preferredStyle
//        super.init(nibName: nil, bundle: nil)
//        self.title = title
//        self.message = message
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func dismiss(animated flag: Bool, completion: (() -> ())?) {
//        print("dismiss ignored")
//        completion?()
//    }
//
//    func superDismiss(animated flag: Bool) {
//        print("dismiss")
//        super.dismiss(animated: flag)
//    }
// }
