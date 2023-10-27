import Foundation
import OSLog
import UIKit

public struct BackButtonSpec: Equatable, Hashable {
    static let logger = Logger(subsystem: "Applin", category: "BackButtonSpec")
    static let TYP = "back_button"
    let actions: [ActionSpec]

    public init(_ actions: [ActionSpec]) {
        self.actions = actions
    }

    init(_ item: JsonItem) throws {
        self.actions = try item.optActions() ?? []
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(BackButtonSpec.TYP)
        item.actions = self.actions.map({ action in action.toString() })
        return item
    }

    func keys() -> [String] {
        []
    }

    func subs() -> [Spec] {
        []
    }

    func vars() -> [(String, Var)] {
        []
    }

    func priority() -> WidgetPriority {
        .stateless
    }

    func widgetClass() -> AnyClass {
        BackButtonWidget.self
    }

    func newWidget() -> Widget {
        Self.logger.debug("\(String(describing: self)) newWidget")
        return BackButtonWidget()
    }

    func tap(_ ctx: PageContext) {
        Self.logger.debug("\(String(describing: self)) tap")
        Task {
            await ctx.pageStack?.doActions(pageKey: ctx.pageKey, self.actions)
        }
    }

    func visitActions(_ f: (ActionSpec) -> ()) {
        self.actions.forEach(f)
    }
}

class BackButtonWidget: Widget {
    func isFocused() -> Bool {
        false
    }

    func update(_ ctx: PageContext, _ spec: Spec, _ subs: [Widget]) throws {
    }

    func getView() -> UIView {
        NamedUIView(name: "BackButtonWidget")
    }
}
