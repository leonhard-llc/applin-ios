import Foundation
import UIKit

struct ScrollData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "scroll"
    let sub: WidgetData

    init(_ session: ApplinSession?, pageKey: String, _ item: JsonItem) throws {
        self.sub = try item.requireWidget(session, pageKey: pageKey)
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(ScrollData.TYP)
        item.widget = self.sub.inner().toJsonItem()
        return item
    }

    func keys() -> [String] {
        []
    }

    func priority() -> WidgetPriority {
        .stateful
    }

    func subs() -> [WidgetData] {
        [self.sub]
    }

    func vars() -> [(String, Var)] {
        self.sub.inner().vars()
    }

    func widgetClass() -> AnyClass {
        ScrollWidget.self
    }

    func widget() -> WidgetProto {
        ScrollWidget()
    }
}


// https://www.hackingwithswift.com/example-code/uikit/how-to-adjust-a-uiscrollview-to-fit-the-keyboard

class KeyboardAvoidingScrollView: UIScrollView {
    init() {
        super.init(frame: CGRect.zero)
        let notificationCenter = NotificationCenter.default
        // NOTE: NotificationCenter.default.addObserver will silently do nothing if you pass it
        //       an object that doesn't inherit from one of UIKit's widgets.
        notificationCenter.addObserver(
                self,
                selector: #selector(adjustForKeyboard),
                name: UIResponder.keyboardWillHideNotification,
                object: nil
        )
        notificationCenter.addObserver(
                self,
                selector: #selector(adjustForKeyboard),
                name: UIResponder.keyboardWillChangeFrameNotification,
                object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func adjustForKeyboard(notification: Notification) {
        guard let frameNsValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        let relativeFrame = self.convert(frameNsValue.cgRectValue, from: self.window)
        print("adjustForKeyboard frameNsValue=\(frameNsValue), relativeFrame=\(relativeFrame)")
        if notification.name == UIResponder.keyboardWillHideNotification {
            self.contentInset = .zero
        } else {
            self.contentInset = UIEdgeInsets(
                    top: 0,
                    left: 0,
                    bottom: relativeFrame.height - self.safeAreaInsets.bottom,
                    right: 0
            )
        }
    }
}

class ScrollWidget: WidgetProto {
    let scrollView: KeyboardAvoidingScrollView
    private let helper: SingleViewContainerHelper
    var keyboardInset: CGFloat = 0.0

    init() {
        self.scrollView = KeyboardAvoidingScrollView()
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.keyboardDismissMode = .interactive
        self.helper = SingleViewContainerHelper(superView: self.scrollView)
    }

    func getView() -> UIView {
        self.scrollView
    }

    func isFocused(_ session: ApplinSession, _ data: WidgetData) -> Bool {
        false
    }

    func update(_ session: ApplinSession, _ data: WidgetData, _ subs: [WidgetProto]) throws {
        guard case .scroll = data else {
            throw "Expected .scroll got: \(data)"
        }
        if subs.count != 1 {
            throw "Expected one sub, got: \(subs)"
        }
        let sub = subs[0]
        let subView = sub.getView()
        self.helper.update(subView) {
            [
                subView.topAnchor.constraint(equalTo: self.scrollView.topAnchor),
                subView.bottomAnchor.constraint(equalTo: self.scrollView.bottomAnchor),
                subView.leftAnchor.constraint(equalTo: self.scrollView.leftAnchor),
                subView.rightAnchor.constraint(equalTo: self.scrollView.rightAnchor),
                subView.widthAnchor.constraint(lessThanOrEqualTo: self.scrollView.widthAnchor),
            ]
        }
    }
}
