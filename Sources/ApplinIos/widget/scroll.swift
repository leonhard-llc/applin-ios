import Foundation
import OSLog
import UIKit

public struct ScrollSpec: Equatable, Hashable, ToSpec {
    static let TYP = "scroll"
    let pull_to_refresh: Bool?
    let widget: Spec

    public init(pull_to_refresh: Bool? = nil, _ widget: ToSpec) {
        self.pull_to_refresh = pull_to_refresh
        self.widget = widget.toSpec()
    }

    init(_ config: ApplinConfig, _ item: JsonItem) throws {
        self.pull_to_refresh = item.pull_to_refresh
        self.widget = try item.requireWidget(config)
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(ScrollSpec.TYP)
        item.pull_to_refresh = self.pull_to_refresh
        item.widget = self.widget.toJsonItem()
        return item
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

public class KeyboardAvoidingScrollView: UIScrollView {
    static let logger = Logger(subsystem: "Applin", category: "KeyboardAvoidingScrollView")

    public init() {
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

    override public var description: String {
        "KeyboardAvoidingScrollView.\(self.address)"
    }
}

class ScrollWidget: Widget {
    static let logger = Logger(subsystem: "Applin", category: "ScrollWidget")
    let refreshControl: UIRefreshControl
    let scrollView: KeyboardAvoidingScrollView
    private let helper: SingleViewContainerHelper
    private var pageKey: String?
    private weak var weakPageStack: PageStack?

    init() {
        self.scrollView = KeyboardAvoidingScrollView()
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.scrollView.keyboardDismissMode = .interactive
        self.helper = SingleViewContainerHelper(superView: self.scrollView)
        self.refreshControl = UIRefreshControl()
        self.refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
    }

    func getView() -> UIView {
        self.scrollView
    }

    @objc func handleRefresh() {
        guard let pageKey = self.pageKey, let pageStack = self.weakPageStack else {
            return
        }
        Self.logger.info("refresh pageKey=\(pageKey)")
        Task(priority: .userInitiated) {
            let _ = await pageStack.doActions(pageKey: pageKey, [.poll], showWorking: false)
            await self.refreshControl.endRefreshing()
        }
    }

    func isFocused() -> Bool {
        false
    }

    func update(_ ctx: PageContext, _ spec: Spec, _ subs: [Widget]) throws {
        self.pageKey = ctx.pageKey
        self.weakPageStack = ctx.pageStack
        guard case let .scroll(scrollSpec) = spec.value else {
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
        if scrollSpec.pull_to_refresh ?? true {
            self.scrollView.refreshControl = self.refreshControl
        } else {
            self.scrollView.refreshControl = nil
        }
    }
}
