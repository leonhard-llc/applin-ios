import Foundation
import OSLog
import UIKit

public struct ScrollSpec: Equatable, Hashable, ToSpec {
    static let TYP = "scroll"
    let widget: Spec

    init(_ config: ApplinConfig, _ item: JsonItem) throws {
        self.widget = try item.requireWidget(config)
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(ScrollSpec.TYP)
        item.widget = self.widget.toJsonItem()
        return item
    }

    init(_ sub: ToSpec) {
        self.widget = sub.toSpec()
    }

    public func toSpec() -> Spec {
        Spec(.scroll(self))
    }

    func keys() -> [String] {
        []
    }

    func priority() -> WidgetPriority {
        .stateful
    }

    func subs() -> [Spec] {
        [self.widget]
    }

    func vars() -> [(String, Var)] {
        self.widget.vars()
    }

    func widgetClass() -> AnyClass {
        ScrollWidget.self
    }

    func newWidget() -> Widget {
        ScrollWidget()
    }

    func visitActions(_ f: (ActionSpec) -> ()) {
        self.widget.visitActions(f)
    }
}


// https://www.hackingwithswift.com/example-code/uikit/how-to-adjust-a-uiscrollview-to-fit-the-keyboard

class KeyboardAvoidingScrollView: UIScrollView {
    static let logger = Logger(subsystem: "Applin", category: "KeyboardAvoidingScrollView")

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
        fatalError("init(coder:) is not implemented")
    }

    @objc func adjustForKeyboard(notification: Notification) {
        guard let frameNsValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        let relativeFrame = self.convert(frameNsValue.cgRectValue, from: self.window)
        Self.logger.debug("adjustForKeyboard frameNsValue=\(frameNsValue), relativeFrame=\(String(describing: relativeFrame))")
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

class ScrollWidget: Widget {
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

    func isFocused() -> Bool {
        false
    }

    func update(_ ctx: PageContext, _ spec: Spec, _ subs: [Widget]) throws {
        guard case .scroll = spec.value else {
            throw "Expected .scroll got: \(spec)"
        }
        if subs.count != 1 {
            throw "Expected one sub, got: \(subs)"
        }
        let sub = subs[0]
        let subView = sub.getView()
        subView.translatesAutoresizingMaskIntoConstraints = false
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
