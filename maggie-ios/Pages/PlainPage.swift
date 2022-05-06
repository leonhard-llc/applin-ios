import Foundation
import SwiftUI

struct MaggiePlainPage: Equatable {
    static let TYP = "plain-page"
    let title: String?
    let widget: MaggieWidget
    
    init(title: String?, _ widget: MaggieWidget) {
        self.title = title
        self.widget = widget
    }
    
    init(_ item: JsonItem, _ session: MaggieSession) throws {
        self.title = try item.takeOptTitle()
        self.widget = try item.takeWidget(session)
    }
    
    func toJsonItem() -> JsonItem {
        let item = JsonItem(MaggieNavPage.TYP)
        item.title = self.title
        item.widget = self.widget.toJsonItem()
        return item
    }

    public func toView() -> AnyView {
        return AnyView(self.widget.navigationBarHidden(true))
    }
}
