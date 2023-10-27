import Foundation
import OSLog
import UIKit

public struct PlainPageSpec: Equatable {
    static let TYP = "plain_page"
    let connectionMode: ConnectionMode
    let ephemeral: Bool?
    let title: String?
    let widget: Spec

    public init(
            title: String?,
            connectionMode: ConnectionMode = .disconnect,
            ephemeral: Bool? = nil,
            _ widget: ToSpec
    ) {
        self.connectionMode = connectionMode
        self.ephemeral = ephemeral
        self.title = title
        self.widget = widget.toSpec()
    }

    init(_ config: ApplinConfig, pageKey: String, _ item: JsonItem) throws {
        self.connectionMode = ConnectionMode(item.stream, item.poll_seconds)
        self.ephemeral = item.ephemeral
        self.title = item.title
        self.widget = try item.requireWidget(config)
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(PlainPageSpec.TYP)
        item.poll_seconds = self.connectionMode.getPollSeconds()
        item.stream = self.connectionMode.getStream()
        item.ephemeral = self.ephemeral
        item.title = self.title
        item.widget = self.widget.toJsonItem()
        return item
    }

    public func toSpec() -> PageSpec {
        .plainPage(self)
    }

    func vars() -> [(String, Var)] {
        self.widget.vars()
    }

    func visitActions(_ f: (ActionSpec) -> ()) {
        self.widget.visitActions(f)
    }
}

class PlainPageController: UIViewController, PageController {
    static let logger = Logger(subsystem: "Applin", category: "PlainPageController")
    var spec: PlainPageSpec?
    var helper: SingleViewContainerHelper!

    init() {
        Self.logger.debug("init")
        super.init(nibName: nil, bundle: nil)
        self.helper = SingleViewContainerHelper(superView: self.view)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not implemented")
    }

    // Implement PageController -----------------

    func allowBackSwipe() -> Bool {
        true
    }

    func klass() -> AnyClass {
        PlainPageController.self
    }

    func update(_ ctx: PageContext, _ newPageSpec: PageSpec) {
        guard let cache = ctx.cache else {
            return
        }
        guard case let .plainPage(plainPageSpec) = newPageSpec else {
            // This should never happen.
            fatalError("update called with non-plainPage spec: \(newPageSpec)")
        }
        self.title = plainPageSpec.title
        self.view.backgroundColor = .systemBackground
        let widget = cache.updateAll(ctx, plainPageSpec.widget)
        let subView = widget.getView()
        subView.translatesAutoresizingMaskIntoConstraints = false
        self.helper.update(subView) {
            [
                subView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
                subView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
                subView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
                subView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
            ]
        }
    }

    override var description: String {
        "PlainPageController{title=\(self.title ?? "")}"
    }
}
