import Foundation
import UIKit

struct ErrorDetailsData: Equatable, Hashable, WidgetDataProto {
    static let TYP = "error-details"

    func toJsonItem() -> JsonItem {
        let item = JsonItem(ErrorDetailsData.TYP)
        return item
    }

    func keys() -> [String] {
        []
    }

    func getTapActions() -> [ActionData]? {
        nil
    }

    func getView(_ session: ApplinSession, _ widgetCache: WidgetCache) -> UIView {
        TextData(session.error ?? "no error").getView(session, widgetCache)
    }
}
