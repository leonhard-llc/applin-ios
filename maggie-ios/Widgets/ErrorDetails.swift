import Foundation
import UIKit

struct MaggieErrorDetails: Equatable, Hashable {
    static let TYP = "error-details"
    let error: String

    init(_ session: MaggieSession) {
        self.error = session.error ?? "no error"
    }

    func makeView() -> UIView {
        MaggieText(self.error).makeView()
    }
}
