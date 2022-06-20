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
