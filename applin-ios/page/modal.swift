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

    public func style() -> UIAlertController.Style {
        switch self {
        case .alert:
            return .alert
        case .drawer:
            return .actionSheet
        }
    }
}

struct ModalData: Equatable, PageDataProto {
    let connectionMode: ConnectionMode
    let kind: ModalKind
    let pageKey: String
    let text: String?
    let title: String
    let typ: String
    let widgets: [ModalButtonData]

    init(pageKey: String, _ kind: ModalKind, title: String, text: String?, _ widgets: [ModalButtonData]) {
        self.connectionMode = .disconnect
        self.kind = kind
        self.pageKey = pageKey
        self.typ = kind.typ()
        self.title = title
        self.text = text
        self.widgets = widgets
    }

    init(pageKey: String, _ kind: ModalKind, _ item: JsonItem) throws {
        self.connectionMode = ConnectionMode(item.stream, item.pollSeconds)
        self.kind = kind
        self.pageKey = pageKey
        self.text = item.text
        self.title = try item.requireTitle()
        self.typ = kind.typ()
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
        item.pollSeconds = self.connectionMode.getPollSeconds()
        item.stream = self.connectionMode.getStream()
        item.text = self.text
        item.title = self.title
        item.widgets = self.widgets.map({ widgets in widgets.toJsonItem() })
        return item
    }

    func toAlert(_ session: ApplinSession) -> AlertController {
        let alert = AlertController(title: self.title, message: self.text, preferredStyle: self.kind.style())
        for widget in self.widgets {
            alert.addAction(widget.toAlertAction(session, pageKey: self.pageKey))
        }
        return alert
    }

    func vars() -> [(String, Var)] {
        []
    }
}

// TODONT: Don't make each page controller present the modals above it.
// You will hit two errors:
// 1. "setViewControllers:animated: called on <NavigationController> while
//    an existing transition or presentation is occurring; the navigation
//    stack will not be updated."
//    This means that the UINavigationController refuses to update the stack
//    whenever a modal is displayed by any page in the stack.
// 2. "Attempt to present <AlertController> on <ModalPageController>
//    whose view is not in the window hierarchy."
//    This happens when you call present() on a window that is not visible.
//    This means that displaying multiple modals requires a long slow dance of
//    display, wait for the modal to show, then display.
//    Coding this to work reliably is very challenging.  I gave up.
//
// class ModalPageController: UIViewController, PageController {
//    var data: ModalData?
//    var toPresent: AlertController?
//    var presented: AlertController?
//    var visible = false
//
//    func isModal() -> Bool {
//        true
//    }
//
//    func allowBackSwipe() -> Bool {
//        false
//    }
//
//    func update(_ session: ApplinSession, _ data: ModalData, isTop: Bool) {
//        print("modal update isTop=\(isTop) \(data)")
//        self.view.backgroundColor = .systemBackground // pastelPeach.withAlphaComponent(0.5)
//        if isTop {
//            if (self.presented == nil) || !(self.presented?.isBeingPresented ?? false) {
//                let alert = AlertController(title: data.title, message: data.text, preferredStyle: data.kind.style())
//                for widget in data.widgets {
//                    alert.addAction(widget.toAlertAction(session))
//                }
//                if self.visible {
//                    print("modal present animated=false")
//                    self.present(alert, animated: false)
//                    self.presented = alert
//                } else {
//                    print("modal postpone present")
//                    self.toPresent = alert
//                }
//            } else {
//                print("postponing update to top modal")
//            }
//        } else {
//            print("modal dismiss")
//            self.data = data
//            self.title = data.title
//            self.toPresent = nil
//            self.presented?.dismiss(animated: false, completion: {})
//            self.presented = nil
//        }
//    }
//
//    override func viewDidAppear(_ animated: Bool) {
//        self.visible = true
//        if let alert = self.toPresent {
//            print("modal present animated=true")
//            self.toPresent = nil
//            alert.setAnimated(true)
//            self.present(alert, animated: true) {
//                alert.setAnimated(false)
//            }
//            self.presented = alert
//        }
//        super.viewDidAppear(animated)
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        self.visible = false
//        super.viewWillDisappear(animated)
//    }
// }

// TODONT: Don't try to add the UIAlertController as a child view controller.
//         It will display properly, but will not call button handlers.
// class ModalPageController: UIViewController, PageController {
//    var data: ModalData?
//    var alert: AlertController?
//    let helper = SuperviewHelper()
//
//    func isModal() -> Bool { true }
//    func allowBackSwipe() -> Bool { false }
//
//    func update(_ session: ApplinSession, _ data: ModalData, hasNextPage: Bool) {
//        if data == self.data {
//            return
//        }
//        if self.alert != nil && !hasNextPage {
//            print("postponing update to modal")
//            return
//        }
//        self.data = data
//        self.title = data.title
//        self.helper.removeSubviewsAndConstraints(self.view)
//
//        // self.view.backgroundColor = pastelPeach.withAlphaComponent(0.5)
//        self.alert = nil
//        self.alert = AlertController(title: data.title, message: data.text, preferredStyle: data.kind.style())
//        for widget in data.widgets {
//            self.alert!.addAction(widget.toAlertAction(session))
//        }
//        // This doesn't make a difference.
//        //self.addChild(self.alert!)
//        self.view.addSubview(self.alert!.view)
//
//        self.helper.setConstraints([
//            self.alert!.view.centerXAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerXAnchor),
//            self.alert!.view.centerYAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.centerYAnchor),
//        ])
//    }
// }
