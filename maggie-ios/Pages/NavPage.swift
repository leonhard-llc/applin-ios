import Foundation
import SwiftUI

struct MaggieNavPage: Equatable {
    static let TYP = "nav-page"
    let title: String
    let start: MaggieWidget?
    let end: MaggieWidget?
    let widget: MaggieWidget

    init(
            title: String,
            widget: MaggieWidget,
            start: MaggieWidget? = nil,
            end: MaggieWidget? = nil
    ) {
        self.title = title
        self.start = start
        self.end = end
        self.widget = widget
    }

    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.title = try item.takeTitle()
        self.start = try item.takeOptStart(session)
        self.end = try item.takeOptEnd(session)
        self.widget = try item.takeWidget(session)
    }

    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieNavPage.TYP)
        item.title = self.title
        item.start = self.start?.toJsonItem()
        item.end = self.end?.toJsonItem()
        item.widget = self.widget.toJsonItem()
        return item
    }

    public func toView(_ session: MaggieSession, hasPrevPage: Bool) -> AnyView {
        var view: AnyView = AnyView(
                self.widget
                        .navigationTitle(self.title)
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationBarBackButtonHidden(true)
        )
        if let start = self.start {
            view = AnyView(view.toolbar() {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    start
                }
            })
        } else if hasPrevPage {
            view = AnyView(view.toolbar() {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    MaggieBackButton([.Pop], session)
                }
            })
        }
        if let end = self.end {
            view = AnyView(view.toolbar() {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    end
                }
            })
        }
        return view
    }
}
