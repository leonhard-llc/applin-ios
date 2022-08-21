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

    func canTap() -> Bool {
        false
    }

    func tap(_ session: ApplinSession, _ cache: WidgetCache) {
    }

    func getView(_ session: ApplinSession, _ cache: WidgetCache) -> UIView {
        TextData(session.error ?? "no error").getView(session, cache)
    }

    func vars() -> [(String, Var)] {
        []
    }
}
