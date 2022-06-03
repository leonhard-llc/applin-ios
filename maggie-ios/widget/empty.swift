import Foundation
import UIKit

struct MaggieEmpty: Equatable, Hashable {
    static let TYP = "empty"

    func makeView() -> UIView {
        let view = UIView()
        view.backgroundColor = pastelPink
        return view
    }
}
