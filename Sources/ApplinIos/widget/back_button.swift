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

    init(_ config: ApplinConfig, _ item: JsonItem) throws {
        self.actions = try item.optActions(config) ?? []
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(BackButtonSpec.TYP)
        item.actions = self.actions.map({ action in action.toJsonAction() })
        return item
    }

    func hasValidatedInput() -> Bool {
        false
    }

    func keys() -> [String] {
        []
    }

    func newWidget() -> Widget {
        Self.logger.dbg("\(String(describing: self)) newWidget")
        return BackButtonWidget()
    }

    func priority() -> WidgetPriority {
        .stateless
    }

    func subs() -> [Spec] {
        []
    }

    func tap(_ ctx: PageContext) {
        Self.logger.dbg("\(String(describing: self)) tap")
        Task {
            await ctx.pageStack?.doActions(pageKey: ctx.pageKey, self.actions)
        }
    }

    func vars() -> [(String, Var)] {
        []
    }

    func widgetClass() -> AnyClass {
        BackButtonWidget.self
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
