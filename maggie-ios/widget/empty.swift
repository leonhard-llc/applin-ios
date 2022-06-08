import Foundation
import UIKit

struct EmptyData: Equatable, Hashable {
    static let TYP = "empty"

    static func toJsonItem() -> JsonItem {
        let item = JsonItem(ColumnData.TYP)
        return item
    }

    static func getView() -> UIView {
        let view = UIView()
        view.backgroundColor = pastelPink
        return view
    }
}
